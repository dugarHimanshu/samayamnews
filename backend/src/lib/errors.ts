import type { ErrorRequestHandler, RequestHandler } from 'express'
import { ZodError } from 'zod'
import { logger } from './logger.js'

export class HttpError extends Error {
  constructor(
    public status: number,
    public code: string,
    message: string,
    public details?: unknown,
  ) {
    super(message)
  }
}

export const badRequest = (message: string, details?: unknown) => new HttpError(400, 'bad_request', message, details)
export const unauthorized = (message = 'Sign in required') => new HttpError(401, 'unauthorized', message)
export const forbidden = (message = 'You do not have access to this') => new HttpError(403, 'forbidden', message)
export const notFound = (message = 'Not found') => new HttpError(404, 'not_found', message)
export const conflict = (code: string, message: string) => new HttpError(409, code, message)
export const tooMany = (code: string, message: string) => new HttpError(429, code, message)

export const notFoundHandler: RequestHandler = (_req, _res, next) => next(notFound('Route not found'))

/** Single error shape for every failure: { error: { code, message, requestId, details? } } */
export const errorHandler: ErrorRequestHandler = (err, req, res, _next) => {
  const requestId = req.id
  if (err instanceof ZodError) {
    res.status(400).json({ error: { code: 'validation_failed', message: 'Invalid request', requestId, details: err.flatten() } })
    return
  }
  if (err instanceof HttpError) {
    res.status(err.status).json({ error: { code: err.code, message: err.message, requestId, details: err.details } })
    return
  }
  if (err?.type === 'entity.parse.failed') {
    res.status(400).json({ error: { code: 'invalid_json', message: 'Malformed JSON body', requestId } })
    return
  }
  logger.error({ err, requestId }, 'Unhandled error')
  res.status(500).json({ error: { code: 'internal', message: 'Something went wrong', requestId } })
}
