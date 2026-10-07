import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kargom_nerede/src/core/constants/app_constants.dart';
import 'package:kargom_nerede/src/core/utils/app_utils.dart';
import 'package:kargom_nerede/src/core/extensions/extensions.dart';
import 'package:kargom_nerede/src/shared/providers/app_providers.dart';
import 'package:kargom_nerede/src/shared/models/settings.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    final notificationSettings = ref.watch(notificationSettingsProvider);
    final trackingProvider = ref.watch(trackingProviderProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayarlar'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _buildSection(
            context,
            'Görünüm',
            [
              _buildThemeTile(context, themeMode, ref),
              _buildLanguageTile(context, locale, ref),
            ],
          ),
          _buildSection(
            context,
            'Bildirimler',
            [
              _buildNotificationToggle(context, notificationSettings, ref),
              _buildNotificationDetailTiles(context, notificationSettings, ref),
            ],
          ),
          _buildSection(
            context,
            'Kargo Takip',
            [
              _buildTrackingProviderTile(context, trackingProvider, ref),
              _buildRefreshSettingsTile(context, ref),
            ],
          ),
          _buildSection(
            context,
            'Veri ve Depolama',
            [
              _buildCacheTile(context, ref),
              _buildExportDataTile(context, ref),
              _buildClearDataTile(context, ref),
            ],
          ),
          _buildSection(
            context,
            'Uygulama',
            [
              _buildAboutTile(context),
              _buildPrivacyTile(context),
              _buildLicensesTile(context),
              _buildVersionTile(context),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: context.textTheme.labelLarge?.copyWith(
              color: context.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ...children,
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildThemeTile(BuildContext context, ThemeMode themeMode, WidgetRef ref) {
    return ListTile(
      leading: Icon(
        themeMode == ThemeMode.dark
            ? Icons.dark_mode
            : themeMode == ThemeMode.light
                ? Icons.light_mode
                : Icons.settings_brightness,
        color: context.colorScheme.primary,
      ),
      title: const Text('Tema'),
      subtitle: Text(
        themeMode == ThemeMode.dark
            ? 'Koyu'
            : themeMode == ThemeMode.light
                ? 'Açık'
                : 'Sistem Ayarı',
      ),
      trailing: PopupMenuButton<ThemeMode>(
        initialValue: themeMode,
        onSelected: (mode) => ref.read(themeModeProvider.notifier).setThemeMode(mode),
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: ThemeMode.system,
            child: Row(
              children: [
                Icon(Icons.settings_brightness, size: 20),
                SizedBox(width: 8),
                Text('Sistem Ayarı'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: ThemeMode.light,
            child: Row(
              children: [
                Icon(Icons.light_mode, size: 20),
                SizedBox(width: 8),
                Text('Açık'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: ThemeMode.dark,
            child: Row(
              children: [
                Icon(Icons.dark_mode, size: 20),
                SizedBox(width: 8),
                Text('Koyu'),
              ],
            ),
          ),
        ],
        child: const Icon(Icons.arrow_drop_down),
      ),
    );
  }

  Widget _buildLanguageTile(BuildContext context, Locale locale, WidgetRef ref) {
    return ListTile(
      leading: Icon(Icons.language, color: context.colorScheme.primary),
      title: const Text('Dil'),
      subtitle: Text(locale.languageCode == 'tr' ? 'Türkçe' : 'English'),
      trailing: PopupMenuButton<Locale>(
        initialValue: locale,
        onSelected: (l) => ref.read(localeProvider.notifier).setLocale(l),
        itemBuilder: (context) => AppConstants.supportedLanguages.map((code) => PopupMenuItem(
              value: Locale(code),
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  Text(code == 'tr' ? 'Türkçe' : 'English'),
                ],
              ),
            )).toList(),
        child: const Icon(Icons.arrow_drop_down),
      ),
    );
  }

  Widget _buildNotificationToggle(BuildContext context, NotificationSettings settings, WidgetRef ref) {
    return SwitchListTile(
      secondary: Icon(
        settings.enabled ? Icons.notifications_active : Icons.notifications_off,
        color: context.colorScheme.primary,
      ),
      title: const Text('Bildirimler'),
      subtitle: Text(settings.enabled ? 'Açık' : 'Kapalı'),
      value: settings.enabled,
      onChanged: (value) {
        ref.read(notificationSettingsProvider.notifier).updateSettings(
              settings.copyWith(enabled: value),
            );
      },
    );
  }

  Widget _buildNotificationDetailTiles(BuildContext context, NotificationSettings settings, WidgetRef ref) {
    if (!settings.enabled) return const SizedBox.shrink();

    return Column(
      children: [
        _buildNotificationOption(
          context,
          'Yeni Hareket',
          'Kargonuzda yeni bir hareket olduğunda',
          settings.newMovement,
          (value) => ref.read(notificationSettingsProvider.notifier).updateSettings(
                settings.copyWith(newMovement: value),
              ),
        ),
        _buildNotificationOption(
          context,
          'Dağıtıma Çıktı',
          'Kargonuz dağıtıma çıktığında',
          settings.outForDelivery,
          (value) => ref.read(notificationSettingsProvider.notifier).updateSettings(
                settings.copyWith(outForDelivery: value),
              ),
        ),
        _buildNotificationOption(
          context,
          'Teslim Edildi',
          'Kargonuz teslim edildiğinde',
          settings.delivered,
          (value) => ref.read(notificationSettingsProvider.notifier).updateSettings(
                settings.copyWith(delivered: value),
              ),
        ),
        _buildNotificationOption(
          context,
          'Problem / İstisna',
          'Kargonuzda bir sorun oluştuğunda',
          settings.exception,
          (value) => ref.read(notificationSettingsProvider.notifier).updateSettings(
                settings.copyWith(exception: value),
              ),
        ),
        _buildNotificationOption(
          context,
          'Gecikme',
          'Tahmini teslim tarihi geçtiğinde',
          settings.delay,
          (value) => ref.read(notificationSettingsProvider.notifier).updateSettings(
                settings.copyWith(delay: value),
              ),
        ),
        _buildNotificationOption(
          context,
          'Sadece Wi-Fi',
          'Bildirimleri sadece Wi-Fi üzerinden gönder',
          settings.wifiOnly,
          (value) => ref.read(notificationSettingsProvider.notifier).updateSettings(
                settings.copyWith(wifiOnly: value),
              ),
        ),
      ],
    );
  }

  Widget _buildNotificationOption(
    BuildContext context,
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }

  Widget _buildTrackingProviderTile(BuildContext context, String provider, WidgetRef ref) {
    return ListTile(
      leading: Icon(Icons.api, color: context.colorScheme.primary),
      title: const Text('Takip Sağlayıcısı'),
      subtitle: Text(_getProviderName(provider)),
      trailing: PopupMenuButton<String>(
        onSelected: (p) => ref.read(trackingProviderProvider.notifier).setProvider(p),
        itemBuilder: (context) => [
          PopupMenuItem(
            value: AppConstants.trackingProvider17Track,
            child: const Text('17TRACK'),
          ),
          PopupMenuItem(
            value: AppConstants.trackingProviderAfterShip,
            child: const Text('AfterShip'),
          ),
          PopupMenuItem(
            value: AppConstants.trackingProviderShip24,
            child: const Text('Ship24'),
          ),
        ],
        child: const Icon(Icons.arrow_drop_down),
      ),
    );
  }

  String _getProviderName(String code) {
    if (code == AppConstants.trackingProvider17Track) return '17TRACK';
    if (code == AppConstants.trackingProviderAfterShip) return 'AfterShip';
    if (code == AppConstants.trackingProviderShip24) return 'Ship24';
    return code;
  }

  Widget _buildRefreshSettingsTile(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: Icon(Icons.refresh, color: context.colorScheme.primary),
      title: const Text('Otomatik Yenileme'),
      subtitle: const Text('Arka planda kargo durumlarını kontrol et'),
      trailing: Switch(
        value: true, // TODO: Get from settings
        onChanged: (value) {
          // TODO: Implement
        },
      ),
    );
  }

  Widget _buildCacheTile(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: Icon(Icons.storage, color: context.colorScheme.primary),
      title: const Text('Önbellek'),
      subtitle: const Text('Yerel verileri yönet'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        // TODO: Show cache management dialog
      },
    );
  }

  Widget _buildExportDataTile(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: Icon(Icons.download, color: context.colorScheme.primary),
      title: const Text('Verileri Dışa Aktar'),
      subtitle: const Text('Kargolarınızı JSON olarak kaydet'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        // TODO: Implement export
      },
    );
  }

  Widget _buildClearDataTile(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: Icon(Icons.delete_forever, color: Colors.red[600]),
      title: Text(
        'Tüm Verileri Temizle',
        style: TextStyle(color: Colors.red[600]),
      ),
      subtitle: const Text('Tüm kargolar ve ayarlar silinecek'),
      onTap: () => _showClearDataDialog(context),
    );
  }

  void _showClearDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tüm Verileri Temizle'),
        content: const Text(
            'Bu işlem tüm kargolarınızı, ayarlarınızı ve geçmişinizi kalıcı olarak silecek. Devam etmek istiyor musunuz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement clear data
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Veriler temizlendi')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Temizle'),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutTile(BuildContext context) {
    return ListTile(
      leading: Icon(Icons.info_outline, color: context.colorScheme.primary),
      title: const Text('Hakkında'),
      subtitle: const Text('Uygulama bilgileri ve sürüm'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showAboutDialog(context),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: AppConstants.appName,
      applicationVersion: AppConstants.appVersion,
      applicationIcon: const Icon(Icons.local_shipping, size: 48, color: Color(0xFF1E88E5)),
      children: [
        const Text(
          'KargomNerede - Tüm kargolarınızı tek uygulamadan takip edin.\n\n'
          'Türkiye\'deki ve yurtdışındaki onlarca kargo firmasını destekler. '
          'Otomatik taşıyıcı algılama, anlık bildirimler ve detaylı hareket geçmişi ile '
          'kargonuzun nerede olduğunu her an bilmenizi sağlar.',
        ),
      ],
    );
  }

  Widget _buildPrivacyTile(BuildContext context) {
    return ListTile(
      leading: Icon(Icons.privacy_tip_outlined, color: context.colorScheme.primary),
      title: const Text('Gizlilik Politikası'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showPrivacyPolicy(context),
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gizlilik Politikası'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Kargom Nerede uygulamasını kullanırken gizliliğiniz bizim için önemlidir.',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              const Text(
                'Toplanan Veriler:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              const Text('• Kargo takip numaralarınız\n• Kargo firması bilgileri\n• Uygulama kullanım istatistikleri'),
              const SizedBox(height: 12),
              const Text(
                'Veri Kullanımı:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              const Text('Verileriniz yalnızca kargo takibi için kullanılır ve üçüncü taraflarla paylaşılmaz.'),
              const SizedBox(height: 12),
              const Text(
                'Veri Saklama:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              const Text('Verileriniz cihazınızda yerel olarak saklanır. Cloud senkronizasyonu opsiyoneldir.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  Widget _buildLicensesTile(BuildContext context) {
    return ListTile(
      leading: Icon(Icons.description_outlined, color: context.colorScheme.primary),
      title: const Text('Açık Kaynak Lisanslar'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => showLicensePage(
        context: context,
        applicationName: AppConstants.appName,
        applicationVersion: AppConstants.appVersion,
      ),
    );
  }

  Widget _buildVersionTile(BuildContext context) {
    return ListTile(
      leading: Icon(Icons.build_outlined, color: context.colorScheme.primary),
      title: const Text('Sürüm'),
      subtitle: Text('${AppConstants.appVersion} (${AppConstants.packageName})'),
    );
  }
}