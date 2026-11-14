import { eq } from 'drizzle-orm'
import sharp, { type Metadata } from 'sharp'
import { db } from '../db/client.js'
import { bookmarks, devices, likes, media, profiles } from '../db/schema.js'
import { logger } from '../lib/logger.js'
import type { DeleteAccountJob, ProcessMediaJob, SendPushJob } from '../services/jobs.js'
import { MEDIA_BUCKET, RAW_BUCKET, supabaseAdmin } from '../services/storage.js'

const WIDTHS = [320, 640, 1080] as const

/** Resize to WebP variants and strip all metadata (EXIF/GPS) so reporters' locations never leak. */
export async function processMedia({ mediaId }: ProcessMediaJob) {
  const m = (await db.select().from(media).where(eq(media.id, mediaId)).limit(1))[0]
  if (!m || m.status === 'ready') return
  const storage = supabaseAdmin().storage
  const { data: blob, error } = await storage.from(RAW_BUCKET).download(m.rawKey)
  if (error || !blob) throw new Error(`Download failed for ${m.rawKey}: ${error?.message}`)
  const input = Buffer.from(await blob.arrayBuffer())

  if (m.kind === 'pdf') {
    if (input.subarray(0, 5).toString() !== '%PDF-') return fail(mediaId, 'Not a valid PDF file')
    const key = `${mediaId}/document.pdf`
    const up = await storage.from(MEDIA_BUCKET).upload(key, input, { contentType: 'application/pdf', upsert: true })
    if (up.error) throw new Error(up.error.message)
    await db.update(media).set({ status: 'ready', variants: { pdf: key }, error: null }).where(eq(media.id, mediaId))
    return
  }

  let meta: Metadata
  try {
    meta = await sharp(input).metadata()
  } catch {
    return fail(mediaId, 'File is not a readable image')
  }
  const variants: Record<string, string> = {}
  for (const width of WIDTHS) {
    // .rotate() applies EXIF orientation; sharp drops all metadata by default on output.
    const out = await sharp(input).rotate().resize({ width, withoutEnlargement: true }).webp({ quality: 78 }).toBuffer()
    const key = `${mediaId}/${width}.webp`
    const up = await storage
      .from(MEDIA_BUCKET)
      .upload(key, out, { contentType: 'image/webp', upsert: true, cacheControl: '31536000' })
    if (up.error) throw new Error(up.error.message)
    variants[String(width)] = key
  }
  await db
    .update(media)
    .set({ status: 'ready', variants, width: meta.width ?? null, height: meta.height ?? null, error: null })
    .where(eq(media.id, mediaId))
  // The raw original (which may contain GPS EXIF) is no longer needed.
  await storage.from(RAW_BUCKET).remove([m.rawKey])
}

async function fail(mediaId: string, reason: string) {
  await db.update(media).set({ status: 'failed', error: reason }).where(eq(media.id, mediaId))
}

/** Anonymise the profile, drop personal reader data, remove the auth user. Submissions are kept (editorial record). */
export async function deleteAccount({ userId }: DeleteAccountJob) {
  await db.delete(bookmarks).where(eq(bookmarks.userId, userId))
  await db.delete(likes).where(eq(likes.userId, userId))
  await db.delete(devices).where(eq(devices.userId, userId))
  await db
    .update(profiles)
    .set({ email: null, fullName: 'Deleted user', homeDistrictId: null, deletedAt: new Date() })
    .where(eq(profiles.id, userId))
  // shouldSoftDelete keeps auth.users row (so FK from profiles survives) but makes the login unusable.
  const { error } = await supabaseAdmin().auth.admin.deleteUser(userId, true)
  if (error && !/not found/i.test(error.message)) throw new Error(error.message)
}

/** Push via Firebase topics. Firebase isn't configured yet, so this logs until credentials are provided. */
export async function sendPush(job: SendPushJob) {
  logger.info({ job }, 'Push notification queued (Firebase not configured yet — skipping send)')
}
