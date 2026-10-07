import { Router } from 'express';
import { z } from 'zod';
import { asyncHandler, AppError } from '../middleware/errorHandler';
import { shipmentService } from '../services/shipmentService';

export const shipmentRoutes = Router();

// Get all shipments for user
shipmentRoutes.get('/', asyncHandler(async (req, res) => {
  const schema = z.object({
    userId: z.string().uuid(),
    status: z.string().optional(),
    page: z.coerce.number().min(1).default(1),
    limit: z.coerce.number().min(1).max(100).default(20),
  });
  
  const { userId, status, page, limit } = schema.parse(req.query);
  
  const result = await shipmentService.getUserShipments(userId, { status, page, limit });
  
  res.json({
    success: true,
    data: result,
  });
}));

// Get single shipment
shipmentRoutes.get('/:id', asyncHandler(async (req, res) => {
  const { id } = req.params;
  const { userId } = req.query;
  
  if (!userId) {
    throw new AppError(400, 'userId is required', 'MISSING_USER_ID');
  }
  
  const shipment = await shipmentService.getShipment(id, userId as string);
  
  if (!shipment) {
    throw new AppError(404, 'Shipment not found', 'SHIPMENT_NOT_FOUND');
  }
  
  res.json({
    success: true,
    data: shipment,
  });
}));

// Add new shipment
shipmentRoutes.post('/', asyncHandler(async (req, res) => {
  const schema = z.object({
    userId: z.string().uuid(),
    trackingNumber: z.string().min(5).max(50),
    carrierCode: z.string(),
    carrierName: z.string(),
    customName: z.string().optional(),
  });
  
  const data = schema.parse(req.body);
  
  const shipment = await shipmentService.createShipment(data);
  
  res.status(201).json({
    success: true,
    data: shipment,
  });
}));

// Update shipment (custom name, etc.)
shipmentRoutes.patch('/:id', asyncHandler(async (req, res) => {
  const { id } = req.params;
  const { userId } = req.query;
  
  if (!userId) {
    throw new AppError(400, 'userId is required', 'MISSING_USER_ID');
  }
  
  const schema = z.object({
    customName: z.string().optional(),
    isArchived: z.boolean().optional(),
  });
  
  const data = schema.parse(req.body);
  
  const shipment = await shipmentService.updateShipment(id, userId as string, data);
  
  if (!shipment) {
    throw new AppError(404, 'Shipment not found', 'SHIPMENT_NOT_FOUND');
  }
  
  res.json({
    success: true,
    data: shipment,
  });
}));

// Delete shipment
shipmentRoutes.delete('/:id', asyncHandler(async (req, res) => {
  const { id } = req.params;
  const { userId } = req.query;
  
  if (!userId) {
    throw new AppError(400, 'userId is required', 'MISSING_USER_ID');
  }
  
  const deleted = await shipmentService.deleteShipment(id, userId as string);
  
  if (!deleted) {
    throw new AppError(404, 'Shipment not found', 'SHIPMENT_NOT_FOUND');
  }
  
  res.json({
    success: true,
    message: 'Shipment deleted',
  });
}));

// Refresh shipment tracking
shipmentRoutes.post('/:id/refresh', asyncHandler(async (req, res) => {
  const { id } = req.params;
  const { userId } = req.query;
  
  if (!userId) {
    throw new AppError(400, 'userId is required', 'MISSING_USER_ID');
  }
  
  const shipment = await shipmentService.refreshShipment(id, userId as string);
  
  if (!shipment) {
    throw new AppError(404, 'Shipment not found', 'SHIPMENT_NOT_FOUND');
  }
  
  res.json({
    success: true,
    data: shipment,
  });
}));