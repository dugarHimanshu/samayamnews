import { Router } from 'express'
import { and, asc, desc, eq, ilike, or, sql } from 'drizzle-orm'
import { z } from 'zod'
import { db } from '../db/client.js'
import { adStatsDaily, ads, appConfig, locations, magazines, profiles, roleEnum } from '../db/schema.js'
import { forgetUser, requireAuth, requireRole } from '../lib/auth.js'
import { invalidate, noStore } from '../lib/cache.js'
import { decodeCursor, encodeCursor } from '../lib/cursor.js'
import { badRequest, notFound } from '../lib/errors.js'
import { limitSchema, parseBody, parseParams, parseQuery, uuidParam } from '../lib/validate.js'
import { listApplications, reviewApplication } from '../services/applications.js'
import { adminArticles, contributors, deleteArticle, removeContributor } from '../services/moderation.js'
import { reviewInput } from './applications.js'

export const adminRouter = Router()
adminRouter.use(noStore, requireAuth, requireRole('admin'))

// ------------------------------------------------------------------ stats (one query instead of ten)

adminRouter.get('/stats', async (_req, res) => {
  const [row] = await db.execute(sql`
    SELECT
      (SELECT count(*) FROM app.profiles WHERE deleted_at IS NULL)::int AS total_users,
      (SELECT jsonb_object_agg(role, n) FROM (SELECT role, count(*)::int n FROM app.profiles WHERE deleted_at IS NULL GROUP BY role) r) AS users_by_role,
      (SELECT jsonb_object_agg(status, n) FROM (SELECT status, count(*)::int n FROM app.submissions GROUP BY status) s) AS submissions_by_status,
      (SELECT count(*) FROM app.articles WHERE status = 'live')::int AS live_articles,
      (SELECT count(*) FROM app.articles WHERE published_at > now() - interval '24 hours')::int AS published_24h,
      (SELECT count(*) FROM app.contributor_applications WHERE status = 'pending')::int AS pending_applications`)
  res.json(row)
})

// ------------------------------------------------------------------ users

adminRouter.get('/users', async (req, res) => {
  const q = parseQuery(
    req,
    z.object({ q: z.string().trim().max(100).optional(), role: z.enum(roleEnum.enumValues).optional(), cursor: z.string().max(500).optional(), limit: limitSchema }),
  )
  const pos = decodeCursor<{ t: string; i: string }>(q.cursor)
  const rows = await db
    .select()
    .from(profiles)
    .where(
      and(
        sql`${profiles.deletedAt} IS NULL`,
        q.role ? eq(profiles.role, q.role) : undefined,
        q.q ? or(ilike(profiles.email, `%${q.q}%`), ilike(profiles.fullName, `%${q.q}%`)) : undefined,
        pos ? sql`(${profiles.createdAt}, ${profiles.id}) < (${pos.t}::timestamptz, ${pos.i}::uuid)` : undefined,
      ),
    )
    .orderBy(desc(profiles.createdAt), desc(profiles.id))
    .limit(q.limit + 1)
  const slice = rows.slice(0, q.limit)
  const last = slice.at(-1)
  res.json({ items: slice, nextCursor: rows.length > q.limit && last ? encodeCursor({ t: last.createdAt.toISOString(), i: last.id }) : null })
})

adminRouter.patch('/users/:id', async (req, res) => {
  const { id } = parseParams(req, uuidParam)
  const body = parseBody(
    req,
    z
      .object({
        role: z.enum(roleEnum.enumValues).optional(),
        fullName: z.string().trim().min(1).max(120).optional(),
        language: z.string().max(5).optional(),
        homeDistrictId: z.number().int().positive().nullable().optional(),
      })
      .strict(),
  )
  if (id === req.user!.id && body.role && body.role !== 'admin') throw badRequest('You cannot remove your own admin role')
  const [p] = await db.update(profiles).set(body).where(eq(profiles.id, id)).returning()
  if (!p) throw notFound('User not found')
  // Roles are read from the database (not the JWT), so this takes effect on the user's next request.
  forgetUser(id)
  res.json(p)
})

