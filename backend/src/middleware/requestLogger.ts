import type { Request, Response, NextFunction } from 'express';

/**
 * Request logger middleware.
 *
 * `morgan('combined')` already prints an access line for every request, so
 * this middleware only reports the requests that end with an error status.
 * That keeps the normal log readable while still making failed tracking /
 * shipment calls easy to spot.
 *
 * (This module was referenced by `src/index.ts` but did not exist, which
 * prevented the API from booting at all.)
 */
export function requestLogger(req: Request, res: Response, next: NextFunction): void {
  const start = Date.now();

  res.on('finish', () => {
    if (res.statusCode >= 400) {
      const duration = Date.now() - start;
      // eslint-disable-next-line no-console
      console.error(
        `[error] ${req.method} ${req.originalUrl} -> ${res.statusCode} (${duration}ms)`
      );
    }
  });

  next();
}
