import axios from 'axios';
import { AppError } from '../middleware/errorHandler';

export interface TrackingResult {
  trackingNumber: string;
  carrierCode: string;
  carrierName: string;
  status: string;
  statusDescription: string;
  lastUpdate: string;
  estimatedDelivery?: string;
  events: TrackingEvent[];
  sender?: string;
  recipient?: string;
  origin?: string;
  destination?: string;
  currentLocation?: string;
}

export interface TrackingEvent {
  timestamp: string;
  status: string;
  description: string;
  location?: string;
  facilityName?: string;
}

export interface ProviderStatus {
  name: string;
  available: boolean;
  rateLimit?: {
    remaining: number;
    reset: number;
  };
  lastCheck: string;
  /** Extra diagnostics, e.g. why a configured provider is unavailable. */
  detail?: string;
}

class TrackingService {
  private providers: Map<string, TrackingProvider> = new Map();
  private cache: Map<string, { data: TrackingResult; expires: number }> = new Map();
  private readonly CACHE_TTL = 15 * 60 * 1000; // 15 minutes

  constructor() {
    this.initializeProviders();
  }

  private initializeProviders() {
    // 17TRACK
    if (process.env.TRACKING_17TRACK_API_KEY) {
      this.providers.set('17track', {
        name: '17TRACK',
        track: this.track17Track.bind(this),
        getStatus: this.get17TrackStatus.bind(this),
      });
    }

    // AfterShip
    if (process.env.TRACKING_AFTERSHIP_API_KEY) {
      this.providers.set('aftership', {
        name: 'AfterShip',
        track: this.trackAfterShip.bind(this),
        getStatus: this.getAfterShipStatus.bind(this),
      });
    }

    // Ship24
    if (process.env.TRACKING_SHIP24_API_KEY) {
      this.providers.set('ship24', {
        name: 'Ship24',
        track: this.trackShip24.bind(this),
        getStatus: this.getShip24Status.bind(this),
        // Ship24's search endpoint identifies the courier from the tracking
        // number alone, so it is the adapter that can answer provider-side
        // carrier detection.
        detectCarrier: this.detectCarrierShip24.bind(this),
      });
    }

    // Development only: the mock provider is never registered implicitly.
    // Without a configured provider the API fails loudly
    // (503 PROVIDER_NOT_CONFIGURED) instead of returning random data that
    // looks like a real shipment. Opt in explicitly with TRACKING_PROVIDER=mock.
    if (process.env.TRACKING_PROVIDER === 'mock') {
      this.providers.set('mock', {
        name: 'Mock Provider (Development)',
        track: this.trackMock.bind(this),
        getStatus: this.getMockStatus.bind(this),
      });
    }
  }

  /**
   * The provider selected through TRACKING_PROVIDER. Throws 503 when nothing
   * is configured or the selected provider has no API key, so callers (and
   * clients) see a clear configuration error instead of fake data.
   */
  private requireProvider(): TrackingProvider {
    const providerName = process.env.TRACKING_PROVIDER?.trim();

    if (!providerName) {
      throw new AppError(
        503,
        'Tracking provider is not configured. Set TRACKING_PROVIDER and the matching API key (see backend/.env.example).',
        'PROVIDER_NOT_CONFIGURED'
      );
    }

    const provider = this.providers.get(providerName);
    if (!provider) {
      throw new AppError(
        503,
        `Tracking provider "${providerName}" is not available. Check TRACKING_PROVIDER and its API key (see backend/.env.example).`,
        'PROVIDER_UNAVAILABLE'
      );
    }

    return provider;
  }

  /**
   * Asks the configured provider to identify the carrier of a tracking
   * number (used when the number's format is ambiguous, e.g. plain 13-digit
   * numbers that match several Turkish carriers at once).
   *
   * Returns `null` when the provider cannot tell - adapters that require an
   * explicit carrier simply do not implement `detectCarrier`. Throws 503 when
   * no provider/API key is configured.
   */
  async detectCarrierByProvider(trackingNumber: string): Promise<string | null> {
    const provider = this.requireProvider();
    if (!provider.detectCarrier) {
      return null;
    }
    try {
      const code = await provider.detectCarrier(trackingNumber);
      const trimmed = code?.trim();
      return trimmed ? trimmed : null;
    } catch (error) {
      if (error instanceof AppError) throw error;
      // Provider could not identify the carrier: report "not detected"
      // instead of guessing.
      return null;
    }
  }

