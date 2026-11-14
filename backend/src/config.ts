import 'dotenv/config'
import { z } from 'zod'

const bool = z
  .string()
  .optional()
  .transform((v) => v === 'true' || v === '1')

const schema = z.object({
  NODE_ENV: z.enum(['development', 'test', 'production']).default('development'),
  PORT: z.coerce.number().default(4000),
  LOG_LEVEL: z.string().default('info'),
  CORS_ORIGINS: z.string().default(''),
  DATABASE_URL: z.string().min(1, 'DATABASE_URL is required'),
  DATABASE_POOL_MAX: z.coerce.number().default(10),
  SUPABASE_URL: z.string().url(),
  SUPABASE_SERVICE_ROLE_KEY: z.string().default(''),
  SUPABASE_JWT_SECRET: z.string().default(''),
  WORKER_INLINE: bool,
  TRUST_PROXY: z.coerce.number().int().min(0).default(1),
  // Feed tuning (can also be overridden at runtime through app_config)
  FEED_DISTRICT_WINDOW_HOURS: z.coerce.number().default(48),
})

const parsed = schema.safeParse(process.env)
if (!parsed.success) {
  console.error('Invalid environment configuration:', parsed.error.flatten().fieldErrors)
  process.exit(1)
}

export const config = parsed.data
export const isProd = config.NODE_ENV === 'production'
