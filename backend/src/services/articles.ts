import { and, desc, eq, inArray, sql, type SQL } from 'drizzle-orm'
import { db } from '../db/client.js'
import { ads, articleStats, articles, magazines, media } from '../db/schema.js'
import { decodeCursor, encodeCursor } from '../lib/cursor.js'
import { cached } from '../lib/cache.js'
import { mediaUrl } from './storage.js'
import { categoryIndex, feedConfig, locationIndex } from './reference.js'

// ------------------------------------------------------------------ DTOs

type ArticleRow = typeof articles.$inferSelect
type MediaRow = typeof media.$inferSelect

export interface ImageDto {
  thumb: string | null
  medium: string | null
  large: string | null
}

function imageDto(m: Pick<MediaRow, 'variants' | 'status'> | null | undefined): ImageDto | null {
  if (!m || m.status !== 'ready' || !m.variants) return null
  const v = m.variants
  return { thumb: mediaUrl(v['320']), medium: mediaUrl(v['640']), large: mediaUrl(v['1080'] ?? v['640']) }
}

export async function toArticleDtos(
  rows: { article: ArticleRow; cover: Pick<MediaRow, 'variants' | 'status'> | null; likes?: number | null }[],
  opts: { withBody: boolean },
) {
  const [locs, cats] = await Promise.all([locationIndex(), categoryIndex()])
  const loc = (id: number | null) => {
    const l = id ? locs.get(id) : undefined
    return l ? { id: l.id, nameEn: l.nameEn, nameTe: l.nameTe } : null
  }
  return rows.map(({ article: a, cover, likes }) => {
    const c = cats.get(a.categoryId)
    return {
      id: a.id,
      title: a.title,
      summary: a.summary,
      ...(opts.withBody ? { body: a.body } : {}),
      language: a.language,
      category: c ? { id: c.id, slug: c.slug, nameEn: c.nameEn, nameTe: c.nameTe, nameHi: c.nameHi } : null,
      location: { state: loc(a.stateId), district: loc(a.districtId), mandal: loc(a.mandalId), village: loc(a.villageId) },
      image: imageDto(cover),
      authorName: a.authorName,
      source: a.source,
      isBreaking: a.isBreaking,
      publishedAt: a.publishedAt.toISOString(),
      updatedAt: a.updatedAt.toISOString(),
      ...(likes !== undefined ? { likeCount: Number(likes ?? 0) } : {}),
    }
  })
}
export type ArticleDto = Awaited<ReturnType<typeof toArticleDtos>>[number]

const selectArticle = { article: articles, cover: { variants: media.variants, status: media.status } }

async function fetchArticles(where: SQL | undefined, limit: number) {
  return db
    .select(selectArticle)
    .from(articles)
    .leftJoin(media, eq(media.id, articles.coverMediaId))
    .where(where)
    .orderBy(desc(articles.publishedAt), desc(articles.id))
    .limit(limit)
}

const live = eq(articles.status, 'live')
const before = (c?: { t: string; i: string }) =>
  c ? sql`(${articles.publishedAt}, ${articles.id}) < (${c.t}::timestamptz, ${c.i}::uuid)` : undefined

// ------------------------------------------------------------------ home feed (district first)

interface FeedCursor {
  p: 'A' | 'B' // phase: A = home district inside the time window, B = everything else
  ws: string // window start (fixed for the whole scroll session)
  t?: string // last published_at seen in the current phase
  i?: string // last id seen in the current phase
  n: number // articles served so far (keeps ad/magazine slots stable across pages)
}

