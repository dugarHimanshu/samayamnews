import { and, desc, eq, inArray, sql } from 'drizzle-orm'
import { z } from 'zod'
import { db } from '../db/client.js'
import { contributorApplications, locations, profiles } from '../db/schema.js'
import { type AuthUser, forgetUser } from '../lib/auth.js'
import { badRequest, conflict, notFound } from '../lib/errors.js'
import { supabaseAdmin } from './storage.js'

/**
 * Reporter / freelancer registration.
 *
 *   1. Anyone fills the form → we create (or reuse) their account as a reader and store a pending application.
 *   2. They can sign in straight away, but only see "application under review" in the newsroom.
 *   3. An admin approves → their role becomes `employee` (reporter) or `freelancer` and they can submit news.
 */

export const APPLICANT_ROLES = ['employee', 'freelancer'] as const

const mobile = z
  .string()
  .trim()
  .transform((s) => s.replace(/[\s-]/g, ''))
  .pipe(z.string().regex(/^(\+?91)?[6-9]\d{9}$/, 'Enter a valid 10-digit Indian mobile number'))
  .transform((s) => s.slice(-10))

export const applicationInput = z.object({
  role: z.enum(APPLICANT_ROLES),
  fullName: z.string().trim().min(2).max(120),
  mobile,
  email: z.string().trim().toLowerCase().email().max(200),
  address: z.string().trim().max(500).nullish(),
  districtId: z.number().int().positive(),
  mandalId: z.number().int().positive().nullish(),
})

/** Public sign-up additionally needs a password, since it creates the account. */
export const publicApplicationInput = applicationInput.extend({ password: z.string().min(8).max(72) })

type ApplicationRow = typeof contributorApplications.$inferSelect

async function resolveLocation(districtId: number, mandalId: number | null | undefined) {
  const ids = mandalId ? [districtId, mandalId] : [districtId]
  const rows = await db.select().from(locations).where(inArray(locations.id, ids))
  const district = rows.find((r) => r.id === districtId && r.level === 'district')
  if (!district) throw badRequest('Unknown district')
  if (mandalId) {
    const mandal = rows.find((r) => r.id === mandalId && r.level === 'mandal')
    if (!mandal || mandal.districtId !== districtId) throw badRequest('That mandal is not in the chosen district')
  }
  return { stateId: district.stateId ?? district.parentId }
}

async function insertApplication(userId: string, input: z.infer<typeof applicationInput>) {
  const { stateId } = await resolveLocation(input.districtId, input.mandalId)
  const [profile] = await db.select({ role: profiles.role }).from(profiles).where(eq(profiles.id, userId)).limit(1)
  if (profile && profile.role !== 'reader') throw conflict('already_contributor', 'This account already has newsroom access. Please sign in.')
  const open = await db
    .select({ id: contributorApplications.id })
    .from(contributorApplications)
    .where(and(eq(contributorApplications.userId, userId), eq(contributorApplications.status, 'pending')))
    .limit(1)
  if (open.length) throw conflict('application_pending', 'An application for this account is already under review.')
  const [row] = await db
    .insert(contributorApplications)
    .values({
      userId,
      requestedRole: input.role,
      fullName: input.fullName,
      mobile: input.mobile,
      email: input.email,
      address: input.address ?? null,
      stateId,
      districtId: input.districtId,
      mandalId: input.mandalId ?? null,
    })
    .returning()
  // Fill in the profile so the admin's user list shows a name and the home district is set.
  await db
    .update(profiles)
    .set({ fullName: input.fullName, homeDistrictId: input.districtId })
    .where(eq(profiles.id, userId))
  return row!
}

/** Registration from a signed-out device: creates the login, then the application. */
export async function registerApplicant(input: z.infer<typeof publicApplicationInput>) {
  await resolveLocation(input.districtId, input.mandalId) // validate before creating an account
  const auth = supabaseAdmin().auth.admin
  const { data, error } = await auth.createUser({
    email: input.email,
    password: input.password,
    email_confirm: true,
    user_metadata: { full_name: input.fullName },
  })
  if (error || !data.user) {
    if (/already|registered|exists/i.test(error?.message ?? ''))
      throw conflict('email_taken', 'This email already has an account. Sign in first, then open Reporter Registration from the menu.')
    throw new Error(`Could not create account: ${error?.message}`)
  }
  const userId = data.user.id
  // The auth trigger normally creates the profile; make sure it exists before referencing it.
  await db.insert(profiles).values({ id: userId, email: input.email, fullName: input.fullName }).onConflictDoNothing()
  try {
    return await insertApplication(userId, input)
  } catch (e) {
    await auth.deleteUser(userId).catch(() => {}) // don't leave a half-registered account behind
    throw e
  }
}

