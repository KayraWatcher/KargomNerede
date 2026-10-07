import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:kargom_nerede/src/core/constants/app_constants.dart';
import 'package:kargom_nerede/src/core/extensions/extensions.dart';
import 'package:kargom_nerede/src/features/update/presentation/screens/optional_update_dialog.dart';
import 'package:kargom_nerede/src/shared/providers/supabase_providers.dart';

/// Force update screen - shown when minimum version is required
class ForceUpdateScreen extends ConsumerWidget {
  const ForceUpdateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final updateStatus = ref.watch(updateStatusProvider);
    
    return PopScope(
      canPop: false, // Prevent back button from dismissing
      child: Scaffold(
        backgroundColor: context.colorScheme.surface,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        context.colorScheme.error.withValues(alpha: 0.15),
                        context.colorScheme.error.withValues(alpha: 0.05),
                      ],
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: context.colorScheme.error.withValues(alpha: 0.2),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.system_update_alt_rounded,
                    size: 60,
                    color: context.colorScheme.error,
                  ),
                ),
                const SizedBox(height: 32),
                
                // Title
                Text(
                  'Güncelleme Gerekli',
                  style: context.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: context.colorScheme.onSurface,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                
                // Message
                Text(
                  updateStatus.message ?? 
                  'Uygulamayı kullanmaya devam etmek için en yeni sürümü yüklemeniz gerekiyor.',
                  style: context.textTheme.bodyLarge?.copyWith(
                    color: context.colorScheme.onSurface.withValues(alpha: 0.75),
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                
                // Version info
                if (updateStatus.minimumVersion != null) ...[
                  Text(
                    'Minimum sürüm: ${updateStatus.minimumVersion}',
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: context.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
                if (updateStatus.latestVersion != null) ...[
                  Text(
                    'Mevcut sürüm: ${updateStatus.latestVersion}',
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: context.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                
                // Update button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _launchDownloadUrl(updateStatus.downloadUrl, context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.colorScheme.error,
                      foregroundColor: context.colorScheme.onError,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    child: const Text('Güncelle'),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Note
                Text(
                  'Uygulama kapatılmadan güncellenemez.',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _launchDownloadUrl(String? url, BuildContext context) async {
    if (url == null || url.isEmpty) {
      // Fallback to update site
      const updateSiteUrl = 'https://kargomnerede.com';
      if (await canLaunchUrl(Uri.parse(updateSiteUrl))) {
        await launchUrl(Uri.parse(updateSiteUrl), mode: LaunchMode.externalApplication);
      }
      return;
    }
    
    final downloadUrl = url.startsWith('http') ? url : 'https://kargomnerede.com$url';
    
    if (await canLaunchUrl(Uri.parse(downloadUrl))) {
      await launchUrl(Uri.parse(downloadUrl), mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('İndirme bağlantısı açılamadı'),
          backgroundColor: context.colorScheme.error,
        ),
      );
    }
  }
}

/// Wrapper to show optional update dialog when needed
class OptionalUpdateChecker extends ConsumerStatefulWidget {
  final Widget child;
  final Duration checkInterval;

  const OptionalUpdateChecker({
    super.key,
    required this.child,
    this.checkInterval = const Duration(hours: 24),
  });

  @override
  ConsumerState<OptionalUpdateChecker> createState() => _OptionalUpdateCheckerState();
}

class _OptionalUpdateCheckerState extends ConsumerState<OptionalUpdateChecker> {
  Timer? _timer;
  bool _dialogShown = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(widget.checkInterval, (_) => _checkForOptionalUpdate());
    // Initial check
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkForOptionalUpdate());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _checkForOptionalUpdate() {
    final updateStatus = ref.read(updateStatusProvider);
    if (updateStatus.showOptionalUpdate && !_dialogShown && mounted) {
      _dialogShown = true;
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (_) => const OptionalUpdateDialog(),
      ).then((_) => _dialogShown = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}