// ------------------------------------------------------------------ reporters / freelancers

adminRouter.get('/contributors', async (_req, res) => {
  res.json({ items: await contributors() })
})

/** Remove a reporter/freelancer: they can no longer sign in or upload; their published news stays. */
adminRouter.post('/users/:id/remove', async (req, res) => {
  await removeContributor(req.user!, parseParams(req, uuidParam).id)
  res.status(204).end()
})

// ------------------------------------------------------------------ news list (permanent delete)

adminRouter.get('/articles', async (req, res) => {
  const q = parseQuery(req, z.object({ q: z.string().trim().max(100).optional(), cursor: z.string().max(500).optional(), limit: limitSchema }))
  res.json(await adminArticles(q))
})

adminRouter.delete('/articles/:id', async (req, res) => {
  await deleteArticle(req.user!, parseParams(req, uuidParam).id)
  res.status(204).end()
})

// ------------------------------------------------------------------ reporter / freelancer applications

adminRouter.get('/applications', async (req, res) => {
  const q = parseQuery(req, z.object({ status: z.enum(['pending', 'approved', 'rejected']).optional(), limit: limitSchema }))
  res.json(await listApplications(q.status, q.limit))
})

adminRouter.post('/applications/:id/review', async (req, res) => {
  const { id } = parseParams(req, uuidParam)
  const body = parseBody(req, reviewInput)
  res.json(
    await reviewApplication(req.user!, id, body.decision === 'approve' ? { approve: true, role: body.role } : { approve: false, reason: body.reason }),
  )
})

// ------------------------------------------------------------------ ads

const adInput = z.object({
  sponsor: z.string().trim().min(1).max(120),
  headline: z.string().trim().min(3).max(200),
  description: z.string().trim().max(500).nullish(),
  tag: z.string().trim().max(60).nullish(),
  ctaText: z.string().trim().max(40).nullish(),
  ctaUrl: z.string().url().max(1000).nullish(),
  imageMediaId: z.string().uuid().nullish(),
  imageUrl: z.string().url().max(1000).nullish(),
  weight: z.number().int().min(1).max(100).default(1),
  startsAt: z.coerce.date().nullish(),
  endsAt: z.coerce.date().nullish(),
  isActive: z.boolean().default(true),
  // 4-page sliding campaign + where it should be shown
  slides: z
    .array(
      z.object({
        pageIndex: z.number().int().min(1).max(4),
        tag: z.string().trim().max(60).default(''),
        headline: z.string().trim().max(200).default(''),
        description: z.string().trim().max(500).default(''),
        imageUrl: z.string().trim().max(1000).default(''),
        highlightBadge: z.string().trim().max(80).nullish(),
      }),
    )
    .max(4)
    .nullish(),
  scheduleType: z.enum(['oneDay', 'threePlusOne', 'custom']).nullish(),
  category: z.string().trim().max(60).nullish(),
  targetScope: z.enum(['all', 'state', 'district']).default('all'),
  targetStateId: z.number().int().positive().nullish(),
  targetDistrictId: z.number().int().positive().nullish(),
})

/** Checks the area matches the scope (a state for 'state', a district for 'district') and clears the rest. */
async function normaliseTarget<T extends { targetScope?: 'all' | 'state' | 'district'; targetStateId?: number | null; targetDistrictId?: number | null }>(b: T) {
  if (b.targetScope === undefined) return b
  if (b.targetScope === 'all') return { ...b, targetStateId: null, targetDistrictId: null }
  const id = b.targetScope === 'state' ? b.targetStateId : b.targetDistrictId
  if (!id) throw badRequest(b.targetScope === 'state' ? 'Choose a state for this ad' : 'Choose a district for this ad')
  const [loc] = await db.select().from(locations).where(eq(locations.id, id)).limit(1)
  if (!loc || loc.level !== b.targetScope) throw badRequest(`Unknown ${b.targetScope}`)
  return b.targetScope === 'state'
    ? { ...b, targetStateId: id, targetDistrictId: null }
    : { ...b, targetDistrictId: id, targetStateId: loc.stateId ?? loc.parentId }
}

