export interface CarrierInfo {
  code: string;
  name: string;
  patterns: RegExp[];
  country: string;
  isTurkish: boolean;
  priority: number; // Higher = checked first
}

class CarrierDetectionService {
  private carriers: CarrierInfo[] = [
    // Turkish Carriers - High Priority (checked first)
    {
      code: 'yurtici',
      name: 'Yurtiçi Kargo',
      patterns: [
        /^\d{13}$/,           // 13 digits
        /^YT\d{11}$/,         // YT + 11 digits
        /^YURTICI\d{10}$/i,   // YURTICI + 10 digits
      ],
      country: 'TR',
      isTurkish: true,
      priority: 100,
    },
    {
      code: 'mng',
      name: 'MNG Kargo',
      patterns: [
        /^\d{10,12}$/,        // 10-12 digits
        /^MN\d{10}$/,         // MN + 10 digits
        /^MNG\d{9}$/i,        // MNG + 9 digits
      ],
      country: 'TR',
      isTurkish: true,
      priority: 95,
    },
    {
      code: 'aras',
      name: 'Aras Kargo',
      patterns: [
        /^\d{10,13}$/,        // 10-13 digits
        /^AR\d{11}$/,         // AR + 11 digits
        /^ARAS\d{9}$/i,       // ARAS + 9 digits
      ],
      country: 'TR',
      isTurkish: true,
      priority: 90,
    },
    {
      code: 'surat',
      name: 'Sürat Kargo',
      patterns: [
        /^\d{10,12}$/,        // 10-12 digits
        /^SR\d{10}$/,         // SR + 10 digits
        /^SURAT\d{8}$/i,      // SURAT + 8 digits
      ],
      country: 'TR',
      isTurkish: true,
      priority: 85,
    },
    {
      code: 'ptt',
      name: 'PTT',
      patterns: [
        /^[A-Z]{2}\d{9}[A-Z]{2}$/,  // International format: RR123456789TR
        /^\d{13}$/,                  // 13 digits domestic
        /^PTT\d{10}$/i,             // PTT + 10 digits
      ],
      country: 'TR',
      isTurkish: true,
      priority: 80,
    },
    {
      code: 'trendyol_express',
      name: 'Trendyol Express',
      patterns: [
        /^TY\d{12}$/,         // TY + 12 digits
        /^\d{14}$/,           // 14 digits
        /^TRENDYOL\d{8}$/i,   // TRENDYOL + 8 digits
      ],
      country: 'TR',
      isTurkish: true,
      priority: 75,
    },
    {
      code: 'hepsiburada',
      name: 'Hepsiburada Lojistik',
      patterns: [
        /^HB\d{12}$/,         // HB + 12 digits
        /^HEPSIBURADA\d{8}$/i, // HEPSIBURADA + 8 digits
      ],
      country: 'TR',
      isTurkish: true,
      priority: 70,
    },
    {
      code: 'n11',
      name: 'n11 Lojistik',
      patterns: [
        /^N11\d{10}$/,        // N11 + 10 digits
        /^N11LOG\d{8}$/i,     // N11LOG + 8 digits
      ],
      country: 'TR',
      isTurkish: true,
      priority: 65,
    },
    // International Carriers
    {
      code: 'ups',
      name: 'UPS',
      patterns: [
        /^1Z[A-Z0-9]{16}$/,   // Standard UPS: 1Z + 16 alphanumeric
        /^\d{10,12}$/,        // UPS Freight: 10-12 digits
        /^T\d{10}$/,          // UPS Mail Innovations
      ],
      country: 'US',
      isTurkish: false,
      priority: 50,
    },
    {
      code: 'fedex',
      name: 'FedEx',
      patterns: [
        /^\d{12,14}$/,        // 12-14 digits
        /^\d{15}$/,           // 15 digits (FedEx Ground)
        /^FDX\d{11}$/i,       // FDX + 11 digits
        /^[A-Z]{2}\d{9}[A-Z]{2}$/, // International format
      ],
      country: 'US',
      isTurkish: false,
      priority: 45,
    },
    {
      code: 'dhl',
      name: 'DHL',
      patterns: [
        /^\d{10,11}$/,        // 10-11 digits
        /^[A-Z]{3}\d{7}$/,    // JJD format: 3 letters + 7 digits
        /^[A-Z]{2}\d{9}[A-Z]{2}$/, // International format
        /^JD\d{13,15}$/i,     // JD + 13-15 digits (DHL eCommerce)
      ],
      country: 'DE',
      isTurkish: false,
      priority: 40,
    },
    {
      code: 'tnt',
      name: 'TNT',
      patterns: [
        /^\d{9}$/,            // 9 digits
        /^GD\d{12}$/,         // GD + 12 digits
        /^[A-Z]{2}\d{9}[A-Z]{2}$/, // International format
      ],
      country: 'NL',
      isTurkish: false,
      priority: 35,
    },
    {
      code: 'dpd',
      name: 'DPD',
      patterns: [
        /^\d{14,15}$/,        // 14-15 digits
        /^[A-Z]{2}\d{9}[A-Z]{2}$/, // International format
      ],
      country: 'FR',
      isTurkish: false,
      priority: 30,
    },
    {
      code: 'gls',
      name: 'GLS',
      patterns: [
        /^\d{11,12}$/,        // 11-12 digits
        /^[A-Z]{2}\d{9}[A-Z]{2}$/, // International format
      ],
      country: 'NL',
      isTurkish: false,
      priority: 25,
    },
    {
      code: 'hermes',
      name: 'Hermes / Evri',
      patterns: [
        /^\d{16}$/,           // 16 digits
        /^[A-Z]{2}\d{9}[A-Z]{2}$/, // International format
      ],
      country: 'DE',
      isTurkish: false,
      priority: 20,
    },
    // Turkish E-commerce specific carriers
    {
      code: 'cargonet',
      name: 'Cargonet',
      patterns: [
        /^CN\d{11}$/,         // CN + 11 digits
        /^CARGONET\d{8}$/i,   // CARGONET + 8 digits
      ],
      country: 'TR',
      isTurkish: true,
      priority: 60,
    },
    {
      code: 'kargomatik',
      name: 'Kargomatik',
      patterns: [
        /^KM\d{11}$/,         // KM + 11 digits
        /^KARGOMATIK\d{7}$/i, // KARGOMATIK + 7 digits
      ],
      country: 'TR',
      isTurkish: true,
      priority: 55,
    },
    {
      code: 'sendeo',
      name: 'Sendeo',
      patterns: [
        /^SD\d{11}$/,         // SD + 11 digits
        /^SENDEO\d{8}$/i,     // SENDEO + 8 digits
      ],
      country: 'TR',
      isTurkish: true,
      priority: 50,
    },
  ];

