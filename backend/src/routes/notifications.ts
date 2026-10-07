import { Router } from 'express';
import { z } from 'zod';
import { asyncHandler, AppError } from '../middleware/errorHandler';
import { notificationService } from '../services/notificationService';

export const notificationRoutes = Router();

// Get user notifications
notificationRoutes.get('/', asyncHandler(async (req, res) => {
  const schema = z.object({
    userId: z.string().uuid(),
    unreadOnly: z.coerce.boolean().default(false),
    page: z.coerce.number().min(1).default(1),
    limit: z.coerce.number().min(1).max(100).default(20),
  });
  
  const { userId, unreadOnly, page, limit } = schema.parse(req.query);
  
  const result = await notificationService.getUserNotifications(userId, { unreadOnly, page, limit });
  
  res.json({
    success: true,
    data: result,
  });
}));

// Mark notification as read
notificationRoutes.patch('/:id/read', asyncHandler(async (req, res) => {
  const { id } = req.params;
  const { userId } = req.query;
  
  if (!userId) {
    throw new AppError(400, 'userId is required', 'MISSING_USER_ID');
  }
  
  const notification = await notificationService.markAsRead(id, userId as string);
  
  if (!notification) {
    throw new AppError(404, 'Notification not found', 'NOTIFICATION_NOT_FOUND');
  }
  
  res.json({
    success: true,
    data: notification,
  });
}));

// Mark all as read
notificationRoutes.post('/read-all', asyncHandler(async (req, res) => {
  const schema = z.object({
    userId: z.string().uuid(),
  });
  
  const { userId } = schema.parse(req.body);
  
  await notificationService.markAllAsRead(userId);
  
  res.json({
    success: true,
    message: 'All notifications marked as read',
  });
}));

// Delete notification
notificationRoutes.delete('/:id', asyncHandler(async (req, res) => {
  const { id } = req.params;
  const { userId } = req.query;
  
  if (!userId) {
    throw new AppError(400, 'userId is required', 'MISSING_USER_ID');
  }
  
  const deleted = await notificationService.deleteNotification(id, userId as string);
  
  if (!deleted) {
    throw new AppError(404, 'Notification not found', 'NOTIFICATION_NOT_FOUND');
  }
  
  res.json({
    success: true,
    message: 'Notification deleted',
  });
}));

// Get notification preferences
notificationRoutes.get('/preferences', asyncHandler(async (req, res) => {
  const { userId } = req.query;
  
  if (!userId) {
    throw new AppError(400, 'userId is required', 'MISSING_USER_ID');
  }
  
  const preferences = await notificationService.getPreferences(userId as string);
  
  res.json({
    success: true,
    data: preferences,
  });
}));

// Update notification preferences
notificationRoutes.patch('/preferences', asyncHandler(async (req, res) => {
  const schema = z.object({
    userId: z.string().uuid(),
    enabled: z.boolean().optional(),
    newMovement: z.boolean().optional(),
    arrivedAtFacility: z.boolean().optional(),
    outForDelivery: z.boolean().optional(),
    delivered: z.boolean().optional(),
    exception: z.boolean().optional(),
    delay: z.boolean().optional(),
    wifiOnly: z.boolean().optional(),
  });
  
  const { userId, ...preferences } = schema.parse(req.body);
  
  const updated = await notificationService.updatePreferences(userId, preferences);
  
  res.json({
    success: true,
    data: updated,
  });
}));

// Register FCM token
notificationRoutes.post('/fcm-token', asyncHandler(async (req, res) => {
  const schema = z.object({
    userId: z.string().uuid(),
    token: z.string().min(10),
    platform: z.enum(['android', 'ios', 'web']),
  });
  
  const { userId, token, platform } = schema.parse(req.body);
  
  await notificationService.registerFCMToken(userId, token, platform);
  
  res.json({
    success: true,
    message: 'FCM token registered',
  });
}));

// Unregister FCM token
notificationRoutes.delete('/fcm-token', asyncHandler(async (req, res) => {
  const schema = z.object({
    userId: z.string().uuid(),
    token: z.string().min(10),
  });
  
  const { userId, token } = schema.parse(req.body);
  
  await notificationService.unregisterFCMToken(userId, token);
  
  res.json({
    success: true,
    message: 'FCM token unregistered',
  });
}));