adminRouter.get('/ads', async (_req, res) => {
  res.json({ items: await db.select().from(ads).orderBy(desc(ads.createdAt)) })
})

adminRouter.post('/ads', async (req, res) => {
  const body = await normaliseTarget(parseBody(req, adInput))
  const [ad] = await db.insert(ads).values({ ...body, createdBy: req.user!.id }).returning()
  invalidate('feed:')
  res.status(201).json(ad)
})

adminRouter.patch('/ads/:id', async (req, res) => {
  const { id } = parseParams(req, uuidParam)
  const body = await normaliseTarget(parseBody(req, adInput.partial()))
  const [ad] = await db.update(ads).set(body).where(eq(ads.id, id)).returning()
  if (!ad) throw notFound('Ad not found')
  invalidate('feed:')
  res.json(ad)
})

adminRouter.delete('/ads/:id', async (req, res) => {
  const { id } = parseParams(req, uuidParam)
  await db.delete(ads).where(eq(ads.id, id))
  invalidate('feed:')
  res.status(204).end()
})

adminRouter.get('/ads/:id/report', async (req, res) => {
  const { id } = parseParams(req, uuidParam)
  const days = await db.select().from(adStatsDaily).where(eq(adStatsDaily.adId, id)).orderBy(asc(adStatsDaily.day))
  const totals = days.reduce((t, d) => ({ impressions: t.impressions + d.impressions, clicks: t.clicks + d.clicks }), { impressions: 0, clicks: 0 })
  res.json({ adId: id, totals: { ...totals, ctr: totals.impressions ? totals.clicks / totals.impressions : 0 }, days })
})

// ------------------------------------------------------------------ magazines

const magazineInput = z.object({
  title: z.string().trim().min(2).max(200),
  subtitle: z.string().trim().max(300).nullish(),
  issue: z.string().trim().min(1).max(100),
  category: z.string().trim().max(60).nullish(),
  coverMediaId: z.string().uuid().nullish(),
  coverUrl: z.string().url().nullish(),
  pdfMediaId: z.string().uuid().nullish(),
  pdfUrl: z.string().url().nullish(),
  pageCount: z.number().int().positive().nullish(),
  isPublished: z.boolean().default(true),
})

adminRouter.get('/magazines', async (_req, res) => {
  res.json({ items: await db.select().from(magazines).orderBy(desc(magazines.publishedAt)) })
})

adminRouter.post('/magazines', async (req, res) => {
  const [m] = await db.insert(magazines).values(parseBody(req, magazineInput)).returning()
  invalidate('feed:')
  res.status(201).json(m)
})

adminRouter.patch('/magazines/:id', async (req, res) => {
  const { id } = parseParams(req, uuidParam)
  const [m] = await db.update(magazines).set(parseBody(req, magazineInput.partial())).where(eq(magazines.id, id)).returning()
  if (!m) throw notFound('Magazine not found')
  invalidate('feed:')
  res.json(m)
})

// ------------------------------------------------------------------ runtime config (no deploy needed)

adminRouter.get('/config', async (_req, res) => {
  res.json({ items: await db.select().from(appConfig) })
})

adminRouter.put('/config/:key', async (req, res) => {
  const { key } = parseParams(req, z.object({ key: z.string().regex(/^[a-z0-9_.-]{1,64}$/) }))
  const value = parseBody(req, z.object({ value: z.unknown() })).value
  if (value === undefined) throw badRequest('value is required')
  await db
    .insert(appConfig)
    .values({ key, value })
    .onConflictDoUpdate({ target: appConfig.key, set: { value, updatedAt: new Date() } })
  invalidate('ref:config')
  res.json({ key, value })
})
