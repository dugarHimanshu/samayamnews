import { and, asc, eq, inArray, sql } from 'drizzle-orm'
import { z } from 'zod'
import { db } from '../db/client.js'
import { articleRevisions, articles, media, profiles, submissionEvents, submissions } from '../db/schema.js'
import type { AuthUser } from '../lib/auth.js'
import { invalidate } from '../lib/cache.js'
import { decodeCursor, encodeCursor } from '../lib/cursor.js'
import { badRequest, conflict, forbidden, notFound, tooMany } from '../lib/errors.js'
import { categoryIndex, locationIndex } from './reference.js'
import { enqueue, QUEUES } from './jobs.js'

export const FREELANCER_DAILY_LIMIT = Number(process.env.FREELANCER_DAILY_LIMIT ?? 10)
export const CLAIM_MINUTES = 15

// ------------------------------------------------------------------ validation

export const storyFields = z.object({
  title: z.string().trim().min(5).max(200),
  summary: z.string().trim().min(10).max(600),
  body: z.string().trim().min(20).max(10_000),
  language: z.string().trim().toLowerCase().regex(/^[a-z]{2,3}$/, 'ISO language code, e.g. te, en, hi'),
  categoryId: z.number().int().positive(),
  stateId: z.number().int().positive(),
  districtId: z.number().int().positive(),
  mandalId: z.number().int().positive().nullish(),
  villageId: z.number().int().positive().nullish(),
  coverMediaId: z.string().uuid().nullish(),
  authorName: z.string().trim().min(2).max(120),
  source: z.string().trim().max(200).nullish(),
})
export type StoryFields = z.infer<typeof storyFields>

/** Checks the category exists and that the location chain is consistent (village ∈ mandal ∈ district ∈ state). */
export async function assertStoryRefs(f: Partial<StoryFields>, current?: Partial<StoryFields>) {
  const merged = { ...current, ...f }
  if (f.categoryId !== undefined) {
    const cats = await categoryIndex()
    if (!cats.has(f.categoryId)) throw badRequest('Unknown category')
  }
  const touched = ['stateId', 'districtId', 'mandalId', 'villageId'].some((k) => k in f)
  if (!touched) return
  const locs = await locationIndex()
  const expect = (id: number | null | undefined, level: string, parent?: number | null) => {
    if (id == null) return
    const l = locs.get(id)
    if (!l || l.level !== level || !l.isActive) throw badRequest(`Unknown ${level}`)
    if (parent != null && l.parentId !== parent) throw badRequest(`The ${level} does not belong to the selected parent location`)
  }
  expect(merged.stateId, 'state')
  expect(merged.districtId, 'district', merged.stateId)
  expect(merged.mandalId, 'mandal', merged.districtId)
  if (merged.villageId != null && merged.mandalId == null) throw badRequest('Select a mandal before a village')
  expect(merged.villageId, 'village', merged.mandalId)
}

async function assertOwnImage(mediaId: string | null | undefined, user: AuthUser) {
  if (!mediaId) return
  const m = (await db.select().from(media).where(eq(media.id, mediaId)).limit(1))[0]
  if (!m || m.kind !== 'image') throw badRequest('Unknown image')
  if (m.ownerId !== user.id && !['editor', 'admin'].includes(user.role)) throw forbidden('That image belongs to someone else')
}

// ------------------------------------------------------------------ contributor side

/** Start of "today" in India (IST), as a timestamp. */
const istDayStart = sql`(date_trunc('day', now() AT TIME ZONE 'Asia/Kolkata') AT TIME ZONE 'Asia/Kolkata')`

export async function submissionQuota(user: AuthUser) {
  if (user.role !== 'freelancer') return { limited: false as const, used: null, limit: null, remaining: null }
  const [row] = await db
    .select({ n: sql<number>`count(*)::int` })
    .from(submissions)
    .where(and(eq(submissions.submitterId, user.id), sql`${submissions.createdAt} >= ${istDayStart}`))
  const used = row?.n ?? 0
  return { limited: true as const, used, limit: FREELANCER_DAILY_LIMIT, remaining: Math.max(0, FREELANCER_DAILY_LIMIT - used) }
}