  async trackShipment(trackingNumber: string, carrierCode: string): Promise<TrackingResult> {
    const cacheKey = `${carrierCode}:${trackingNumber}`;
    const cached = this.cache.get(cacheKey);
    
    if (cached && cached.expires > Date.now()) {
      return cached.data;
    }

    const provider = this.requireProvider();

    try {
      const result = await provider.track(trackingNumber, carrierCode);
      
      // Cache the result
      this.cache.set(cacheKey, {
        data: result,
        expires: Date.now() + this.CACHE_TTL,
      });
      
      return result;
    } catch (error) {
      if (error instanceof AppError) throw error;
      // A real provider failure must surface as a real error - never as
      // fake success - but raw provider payloads/messages are not echoed
      // back (they can contain request details); only the HTTP status is.
      if (axios.isAxiosError(error)) {
        const status = error.response?.status;
        if (status === 401 || status === 403) {
          throw new AppError(
            502,
            `Tracking provider rejected the configured API key (HTTP ${status})`,
            'PROVIDER_AUTH_FAILED'
          );
        }
        if (status === 429) {
          throw new AppError(
            429,
            'Tracking provider rate limit exceeded (HTTP 429)',
            'PROVIDER_RATE_LIMITED'
          );
        }
        if (status !== undefined) {
          throw new AppError(
            502,
            `Tracking provider request failed (HTTP ${status})`,
            'PROVIDER_ERROR'
          );
        }
        throw new AppError(
          502,
          'Tracking provider is unreachable',
          'PROVIDER_UNREACHABLE'
        );
      }
      throw new AppError(502, 'Tracking provider request failed', 'PROVIDER_ERROR');
    }
  }

  async getProviderStatus(): Promise<ProviderStatus[]> {
    const statuses: ProviderStatus[] = [];
    const now = new Date().toISOString();
    
    for (const [key, provider] of this.providers) {
      try {
        const status = await provider.getStatus();
        statuses.push({ ...status, name: provider.name });
      } catch {
        statuses.push({
          name: provider.name,
          available: false,
          lastCheck: now,
          detail: 'Provider status check failed',
        });
      }
    }

    // Make the configuration state visible instead of silently reporting an
    // empty (or mock) provider list.
    const selected = process.env.TRACKING_PROVIDER?.trim();
    if (!selected) {
      statuses.push({
        name: 'TRACKING_PROVIDER',
        available: false,
        lastCheck: now,
        detail: 'Not configured - set TRACKING_PROVIDER and its API key (see backend/.env.example)',
      });
    } else if (!this.providers.has(selected)) {
      statuses.push({
        name: selected,
        available: false,
        lastCheck: now,
        detail: 'Selected in TRACKING_PROVIDER but not available - its API key is missing (see backend/.env.example)',
      });
    }

    return statuses;
  }

  // 17TRACK Implementation
  private async track17Track(trackingNumber: string, carrierCode: string): Promise<TrackingResult> {
    const response = await axios.post(
      'https://api.17track.net/track/v2.2/gettrackinfo',
      {
        tracking_numbers: [{
          number: trackingNumber,
          carrier: carrierCode,
        }],
      },
      {
        headers: {
          '17token': process.env.TRACKING_17TRACK_API_KEY!,
          'Content-Type': 'application/json',
        },
      }
    );

    return this.normalize17TrackResponse(response.data, trackingNumber, carrierCode);
  }

  private async get17TrackStatus(): Promise<ProviderStatus> {
    return { name: '17TRACK', available: true, lastCheck: new Date().toISOString() };
  }

  private normalize17TrackResponse(data: any, trackingNumber: string, carrierCode: string): TrackingResult {
    const trackInfo = data?.data?.accept?.[0] || data?.data?.track_info?.[0];
    
    if (!trackInfo) {
      throw new AppError(404, 'Tracking info not found', 'NOT_FOUND');
    }

    const events: TrackingEvent[] = (trackInfo.details || []).map((detail: any) => ({
      timestamp: detail.time,
      status: this.map17TrackStatus(detail.status),
      description: detail.desc,
      location: detail.location,
      facilityName: detail.location,
    }));

    return {
      trackingNumber,
      carrierCode,
      carrierName: trackInfo.carrier_name || carrierCode,
      status: this.map17TrackStatus(trackInfo.status),
      statusDescription: trackInfo.status_description || '',
      lastUpdate: trackInfo.last_update || new Date().toISOString(),
      estimatedDelivery: trackInfo.estimated_delivery,
      events: events.reverse(),
      sender: trackInfo.sender,
      recipient: trackInfo.recipient,
      origin: trackInfo.origin,
      destination: trackInfo.destination,
      currentLocation: trackInfo.current_location,
    };
  }

