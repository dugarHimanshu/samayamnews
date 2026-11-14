import request from 'supertest'
import { afterAll, beforeAll, describe, expect, it } from 'vitest'
import { sqlClient as sql } from '../src/db/client.js'
import { createApp } from '../src/app.js'
import { anyDistricts, cleanup, TEST_SOURCE } from './helpers.js'

const app = createApp()
let home: { id: number; stateId: number }
let other: { id: number; stateId: number }

async function insertArticle(districtId: number, stateId: number, hoursAgo: number, title: string) {
  await sql`
    INSERT INTO app.articles (title, summary, body, language, category_id, state_id, district_id, author_name, source, published_at)
    VALUES (${title}, 'summary text here', 'body text that is long enough', 'en', 1, ${stateId}, ${districtId}, 'Vitest', ${TEST_SOURCE},
            now() - make_interval(mins => ${Math.round(hoursAgo * 60)}))`
}

async function readWholeFeed(query: string) {
  const titles: string[] = []
  let cursor: string | null = null
  for (let page = 0; page < 50; page++) {
    const res: request.Response = await request(app).get(`/v1/feed?${query}&limit=3${cursor ? `&cursor=${cursor}` : ''}`).expect(200)
    for (const item of res.body.items) if (item.type === 'article' && item.article.source === TEST_SOURCE) titles.push(item.article.title)
    cursor = res.body.nextCursor
    if (!cursor) break
  }
  return titles
}

beforeAll(async () => {
  const ds = await anyDistricts(2)
  home = ds[0]!
  other = ds[1]!
  await cleanup([])
  // home district: 4 recent + 1 old; other district: 4 recent
  for (let i = 1; i <= 4; i++) await insertArticle(home.id, home.stateId, i, `home-recent-${i}`)
  await insertArticle(home.id, home.stateId, 100, 'home-old')
  for (let i = 1; i <= 4; i++) await insertArticle(other.id, other.stateId, i + 0.5, `other-recent-${i}`)
})

afterAll(async () => {
  await cleanup([])
})

describe('GET /v1/feed', () => {
  it('shows the home district’s last-48h news first, then everything else newest-first, with no duplicates', async () => {
    const titles = await readWholeFeed(`district=${home.id}`)
    expect(titles.slice(0, 4)).toEqual(['home-recent-1', 'home-recent-2', 'home-recent-3', 'home-recent-4'])
    const rest = titles.slice(4)
    expect(rest).toEqual(['other-recent-1', 'other-recent-2', 'other-recent-3', 'other-recent-4', 'home-old'])
    expect(new Set(titles).size).toBe(titles.length)
  })

  it('without a district it is plain newest-first', async () => {
    const titles = await readWholeFeed('')
    expect(titles[0]).toBe('home-recent-1')
    expect(titles[1]).toBe('other-recent-1')
    expect(titles).toHaveLength(9)
  })

  it('is cacheable at the CDN', async () => {
    const res = await request(app).get(`/v1/feed?district=${home.id}`).expect(200)
    expect(res.headers['cache-control']).toContain('s-maxage=30')
  })

  it('rejects a tampered cursor', async () => {
    await request(app).get('/v1/feed?cursor=%%%').expect(400)
  })
})
