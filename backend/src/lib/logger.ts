import pino from 'pino'
import { config, isProd } from '../config.js'

export const logger = pino({
  level: config.LOG_LEVEL,
  redact: ['req.headers.authorization', 'req.headers.cookie', '*.password', '*.token'],
  ...(isProd || config.NODE_ENV === 'test' ? {} : { transport: { target: 'pino-pretty' } }),
})
