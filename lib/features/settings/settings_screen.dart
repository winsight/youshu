import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/theme/app_colors.dart';
import '../../core/l10n/app_locale.dart';
import '../../services/cloud_storage.dart';
import '../../services/cloud_storage_factory.dart';
import '../../data/repository/sync_repository.dart';
import '../../providers/database_provider.dart';
import '../../providers/asset_providers.dart';
import '../../providers/locale_provider.dart';
import '../../providers/theme_mode_provider.dart';
import '../../shared/widgets/update_dialog.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isConfigured = false;
  bool _isSyncing = false;
  String? _lastSyncInfo;
  StorageProviderType _providerType = StorageProviderType.webdav;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _doSync() async {
    setState(() => _isSyncing = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final storage = const FlutterSecureStorage();
      final config = StorageConfig(
        type: _providerType,
        url: prefs.getString('webdav_url'),
        username: prefs.getString('webdav_username'),
        password: await storage.read(key: 'webdav_password'),
        accessToken: await _loadToken(),
      );
      final syncRepo = SyncRepository(ref.read(assetRepositoryProvider));
      syncRepo.configure(config);
      final result = await syncRepo.sync();

      if (mounted) {
        if (result.success) {
          ref.invalidate(assetListProvider);
          ref.invalidate(filteredAssetsProvider);
          ref.invalidate(dashboardSummaryProvider);
          ref.invalidate(categoryDistributionProvider);
          setState(() {
            final dt = result.syncTime ?? DateTime.now();
            _lastSyncInfo =
                '${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
          });
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.success
                  ? '${AppL10n.of(context).syncComplete} (↑${result.pushed} ↓${result.pulled} 🖼${result.imagesUploaded})'
                  : '${result.error}',
            ),
            backgroundColor: result.success
                ? AppColors.primary
                : AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  Future<String?> _loadToken() async {
    final storage = const FlutterSecureStorage();
    return await storage.read(key: 'gdrive_token') ??
           await storage.read(key: 'onedrive_token') ??
           await storage.read(key: 'storage_token');
  }

  Future<void> _loadStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final url = prefs.getString('webdav_url');
    final token = prefs.getString('storage_token');
    final lastSync = prefs.getString('last_sync_time');
    final providerStr = prefs.getString('storage_provider');
    if (providerStr != null && mounted) {
      setState(() {
        _providerType = StorageProviderType.values.firstWhere(
          (t) => t.name == providerStr,
          orElse: () => StorageProviderType.webdav,
        );
      });
    }
    if (mounted) {
      setState(() {
        _isConfigured =
            (url != null && url.isNotEmpty) ||
            (token != null && token.isNotEmpty);
        if (lastSync != null) {
          final dt = DateTime.parse(lastSync);
          _lastSyncInfo =
              '${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final selectedLang = ref.watch(localeProvider);
    final selectedTheme = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          // Language
          _SectionHeader(title: l10n.language),
          _Card(
            children: AppLanguage.values.map((lang) {
              final isSelected = selectedLang == lang;
              return InkWell(
                onTap: () =>
                    ref.read(localeProvider.notifier).setLanguage(lang),
                borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          lang.displayName,
                          style: TextStyle(
                            fontSize: 16,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                      if (isSelected)
                        const Icon(
                          Icons.check_circle,
                          color: AppColors.primary,
                          size: 22,
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          _SectionHeader(title: l10n.appearance),
          _Card(
            children: ThemeMode.values.map((mode) {
              final isSelected = selectedTheme == mode;
              return InkWell(
                onTap: () =>
                    ref.read(themeModeProvider.notifier).setThemeMode(mode),
                borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _themeIcon(mode),
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _themeLabel(mode, l10n),
                          style: TextStyle(
                            fontSize: 16,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                      if (isSelected)
                        const Icon(
                          Icons.check_circle,
                          color: AppColors.primary,
                          size: 22,
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Cloud Sync
          _SectionHeader(title: l10n.isZh ? '云同步' : 'Cloud Sync'),
          if (_lastSyncInfo != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                '${l10n.isZh ? '上次同步' : 'Last sync'}: $_lastSyncInfo',
                style: const TextStyle(fontSize: 12, color: AppColors.primary),
              ),
            ),
          _Card(
            children: StorageProviderType.values.map((provider) {
              return InkWell(
                onTap: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('storage_provider', provider.name);
                  setState(() => _providerType = provider);
                  await context.push('/settings/webdav');
                  _loadStatus();
                },
                borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Radio<StorageProviderType>(
                        value: provider,
                        groupValue: _providerType,
                        onChanged: (v) async {
                          if (v == null) return;
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setString('storage_provider', v.name);
                          setState(() => _providerType = v);
                        },
                        activeColor: AppColors.primary,
                      ),
                      Icon(
                        provider.iconData,
                        size: 22,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.isZh
                                  ? provider.chineseName
                                  : provider.displayName,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _providerDesc(provider, l10n.isZh),
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),

          // Sync button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              height: 48,
              child: FilledButton.icon(
                onPressed: (_isSyncing || !_isConfigured) ? null : _doSync,
                icon: _isSyncing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.sync, size: 20),
                label: Text(
                  _isSyncing
                      ? (AppL10n.of(context).isZh ? '同步中...' : 'Syncing...')
                      : (AppL10n.of(context).isZh ? '立即同步' : 'Sync Now'),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Check update
          _SectionHeader(title: l10n.isZh ? '版本更新' : 'Update'),
          _Card(
            children: [
              InkWell(
                onTap: () => checkAndShowUpdate(context),
                borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      const Icon(Icons.system_update, size: 22, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(l10n.isZh ? '检查更新' : 'Check for Updates',
                            style: const TextStyle(fontSize: 16, color: AppColors.onSurface)),
                      ),
                      const Icon(Icons.chevron_right, color: AppColors.onSurfaceVariant, size: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // About
          _SectionHeader(title: l10n.about),
          _Card(
            padding: const EdgeInsets.all(16),
            children: [
              _AboutRow(
                icon: Icons.info_outline,
                label: 'App Name',
                value: '有数',
              ),
              const Divider(color: AppColors.outlineVariant, height: 1),
              _AboutRow(icon: Icons.tag, label: 'Version', value: '1.0.0'),
              const Divider(color: AppColors.outlineVariant, height: 1),
              _AboutRow(
                icon: Icons.storage_outlined,
                label: 'Data Storage',
                value: 'Local + Cloud',
              ),
            ],
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  String _providerDesc(StorageProviderType type, bool isZh) {
    switch (type) {
      case StorageProviderType.webdav:
        return isZh
            ? '支持 Nextcloud / 坚果云 / Synology'
            : 'Nextcloud / Jianguoyun / Synology';
      case StorageProviderType.onedrive:
        return isZh ? '微软个人/企业账户登录' : 'Microsoft personal/business account';
      case StorageProviderType.googledrive:
        return isZh ? 'Google 账户授权登录' : 'Google account authorization';
    }
  }

  String _themeLabel(ThemeMode mode, AppL10n l10n) {
    switch (mode) {
      case ThemeMode.system:
        return l10n.themeSystem;
      case ThemeMode.light:
        return l10n.themeLight;
      case ThemeMode.dark:
        return l10n.themeDark;
    }
  }

  IconData _themeIcon(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return Icons.brightness_auto_outlined;
      case ThemeMode.light:
        return Icons.light_mode_outlined;
      case ThemeMode.dark:
        return Icons.dark_mode_outlined;
    }
  }
}

class _Card extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry? padding;
  const _Card({required this.children, this.padding});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: padding,
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      ),
      child: Column(children: children),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
    child: Text(
      title,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        letterSpacing: 0.5,
      ),
    ),
  );
}

class _AboutRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _AboutRow({
    required this.icon,
    required this.label,
    required this.value,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    ),
  );
}