export async function createSubmission(user: AuthUser, input: StoryFields) {
  await assertStoryRefs(input)
  await assertOwnImage(input.coverMediaId, user)
  return db.transaction(async (tx) => {
    if (user.role === 'freelancer') {
      // Serialise this user's submissions so two parallel requests can't both slip under the limit.
      await tx.execute(sql`SELECT pg_advisory_xact_lock(hashtext(${'submit:' + user.id}))`)
      const [row] = await tx
        .select({ n: sql<number>`count(*)::int` })
        .from(submissions)
        .where(and(eq(submissions.submitterId, user.id), sql`${submissions.createdAt} >= ${istDayStart}`))
      if ((row?.n ?? 0) >= FREELANCER_DAILY_LIMIT)
        throw tooMany('daily_limit_reached', `Daily limit of ${FREELANCER_DAILY_LIMIT} submissions reached. Try again tomorrow.`)
    }
    const [created] = await tx
      .insert(submissions)
      .values({ ...input, submitterId: user.id })
      .returning()
    await tx.insert(submissionEvents).values({ submissionId: created!.id, actorId: user.id, type: 'submitted' })
    return created!
  })
}

export async function mySubmissions(user: AuthUser, params: { cursor?: string; limit: number }) {
  const pos = decodeCursor<{ t: string; i: string }>(params.cursor)
  const rows = await db
    .select()
    .from(submissions)
    .where(
      and(
        eq(submissions.submitterId, user.id),
        pos ? sql`(${submissions.createdAt}, ${submissions.id}) < (${pos.t}::timestamptz, ${pos.i}::uuid)` : undefined,
      ),
    )
    .orderBy(sql`${submissions.createdAt} DESC, ${submissions.id} DESC`)
    .limit(params.limit + 1)
  const slice = rows.slice(0, params.limit)
  const reasons = await rejectionReasons(slice.filter((s) => s.status === 'rejected').map((s) => s.id))
  const last = slice.at(-1)
  return {
    items: slice.map((s) => submissionForSubmitter(s, reasons.get(s.id))),
    nextCursor: rows.length > params.limit && last ? encodeCursor({ t: last.createdAt.toISOString(), i: last.id }) : null,
  }
}

export async function mySubmission(user: AuthUser, id: string) {
  const s = (await db.select().from(submissions).where(eq(submissions.id, id)).limit(1))[0]
  if (!s || s.submitterId !== user.id) throw notFound('Submission not found')
  const reasons = await rejectionReasons(s.status === 'rejected' ? [s.id] : [])
  return submissionForSubmitter(s, reasons.get(s.id))
}

async function rejectionReasons(ids: string[]) {
  if (!ids.length) return new Map<string, string>()
  const rows = await db
    .select({ submissionId: submissionEvents.submissionId, payload: submissionEvents.payload })
    .from(submissionEvents)
    .where(and(inArray(submissionEvents.submissionId, ids), eq(submissionEvents.type, 'rejected')))
    .orderBy(asc(submissionEvents.createdAt))
  const m = new Map<string, string>()
  for (const r of rows) m.set(r.submissionId, String(r.payload?.reason ?? ''))
  return m
}

/** What a submitter sees: never the identity of the editor handling it. */
function submissionForSubmitter(s: typeof submissions.$inferSelect, rejectionReason?: string) {
  const { claimedBy: _c, claimExpiresAt: _e, ...rest } = s
  return {
    ...rest,
    status: s.status,
    createdAt: s.createdAt.toISOString(),
    updatedAt: s.updatedAt.toISOString(),
    rejectionReason: rejectionReason ?? null,
  }
}

// ------------------------------------------------------------------ editor side

export async function editorQueue(user: AuthUser, params: { cursor?: string; limit: number }) {
  const pos = decodeCursor<{ t: string; i: string }>(params.cursor)
  const rows = await db
    .select({ s: submissions, claimer: { id: profiles.id, fullName: profiles.fullName } })
    .from(submissions)
    .leftJoin(profiles, eq(profiles.id, submissions.claimedBy))
    .where(
      and(
        inArray(submissions.status, ['pending', 'in_review']),
        pos ? sql`(${submissions.createdAt}, ${submissions.id}) > (${pos.t}::timestamptz, ${pos.i}::uuid)` : undefined,
      ),
    )
    .orderBy(asc(submissions.createdAt), asc(submissions.id))
    .limit(params.limit + 1)
  const now = Date.now()
  const slice = rows.slice(0, params.limit)
  const last = slice.at(-1)
  return {
    items: slice.map(({ s, claimer }) => {
      const claimActive = !!s.claimedBy && !!s.claimExpiresAt && s.claimExpiresAt.getTime() > now
      return {
        ...s,
        createdAt: s.createdAt.toISOString(),
        updatedAt: s.updatedAt.toISOString(),
        claim: claimActive
          ? { byMe: s.claimedBy === user.id, editorName: claimer?.fullName ?? 'another editor', expiresAt: s.claimExpiresAt!.toISOString() }
          : null,
      }
    }),
    nextCursor: rows.length > params.limit && last ? encodeCursor({ t: last.s.createdAt.toISOString(), i: last.s.id }) : null,
  }
}

