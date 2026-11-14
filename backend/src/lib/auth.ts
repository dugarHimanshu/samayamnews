import type { RequestHandler } from 'express'
import { eq } from 'drizzle-orm'
import { createRemoteJWKSet, jwtVerify, type JWTPayload } from 'jose'
import { LRUCache } from 'lru-cache'
import { config } from '../config.js'
import { db } from '../db/client.js'
import { profiles } from '../db/schema.js'
import { forbidden, unauthorized } from './errors.js'

export type Role = (typeof profiles.$inferSelect)['role']
export interface AuthUser {
  id: string
  email: string | null
  role: Role
}

declare global {
  // eslint-disable-next-line @typescript-eslint/no-namespace
  namespace Express {
    interface Request {
      user?: AuthUser
    }
  }
}

const hsSecret = config.SUPABASE_JWT_SECRET ? new TextEncoder().encode(config.SUPABASE_JWT_SECRET) : null
const jwks = createRemoteJWKSet(new URL('/auth/v1/.well-known/jwks.json', config.SUPABASE_URL))

/** Verifies a Supabase access token offline (HS256 secret if configured, otherwise the project's JWKS). */
export async function verifyAccessToken(token: string): Promise<JWTPayload> {
  const options = { audience: 'authenticated' }
  if (hsSecret) {
    try {
      return (await jwtVerify(token, hsSecret, options)).payload
    } catch (err) {
      // Projects migrated to asymmetric signing keys may issue both kinds; fall through to JWKS.
      if (!(err instanceof Error) || !/alg|signature/i.test(err.message)) throw err
    }
  }
  return (await jwtVerify(token, jwks, options)).payload
}

// Role lookups are cached briefly so we hit the database at most once per user per 30s per instance.
const profileCache = new LRUCache<string, AuthUser>({ max: 20_000, ttl: 30_000 })

export function forgetUser(userId: string) {
  profileCache.delete(userId)
}

async function loadUser(id: string, email: string | null): Promise<AuthUser> {
  const hit = profileCache.get(id)
  if (hit) return hit
  let row = (await db.select().from(profiles).where(eq(profiles.id, id)).limit(1))[0]
  if (!row) {
    // Safety net if the auth trigger hasn't created the profile yet.
    row = (await db.insert(profiles).values({ id, email }).onConflictDoNothing().returning())[0]
    row ??= (await db.select().from(profiles).where(eq(profiles.id, id)).limit(1))[0]
  }
  if (!row || row.deletedAt) throw unauthorized('Account not found')
  const user: AuthUser = { id, email: row.email ?? email, role: row.role }
  profileCache.set(id, user)
  return user
}

function bearer(header: string | undefined): string | null {
  if (!header?.startsWith('Bearer ')) return null
  return header.slice(7).trim() || null
}

/** Attaches req.user when a valid token is present; never rejects. */
export const optionalAuth: RequestHandler = async (req, _res, next) => {
  const token = bearer(req.headers.authorization)
  if (!token) return next()
  try {
    const payload = await verifyAccessToken(token)
    if (payload.sub) req.user = await loadUser(payload.sub, (payload.email as string) ?? null)
  } catch {
    // ignore invalid tokens on optional routes
  }
  next()
}

/** Requires a valid token. */
export const requireAuth: RequestHandler = async (req, _res, next) => {
  const token = bearer(req.headers.authorization)
  if (!token) return next(unauthorized())
  try {
    const payload = await verifyAccessToken(token)
    if (!payload.sub) return next(unauthorized('Invalid token'))
    req.user = await loadUser(payload.sub, (payload.email as string) ?? null)
    next()
  } catch (err) {
    next(err instanceof Error && 'status' in err ? err : unauthorized('Invalid or expired token'))
  }
}

/** Requires one of the given roles (admins pass every role check). */
export const requireRole =
  (...roles: Role[]): RequestHandler =>
  (req, _res, next) => {
    const role = req.user?.role
    if (!role) return next(unauthorized())
    if (role === 'admin' || roles.includes(role)) return next()
    next(forbidden())
  }

export const CONTRIBUTOR_ROLES: Role[] = ['freelancer', 'employee', 'editor']
