import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kargom_nerede/src/core/constants/app_constants.dart';

class NotificationItem {
  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  final String type;
  final String shipmentId;
  final bool read;

  NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    required this.type,
    required this.shipmentId,
    this.read = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'body': body,
    'timestamp': timestamp.toIso8601String(),
    'type': type,
    'shipmentId': shipmentId,
    'read': read,
  };

  factory NotificationItem.fromJson(Map<String, dynamic> json) => NotificationItem(
    id: json['id'],
    title: json['title'],
    body: json['body'],
    timestamp: DateTime.parse(json['timestamp']),
    type: json['type'],
    shipmentId: json['shipmentId'],
    read: json['read'] ?? false,
  );
}

class NotificationNotifier extends StateNotifier<List<NotificationItem>> {
  NotificationNotifier() : super([]) {
    _load();
  }

  static const _key = 'notifications_persist';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      try {
        final list = (jsonDecode(raw) as List)
            .map((e) => NotificationItem.fromJson(e as Map<String, dynamic>))
            .toList();
        state = list;
      } catch (_) {
        state = [];
      }
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(state.map((e) => e.toJson()).toList());
    await prefs.setString(_key, raw);
  }

  Future<void> add(NotificationItem item) async {
    state = [item, ...state];
    await _save();
  }

  Future<void> dismiss(String id) async {
    state = state.where((e) => e.id != id).toList();
    await _save();
  }

  Future<void> clearAll() async {
    state = [];
    await _save();
  }

  Future<void> markRead(String id) async {
    state = [
      for (final item in state)
        if (item.id == id) item.copyWith(read: true) else item
    ];
    await _save();
  }
}

extension on NotificationItem {
  NotificationItem copyWith({bool? read}) => NotificationItem(
    id: id,
    title: title,
    body: body,
    timestamp: timestamp,
    type: type,
    shipmentId: shipmentId,
    read: read ?? this.read,
  );
}

final notificationProvider = StateNotifierProvider<NotificationNotifier, List<NotificationItem>>((ref) {
  return NotificationNotifier();
});
