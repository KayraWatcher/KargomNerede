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
    const candidates = carrierDetectionService.detectCarrierCandidates(trackingNumber);

    if (candidates.length === 1) {
      detectedCarrier = candidates[0];
    } else {
      // Ambiguous or unknown format (e.g. a plain 13-digit number matches
      // several Turkish carriers): the format alone cannot identify the
      // sender, so the configured tracking provider decides. This needs
      // TRACKING_PROVIDER + its API key; without them the request fails with
      // 503 PROVIDER_NOT_CONFIGURED instead of guessing a carrier.
      const providerCarrier = await trackingService.detectCarrierByProvider(trackingNumber);
      if (!providerCarrier) {
        throw new AppError(400, 'Carrier could not be detected. Please specify carrierCode.', 'CARRIER_DETECTION_FAILED');
      }
      detectedCarrier = providerCarrier;
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
    shipments.map(s => {
      // Resolve the carrier the same way as /track: an explicit code, else a
      // unique format match. Ambiguous numbers are not guessed - they fail
      // with CARRIER_DETECTION_FAILED.
      const carrier = s.carrierCode || carrierDetectionService.detectCarrier(s.trackingNumber);
      if (!carrier) {
        throw new AppError(400, 'Carrier could not be detected. Please specify carrierCode.', 'CARRIER_DETECTION_FAILED');
      }
      return trackingService.trackShipment(s.trackingNumber, carrier);
    })
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
  const candidates = carrierDetectionService.detectCarrierCandidates(trackingNumber);

  if (candidates.length === 1) {
    res.json({
      success: true,
      data: {
        trackingNumber,
        carrierCode: candidates[0],
        detected: true,
        source: 'format',
        candidates,
      },
    });
    return;
  }

  // Ambiguous (several matches) or unknown format: ask the tracking provider.
  // Throws 503 PROVIDER_NOT_CONFIGURED / PROVIDER_UNAVAILABLE when no
  // provider/API key is configured - detection never falls back to a
  // priority-ordered guess.
  const carrierCode = await trackingService.detectCarrierByProvider(trackingNumber);

  res.json({
    success: true,
    data: {
      trackingNumber,
      carrierCode,
      detected: !!carrierCode,
      source: carrierCode ? 'provider' : null,
      candidates,
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