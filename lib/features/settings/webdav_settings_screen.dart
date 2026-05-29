import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';
import '../../core/l10n/app_locale.dart';
import '../../services/cloud_storage.dart';
import '../../services/cloud_storage_factory.dart';
import '../../data/repository/sync_repository.dart';
import '../../providers/database_provider.dart';
import '../../providers/asset_providers.dart';

class WebDavSettingsScreen extends ConsumerStatefulWidget {
  const WebDavSettingsScreen({super.key});
  @override
  ConsumerState<WebDavSettingsScreen> createState() =>
      _WebDavSettingsScreenState();
}

class _WebDavSettingsScreenState extends ConsumerState<WebDavSettingsScreen> {
  final _urlController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _storage = const FlutterSecureStorage();
  bool _isTesting = false;
  bool _isSyncing = false;
  bool _isAuthenticating = false;
  bool _isLoggedIn = false;
  String? _lastSyncInfo;
  StorageProviderType _providerType = StorageProviderType.webdav;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final providerStr = prefs.getString('storage_provider');
    if (providerStr != null) {
      _providerType = StorageProviderType.values.firstWhere(
        (t) => t.name == providerStr,
        orElse: () => StorageProviderType.webdav,
      );
    }
    final url = prefs.getString('webdav_url');
    final username = prefs.getString('webdav_username');
    final password = await _storage.read(key: 'webdav_password');
    final token = providerStr == 'googledrive'
        ? await _storage.read(key: 'gdrive_token')
        : await _storage.read(key: 'onedrive_token');

    if (mounted) {
      setState(() {
        if (url != null) _urlController.text = url;
        if (username != null) _usernameController.text = username;
        if (password != null) _passwordController.text = password;
        _isLoggedIn =
            (token != null && token.isNotEmpty) ||
            (url != null && url.isNotEmpty);
      });
    }

    final lastSync = prefs.getString('last_sync_time');
    if (lastSync != null && mounted) {
      setState(() => _lastSyncInfo = _fmt(DateTime.parse(lastSync)));
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  StorageConfig _buildConfig() => StorageConfig(
    type: _providerType,
    url: _urlController.text.trim(),
    username: _usernameController.text.trim(),
    password: _passwordController.text.trim(),
  );

  Future<void> _doLogin() async {
    setState(() => _isAuthenticating = true);
    try {
      final config = _buildConfig();
      final storage = CloudStorageFactory.create(config);
      final ok = await storage.authenticate(context);
      if (mounted) {
        setState(() => _isLoggedIn = ok);
        if (ok) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('storage_provider', _providerType.name);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ok
                  ? (AppL10n.of(context).isZh ? '登录成功' : 'Login OK')
                  : (AppL10n.of(context).isZh ? '登录失败' : 'Login failed'),
            ),
            backgroundColor: ok ? AppColors.primary : AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _isAuthenticating = false);
    }
  }

  Future<void> _doSync() async {
    setState(() => _isSyncing = true);
    final syncRepo = SyncRepository(ref.read(assetRepositoryProvider));
    syncRepo.configure(_buildConfig());
    final result = await syncRepo.sync();

    if (mounted) {
      if (result.success) {
        ref.invalidate(assetListProvider);
        ref.invalidate(filteredAssetsProvider);
        ref.invalidate(dashboardSummaryProvider);
        ref.invalidate(categoryDistributionProvider);
        setState(() => _lastSyncInfo = _fmt(result.syncTime ?? DateTime.now()));
      }
      setState(() => _isSyncing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.success
                ? '${AppL10n.of(context).syncComplete} (↑${result.pushed} ↓${result.pulled} 🖼${result.imagesUploaded})'
                : '${AppL10n.of(context).syncFailed}: ${result.error}',
          ),
          backgroundColor: result.success ? AppColors.primary : AppColors.error,
        ),
      );
    }
  }

  Future<void> _saveWebdav() async {
    final l10n = AppL10n.of(context);
    final url = _urlController.text.trim();
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    if (url.isEmpty || username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.fillAllFields)));
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('webdav_url', url);
    await prefs.setString('webdav_username', username);
    await _storage.write(key: 'webdav_password', value: password);
    await prefs.setString('storage_provider', _providerType.name);
    setState(() => _isLoggedIn = true);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.configSaved)));
    }
  }

  String _fmt(DateTime dt) =>
      '${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final isWebDav = _providerType == StorageProviderType.webdav;
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.isZh ? _providerType.chineseName : _providerType.displayName,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
                border: Border.all(color: colors.outlineVariant.withAlpha(80)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _isLoggedIn
                          ? AppColors.primary
                          : AppColors.outline,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _isLoggedIn ? l10n.configured : l10n.notConfigured,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _isLoggedIn
                          ? AppColors.primary
                          : colors.onSurfaceVariant,
                    ),
                  ),
                  if (_lastSyncInfo != null) ...[
                    const Spacer(),
                    Text(
                      _lastSyncInfo!,
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Fields (WebDAV only)
            if (isWebDav) ...[
              TextFormField(
                controller: _urlController,
                decoration: InputDecoration(
                  labelText: l10n.webdavUrl,
                  hintText: 'https://dav.jianguoyun.com/dav/',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _usernameController,
                decoration: InputDecoration(labelText: l10n.username),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(labelText: l10n.password),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _saveWebdav,
                child: Text(l10n.saveConfig),
              ),
            ],

            const Spacer(),

            // Login button (OAuth providers)
            if (!isWebDav) ...[
              SizedBox(
                height: 52,
                child: FilledButton.icon(
                  onPressed: _isAuthenticating ? null : _doLogin,
                  icon: _isAuthenticating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.login, size: 22),
                  label: Text(
                    _isLoggedIn
                        ? (l10n.isZh ? '重新登录' : 'Re-login')
                        : (l10n.isZh ? '授权登录' : 'Sign In'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor:
                        _providerType == StorageProviderType.googledrive
                        ? const Color(0xFF4285F4)
                        : const Color(0xFF0078D4),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 12),

            // Sync button
            SizedBox(
              height: 52,
              child: FilledButton.icon(
                onPressed: (_isSyncing || !_isLoggedIn) ? null : _doSync,
                icon: _isSyncing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.sync, size: 22),
                label: Text(
                  _isSyncing ? l10n.syncing : l10n.syncNow,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryContainer,
                  foregroundColor: AppColors.onPrimaryContainer,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
