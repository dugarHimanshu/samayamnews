import { createClient, type SupabaseClient } from '@supabase/supabase-js'
import { config } from '../config.js'

export const RAW_BUCKET = 'raw' // private: original uploads, never served directly
export const MEDIA_BUCKET = 'media' // public: processed WebP images and PDFs

let admin: SupabaseClient | null = null

/** Service-role Supabase client (server-side only). */
export function supabaseAdmin(): SupabaseClient {
  if (!config.SUPABASE_SERVICE_ROLE_KEY) throw new Error('SUPABASE_SERVICE_ROLE_KEY is not configured')
  admin ??= createClient(config.SUPABASE_URL, config.SUPABASE_SERVICE_ROLE_KEY, {
    auth: { persistSession: false, autoRefreshToken: false },
  })
  return admin
}

const publicBase = (process.env.PUBLIC_MEDIA_BASE_URL || `${config.SUPABASE_URL}/storage/v1/object/public/${MEDIA_BUCKET}`).replace(/\/$/, '')

/** Public URL for a processed media key (served through Cloudflare in production via PUBLIC_MEDIA_BASE_URL). */
export function mediaUrl(key: string | null | undefined): string | null {
  return key ? `${publicBase}/${key}` : null
}