  constructor() {
    // Sort carriers by priority (highest first)
    this.carriers.sort((a, b) => b.priority - a.priority);
  }

  detectCarrier(trackingNumber: string): string | null {
    const cleanNumber = trackingNumber.trim().toUpperCase().replace(/\s+/g, '');
    
    if (cleanNumber.length < 5 || cleanNumber.length > 50) {
      return null;
    }

    // Carriers are already sorted by priority
    for (const carrier of this.carriers) {
      for (const pattern of carrier.patterns) {
        if (pattern.test(cleanNumber)) {
          return carrier.code;
        }
      }
    }

    return null;
  }

  getSupportedCarriers(): CarrierInfo[] {
    return this.carriers.map(c => ({
      code: c.code,
      name: c.name,
      patterns: c.patterns,
      country: c.country,
      isTurkish: c.isTurkish,
      priority: c.priority,
    }));
  }

  getCarrierByCode(code: string): CarrierInfo | undefined {
    return this.carriers.find(c => c.code === code);
  }

  getTurkishCarriers(): CarrierInfo[] {
    return this.carriers.filter(c => c.isTurkish);
  }

  getInternationalCarriers(): CarrierInfo[] {
    return this.carriers.filter(c => !c.isTurkish);
  }

  validateTrackingNumber(trackingNumber: string, carrierCode?: string): boolean {
    const cleanNumber = trackingNumber.trim().toUpperCase().replace(/\s+/g, '');
    
    if (cleanNumber.length < 5 || cleanNumber.length > 50) {
      return false;
    }

    if (carrierCode) {
      const carrier = this.getCarrierByCode(carrierCode);
      if (!carrier) return false;
      
      return carrier.patterns.some(pattern => pattern.test(cleanNumber));
    }

    // Check against all carriers
    return this.carriers.some(carrier => 
      carrier.patterns.some(pattern => pattern.test(cleanNumber))
    );
  }

  // Get carrier info for display
  getCarrierDisplayInfo(code: string): { name: string; code: string; isTurkish: boolean } | null {
    const carrier = this.getCarrierByCode(code);
    if (!carrier) return null;
    return {
      name: carrier.name,
      code: carrier.code,
      isTurkish: carrier.isTurkish,
    };
  }
}

export const carrierDetectionService = new CarrierDetectionService();