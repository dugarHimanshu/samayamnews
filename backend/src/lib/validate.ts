import type { Request } from 'express'
import { z, type ZodTypeAny } from 'zod'

export const parseBody = <T extends ZodTypeAny>(req: Request, schema: T): z.infer<T> => schema.parse(req.body)
export const parseQuery = <T extends ZodTypeAny>(req: Request, schema: T): z.infer<T> => schema.parse(req.query)
export const parseParams = <T extends ZodTypeAny>(req: Request, schema: T): z.infer<T> => schema.parse(req.params)

export const uuidParam = z.object({ id: z.string().uuid() })
export const limitSchema = z.coerce.number().int().min(1).max(50).default(20)
