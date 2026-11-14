import { LRUCache } from 'lru-cache'
import type { RequestHandler } from 'express'

/** Small per-instance cache for hot, user-independent data (feed first pages, config, categories). */
const cache = new LRUCache<string, object>({ max: 2000 })

export async function cached<T extends object>(key: string, ttlMs: number, load: () => Promise<T>): Promise<T> {
  const hit = cache.get(key) as T | undefined
  if (hit) return hit
  const value = await load()
  cache.set(key, value, { ttl: ttlMs })
  return value
}

export function invalidate(prefix: string) {
  for (const key of cache.keys()) if (key.startsWith(prefix)) cache.delete(key)
}

/** Public, CDN-cacheable response (Cloudflare honours s-maxage). */
export const publicCache =
  (sMaxAge: number, swr = sMaxAge * 4): RequestHandler =>
  (_req, res, next) => {
    res.setHeader('Cache-Control', `public, max-age=0, s-maxage=${sMaxAge}, stale-while-revalidate=${swr}`)
    next()
  }

export const noStore: RequestHandler = (_req, res, next) => {
  res.setHeader('Cache-Control', 'private, no-store')
  next()
}
