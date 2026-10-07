import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/app_utils.dart';
import '../../core/extensions/extensions.dart';

class Shipment {
  final String id;
  final String trackingNumber;
  final String carrierCode;
  final String carrierName;
  final String? customName;
  final String status;
  final DateTime lastUpdate;
  final DateTime? estimatedDelivery;
  final String? sender;
  final String? recipient;
  final String? currentLocation;
  final String? origin;
  final String? destination;
  final List<TrackingEvent> events;
  final bool isDelivered;
  final bool hasException;
  final String? exceptionDescription;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic>? rawData;

  const Shipment({
    required this.id,
    required this.trackingNumber,
    required this.carrierCode,
    required this.carrierName,
    this.customName,
    required this.status,
    required this.lastUpdate,
    this.estimatedDelivery,
    this.sender,
    this.recipient,
    this.currentLocation,
    this.origin,
    this.destination,
    this.events = const [],
    this.isDelivered = false,
    this.hasException = false,
    this.exceptionDescription,
    this.createdAt,
    this.updatedAt,
    this.rawData,
  });

  factory Shipment.fromJson(Map<String, dynamic> json) {
    return Shipment(
      id: json['id'] as String,
      trackingNumber: json['trackingNumber'] as String,
      carrierCode: json['carrierCode'] as String,
      carrierName: json['carrierName'] as String,
      customName: json['customName'] as String?,
      status: json['status'] as String,
      lastUpdate: DateTime.parse(json['lastUpdate'] as String),
      estimatedDelivery: json['estimatedDelivery'] != null
          ? DateTime.parse(json['estimatedDelivery'] as String)
          : null,
      sender: json['sender'] as String?,
      recipient: json['recipient'] as String?,
      currentLocation: json['currentLocation'] as String?,
      origin: json['origin'] as String?,
      destination: json['destination'] as String?,
      events: (json['events'] as List<dynamic>?)
          ?.map((e) => TrackingEvent.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      isDelivered: json['isDelivered'] as bool? ?? false,
      hasException: json['hasException'] as bool? ?? false,
      exceptionDescription: json['exceptionDescription'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      rawData: json['rawData'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trackingNumber': trackingNumber,
      'carrierCode': carrierCode,
      'carrierName': carrierName,
      'customName': customName,
      'status': status,
      'lastUpdate': lastUpdate.toIso8601String(),
      'estimatedDelivery': estimatedDelivery?.toIso8601String(),
      'sender': sender,
      'recipient': recipient,
      'currentLocation': currentLocation,
      'origin': origin,
      'destination': destination,
      'events': events.map((e) => e.toJson()).toList(),
      'isDelivered': isDelivered,
      'hasException': hasException,
      'exceptionDescription': exceptionDescription,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'rawData': rawData,
    };
  }

  String get displayName => customName ?? 'Kargo #${trackingNumber.maskTrackingNumber}';
  
  String get statusDisplayName {
    return AppConstants.statusDisplayNames[status] ?? status;
  }

  Color get statusColor {
    final colorValue = AppConstants.statusColors[status];
    return colorValue != null ? Color(colorValue) : Colors.grey;
  }

  int get statusOrder => AppUtils.getStatusOrder(status);

  bool get isActive => !isDelivered && !hasException && 
      status != 'CANCELLED' && status != 'RETURNED' && status != 'LOST';

  Duration? get timeSinceLastUpdate => DateTime.now().difference(lastUpdate);

  String get formattedLastUpdate => lastUpdate.formatRelative();

  String? get formattedEstimatedDelivery => estimatedDelivery?.formatTurkish(withTime: true);

  bool get isOverdue {
    if (estimatedDelivery == null || isDelivered) return false;
    return DateTime.now().isAfter(estimatedDelivery!);
  }

  List<TrackingEvent> get sortedEvents {
    final events = [...this.events];
    events.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return events;
  }

  TrackingEvent? get latestEvent => sortedEvents.firstOrNull;

  Shipment copyWith({
    String? id,
    String? trackingNumber,
    String? carrierCode,
    String? carrierName,
    String? customName,
    String? status,
    DateTime? lastUpdate,
    DateTime? estimatedDelivery,
    String? sender,
    String? recipient,
    String? currentLocation,
    String? origin,
    String? destination,
    List<TrackingEvent>? events,
    bool? isDelivered,
    bool? hasException,
    String? exceptionDescription,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? rawData,
  }) {
    return Shipment(
      id: id ?? this.id,
      trackingNumber: trackingNumber ?? this.trackingNumber,
      carrierCode: carrierCode ?? this.carrierCode,
      carrierName: carrierName ?? this.carrierName,
      customName: customName ?? this.customName,
      status: status ?? this.status,
      lastUpdate: lastUpdate ?? this.lastUpdate,
      estimatedDelivery: estimatedDelivery ?? this.estimatedDelivery,
      sender: sender ?? this.sender,
      recipient: recipient ?? this.recipient,
      currentLocation: currentLocation ?? this.currentLocation,
      origin: origin ?? this.origin,
      destination: destination ?? this.destination,
      events: events ?? this.events,
      isDelivered: isDelivered ?? this.isDelivered,
      hasException: hasException ?? this.hasException,
      exceptionDescription: exceptionDescription ?? this.exceptionDescription,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rawData: rawData ?? this.rawData,
    );
  }

  Shipment copyWithStatus(String newStatus, {DateTime? updateTime, String? description, String? location}) {
    final newEvent = TrackingEvent(
      id: AppUtils.generateId(),
      timestamp: updateTime ?? DateTime.now(),
      status: newStatus,
      description: description ?? AppConstants.statusDisplayNames[newStatus] ?? newStatus,
      location: location,
    );
    return copyWith(
      status: newStatus,
      lastUpdate: updateTime ?? DateTime.now(),
      events: [newEvent, ...events],
      isDelivered: newStatus == 'DELIVERED',
      hasException: newStatus == 'EXCEPTION',
      updatedAt: DateTime.now(),
    );
  }
}

class TrackingEvent {
  final String id;
  final DateTime timestamp;
  final String status;
  final String description;
  final String? location;
  final String? facilityName;
  final double? latitude;
  final double? longitude;
  final Map<String, dynamic>? rawData;

  const TrackingEvent({
    required this.id,
    required this.timestamp,
    required this.status,
    required this.description,
    this.location,
    this.facilityName,
    this.latitude,
    this.longitude,
    this.rawData,
  });

  factory TrackingEvent.fromJson(Map<String, dynamic> json) {
    return TrackingEvent(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      status: json['status'] as String,
      description: json['description'] as String,
      location: json['location'] as String?,
      facilityName: json['facilityName'] as String?,
      latitude: json['latitude'] as double?,
      longitude: json['longitude'] as double?,
      rawData: json['rawData'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'status': status,
      'description': description,
      'location': location,
      'facilityName': facilityName,
      'latitude': latitude,
      'longitude': longitude,
      'rawData': rawData,
    };
  }

  String get formattedTime => timestamp.formatTurkish(withTime: true);
  
  String get formattedRelativeTime => timestamp.formatRelative();
  
  bool get hasLocation => latitude != null && longitude != null;
}