import { drizzle } from 'drizzle-orm/postgres-js'
import postgres from 'postgres'
import { config } from '../config.js'
import * as schema from './schema.js'

// `prepare: false` is required behind Supabase's Supavisor pooler in transaction mode.
export const sqlClient = postgres(config.DATABASE_URL, {
  max: config.DATABASE_POOL_MAX,
  prepare: false,
  idle_timeout: 20,
})

export const db = drizzle(sqlClient, { schema })
export type DB = typeof db
export type Tx = Parameters<Parameters<DB['transaction']>[0]>[0]
