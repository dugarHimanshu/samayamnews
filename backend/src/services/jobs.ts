import { PgBoss } from 'pg-boss'
import { config } from '../config.js'
import { logger } from '../lib/logger.js'

/** Background jobs live in Postgres (pg-boss) — no Redis or Kafka needed at this scale. */
export const QUEUES = {
  processMedia: 'process-media',
  deleteAccount: 'delete-account',
  sendPush: 'send-push',
} as const

export interface ProcessMediaJob {
  mediaId: string
}
export interface DeleteAccountJob {
  userId: string
}
export interface SendPushJob {
  articleId: string
  topic: string
  title: string
  body: string
}

let boss: PgBoss | null = null
let starting: Promise<PgBoss> | null = null

export async function getBoss(): Promise<PgBoss> {
  if (boss) return boss
  starting ??= (async () => {
    const b = new PgBoss({ connectionString: config.DATABASE_URL, schema: 'pgboss' })
    b.on('error', (err) => logger.error({ err }, 'pg-boss error'))
    await b.start()
    for (const name of Object.values(QUEUES)) await b.createQueue(name)
    boss = b
    return b
  })()
  return starting
}

export async function enqueue<T extends object>(queue: (typeof QUEUES)[keyof typeof QUEUES], data: T, opts: { retryLimit?: number } = {}) {
  try {
    const b = await getBoss()
    await b.send(queue, data, { retryLimit: opts.retryLimit ?? 3, retryDelay: 10, retryBackoff: true })
  } catch (err) {
    // Jobs are best-effort side effects; the request that triggered them already succeeded.
    logger.error({ err, queue }, 'Failed to enqueue job')
  }
}

export async function stopBoss() {
  if (boss) await boss.stop({ graceful: true })
  boss = null
  starting = null
}
