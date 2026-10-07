import 'package:flutter/material.dart';

class AppSettings {
  final ThemeMode themeMode;
  final Locale locale;
  final bool notificationsEnabled;
  final bool wifiOnlySync;
  final String defaultTrackingProvider;
  final String defaultCarrier;
  final bool autoRefresh;
  final int refreshIntervalMinutes;
  final bool showDeliveredShipments;
  final int maxShipmentsPerPage;
  final bool biometricAuth;
  final bool analyticsEnabled;
  final bool debugMode;

  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.locale = const Locale('tr'),
    this.notificationsEnabled = true,
    this.wifiOnlySync = false,
    this.defaultTrackingProvider = '17track',
    this.defaultCarrier = '',
    this.autoRefresh = true,
    this.refreshIntervalMinutes = 15,
    this.showDeliveredShipments = true,
    this.maxShipmentsPerPage = 20,
    this.biometricAuth = false,
    this.analyticsEnabled = true,
    this.debugMode = false,
  });

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      themeMode: ThemeMode.values[json['themeMode'] as int? ?? 0],
      locale: Locale(json['locale'] as String? ?? 'tr'),
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      wifiOnlySync: json['wifiOnlySync'] as bool? ?? false,
      defaultTrackingProvider: json['defaultTrackingProvider'] as String? ?? '17track',
      defaultCarrier: json['defaultCarrier'] as String? ?? '',
      autoRefresh: json['autoRefresh'] as bool? ?? true,
      refreshIntervalMinutes: json['refreshIntervalMinutes'] as int? ?? 15,
      showDeliveredShipments: json['showDeliveredShipments'] as bool? ?? true,
      maxShipmentsPerPage: json['maxShipmentsPerPage'] as int? ?? 20,
      biometricAuth: json['biometricAuth'] as bool? ?? false,
      analyticsEnabled: json['analyticsEnabled'] as bool? ?? true,
      debugMode: json['debugMode'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'themeMode': themeMode.index,
      'locale': locale.languageCode,
      'notificationsEnabled': notificationsEnabled,
      'wifiOnlySync': wifiOnlySync,
      'defaultTrackingProvider': defaultTrackingProvider,
      'defaultCarrier': defaultCarrier,
      'autoRefresh': autoRefresh,
      'refreshIntervalMinutes': refreshIntervalMinutes,
      'showDeliveredShipments': showDeliveredShipments,
      'maxShipmentsPerPage': maxShipmentsPerPage,
      'biometricAuth': biometricAuth,
      'analyticsEnabled': analyticsEnabled,
      'debugMode': debugMode,
    };
  }

  AppSettings copyWith({
    ThemeMode? themeMode,
    Locale? locale,
    bool? notificationsEnabled,
    bool? wifiOnlySync,
    String? defaultTrackingProvider,
    String? defaultCarrier,
    bool? autoRefresh,
    int? refreshIntervalMinutes,
    bool? showDeliveredShipments,
    int? maxShipmentsPerPage,
    bool? biometricAuth,
    bool? analyticsEnabled,
    bool? debugMode,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      locale: locale ?? this.locale,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      wifiOnlySync: wifiOnlySync ?? this.wifiOnlySync,
      defaultTrackingProvider: defaultTrackingProvider ?? this.defaultTrackingProvider,
      defaultCarrier: defaultCarrier ?? this.defaultCarrier,
      autoRefresh: autoRefresh ?? this.autoRefresh,
      refreshIntervalMinutes: refreshIntervalMinutes ?? this.refreshIntervalMinutes,
      showDeliveredShipments: showDeliveredShipments ?? this.showDeliveredShipments,
      maxShipmentsPerPage: maxShipmentsPerPage ?? this.maxShipmentsPerPage,
      biometricAuth: biometricAuth ?? this.biometricAuth,
      analyticsEnabled: analyticsEnabled ?? this.analyticsEnabled,
      debugMode: debugMode ?? this.debugMode,
    );
  }
}

