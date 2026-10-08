import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:kargom_nerede/src/core/constants/app_constants.dart';
import 'package:kargom_nerede/src/core/extensions/extensions.dart';
import 'package:kargom_nerede/src/shared/widgets/common_widgets.dart';
import 'package:kargom_nerede/src/features/notifications/data/notification_service.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bildirimler'),
        actions: [
          if (notifications.isNotEmpty)
            TextButton(
              onPressed: () => _clearAllNotifications(context, ref),
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
                  onDismiss: () => _dismissNotification(context, ref, notification.id),
                ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: 0.2);
              },
            ),
    );
  }

  void _dismissNotification(BuildContext context, WidgetRef ref, String id) {
    ref.read(notificationProvider.notifier).dismiss(id);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bildirim silindi')),
    );
  }

  void _clearAllNotifications(BuildContext context, WidgetRef ref) {
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
              ref.read(notificationProvider.notifier).clearAll();
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
  final NotificationItem notification;
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

  Color _getTypeColor(String type) {
    switch (type) {
      case 'newMovement':
        return const Color(0xFF2196F3);
      case 'arrivedAtFacility':
        return const Color(0xFF9C27B0);
      case 'outForDelivery':
        return const Color(0xFFFF9800);
      case 'delivered':
        return const Color(0xFF4CAF50);
      case 'exception':
        return const Color(0xFFF44336);
      case 'delay':
        return const Color(0xFFF44336);
      case 'returned':
        return const Color(0xFF795548);
      default:
        return const Color(0xFF2196F3);
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'newMovement':
        return Icons.local_shipping;
      case 'arrivedAtFacility':
        return Icons.factory;
      case 'outForDelivery':
        return Icons.delivery_dining;
      case 'delivered':
        return Icons.check_circle;
      case 'exception':
        return Icons.warning;
      case 'delay':
        return Icons.schedule;
      case 'returned':
        return Icons.undo;
      default:
        return Icons.notifications;
    }
  }
}