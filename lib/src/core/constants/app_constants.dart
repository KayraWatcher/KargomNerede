class AppConstants {
  AppConstants._();

  static const String appName = 'KargomNerede';
  static const String appVersion = '1.0.0';
  static const String packageName = 'com.kargomnerede.kargom_nerede';

  // API
  static const String baseUrl = 'https://api.kargomnerede.com/v1';
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
  static final Map<String, List<RegExp>> carrierPatterns = {
    'yurtici': [RegExp(r'^\d{13}$'), RegExp(r'^YT\d{11}$')],
    'mng': [RegExp(r'^\d{10,12}$'), RegExp(r'^MN\d{10}$')],
    'aras': [RegExp(r'^\d{10,13}$'), RegExp(r'^AR\d{11}$')],
    'surat': [RegExp(r'^\d{10,12}$'), RegExp(r'^SR\d{10}$')],
    'yurtici_kargo': [RegExp(r'^\d{13}$')],
    'ptt': [RegExp(r'^[A-Z]{2}\d{9}[A-Z]{2}$'), RegExp(r'^\d{13}$')],
    'ups': [RegExp(r'^1Z[A-Z0-9]{16}$')],
    'fedex': [RegExp(r'^\d{12,14}$'), RegExp(r'^\d{15}$')],
    'dhl': [RegExp(r'^\d{10,11}$'), RegExp(r'^[A-Z]{3}\d{7}$')],
    'trendyol_express': [RegExp(r'^TY\d{12}$'), RegExp(r'^\d{14}$')],
    'hepsiburada': [RegExp(r'^HB\d{12}$')],
    'n11': [RegExp(r'^N11\d{10}$')],
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