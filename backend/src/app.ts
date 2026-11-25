import { randomUUID } from 'node:crypto'
import cors from 'cors'
import express from 'express'
import rateLimit from 'express-rate-limit'
import helmet from 'helmet'
import { pinoHttp } from 'pino-http'
import { sql } from 'drizzle-orm'
import { config } from './config.js'
import { db } from './db/client.js'
import { optionalAuth } from './lib/auth.js'
import { errorHandler, notFoundHandler } from './lib/errors.js'
import { logger } from './lib/logger.js'
import { adminRouter } from './routes/admin.js'
import { applicationsRouter } from './routes/applications.js'
import { communityRouter } from './routes/community.js'
import { eventsRouter } from './routes/events.js'
import { meRouter } from './routes/me.js'
import { newsroomRouter } from './routes/newsroom.js'
import { publicRouter } from './routes/public.js'

export function createApp() {
  const app = express()
  app.disable('x-powered-by')
  // Number of proxy hops in front of the app (Cloudflare → load balancer = 2). Never `true`: that lets clients spoof their IP.
  app.set('trust proxy', config.TRUST_PROXY)

  app.use(
    pinoHttp({
      logger,
      genReqId: (req, res) => {
        const id = (req.headers['x-request-id'] as string) || randomUUID()
        res.setHeader('x-request-id', id)
        return id
      },
      customProps: (req) => ({ userId: (req as express.Request).user?.id }),
      autoLogging: { ignore: (req) => req.url === '/healthz' },
    }),
  )
  app.use(helmet())
  const origins = config.CORS_ORIGINS.split(',').map((s) => s.trim()).filter(Boolean)
  app.use(cors({ origin: origins.length ? origins : false, exposedHeaders: ['x-request-id'] }))
  app.use(express.json({ limit: '256kb' }))

  // Per-instance safety net; Cloudflare rate-limiting rules are the primary defence in production.
  app.use(
    '/v1',
    rateLimit({ windowMs: 60_000, limit: 300, standardHeaders: 'draft-8', legacyHeaders: false, message: { error: { code: 'rate_limited', message: 'Too many requests' } } }),
  )

  app.get('/healthz', (_req, res) => void res.json({ ok: true }))
  app.get('/readyz', async (_req, res) => {
    await db.execute(sql`select 1`)
    res.json({ ok: true })
  })

  const v1 = express.Router()
  v1.use(optionalAuth)
  v1.use(publicRouter)
  v1.use(applicationsRouter)
  v1.use(communityRouter)
  v1.use(eventsRouter)
  v1.use(meRouter)
  v1.use(newsroomRouter)
  v1.use('/admin', adminRouter)
  app.use('/v1', v1)

  app.use(notFoundHandler)
  app.use(errorHandler)
  return app
}
