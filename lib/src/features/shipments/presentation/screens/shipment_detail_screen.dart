import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:kargom_nerede/src/core/constants/app_constants.dart';
import 'package:kargom_nerede/src/core/errors/app_exceptions.dart';
import 'package:kargom_nerede/src/core/utils/app_utils.dart';
import 'package:kargom_nerede/src/core/extensions/extensions.dart';
import 'package:kargom_nerede/src/shared/models/shipment.dart';
import 'package:kargom_nerede/src/shared/widgets/common_widgets.dart';
import 'package:kargom_nerede/src/features/shipments/data/tracking_api.dart';
import 'package:kargom_nerede/src/features/shipments/presentation/providers/shipment_providers.dart';

final _isEditingNameProvider = StateProvider<bool>((ref) => false);
final _nameControllerProvider = StateProvider<TextEditingController>((ref) => TextEditingController());

class ShipmentDetailScreen extends ConsumerWidget {
  final String shipmentId;

  const ShipmentDetailScreen({super.key, required this.shipmentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shipmentAsync = ref.watch(shipmentDetailProvider(shipmentId));
    final isEditingName = ref.watch(_isEditingNameProvider);
    final nameController = ref.watch(_nameControllerProvider);

    return shipmentAsync.when(
      data: (shipment) => _buildDetailView(context, ref, shipment, isEditingName, nameController),
      loading: () => _buildLoadingView(),
      error: (error, _) => _buildErrorView(context, ref, error),
    );
  }

  Widget _buildDetailView(BuildContext context, WidgetRef ref, Shipment shipment, bool isEditingName, TextEditingController nameController) {
    nameController.text = shipment.customName ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(shipment.displayName),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) => _handleMenuAction(context, ref, value, shipment),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit_name',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 20),
                    SizedBox(width: 8),
                    Text('İsmi Düzenle'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'copy_tracking',
                child: Row(
                  children: [
                    Icon(Icons.copy, size: 20),
                    SizedBox(width: 8),
                    Text('Takip No Kopyala'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'share',
                child: Row(
                  children: [
                    Icon(Icons.share, size: 20),
                    SizedBox(width: 8),
                    Text('Paylaş'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 20, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Sil', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _refreshFromProvider(context, ref, shipment),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  _buildHeaderCard(context, ref, shipment, isEditingName, nameController),
                  _buildInfoCards(context, shipment),
                  _buildTimeline(context, shipment),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Pull-to-refresh: re-queries the tracking provider through the backend
  /// (`POST /tracking/track`) and caches the fresh status/timeline in the
  /// local repository. The local record is only a cache/history - when the
  /// backend or provider is unreachable the error is shown and the cached
  /// record stays untouched.
  Future<void> _refreshFromProvider(
    BuildContext context,
    WidgetRef ref,
    Shipment shipment,
  ) async {
    try {
      final tracked = await ref.read(trackingApiProvider).track(
            trackingNumber: shipment.trackingNumber,
            carrierCode: shipment.carrierCode,
          );
      await ref.read(shipmentsProvider.notifier).updateShipment(
            tracked.toShipment(
              id: shipment.id,
              customName: shipment.customName,
              createdAt: shipment.createdAt,
            ),
          );
      // The detail screen reads its own provider, so make it pick up the
      // freshly cached record.
      ref.invalidate(shipmentDetailProvider(shipmentId));
    } catch (error) {
      if (context.mounted) {
        final detail = error is AppException ? error.message : '$error';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Güncelleme alınamadı: $detail')),
        );
      }
    } finally {
      await ref.read(shipmentsProvider.notifier).refresh();
    }
  }

  Widget _buildLoadingView() {
    return Scaffold(
      appBar: AppBar(title: const Text('Yükleniyor...')),
      body: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildErrorView(BuildContext context, WidgetRef ref, Object error) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hata')),
      body: EmptyState(
        icon: Icons.error_outline,
        title: 'Kargo Yüklenemedi',
        description: error.toString(),
        action: ElevatedButton(
          onPressed: () => ref.invalidate(shipmentDetailProvider(shipmentId)),
          child: const Text('Tekrar Dene'),
        ),
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context, WidgetRef ref, Shipment shipment, bool isEditingName, TextEditingController nameController) {
    return _ShipmentHeaderCard(
      shipment: shipment,
      isEditingName: isEditingName,
      nameController: nameController,
      onEditPressed: () => ref.read(_isEditingNameProvider.notifier).state = true,
      onSavePressed: () => _saveName(context, ref, shipment, nameController),
      onCopyTracking: () => _copyToClipboard(context, shipment.trackingNumber),
    );
  }

  Widget _buildInfoCards(BuildContext context, Shipment shipment) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (shipment.sender != null || shipment.recipient != null)
            _buildInfoCard(
              context,
              'Gönderici / Alıcı',
              [
                if (shipment.sender != null)
                  _InfoRow('Gönderici', shipment.sender!, Icons.person_outline),
                if (shipment.recipient != null)
                  _InfoRow('Alıcı', shipment.recipient!, Icons.person_outline),
              ],
            ),
          if (shipment.origin != null || shipment.destination != null)
            _buildInfoCard(
              context,
              'Rota',
              [
                if (shipment.origin != null)
                  _InfoRow('Çıkış', shipment.origin!, Icons.location_on_outlined),
                if (shipment.destination != null)
                  _InfoRow('Varış', shipment.destination!, Icons.flag_outlined),
              ],
            ),
          if (shipment.currentLocation != null)
            _buildInfoCard(
              context,
              'Mevcut Konum',
              [
                _InfoRow('Konum', shipment.currentLocation!, Icons.my_location),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, String title, List<_InfoRow> rows) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: context.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ...rows.map((row) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(row.icon, size: 20, color: Colors.grey[600]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            row.label,
                            style: context.textTheme.bodySmall?.copyWith(
                              color: Colors.grey[500],
                            ),
                          ),
                          Text(
                            row.value,
                            style: context.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildTimeline(BuildContext context, Shipment shipment) {
    final events = shipment.sortedEvents;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hareket Geçmişi',
            style: context.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          if (events.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(Icons.timeline, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'Henüz hareket kaydı yok',
                      style: context.textTheme.titleMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Kargo firmasından veri alındığında buraya gelecek.',
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[500],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            ...events.asMap().entries.map((entry) {
              final index = entry.key;
              final event = entry.value;
              final isLast = index == events.length - 1;
              final isFirst = index == 0;
              return _TimelineEvent(
                event: event,
                isFirst: isFirst,
                isLast: isLast,
                color: shipment.statusColor,
              ).animate().fadeIn(delay: (index * 100).ms).slideX(begin: 0.2);
            }),
        ],
      ),
    );
  }

  void _handleMenuAction(BuildContext context, WidgetRef ref, String action, Shipment shipment) {
    switch (action) {
      case 'edit_name':
        ref.read(_isEditingNameProvider.notifier).state = true;
        break;
      case 'copy_tracking':
        _copyToClipboard(context, shipment.trackingNumber);
        break;
      case 'share':
        _shareShipment(context, shipment);
        break;
      case 'delete':
        _confirmDelete(context, ref, shipment);
        break;
    }
  }

  Future<void> _saveName(BuildContext context, WidgetRef ref, Shipment shipment, TextEditingController nameController) async {
    final newName = nameController.text.trim();
    final updatedShipment = shipment.copyWith(
      customName: newName.isEmpty ? null : newName,
      updatedAt: DateTime.now(),
    );
    await ref.read(shipmentsProvider.notifier).updateShipment(updatedShipment);
    ref.read(_isEditingNameProvider.notifier).state = false;
  }

  void _copyToClipboard(BuildContext context, String text) {
    AppUtils.copyToClipboard(text);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Takip numarası kopyalandı')),
    );
  }

  void _shareShipment(BuildContext context, Shipment shipment) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Paylaşım özelliği yakında')),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Shipment shipment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kargoyu Sil'),
        content: Text('"${shipment.displayName}" kargosunu silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteShipment(context, ref, shipment);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteShipment(BuildContext context, WidgetRef ref, Shipment shipment) async {
    // Show loading indicator
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('Siliniyor...'),
          ],
        ),
        duration: const Duration(seconds: 10),
      ),
    );
    
    try {
      await ref.read(shipmentsProvider.notifier).deleteShipment(shipment.id);
      
      if (!context.mounted) return;
      
      // Hide loading snackbar
      scaffoldMessenger.hideCurrentSnackBar();
      
      // Navigate back to shipments list
      context.go('/');
      
      // Show success message
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('${shipment.displayName} silindi'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      
      scaffoldMessenger.hideCurrentSnackBar();
      
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Silme hatası: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toUpperCase()) {
      case 'CREATED':
        return Icons.inventory;
      case 'IN_TRANSIT':
        return Icons.local_shipping;
      case 'ARRIVED_AT_FACILITY':
        return Icons.factory;
      case 'OUT_FOR_DELIVERY':
        return Icons.delivery_dining;
      case 'DELIVERED':
        return Icons.check_circle;
      case 'EXCEPTION':
        return Icons.warning;
      case 'RETURNED':
        return Icons.undo;
      case 'LOST':
        return Icons.help;
      case 'CANCELLED':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }
}

class _ShipmentHeaderCard extends ConsumerWidget {
  final Shipment shipment;
  final bool isEditingName;
  final TextEditingController nameController;
  final VoidCallback onEditPressed;
  final VoidCallback onSavePressed;
  final VoidCallback onCopyTracking;

  const _ShipmentHeaderCard({
    required this.shipment,
    required this.isEditingName,
    required this.nameController,
    required this.onEditPressed,
    required this.onSavePressed,
    required this.onCopyTracking,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final infoRow = Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildInfoItemStatic(
          'Takip No',
          shipment.trackingNumber.maskTrackingNumber,
          Icons.qr_code,
          onTap: () => onCopyTracking(),
        ),
        _buildInfoItemStatic(
          'Son Güncelleme',
          shipment.formattedLastUpdate,
          Icons.access_time,
        ),
        if (shipment.estimatedDelivery != null)
          _buildInfoItemStatic(
            'Tahmini Teslim',
            shipment.estimatedDelivery!.formatTurkish(withTime: true),
            Icons.event,
            color: shipment.isOverdue ? Colors.red : null,
          ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              shipment.statusColor.withValues(alpha: 0.1),
              shipment.statusColor.withValues(alpha: 0.05),
            ],
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                CarrierAvatar(
                  carrierCode: shipment.carrierCode,
                  carrierName: shipment.carrierName,
                  radius: 32,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      isEditingName
                          ? TextField(
                              controller: nameController,
                              autofocus: true,
                              decoration: const InputDecoration(
                                isDense: true,
                                border: InputBorder.none,
                              ),
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                              onSubmitted: (_) => onSavePressed(),
                            )
                          : Text(
                              shipment.displayName,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                      const SizedBox(height: 4),
                      Text(
                        shipment.carrierName,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isEditingName)
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => ref.read(_isEditingNameProvider.notifier).state = true,
                    tooltip: 'İsmi Düzenle',
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.check),
                    onPressed: () => ref.read(_isEditingNameProvider.notifier).state = false,
                    tooltip: 'Kaydet',
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: shipment.statusColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _getStatusIconStatic(shipment.status),
                    color: shipment.statusColor,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    shipment.statusDisplayName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: shipment.statusColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            infoRow,
          ],
        ),
      ),
    );
  }

  static Widget _buildInfoItemStatic(String label, String value, IconData icon, {Color? color, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Column(
          children: [
            Icon(icon, size: 20, color: color ?? Colors.grey[600]),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static IconData _getStatusIconStatic(String status) {
    switch (status.toUpperCase()) {
      case 'CREATED':
        return Icons.inventory;
      case 'IN_TRANSIT':
        return Icons.local_shipping;
      case 'ARRIVED_AT_FACILITY':
        return Icons.factory;
      case 'OUT_FOR_DELIVERY':
        return Icons.delivery_dining;
      case 'DELIVERED':
        return Icons.check_circle;
      case 'EXCEPTION':
        return Icons.warning;
      case 'RETURNED':
        return Icons.undo;
      case 'LOST':
        return Icons.help;
      case 'CANCELLED':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }
}

class _InfoRow {
  final String label;
  final String value;
  final IconData icon;

  _InfoRow(this.label, this.value, this.icon);
}

class _TimelineEvent extends StatelessWidget {
  final TrackingEvent event;
  final bool isFirst;
  final bool isLast;
  final Color color;

  const _TimelineEvent({
    required this.event,
    required this.isFirst,
    required this.isLast,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              if (!isFirst)
                Expanded(
                  child: Container(
                    width: 2,
                    color: Colors.grey[300],
                  ),
                ),
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: Colors.grey[300],
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          event.description,
                          style: context.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Text(
                        event.formattedTime,
                        style: context.textTheme.bodySmall?.copyWith(
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                  if (event.location != null || event.facilityName != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 14,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            event.facilityName ?? event.location ?? '',
                            style: context.textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}