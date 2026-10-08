class AppConfig {
  final String id;
  final String minimumVersion;
  final String latestVersion;
  final String downloadUrl;
  final bool forceUpdate;
  final String updateMessage;
  final DateTime updatedAt;
  final DateTime? createdAt;

  const AppConfig({
    required this.id,
    required this.minimumVersion,
    required this.latestVersion,
    required this.downloadUrl,
    required this.forceUpdate,
    required this.updateMessage,
    required this.updatedAt,
    this.createdAt,
  });

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    return AppConfig(
      id: json['id'] as String,
      minimumVersion: json['minimum_version'] as String,
      latestVersion: json['latest_version'] as String,
      downloadUrl: json['download_url'] as String,
      forceUpdate: json['force_update'] as bool,
      updateMessage: json['update_message'] as String,
      updatedAt: DateTime.parse(json['updated_at'] as String),
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'minimum_version': minimumVersion,
      'latest_version': latestVersion,
      'download_url': downloadUrl,
      'force_update': forceUpdate,
      'update_message': updateMessage,
      'updated_at': updatedAt.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
    };
  }

  /// Semantic version comparison
  /// Returns -1 if a < b, 0 if a == b, 1 if a > b
  static int compareVersions(String a, String b) {
    final aParts = a.split('.').map(int.tryParse).map((e) => e ?? 0).toList();
    final bParts = b.split('.').map(int.tryParse).map((e) => e ?? 0).toList();
    
    final maxLength = aParts.length > bParts.length ? aParts.length : bParts.length;
    
    for (int i = 0; i < maxLength; i++) {
      final aVal = i < aParts.length ? aParts[i] : 0;
      final bVal = i < bParts.length ? bParts[i] : 0;
      
      if (aVal < bVal) return -1;
      if (aVal > bVal) return 1;
    }
    return 0;
  }

  /// Check if current version is less than minimum required version
  bool get isForceUpdateRequired {
    return compareVersions(AppConfig.currentAppVersion, minimumVersion) < 0;
  }

  /// Check if there's a newer version available (optional update)
  bool get hasOptionalUpdate {
    return compareVersions(AppConfig.currentAppVersion, latestVersion) < 0;
  }

  /// Get current app version from package info
  static String get currentAppVersion {
    return AppConfig._currentAppVersion;
  }

  static String _currentAppVersion = '1.0.0';

  static void setCurrentAppVersion(String version) {
    _currentAppVersion = version;
  }

  /// Get update type based on current version
  UpdateType get updateType {
    // 1. Minimum version check always forces update
    if (isForceUpdateRequired) return UpdateType.force;
    
    // 2. If force_update flag is enabled and a newer version exists, force it
    if (forceUpdate && hasOptionalUpdate) {
      return UpdateType.force;
    }
    
    // 3. Optional update if newer version exists
    if (hasOptionalUpdate) return UpdateType.optional;
    
    return UpdateType.none;
  }
}

enum UpdateType {
  none,
  optional,
  force,
}