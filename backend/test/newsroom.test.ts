import { afterAll, beforeAll, describe, expect, it } from 'vitest'
import { sqlClient as sql } from '../src/db/client.js'
import type { AuthUser } from '../src/lib/auth.js'
import {
  claimSubmission,
  createSubmission,
  FREELANCER_DAILY_LIMIT,
  heartbeat,
  mySubmission,
  publishSubmission,
  rejectSubmission,
  saveDraft,
  submissionQuota,
} from '../src/services/newsroom.js'
import { anyDistricts, cleanup, makeUser, TEST_SOURCE } from './helpers.js'

let freelancer: AuthUser, employee: AuthUser, editorA: AuthUser, editorB: AuthUser
let story: Parameters<typeof createSubmission>[1]

beforeAll(async () => {
  ;[freelancer, employee, editorA, editorB] = await Promise.all([makeUser('freelancer'), makeUser('employee'), makeUser('editor'), makeUser('editor')])
  const [d] = await anyDistricts(1)
  story = {
    title: 'Test story title',
    summary: 'A short summary of the test story',
    body: 'The body of the story, long enough to pass validation.',
    language: 'en',
    categoryId: 1,
    stateId: d!.stateId,
    districtId: d!.id,
    mandalId: d!.mandalId,
    authorName: 'Vitest Reporter',
    source: TEST_SOURCE,
  }
})

afterAll(async () => {
  await sql`DELETE FROM app.articles WHERE submission_id IN (SELECT id FROM app.submissions WHERE submitter_id = ANY(${[freelancer.id, employee.id]}))`
  await cleanup([freelancer, employee, editorA, editorB].map((u) => u.id))
})

describe('submissions', () => {
  it(`limits freelancers to ${FREELANCER_DAILY_LIMIT} per IST day, even under concurrency`, async () => {
    const results = await Promise.allSettled(Array.from({ length: FREELANCER_DAILY_LIMIT + 3 }, () => createSubmission(freelancer, story)))
    expect(results.filter((r) => r.status === 'fulfilled')).toHaveLength(FREELANCER_DAILY_LIMIT)
    expect(results.filter((r) => r.status === 'rejected')).toHaveLength(3)
    expect(await submissionQuota(freelancer)).toMatchObject({ used: FREELANCER_DAILY_LIMIT, remaining: 0 })
  })

  it('does not limit employees', async () => {
    for (let i = 0; i < FREELANCER_DAILY_LIMIT + 1; i++) await createSubmission(employee, story)
    expect((await submissionQuota(employee)).limited).toBe(false)
  })

  it('rejects a mandal that is not inside the chosen district', async () => {
    await expect(createSubmission(employee, { ...story, mandalId: 999999999 })).rejects.toThrow(/mandal/i)
  })
})

describe('editor workflow', () => {
  it('lets only one editor claim a story at a time', async () => {
    const s = await createSubmission(employee, story)
    const [a, b] = await Promise.allSettled([claimSubmission(editorA, s.id), claimSubmission(editorB, s.id)])
    expect([a.status, b.status].sort()).toEqual(['fulfilled', 'rejected'])
  })

  it('claim → edit → publish creates exactly one live article', async () => {
    const s = await createSubmission(employee, story)
    const claimed = await claimSubmission(editorA, s.id)
    await expect(claimSubmission(editorB, s.id)).rejects.toThrow(/another editor/i)
    await heartbeat(editorA, s.id)
    const edited = await saveDraft(editorA, s.id, claimed.version, { title: 'Edited headline for test' })
    // stale version is refused (optimistic locking)
    await expect(saveDraft(editorA, s.id, claimed.version, { title: 'Stale edit' })).rejects.toThrow(/changed elsewhere/i)
    const article = await publishSubmission(editorA, s.id, { version: edited.version, isBreaking: false })
    expect(article.title).toBe('Edited headline for test')
    // publishing twice is impossible
    await expect(publishSubmission(editorA, s.id, { version: edited.version + 1, isBreaking: false })).rejects.toThrow()
    const [{ n }] = (await sql`SELECT count(*)::int AS n FROM app.articles WHERE submission_id = ${s.id}`) as unknown as [{ n: number }]
    expect(n).toBe(1)
  })

  it('an expired claim can be taken over by another editor', async () => {
    const s = await createSubmission(employee, story)
    await claimSubmission(editorA, s.id)
    await sql`UPDATE app.submissions SET claim_expires_at = now() - interval '1 minute' WHERE id = ${s.id}`
    await expect(claimSubmission(editorB, s.id)).resolves.toMatchObject({ claimedBy: editorB.id })
  })

  it('rejection reason reaches the submitter without the editor identity', async () => {
    const s = await createSubmission(employee, story)
    await claimSubmission(editorA, s.id)
    await rejectSubmission(editorA, s.id, 'Please add a second source.')
    const mine = await mySubmission(employee, s.id)
    expect(mine.status).toBe('rejected')
    expect(mine.rejectionReason).toBe('Please add a second source.')
    expect(JSON.stringify(mine)).not.toContain(editorA.id)
  })
})