export async function getFeed(params: { districtId?: number; cursor?: string; limit: number }) {
  const cfg = await feedConfig()
  const cur = decodeCursor<FeedCursor>(params.cursor) ?? {
    p: params.districtId ? 'A' : 'B',
    ws: new Date(Date.now() - cfg.districtWindowHours * 3600_000).toISOString(),
    n: 0,
  }
  const d = params.districtId
  const inWindow = d ? and(eq(articles.districtId, d), sql`${articles.publishedAt} > ${cur.ws}::timestamptz`) : undefined
  const pos = cur.t && cur.i ? { t: cur.t, i: cur.i } : undefined

  const out: Awaited<ReturnType<typeof fetchArticles>> = []
  let phase = cur.p
  let hasMore = true
  let lastInPhase: (typeof out)[number] | undefined

  if (phase === 'A' && d) {
    const rows = await fetchArticles(and(live, inWindow, before(pos)), params.limit + 1)
    out.push(...rows.slice(0, params.limit))
    lastInPhase = out.at(-1)
    if (rows.length <= params.limit) {
      phase = 'B' // district window exhausted — continue with everything else
      lastInPhase = undefined
    }
  }
  if (phase === 'B' && out.length < params.limit) {
    const remaining = params.limit - out.length
    const posB = cur.p === 'B' ? pos : undefined
    const excludeWindow = inWindow ? sql`NOT (${inWindow})` : undefined
    const rows = await fetchArticles(and(live, excludeWindow, before(posB)), remaining + 1)
    const taken = rows.slice(0, remaining)
    out.push(...taken)
    hasMore = rows.length > remaining
    lastInPhase = taken.at(-1)
  }

  // Keep the previous B position if this page added no new B rows.
  const position =
    lastInPhase !== undefined
      ? { t: lastInPhase.article.publishedAt.toISOString(), i: lastInPhase.article.id }
      : phase === cur.p
        ? pos
        : undefined
  const nextCursor = hasMore
    ? encodeCursor({ p: phase, ws: cur.ws, ...(position ?? {}), n: cur.n + out.length } satisfies FeedCursor)
    : null

  const dtos = await toArticleDtos(out, { withBody: false })
  const items = await interleave(dtos, cur.n, cfg)
  return { items, nextCursor }
}

// ------------------------------------------------------------------ ads & magazines in the feed

export async function activeAds() {
  return cached('feed:ads', 60_000, async () => ({
    rows: await db
      .select({ ad: ads, image: { variants: media.variants, status: media.status } })
      .from(ads)
      .leftJoin(media, eq(media.id, ads.imageMediaId))
      .where(
        and(
          eq(ads.isActive, true),
          sql`(${ads.startsAt} IS NULL OR ${ads.startsAt} <= now())`,
          sql`(${ads.endsAt} IS NULL OR ${ads.endsAt} > now())`,
        ),
      )
      .orderBy(desc(ads.weight), desc(ads.createdAt)),
  }))
}

export function adDto({ ad, image }: Awaited<ReturnType<typeof activeAds>>['rows'][number]) {
  return {
    id: ad.id,
    sponsor: ad.sponsor,
    headline: ad.headline,
    description: ad.description,
    tag: ad.tag,
    ctaText: ad.ctaText,
    ctaUrl: ad.ctaUrl,
    imageUrl: imageDto(image)?.medium ?? ad.imageUrl,
  }
}

export async function publishedMagazines() {
  return cached('feed:magazines', 60_000, async () => ({
    rows: await db
      .select({ magazine: magazines, cover: { variants: media.variants, status: media.status } })
      .from(magazines)
      .leftJoin(media, eq(media.id, magazines.coverMediaId))
      .where(eq(magazines.isPublished, true))
      .orderBy(desc(magazines.publishedAt))
      .limit(50),
  }))
}

export async function magazineDto({ magazine: m, cover }: Awaited<ReturnType<typeof publishedMagazines>>['rows'][number]) {
  let pdfUrl = m.pdfUrl
  if (m.pdfMediaId) {
    const pdf = (await db.select({ variants: media.variants }).from(media).where(eq(media.id, m.pdfMediaId)).limit(1))[0]
    pdfUrl = mediaUrl(pdf?.variants?.pdf) ?? pdfUrl
  }
  return {
    id: m.id,
    title: m.title,
    subtitle: m.subtitle,
    issue: m.issue,
    category: m.category,
    coverUrl: imageDto(cover)?.medium ?? m.coverUrl,
    pdfUrl,
    pageCount: m.pageCount,
    publishedAt: m.publishedAt.toISOString(),
  }
}

type FeedItem =
  | { type: 'article'; article: ArticleDto }
  | { type: 'ad'; ad: ReturnType<typeof adDto> }
  | { type: 'magazine'; magazine: Awaited<ReturnType<typeof magazineDto>> }

