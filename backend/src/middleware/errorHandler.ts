import { Request, Response, NextFunction } from 'express';
import { ZodError } from 'zod';

// NOTE: request logging lives in ./requestLogger (used by index.ts); the
// duplicate definition that used to be here was dead code.

export class AppError extends Error {
  constructor(
    public statusCode: number,
    public message: string,
    public code?: string,
    public details?: any
  ) {
    super(message);
    Object.setPrototypeOf(this, AppError.prototype);
  }
}

export const errorHandler = (err: Error, req: Request, res: Response, next: NextFunction) => {
  console.error('Error:', err);

  if (err instanceof AppError) {
    return res.status(err.statusCode).json({
      error: err.name,
      message: err.message,
      code: err.code,
      details: err.details,
    });
  }

  // Zod validation errors (only field paths/messages - no secrets)
  if (err instanceof ZodError) {
    return res.status(400).json({
      error: 'ValidationError',
      message: 'Invalid request data',
      code: 'VALIDATION_ERROR',
      details: err.issues,
    });
  }

  // Express/body-parser client errors (malformed JSON, payload too large,
  // unsupported media type, ...). These carry their own 4xx status and must
  // not be reported as server errors.
  const httpStatus = (err as any).statusCode ?? (err as any).status;
  if (typeof httpStatus === 'number' && httpStatus >= 400 && httpStatus < 500) {
    return res.status(httpStatus).json({
      error: err.name,
      message:
        (err as any).type === 'entity.parse.failed'
          ? 'Invalid JSON in request body'
          : err.message,
      code: httpStatus === 413 ? 'PAYLOAD_TOO_LARGE' : 'BAD_REQUEST',
    });
  }

  // Default error
  return res.status(500).json({
    error: 'InternalServerError',
    message: process.env.NODE_ENV === 'production' 
      ? 'An unexpected error occurred' 
      : err.message,
    code: 'INTERNAL_ERROR',
  });
};

/**
 * Route handler wrapper: rejects surface in the error handler above instead
 * of crashing the process.
 *
 * The parameter types give route callbacks an explicit `Request`/`Response`
 * context (previously `fn: Function` left every `req`/`res` untyped, which
 * broke `tsc` under `strict`).
 */
export type AsyncRequestHandler = (
  req: Request,
  res: Response,
  next: NextFunction
) => Promise<unknown> | unknown;

export const asyncHandler =
  (fn: AsyncRequestHandler) =>
  (req: Request, res: Response, next: NextFunction) => {
    Promise.resolve(fn(req, res, next)).catch(next);
  };