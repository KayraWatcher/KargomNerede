import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kargom_nerede/src/core/errors/app_exceptions.dart';
import 'package:kargom_nerede/src/core/utils/app_utils.dart';
import 'package:kargom_nerede/src/core/extensions/extensions.dart';
import 'package:kargom_nerede/src/shared/models/shipment.dart';
import 'package:kargom_nerede/src/shared/models/carrier.dart';
import 'package:kargom_nerede/src/shared/widgets/common_widgets.dart';
import 'package:kargom_nerede/src/features/shipments/data/tracking_api.dart';
import 'package:kargom_nerede/src/features/shipments/presentation/providers/shipment_providers.dart';

/// Add shipment screen.
///
/// Focus/input state lives in [State] (never in `build`), so every rebuild
/// caused by carrier detection keeps the same controller, focus node and form
/// key - typing can never close the keyboard or reset the field.
class AddShipmentScreen extends ConsumerStatefulWidget {
  const AddShipmentScreen({super.key});

  @override
  ConsumerState<AddShipmentScreen> createState() => _AddShipmentScreenState();
}

class _AddShipmentScreenState extends ConsumerState<AddShipmentScreen> {
  /// Carrier detection runs only after the user stopped typing.
  static const Duration _detectionDebounce = Duration(milliseconds: 400);
  static const int _minDetectionLength = 5;
  static const int _minBackendDetectionLength = 8;
  static const int _maxBackendDetectionAttempts = 5;

  final TextEditingController _trackingController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final FocusNode _trackingFocusNode = FocusNode();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final Debouncer _detectionDebouncer = Debouncer(delay: _detectionDebounce);

  /// Incremented for every detection run; a slow result that belongs to an
  /// older tracking number is dropped instead of overwriting the new one.
  int _detectionSequence = 0;

  bool _isDetecting = false;
  bool _detectionCompleted = false;
  String? _detectedCarrierCode;
  bool _detectedFromRecord = false;
  Carrier? _selectedCarrier;
  bool _showCarrierSelection = false;
  Shipment? _existingShipment;

  /// True while the real tracking request (`POST /tracking/track`) is running
  /// - blocks a second tap and is shown on the button.
  bool _isSaving = false;

  /// Backend detection results (including failures) per normalized number, so
  /// a tracking number never triggers the same request twice.
  final Map<String, String?> _backendDetectionCache = {};
  int _backendDetectionAttempts = 0;

  /// Cancelled on dispose: leaving the screen never leaves a request running.
  CancelToken? _detectionCancelToken;