async function interleave(list: ArticleDto[], servedBefore: number, cfg: Awaited<ReturnType<typeof feedConfig>>) {
  const [adRows, magRows] = await Promise.all([
    cfg.adsEnabled && cfg.adEvery > 0 ? activeAds().then((r) => r.rows) : Promise.resolve([]),
    cfg.magazineEvery > 0 ? publishedMagazines().then((r) => r.rows) : Promise.resolve([]),
  ])
  const items: FeedItem[] = []
  for (const [idx, article] of list.entries()) {
    items.push({ type: 'article', article })
    const n = servedBefore + idx + 1 // 1-based position of this article in the whole feed
    if (magRows.length && n % cfg.magazineEvery === cfg.magazineOffset) {
      const m = magRows[Math.floor(n / cfg.magazineEvery) % magRows.length]!
      items.push({ type: 'magazine', magazine: await magazineDto(m) })
    }
    if (adRows.length && n % cfg.adEvery === 0) {
      items.push({ type: 'ad', ad: adDto(adRows[(n / cfg.adEvery - 1) % adRows.length]!) })
    }
  }
  return items
}

// ------------------------------------------------------------------ other lists

/** Newest-first list with optional filters (category screen, location screen). */
export async function listArticles(params: {
  districtId?: number
  mandalId?: number
  categoryId?: number
  cursor?: string
  limit: number
}) {
  const pos = decodeCursor<{ t: string; i: string }>(params.cursor)
  const where = and(
    live,
    params.districtId ? eq(articles.districtId, params.districtId) : undefined,
    params.mandalId ? eq(articles.mandalId, params.mandalId) : undefined,
    params.categoryId ? eq(articles.categoryId, params.categoryId) : undefined,
    before(pos),
  )
  const rows = await fetchArticles(where, params.limit + 1)
  return page(rows, params.limit)
}

export async function searchArticles(params: { q: string; cursor?: string; limit: number }) {
  const pos = decodeCursor<{ t: string; i: string }>(params.cursor)
  const q = params.q.trim()
  const match = sql`(${articles.search} @@ websearch_to_tsquery('simple', ${q}) OR ${articles.title} ILIKE ${'%' + q.replace(/[%_\\]/g, '\\$&') + '%'})`
  const rows = await fetchArticles(and(live, match, before(pos)), params.limit + 1)
  return page(rows, params.limit)
}

async function page(rows: Awaited<ReturnType<typeof fetchArticles>>, limit: number) {
  const slice = rows.slice(0, limit)
  const last = slice.at(-1)
  return {
    items: await toArticleDtos(slice, { withBody: false }),
    nextCursor: rows.length > limit && last ? encodeCursor({ t: last.article.publishedAt.toISOString(), i: last.article.id }) : null,
  }
}

export async function getArticle(id: string, opts: { includeUnpublished?: boolean } = {}) {
  const rows = await db
    .select({ ...selectArticle, likes: articleStats.likes })
    .from(articles)
    .leftJoin(media, eq(media.id, articles.coverMediaId))
    .leftJoin(articleStats, eq(articleStats.articleId, articles.id))
    .where(and(eq(articles.id, id), opts.includeUnpublished ? undefined : live))
    .limit(1)
  if (!rows[0]) return null
  return (await toArticleDtos(rows, { withBody: true }))[0]!
}

export async function getArticlesByIds(ids: string[]) {
  if (!ids.length) return []
  const rows = await db
    .select(selectArticle)
    .from(articles)
    .leftJoin(media, eq(media.id, articles.coverMediaId))
    .where(and(live, inArray(articles.id, ids)))
  return toArticleDtos(rows, { withBody: false })
}

export async function feedHead(districtId?: number) {
  const latest = await db
    .select({ id: articles.id, publishedAt: articles.publishedAt })
    .from(articles)
    .where(and(live, districtId ? eq(articles.districtId, districtId) : undefined))
    .orderBy(desc(articles.publishedAt), desc(articles.id))
    .limit(1)
  return { latestId: latest[0]?.id ?? null, latestPublishedAt: latest[0]?.publishedAt.toISOString() ?? null }
}
