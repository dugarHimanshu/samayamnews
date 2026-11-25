import { Router } from 'express'
import { eq } from 'drizzle-orm'
import { z } from 'zod'
import { db } from '../db/client.js'
import { media } from '../db/schema.js'
import { CONTRIBUTOR_ROLES, requireAuth, requireRole } from '../lib/auth.js'
import { noStore } from '../lib/cache.js'
import { badRequest, forbidden, notFound } from '../lib/errors.js'
import { limitSchema, parseBody, parseParams, parseQuery, uuidParam } from '../lib/validate.js'
import { getArticle } from '../services/articles.js'
import { enqueue, QUEUES } from '../services/jobs.js'
import {
  articleEdit,
  claimSubmission,
  createSubmission,
  editorQueue,
  editorStats,
  editorSubmission,
  heartbeat,
  mySubmission,
  mySubmissions,
  publishSubmission,
  rejectSubmission,
  releaseClaim,
  saveDraft,
  setArticleStatus,
  storyFields,
  submissionQuota,
  updateArticle,
} from '../services/newsroom.js'
import { RAW_BUCKET, supabaseAdmin } from '../services/storage.js'

export const newsroomRouter = Router()
newsroomRouter.use(noStore)

const cursorQuery = z.object({ cursor: z.string().max(500).optional(), limit: limitSchema })

// ------------------------------------------------------------------ uploads (signed URL → direct to storage)

const IMAGE_TYPES: Record<string, string> = { 'image/jpeg': 'jpg', 'image/png': 'png', 'image/webp': 'webp', 'image/heic': 'heic' }
const MAX_IMAGE_BYTES = 10 * 1024 * 1024
const MAX_PDF_BYTES = 50 * 1024 * 1024
const VIDEO_TYPES: Record<string, string> = { 'video/mp4': 'mp4', 'video/quicktime': 'mov', 'video/webm': 'webm', 'video/3gpp': '3gp' }
const MAX_VIDEO_BYTES = 50 * 1024 * 1024 // matches the storage bucket's per-file limit

// Photos: any signed-in user (readers attach one to birthday/anniversary wishes). Videos: newsroom only.
newsroomRouter.post('/uploads', requireAuth, async (req, res) => {
  const body = parseBody(
    req,
    z.object({ kind: z.enum(['image', 'pdf', 'video']), contentType: z.string(), sizeBytes: z.number().int().positive() }),
  )
  let ext: string
  if (body.kind === 'image') {
    ext = IMAGE_TYPES[body.contentType] ?? ''
    if (!ext) throw badRequest('Images must be JPEG, PNG, WebP or HEIC')
    if (body.sizeBytes > MAX_IMAGE_BYTES) throw badRequest('Images must be 10 MB or smaller')
  } else if (body.kind === 'video') {
    if (![...CONTRIBUTOR_ROLES, 'admin'].includes(req.user!.role)) throw forbidden('Only reporters can upload videos')
    ext = VIDEO_TYPES[body.contentType] ?? ''
    if (!ext) throw badRequest('Videos must be MP4, MOV, WebM or 3GP')
    if (body.sizeBytes > MAX_VIDEO_BYTES) throw badRequest('Videos must be 50 MB or smaller')
  } else {
    if (req.user!.role !== 'admin') throw forbidden('Only admins can upload PDFs')
    if (body.contentType !== 'application/pdf') throw badRequest('Expected application/pdf')
    if (body.sizeBytes > MAX_PDF_BYTES) throw badRequest('PDFs must be 50 MB or smaller')
    ext = 'pdf'
  }
  const [m] = await db
    .insert(media)
    .values({ ownerId: req.user!.id, kind: body.kind, rawKey: 'pending', contentType: body.contentType, sizeBytes: body.sizeBytes })
    .returning()
  const rawKey = `${req.user!.id}/${m!.id}.${ext}`
  await db.update(media).set({ rawKey }).where(eq(media.id, m!.id))
  const { data, error } = await supabaseAdmin().storage.from(RAW_BUCKET).createSignedUploadUrl(rawKey)
  if (error || !data) throw new Error(`Could not create upload URL: ${error?.message}`)
  res.status(201).json({ mediaId: m!.id, bucket: RAW_BUCKET, path: data.path, token: data.token, uploadUrl: data.signedUrl })
})

