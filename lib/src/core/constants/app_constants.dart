class AppConstants {
  AppConstants._();

  static const String appName = 'Kargom Nerede';
  static const String appVersion = '1.0.0';
  static const String packageName = 'com.kargomnerede.kargom_nerede';

  // API
  //
  // Canonical prefix: the backend mounts every endpoint under `/api/v1`
  // (see `backend/src/index.ts`), so the app calls
  // `<origin>/api/v1/tracking/...`. Keep this in sync with
  // `backend/.env.example` (API_BASE_URL).
  //
  // NOTE: `api.kargomnerede.com` currently has NO DNS record (the apex
  // domain resolves, the `api` subdomain does not) - the production backend
  // is not deployed yet. That is a deployment/DNS task; the app does not
  // hide it. For a local/staging backend, override without editing code:
  //   flutter build apk --dart-define=API_BASE_URL=http://10.0.2.2:3000/api/v1
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.kargomnerede.com/api/v1',
  );
  static const int apiTimeoutSeconds = 30;
  static const int maxRetryAttempts = 3;

  // Tracking Providers
  static const String trackingProvider17Track = '17track';
  static const String trackingProviderAfterShip = 'aftership';
  static const String trackingProviderShip24 = 'ship24';

  // Default tracking provider
  static const String defaultTrackingProvider = trackingProvider17Track;

  // Cache
  static const Duration cacheExpiration = Duration(hours: 24);
  static const int maxCachedShipments = 100;

  // Notifications
  static const String notificationChannelId = 'shipment_updates';
  static const String notificationChannelName = 'Kargo Güncellemeleri';
  static const String notificationChannelDescription = 'Kargo durum değişiklikleri için bildirimler';

  // Polling intervals
  static const Duration pollingIntervalActive = Duration(minutes: 15);
  static const Duration pollingIntervalDelivered = Duration(hours: 6);
  static const Duration pollingIntervalException = Duration(minutes: 30);

  // Storage keys
  static const String keyTrackingProvider = 'tracking_provider';
  static const String keyThemeMode = 'theme_mode';
  static const String keyLanguage = 'language';
  static const String keyNotificationEnabled = 'notification_enabled';
  static const String keyWifiOnlySync = 'wifi_only_sync';
  static const String keyDefaultCarrier = 'default_carrier';
  static const String keyAutoRefresh = 'auto_refresh';
  static const String keyRefreshInterval = 'refresh_interval';
  static const String keyOnboardingCompleted = 'onboarding_completed';
  static const String keyAppConfigCache = 'app_config_cache';
  static const String keyAppConfigCacheTime = 'app_config_cache_time';

  // Database
  static const String databaseName = 'kargom_nerede.db';
  static const int databaseVersion = 1;

  // UI
  static const double defaultBorderRadius = 12.0;
  static const double cardElevation = 2.0;
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration pageTransitionDuration = Duration(milliseconds: 400);

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 50;

  // Supported languages
  static const List<String> supportedLanguages = ['tr', 'en'];
  static const String defaultLanguage = 'tr';

  // Carrier detection patterns (Turkish carriers)
  //
  // Mirrors the pattern list of the backend detection service
  // (`backend/src/services/carrierDetectionService.ts`), so the app and the
  // backend agree on which carriers a number could belong to.
  //
  // Digit formats overlap (13 digits matches yurtici + aras + ptt + fedex),
  // so a carrier code is only accepted when EXACTLY ONE carrier matches -
  // see `AppUtils.detectCarrier`. Never invent a carrier here: every key
  // must exist in `CarrierRegistry` (see shared/models/carrier.dart).
  static final Map<String, List<RegExp>> carrierPatterns = {
    // Turkish carriers (also the backend's priority order for display)
    'yurtici': [
      RegExp(r'^\d{13}$'), // 13 digits
      RegExp(r'^YT\d{11}$'), // YT + 11 digits
      RegExp(r'^YURTICI\d{10}$'), // YURTICI + 10 digits
    ],
    'mng': [
      RegExp(r'^\d{10,12}$'), // 10-12 digits
      RegExp(r'^MN\d{10}$'), // MN + 10 digits
      RegExp(r'^MNG\d{9}$'), // MNG + 9 digits
    ],
    'aras': [
      RegExp(r'^\d{10,13}$'), // 10-13 digits
      RegExp(r'^AR\d{11}$'), // AR + 11 digits
      RegExp(r'^ARAS\d{9}$'), // ARAS + 9 digits
    ],
    'surat': [
      RegExp(r'^\d{10,12}$'), // 10-12 digits
      RegExp(r'^SR\d{10}$'), // SR + 10 digits
      RegExp(r'^SURAT\d{8}$'), // SURAT + 8 digits
    ],
    'ptt': [
      RegExp(r'^[A-Z]{2}\d{9}[A-Z]{2}$'), // International format: RR123456789TR
      RegExp(r'^\d{13}$'), // 13 digits domestic
      RegExp(r'^PTT\d{10}$'), // PTT + 10 digits
    ],
    'trendyol_express': [
      RegExp(r'^TY\d{12}$'), // TY + 12 digits
      RegExp(r'^\d{14}$'), // 14 digits
      RegExp(r'^TRENDYOL\d{8}$'), // TRENDYOL + 8 digits
    ],
    // HepsiJet has no publicly documented numeric-only format, so detection
    // only triggers on explicit HepsiJet prefixes. Anything ambiguous is left
    // undetected instead of being guessed.
    'hepsijet': [
      RegExp(r'^HJ\d{10,14}$'), // HJ + 10-14 digits
      RegExp(r'^HEPSIJET\d{6,14}$'), // HEPSIJET + 6-14 digits
    ],
    'hepsiburada': [
      RegExp(r'^HB\d{12}$'), // HB + 12 digits
      RegExp(r'^HEPSIBURADA\d{8}$'), // HEPSIBURADA + 8 digits
    ],
    'n11': [
      RegExp(r'^N11\d{10}$'), // N11 + 10 digits
      RegExp(r'^N11LOG\d{8}$'), // N11LOG + 8 digits
    ],
    // International carriers
    'ups': [
      RegExp(r'^1Z[A-Z0-9]{16}$'), // Standard UPS: 1Z + 16 alphanumeric
      RegExp(r'^T\d{10}$'), // UPS Mail Innovations
    ],
    'fedex': [
      RegExp(r'^FDX\d{11}$'), // FDX + 11 digits
      RegExp(r'^\d{12,14}$'), // 12-14 digits
      RegExp(r'^\d{15}$'), // 15 digits (FedEx Ground)
    ],
    'dhl': [
      RegExp(r'^[A-Z]{3}\d{7}$'), // JJD format: 3 letters + 7 digits
      RegExp(r'^JD\d{13,15}$'), // JD + 13-15 digits (DHL eCommerce)
      RegExp(r'^\d{10,11}$'), // 10-11 digits
    ],
  };

  // Standard shipment statuses
  static const List<String> standardStatuses = [
    'CREATED',
    'IN_TRANSIT',
    'ARRIVED_AT_FACILITY',
    'OUT_FOR_DELIVERY',
    'DELIVERED',
    'EXCEPTION',
    'RETURNED',
    'LOST',
    'CANCELLED',
  ];

  // Status display names (Turkish)
  static const Map<String, String> statusDisplayNames = {
    'CREATED': 'Gönderi Oluşturuldu',
    'IN_TRANSIT': 'Yolda',
    'ARRIVED_AT_FACILITY': 'İşleme Merkezinde',
    'OUT_FOR_DELIVERY': 'Dağıtıma Çıktı',
    'DELIVERED': 'Teslim Edildi',
    'EXCEPTION': 'İstisna/Problem',
    'RETURNED': 'Göndericiye Döndü',
    'LOST': 'Kayıp',
    'CANCELLED': 'İptal Edildi',
  };

  // Status colors
  static const Map<String, int> statusColors = {
    'CREATED': 0xFF2196F3,        // Blue
    'IN_TRANSIT': 0xFF00BCD4,     // Cyan
    'ARRIVED_AT_FACILITY': 0xFF9C27B0, // Purple
    'OUT_FOR_DELIVERY': 0xFFFF9800,    // Orange
    'DELIVERED': 0xFF4CAF50,      // Green
    'EXCEPTION': 0xFFF44336,      // Red
    'RETURNED': 0xFF795548,       // Brown
    'LOST': 0xFF9E9E9E,           // Grey
    'CANCELLED': 0xFF607D8B,      // Blue Grey
  };
}