export async function editorSubmission(id: string) {
  const s = (await db.select().from(submissions).where(eq(submissions.id, id)).limit(1))[0]
  if (!s) throw notFound('Submission not found')
  const events = await db
    .select({ type: submissionEvents.type, payload: submissionEvents.payload, createdAt: submissionEvents.createdAt, actorName: profiles.fullName })
    .from(submissionEvents)
    .leftJoin(profiles, eq(profiles.id, submissionEvents.actorId))
    .where(eq(submissionEvents.submissionId, id))
    .orderBy(asc(submissionEvents.createdAt))
  return { ...s, events }
}

/** Atomic claim: succeeds only if nobody else holds an unexpired claim. */
export async function claimSubmission(user: AuthUser, id: string) {
  const [row] = await db
    .update(submissions)
    .set({
      claimedBy: user.id,
      claimExpiresAt: sql`now() + make_interval(mins => ${CLAIM_MINUTES})`,
      status: 'in_review',
    })
    .where(
      and(
        eq(submissions.id, id),
        inArray(submissions.status, ['pending', 'in_review']),
        sql`(${submissions.claimedBy} IS NULL OR ${submissions.claimExpiresAt} < now() OR ${submissions.claimedBy} = ${user.id})`,
      ),
    )
    .returning()
  if (!row) {
    const exists = (await db.select({ status: submissions.status }).from(submissions).where(eq(submissions.id, id)).limit(1))[0]
    if (!exists) throw notFound('Submission not found')
    if (exists.status === 'published' || exists.status === 'rejected') throw conflict('already_decided', `This story was already ${exists.status}`)
    throw conflict('claimed_by_other', 'Another editor is reviewing this story')
  }
  await db.insert(submissionEvents).values({ submissionId: id, actorId: user.id, type: 'claimed' })
  return row
}

export async function heartbeat(user: AuthUser, id: string) {
  const [row] = await db
    .update(submissions)
    .set({ claimExpiresAt: sql`now() + make_interval(mins => ${CLAIM_MINUTES})` })
    .where(and(eq(submissions.id, id), eq(submissions.claimedBy, user.id), eq(submissions.status, 'in_review')))
    .returning({ claimExpiresAt: submissions.claimExpiresAt })
  if (!row) throw conflict('claim_lost', 'Your review lock expired or was taken by another editor')
  return { claimExpiresAt: row.claimExpiresAt!.toISOString() }
}

export async function releaseClaim(user: AuthUser, id: string) {
  const [row] = await db
    .update(submissions)
    .set({ claimedBy: null, claimExpiresAt: null, status: 'pending' })
    .where(and(eq(submissions.id, id), eq(submissions.claimedBy, user.id), eq(submissions.status, 'in_review')))
    .returning({ id: submissions.id })
  if (row) await db.insert(submissionEvents).values({ submissionId: id, actorId: user.id, type: 'released' })
  return { released: !!row }
}

const holdsClaim = (user: AuthUser) =>
  and(eq(submissions.claimedBy, user.id), sql`${submissions.claimExpiresAt} > now()`, eq(submissions.status, 'in_review'))

/** Save draft edits; `version` must match (optimistic locking) so two tabs can't overwrite each other. */
export async function saveDraft(user: AuthUser, id: string, version: number, edits: Partial<StoryFields>) {
  const current = (await db.select().from(submissions).where(eq(submissions.id, id)).limit(1))[0]
  if (!current) throw notFound('Submission not found')
  await assertStoryRefs(edits, current as Partial<StoryFields>)
  await assertOwnImage(edits.coverMediaId, user)
  return db.transaction(async (tx) => {
    const [row] = await tx
      .update(submissions)
      .set({ ...edits, version: sql`${submissions.version} + 1`, claimExpiresAt: sql`now() + make_interval(mins => ${CLAIM_MINUTES})` })
      .where(and(eq(submissions.id, id), eq(submissions.version, version), holdsClaim(user)))
      .returning()
    if (!row) throw conflict('stale_or_unclaimed', 'This story changed elsewhere or your review lock expired. Reload and try again.')
    await tx.insert(submissionEvents).values({ submissionId: id, actorId: user.id, type: 'edited', payload: { fields: Object.keys(edits) } })
    return row
  })
}

