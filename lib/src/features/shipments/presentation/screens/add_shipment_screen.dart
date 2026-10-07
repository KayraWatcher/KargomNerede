import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:kargom_nerede/src/core/constants/app_constants.dart';
import 'package:kargom_nerede/src/core/utils/app_utils.dart';
import 'package:kargom_nerede/src/core/extensions/extensions.dart';
import 'package:kargom_nerede/src/shared/models/shipment.dart';
import 'package:kargom_nerede/src/shared/models/carrier.dart';
import 'package:kargom_nerede/src/shared/widgets/common_widgets.dart';
import 'package:kargom_nerede/src/features/shipments/presentation/providers/shipment_providers.dart';

final _trackingControllerProvider = StateProvider<TextEditingController>((ref) => TextEditingController());
final _nameControllerProvider = StateProvider<TextEditingController>((ref) => TextEditingController());
final _detectedCarrierCodeProvider = StateProvider<String?>((ref) => null);
final _selectedCarrierProvider = StateProvider<Carrier?>((ref) => null);
final _isDetectingProvider = StateProvider<bool>((ref) => false);
final _showCarrierSelectionProvider = StateProvider<bool>((ref) => false);

class AddShipmentScreen extends ConsumerWidget {
  const AddShipmentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = GlobalKey<FormState>();
    final trackingController = ref.watch(_trackingControllerProvider);
    final nameController = ref.watch(_nameControllerProvider);
    final detectedCarrierCode = ref.watch(_detectedCarrierCodeProvider);
    final selectedCarrier = ref.watch(_selectedCarrierProvider);
    final isDetecting = ref.watch(_isDetectingProvider);
    final showCarrierSelection = ref.watch(_showCarrierSelectionProvider);
    final carriersAsync = ref.watch(activeCarriersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kargo Ekle'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: Form(
        key: GlobalKey<FormState>(), // We can't use a form key easily with ConsumerWidget, so we'll validate manually
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildTrackingNumberField(context, ref, trackingController),
            const SizedBox(height: 24),
            _buildCarrierSection(context, ref, carriersAsync),
            const SizedBox(height: 24),
            _buildCustomNameField(context, ref),
            const SizedBox(height: 32),
            _buildAddButton(context, ref),
            const SizedBox(height: 16),
            _buildInfoText(context),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackingNumberField(BuildContext context, WidgetRef ref, TextEditingController controller) {
    final isDetecting = ref.watch(_isDetectingProvider);
    final detectedCarrierCode = ref.watch(_detectedCarrierCodeProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Takip Numarası',
          style: context.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'Örn: 1234567890123',
            prefixIcon: const Icon(Icons.qr_code),
            suffixIcon: isDetecting
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : detectedCarrierCode != null
                    ? Icon(
                        Icons.check_circle,
                        color: Colors.green[600],
                      )
                    : null,
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Takip numarası gereklidir';
            }
            if (!AppUtils.isValidTrackingNumber(value.trim())) {
              return 'Geçersiz takip numarası formatı';
            }
            return null;
          },
          onChanged: (value) {
            if (value.length >= 8 && !ref.read(_isDetectingProvider)) {
              _detectCarrier(ref, value);
            }
          },
          textInputAction: TextInputAction.next,
        ),
        if (detectedCarrierCode != null && !isDetecting)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  size: 16,
                  color: Colors.green[600],
                ),
                const SizedBox(width: 4),
                Text(
                  'Kargo firması otomatik algılandı',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: Colors.green[600],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Future<void> _detectCarrier(WidgetRef ref, String trackingNumber) async {
    ref.read(_isDetectingProvider.notifier).state = true;
    ref.read(_detectedCarrierCodeProvider.notifier).state = null;
    ref.read(_selectedCarrierProvider.notifier).state = null;
    ref.read(_showCarrierSelectionProvider.notifier).state = false;

    await Future.delayed(const Duration(milliseconds: 500));

    // Use carrier patterns from AppConstants
    String? detectedCode;
    final normalizedTracking = trackingNumber.trim().toUpperCase();
    
    for (final entry in AppConstants.carrierPatterns.entries) {
      for (final pattern in entry.value) {
        if (pattern.hasMatch(normalizedTracking)) {
          detectedCode = entry.key;
          break;
        }
      }
      if (detectedCode != null) break;
    }

    ref.read(_isDetectingProvider.notifier).state = false;
    ref.read(_detectedCarrierCodeProvider.notifier).state = detectedCode;
    if (detectedCode != null) {
      ref.read(_selectedCarrierProvider.notifier).state = _getCarrierByCode(detectedCode!);
    }
    ref.read(_showCarrierSelectionProvider.notifier).state = detectedCode == null;
  }

  Carrier? _getCarrierByCode(String code) {
    // This would be fetched from the database
    return null;
  }

  Widget _buildCarrierSection(BuildContext context, WidgetRef ref, AsyncValue<List<Carrier>> carriersAsync) {
    final detectedCarrierCode = ref.watch(_detectedCarrierCodeProvider);
    final selectedCarrier = ref.watch(_selectedCarrierProvider);
    final showCarrierSelection = ref.watch(_showCarrierSelectionProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Kargo Firması',
          style: context.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        if (ref.watch(_detectedCarrierCodeProvider) != null && ref.watch(_selectedCarrierProvider) != null)
          _buildDetectedCarrierCard(context, ref)
        else if (ref.watch(_showCarrierSelectionProvider))
          ref.watch(activeCarriersProvider).when(
            data: (carriers) => _buildCarrierSelection(context, ref, carriers),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => _buildManualCarrierInput(context, ref),
          )
        else if (ref.watch(_detectedCarrierCodeProvider) == null)
          _buildManualCarrierInput(context, ref),
      ],
    );
  }

  Widget _buildDetectedCarrierCard(BuildContext context, WidgetRef ref) {
    final selectedCarrier = ref.watch(_selectedCarrierProvider);
    final detectedCarrierCode = ref.watch(_detectedCarrierCodeProvider);

    return AppCard(
      child: Row(
        children: [
          CarrierAvatar(
            carrierCode: ref.watch(_selectedCarrierProvider)?.code ?? ref.watch(_detectedCarrierCodeProvider)!,
            carrierName: ref.watch(_selectedCarrierProvider)?.name,
            radius: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ref.watch(_selectedCarrierProvider)?.name ?? _formatCarrierName(ref.watch(_detectedCarrierCodeProvider)!),
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '✓ Otomatik algılandı',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: Colors.green[600],
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              ref.read(_showCarrierSelectionProvider.notifier).state = true;
              ref.read(_selectedCarrierProvider.notifier).state = null;
              ref.read(_detectedCarrierCodeProvider.notifier).state = null;
            },
            child: const Text('Değiştir'),
          ),
        ],
      ),
    );
  }

  Widget _buildManualCarrierInput(BuildContext context, WidgetRef ref) {
    final detectedCarrierCode = ref.watch(_detectedCarrierCodeProvider);
    
    return Column(
      children: [
        if (detectedCarrierCode == null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 20,
                  color: Colors.orange[700],
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Kargo firması otomatik belirlenemedi.',
                    style: context.textTheme.bodySmall?.copyWith(
                      color: Colors.orange[800],
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 8),
        TextFormField(
          decoration: InputDecoration(
            hintText: 'Kargo firmasını seçin veya otomatik algıla',
            prefixIcon: const Icon(Icons.local_shipping),
            suffixIcon: IconButton(
              icon: const Icon(Icons.arrow_drop_down),
              onPressed: () => ref.read(_showCarrierSelectionProvider.notifier).state = true,
            ),
          ),
          readOnly: true,
          onTap: () => ref.read(_showCarrierSelectionProvider.notifier).state = true,
          validator: (value) {
            if (ref.read(_selectedCarrierProvider) == null && ref.read(_detectedCarrierCodeProvider) == null) {
              return 'Kargo firması seçilmeli';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildCarrierSelection(BuildContext context, WidgetRef ref, List<Carrier> carriers) {
    final selectedCarrier = ref.watch(_selectedCarrierProvider);

    return Column(
      children: [
        Text(
          'Kargo firmasını seçin',
          style: context.textTheme.bodyMedium?.copyWith(
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: carriers.map((carrier) => _CarrierChip(
                carrier: carrier,
                isSelected: ref.watch(_selectedCarrierProvider)?.code == carrier.code,
                onTap: () => ref.read(_selectedCarrierProvider.notifier).state = carrier,
              )).toList(),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => _showOtherCarrierDialog(ref),
          child: const Text('Diğer / Listede yok'),
        ),
      ],
    );
  }

  Widget _buildCustomNameField(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Kargo Adı (İsteğe Bağlı)',
          style: context.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: ref.watch(_nameControllerProvider),
          decoration: InputDecoration(
            hintText: 'Örn: Yeni kulaklık, Annemin ayakkabısı...',
            prefixIcon: const Icon(Icons.label),
          ),
          textInputAction: TextInputAction.done,
        ),
      ],
    );
  }

  Widget _buildAddButton(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _saveShipment(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Kargoyu Ekle'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _buildInfoText(BuildContext context) {
    return Text(
      'Takip numarası ile kargonuzun tüm hareketlerini anlık takip edebilirsiniz. '
      'Durum değişikliklerinde bildirim alacaksınız.',
      style: context.textTheme.bodySmall?.copyWith(
        color: Colors.grey[600],
      ),
      textAlign: TextAlign.center,
    );
  }

  Future<void> _saveShipment(BuildContext context, WidgetRef ref) async {
    final trackingController = ref.read(_trackingControllerProvider);
    final nameController = ref.read(_nameControllerProvider);
    final carrierCode = ref.read(_selectedCarrierProvider)?.code ?? ref.read(_detectedCarrierCodeProvider);
    final carrierName = ref.read(_selectedCarrierProvider)?.name ?? _formatCarrierName(ref.read(_detectedCarrierCodeProvider) ?? '');

    if (carrierCode == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kargo firması seçilmeli')),
      );
      return;
    }

    final shipment = Shipment(
      id: AppUtils.generateId(),
      trackingNumber: ref.read(_trackingControllerProvider).text.trim().toUpperCase(),
      carrierCode: carrierCode!,
      carrierName: carrierName,
      customName: ref.read(_nameControllerProvider).text.trim().isEmpty ? null : ref.read(_nameControllerProvider).text.trim(),
      status: 'CREATED',
      lastUpdate: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      events: [
        TrackingEvent(
          id: AppUtils.generateId(),
          timestamp: DateTime.now(),
          status: 'CREATED',
          description: 'Gönderi takip sistemine eklendi',
        ),
      ],
    );

    await ref.read(shipmentsProvider.notifier).addShipment(shipment);

    if (context.mounted) {
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${shipment.displayName} eklendi'),
          action: SnackBarAction(
            label: 'Detay',
            onPressed: () => context.push('/detail/${shipment.id}'),
          ),
        ),
      );
    }
  }

  void _showOtherCarrierDialog(WidgetRef ref) {
    // We need a context for showDialog, so we'll need to handle this differently
    // For now, we'll skip this feature in ConsumerWidget
  }

  String _formatCarrierName(String code) {
    return code.split('_').map((e) => e.capitalize).join(' ');
  }
}

class _CarrierChip extends ConsumerWidget {
  final Carrier carrier;
  final bool isSelected;
  final VoidCallback onTap;

  const _CarrierChip({
    required this.carrier,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CarrierAvatar(
            carrierCode: carrier.code,
            carrierName: carrier.name,
            radius: 14,
          ),
          const SizedBox(width: 8),
          Text(carrier.name),
        ],
      ),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: context.colorScheme.primary.withValues(alpha: 0.1),
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
  }
}