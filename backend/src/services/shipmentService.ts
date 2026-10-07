// Shipment Service - Handles CRUD operations for shipments
// In production, this would use a database (PostgreSQL with Drizzle ORM)

export interface Shipment {
  id: string;
  userId: string;
  trackingNumber: string;
  carrierCode: string;
  carrierName: string;
  customName?: string;
  status: string;
  lastUpdate: string;
  estimatedDelivery?: string;
  events: any[];
  sender?: string;
  recipient?: string;
  origin?: string;
  destination?: string;
  currentLocation?: string;
  isArchived: boolean;
  createdAt: string;
  updatedAt: string;
}

export interface ShipmentListResult {
  shipments: Shipment[];
  total: number;
  page: number;
  limit: number;
  totalPages: number;
}

class ShipmentService {
  private shipments: Map<string, Shipment> = new Map();

  constructor() {
    // Add some mock data for development
    this.initializeMockData();
  }

  private initializeMockData() {
    const mockShipments: Shipment[] = [
      {
        id: 'shipment_1',
        userId: 'user_1',
        trackingNumber: '1234567890123',
        carrierCode: 'yurtici',
        carrierName: 'Yurtiçi Kargo',
        customName: 'Yeni Kulaklık',
        status: 'OUT_FOR_DELIVERY',
        lastUpdate: new Date().toISOString(),
        estimatedDelivery: new Date(Date.now() + 3600000).toISOString(),
        events: [
          { timestamp: new Date(Date.now() - 86400000).toISOString(), status: 'CREATED', description: 'Gönderi oluşturuldu', location: 'İstanbul' },
          { timestamp: new Date(Date.now() - 43200000).toISOString(), status: 'IN_TRANSIT', description: 'Yola çıktı', location: 'İstanbul' },
          { timestamp: new Date(Date.now() - 7200000).toISOString(), status: 'ARRIVED_AT_FACILITY', description: 'Ankara transfer merkezine ulaştı', location: 'Ankara' },
          { timestamp: new Date(Date.now() - 1800000).toISOString(), status: 'OUT_FOR_DELIVERY', description: 'Dağıtıma çıktı', location: 'Ankara' },
        ],
        sender: 'Trendyol',
        recipient: 'Ahmet Yılmaz',
        origin: 'İstanbul',
        destination: 'Ankara',
        currentLocation: 'Ankara',
        isArchived: false,
        createdAt: new Date(Date.now() - 86400000).toISOString(),
        updatedAt: new Date().toISOString(),
      },
      {
        id: 'shipment_2',
        userId: 'user_1',
        trackingNumber: '9876543210',
        carrierCode: 'mng',
        carrierName: 'MNG Kargo',
        customName: 'Annemin Ayakkabısı',
        status: 'DELIVERED',
        lastUpdate: new Date(Date.now() - 7200000).toISOString(),
        estimatedDelivery: new Date(Date.now() - 7200000).toISOString(),
        events: [
          { timestamp: new Date(Date.now() - 172800000).toISOString(), status: 'CREATED', description: 'Gönderi oluşturuldu', location: 'İzmir' },
          { timestamp: new Date(Date.now() - 129600000).toISOString(), status: 'IN_TRANSIT', description: 'Yola çıktı', location: 'İzmir' },
          { timestamp: new Date(Date.now() - 43200000).toISOString(), status: 'ARRIVED_AT_FACILITY', description: 'İstanbul transfer merkezine ulaştı', location: 'İstanbul' },
          { timestamp: new Date(Date.now() - 7200000).toISOString(), status: 'DELIVERED', description: 'Teslim edildi', location: 'İstanbul' },
        ],
        sender: 'Hepsiburada',
        recipient: 'Ayşe Demir',
        origin: 'İzmir',
        destination: 'İstanbul',
        currentLocation: 'İstanbul',
        isArchived: false,
        createdAt: new Date(Date.now() - 172800000).toISOString(),
        updatedAt: new Date(Date.now() - 7200000).toISOString(),
      },
    ];

    mockShipments.forEach(s => this.shipments.set(s.id, s));
  }

  async getUserShipments(
    userId: string,
    options: { status?: string; page: number; limit: number }
  ): Promise<ShipmentListResult> {
    let userShipments = Array.from(this.shipments.values())
      .filter(s => s.userId === userId && !s.isArchived);

    if (options.status) {
      userShipments = userShipments.filter(s => s.status === options.status);
    }

    // Sort by last update descending
    userShipments.sort((a, b) => new Date(b.lastUpdate).getTime() - new Date(a.lastUpdate).getTime());

    const total = userShipments.length;
    const totalPages = Math.ceil(total / options.limit);
    const start = (options.page - 1) * options.limit;
    const shipments = userShipments.slice(start, start + options.limit);

    return {
      shipments,
      total,
      page: options.page,
      limit: options.limit,
      totalPages,
    };
  }

  async getShipment(id: string, userId: string): Promise<Shipment | null> {
    const shipment = this.shipments.get(id);
    if (shipment && shipment.userId === userId) {
      return shipment;
    }
    return null;
  }

  async createShipment(data: {
    userId: string;
    trackingNumber: string;
    carrierCode: string;
    carrierName: string;
    customName?: string;
  }): Promise<Shipment> {
    const id = `shipment_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    const now = new Date().toISOString();

    const shipment: Shipment = {
      id,
      userId: data.userId,
      trackingNumber: data.trackingNumber,
      carrierCode: data.carrierCode,
      carrierName: data.carrierName,
      customName: data.customName,
      status: 'CREATED',
      lastUpdate: now,
      events: [
        {
          timestamp: now,
          status: 'CREATED',
          description: 'Gönderi takip sistemine eklendi',
        },
      ],
      isArchived: false,
      createdAt: now,
      updatedAt: now,
    };

    this.shipments.set(id, shipment);
    return shipment;
  }

  async updateShipment(
    id: string,
    userId: string,
    data: { customName?: string; isArchived?: boolean }
  ): Promise<Shipment | null> {
    const shipment = await this.getShipment(id, userId);
    if (!shipment) return null;

    if (data.customName !== undefined) {
      shipment.customName = data.customName;
    }
    if (data.isArchived !== undefined) {
      shipment.isArchived = data.isArchived;
    }

    shipment.updatedAt = new Date().toISOString();
    this.shipments.set(id, shipment);
    return shipment;
  }

  async deleteShipment(id: string, userId: string): Promise<boolean> {
    const shipment = await this.getShipment(id, userId);
    if (!shipment) return false;

    this.shipments.delete(id);
    return true;
  }

  async refreshShipment(id: string, userId: string): Promise<Shipment | null> {
    const shipment = await this.getShipment(id, userId);
    if (!shipment) return null;

    // In production, this would call trackingService.trackShipment
    // For now, just update the timestamp
    shipment.lastUpdate = new Date().toISOString();
    shipment.updatedAt = new Date().toISOString();
    this.shipments.set(id, shipment);
    
    return shipment;
  }
}

export const shipmentService = new ShipmentService();