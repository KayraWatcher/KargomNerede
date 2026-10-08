import { Router, Request, Response } from 'express';
import { asyncHandler } from '../middleware/errorHandler';

export const healthRoutes = Router();

// Liveness probe for Render (healthCheckPath: /health).
// Deliberately minimal: no configuration, provider names or secrets here.
healthRoutes.get('/', asyncHandler(async (req: Request, res: Response) => {
  res.json({
    ok: true,
    service: 'kargomnerede-backend',
    status: 'ok',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    environment: process.env.NODE_ENV || 'development',
    version: process.env.npm_package_version || '1.0.0',
  });
}));

healthRoutes.get('/ready', asyncHandler(async (req: Request, res: Response) => {
  // Honest readiness: only things this process actually controls.
  // A missing tracking provider key does NOT make the service unready -
  // tracking requests fail explicitly with PROVIDER_NOT_CONFIGURED instead.
  const checks = {
    process: 'ok',
    trackingProvider: process.env.TRACKING_PROVIDER?.trim()
      ? 'configured'
      : 'not_configured',
  };

  res.json({
    status: 'ready',
    checks,
  });
}));

healthRoutes.get('/live', asyncHandler(async (req: Request, res: Response) => {
  res.json({
    status: 'alive',
    timestamp: new Date().toISOString(),
  });
}));