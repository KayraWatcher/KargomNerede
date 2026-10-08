import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kargom_nerede/src/shared/models/shipment.dart';
import 'package:kargom_nerede/src/shared/models/carrier.dart';
import 'package:kargom_nerede/src/core/utils/app_utils.dart';
import 'package:kargom_nerede/src/core/extensions/extensions.dart';

/// Local shipment repository.
///
/// Shipments are kept in memory and mirrored to [SharedPreferences] so that
/// the history survives an app restart - a delivered shipment written weeks
/// ago must still be found when the user types the same tracking number
/// again (and it must never be duplicated).
class MockShipmentRepository {
  static const String _storageKey = 'shipments_v1';

  final List<Shipment> _shipments = [];
  late final Future<void> _ready = _initialize();

  Future<void> _initialize() async {
    final stored = await _readPersisted();
    if (stored != null && stored.isNotEmpty) {
      _shipments.addAll(stored);
      return;
    }
    if (stored != null && stored.isEmpty) {
      // The user deleted every shipment before: do not re-seed demo data.
      return;
    }
    _seedMockData();
  }

  Future<List<Shipment>?> _readPersisted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw == null) return null;
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((e) => Shipment.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      // Storage unavailable (tests, corrupted data, ...): stay in-memory.
      return null;
    }
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _storageKey,
        jsonEncode(_shipments.map((s) => s.toJson()).toList()),
      );
    } catch (_) {
      // Persistence is best effort; the in-memory state stays authoritative.
    }
  }

  void _seedMockData() {
    final now = DateTime.now();
    _shipments.addAll([
      Shipment(
        id: 'shipment_1',
        trackingNumber: '1234567890123',
        carrierCode: 'yurtici',
        carrierName: 'Yurtiçi Kargo',
        customName: 'Yeni Kulaklık',
        status: 'OUT_FOR_DELIVERY',
        lastUpdate: now.subtract(const Duration(minutes: 30)),
        estimatedDelivery: now.add(const Duration(hours: 2)),
        events: [
          TrackingEvent(id: 'e1', timestamp: now.subtract(const Duration(days: 1)), status: 'CREATED', description: 'Gönderi oluşturuldu', location: 'İstanbul'),
          TrackingEvent(id: 'e2', timestamp: now.subtract(const Duration(hours: 12)), status: 'IN_TRANSIT', description: 'Yola çıktı', location: 'İstanbul'),
          TrackingEvent(id: 'e3', timestamp: now.subtract(const Duration(hours: 2)), status: 'ARRIVED_AT_FACILITY', description: 'Ankara transfer merkezine ulaştı', location: 'Ankara'),
          TrackingEvent(id: 'e4', timestamp: now.subtract(const Duration(minutes: 30)), status: 'OUT_FOR_DELIVERY', description: 'Dağıtıma çıktı', location: 'Ankara'),
        ],
        sender: 'Trendyol',
        recipient: 'Ahmet Yılmaz',
        origin: 'İstanbul',
        destination: 'Ankara',
        currentLocation: 'Ankara',
        isDelivered: false,
        hasException: false,
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now.subtract(const Duration(minutes: 30)),
      ),
      Shipment(
        id: 'shipment_2',
        trackingNumber: '9876543210',
        carrierCode: 'mng',
        carrierName: 'MNG Kargo',
        customName: 'Annemin Ayakkabısı',
        status: 'DELIVERED',
        lastUpdate: now.subtract(const Duration(hours: 2)),
        estimatedDelivery: now.subtract(const Duration(hours: 2)),
        events: [
          TrackingEvent(id: 'e5', timestamp: now.subtract(const Duration(days: 2)), status: 'CREATED', description: 'Gönderi oluşturuldu', location: 'İzmir'),
          TrackingEvent(id: 'e6', timestamp: now.subtract(const Duration(days: 1)), status: 'IN_TRANSIT', description: 'Yola çıktı', location: 'İzmir'),
          TrackingEvent(id: 'e7', timestamp: now.subtract(const Duration(hours: 12)), status: 'ARRIVED_AT_FACILITY', description: 'İstanbul transfer merkezine ulaştı', location: 'İstanbul'),
          TrackingEvent(id: 'e8', timestamp: now.subtract(const Duration(hours: 2)), status: 'DELIVERED', description: 'Teslim edildi', location: 'İstanbul'),
        ],
        sender: 'Hepsiburada',
        recipient: 'Ayşe Demir',
        origin: 'İzmir',
        destination: 'İstanbul',
        currentLocation: 'İstanbul',
        isDelivered: true,
        hasException: false,
        createdAt: now.subtract(const Duration(days: 2)),
        updatedAt: now.subtract(const Duration(hours: 2)),
      ),
    ]);
  }

  Future<List<Shipment>> getAllShipments() async {
    await _ready;
    await Future.delayed(const Duration(milliseconds: 300));
    return List.from(_shipments)..sort((a, b) => b.lastUpdate.compareTo(a.lastUpdate));
  }

  Future<Shipment?> getShipment(String id) async {
    await _ready;
    await Future.delayed(const Duration(milliseconds: 100));
    try {
      return _shipments.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Finds a shipment by its tracking number, ignoring whitespace and case.
  Future<Shipment?> findByTrackingNumber(String trackingNumber) async {
    await _ready;
    final target = trackingNumber.normalizeTrackingNumber();
    if (target.isEmpty) return null;
    for (final shipment in _shipments) {
      if (shipment.trackingNumber.normalizeTrackingNumber() == target) {
        return shipment;
      }
    }
    return null;
  }

  /// Inserts [shipment] unless a record with the same tracking number already
  /// exists. In that case the existing record is returned untouched, so a
  /// duplicate shipment is never created and the old history is preserved.
  Future<Shipment> insertShipment(Shipment shipment) async {
    await _ready;
    final existing = await findByTrackingNumber(shipment.trackingNumber);
    if (existing != null) return existing;

    await Future.delayed(const Duration(milliseconds: 200));
    _shipments.add(shipment);
    await _persist();
    return shipment;
  }

  Future<void> updateShipment(Shipment shipment) async {
    await _ready;
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _shipments.indexWhere((s) => s.id == shipment.id);
    if (index != -1) {
      _shipments[index] = shipment;
      await _persist();
    }
  }

  Future<void> deleteShipment(String id) async {
    await _ready;
    await Future.delayed(const Duration(milliseconds: 200));
    _shipments.removeWhere((s) => s.id == id);
    await _persist();
  }

  Future<void> addTrackingEvent(String shipmentId, TrackingEvent event) async {
    final shipment = await getShipment(shipmentId);
    if (shipment != null) {
      final updated = shipment.copyWith(
        status: event.status,
        lastUpdate: event.timestamp,
        events: [event, ...shipment.events],
        updatedAt: DateTime.now(),
        isDelivered: event.status == 'DELIVERED',
        hasException: event.status == 'EXCEPTION',
      );
      await updateShipment(updated);
    }
  }
}

final mockShipmentRepositoryProvider = Provider<MockShipmentRepository>((ref) {
  return MockShipmentRepository();
});

final shipmentsProvider = StateNotifierProvider<ShipmentsNotifier, AsyncValue<List<Shipment>>>((ref) {
  return ShipmentsNotifier(ref.read(mockShipmentRepositoryProvider));
});

class ShipmentsNotifier extends StateNotifier<AsyncValue<List<Shipment>>> {
  final MockShipmentRepository _repository;

  ShipmentsNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadShipments();
  }

  Future<void> loadShipments() async {
    state = const AsyncValue.loading();
    try {
      final shipments = await _repository.getAllShipments();
      state = AsyncValue.data(shipments);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> refresh() async {
    await loadShipments();
  }

  /// Adds [shipment]. When the same tracking number already exists the
  /// existing record is returned and no duplicate is created.
  Future<Shipment> addShipment(Shipment shipment) async {
    try {
      final stored = await _repository.insertShipment(shipment);
      await loadShipments();
      return stored;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return shipment;
    }
  }

  Future<void> updateShipment(Shipment shipment) async {
    try {
      await _repository.updateShipment(shipment);
      await loadShipments();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deleteShipment(String id) async {
    try {
      await _repository.deleteShipment(id);
      await loadShipments();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final searchQueryProvider = StateProvider<String>((ref) => '');

final filteredShipmentsProvider = Provider.family<AsyncValue<List<Shipment>>, String>((ref, filter) {
  final shipmentsAsync = ref.watch(shipmentsProvider);
  final searchQuery = ref.watch(searchQueryProvider);

  return shipmentsAsync.when(
    data: (shipments) {
      var filtered = shipments;

      if (filter != 'Tümü') {
        final statuses = AppUtils.filterToStatus(filter).split(',');
        filtered = filtered.where((s) => statuses.contains(s.status)).toList();
      }

      if (searchQuery.isNotEmpty) {
        final query = searchQuery.normalizeForSearch();
        filtered = filtered.where((s) =>
          s.trackingNumber.normalizeForSearch().contains(query) ||
          s.displayName.normalizeForSearch().contains(query) ||
          s.carrierName.normalizeForSearch().contains(query) ||
          (s.customName?.normalizeForSearch().contains(query) ?? false)
        ).toList();
      }

      filtered.sort((a, b) => b.lastUpdate.compareTo(a.lastUpdate));

      return AsyncValue.data(filtered);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

final shipmentDetailProvider = FutureProvider.family<Shipment, String>((ref, id) async {
  final repository = ref.watch(mockShipmentRepositoryProvider);
  final value = await repository.getShipment(id);
  if (value == null) throw Exception('Shipment not found');
  return value;
});

/// Carriers the user can pick from. Backed by [CarrierRegistry] so the list,
/// the display names and the detection codes stay in sync.
final activeCarriersProvider = FutureProvider<List<Carrier>>((ref) async {
  await Future.delayed(const Duration(milliseconds: 100));
  return CarrierRegistry.activeCarriers;
});