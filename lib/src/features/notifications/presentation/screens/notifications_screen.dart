import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:kargom_nerede/src/core/constants/app_constants.dart';
import 'package:kargom_nerede/src/core/extensions/extensions.dart';
import 'package:kargom_nerede/src/shared/widgets/common_widgets.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: Implement notifications from local storage / FCM
    final notifications = _getMockNotifications();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bildirimler'),
        actions: [
          if (notifications.isNotEmpty)
            TextButton(
              onPressed: () => _clearAllNotifications(context),
              child: const Text('Tümünü Temizle'),
            ),
        ],
      ),
      body: notifications.isEmpty
          ? EmptyState(
              icon: Icons.notifications_none_outlined,
              title: 'Henüz Bildirim Yok',
              description: 'Kargo durumları değiştiğinde buraya bildirim gelecek.',
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return _NotificationCard(
                  notification: notification,
                  onDismiss: () => _dismissNotification(context, index),
                ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: 0.2);
              },
            ),
    );
  }

  List<_Notification> _getMockNotifications() {
    return [
      _Notification(
        id: '1',
        title: 'Kargonuz Dağıtıma Çıktı',
        body: 'Yurtiçi Kargo - 1234567890123 bugün teslim edilecek.',
        timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
        type: NotificationType.outForDelivery,
        shipmentId: 'shipment_1',
        read: false,
      ),
      _Notification(
        id: '2',
        title: 'Teslim Edildi',
        body: 'MNG Kargo - 9876543210 başarıyla teslim edildi.',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        type: NotificationType.delivered,
        shipmentId: 'shipment_2',
        read: true,
      ),
      _Notification(
        id: '3',
        title: 'Transfer Merkezinde',
        body: 'Aras Kargo - 5556667777888 Ankara transfer merkezine ulaştı.',
        timestamp: DateTime.now().subtract(const Duration(hours: 5)),
        type: NotificationType.newMovement,
        shipmentId: 'shipment_3',
        read: true,
      ),
      _Notification(
        id: '4',
        title: 'Gecikme Bildirimi',
        body: 'PTT - RR123456789TR tahmini teslim tarihi geçti.',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        type: NotificationType.delay,
        shipmentId: 'shipment_4',
        read: false,
      ),
    ];
  }

  void _dismissNotification(BuildContext context, int index) {
    // TODO: Remove from local storage
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bildirim silindi')),
    );
  }

  void _clearAllNotifications(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tüm Bildirimleri Temizle'),
        content: const Text('Tüm bildirimler silinecek. Emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement actual clearing from local storage
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tüm bildirimler temizlendi')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Temizle'),
          ),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final _Notification notification;
  final VoidCallback onDismiss;

  const _NotificationCard({
    required this.notification,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red[400],
          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => onDismiss(),
      child: AppCard(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getTypeColor(notification.type).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getTypeIcon(notification.type),
                color: _getTypeColor(notification.type),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: context.textTheme.titleSmall?.copyWith(
                            fontWeight: notification.read ? FontWeight.w500 : FontWeight.w700,
                          ),
                        ),
                      ),
                      if (!notification.read)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: context.colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.body,
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    notification.timestamp.formatRelative(),
                    style: context.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getTypeColor(NotificationType type) {
    switch (type) {
      case NotificationType.newMovement:
        return const Color(0xFF2196F3);
      case NotificationType.arrivedAtFacility:
        return const Color(0xFF9C27B0);
      case NotificationType.outForDelivery:
        return const Color(0xFFFF9800);
      case NotificationType.delivered:
        return const Color(0xFF4CAF50);
      case NotificationType.exception:
        return const Color(0xFFF44336);
      case NotificationType.delay:
        return const Color(0xFFF44336);
      case NotificationType.returned:
        return const Color(0xFF795548);
    }
  }

  IconData _getTypeIcon(NotificationType type) {
    switch (type) {
      case NotificationType.newMovement:
        return Icons.local_shipping;
      case NotificationType.arrivedAtFacility:
        return Icons.factory;
      case NotificationType.outForDelivery:
        return Icons.delivery_dining;
      case NotificationType.delivered:
        return Icons.check_circle;
      case NotificationType.exception:
        return Icons.warning;
      case NotificationType.delay:
        return Icons.schedule;
      case NotificationType.returned:
        return Icons.undo;
    }
  }
}

class _Notification {
  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  final NotificationType type;
  final String shipmentId;
  final bool read;

  _Notification({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    required this.type,
    required this.shipmentId,
    required this.read,
  });
}

enum NotificationType {
  newMovement,
  arrivedAtFacility,
  outForDelivery,
  delivered,
  exception,
  delay,
  returned,
}