class NotificationPreferences {
  final bool enabled;
  final bool newMovement;
  final bool arrivedAtFacility;
  final bool outForDelivery;
  final bool delivered;
  final bool exception;
  final bool delay;
  final bool returned;
  final bool wifiOnly;
  final String sound;
  final bool vibration;
  final bool showPreview;

  const NotificationPreferences({
    this.enabled = true,
    this.newMovement = true,
    this.arrivedAtFacility = true,
    this.outForDelivery = true,
    this.delivered = true,
    this.exception = true,
    this.delay = true,
    this.returned = true,
    this.wifiOnly = false,
    this.sound = 'default',
    this.vibration = true,
    this.showPreview = true,
  });

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      enabled: json['enabled'] as bool? ?? true,
      newMovement: json['newMovement'] as bool? ?? true,
      arrivedAtFacility: json['arrivedAtFacility'] as bool? ?? true,
      outForDelivery: json['outForDelivery'] as bool? ?? true,
      delivered: json['delivered'] as bool? ?? true,
      exception: json['exception'] as bool? ?? true,
      delay: json['delay'] as bool? ?? true,
      returned: json['returned'] as bool? ?? true,
      wifiOnly: json['wifiOnly'] as bool? ?? false,
      sound: json['sound'] as String? ?? 'default',
      vibration: json['vibration'] as bool? ?? true,
      showPreview: json['showPreview'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'newMovement': newMovement,
      'arrivedAtFacility': arrivedAtFacility,
      'outForDelivery': outForDelivery,
      'delivered': delivered,
      'exception': exception,
      'delay': delay,
      'returned': returned,
      'wifiOnly': wifiOnly,
      'sound': sound,
      'vibration': vibration,
      'showPreview': showPreview,
    };
  }

  NotificationPreferences copyWith({
    bool? enabled,
    bool? newMovement,
    bool? arrivedAtFacility,
    bool? outForDelivery,
    bool? delivered,
    bool? exception,
    bool? delay,
    bool? returned,
    bool? wifiOnly,
    String? sound,
    bool? vibration,
    bool? showPreview,
  }) {
    return NotificationPreferences(
      enabled: enabled ?? this.enabled,
      newMovement: newMovement ?? this.newMovement,
      arrivedAtFacility: arrivedAtFacility ?? this.arrivedAtFacility,
      outForDelivery: outForDelivery ?? this.outForDelivery,
      delivered: delivered ?? this.delivered,
      exception: exception ?? this.exception,
      delay: delay ?? this.delay,
      returned: returned ?? this.returned,
      wifiOnly: wifiOnly ?? this.wifiOnly,
      sound: sound ?? this.sound,
      vibration: vibration ?? this.vibration,
      showPreview: showPreview ?? this.showPreview,
    );
  }
}

class NotificationSettings {
  final bool enabled;
  final bool wifiOnly;
  final bool newMovement;
  final bool outForDelivery;
  final bool delivered;
  final bool exception;
  final bool delay;

  const NotificationSettings({
    this.enabled = true,
    this.wifiOnly = false,
    this.newMovement = true,
    this.outForDelivery = true,
    this.delivered = true,
    this.exception = true,
    this.delay = true,
  });

  NotificationSettings copyWith({
    bool? enabled,
    bool? wifiOnly,
    bool? newMovement,
    bool? outForDelivery,
    bool? delivered,
    bool? exception,
    bool? delay,
  }) {
    return NotificationSettings(
      enabled: enabled ?? this.enabled,
      wifiOnly: wifiOnly ?? this.wifiOnly,
      newMovement: newMovement ?? this.newMovement,
      outForDelivery: outForDelivery ?? this.outForDelivery,
      delivered: delivered ?? this.delivered,
      exception: exception ?? this.exception,
      delay: delay ?? this.delay,
    );
  }
}