  // AfterShip Implementation
  private async trackAfterShip(trackingNumber: string, carrierCode: string): Promise<TrackingResult> {
    const response = await axios.get(
      `https://api.aftership.com/v4/trackings/${carrierCode}/${trackingNumber}`,
      {
        headers: {
          'aftership-api-key': process.env.TRACKING_AFTERSHIP_API_KEY!,
        },
      }
    );

    return this.normalizeAfterShipResponse(response.data, trackingNumber, carrierCode);
  }

  private async getAfterShipStatus(): Promise<ProviderStatus> {
    return { name: 'AfterShip', available: true, lastCheck: new Date().toISOString() };
  }

  private normalizeAfterShipResponse(data: any, trackingNumber: string, carrierCode: string): TrackingResult {
    const tracking = data?.data?.tracking;
    
    if (!tracking) {
      throw new AppError(404, 'Tracking info not found', 'NOT_FOUND');
    }

    const events: TrackingEvent[] = (tracking.checkpoints || []).map((cp: any) => ({
      timestamp: cp.checkpoint_time,
      status: this.mapAfterShipStatus(cp.status),
      description: cp.message,
      location: cp.location,
      facilityName: cp.location,
    }));

    return {
      trackingNumber,
      carrierCode,
      carrierName: tracking.courier_name || carrierCode,
      status: this.mapAfterShipStatus(tracking.tag),
      statusDescription: tracking.tag,
      lastUpdate: tracking.updated_at || new Date().toISOString(),
      estimatedDelivery: tracking.estimated_delivery_date,
      events: events.reverse(),
      sender: tracking.origin_info?.name,
      recipient: tracking.destination_info?.name,
      origin: tracking.origin_info?.country_iso3,
      destination: tracking.destination_info?.country_iso3,
      currentLocation: tracking.checkpoints?.[0]?.location,
    };
  }

  // Ship24 Implementation
  private async trackShip24(trackingNumber: string, carrierCode: string): Promise<TrackingResult> {
    const response = await axios.post(
      'https://api.ship24.com/public/v1/tracking/search',
      {
        trackingNumber,
        courierCode: carrierCode,
      },
      {
        headers: {
          'Authorization': `Bearer ${process.env.TRACKING_SHIP24_API_KEY}`,
          'Content-Type': 'application/json',
        },
      }
    );

    return this.normalizeShip24Response(response.data, trackingNumber, carrierCode);
  }

  /**
   * Provider-side carrier detection (Ship24 search without a courier filter).
   * Returns Ship24's own courier slug - if it is not one of our carrier codes
   * the caller treats the result as "not detected" rather than guessing.
   */
  private async detectCarrierShip24(trackingNumber: string): Promise<string | null> {
    const response = await axios.post(
      'https://api.ship24.com/public/v1/tracking/search',
      { trackingNumber },
      {
        headers: {
          'Authorization': `Bearer ${process.env.TRACKING_SHIP24_API_KEY}`,
          'Content-Type': 'application/json',
        },
      }
    );

    const courier = response.data?.data?.trackings?.[0]?.courier;
    const slug = courier?.slug ?? courier?.code;
    return typeof slug === 'string' && slug.trim().length > 0 ? slug.trim() : null;
  }

  private async getShip24Status(): Promise<ProviderStatus> {
    return { name: 'Ship24', available: true, lastCheck: new Date().toISOString() };
  }

  private normalizeShip24Response(data: any, trackingNumber: string, carrierCode: string): TrackingResult {
    const tracking = data?.data?.trackings?.[0];
    
    if (!tracking) {
      throw new AppError(404, 'Tracking info not found', 'NOT_FOUND');
    }

    const events: TrackingEvent[] = (tracking.events || []).map((evt: any) => ({
      timestamp: evt.datetime,
      status: this.mapShip24Status(evt.status),
      description: evt.description,
      location: evt.location,
      facilityName: evt.location,
    }));

    return {
      trackingNumber,
      // With no explicit carrier (auto-detection path) fall back to the
      // courier the provider itself identified.
      carrierCode: carrierCode || tracking.courier?.slug || '',
      carrierName: tracking.courier?.name || carrierCode,
      status: this.mapShip24Status(tracking.status),
      statusDescription: tracking.statusDescription || '',
      lastUpdate: tracking.lastUpdate || new Date().toISOString(),
      estimatedDelivery: tracking.estimatedDeliveryDate,
      events: events.reverse(),
      sender: tracking.shipper?.name,
      recipient: tracking.recipient?.name,
      origin: tracking.originCountry?.name,
      destination: tracking.destinationCountry?.name,
      currentLocation: tracking.events?.[0]?.location,
    };
  }

