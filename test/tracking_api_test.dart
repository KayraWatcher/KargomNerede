import 'package:flutter_test/flutter_test.dart';

import 'package:kargom_nerede/src/core/constants/app_constants.dart';
import 'package:kargom_nerede/src/core/errors/app_exceptions.dart';
import 'package:kargom_nerede/src/features/shipments/data/tracking_api.dart';

void main() {
  group('API path contract', () {
    test('app and backend agree on the canonical /api/v1 prefix', () {
      // The backend mounts its routes under /api/v1 (backend/src/index.ts);
      // the app must call the very same prefix.
      expect(AppConstants.baseUrl, endsWith('/api/v1'));
      expect(TrackingApi.detectPath, '/tracking/detect-carrier');
      expect(TrackingApi.trackPath, '/tracking/track');
    });
  });

  group('TrackResult.fromJson', () {
    // Field-for-field mirror of the backend `TrackingResult` interface
    // (backend/src/services/trackingService.ts) - this is the exact payload
    // shape `POST /api/v1/tracking/track` returns under `data`.
    Map<String, dynamic> payload({String status = 'OUT_FOR_DELIVERY'}) => {
          'trackingNumber': 'AR12345678901',
          'carrierCode': 'aras',
          'carrierName': 'Aras Kargo',
          'status': status,
          'statusDescription': 'Dağıtıma çıktı',
          'lastUpdate': '2026-10-08T02:47:42.112Z',
          'estimatedDelivery': '2026-10-10T02:47:42.112Z',
          'events': [
            {
              'timestamp': '2026-10-07T22:47:42.112Z',
              'status': 'IN_TRANSIT',
              'description': 'Transfer merkezine ulaştı',
              'location': 'Ankara',
              'facilityName': 'Ankara Aktarma',
            },
            {
              'timestamp': '2026-10-07T21:47:42.112Z',
              'status': 'CREATED',
              'description': 'Gönderi alındı',
              'location': 'İzmir',
            },
          ],
          'sender': 'Gönderici Firma',
          'recipient': 'Alıcı Adı',
          'origin': 'İzmir',
          'destination': 'Ankara',
          'currentLocation': 'Ankara',
        };

    test('parses status, timeline and dates into a Shipment', () {
      final result = TrackResult.fromJson(payload());
      final shipment = result.toShipment(customName: 'Anneme');

      expect(shipment.trackingNumber, 'AR12345678901');
      expect(shipment.carrierCode, 'aras');
      expect(shipment.carrierName, 'Aras Kargo');
      expect(shipment.customName, 'Anneme');
      expect(shipment.status, 'OUT_FOR_DELIVERY');
      expect(shipment.statusDisplayName, 'Dağıtıma Çıktı');
      expect(shipment.isDelivered, isFalse);
      expect(shipment.hasException, isFalse);
      expect(shipment.estimatedDelivery, isNotNull);
      expect(shipment.currentLocation, 'Ankara');
      expect(shipment.sender, 'Gönderici Firma');

      // Timeline comes from the provider response, in full.
      expect(shipment.events, hasLength(2));
      expect(shipment.events.first.status, 'IN_TRANSIT');
      expect(shipment.events.first.description, 'Transfer merkezine ulaştı');
      expect(shipment.events.first.location, 'Ankara');
      expect(
        shipment.events.first.timestamp.isUtc,
        isTrue,
        reason: 'provider timestamps must be kept, not localised/replaced',
      );
    });

    test('marks a DELIVERED result as delivered', () {
      final shipment = TrackResult.fromJson(payload(status: 'DELIVERED'))
          .toShipment();
      expect(shipment.isDelivered, isTrue);
      expect(shipment.statusDisplayName, 'Teslim Edildi');
    });

    test('drops events without a usable timestamp instead of inventing one',
        () {
      final json = payload();
      json['events'] = [
        {
          'timestamp': 'not-a-timestamp',
          'status': 'IN_TRANSIT',
          'description': 'Geçersiz',
        },
        {'status': 'CREATED', 'description': 'Zaman damgası yok'},
        {
          'timestamp': '2026-10-07T22:47:42.112Z',
          'status': 'CREATED',
          'description': 'Geçerli',
        },
      ];

      final shipment = TrackResult.fromJson(json).toShipment();
      expect(shipment.events, hasLength(1));
      expect(shipment.events.single.description, 'Geçerli');
    });

    test('rejects a payload without tracking status', () {
      final json = payload()..remove('status');
      expect(
        () => TrackResult.fromJson(json),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('error mapping', () {
    test('exposes the backend error code as TrackingException code', () {
      // Shape produced by backend/src/middleware/errorHandler.ts.
      final exception = TrackingApi.errorFromResponse(
        503,
        {
          'error': 'AppError',
          'message':
              'Tracking provider is not configured. Set TRACKING_PROVIDER and the matching API key (see backend/.env.example).',
          'code': 'PROVIDER_NOT_CONFIGURED',
        },
      );

      expect(exception, isA<TrackingException>());
      expect(exception!.code, 'PROVIDER_NOT_CONFIGURED');
      expect(exception.message, contains('TRACKING_PROVIDER'));
    });

    test('2xx is not an error', () {
      expect(TrackingApi.errorFromResponse(200, null), isNull);
    });
  });
}
