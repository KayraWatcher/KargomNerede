// Webhook Service - Handles incoming webhooks from tracking providers

import { trackingService } from './trackingService';
import { shipmentService } from './shipmentService';
import { notificationService } from './notificationService';

class WebhookService {
  async process17TrackWebhook(payload: any): Promise<void> {
    console.log('Processing 17TRACK webhook:', JSON.stringify(payload, null, 2));
    
    // 17TRACK webhook format
    const trackings = payload?.data?.trackings || [];
    
    for (const tracking of trackings) {
      await this.processTrackingUpdate({
        trackingNumber: tracking.number,
        carrierCode: tracking.carrier,
        status: this.map17TrackStatus(tracking.status),
        description: tracking.status_description,
        location: tracking.location,
        timestamp: tracking.updated_at || new Date().toISOString(),
        events: tracking.details?.map((d: any) => ({
          timestamp: d.time,
          status: this.map17TrackStatus(d.status),
          description: d.desc,
          location: d.location,
        })) || [],
      });
    }
  }

  async processAfterShipWebhook(payload: any): Promise<void> {
    console.log('Processing AfterShip webhook:', JSON.stringify(payload, null, 2));
    
    const tracking = payload?.tracking;
    if (!tracking) return;

    await this.processTrackingUpdate({
      trackingNumber: tracking.tracking_number,
      carrierCode: tracking.slug,
      status: this.mapAfterShipStatus(tracking.tagging?.tag ?? tracking.tag ?? ''),
      description: tracking.checkpoints?.[0]?.message,
      location: tracking.checkpoints?.[0]?.location,
      timestamp: tracking.updated_at,
      events: tracking.checkpoints?.map((cp: any) => ({
        timestamp: cp.checkpoint_time,
        status: this.mapAfterShipStatus(cp.status),
        description: cp.message,
        location: cp.location,
      })) || [],
    });
  }

  async processShip24Webhook(payload: any): Promise<void> {
    console.log('Processing Ship24 webhook:', JSON.stringify(payload, null, 2));
    
    const trackings = payload?.data?.trackings || [];
    
    for (const tracking of trackings) {
      await this.processTrackingUpdate({
        trackingNumber: tracking.trackingNumber,
        carrierCode: tracking.courier?.slug || '',
        status: this.mapShip24Status(tracking.status),
        description: tracking.statusDescription,
        location: tracking.events?.[0]?.location,
        timestamp: tracking.lastUpdate,
        events: tracking.events?.map((e: any) => ({
          timestamp: e.datetime,
          status: this.mapShip24Status(e.status),
          description: e.description,
          location: e.location,
        })) || [],
      });
    }
  }

  private async processTrackingUpdate(data: {
    trackingNumber: string;
    carrierCode: string;
    status: string;
    description: string;
    location?: string;
    timestamp: string;
    events: any[];
  }): Promise<void> {
    // Find shipments with this tracking number
    // In production, this would query the database
    // For now, we'll just log
    console.log('Tracking update:', data);

    // In a real implementation:
    // 1. Find all users tracking this number
    // 2. Update shipment status in database
    // 3. Create notifications for status changes
    // 4. Send FCM notifications
  }

  async registerWebhook(provider: string, webhookUrl: string): Promise<any> {
    // Register webhook URL with tracking provider
    // This would make API calls to 17TRACK, AfterShip, Ship24
    console.log(`Registering webhook for ${provider}: ${webhookUrl}`);
    
    return { success: true, provider, webhookUrl };
  }

  async getWebhookStatus(): Promise<any> {
    return {
      providers: [
        { name: '17TRACK', registered: false, url: '' },
        { name: 'AfterShip', registered: false, url: '' },
        { name: 'Ship24', registered: false, url: '' },
      ],
    };
  }

  // Status mapping (same as trackingService)
  private map17TrackStatus(status: number): string {
    const map: Record<number, string> = {
      0: 'CREATED', 1: 'IN_TRANSIT', 2: 'IN_TRANSIT', 3: 'ARRIVED_AT_FACILITY',
      4: 'OUT_FOR_DELIVERY', 5: 'DELIVERED', 6: 'EXCEPTION', 7: 'RETURNED', 8: 'EXCEPTION',
    };
    return map[status] || 'CREATED';
  }

  private mapAfterShipStatus(status: string): string {
    const map: Record<string, string> = {
      'Pending': 'CREATED', 'InfoReceived': 'CREATED', 'InTransit': 'IN_TRANSIT',
      'OutForDelivery': 'OUT_FOR_DELIVERY', 'AttemptFail': 'EXCEPTION',
      'Delivered': 'DELIVERED', 'AvailableForPickup': 'ARRIVED_AT_FACILITY',
      'Exception': 'EXCEPTION', 'Expired': 'EXCEPTION',
    };
    return map[status] || 'CREATED';
  }

  private mapShip24Status(status: string): string {
    const map: Record<string, string> = {
      'pending': 'CREATED', 'in_transit': 'IN_TRANSIT', 'arrived_at_facility': 'ARRIVED_AT_FACILITY',
      'out_for_delivery': 'OUT_FOR_DELIVERY', 'delivered': 'DELIVERED',
      'exception': 'EXCEPTION', 'returned': 'RETURNED',
    };
    return map[status] || 'CREATED';
  }
}

export const webhookService = new WebhookService();