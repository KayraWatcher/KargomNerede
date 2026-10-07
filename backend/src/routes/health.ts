import { Router, Request, Response } from 'express';
import { asyncHandler } from '../middleware/errorHandler';

export const healthRoutes = Router();

healthRoutes.get('/', asyncHandler(async (req: Request, res: Response) => {
  res.json({
    status: 'ok',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    environment: process.env.NODE_ENV || 'development',
    version: process.env.npm_package_version || '1.0.0',
  });
}));

healthRoutes.get('/ready', asyncHandler(async (req: Request, res: Response) => {
  // Check database, redis, external services
  const checks = {
    database: 'ok', // await checkDatabase()
    redis: 'ok',    // await checkRedis()
    tracking: 'ok', // await checkTrackingProviders()
  };
  
  const allHealthy = Object.values(checks).every(v => v === 'ok');
  
  res.status(allHealthy ? 200 : 503).json({
    status: allHealthy ? 'ready' : 'not ready',
    checks,
  });
}));

healthRoutes.get('/live', asyncHandler(async (req: Request, res: Response) => {
  res.json({
    status: 'alive',
    timestamp: new Date().toISOString(),
  });
}));