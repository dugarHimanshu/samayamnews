import { logger } from '../lib/logger.js'
import { getBoss, QUEUES, stopBoss, type DeleteAccountJob, type ProcessMediaJob, type SendPushJob } from '../services/jobs.js'
import { deleteAccount, processMedia, sendPush } from './handlers.js'

export async function startWorkers() {
  const boss = await getBoss()
  await boss.work<ProcessMediaJob>(QUEUES.processMedia, { batchSize: 2 }, async (jobs) => {
    for (const j of jobs) await processMedia(j.data)
  })
  await boss.work<DeleteAccountJob>(QUEUES.deleteAccount, async (jobs) => {
    for (const j of jobs) await deleteAccount(j.data)
  })
  await boss.work<SendPushJob>(QUEUES.sendPush, async (jobs) => {
    for (const j of jobs) await sendPush(j.data)
  })
  logger.info('Background workers started')
}

// Run standalone: `npm run start:worker`
if (import.meta.url === `file://${process.argv[1]}`) {
  await startWorkers()
  const shutdown = async () => {
    await stopBoss()
    process.exit(0)
  }
  process.on('SIGTERM', shutdown)
  process.on('SIGINT', shutdown)
}
