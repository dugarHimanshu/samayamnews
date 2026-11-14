import { sql } from 'drizzle-orm'
import { db } from '../db/client.js'
import { logger } from '../lib/logger.js'

/**
 * View / share / ad counters are buffered in memory and written in one batched UPSERT
 * every 30 seconds, so thousands of concurrent readers never hit Postgres row by row.
 */
const articleViews = new Map<string, number>()
const articleShares = new Map<string, number>()
const adImpressions = new Map<string, number>()
const adClicks = new Map<string, number>()

const bump = (m: Map<string, number>, k: string, by = 1) => m.set(k, (m.get(k) ?? 0) + by)

export function recordEvent(e: { type: 'view' | 'share' | 'ad_impression' | 'ad_click'; id: string }) {
  if (e.type === 'view') bump(articleViews, e.id)
  else if (e.type === 'share') bump(articleShares, e.id)
  else if (e.type === 'ad_impression') bump(adImpressions, e.id)
  else bump(adClicks, e.id)
}

function drain(m: Map<string, number>) {
  const entries = [...m.entries()]
  m.clear()
  return entries
}

export async function flushCounters() {
  const views = drain(articleViews)
  const shares = drain(articleShares)
  const imps = drain(adImpressions)
  const clicks = drain(adClicks)
  try {
    const articleRows = new Map<string, { v: number; s: number }>()
    for (const [id, v] of views) articleRows.set(id, { v, s: 0 })
    for (const [id, s] of shares) articleRows.set(id, { v: articleRows.get(id)?.v ?? 0, s })
    if (articleRows.size) {
      const json = JSON.stringify([...articleRows].map(([id, r]) => ({ id, v: r.v, s: r.s })))
      // Unknown ids are ignored via the JOIN so a bad client can't create junk rows.
      await db.execute(sql`
        INSERT INTO app.article_stats (article_id, views, shares)
        SELECT a.id, x.v, x.s FROM jsonb_to_recordset(${json}::jsonb) AS x(id uuid, v bigint, s bigint)
        JOIN app.articles a ON a.id = x.id
        ON CONFLICT (article_id) DO UPDATE
          SET views = app.article_stats.views + EXCLUDED.views, shares = app.article_stats.shares + EXCLUDED.shares`)
    }
    const adRows = new Map<string, { i: number; c: number }>()
    for (const [id, i] of imps) adRows.set(id, { i, c: 0 })
    for (const [id, c] of clicks) adRows.set(id, { i: adRows.get(id)?.i ?? 0, c })
    if (adRows.size) {
      const json = JSON.stringify([...adRows].map(([id, r]) => ({ id, i: r.i, c: r.c })))
      await db.execute(sql`
        INSERT INTO app.ad_stats_daily (ad_id, day, impressions, clicks)
        SELECT a.id, (now() AT TIME ZONE 'Asia/Kolkata')::date, x.i, x.c
        FROM jsonb_to_recordset(${json}::jsonb) AS x(id uuid, i bigint, c bigint)
        JOIN app.ads a ON a.id = x.id
        ON CONFLICT (ad_id, day) DO UPDATE
          SET impressions = app.ad_stats_daily.impressions + EXCLUDED.impressions,
              clicks = app.ad_stats_daily.clicks + EXCLUDED.clicks`)
    }
  } catch (err) {
    logger.error({ err }, 'Counter flush failed; counts from this window are dropped')
  }
}

let timer: NodeJS.Timeout | null = null
export function startCounterFlush(intervalMs = 30_000) {
  timer ??= setInterval(() => void flushCounters(), intervalMs)
  timer.unref()
}
export async function stopCounterFlush() {
  if (timer) clearInterval(timer)
  timer = null
  await flushCounters()
}
