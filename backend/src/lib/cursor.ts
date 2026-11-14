import { badRequest } from './errors.js'

/** Opaque keyset cursors: base64url(JSON). */
export function encodeCursor(value: Record<string, unknown>): string {
  return Buffer.from(JSON.stringify(value)).toString('base64url')
}

export function decodeCursor<T>(raw: string | undefined): T | undefined {
  if (!raw) return undefined
  try {
    return JSON.parse(Buffer.from(raw, 'base64url').toString('utf8')) as T
  } catch {
    throw badRequest('Invalid cursor')
  }
}
