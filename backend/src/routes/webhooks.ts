import { Router } from 'express';
import { z } from 'zod';
import { asyncHandler, AppError } from '../middleware/errorHandler';
import { webhookService } from '../services/webhookService';
import crypto from 'crypto';

export const webhookRoutes = Router();

// 17TRACK webhook
webhookRoutes.post('/17track', asyncHandler(async (req, res) => {
  const signature = req.headers['x-17track-signature'] as string;
  const payload = JSON.stringify(req.body);
  
  // Verify signature
  const expectedSignature = crypto
    .createHmac('sha256', process.env.WEBHOOK_SECRET_17TRACK || '')
    .update(payload)
    .digest('hex');
  
  if (signature !== expectedSignature) {
    throw new AppError(401, 'Invalid webhook signature', 'INVALID_SIGNATURE');
  }
  
  await webhookService.process17TrackWebhook(req.body);
  
  res.json({ success: true });
}));

// AfterShip webhook
webhookRoutes.post('/aftership', asyncHandler(async (req, res) => {
  const signature = req.headers['aftership-hmac-sha256'] as string;
  const payload = JSON.stringify(req.body);
  
  const expectedSignature = crypto
    .createHmac('sha256', process.env.WEBHOOK_SECRET_AFTERSHIP || '')
    .update(payload)
    .digest('hex');
  
  if (signature !== expectedSignature) {
    throw new AppError(401, 'Invalid webhook signature', 'INVALID_SIGNATURE');
  }
  
  await webhookService.processAfterShipWebhook(req.body);
  
  res.json({ success: true });
}));

// Ship24 webhook
webhookRoutes.post('/ship24', asyncHandler(async (req, res) => {
  // Ship24 uses different verification
  await webhookService.processShip24Webhook(req.body);
  
  res.json({ success: true });
}));

// Generic webhook for testing
webhookRoutes.post('/test', asyncHandler(async (req, res) => {
  console.log('Test webhook received:', req.body);
  
  res.json({
    success: true,
    message: 'Test webhook received',
    data: req.body,
  });
}));

// Register webhook URL with provider
webhookRoutes.post('/register', asyncHandler(async (req, res) => {
  const schema = z.object({
    provider: z.enum(['17track', 'aftership', 'ship24']),
    webhookUrl: z.string().url(),
  });
  
  const { provider, webhookUrl } = schema.parse(req.body);
  
  const result = await webhookService.registerWebhook(provider, webhookUrl);
  
  res.json({
    success: true,
    data: result,
  });
}));

// Get webhook status
webhookRoutes.get('/status', asyncHandler(async (req, res) => {
  const status = await webhookService.getWebhookStatus();
  
  res.json({
    success: true,
    data: status,
  });
}));