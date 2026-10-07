import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:kargom_nerede/src/core/constants/app_constants.dart';
import 'package:kargom_nerede/src/core/utils/app_utils.dart';
import 'package:kargom_nerede/src/core/extensions/extensions.dart';
import 'package:kargom_nerede/src/shared/models/shipment.dart';
import 'package:kargom_nerede/src/shared/widgets/common_widgets.dart' show AppCard, CarrierAvatar, StatusChip, EmptyState, FilterChips, SectionHeader, _ShipmentCardSkeleton;
import 'package:kargom_nerede/src/features/shipments/presentation/providers/shipment_providers.dart';

final _selectedFilterProvider = StateProvider<String>((ref) => 'Tümü');
final _searchControllerProvider = StateProvider<TextEditingController>((ref) => TextEditingController());
final _searchDebouncerProvider = Provider<Debouncer>((ref) => Debouncer(delay: const Duration(milliseconds: 300)));
final _selectionModeProvider = StateProvider<bool>((ref) => false);
final _selectedShipmentsProvider = StateProvider<Set<String>>((ref) => {});

class ShipmentsScreen extends ConsumerWidget {
  const ShipmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedFilter = ref.watch(_selectedFilterProvider);
    final searchController = ref.watch(_searchControllerProvider);
    final searchDebouncer = ref.watch(_searchDebouncerProvider);
    final shipmentsAsync = ref.watch(filteredShipmentsProvider(selectedFilter));
    final filterOptions = AppUtils.getFilterOptions();
    final selectionMode = ref.watch(_selectionModeProvider);
    final selectedShipments = ref.watch(_selectedShipmentsProvider);

