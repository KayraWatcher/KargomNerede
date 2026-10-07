import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../core/constants/app_constants.dart';
import '../../core/network/api_client.dart';
import '../../shared/models/settings.dart';

final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) async {
  return await SharedPreferences.getInstance();
});

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier(ref.read(sharedPreferencesProvider.future));
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final Future<SharedPreferences> _prefsFuture;
  static const _key = AppConstants.keyThemeMode;

  ThemeModeNotifier(this._prefsFuture) : super(ThemeMode.system) {
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    final prefs = await _prefsFuture;
    final themeIndex = prefs.getInt(_key) ?? 0;
    state = ThemeMode.values[themeIndex];
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = await _prefsFuture;
    await prefs.setInt(_key, mode.index);
    state = mode;
  }
}

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier(ref.read(sharedPreferencesProvider.future));
});

class LocaleNotifier extends StateNotifier<Locale> {
  final Future<SharedPreferences> _prefsFuture;
  static const _key = AppConstants.keyLanguage;

  LocaleNotifier(this._prefsFuture) : super(const Locale(AppConstants.defaultLanguage)) {
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final prefs = await _prefsFuture;
    final languageCode = prefs.getString(_key) ?? AppConstants.defaultLanguage;
    state = Locale(languageCode);
  }

  Future<void> setLocale(Locale locale) async {
    final prefs = await _prefsFuture;
    await prefs.setString(_key, locale.languageCode);
    state = locale;
  }
}

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(baseUrl: AppConstants.baseUrl);
});

final connectivityProvider = StreamProvider<ConnectivityResult>((ref) {
  // TODO: Implement with connectivity_plus
  return const Stream<ConnectivityResult>.empty();
});

class AuthState {
  final bool isAuthenticated;
  final String? userId;
  final String? email;
  final String? displayName;

  const AuthState({
    this.isAuthenticated = false,
    this.userId,
    this.email,
    this.displayName,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    String? userId,
    String? email,
    String? displayName,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      userId: userId ?? this.userId,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
    );
  }
}

final authStateProvider = StateNotifierProvider<AuthStateNotifier, AuthState>((ref) {
  return AuthStateNotifier();
});

class AuthStateNotifier extends StateNotifier<AuthState> {
  AuthStateNotifier() : super(const AuthState());

  Future<void> signIn(String email, String password) async {
    // TODO: Implement authentication
    state = state.copyWith(
      isAuthenticated: true,
      email: email,
      userId: 'user_${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  Future<void> signOut() async {
    state = const AuthState();
  }

  Future<void> checkAuthState() async {
    // TODO: Check stored token
  }
}

final trackingProviderProvider = StateNotifierProvider<TrackingProviderNotifier, String>((ref) {
  return TrackingProviderNotifier(ref.read(sharedPreferencesProvider.future));
});

class TrackingProviderNotifier extends StateNotifier<String> {
  final Future<SharedPreferences> _prefsFuture;
  static const _key = AppConstants.keyTrackingProvider;

  TrackingProviderNotifier(this._prefsFuture) : super(AppConstants.defaultTrackingProvider) {
    _loadProvider();
  }

  Future<void> _loadProvider() async {
    final prefs = await _prefsFuture;
    state = prefs.getString(_key) ?? AppConstants.defaultTrackingProvider;
  }

  Future<void> setProvider(String provider) async {
    final prefs = await _prefsFuture;
    await prefs.setString(_key, provider);
    state = provider;
  }
}

final notificationSettingsProvider = StateNotifierProvider<NotificationSettingsNotifier, NotificationSettings>((ref) {
  return NotificationSettingsNotifier(ref.read(sharedPreferencesProvider.future));
});

class NotificationSettingsNotifier extends StateNotifier<NotificationSettings> {
  final Future<SharedPreferences> _prefsFuture;

  NotificationSettingsNotifier(this._prefsFuture) : super(const NotificationSettings()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await _prefsFuture;
    state = NotificationSettings(
      enabled: prefs.getBool(AppConstants.keyNotificationEnabled) ?? true,
      wifiOnly: prefs.getBool(AppConstants.keyWifiOnlySync) ?? false,
    );
  }

  Future<void> updateSettings(NotificationSettings settings) async {
    final prefs = await _prefsFuture;
    await prefs.setBool(AppConstants.keyNotificationEnabled, settings.enabled);
    await prefs.setBool(AppConstants.keyWifiOnlySync, settings.wifiOnly);
    state = settings;
  }
}