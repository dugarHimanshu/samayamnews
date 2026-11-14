import { randomUUID } from 'node:crypto'
import { sqlClient as sql } from '../src/db/client.js'
import type { AuthUser, Role } from '../src/lib/auth.js'

export const TEST_SOURCE = '__vitest__'

/** Creates an auth user + profile directly in the local database. */
export async function makeUser(role: Role): Promise<AuthUser> {
  const id = randomUUID()
  const email = `${role}-${id.slice(0, 8)}@vitest.local`
  await sql`INSERT INTO auth.users (id, email, aud, role, instance_id) VALUES (${id}, ${email}, 'authenticated', 'authenticated', '00000000-0000-0000-0000-000000000000')`
  await sql`INSERT INTO app.profiles (id, email, role, full_name) VALUES (${id}, ${email}, ${role}, ${'Vitest ' + role}) ON CONFLICT (id) DO UPDATE SET role = EXCLUDED.role`
  return { id, email, role }
}

export async function anyDistricts(n: number) {
  const rows = await sql`
    SELECT d.id, d.state_id, (SELECT m.id FROM app.locations m WHERE m.parent_id = d.id AND m.level = 'mandal' LIMIT 1) AS mandal_id
    FROM app.locations d WHERE d.level = 'district' ORDER BY d.id LIMIT ${n}`
  return rows.map((r) => ({ id: r.id as number, stateId: r.state_id as number, mandalId: r.mandal_id as number }))
}

export async function cleanup(userIds: string[]) {
  await sql`DELETE FROM app.articles WHERE source = ${TEST_SOURCE}`
  if (userIds.length) {
    await sql`DELETE FROM app.submissions WHERE submitter_id = ANY(${userIds})`
    await sql`DELETE FROM app.profiles WHERE id = ANY(${userIds})`
    await sql`DELETE FROM auth.users WHERE id = ANY(${userIds})`
  }
}