/** Called after the file has been uploaded to the signed URL: queues resizing / EXIF stripping. */
newsroomRouter.post('/uploads/:id/complete', requireAuth, async (req, res) => {
  const { id } = parseParams(req, uuidParam)
  const m = (await db.select().from(media).where(eq(media.id, id)).limit(1))[0]
  if (!m || m.ownerId !== req.user!.id) throw notFound('Upload not found')
  await enqueue(QUEUES.processMedia, { mediaId: id })
  res.status(202).json({ mediaId: id, status: m.status })
})

newsroomRouter.get('/uploads/:id', requireAuth, async (req, res) => {
  const { id } = parseParams(req, uuidParam)
  const m = (await db.select().from(media).where(eq(media.id, id)).limit(1))[0]
  if (!m || (m.ownerId !== req.user!.id && !['editor', 'admin'].includes(req.user!.role))) throw notFound('Upload not found')
  res.json({ mediaId: m.id, status: m.status, error: m.error })
})

// ------------------------------------------------------------------ contributors

newsroomRouter.get('/me/submission-quota', requireAuth, requireRole(...CONTRIBUTOR_ROLES), async (req, res) => {
  res.json(await submissionQuota(req.user!))
})

newsroomRouter.post('/submissions', requireAuth, requireRole(...CONTRIBUTOR_ROLES), async (req, res) => {
  const input = parseBody(req, storyFields)
  res.status(201).json(await createSubmission(req.user!, input))
})

newsroomRouter.get('/me/submissions', requireAuth, async (req, res) => {
  res.json(await mySubmissions(req.user!, parseQuery(req, cursorQuery)))
})

newsroomRouter.get('/me/submissions/:id', requireAuth, async (req, res) => {
  res.json(await mySubmission(req.user!, parseParams(req, uuidParam).id))
})

// ------------------------------------------------------------------ editors

const editor = Router()
editor.use(requireAuth, requireRole('editor'))

editor.get('/queue', async (req, res) => res.json(await editorQueue(req.user!, parseQuery(req, cursorQuery))))
editor.get('/stats', async (_req, res) => res.json(await editorStats()))
editor.get('/submissions/:id', async (req, res) => res.json(await editorSubmission(parseParams(req, uuidParam).id)))
editor.post('/submissions/:id/claim', async (req, res) => res.json(await claimSubmission(req.user!, parseParams(req, uuidParam).id)))
editor.post('/submissions/:id/heartbeat', async (req, res) => res.json(await heartbeat(req.user!, parseParams(req, uuidParam).id)))
editor.post('/submissions/:id/release', async (req, res) => res.json(await releaseClaim(req.user!, parseParams(req, uuidParam).id)))

editor.patch('/submissions/:id', async (req, res) => {
  const { id } = parseParams(req, uuidParam)
  const body = parseBody(req, z.object({ version: z.number().int().positive(), edits: storyFields.partial() }))
  res.json(await saveDraft(req.user!, id, body.version, body.edits))
})

editor.post('/submissions/:id/publish', async (req, res) => {
  const { id } = parseParams(req, uuidParam)
  const body = parseBody(
    req,
    z.object({ version: z.number().int().positive(), isBreaking: z.boolean().default(false), edits: storyFields.partial().optional() }),
  )
  const article = await publishSubmission(req.user!, id, body)
  res.status(201).json({ articleId: article.id, publishedAt: article.publishedAt.toISOString() })
})

editor.post('/submissions/:id/reject', async (req, res) => {
  const { id } = parseParams(req, uuidParam)
  const { reason } = parseBody(req, z.object({ reason: z.string().trim().min(5).max(1000) }))
  const s = await rejectSubmission(req.user!, id, reason)
  res.json({ id: s.id, status: s.status })
})

editor.get('/articles/:id', async (req, res) => {
  const a = await getArticle(parseParams(req, uuidParam).id, { includeUnpublished: true })
  if (!a) throw notFound('Article not found')
  res.json(a)
})

editor.patch('/articles/:id', async (req, res) => {
  const { id } = parseParams(req, uuidParam)
  const edits = parseBody(req, articleEdit)
  if (!Object.keys(edits).length) throw badRequest('Nothing to update')
  const a = await updateArticle(req.user!, id, edits)
  res.json({ id: a.id, updatedAt: a.updatedAt.toISOString() })
})

editor.post('/articles/:id/unpublish', async (req, res) => {
  const a = await setArticleStatus(req.user!, parseParams(req, uuidParam).id, 'unpublished')
  res.json({ id: a.id, status: a.status })
})

editor.post('/articles/:id/republish', async (req, res) => {
  const a = await setArticleStatus(req.user!, parseParams(req, uuidParam).id, 'live')
  res.json({ id: a.id, status: a.status })
})

newsroomRouter.use('/editor', editor)