    return Scaffold(
      appBar: AppBar(
        title: selectionMode
            ? Text('${selectedShipments.length} seçildi')
            : const Text('Kargolarım'),
        leading: selectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  ref.read(_selectionModeProvider.notifier).state = false;
                  ref.read(_selectedShipmentsProvider.notifier).state = {};
                },
              )
            : null,
        actions: [
          if (!selectionMode) ...[
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => context.push('/add'),
              tooltip: 'Kargo Ekle',
            ),
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: () => _showFilterBottomSheet(context, ref),
              tooltip: 'Filtrele',
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.select_all),
              onPressed: () => _selectAllShipments(ref, shipmentsAsync),
              tooltip: 'Tümünü Seç',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: selectedShipments.isEmpty
                  ? null
                  : () => _confirmBulkDelete(context, ref, selectedShipments),
              tooltip: 'Sil',
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(context, ref, searchController, searchDebouncer),
          _buildFilterChips(context, ref, filterOptions),
          Expanded(
            child: shipmentsAsync.when(
              data: (shipments) => _buildShipmentsList(context, ref, shipments),
              loading: () => _buildLoadingList(),
              error: (error, stack) => _buildErrorState(context, ref, error),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/add'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, WidgetRef ref, TextEditingController controller, Debouncer debouncer) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: _CustomSearchField(
        controller: controller,
        hintText: 'Takip no, isim veya firma ara...',
        onChanged: (query) {
          debouncer.run(() {
            ref.read(searchQueryProvider.notifier).state = query;
          });
        },
        onClear: () {
          ref.read(searchQueryProvider.notifier).state = '';
          controller.clear();
        },
      ),
    );
  }

  Widget _buildFilterChips(BuildContext context, WidgetRef ref, List<String> filters) {
    final selectedFilter = ref.watch(_selectedFilterProvider);
    return SizedBox(
      height: 50,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = filter == selectedFilter;
          return FilterChip(
            label: Text(filter),
            selected: isSelected,
            onSelected: (_) => ref.read(_selectedFilterProvider.notifier).state = filter,
            selectedColor: context.colorScheme.primary.withValues(alpha: 0.1),
            checkmarkColor: context.colorScheme.primary,
            labelStyle: context.textTheme.labelMedium?.copyWith(
              color: isSelected ? context.colorScheme.primary : Colors.grey[700],
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: isSelected ? context.colorScheme.primary : Colors.grey[300]!,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildShipmentsList(BuildContext context, WidgetRef ref, List<Shipment> shipments) {
    final selectionMode = ref.watch(_selectionModeProvider);
    final selectedShipments = ref.watch(_selectedShipmentsProvider);
    
    if (shipments.isEmpty) {
      return EmptyState(
        icon: Icons.inventory_2_outlined,
        title: _getEmptyTitle(ref),
        description: _getEmptyDescription(ref),
        action: ref.watch(_selectedFilterProvider) != 'Tümü' || ref.watch(_searchControllerProvider).text.isNotEmpty
            ? TextButton(
                onPressed: () {
                  ref.read(_selectedFilterProvider.notifier).state = 'Tümü';
                  ref.read(_searchControllerProvider).clear();
                  ref.read(searchQueryProvider.notifier).state = '';
                },
                child: const Text('Filtreleri Temizle'),
              )
            : ElevatedButton.icon(
                onPressed: () => ref.read(shipmentsProvider.notifier).refresh(),
                icon: const Icon(Icons.add),
                label: const Text('İlk Kargonuzu Ekleyin'),
              ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(shipmentsProvider.notifier).refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: shipments.length,
        itemBuilder: (context, index) {
          final shipment = shipments[index];
          final isSelected = selectedShipments.contains(shipment.id);
          return _ShipmentCard(
            shipment: shipment,
            isSelectionMode: selectionMode,
            isSelected: isSelected,
            onLongPress: () => _handleLongPress(ref, shipment.id),
            onTap: selectionMode
                ? () => _handleSelectionToggle(ref, shipment.id)
                : () => context.push('/detail/${shipment.id}'),
          )
              .animate()
              .fadeIn(duration: 300.ms, delay: (index * 50).ms)
              .slideX(begin: 0.1, end: 0);
        },
      ),
    );
  }

  Widget _buildLoadingList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: 5,
      itemBuilder: (context, index) => _ShipmentCardSkeleton(),
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref, Object error) {
    return EmptyState(
      icon: Icons.error_outline,
      title: 'Bir Hata Oluştu',
      description: error.toString(),
      action: ElevatedButton(
        onPressed: () => ref.read(shipmentsProvider.notifier).refresh(),
        child: const Text('Tekrar Dene'),
      ),
    );
  }

  String _getEmptyTitle(WidgetRef ref) {
    if (ref.watch(_searchControllerProvider).text.isNotEmpty) return 'Sonuç Bulunamadı';
    switch (ref.watch(_selectedFilterProvider)) {
      case 'Bekleyen': return 'Bekleyen Kargonuz Yok';
      case 'Dağıtımda': return 'Dağıtımdaki Kargonuz Yok';
      case 'Bugün': return 'Bugün Teslim Edilecek Kargo Yok';
      case 'Teslim Edildi': return 'Teslim Edilmiş Kargonuz Yok';
      case 'Sorunlu': return 'Sorunlu Kargonuz Yok';
      default: return 'Henüz Kargonuz Yok';
    }
  }

  String _getEmptyDescription(WidgetRef ref) {
    if (ref.watch(_searchControllerProvider).text.isNotEmpty) {
      return '"${ref.watch(_searchControllerProvider).text}" için eşleşen kargo bulunamadı.';
    }
    switch (ref.watch(_selectedFilterProvider)) {
      case 'Bekleyen': return 'Henüz yolda veya işleme merkezinde kargonuz bulunmuyor.';
      case 'Dağıtımda': return 'Şu an dağıtıma çıkmış kargonuz yok.';
      case 'Bugün': return 'Bugün teslim edilecek kargonuz bulunmuyor.';
      case 'Teslim Edildi': return 'Henüz teslim edilmiş kargonuz yok.';
      case 'Sorunlu': return 'Sorunu olan kargonuz bulunmuyor, bu iyi haber!';
      default: return 'İlk kargonuzu ekleyerek takip etmeye başlayın.';
    }
  }

  void _showFilterBottomSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _FilterBottomSheet(
        currentFilter: ref.watch(_selectedFilterProvider),
        onFilterChanged: (filter) {
          ref.read(_selectedFilterProvider.notifier).state = filter;
          Navigator.pop(context);
        },
      ),
    );
  }

  void _handleLongPress(WidgetRef ref, String shipmentId) {
    ref.read(_selectionModeProvider.notifier).state = true;
    ref.read(_selectedShipmentsProvider.notifier).state = {shipmentId};
  }

  void _handleSelectionToggle(WidgetRef ref, String shipmentId) {
    final currentSelection = ref.read(_selectedShipmentsProvider);
    if (currentSelection.contains(shipmentId)) {
      ref.read(_selectedShipmentsProvider.notifier).state = 
          Set.from(currentSelection)..remove(shipmentId);
    } else {
      ref.read(_selectedShipmentsProvider.notifier).state = 
          Set.from(currentSelection)..add(shipmentId);
    }
    
    // If all selections are cleared, exit selection mode
    if (ref.read(_selectedShipmentsProvider).isEmpty) {
      ref.read(_selectionModeProvider.notifier).state = false;
    }
  }

  void _selectAllShipments(WidgetRef ref, AsyncValue<List<Shipment>> shipmentsAsync) {
    shipmentsAsync.when(
      data: (shipments) {
        final allIds = shipments.map((s) => s.id).toSet();
        ref.read(_selectedShipmentsProvider.notifier).state = allIds;
      },
      loading: () {},
      error: (_, __) {},
    );
  }

  Future<void> _confirmBulkDelete(BuildContext context, WidgetRef ref, Set<String> selectedShipments) async {
    final count = selectedShipments.length;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kargoları Sil'),
        content: Text(
          '$count kargoyu silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    
    if (result == true) {
      await _bulkDeleteShipments(context, ref, selectedShipments);
    }
  }

  Future<void> _bulkDeleteShipments(BuildContext context, WidgetRef ref, Set<String> selectedShipments) async {
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
      final notifier = ref.read(shipmentsProvider.notifier);
      for (final id in selectedShipments) {
        await notifier.deleteShipment(id);
      }
      
      if (!context.mounted) return;
      
      scaffoldMessenger.hideCurrentSnackBar();
      
      // Exit selection mode
      ref.read(_selectionModeProvider.notifier).state = false;
      ref.read(_selectedShipmentsProvider.notifier).state = {};
      
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('${selectedShipments.length} kargo silindi'),
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
}

class _CustomSearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;

  const _CustomSearchField({
    required this.controller,
    required this.hintText,
    this.onChanged,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  controller.clear();
                  onClear?.call();
                  onChanged?.call('');
                },
              )
            : null,
        filled: true,
        fillColor: Colors.grey[100],
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
          borderSide: BorderSide(color: context.colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
          borderSide: BorderSide(color: Colors.red, width: 1),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
          borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
      ),
      style: const TextStyle(
        fontSize: 16,
        height: 1.2,
        decoration: TextDecoration.none,
      ),
    );
  }
}

