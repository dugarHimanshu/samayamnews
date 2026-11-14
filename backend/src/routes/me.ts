import { Router } from 'express'
import { and, desc, eq, inArray, sql } from 'drizzle-orm'
import { z } from 'zod'
import { db } from '../db/client.js'
import { articleStats, articles, bookmarks, devices, likes, locations, profiles } from '../db/schema.js'
import { forgetUser, requireAuth } from '../lib/auth.js'
import { noStore } from '../lib/cache.js'
import { decodeCursor, encodeCursor } from '../lib/cursor.js'
import { badRequest, notFound } from '../lib/errors.js'
import { limitSchema, parseBody, parseParams, parseQuery } from '../lib/validate.js'
import { getArticlesByIds } from '../services/articles.js'
import { enqueue, QUEUES } from '../services/jobs.js'

export const meRouter = Router()
meRouter.use(noStore, requireAuth)

meRouter.get('/me', async (req, res) => {
  const p = (await db.select().from(profiles).where(eq(profiles.id, req.user!.id)).limit(1))[0]
  if (!p) throw notFound()
  res.json({ id: p.id, email: p.email, role: p.role, fullName: p.fullName, language: p.language, homeDistrictId: p.homeDistrictId })
})

meRouter.patch('/me', async (req, res) => {
  const body = parseBody(
    req,
    z
      .object({
        fullName: z.string().trim().min(1).max(120).optional(),
        language: z.string().trim().toLowerCase().regex(/^[a-z]{2,3}$/).optional(),
        homeDistrictId: z.number().int().positive().nullable().optional(),
      })
      .strict(),
  )
  if (body.homeDistrictId) {
    const d = (await db.select().from(locations).where(eq(locations.id, body.homeDistrictId)).limit(1))[0]
    if (!d || d.level !== 'district') throw badRequest('Unknown district')
  }
  const [p] = await db.update(profiles).set(body).where(eq(profiles.id, req.user!.id)).returning()
  res.json({ id: p!.id, email: p!.email, role: p!.role, fullName: p!.fullName, language: p!.language, homeDistrictId: p!.homeDistrictId })
})

/** Account deletion: mark now, clean up asynchronously (profile anonymised, auth user removed). */
meRouter.delete('/me', async (req, res) => {
  await db.update(profiles).set({ deletedAt: new Date() }).where(eq(profiles.id, req.user!.id))
  forgetUser(req.user!.id)
  await enqueue(QUEUES.deleteAccount, { userId: req.user!.id }, { retryLimit: 10 })
  res.status(202).json({ status: 'scheduled' })
})

// ---------------- bookmarks & likes (keyed by article id, synced across devices)

const articleIdParam = z.object({ articleId: z.string().uuid() })

async function assertArticle(id: string) {
  const a = (await db.select({ id: articles.id }).from(articles).where(eq(articles.id, id)).limit(1))[0]
  if (!a) throw notFound('Article not found')
}

meRouter.get('/me/bookmarks', async (req, res) => {
  const q = parseQuery(req, z.object({ cursor: z.string().max(500).optional(), limit: limitSchema }))
  const pos = decodeCursor<{ t: string; i: string }>(q.cursor)
  const rows = await db
    .select()
    .from(bookmarks)
    .where(
      and(
        eq(bookmarks.userId, req.user!.id),
        pos ? sql`(${bookmarks.createdAt}, ${bookmarks.articleId}) < (${pos.t}::timestamptz, ${pos.i}::uuid)` : undefined,
      ),
    )
    .orderBy(desc(bookmarks.createdAt), desc(bookmarks.articleId))
    .limit(q.limit + 1)
  const slice = rows.slice(0, q.limit)
  const dtos = await getArticlesByIds(slice.map((r) => r.articleId))
  const byId = new Map(dtos.map((d) => [d.id, d]))
  const last = slice.at(-1)
  res.json({
    items: slice.flatMap((r) => (byId.has(r.articleId) ? [{ savedAt: r.createdAt.toISOString(), article: byId.get(r.articleId)! }] : [])),
    nextCursor: rows.length > q.limit && last ? encodeCursor({ t: last.createdAt.toISOString(), i: last.articleId }) : null,
  })
})

meRouter.put('/me/bookmarks/:articleId', async (req, res) => {
  const { articleId } = parseParams(req, articleIdParam)
  await assertArticle(articleId)
  await db.insert(bookmarks).values({ userId: req.user!.id, articleId }).onConflictDoNothing()
  res.status(204).end()
})

meRouter.delete('/me/bookmarks/:articleId', async (req, res) => {
  const { articleId } = parseParams(req, articleIdParam)
  await db.delete(bookmarks).where(and(eq(bookmarks.userId, req.user!.id), eq(bookmarks.articleId, articleId)))
  res.status(204).end()
})

meRouter.put('/me/likes/:articleId', async (req, res) => {
  const { articleId } = parseParams(req, articleIdParam)
  await assertArticle(articleId)
  const inserted = await db.insert(likes).values({ userId: req.user!.id, articleId }).onConflictDoNothing().returning()
  if (inserted.length) {
    await db
      .insert(articleStats)
      .values({ articleId, likes: 1 })
      .onConflictDoUpdate({ target: articleStats.articleId, set: { likes: sql`${articleStats.likes} + 1` } })
  }
  res.status(204).end()
})

meRouter.delete('/me/likes/:articleId', async (req, res) => {
  const { articleId } = parseParams(req, articleIdParam)
  const deleted = await db
    .delete(likes)
    .where(and(eq(likes.userId, req.user!.id), eq(likes.articleId, articleId)))
    .returning()
  if (deleted.length) {
    await db
      .update(articleStats)
      .set({ likes: sql`greatest(${articleStats.likes} - 1, 0)` })
      .where(eq(articleStats.articleId, articleId))
  }
  res.status(204).end()
})

/** Liked/saved flags for a page of articles (the feed itself is shared & cached, so per-user state comes from here). */
meRouter.get('/me/state', async (req, res) => {
  const q = parseQuery(req, z.object({ ids: z.string().max(2000) }))
  const ids = q.ids.split(',').filter((s) => z.string().uuid().safeParse(s).success).slice(0, 50)
  if (!ids.length) return void res.json({ liked: [], saved: [] })
  const [l, b] = await Promise.all([
    db.select({ id: likes.articleId }).from(likes).where(and(eq(likes.userId, req.user!.id), inArray(likes.articleId, ids))),
    db.select({ id: bookmarks.articleId }).from(bookmarks).where(and(eq(bookmarks.userId, req.user!.id), inArray(bookmarks.articleId, ids))),
  ])
  res.json({ liked: l.map((r) => r.id), saved: b.map((r) => r.id) })
})

// ---------------- push notification devices

meRouter.post('/devices', async (req, res) => {
  const body = parseBody(
    req,
    z.object({
      fcmToken: z.string().min(10).max(4096),
      platform: z.enum(['android', 'ios', 'web']),
      districtId: z.number().int().positive().nullish(),
      language: z.string().max(5).nullish(),
    }),
  )
  await db
    .insert(devices)
    .values({ ...body, userId: req.user!.id })
    .onConflictDoUpdate({
      target: devices.fcmToken,
      set: { userId: req.user!.id, platform: body.platform, districtId: body.districtId, language: body.language, lastSeenAt: new Date() },
    })
  res.status(204).end()
})
