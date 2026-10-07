import { Router } from 'express';
import { z } from 'zod';
import { asyncHandler, AppError } from '../middleware/errorHandler';
import { trackingService } from '../services/trackingService';
import { carrierDetectionService } from '../services/carrierDetectionService';

export const trackingRoutes = Router();

// Track a shipment
trackingRoutes.post('/track', asyncHandler(async (req, res) => {
  const schema = z.object({
    trackingNumber: z.string().min(5).max(50),
    carrierCode: z.string().optional(),
  });
  
  const { trackingNumber, carrierCode } = schema.parse(req.body);
  
  let detectedCarrier = carrierCode;
  
  if (!detectedCarrier) {
    detectedCarrier = carrierDetectionService.detectCarrier(trackingNumber);
    if (!detectedCarrier) {
      throw new AppError(400, 'Carrier could not be detected. Please specify carrierCode.', 'CARRIER_DETECTION_FAILED');
    }
  }
  
  const result = await trackingService.trackShipment(trackingNumber, detectedCarrier);
  
  res.json({
    success: true,
    data: result,
  });
}));

// Track multiple shipments
trackingRoutes.post('/track/batch', asyncHandler(async (req, res) => {
  const schema = z.object({
    shipments: z.array(z.object({
      trackingNumber: z.string().min(5).max(50),
      carrierCode: z.string().optional(),
    })).min(1).max(50),
  });
  
  const { shipments } = schema.parse(req.body);
  
  const results = await Promise.allSettled(
    shipments.map(s => trackingService.trackShipment(s.trackingNumber, s.carrierCode || carrierDetectionService.detectCarrier(s.trackingNumber) || ''))
  );
  
  res.json({
    success: true,
    data: results.map((r, i) => ({
      trackingNumber: shipments[i].trackingNumber,
      carrierCode: shipments[i].carrierCode,
      success: r.status === 'fulfilled',
      data: r.status === 'fulfilled' ? r.value : null,
      error: r.status === 'rejected' ? r.reason.message : null,
    })),
  });
}));

// Get supported carriers
trackingRoutes.get('/carriers', asyncHandler(async (req, res) => {
  const carriers = carrierDetectionService.getSupportedCarriers();
  
  res.json({
    success: true,
    data: carriers,
  });
}));

// Detect carrier from tracking number
trackingRoutes.post('/detect-carrier', asyncHandler(async (req, res) => {
  const schema = z.object({
    trackingNumber: z.string().min(5).max(50),
  });
  
  const { trackingNumber } = schema.parse(req.body);
  const carrier = carrierDetectionService.detectCarrier(trackingNumber);
  
  res.json({
    success: true,
    data: {
      trackingNumber,
      carrierCode: carrier,
      detected: !!carrier,
    },
  });
}));

// Get tracking provider status
trackingRoutes.get('/providers/status', asyncHandler(async (req, res) => {
  const status = await trackingService.getProviderStatus();
  
  res.json({
    success: true,
    data: status,
  });
}));