class _ShipmentCard extends ConsumerWidget {
  final Shipment shipment;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback? onLongPress;
  final VoidCallback? onTap;

  const _ShipmentCard({
    required this.shipment,
    this.isSelectionMode = false,
    this.isSelected = false,
    this.onLongPress,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppCard(
      onTap: onTap ?? () => context.push('/detail/${shipment.id}'),
      onLongPress: onLongPress,
      child: Stack(
        children: [
          if (isSelectionMode)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? context.colorScheme.primary : Colors.grey[400]!,
                    width: 2,
                  ),
                  color: isSelected ? context.colorScheme.primary : Colors.transparent,
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check,
                        size: 16,
                        color: Colors.white,
                      )
                    : null,
              ),
            ),
          Row(
            children: [
              CarrierAvatar(
                carrierCode: shipment.carrierCode,
                carrierName: shipment.carrierName,
                radius: 28,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            shipment.displayName,
                            style: context.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        StatusChip(status: shipment.status, small: true),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      shipment.carrierName,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Son güncelleme: ${shipment.formattedLastUpdate}',
                          style: context.textTheme.bodySmall?.copyWith(
                            color: Colors.grey[500],
                          ),
                        ),
                        if (shipment.estimatedDelivery != null) ...[
                          const SizedBox(width: 16),
                          Icon(
                            Icons.event,
                            size: 14,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            shipment.estimatedDelivery!.formatTurkish(withTime: true),
                            style: context.textTheme.bodySmall?.copyWith(
                              color: shipment.isOverdue ? Colors.red : Colors.grey[500],
                              fontWeight: shipment.isOverdue ? FontWeight.w600 : FontWeight.w400,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (shipment.latestEvent != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _getEventIcon(shipment.latestEvent!.status),
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                shipment.latestEvent!.description,
                                style: context.textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[700],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (shipment.latestEvent!.location != null) ...[
                              const SizedBox(width: 8),
                              Icon(
                                Icons.location_on,
                                size: 12,
                                color: Colors.grey[500],
                              ),
                              const SizedBox(width: 2),
                              Expanded(
                                child: Text(
                                  shipment.latestEvent!.location!,
                                  style: context.textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[500],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (!isSelectionMode)
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey[400],
                ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getEventIcon(String status) {
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
      default:
        return Icons.info;
    }
  }
}

class _ShipmentCardSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.grey[300],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 16,
                  width: double.infinity,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 8),
                Container(
                  height: 12,
                  width: 100,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 8),
                Container(
                  height: 12,
                  width: 150,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 8),
                Container(
                  height: 12,
                  width: 200,
                  color: Colors.grey[300],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterBottomSheet extends ConsumerWidget {
  final String currentFilter;
  final ValueChanged<String> onFilterChanged;

  const _FilterBottomSheet({
    required this.currentFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = AppUtils.getFilterOptions();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filtrele',
            style: context.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          ...filters.map((filter) => RadioListTile<String>(
                title: Text(filter),
                value: filter,
                groupValue: currentFilter,
                onChanged: (value) => onFilterChanged(value!),
                activeColor: context.colorScheme.primary,
              )),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}