import { Router } from 'express'
import { z } from 'zod'
import { requireAuth, requireRole } from '../lib/auth.js'
import { noStore, publicCache } from '../lib/cache.js'
import { limitSchema, parseBody, parseParams, parseQuery, uuidParam } from '../lib/validate.js'
import {
  addComment,
  commentInput,
  deleteComment,
  deleteWish,
  listComments,
  listWishes,
  reviewWish,
  submitWish,
  wishInput,
} from '../services/community.js'

/** Comments and wishes. Mounted before the signed-in-only routers because reading is public. */
export const communityRouter = Router()

const articleParam = z.object({ articleId: z.string().uuid() })
const kind = z.enum(['birthday', 'anniversary']).optional()

communityRouter.get('/articles/:articleId/comments', noStore, async (req, res) => {
  const { articleId } = parseParams(req, articleParam)
  const q = parseQuery(req, z.object({ cursor: z.string().max(500).optional(), limit: limitSchema }))
  res.json(await listComments(articleId, q))
})

communityRouter.post('/articles/:articleId/comments', noStore, requireAuth, async (req, res) => {
  const { articleId } = parseParams(req, articleParam)
  const { body } = parseBody(req, commentInput)
  res.status(201).json(await addComment(req.user!, articleId, body))
})

communityRouter.delete('/comments/:id', noStore, requireAuth, async (req, res) => {
  await deleteComment(req.user!, parseParams(req, uuidParam).id)
  res.status(204).end()
})

// Approved wishes posters (public, CDN-cached briefly)
communityRouter.get('/wishes', publicCache(30, 120), async (req, res) => {
  const q = parseQuery(req, z.object({ kind, limit: limitSchema }))
  res.json(await listWishes({ ...q, status: 'approved' }))
})

communityRouter.post('/wishes', noStore, requireAuth, async (req, res) => {
  res.status(201).json(await submitWish(req.user!, parseBody(req, wishInput)))
})

communityRouter.get('/me/wishes', noStore, requireAuth, async (req, res) => {
  res.json(await listWishes({ mine: req.user!.id, limit: 50 }))
})

communityRouter.delete('/wishes/:id', noStore, requireAuth, async (req, res) => {
  await deleteWish(req.user!, parseParams(req, uuidParam).id)
  res.status(204).end()
})

// Editors / admins: review queue
communityRouter.get('/editor/wishes', noStore, requireAuth, requireRole('editor'), async (req, res) => {
  const q = parseQuery(req, z.object({ status: z.enum(['pending', 'approved', 'rejected']).default('pending'), kind, limit: limitSchema }))
  res.json(await listWishes(q))
})

communityRouter.post('/editor/wishes/:id/review', noStore, requireAuth, requireRole('editor'), async (req, res) => {
  const body = parseBody(
    req,
    z.discriminatedUnion('decision', [
      z.object({ decision: z.literal('approve') }),
      z.object({ decision: z.literal('reject'), reason: z.string().trim().min(3).max(500) }),
    ]),
  )
  const id = parseParams(req, uuidParam).id
  res.json(await reviewWish(req.user!, id, body.decision === 'approve' ? { approve: true } : { approve: false, reason: body.reason }))
})
