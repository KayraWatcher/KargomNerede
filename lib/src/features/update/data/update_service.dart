import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kargom_nerede/src/shared/models/app_config.dart';
import 'package:kargom_nerede/src/core/errors/app_exceptions.dart';

/// Service to handle app update checks and configuration management
class UpdateService {
  final SupabaseClient _supabase;

  UpdateService(this._supabase);

  /// Fetch app configuration from Supabase
  Future<AppConfig> fetchAppConfig() async {
    try {
      final response = await _supabase
          .from('app_config')
          .select()
          .eq('id', 'main')
          .single();
      
      return AppConfig.fromJson(response);
    } on PostgrestException catch (e) {
      throw ConfigurationException(
        message: 'App config not found: ${e.message}',
        originalError: e,
      );
    } catch (e) {
      throw ConfigurationException(
        message: 'Failed to fetch app config: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Check if force update is required
  Future<UpdateCheckResult> checkForUpdates() async {
    try {
      final config = await fetchAppConfig();
      return UpdateCheckResult.fromConfig(config);
    } catch (e) {
      // On any error, allow app to continue (fail open)
      debugPrint('Update check failed (fail-open): $e');
      return UpdateCheckResult(
        shouldForceUpdate: false,
        shouldShowOptional: false,
        isOffline: true,
      );
    }
  }

  /// Get download URL from config
  String getDownloadUrl(AppConfig config) {
    return config.downloadUrl;
  }
}

/// Result of update check
@immutable
class UpdateCheckResult {
  final bool shouldForceUpdate;
  final bool shouldShowOptional;
  final bool isOffline;
  final String? message;
  final String? downloadUrl;
  final String? latestVersion;
  final String? minimumVersion;

  const UpdateCheckResult({
    this.shouldForceUpdate = false,
    this.shouldShowOptional = false,
    this.isOffline = false,
    this.message,
    this.downloadUrl,
    this.latestVersion,
    this.minimumVersion,
  });

  factory UpdateCheckResult.fromConfig(AppConfig config) {
    return UpdateCheckResult(
      shouldForceUpdate: config.updateType == UpdateType.force,
      shouldShowOptional: config.updateType == UpdateType.optional,
      isOffline: false,
      message: config.updateMessage,
      downloadUrl: config.downloadUrl,
      latestVersion: config.latestVersion,
      minimumVersion: config.minimumVersion,
    );
  }
}