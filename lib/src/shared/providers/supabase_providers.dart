import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kargom_nerede/src/shared/models/app_config.dart';
import 'package:kargom_nerede/src/core/constants/app_constants.dart';
import 'package:kargom_nerede/src/core/errors/app_exceptions.dart';

/// Supabase client provider
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

/// App config provider - fetches configuration from Supabase
final appConfigProvider = FutureProvider<AppConfig>((ref) async {
  final supabase = ref.watch(supabaseClientProvider);
  
  try {
    final response = await supabase
        .from('app_config')
        .select()
        .eq('id', 'main')
        .single();
    
    final config = AppConfig.fromJson(response);
    
    // Set current app version for comparison
    final packageInfo = await PackageInfo.fromPlatform();
    AppConfig.setCurrentAppVersion(packageInfo.version);
    
    // Cache the config for offline use
    await _cacheConfig(config);
    
    return config;
  } catch (e) {
    // Try to get cached config on error
    final cached = await _getCachedConfig();
    if (cached != null) {
      return cached;
    }
    throw ConfigurationException(
      message: 'Uygulama yapılandırması yüklenemedi: ${e.toString()}',
      originalError: e,
    );
  }
});

/// Update status provider - determines what kind of update is needed
final updateStatusProvider = Provider<UpdateStatus>((ref) {
  final configAsync = ref.watch(appConfigProvider);
  
  return configAsync.when(
    data: (config) => UpdateStatus.fromConfig(config),
    loading: () => const UpdateStatus.loading(),
    error: (_, __) => const UpdateStatus.offline(),
  );
});

/// Update status model
class UpdateStatus {
  final UpdateType type;
  final String? message;
  final String? downloadUrl;
  final String? latestVersion;
  final String? minimumVersion;
  final bool isLoading;
  final bool isOffline;

  const UpdateStatus._({
    this.type = UpdateType.none,
    this.message,
    this.downloadUrl,
    this.latestVersion,
    this.minimumVersion,
    this.isLoading = false,
    this.isOffline = false,
  });

  const UpdateStatus.loading() : this._(isLoading: true);
  const UpdateStatus.offline() : this._(isOffline: true);
  
  factory UpdateStatus.fromConfig(AppConfig config) {
    switch (config.updateType) {
      case UpdateType.force:
        return UpdateStatus._(
          type: UpdateType.force,
          message: config.updateMessage,
          downloadUrl: config.downloadUrl,
          latestVersion: config.latestVersion,
          minimumVersion: config.minimumVersion,
        );
      case UpdateType.optional:
        return UpdateStatus._(
          type: UpdateType.optional,
          message: config.updateMessage,
          downloadUrl: config.downloadUrl,
          latestVersion: config.latestVersion,
          minimumVersion: config.minimumVersion,
        );
      case UpdateType.none:
      default:
        return const UpdateStatus._();
    }
  }

  bool get showForceUpdate => type == UpdateType.force;
  bool get showOptionalUpdate => type == UpdateType.optional;
  bool get noUpdateNeeded => type == UpdateType.none;
}

/// Initialize Supabase
Future<void> initializeSupabase() async {
  const url = String.fromEnvironment('SUPABASE_URL');
  const anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  
  if (url.isEmpty || anonKey.isEmpty) {
    throw ConfigurationException(
      message: 'Supabase configuration missing. Please set SUPABASE_URL and SUPABASE_ANON_KEY.',
      code: 'MISSING_SUPABASE_CONFIG',
    );
  }
  
  await Supabase.initialize(
    url: url,
    anonKey: anonKey,
  );
}

/// Cache config for offline use
Future<void> _cacheConfig(AppConfig config) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(AppConstants.keyAppConfigCache, jsonEncode(config.toJson()));
  await prefs.setInt(AppConstants.keyAppConfigCacheTime, DateTime.now().millisecondsSinceEpoch);
}

/// Get cached config
Future<AppConfig?> _getCachedConfig() async {
  final prefs = await SharedPreferences.getInstance();
  final cachedJson = prefs.getString(AppConstants.keyAppConfigCache);
  final cacheTime = prefs.getInt(AppConstants.keyAppConfigCacheTime) ?? 0;
  
  // Cache valid for 7 days
  if (cachedJson != null && 
      DateTime.now().millisecondsSinceEpoch - cacheTime < 7 * 24 * 60 * 60 * 1000) {
    try {
      return AppConfig.fromJson(jsonDecode(cachedJson));
    } catch (_) {
      return null;
    }
  }
  return null;
}