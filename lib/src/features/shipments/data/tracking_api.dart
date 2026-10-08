import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kargom_nerede/src/core/errors/app_exceptions.dart';
import 'package:kargom_nerede/src/core/extensions/extensions.dart';
import 'package:kargom_nerede/src/core/network/api_client.dart';
import 'package:kargom_nerede/src/core/utils/app_utils.dart';
import 'package:kargom_nerede/src/shared/models/carrier.dart';
import 'package:kargom_nerede/src/shared/models/shipment.dart';
import 'package:kargom_nerede/src/shared/providers/app_providers.dart';

/// One timeline entry from the backend `POST /tracking/track` response.
class TrackEvent {
  const TrackEvent({
    required this.timestamp,
    required this.status,
    required this.description,
    this.location,
    this.facilityName,
  });

  final DateTime timestamp;
  final String status;
  final String description;
  final String? location;
  final String? facilityName;

  /// Parses a single backend event.
  ///
  /// Returns `null` when the timestamp or status is missing/unusable - such
  /// an event is dropped instead of being given an invented time, so the
  /// timeline only ever contains real provider data.
  static TrackEvent? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final timestamp = DateTime.tryParse('${raw['timestamp'] ?? ''}');
    if (timestamp == null) return null;
    final status = '${raw['status'] ?? ''}';
    if (status.isEmpty) return null;
    return TrackEvent(
      timestamp: timestamp,
      status: status,
      description: '${raw['description'] ?? ''}',
      location: raw['location']?.toString(),
      facilityName: raw['facilityName']?.toString(),
    );
  }

  TrackingEvent toTrackingEvent() => TrackingEvent(
        id: AppUtils.generateId(),
        timestamp: timestamp,
        status: status,
        description: description,
        location: location,
        facilityName: facilityName,
      );
}

/// One shipment exactly as returned by the backend `POST /tracking/track`
/// endpoint.
///
/// Field-for-field mirror of the backend `TrackingResult` interface
/// (`backend/src/services/trackingService.ts`). Status, timeline, dates and
/// locations in the UI all originate here - the local repository only caches
/// them (history), it never invents them.
class TrackResult {
  const TrackResult({
    required this.trackingNumber,
    required this.carrierCode,
    required this.carrierName,
    required this.status,
    this.statusDescription,
    required this.lastUpdate,
    this.estimatedDelivery,
    this.events = const [],
    this.sender,
    this.recipient,
    this.origin,
    this.destination,
    this.currentLocation,
    this.rawData,
  });

  final String trackingNumber;
  final String carrierCode;
  final String carrierName;
  final String status;
  final String? statusDescription;
  final DateTime lastUpdate;
  final DateTime? estimatedDelivery;
  final List<TrackEvent> events;
  final String? sender;
  final String? recipient;
  final String? origin;
  final String? destination;
  final String? currentLocation;
  final Map<String, dynamic>? rawData;

  factory TrackResult.fromJson(Map<String, dynamic> json) {
    final trackingNumber = json['trackingNumber']?.toString() ?? '';
    final carrierCode = json['carrierCode']?.toString() ?? '';
    final status = json['status']?.toString() ?? '';
    final lastUpdate = DateTime.tryParse(json['lastUpdate']?.toString() ?? '');

    if (trackingNumber.isEmpty || carrierCode.isEmpty || status.isEmpty) {
      throw const FormatException(
        'tracking response is missing trackingNumber/carrierCode/status',
      );
    }
    if (lastUpdate == null) {
      throw const FormatException('tracking response has no usable lastUpdate');
    }

    return TrackResult(
      trackingNumber: trackingNumber,
      carrierCode: carrierCode,
      carrierName: json['carrierName']?.toString() ?? '',
      status: status,
      statusDescription: json['statusDescription']?.toString(),
      lastUpdate: lastUpdate,
      estimatedDelivery:
          DateTime.tryParse(json['estimatedDelivery']?.toString() ?? ''),
      events: (json['events'] as List<dynamic>? ?? const <dynamic>[])
          .map(TrackEvent.tryParse)
          .whereType<TrackEvent>()
          .toList(),
      sender: json['sender']?.toString(),
      recipient: json['recipient']?.toString(),
      origin: json['origin']?.toString(),
      destination: json['destination']?.toString(),
      currentLocation: json['currentLocation']?.toString(),
      rawData: json,
    );
  }

  /// Builds the [Shipment] to store in the local repository.
  ///
  /// Provider data is preserved as-is; only identity (`id`, `customName`,
  /// `createdAt`) is local. When refreshing an existing shipment, pass its
  /// identity so the record is updated in place instead of duplicated.
  Shipment toShipment({String? id, String? customName, DateTime? createdAt}) {
    // Prefer the app's own carrier names so the UI stays consistent with the
    // carrier picker; fall back to whatever the provider called it.
    final registryName = CarrierRegistry.byCode(carrierCode)?.name;
    return Shipment(
      id: id ?? AppUtils.generateId(),
      trackingNumber: trackingNumber.normalizeTrackingNumber(),
      carrierCode: carrierCode,
      carrierName: (registryName?.isNotEmpty ?? false)
          ? registryName!
          : (carrierName.trim().isNotEmpty ? carrierName : carrierCode),
      customName: customName,
      status: status,
      lastUpdate: lastUpdate,
      estimatedDelivery: estimatedDelivery,
      sender: sender,
      recipient: recipient,
      currentLocation: currentLocation,
      origin: origin,
      destination: destination,
      events: [for (final event in events) event.toTrackingEvent()],
      isDelivered: status.toUpperCase() == 'DELIVERED',
      hasException: status.toUpperCase() == 'EXCEPTION',
      createdAt: createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
      rawData: rawData,
    );
  }
}

