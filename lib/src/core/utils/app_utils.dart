import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

import '../constants/app_constants.dart';
import '../extensions/extensions.dart';

class AppUtils {
  AppUtils._();

  static final Uuid _uuid = const Uuid();
  static final Random _random = Random();

  static String generateId() => _uuid.v4();

  static String generateShortId() => _uuid.v4().substring(0, 8);

  static String generateTrackingId() => 'KN${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}${_random.nextInt(1000).toString().padLeft(3, '0')}';

  static bool isValidTrackingNumber(String trackingNumber, {String? carrierCode}) {
    final clean = trackingNumber.trim().toUpperCase();
    if (clean.isEmpty) return false;
    if (clean.length < 5 || clean.length > 30) return false;
    return true;
  }

  /// Detects the carrier of [trackingNumber] from its format alone.
  ///
  /// Uses the same pattern list as the backend detection service
  /// (`backend/src/services/carrierDetectionService.ts`) so the app and the
  /// backend agree on which carriers a number could belong to.
  ///
  /// A carrier is returned only when the number matches EXACTLY ONE known
  /// pattern. Digit-only formats overlap heavily - a 13-digit number matches
  /// Yurtiçi, Aras, PTT and FedEx; a 10-digit number matches MNG, Aras,
  /// Sürat and DHL - so those numbers return `null` (ambiguous) and the
  /// caller must ask the backend/tracking provider, or show
  /// "Kargo firması algılanamadı" and let the user pick the carrier.
  /// Ambiguous numbers are never resolved by priority order.
  static String? detectCarrier(String trackingNumber) {
    final clean = trackingNumber.normalizeTrackingNumber();
    if (clean.length < 5 || clean.length > 50) return null;

    String? matched;
    for (final entry in AppConstants.carrierPatterns.entries) {
      for (final pattern in entry.value) {
        if (pattern.hasMatch(clean)) {
          if (matched != null && matched != entry.key) {
            // Several carriers share this format: the format alone does not
            // identify the sender.
            return null;
          }
          matched = entry.key;
          break; // next carrier (patterns within a carrier share its code)
        }
      }
    }
    return matched;
  }

  static String formatBytes(int bytes, {int decimals = 2}) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    final i = (log(bytes) / log(1024)).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(decimals)} ${suffixes[i]}';
  }

  static String formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}g ${duration.inHours.remainder(24)}s';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}s ${duration.inMinutes.remainder(60)}dk';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}dk ${duration.inSeconds.remainder(60)}sn';
    } else {
      return '${duration.inSeconds}sn';
    }
  }

  static Future<void> copyToClipboard(String text, {String? successMessage}) async {
    await Clipboard.setData(ClipboardData(text: text));
  }

  static Future<void> shareText(String text, {String? subject}) async {
    // Implementation with share_plus
  }

  static Future<void> launchUrlString(String url) async {
    // Implementation with url_launcher
  }

  static Future<void> sendEmail(String email, {String? subject, String? body}) async {
    final uri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {
        if (subject != null) 'subject': subject,
        if (body != null) 'body': body,
      },
    );
    // Implementation with url_launcher
  }

  static Future<void> makePhoneCall(String phoneNumber) async {
    final uri = Uri(scheme: 'tel', path: phoneNumber);
    // Implementation with url_launcher
  }

  static Future<void> openMap(double latitude, double longitude, {String? label}) async {
    // Implementation with url_launcher
  }

  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  static String maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return email;
    final username = parts[0];
    final domain = parts[1];
    if (username.length <= 2) return email;
    return '${username[0]}${'*' * (username.length - 2)}${username[username.length - 1]}@$domain';
  }

  static String getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return '${parts[0].substring(0, 1)}${parts[1].substring(0, 1)}'.toUpperCase();
  }

  static Color getStatusColor(String status) {
    // Return color based on status
    switch (status.toUpperCase()) {
      case 'CREATED':
        return const Color(0xFF2196F3);
      case 'IN_TRANSIT':
        return const Color(0xFF00BCD4);
      case 'ARRIVED_AT_FACILITY':
        return const Color(0xFF9C27B0);
      case 'OUT_FOR_DELIVERY':
        return const Color(0xFFFF9800);
      case 'DELIVERED':
        return const Color(0xFF4CAF50);
      case 'EXCEPTION':
        return const Color(0xFFF44336);
      case 'RETURNED':
        return const Color(0xFF795548);
      case 'LOST':
        return const Color(0xFF9E9E9E);
      case 'CANCELLED':
        return const Color(0xFF607D8B);
      default:
        return Colors.grey;
    }
  }

  static String getStatusDisplayName(String status) {
    const statusNames = {
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
    return statusNames[status.toUpperCase()] ?? status;
  }

  static int getStatusOrder(String status) {
    const order = {
      'CREATED': 0,
      'IN_TRANSIT': 1,
      'ARRIVED_AT_FACILITY': 2,
      'OUT_FOR_DELIVERY': 3,
      'DELIVERED': 4,
      'EXCEPTION': 5,
      'RETURNED': 6,
      'LOST': 7,
      'CANCELLED': 8,
    };
    return order[status.toUpperCase()] ?? 99;
  }

  static List<String> getFilterOptions() {
    return [
      'Tümü',
      'Bekleyen',
      'Dağıtımda',
      'Bugün',
      'Teslim Edildi',
      'Sorunlu',
    ];
  }

  static String filterToStatus(String filter) {
    switch (filter) {
      case 'Bekleyen':
        return 'CREATED,IN_TRANSIT,ARRIVED_AT_FACILITY';
      case 'Dağıtımda':
        return 'OUT_FOR_DELIVERY';
      case 'Bugün':
        return 'OUT_FOR_DELIVERY,DELIVERED';
      case 'Teslim Edildi':
        return 'DELIVERED';
      case 'Sorunlu':
        return 'EXCEPTION,RETURNED,LOST';
      default:
        return '';
    }
  }
}

class Debouncer {
  final Duration delay;
  Timer? _timer;

  Debouncer({required this.delay});

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  void cancel() => _timer?.cancel();

  void dispose() => _timer?.cancel();
}

class Throttler {
  final Duration delay;
  DateTime? _lastRun;
  Timer? _timer;

  Throttler({required this.delay});

  void run(VoidCallback action) {
    final now = DateTime.now();
    if (_lastRun == null || now.difference(_lastRun!) >= delay) {
      _lastRun = now;
      action();
    } else {
      _timer?.cancel();
      _timer = Timer(delay - now.difference(_lastRun!), () {
        _lastRun = DateTime.now();
        action();
      });
    }
  }

  void cancel() => _timer?.cancel();

  void dispose() => _timer?.cancel();
}