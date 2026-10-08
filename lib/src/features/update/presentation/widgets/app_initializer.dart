import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kargom_nerede/src/core/extensions/extensions.dart';
import 'package:kargom_nerede/src/features/update/presentation/screens/force_update_screen.dart';
import 'package:kargom_nerede/src/features/update/presentation/screens/optional_update_dialog.dart';
import 'package:kargom_nerede/src/shared/models/app_config.dart';
import 'package:kargom_nerede/src/shared/providers/supabase_providers.dart';

/// Provider to check if force update is required on app start
final forceUpdateCheckProvider = FutureProvider<UpdateCheckResult>((ref) async {
  try {
    final config = await ref.watch(appConfigProvider.future);
    return UpdateCheckResult.fromConfig(config);
  } catch (e) {
    // On error, allow app to continue (offline mode)
    return UpdateCheckResult(
      shouldForceUpdate: false,
      shouldShowOptional: false,
      isOffline: true,
    );
  }
});

class UpdateCheckResult {
  final bool shouldForceUpdate;
  final bool shouldShowOptional;
  final bool isOffline;
  final String? message;
  final String? downloadUrl;
  final String? latestVersion;
  final String? minimumVersion;

  const UpdateCheckResult({
    this.shouldForceUpdate = false,
    this.shouldShowOptional = false,
    this.isOffline = false,
    this.message,
    this.downloadUrl,
    this.latestVersion,
    this.minimumVersion,
  });

  factory UpdateCheckResult.fromConfig(AppConfig config) {
    return UpdateCheckResult(
      shouldForceUpdate: config.updateType == UpdateType.force,
      shouldShowOptional: config.updateType == UpdateType.optional,
      isOffline: false,
      message: config.updateMessage,
      downloadUrl: config.downloadUrl,
      latestVersion: config.latestVersion,
      minimumVersion: config.minimumVersion,
    );
  }
}

/// App initialization wrapper that handles force update check
class AppInitializer extends ConsumerStatefulWidget {
  final Widget child;

  const AppInitializer({super.key, required this.child});

  @override
  ConsumerState<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends ConsumerState<AppInitializer> {
  @override
  Widget build(BuildContext context) {
    final checkResult = ref.watch(forceUpdateCheckProvider);

    return checkResult.when(
      loading: () => widget.child,
      error: (error, stack) => widget.child,
      data: (result) {
        if (result.shouldForceUpdate) {
          return const ForceUpdateScreen();
        }
        
        // Show optional update dialog after app loads
        if (result.shouldShowOptional) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              showDialog(
                context: context,
                barrierDismissible: true,
                builder: (_) => const OptionalUpdateDialog(),
              );
            }
          });
        }
        
        return widget.child;
      },
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  final String? error;

  const _LoadingScreen({this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              error != null ? 'Yeniden deneniyor...' : 'Uygulama yükleniyor...',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            if (error != null) ...[
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  error!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}