/** Publish = one transaction: verify claim → create article → mark submission published → audit event. */
export async function publishSubmission(user: AuthUser, id: string, opts: { version: number; isBreaking: boolean; edits?: Partial<StoryFields> }) {
  const current = (await db.select().from(submissions).where(eq(submissions.id, id)).limit(1))[0]
  if (!current) throw notFound('Submission not found')
  if (opts.edits) {
    await assertStoryRefs(opts.edits, current as Partial<StoryFields>)
    await assertOwnImage(opts.edits.coverMediaId, user)
  }
  const article = await db.transaction(async (tx) => {
    const [s] = await tx
      .update(submissions)
      .set({ ...(opts.edits ?? {}), status: 'published', claimedBy: null, claimExpiresAt: null, version: sql`${submissions.version} + 1` })
      .where(and(eq(submissions.id, id), eq(submissions.version, opts.version), holdsClaim(user)))
      .returning()
    if (!s) throw conflict('stale_or_unclaimed', 'This story changed elsewhere or your review lock expired. Reload and try again.')
    const [a] = await tx
      .insert(articles)
      .values({
        submissionId: s.id,
        title: s.title,
        summary: s.summary,
        body: s.body,
        language: s.language,
        categoryId: s.categoryId,
        stateId: s.stateId,
        districtId: s.districtId,
        mandalId: s.mandalId,
        villageId: s.villageId,
        coverMediaId: s.coverMediaId,
        authorName: s.authorName,
        source: s.source,
        isBreaking: opts.isBreaking,
        publishedBy: user.id,
      })
      .returning()
    await tx.insert(submissionEvents).values({ submissionId: id, actorId: user.id, type: 'published', payload: { articleId: a!.id } })
    return a!
  })
  afterArticleChange()
  if (article.isBreaking) {
    await enqueue(QUEUES.sendPush, { articleId: article.id, topic: 'all', title: article.title, body: article.summary })
  }
  return article
}

export async function rejectSubmission(user: AuthUser, id: string, reason: string) {
  return db.transaction(async (tx) => {
    const [s] = await tx
      .update(submissions)
      .set({ status: 'rejected', claimedBy: null, claimExpiresAt: null })
      .where(and(eq(submissions.id, id), holdsClaim(user)))
      .returning()
    if (!s) throw conflict('unclaimed', 'Claim this story before rejecting it')
    await tx.insert(submissionEvents).values({ submissionId: id, actorId: user.id, type: 'rejected', payload: { reason } })
    return s
  })
}

export async function editorStats() {
  const [row] = await db.execute<{
    pending: number
    in_review: number
    published_today: number
    rejected_today: number
  }>(sql`
    SELECT
      count(*) FILTER (WHERE status = 'pending')::int AS pending,
      count(*) FILTER (WHERE status = 'in_review')::int AS in_review,
      count(*) FILTER (WHERE status = 'published' AND updated_at >= ${istDayStart})::int AS published_today,
      count(*) FILTER (WHERE status = 'rejected' AND updated_at >= ${istDayStart})::int AS rejected_today
    FROM app.submissions`)
  return row
}

// ------------------------------------------------------------------ live articles

export const articleEdit = storyFields.partial().extend({ isBreaking: z.boolean().optional() })

export async function updateArticle(user: AuthUser, id: string, edits: z.infer<typeof articleEdit>) {
  const current = (await db.select().from(articles).where(eq(articles.id, id)).limit(1))[0]
  if (!current) throw notFound('Article not found')
  await assertStoryRefs(edits, current as Partial<StoryFields>)
  await assertOwnImage(edits.coverMediaId, user)
  const updated = await db.transaction(async (tx) => {
    const [a] = await tx.update(articles).set(edits).where(eq(articles.id, id)).returning()
    const before: Record<string, unknown> = {}
    for (const k of Object.keys(edits)) before[k] = (current as Record<string, unknown>)[k]
    await tx.insert(articleRevisions).values({ articleId: id, editorId: user.id, before, after: edits })
    return a!
  })
  afterArticleChange()
  return updated
}

export async function setArticleStatus(user: AuthUser, id: string, status: 'live' | 'unpublished') {
  const [a] = await db.update(articles).set({ status }).where(eq(articles.id, id)).returning()
  if (!a) throw notFound('Article not found')
  await db.insert(articleRevisions).values({ articleId: id, editorId: user.id, before: {}, after: { status } })
  afterArticleChange()
  return a
}

function afterArticleChange() {
  // Per-instance caches; Cloudflare's short s-maxage takes care of the edge.
  invalidate('feed:')
}
