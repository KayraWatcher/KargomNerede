class Carrier {
  final String code;
  final String name;
  final String logoUrl;
  final String? website;
  final String? trackingUrl;
  final List<String> supportedCountries;
  final List<RegExpPattern> trackingPatterns;
  final bool isActive;
  final bool isTurkishCarrier;
  final Map<String, dynamic>? metadata;

  const Carrier({
    required this.code,
    required this.name,
    required this.logoUrl,
    this.website,
    this.trackingUrl,
    this.supportedCountries = const [],
    this.trackingPatterns = const [],
    this.isActive = true,
    this.isTurkishCarrier = false,
    this.metadata,
  });

  factory Carrier.fromJson(Map<String, dynamic> json) {
    return Carrier(
      code: json['code'] as String,
      name: json['name'] as String,
      logoUrl: json['logoUrl'] as String,
      website: json['website'] as String?,
      trackingUrl: json['trackingUrl'] as String?,
      supportedCountries: (json['supportedCountries'] as List<dynamic>?)
          ?.map((e) => e as String).toList() ?? [],
      trackingPatterns: (json['trackingPatterns'] as List<dynamic>?)
          ?.map((e) => RegExpPattern.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      isActive: json['isActive'] as bool? ?? true,
      isTurkishCarrier: json['isTurkishCarrier'] as bool? ?? false,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name': name,
      'logoUrl': logoUrl,
      'website': website,
      'trackingUrl': trackingUrl,
      'supportedCountries': supportedCountries,
      'trackingPatterns': trackingPatterns.map((e) => e.toJson()).toList(),
      'isActive': isActive,
      'isTurkishCarrier': isTurkishCarrier,
      'metadata': metadata,
    };
  }

  bool matchesTrackingNumber(String trackingNumber) {
    final cleanNumber = trackingNumber.trim().toUpperCase();
    return trackingPatterns.any((pattern) {
      try {
        return RegExp(pattern.pattern).hasMatch(cleanNumber);
      } catch (e) {
        return false;
      }
    });
  }

  String get displayName => name;
  
  String get shortName => name.length > 20 ? '${name.substring(0, 17)}...' : name;
}

class RegExpPattern {
  final String pattern;
  final String? description;

  const RegExpPattern({
    required this.pattern,
    this.description,
  });

  factory RegExpPattern.fromJson(Map<String, dynamic> json) {
    return RegExpPattern(
      pattern: json['pattern'] as String,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pattern': pattern,
      'description': description,
    };
  }
}

class CarrierDetectionResult {
  final Carrier carrier;
  final double confidence;
  final List<Carrier> alternatives;

  const CarrierDetectionResult({
    required this.carrier,
    required this.confidence,
    this.alternatives = const [],
  });
}

/// Single source of truth for the carriers supported by the app.
///
/// The `code` values are the carrier codes used across the whole stack
/// (backend `carrierDetectionService`, tracking providers and the local
/// shipment records), so a detected code always maps back to a real carrier.
class CarrierRegistry {
  CarrierRegistry._();

  static const List<Carrier> carriers = [
    Carrier(code: 'yurtici', name: 'Yurtiçi Kargo', logoUrl: '', isActive: true, isTurkishCarrier: true),
    Carrier(code: 'mng', name: 'MNG Kargo', logoUrl: '', isActive: true, isTurkishCarrier: true),
    Carrier(code: 'aras', name: 'Aras Kargo', logoUrl: '', isActive: true, isTurkishCarrier: true),
    Carrier(code: 'surat', name: 'Sürat Kargo', logoUrl: '', isActive: true, isTurkishCarrier: true),
    Carrier(code: 'ptt', name: 'PTT', logoUrl: '', isActive: true, isTurkishCarrier: true),
    Carrier(code: 'trendyol_express', name: 'Trendyol Express', logoUrl: '', isActive: true, isTurkishCarrier: true),
    Carrier(code: 'hepsijet', name: 'HepsiJet', logoUrl: '', isActive: true, isTurkishCarrier: true),
    Carrier(code: 'hepsiburada', name: 'Hepsiburada Lojistik', logoUrl: '', isActive: true, isTurkishCarrier: true),
    Carrier(code: 'n11', name: 'n11 Lojistik', logoUrl: '', isActive: true, isTurkishCarrier: true),
    Carrier(code: 'ups', name: 'UPS', logoUrl: '', isActive: true, isTurkishCarrier: false),
    Carrier(code: 'fedex', name: 'FedEx', logoUrl: '', isActive: true, isTurkishCarrier: false),
    Carrier(code: 'dhl', name: 'DHL', logoUrl: '', isActive: true, isTurkishCarrier: false),
  ];

  static Carrier? byCode(String? code) {
    if (code == null || code.isEmpty) return null;
    for (final carrier in carriers) {
      if (carrier.code == code) return carrier;
    }
    return null;
  }

  static List<Carrier> get activeCarriers =>
      carriers.where((carrier) => carrier.isActive).toList();

  /// Display name for a carrier code; falls back to a formatted code so an
  /// unknown (but backend-detected) code is still readable.
  static String displayNameOf(String code, String Function(String) formatter) {
    return byCode(code)?.name ?? formatter(code);
  }
}