/// Client for the backend's tracking endpoints.
///
/// Every path is relative to `AppConstants.baseUrl`, which carries the
/// canonical `/api/v1` prefix the backend mounts (`backend/src/index.ts`):
///
/// * `POST /api/v1/tracking/detect-carrier` - carrier detection
/// * `POST /api/v1/tracking/track`          - real provider tracking
class TrackingApi {
  TrackingApi(this._client);

  final ApiClient _client;

  static const String detectPath = '/tracking/detect-carrier';
  static const String trackPath = '/tracking/track';
  static const Duration detectTimeout = Duration(seconds: 4);

  /// Carrier detection.
  ///
  /// Returns the carrier code the backend resolved, or `null` when the
  /// backend says `detected: false` (ambiguous/unknown format and no provider
  /// answer) or the request fails. The caller then shows
  /// "Kargo firması algılanamadı" - this never falls back to a guess.
  Future<String?> detectCarrier(
    String trackingNumber, {
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _client.post<dynamic>(
        detectPath,
        data: {'trackingNumber': trackingNumber},
        options: Options(
          sendTimeout: detectTimeout,
          receiveTimeout: detectTimeout,
        ),
        cancelToken: cancelToken,
      );
      if (response.statusCode != 200) return null;

      final body = response.data;
      if (body is! Map || body['success'] != true) return null;

      final data = body['data'];
      if (data is! Map || data['detected'] != true) return null;
      if ('${data['trackingNumber'] ?? ''}' != trackingNumber) return null;

      final code = '${data['carrierCode'] ?? ''}';
      if (code.isEmpty) return null;
      // Only codes the app actually knows are usable; a provider slug that
      // is not in the registry is reported as "not detected" so the user
      // picks the carrier manually.
      if (CarrierRegistry.byCode(code) == null) return null;
      return code;
    } catch (_) {
      // Network failure / 5xx: detection is best-effort by design.
      return null;
    }
  }

  /// Real tracking lookup - the backend asks the configured tracking
  /// provider, so the result carries live status/timeline data.
  ///
  /// Throws an [AppException] with a user-facing message when the backend or
  /// provider fails (e.g. code `PROVIDER_NOT_CONFIGURED` when no API key is
  /// configured). Nothing is fabricated on failure.
  Future<TrackResult> track({
    required String trackingNumber,
    required String carrierCode,
  }) async {
    final Response<dynamic> response;
    try {
      response = await _client.post<dynamic>(
        trackPath,
        data: {
          'trackingNumber': trackingNumber,
          'carrierCode': carrierCode,
        },
      );
    } on DioException catch (error) {
      // 5xx responses arrive as DioException (the client accepts < 500), so
      // read the backend's error body first and only fall back to transport
      // errors when there is no response.
      final serverError =
          errorFromResponse(error.response?.statusCode, error.response?.data);
      if (serverError != null) throw serverError;
      throw _transportException(error, trackingNumber, carrierCode);
    }

    final serverError = errorFromResponse(response.statusCode, response.data);
    if (serverError != null) throw serverError;

    final body = response.data;
    if (body is! Map || body['success'] != true || body['data'] is! Map) {
      throw TrackingException(
        message: 'Takip servisinden geçersiz yanıt alındı',
        code: 'INVALID_RESPONSE',
        trackingNumber: trackingNumber,
        carrierCode: carrierCode,
      );
    }

    try {
      return TrackResult.fromJson(Map<String, dynamic>.from(body['data'] as Map));
    } on FormatException catch (error) {
      throw TrackingException(
        message: 'Takip yanıtı okunamadı: ${error.message}',
        code: 'PARSE_ERROR',
        trackingNumber: trackingNumber,
        carrierCode: carrierCode,
      );
    }
  }

  /// Maps a non-2xx backend response (`{error, message, code}`) to an
  /// [AppException] carrying the backend's own message.
  static TrackingException? errorFromResponse(int? statusCode, Object? data) {
    if (statusCode == null || (statusCode >= 200 && statusCode < 300)) {
      return null;
    }
    final body = data is Map ? data : const <String, dynamic>{};
    final message = body['message']?.toString().trim() ?? '';
    final code = body['code']?.toString() ?? 'HTTP_$statusCode';
    return TrackingException(
      message: message.isEmpty ? 'Takip bilgisi alınamadı (HTTP $statusCode)' : message,
      code: code,
    );
  }

  static AppException _transportException(
    DioException error,
    String trackingNumber,
    String carrierCode,
  ) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return TimeoutException(originalError: error);
      case DioExceptionType.connectionError:
        return NoInternetException(
          message: 'Sunucuya ulaşılamıyor. İnternet bağlantınızı kontrol edin.',
          originalError: error,
        );
      default:
        return NetworkException(
          message: 'Takip servisine ulaşılamadı.',
          code: 'NETWORK_ERROR',
          originalError: error,
        );
    }
  }
}

final trackingApiProvider = Provider<TrackingApi>(
  (ref) => TrackingApi(ref.read(apiClientProvider)),
);