  @override
  void dispose() {
    _detectionDebouncer.dispose();
    _detectionCancelToken?.cancel('screen disposed');
    _trackingController.dispose();
    _nameController.dispose();
    _trackingFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildTrackingNumberField(context),
            if (_existingShipment != null) ...[
              const SizedBox(height: 16),
              _buildExistingShipmentCard(context, _existingShipment!),
            ],
            const SizedBox(height: 24),
            _buildCarrierSection(context, carriersAsync),
            const SizedBox(height: 24),
            _buildCustomNameField(context),
            const SizedBox(height: 32),
            _buildAddButton(),
            const SizedBox(height: 16),
            _buildInfoText(context),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Tracking number
  // ---------------------------------------------------------------------------

  Widget _buildTrackingNumberField(BuildContext context) {
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
          controller: _trackingController,
          focusNode: _trackingFocusNode,
          decoration: InputDecoration(
            hintText: 'Örn: 1234567890123',
            prefixIcon: const Icon(Icons.qr_code),
            // Fixed size slot: swapping the spinner/check mark never shifts
            // the field or the content below it.
            suffixIcon: Padding(
              padding: const EdgeInsets.all(12),
              child: _detectionSuffixIcon(),
            ),
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
          onChanged: _onTrackingChanged,
          textInputAction: TextInputAction.next,
          autocorrect: false,
          enableSuggestions: false,
          textCapitalization: TextCapitalization.none,
        ),
      ],
    );
  }

  Widget _detectionSuffixIcon() {
    if (_isDetecting) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    if (_detectedCarrierCode != null) {
      return Icon(Icons.check_circle, color: Colors.green[600], size: 20);
    }
    // Empty, fixed-size placeholder keeps the layout stable.
    return const SizedBox(width: 20, height: 20);
  }

  void _onTrackingChanged(String value) {
    // Nothing is triggered per keystroke: detection (local lookup, pattern
    // matching and the optional backend call) happens once the user stopped
    // typing, so the field keeps focus and the screen does not jump.
    _detectionDebouncer.run(() => _runDetection(value));
  }

  Future<void> _runDetection(String rawValue) async {
    final normalized = rawValue.normalizeTrackingNumber();
    final sequence = ++_detectionSequence;

    if (normalized.length < _minDetectionLength) {
      if (!mounted || sequence != _detectionSequence) return;
      setState(() {
        _isDetecting = false;
        _detectionCompleted = false;
        _detectedCarrierCode = null;
        _detectedFromRecord = false;
        _existingShipment = null;
      });
      return;
    }

    setState(() => _isDetecting = true);

    // 1) A record saved earlier is the most reliable source: it also carries
    //    the carrier and the (possibly delivered) history of this number.
    final repository = ref.read(mockShipmentRepositoryProvider);
    final existing = await repository.findByTrackingNumber(normalized);
    if (!mounted || sequence != _detectionSequence) return;

    if (existing != null) {
      setState(() {
        _existingShipment = existing;
        _detectedCarrierCode = existing.carrierCode;
        _detectedFromRecord = true;
        _detectionCompleted = true;
        _isDetecting = false;
      });
      return;
    }

    // 2) Local detection from the number's format (client mirror of
    //    backend/src/services/carrierDetectionService.ts): a carrier code is
    //    only accepted when the format matches exactly one known carrier.
    //    Ambiguous digit formats (e.g. plain 13 digits) return null here.
    final localCode = AppUtils.detectCarrier(normalized);
    if (!mounted || sequence != _detectionSequence) return;

    setState(() {
      _existingShipment = null;
      _detectedCarrierCode = localCode;
      _detectedFromRecord = false;
      _detectionCompleted = true;
      _isDetecting = false;
    });

    if (localCode != null) return;

    // 3) Ambiguous or unknown format: ask the backend, which can ask the
    //    tracking provider. The UI already shows "algılanamadı"; a valid
    //    backend answer upgrades it, anything else is ignored.
    final remoteCode = await _detectCarrierViaBackend(normalized);
    if (!mounted || sequence != _detectionSequence) return;
    if (remoteCode == null || _detectedCarrierCode != null) return;
    setState(() {
      _detectedCarrierCode = remoteCode;
      _detectedFromRecord = false;
    });
  }

  /// Calls the backend's detection endpoint (which may consult the tracking
  /// provider). Failures are cached, the call is debounced by the caller and
  /// it never blocks the UI.
  Future<String?> _detectCarrierViaBackend(String normalized) async {
    if (_backendDetectionCache.containsKey(normalized)) {
      return _backendDetectionCache[normalized];
    }
    if (normalized.length < _minBackendDetectionLength ||
        _backendDetectionAttempts >= _maxBackendDetectionAttempts) {
      return null;
    }

    _backendDetectionAttempts++;
    String? code;
    try {
      final cancelToken = _detectionCancelToken ??= CancelToken();
      code = await ref
          .read(trackingApiProvider)
          .detectCarrier(normalized, cancelToken: cancelToken);
    } catch (_) {
      // Offline / backend unavailable: detection stays "not detected".
      code = null;
    }

    _backendDetectionCache[normalized] = code;
    return code;
  }

  // ---------------------------------------------------------------------------
  // Previously tracked shipment
  // ---------------------------------------------------------------------------

  Widget _buildExistingShipmentCard(BuildContext context, Shipment shipment) {
    final statusColor = shipment.statusColor;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history, size: 20, color: Colors.blueGrey[600]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Bu kargo daha önce takip edilmiş.',
                  style: context.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Durum:',
                style: context.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              Text(
                shipment.statusDisplayName,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: statusColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          if (shipment.isDelivered)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Geçmiş kaydınız korunuyor, tekrar eklemeniz gerekmez.',
                style: context.textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: () => _openExistingShipment(shipment),
                icon: const Icon(Icons.open_in_new, size: 18),
                label: const Text('Detayı Aç'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openExistingShipment(Shipment shipment) {
    if (!context.mounted) return;
    // Replace this screen so the back button does not return to a form that
    // is already known to be a duplicate.
    context.pushReplacement('/detail/${shipment.id}');
  }

  // ---------------------------------------------------------------------------
  // Carrier section
  // ---------------------------------------------------------------------------

  Widget _buildCarrierSection(
    BuildContext context,
    AsyncValue<List<Carrier>> carriersAsync,
  ) {
    final resolvedCarrier = _resolvedCarrier();

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
        if (resolvedCarrier != null) ...[
          _buildResolvedCarrierCard(context, resolvedCarrier),
          if (_showCarrierSelection) ...[
            const SizedBox(height: 12),
            _buildCarrierPicker(context, carriersAsync),
          ],
        ] else if (_isDetecting) ...[
          Text(
            'Kargo firması algılanıyor...',
            style: context.textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ] else if (_detectionCompleted) ...[
          _buildCarrierNotDetectedNotice(context),
          const SizedBox(height: 12),
          _buildCarrierPicker(context, carriersAsync),
        ] else ...[
          Text(
            'Takip numarası yazdığınızda kargo firması otomatik algılanır.',
            style: context.textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ],
    );
  }

  /// The carrier that will be saved: a manual selection wins, otherwise the
  /// detected one. Falls back to a display-only [Carrier] when a record was
  /// created with a code that is no longer in the registry.
  Carrier? _resolvedCarrier() {
    if (_selectedCarrier != null) return _selectedCarrier;
    final code = _detectedCarrierCode;
    if (code == null || code.isEmpty) return null;
    return CarrierRegistry.byCode(code) ??
        Carrier(
          code: code,
          name: _carrierDisplayName(code),
          logoUrl: '',
          isActive: true,
          isTurkishCarrier: true,
        );
  }

  Widget _buildResolvedCarrierCard(BuildContext context, Carrier carrier) {
    final isManual = _selectedCarrier != null;
    final subtitle = isManual
        ? 'Manuel seçildi'
        : _detectedFromRecord
            ? 'Önceki kayıttan alındı'
            : '✓ Otomatik algılandı';

    return AppCard(
      child: Row(
        children: [
          CarrierAvatar(
            carrierCode: carrier.code,
            carrierName: carrier.name,
            radius: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  carrier.name,
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => setState(() => _showCarrierSelection = true),
            child: const Text('Değiştir'),
          ),
        ],
      ),
    );
  }

  Widget _buildCarrierNotDetectedNotice(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 20, color: Colors.orange[700]),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kargo firması algılanamadı',
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: Colors.orange[900],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Aşağıdan firmanızı seçebilirsiniz.',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: Colors.orange[800],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCarrierPicker(
    BuildContext context,
    AsyncValue<List<Carrier>> carriersAsync,
  ) {
    return carriersAsync.when(
      data: (carriers) => _buildCarrierSelection(context, carriers),
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(8),
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (_, _) => Text(
        'Kargo firması listesi yüklenemedi.',
        style: context.textTheme.bodySmall?.copyWith(color: Colors.red),
      ),
    );
  }

  Widget _buildCarrierSelection(BuildContext context, List<Carrier> carriers) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
          children: carriers
              .map((carrier) => _CarrierChip(
                    carrier: carrier,
                    isSelected: _selectedCarrier?.code == carrier.code,
                    onTap: () => setState(() {
                      _selectedCarrier = carrier;
                      _showCarrierSelection = false;
                    }),
                  ))
              .toList(),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Name + save
  // ---------------------------------------------------------------------------

  Widget _buildCustomNameField(BuildContext context) {
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
          controller: _nameController,
          decoration: const InputDecoration(
            hintText: 'Örn: Yeni kulaklık, Annemin ayakkabısı...',
            prefixIcon: Icon(Icons.label),
          ),
          textInputAction: TextInputAction.done,
        ),
      ],
    );
  }

  Widget _buildAddButton() {
    final existing = _existingShipment;
    final saving = _isSaving;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: saving
            ? null
            : existing != null
                ? () => _openExistingShipment(existing)
                : _saveShipment,
        icon: saving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(existing != null ? Icons.open_in_new : Icons.add),
        label: Text(saving
            ? 'Takip bilgisi alınıyor...'
            : existing != null
                ? 'Mevcut Kargoyu Aç'
                : 'Kargoyu Ekle'),
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

  Future<void> _saveShipment() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    final trackingNumber = _trackingController.text.normalizeTrackingNumber();

    // Duplicate guard: the same tracking number must never create a second
    // shipment - the existing record (active or delivered) is used instead.
    final repository = ref.read(mockShipmentRepositoryProvider);
    final existing = await repository.findByTrackingNumber(trackingNumber);
    if (!mounted) return;

    if (existing != null) {
      setState(() => _existingShipment = existing);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Bu kargo daha önce takip edilmiş: ${existing.statusDisplayName}')),
      );
      _openExistingShipment(existing);
      return;
    }

    final carrierCode = _selectedCarrier?.code ?? _detectedCarrierCode;
    if (carrierCode == null) {
      setState(() => _showCarrierSelection = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Kargo firması algılanamadı, lütfen firma seçin')),
      );
      return;
    }

    // Real tracking: the backend asks the configured tracking provider, so
    // the status/timeline stored below are provider data - never something
    // the app made up. On failure the shipment is NOT created and the error
    // is shown instead.
    setState(() => _isSaving = true);
    TrackResult tracked;
    try {
      tracked = await ref.read(trackingApiProvider).track(
            trackingNumber: trackingNumber,
            carrierCode: carrierCode,
          );
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      final detail = error is AppException ? error.message : '$error';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Takip bilgisi alınamadı: $detail')),
      );
      return;
    }
    if (!mounted) return;

    final shipment = tracked.toShipment(
      customName: _nameController.text.trim().isEmpty
          ? null
          : _nameController.text.trim(),
    );

    final stored =
        await ref.read(shipmentsProvider.notifier).addShipment(shipment);
    if (!mounted) return;
    setState(() => _isSaving = false);

    if (stored.id != shipment.id) {
      // Another record with the same tracking number won the race.
      setState(() => _existingShipment = stored);
      _openExistingShipment(stored);
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    router.pop();
    messenger.showSnackBar(
      SnackBar(
        content: Text('${shipment.displayName} eklendi'),
        action: SnackBarAction(
          label: 'Detay',
          onPressed: () => router.push('/detail/${shipment.id}'),
        ),
      ),
    );
  }

  String _carrierDisplayName(String code) {
    return CarrierRegistry.displayNameOf(code, _formatCarrierName);
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
