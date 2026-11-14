/**
 * Creates one test account per role. The password comes from TEST_USER_PASSWORD in .env — it is never
 * stored in the repo or the app. Re-running resets the password and role.
 */
import postgres from 'postgres'
import 'dotenv/config'
import { supabaseAdmin } from '../src/services/storage.js'

const password = process.env.TEST_USER_PASSWORD
if (!password || password.length < 10) throw new Error('Set TEST_USER_PASSWORD (10+ characters) in .env first')
const domain = process.env.TEST_USER_EMAIL_DOMAIN || 'samayam.test'

const users = [
  { role: 'admin', name: 'Test Admin' },
  { role: 'editor', name: 'Test Editor' },
  { role: 'employee', name: 'Test Staff Reporter' },
  { role: 'freelancer', name: 'Test Freelancer' },
  { role: 'reader', name: 'Test Reader' },
] as const

const admin = supabaseAdmin().auth.admin
const sql = postgres(process.env.DATABASE_URL!, { max: 1, prepare: false })
const existing = (await admin.listUsers({ perPage: 1000 })).data?.users ?? []

for (const u of users) {
  const email = `${u.role}@${domain}`
  let id = existing.find((x) => x.email === email)?.id
  if (id) {
    const { error } = await admin.updateUserById(id, { password, email_confirm: true, user_metadata: { full_name: u.name } })
    if (error) throw error
  } else {
    const { data, error } = await admin.createUser({ email, password, email_confirm: true, user_metadata: { full_name: u.name } })
    if (error) throw error
    id = data.user.id
  }
  await sql`
    INSERT INTO app.profiles (id, email, full_name, role) VALUES (${id}, ${email}, ${u.name}, ${u.role})
    ON CONFLICT (id) DO UPDATE SET role = EXCLUDED.role, full_name = EXCLUDED.full_name, email = EXCLUDED.email, deleted_at = NULL`
  console.log(`  ${u.role.padEnd(10)} ${email}`)
}
await sql.end()
console.log('Test users ready (password = TEST_USER_PASSWORD from .env).')
process.exit(0)
