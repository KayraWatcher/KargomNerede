import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:kargom_nerede/src/core/constants/app_constants.dart';
import 'package:kargom_nerede/src/core/extensions/extensions.dart';
import 'package:kargom_nerede/src/shared/providers/supabase_providers.dart';

/// Optional update dialog - shown when newer version is available but not required
class OptionalUpdateDialog extends ConsumerWidget {
  const OptionalUpdateDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final updateStatus = ref.watch(updateStatusProvider);
    
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: context.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.new_releases_outlined,
              color: context.colorScheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Yeni Sürüm Mevcut',
              style: context.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            updateStatus.message ?? 
            'Uygulamanın yeni bir sürümü (${updateStatus.latestVersion ?? 'yeni sürüm'}) mevcut. Güncellemek ister misiniz?',
            style: context.textTheme.bodyMedium?.copyWith(
              height: 1.5,
            ),
          ),
          if (updateStatus.latestVersion != null) ...[
            const SizedBox(height: 12),
            Text(
              'Mevcut sürüm: ${updateStatus.latestVersion}',
              style: context.textTheme.bodySmall?.copyWith(
                color: context.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Şimdi Değil'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            _launchDownloadUrl(updateStatus.downloadUrl, context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: context.colorScheme.primary,
            foregroundColor: context.colorScheme.onPrimary,
          ),
          child: const Text('Güncelle'),
        ),
      ],
    );
  }

  Future<void> _launchDownloadUrl(String? url, BuildContext context) async {
    if (url == null || url.isEmpty) {
      const updateSiteUrl = 'https://kargomnerede.com';
      if (await canLaunchUrl(Uri.parse(updateSiteUrl))) {
        await launchUrl(Uri.parse(updateSiteUrl), mode: LaunchMode.externalApplication);
      }
      return;
    }
    
    final downloadUrl = url.startsWith('http') ? url : 'https://kargomnerede.com$url';
    
    if (await canLaunchUrl(Uri.parse(downloadUrl))) {
      await launchUrl(Uri.parse(downloadUrl), mode: LaunchMode.externalApplication);
    }
  }
}