  // Mock Provider for Development
  private async trackMock(trackingNumber: string, carrierCode: string): Promise<TrackingResult> {
    // Simulate API delay
    await new Promise(resolve => setTimeout(resolve, 500));
    
    const statuses = ['CREATED', 'IN_TRANSIT', 'ARRIVED_AT_FACILITY', 'OUT_FOR_DELIVERY', 'DELIVERED'];
    const currentStatus = statuses[Math.floor(Math.random() * statuses.length)];
    
    const events: TrackingEvent[] = statuses
      .slice(0, statuses.indexOf(currentStatus) + 1)
      .map((status, i) => ({
        timestamp: new Date(Date.now() - (statuses.length - i) * 3600000).toISOString(),
        status,
        description: this.getStatusDescription(status),
        location: ['İstanbul', 'Ankara', 'İzmir'][Math.floor(Math.random() * 3)],
      }));

    return {
      trackingNumber,
      carrierCode,
      carrierName: carrierCode,
      status: currentStatus,
      statusDescription: this.getStatusDescription(currentStatus),
      lastUpdate: new Date().toISOString(),
      estimatedDelivery: currentStatus !== 'DELIVERED' 
        ? new Date(Date.now() + 2 * 86400000).toISOString() 
        : undefined,
      events: events.reverse(),
      sender: 'Gönderici Firma',
      recipient: 'Alıcı Adı',
      origin: 'İstanbul',
      destination: 'Ankara',
      currentLocation: events[events.length - 1]?.location,
    };
  }

  private async getMockStatus(): Promise<ProviderStatus> {
    return { name: 'Mock Provider', available: true, lastCheck: new Date().toISOString() };
  }

  // Status Mapping
  private map17TrackStatus(status: number): string {
    const map: Record<number, string> = {
      0: 'CREATED',
      1: 'IN_TRANSIT',
      2: 'IN_TRANSIT',
      3: 'ARRIVED_AT_FACILITY',
      4: 'OUT_FOR_DELIVERY',
      5: 'DELIVERED',
      6: 'EXCEPTION',
      7: 'RETURNED',
      8: 'EXCEPTION',
    };
    return map[status] || 'CREATED';
  }

  private mapAfterShipStatus(status: string): string {
    const map: Record<string, string> = {
      'Pending': 'CREATED',
      'InfoReceived': 'CREATED',
      'InTransit': 'IN_TRANSIT',
      'OutForDelivery': 'OUT_FOR_DELIVERY',
      'AttemptFail': 'EXCEPTION',
      'Delivered': 'DELIVERED',
      'AvailableForPickup': 'ARRIVED_AT_FACILITY',
      'Exception': 'EXCEPTION',
      'Expired': 'EXCEPTION',
    };
    return map[status] || 'CREATED';
  }

  private mapShip24Status(status: string): string {
    const map: Record<string, string> = {
      'pending': 'CREATED',
      'in_transit': 'IN_TRANSIT',
      'arrived_at_facility': 'ARRIVED_AT_FACILITY',
      'out_for_delivery': 'OUT_FOR_DELIVERY',
      'delivered': 'DELIVERED',
      'exception': 'EXCEPTION',
      'returned': 'RETURNED',
    };
    return map[status] || 'CREATED';
  }

  private getStatusDescription(status: string): string {
    const descriptions: Record<string, string> = {
      'CREATED': 'Gönderi oluşturuldu',
      'IN_TRANSIT': 'Yolda',
      'ARRIVED_AT_FACILITY': 'İşleme merkezinde',
      'OUT_FOR_DELIVERY': 'Dağıtıma çıktı',
      'DELIVERED': 'Teslim edildi',
      'EXCEPTION': 'İstisna durumu',
      'RETURNED': 'Göndericiye döndü',
    };
    return descriptions[status] || status;
  }
}

interface TrackingProvider {
  name: string;
  track: (trackingNumber: string, carrierCode: string) => Promise<TrackingResult>;
  getStatus: () => Promise<ProviderStatus>;
  /**
   * Optional provider-side carrier detection: identify the carrier from the
   * tracking number alone. Only implemented by adapters whose API supports it
   * (Ship24); the others require an explicit carrierCode.
   */
  detectCarrier?: (trackingNumber: string) => Promise<string | null>;
}

export const trackingService = new TrackingService();