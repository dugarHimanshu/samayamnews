import { afterAll, beforeAll, describe, expect, it } from 'vitest'
import { sqlClient as sql } from '../src/db/client.js'
import type { AuthUser } from '../src/lib/auth.js'
import { applicationInput, applyAsUser, latestApplicationFor, listApplications, reviewApplication } from '../src/services/applications.js'
import { anyDistricts, cleanup, makeUser } from './helpers.js'

let reader: AuthUser, reader2: AuthUser, admin: AuthUser
let district: { id: number; stateId: number; mandalId: number }

beforeAll(async () => {
  ;[reader, reader2, admin] = await Promise.all([makeUser('reader'), makeUser('reader'), makeUser('admin')])
  ;[district] = (await anyDistricts(1)) as [typeof district]
})

afterAll(async () => {
  await sql`DELETE FROM app.contributor_applications WHERE user_id = ANY(${[reader.id, reader2.id]})`
  await cleanup([reader, reader2, admin].map((u) => u.id))
})

const roleOf = async (id: string) => (await sql`SELECT role FROM app.profiles WHERE id = ${id}`)[0]!.role as string

const form = () => applicationInput.parse({
  role: 'employee' as const,
  fullName: 'Ravi Kumar',
  mobile: '+91 98765-43210',
  email: 'ravi@example.com',
  address: 'Main road',
  districtId: district.id,
  mandalId: district.mandalId,
})

describe('reporter / freelancer registration', () => {
  it('stores a pending application with normalised mobile and derived state', async () => {
    const row = await applyAsUser(reader, form())
    expect(row.status).toBe('pending')
    expect(row.mobile).toBe('9876543210')
    expect(row.stateId).toBe(district.stateId)
    const latest = await latestApplicationFor(reader.id)
    expect(latest?.district?.id).toBe(district.id)
  })

  it('refuses a second open application', async () => {
    await expect(applyAsUser(reader, form())).rejects.toMatchObject({ status: 409 })
  })

  it('rejects a mandal from another district', async () => {
    const [, other] = await anyDistricts(2)
    await expect(applyAsUser(reader2, { ...form(), districtId: other!.id })).rejects.toMatchObject({ status: 400 })
  })

  it('admin approval upgrades the role immediately', async () => {
    const { items } = await listApplications('pending', 50)
    const mine = items.find((a) => a.userId === reader.id)!
    const reviewed = await reviewApplication(admin, mine.id, { approve: true })
    expect(reviewed.status).toBe('approved')
    expect(await roleOf(reader.id)).toBe('employee')
    await expect(reviewApplication(admin, mine.id, { approve: true })).rejects.toMatchObject({ status: 409 })
    // Approved contributors can't apply again
    await expect(applyAsUser({ ...reader, role: 'employee' }, form())).rejects.toMatchObject({ status: 409 })
  })

  it('rejection keeps the reader role and records the reason', async () => {
    const row = await applyAsUser(reader2, { ...form(), role: 'freelancer' as const })
    const reviewed = await reviewApplication(admin, row.id, { approve: false, reason: 'Incomplete details' })
    expect(reviewed.status).toBe('rejected')
    expect(reviewed.rejectionReason).toBe('Incomplete details')
    expect(await roleOf(reader2.id)).toBe('reader')
    // Can re-apply after a rejection
    expect((await applyAsUser(reader2, { ...form(), role: 'freelancer' as const })).status).toBe('pending')
  })
})
