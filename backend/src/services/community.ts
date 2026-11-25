import { and, desc, eq, inArray, isNull, sql } from 'drizzle-orm'
import { z } from 'zod'
import { db } from '../db/client.js'
import { articleStats, articles, comments, locations, media, profiles, wishes } from '../db/schema.js'
import type { AuthUser } from '../lib/auth.js'
import { invalidate } from '../lib/cache.js'
import { decodeCursor, encodeCursor } from '../lib/cursor.js'
import { badRequest, conflict, forbidden, notFound, tooMany } from '../lib/errors.js'
import { mediaUrl } from './storage.js'

const MODERATORS = ['editor', 'admin']

// ------------------------------------------------------------------ comments

export const commentInput = z.object({ body: z.string().trim().min(1).max(1000) })

function displayName(p: { fullName: string | null; email: string | null }) {
  if (p.fullName?.trim()) return p.fullName.trim()
  return p.email ? p.email.split('@')[0]! : 'Reader'
}

export async function listComments(articleId: string, params: { cursor?: string; limit: number }) {
  const pos = decodeCursor<{ t: string; i: string }>(params.cursor)
  const rows = await db
    .select({ c: comments, p: { fullName: profiles.fullName, email: profiles.email } })
    .from(comments)
    .innerJoin(profiles, eq(profiles.id, comments.userId))
    .where(
      and(
        eq(comments.articleId, articleId),
        isNull(comments.deletedAt),
        pos ? sql`(${comments.createdAt}, ${comments.id}) < (${pos.t}::timestamptz, ${pos.i}::uuid)` : undefined,
      ),
    )
    .orderBy(desc(comments.createdAt), desc(comments.id))
    .limit(params.limit + 1)
  const slice = rows.slice(0, params.limit)
  const last = slice.at(-1)
  return {
    items: slice.map(({ c, p }) => ({ id: c.id, userId: c.userId, author: displayName(p), body: c.body, createdAt: c.createdAt.toISOString() })),
    nextCursor: rows.length > params.limit && last ? encodeCursor({ t: last.c.createdAt.toISOString(), i: last.c.id }) : null,
  }
}

export async function addComment(user: AuthUser, articleId: string, body: string) {
  const [a] = await db.select({ id: articles.id }).from(articles).where(and(eq(articles.id, articleId), eq(articles.status, 'live'))).limit(1)
  if (!a) throw notFound('Article not found')
  // Light spam guard: at most 5 comments per user per minute.
  const [{ n }] = (await db.execute<{ n: number }>(
    sql`SELECT count(*)::int AS n FROM app.comments WHERE user_id = ${user.id} AND created_at > now() - interval '1 minute'`,
  )) as unknown as [{ n: number }]
  if (n >= 5) throw tooMany('comment_rate', 'You are commenting too fast. Please wait a minute.')
  const row = await db.transaction(async (tx) => {
    const [c] = await tx.insert(comments).values({ articleId, userId: user.id, body }).returning()
    await tx
      .insert(articleStats)
      .values({ articleId, comments: 1 })
      .onConflictDoUpdate({ target: articleStats.articleId, set: { comments: sql`${articleStats.comments} + 1` } })
    return c!
  })
  const [p] = await db.select({ fullName: profiles.fullName, email: profiles.email }).from(profiles).where(eq(profiles.id, user.id))
  invalidate('feed:')
  return { id: row.id, userId: row.userId, author: displayName(p ?? { fullName: null, email: user.email }), body: row.body, createdAt: row.createdAt.toISOString() }
}

/** Authors can delete their own comments; editors and admins can delete any. */
export async function deleteComment(user: AuthUser, id: string) {
  const [c] = await db.select().from(comments).where(eq(comments.id, id)).limit(1)
  if (!c || c.deletedAt) throw notFound('Comment not found')
  if (c.userId !== user.id && !MODERATORS.includes(user.role)) throw forbidden('You can only delete your own comments')
  await db.transaction(async (tx) => {
    await tx.update(comments).set({ deletedAt: new Date(), deletedBy: user.id }).where(eq(comments.id, id))
    await tx.update(articleStats).set({ comments: sql`greatest(${articleStats.comments} - 1, 0)` }).where(eq(articleStats.articleId, c.articleId))
  })
  invalidate('feed:')
}

// ------------------------------------------------------------------ birthday / anniversary wishes

