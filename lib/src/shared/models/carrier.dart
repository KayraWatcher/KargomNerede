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