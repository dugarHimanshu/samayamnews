import { afterAll, beforeAll, describe, expect, it } from 'vitest'
import { sqlClient as sql } from '../src/db/client.js'
import type { AuthUser } from '../src/lib/auth.js'
import { adsForDistrict, getArticle } from '../src/services/articles.js'
import { addComment, deleteComment, listComments, listWishes, reviewWish, submitWish } from '../src/services/community.js'
import { deleteArticle, removeContributor } from '../src/services/moderation.js'
import { anyDistricts, cleanup, makeUser, TEST_SOURCE } from './helpers.js'

let reader: AuthUser, other: AuthUser, editor: AuthUser, admin: AuthUser, reporter: AuthUser
let articleId: string, followUpId: string
let dA: { id: number; stateId: number }, dB: { id: number; stateId: number }
const adIds: string[] = []

async function makeArticle(title: string, d: { id: number; stateId: number }, extra = '') {
  const [a] = await sql`
    INSERT INTO app.articles (title, summary, body, language, category_id, state_id, district_id, author_name, source)
    VALUES (${title}, 'summary text here', ${'body text with Siddipet meeting ' + extra}, 'te', 1, ${d.stateId}, ${d.id}, 'Vitest', ${TEST_SOURCE})
    RETURNING id`
  return a!.id as string
}

beforeAll(async () => {
  ;[reader, other, editor, admin, reporter] = await Promise.all([makeUser('reader'), makeUser('reader'), makeUser('editor'), makeUser('admin'), makeUser('employee')])
  const ds = await anyDistricts(40)
  dA = ds[0]!
  dB = ds.find((d) => d.stateId !== dA.stateId) ?? ds[1]!
  articleId = await makeArticle('Original story', dA)
  followUpId = await makeArticle('Follow-up story', dA)
})

afterAll(async () => {
  if (adIds.length) await sql`DELETE FROM app.ads WHERE id = ANY(${adIds})`
  await sql`DELETE FROM app.wishes WHERE submitted_by = ANY(${[reader.id, editor.id]})`
  await sql`DELETE FROM app.comments WHERE user_id = ANY(${[reader.id, other.id]})`
  await cleanup([reader, other, editor, admin, reporter].map((u) => u.id))
})

describe('comments', () => {
  it('adds, lists and counts comments', async () => {
    const c = await addComment(reader, articleId, 'Great report')
    expect(c.author).toMatch(/^reader-/) // no full name → email prefix
    await addComment(other, articleId, 'Thanks')
    const list = await listComments(articleId, { limit: 20 })
    expect(list.items.map((x) => x.body)).toEqual(['Thanks', 'Great report'])
    expect((await getArticle(articleId))?.commentCount).toBe(2)
  })

  it('only the author or a moderator can delete', async () => {
    const { items } = await listComments(articleId, { limit: 20 })
    const mine = items.find((x) => x.userId === reader.id)!
    await expect(deleteComment(other, mine.id)).rejects.toMatchObject({ status: 403 })
    await deleteComment(editor, mine.id)
    expect((await listComments(articleId, { limit: 20 })).items).toHaveLength(1)
    expect((await getArticle(articleId))?.commentCount).toBe(1)
  })
})

describe('wishes', () => {
  it('reader wishes wait for review; editor wishes publish directly', async () => {
    const w = await submitWish(reader, { kind: 'birthday', recipientName: 'Ravi', message: 'Happy birthday!', fromNames: 'Family' })
    expect(w.status).toBe('pending')
    expect((await listWishes({ status: 'approved', limit: 50 })).items.some((x) => x.id === w.id)).toBe(false)
    await reviewWish(editor, w.id, { approve: true })
    expect((await listWishes({ status: 'approved', kind: 'birthday', limit: 50 })).items.some((x) => x.id === w.id)).toBe(true)
    const e = await submitWish(editor, { kind: 'anniversary', recipientName: 'Sita & Ram', message: 'Happy anniversary', fromNames: 'Friends' })
    expect(e.status).toBe('approved')
  })
})

describe('location-targeted ads', () => {
  it('shows all-, state- and district-wide ads only to the right readers', async () => {
    const rows = await sql`
      INSERT INTO app.ads (sponsor, headline, target_scope, target_state_id, target_district_id) VALUES
        ('V', 'everywhere ad', 'all', NULL, NULL),
        ('V', 'state ad', 'state', ${dA.stateId}, NULL),
        ('V', 'district ad', 'district', ${dA.stateId}, ${dA.id})
      RETURNING id`
    adIds.push(...rows.map((r) => r.id as string))
    const { invalidate } = await import('../src/lib/cache.js')
    invalidate('feed:')
    const headlines = async (d?: number) => (await adsForDistrict(d)).map((r) => r.ad.headline).filter((h) => h.endsWith(' ad'))
    expect(await headlines(dA.id)).toEqual(expect.arrayContaining(['everywhere ad', 'state ad', 'district ad']))
    const inB = await headlines(dB.id)
    expect(inB).toContain('everywhere ad')
    expect(inB).not.toContain('district ad')
    if (dB.stateId !== dA.stateId) expect(inB).not.toContain('state ad')
  })
})

describe('admin moderation', () => {
  it('permanently deletes an article and clears links to it', async () => {
    await sql`UPDATE app.articles SET related_article_id = ${articleId}, related_anchor = 'Siddipet' WHERE id = ${followUpId}`
    await deleteArticle(admin, articleId)
    expect(await getArticle(articleId, { includeUnpublished: true })).toBeNull()
    expect((await getArticle(followUpId))?.relatedArticleId).toBeNull()
    await expect(deleteArticle(admin, articleId)).rejects.toMatchObject({ status: 404 })
  })

  it('removing a reporter disables the account but keeps their published news', async () => {
    const [s] = await sql`
      INSERT INTO app.submissions (submitter_id, title, summary, body, language, category_id, state_id, district_id, author_name)
      VALUES (${reporter.id}, 'pending story', 'summary text here', 'body text long enough', 'te', 1, ${dA.stateId}, ${dA.id}, 'R') RETURNING id`
    await removeContributor(admin, reporter.id).catch((e: Error) => {
      // Local test users are inserted straight into auth.users, so the auth-server ban may fail; the DB part must still apply.
      if (!/sign-in block failed/.test(e.message)) throw e
    })
    const [p] = await sql`SELECT role, disabled_at FROM app.profiles WHERE id = ${reporter.id}`
    expect(p!.role).toBe('reader')
    expect(p!.disabled_at).not.toBeNull()
    const [sub] = await sql`SELECT status FROM app.submissions WHERE id = ${s!.id}`
    expect(sub!.status).toBe('rejected')
    expect((await getArticle(followUpId))?.id).toBe(followUpId)
    await expect(removeContributor(admin, editor.id)).rejects.toMatchObject({ status: 400 })
  })
})