export const wishInput = z.object({
  kind: z.enum(['birthday', 'anniversary']),
  photoMediaId: z.string().uuid().nullish(),
  recipientName: z.string().trim().min(2).max(120),
  message: z.string().trim().min(2).max(500),
  fromNames: z.string().trim().min(2).max(300),
  districtId: z.number().int().positive().nullish(),
})

type WishRow = typeof wishes.$inferSelect

async function wishDtos(rows: WishRow[]) {
  const mediaIds = rows.map((r) => r.photoMediaId).filter((x): x is string => !!x)
  const ms = mediaIds.length ? await db.select().from(media).where(inArray(media.id, mediaIds)) : []
  const byId = new Map(ms.map((m) => [m.id, m]))
  const dIds = [...new Set(rows.map((r) => r.districtId).filter((x): x is number => !!x))]
  const ds = dIds.length ? await db.select({ id: locations.id, nameEn: locations.nameEn, nameTe: locations.nameTe }).from(locations).where(inArray(locations.id, dIds)) : []
  const dById = new Map(ds.map((d) => [d.id, d]))
  return rows.map((w) => {
    const m = w.photoMediaId ? byId.get(w.photoMediaId) : undefined
    const v = m?.status === 'ready' ? m.variants : null
    return {
      id: w.id,
      kind: w.kind,
      photoUrl: v ? mediaUrl(v['1080'] ?? v['640']) : null,
      recipientName: w.recipientName,
      message: w.message,
      fromNames: w.fromNames,
      district: w.districtId ? (dById.get(w.districtId) ?? null) : null,
      status: w.status,
      rejectionReason: w.rejectionReason,
      createdAt: w.createdAt.toISOString(),
    }
  })
}

export async function submitWish(user: AuthUser, input: z.infer<typeof wishInput>) {
  if (input.photoMediaId) {
    const [m] = await db.select().from(media).where(eq(media.id, input.photoMediaId)).limit(1)
    if (!m || m.kind !== 'image' || m.ownerId !== user.id) throw badRequest('Unknown photo')
  }
  const [{ n }] = (await db.execute<{ n: number }>(
    sql`SELECT count(*)::int AS n FROM app.wishes WHERE submitted_by = ${user.id} AND created_at > now() - interval '1 day'`,
  )) as unknown as [{ n: number }]
  if (n >= 10) throw tooMany('wish_limit', 'You can send up to 10 wishes a day.')
  // Editors/admins publish straight away; everyone else waits for review.
  const autoApprove = MODERATORS.includes(user.role)
  const [w] = await db
    .insert(wishes)
    .values({ ...input, submittedBy: user.id, ...(autoApprove ? { status: 'approved' as const, reviewedBy: user.id, reviewedAt: new Date() } : {}) })
    .returning()
  return (await wishDtos([w!]))[0]!
}

export async function listWishes(params: { kind?: 'birthday' | 'anniversary'; status?: WishRow['status']; mine?: string; limit: number }) {
  const rows = await db
    .select()
    .from(wishes)
    .where(
      and(
        params.kind ? eq(wishes.kind, params.kind) : undefined,
        params.status ? eq(wishes.status, params.status) : undefined,
        params.mine ? eq(wishes.submittedBy, params.mine) : undefined,
        // Public posters stay up for 30 days.
        params.status === 'approved' && !params.mine ? sql`${wishes.createdAt} > now() - interval '30 days'` : undefined,
      ),
    )
    .orderBy(desc(wishes.createdAt))
    .limit(params.limit)
  return { items: await wishDtos(rows) }
}

export async function reviewWish(user: AuthUser, id: string, decision: { approve: true } | { approve: false; reason: string }) {
  const [w] = await db.select().from(wishes).where(eq(wishes.id, id)).limit(1)
  if (!w) throw notFound('Wish not found')
  if (w.status !== 'pending') throw conflict('already_reviewed', `This wish was already ${w.status}.`)
  const [row] = await db
    .update(wishes)
    .set(
      decision.approve
        ? { status: 'approved', reviewedBy: user.id, reviewedAt: new Date() }
        : { status: 'rejected', reviewedBy: user.id, reviewedAt: new Date(), rejectionReason: decision.reason },
    )
    .where(eq(wishes.id, id))
    .returning()
  return (await wishDtos([row!]))[0]!
}

export async function deleteWish(user: AuthUser, id: string) {
  const [w] = await db.select().from(wishes).where(eq(wishes.id, id)).limit(1)
  if (!w) throw notFound('Wish not found')
  if (w.submittedBy !== user.id && !MODERATORS.includes(user.role)) throw forbidden()
  await db.delete(wishes).where(eq(wishes.id, id))
}
