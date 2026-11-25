import { Router } from 'express'
import { and, asc, eq } from 'drizzle-orm'
import { z } from 'zod'
import { db } from '../db/client.js'
import { locations } from '../db/schema.js'
import { cached, publicCache } from '../lib/cache.js'
import { notFound } from '../lib/errors.js'
import { limitSchema, parseParams, parseQuery, uuidParam } from '../lib/validate.js'
import {
  feedHead,
  getArticle,
  getFeed,
  listArticles,
  magazineDto,
  publishedMagazines,
  searchArticles,
} from '../services/articles.js'
import { categoryIndex, publicAppConfig } from '../services/reference.js'

/**
 * Public, user-independent endpoints. Everything here sets `s-maxage` so Cloudflare can serve
 * repeat requests from the edge — this is what lets a small origin handle 10k concurrent readers.
 */
export const publicRouter = Router()

const id = z.coerce.number().int().positive()

publicRouter.get('/feed', publicCache(30, 120), async (req, res) => {
  const q = parseQuery(req, z.object({ district: id.optional(), cursor: z.string().max(500).optional(), limit: limitSchema }))
  // First pages are identical for everyone in a district → also cached in memory for 15s.
  const load = () => getFeed({ districtId: q.district, cursor: q.cursor, limit: q.limit })
  res.json(q.cursor ? await load() : await cached(`feed:first:${q.district ?? 'all'}:${q.limit}`, 15_000, load))
})

publicRouter.get('/feed/head', publicCache(15, 30), async (req, res) => {
  const q = parseQuery(req, z.object({ district: id.optional() }))
  res.json(await cached(`feed:head:${q.district ?? 'all'}`, 10_000, () => feedHead(q.district)))
})

publicRouter.get('/articles', publicCache(30, 120), async (req, res) => {
  const q = parseQuery(
    req,
    z.object({
      district: id.optional(),
      mandal: id.optional(),
      category: z.string().max(40).optional(),
      cursor: z.string().max(500).optional(),
      video: z.enum(['0', '1']).optional(),
      limit: limitSchema,
    }),
  )
  let categoryId: number | undefined
  if (q.category) {
    const cats = await categoryIndex()
    categoryId = [...cats.values()].find((c) => c.slug === q.category || String(c.id) === q.category)?.id
    if (!categoryId) throw notFound('Unknown category')
  }
  res.json(await listArticles({ districtId: q.district, mandalId: q.mandal, categoryId, videoOnly: q.video === '1', cursor: q.cursor, limit: q.limit }))
})

publicRouter.get('/articles/:id', publicCache(60, 300), async (req, res) => {
  const { id: articleId } = parseParams(req, uuidParam)
  const article = await cached(`feed:article:${articleId}`, 30_000, async () => ({ a: await getArticle(articleId) }))
  if (!article.a) throw notFound('Article not found')
  res.json(article.a)
})

publicRouter.get('/search', publicCache(60, 240), async (req, res) => {
  const q = parseQuery(req, z.object({ q: z.string().trim().min(2).max(100), cursor: z.string().max(500).optional(), limit: limitSchema }))
  res.json(await searchArticles({ q: q.q, cursor: q.cursor, limit: q.limit }))
})

publicRouter.get('/categories', publicCache(300, 3600), async (_req, res) => {
  res.json({ items: [...(await categoryIndex()).values()] })
})

publicRouter.get('/locations', publicCache(3600, 86400), async (req, res) => {
  const q = parseQuery(
    req,
    z.object({ parent: id.optional(), level: z.enum(['state', 'district', 'mandal', 'village']).optional() }),
  )
  const level = q.level ?? (q.parent ? undefined : 'state')
  const items = await cached(`ref:loc:${q.parent ?? 'root'}:${level ?? 'any'}`, 10 * 60_000, async () => ({
    rows: await db
      .select({ id: locations.id, level: locations.level, parentId: locations.parentId, nameEn: locations.nameEn, nameTe: locations.nameTe })
      .from(locations)
      .where(
        and(
          eq(locations.isActive, true),
          q.parent ? eq(locations.parentId, q.parent) : undefined,
          level ? eq(locations.level, level) : undefined,
        ),
      )
      .orderBy(asc(locations.nameEn)),
  }))
  res.json({ items: items.rows })
})

publicRouter.get('/magazines', publicCache(120, 600), async (_req, res) => {
  const { rows } = await publishedMagazines()
  res.json({ items: await Promise.all(rows.map(magazineDto)) })
})

publicRouter.get('/magazines/:id', publicCache(120, 600), async (req, res) => {
  const { id: magId } = parseParams(req, uuidParam)
  const row = (await publishedMagazines()).rows.find((r) => r.magazine.id === magId)
  if (!row) throw notFound('Magazine not found')
  res.json(await magazineDto(row))
})

publicRouter.get('/config', publicCache(60, 300), async (_req, res) => {
  res.json(await publicAppConfig())
})
