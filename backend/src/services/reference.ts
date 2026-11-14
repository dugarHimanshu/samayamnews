import { asc, eq } from 'drizzle-orm'
import { cached } from '../lib/cache.js'
import { db } from '../db/client.js'
import { appConfig, categories, locations } from '../db/schema.js'

export type LocationRow = typeof locations.$inferSelect
export type CategoryRow = typeof categories.$inferSelect

/** All ~30k locations held in memory (≈ a few MB) for fast name lookups. Refreshed every 10 minutes. */
export async function locationIndex(): Promise<Map<number, LocationRow>> {
  const rows = await cached('ref:locations', 10 * 60_000, async () => ({
    rows: await db.select().from(locations),
  }))
  // Rebuild the map lazily per cache generation
  return mapFor(rows.rows)
}

const mapCache = new WeakMap<LocationRow[], Map<number, LocationRow>>()
function mapFor(rows: LocationRow[]) {
  let m = mapCache.get(rows)
  if (!m) {
    m = new Map(rows.map((r) => [r.id, r]))
    mapCache.set(rows, m)
  }
  return m
}

export async function categoryIndex(): Promise<Map<number, CategoryRow>> {
  const { rows } = await cached('ref:categories', 5 * 60_000, async () => ({
    rows: await db.select().from(categories).where(eq(categories.isActive, true)).orderBy(asc(categories.sortOrder)),
  }))
  return new Map(rows.map((r) => [r.id, r]))
}

export interface FeedConfig {
  adEvery: number // insert an ad after every N articles (0 = off)
  magazineEvery: number // insert a magazine every N articles (0 = off)
  magazineOffset: number // ...at this position inside each block
  districtWindowHours: number
  adsEnabled: boolean
}

const DEFAULT_FEED: FeedConfig = { adEvery: 5, magazineEvery: 10, magazineOffset: 3, districtWindowHours: 48, adsEnabled: true }

export async function feedConfig(): Promise<FeedConfig> {
  return cached('ref:config:feed', 30_000, async () => {
    const row = (await db.select().from(appConfig).where(eq(appConfig.key, 'feed')).limit(1))[0]
    return { ...DEFAULT_FEED, ...((row?.value as Partial<FeedConfig>) ?? {}) }
  })
}

export async function publicAppConfig(): Promise<Record<string, unknown>> {
  return cached('ref:config:public', 30_000, async () => {
    const rows = await db.select().from(appConfig)
    const out: Record<string, unknown> = {}
    for (const r of rows) if (!r.key.startsWith('private.')) out[r.key] = r.value
    return out
  })
}