/** Registration by someone already signed in (e.g. a reader who wants to become a reporter). */
export function applyAsUser(user: AuthUser, input: z.infer<typeof applicationInput>) {
  return insertApplication(user.id, input)
}

async function withNames(rows: ApplicationRow[]) {
  const ids = [...new Set(rows.flatMap((r) => [r.stateId, r.districtId, r.mandalId]).filter((x): x is number => !!x))]
  const locs = ids.length ? await db.select({ id: locations.id, nameEn: locations.nameEn, nameTe: locations.nameTe }).from(locations).where(inArray(locations.id, ids)) : []
  const byId = new Map(locs.map((l) => [l.id, l]))
  return rows.map((r) => ({
    id: r.id,
    userId: r.userId,
    role: r.requestedRole,
    fullName: r.fullName,
    mobile: r.mobile,
    email: r.email,
    address: r.address,
    state: r.stateId ? (byId.get(r.stateId) ?? null) : null,
    district: byId.get(r.districtId) ?? null,
    mandal: r.mandalId ? (byId.get(r.mandalId) ?? null) : null,
    status: r.status,
    rejectionReason: r.rejectionReason,
    reviewedAt: r.reviewedAt?.toISOString() ?? null,
    createdAt: r.createdAt.toISOString(),
  }))
}

export async function latestApplicationFor(userId: string) {
  const rows = await db
    .select()
    .from(contributorApplications)
    .where(eq(contributorApplications.userId, userId))
    .orderBy(desc(contributorApplications.createdAt))
    .limit(1)
  return rows.length ? (await withNames(rows))[0]! : null
}

export async function listApplications(status: ApplicationRow['status'] | undefined, limit: number) {
  const rows = await db
    .select()
    .from(contributorApplications)
    .where(status ? eq(contributorApplications.status, status) : undefined)
    .orderBy(status === 'pending' ? contributorApplications.createdAt : desc(contributorApplications.createdAt))
    .limit(limit)
  const [counts] = await db.execute<{ pending: number; approved: number; rejected: number }>(sql`
    SELECT count(*) FILTER (WHERE status = 'pending')::int AS pending,
           count(*) FILTER (WHERE status = 'approved')::int AS approved,
           count(*) FILTER (WHERE status = 'rejected')::int AS rejected
    FROM app.contributor_applications`)
  return { items: await withNames(rows), counts }
}

export async function reviewApplication(
  admin: AuthUser,
  id: string,
  decision: { approve: true; role?: (typeof APPLICANT_ROLES)[number] } | { approve: false; reason: string },
) {
  const row = await db.transaction(async (tx) => {
    const [app] = await tx.select().from(contributorApplications).where(eq(contributorApplications.id, id)).for('update').limit(1)
    if (!app) throw notFound('Application not found')
    if (app.status !== 'pending') throw conflict('already_reviewed', `This application was already ${app.status}.`)
    if (decision.approve) {
      const role = decision.role ?? app.requestedRole
      await tx
        .update(contributorApplications)
        .set({ status: 'approved', requestedRole: role, reviewedBy: admin.id, reviewedAt: new Date(), rejectionReason: null })
        .where(eq(contributorApplications.id, id))
      // Never downgrade someone who was promoted in the meantime (e.g. to editor).
      await tx
        .update(profiles)
        .set({ role })
        .where(and(eq(profiles.id, app.userId), eq(profiles.role, 'reader')))
    } else {
      await tx
        .update(contributorApplications)
        .set({ status: 'rejected', reviewedBy: admin.id, reviewedAt: new Date(), rejectionReason: decision.reason })
        .where(eq(contributorApplications.id, id))
    }
    const [updated] = await tx.select().from(contributorApplications).where(eq(contributorApplications.id, id))
    return updated!
  })
  forgetUser(row.userId) // roles are read from the DB; drop the cached profile so the change applies immediately
  return (await withNames([row]))[0]!
}
