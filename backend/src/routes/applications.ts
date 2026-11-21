import { Router } from 'express'
import rateLimit from 'express-rate-limit'
import { z } from 'zod'
import { requireAuth } from '../lib/auth.js'
import { noStore } from '../lib/cache.js'
import { parseBody } from '../lib/validate.js'
import {
  applicationInput,
  applyAsUser,
  latestApplicationFor,
  publicApplicationInput,
  registerApplicant,
} from '../services/applications.js'

/**
 * Reporter / freelancer registration. Mounted before the signed-in-only routers because the
 * sign-up form is used by people who don't have an account yet.
 */
export const applicationsRouter = Router()

// Account creation is the abuse-prone part: 5 sign-ups per IP per hour is plenty for a newsroom.
const signupLimit = rateLimit({
  windowMs: 60 * 60_000,
  limit: 5,
  standardHeaders: 'draft-8',
  legacyHeaders: false,
  message: { error: { code: 'rate_limited', message: 'Too many registrations from this network. Please try again later.' } },
})

applicationsRouter.post('/applications', noStore, signupLimit, async (req, res) => {
  if (req.user) {
    // Already signed in: apply with the current account, no password needed.
    const body = parseBody(req, applicationInput)
    await applyAsUser(req.user, body)
    return res.status(201).json(await latestApplicationFor(req.user.id))
  }
  const body = parseBody(req, publicApplicationInput)
  const row = await registerApplicant(body)
  res.status(201).json(await latestApplicationFor(row.userId))
})

/** The signed-in user's latest application (null if they never applied). */
applicationsRouter.get('/me/application', noStore, requireAuth, async (req, res) => {
  res.json({ application: await latestApplicationFor(req.user!.id) })
})

export const reviewInput = z.discriminatedUnion('decision', [
  z.object({ decision: z.literal('approve'), role: z.enum(['employee', 'freelancer']).optional() }),
  z.object({ decision: z.literal('reject'), reason: z.string().trim().min(3).max(500) }),
])
