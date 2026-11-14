import { config } from './config.js'
import { sqlClient } from './db/client.js'
import { logger } from './lib/logger.js'
import { createApp } from './app.js'
import { startCounterFlush, stopCounterFlush } from './services/counters.js'
import { getBoss, stopBoss } from './services/jobs.js'
import { startWorkers } from './worker/index.js'

const app = createApp()
startCounterFlush()

// The API also enqueues jobs, so it always connects to pg-boss; it only *processes* jobs when WORKER_INLINE=true.
await getBoss()
if (config.WORKER_INLINE) await startWorkers()

const server = app.listen(config.PORT, () => logger.info(`API listening on :${config.PORT}`))

let shuttingDown = false
async function shutdown(signal: string) {
  if (shuttingDown) return
  shuttingDown = true
  logger.info({ signal }, 'Shutting down')
  server.close()
  await stopCounterFlush()
  await stopBoss()
  await sqlClient.end({ timeout: 5 })
  process.exit(0)
}
process.on('SIGTERM', () => void shutdown('SIGTERM'))
process.on('SIGINT', () => void shutdown('SIGINT'))
