import { drizzle } from 'drizzle-orm/postgres-js'
import { migrate } from 'drizzle-orm/postgres-js/migrator'
import postgres from 'postgres'
import 'dotenv/config'
import { fileURLToPath } from 'node:url'

const url = process.env.DATABASE_URL
if (!url) throw new Error('DATABASE_URL is required')

const client = postgres(url, { max: 1, prepare: false })
await migrate(drizzle(client), { migrationsFolder: fileURLToPath(new URL('../../drizzle', import.meta.url))})
await client.end()
console.log('Migrations applied')
