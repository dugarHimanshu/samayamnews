import { Router } from 'express'
import { z } from 'zod'
import { parseBody } from '../lib/validate.js'
import { recordEvent } from '../services/counters.js'

export const eventsRouter = Router()

const eventSchema = z.object({
  events: z
    .array(z.object({ type: z.enum(['view', 'share', 'ad_impression', 'ad_click']), id: z.string().uuid() }))
    .max(100),
})

/** Batched analytics events from the app. Buffered in memory; flushed to Postgres every 30s. */
eventsRouter.post('/events', (req, res) => {
  const { events } = parseBody(req, eventSchema)
  for (const e of events) recordEvent(e)
  res.status(202).json({ accepted: events.length })
})
