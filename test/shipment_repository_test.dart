import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kargom_nerede/src/core/extensions/extensions.dart';
import 'package:kargom_nerede/src/features/shipments/presentation/providers/shipment_providers.dart';
import 'package:kargom_nerede/src/shared/models/shipment.dart';

Shipment _shipment({
  required String id,
  required String trackingNumber,
  String status = 'IN_TRANSIT',
  String carrierCode = 'hepsijet',
  String carrierName = 'HepsiJet',
}) {
  return Shipment(
    id: id,
    trackingNumber: trackingNumber,
    carrierCode: carrierCode,
    carrierName: carrierName,
    status: status,
    lastUpdate: DateTime.now(),
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    isDelivered: status == 'DELIVERED',
    events: [
      TrackingEvent(
        id: '$id-event',
        timestamp: DateTime.now(),
        status: status,
        description: 'test',
      ),
    ],
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('MockShipmentRepository', () {
    test('seeds the demo shipments on a fresh install', () async {
      final repository = MockShipmentRepository();
      final shipments = await repository.getAllShipments();
      expect(shipments.length, greaterThanOrEqualTo(2));
    });

    test('finds a shipment with a normalized tracking number', () async {
      final repository = MockShipmentRepository();
      await repository.insertShipment(
        _shipment(id: 'custom-1', trackingNumber: '7777777777777'),
      );

      final found = await repository.findByTrackingNumber('7777777777777');
      expect(found, isNotNull);
      expect(found!.id, 'custom-1');

      final spaced = await repository.findByTrackingNumber('  7777 777777777 ');
      expect(spaced, isNotNull);
      expect(spaced!.id, 'custom-1');

      final lowercase = await repository.findByTrackingNumber('hj123456789012');
      expect(lowercase, isNull);
    });

    test('never creates a duplicate for the same tracking number', () async {
      final repository = MockShipmentRepository();

      final first = await repository.insertShipment(
        _shipment(id: 'first', trackingNumber: 'HJ123456789012'),
      );
      final second = await repository.insertShipment(
        _shipment(id: 'second', trackingNumber: ' hj1234 56789012 '),
      );

      expect(first.id, 'first');
      expect(second.id, 'first', reason: 'the existing record must win');

      final all = await repository.getAllShipments();
      final duplicates = all
          .where((s) =>
              s.trackingNumber.normalizeTrackingNumber() ==
              'HJ123456789012')
          .toList();
      expect(duplicates, hasLength(1));
    });

    test('keeps a delivered shipment in history across restarts', () async {
      final repository = MockShipmentRepository();
      await repository.insertShipment(
        _shipment(
          id: 'delivered-1',
          trackingNumber: '5555555555',
          status: 'DELIVERED',
        ),
      );

      // Simulates an app restart: a brand new repository over the same store.
      final restarted = MockShipmentRepository();
      final found = await restarted.findByTrackingNumber('5555555555');

      expect(found, isNotNull, reason: 'delivered history must survive');
      expect(found!.id, 'delivered-1');
      expect(found.status, 'DELIVERED');
      expect(found.isDelivered, isTrue);
      expect(found.statusDisplayName, 'Teslim Edildi');
    });

    test('an already delivered shipment is still found before adding again',
        () async {
      final repository = MockShipmentRepository();
      await repository.insertShipment(
        _shipment(
          id: 'active-1',
          trackingNumber: '8888888888',
          status: 'IN_TRANSIT',
        ),
      );

      final existing = await repository.findByTrackingNumber('8888888888');
      expect(existing, isNotNull);

      final stored = await repository.insertShipment(
        _shipment(id: 'active-1-copy', trackingNumber: '8888888888'),
      );
      expect(stored.id, 'active-1');
    });
  });
}
