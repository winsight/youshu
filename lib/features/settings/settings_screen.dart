import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';
import '../../services/webdav_service.dart';
import '../../data/repository/sync_repository.dart';
import '../../providers/database_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _urlController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _storage = const FlutterSecureStorage();
  bool _isConfigured = false;
  bool _isLoading = false;
  bool _isTesting = false;
  String? _lastSyncInfo;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final url = prefs.getString('webdav_url');
    final username = prefs.getString('webdav_username');
    final password = await _storage.read(key: 'webdav_password');

    if (url != null && username != null && password != null) {
      setState(() {
        _urlController.text = url;
        _usernameController.text = username;
        _passwordController.text = password;
        _isConfigured = true;
      });
    }

    final lastSync = prefs.getString('last_sync_time');
    if (lastSync != null) {
      setState(() {
        _lastSyncInfo = 'Last sync: ${_formatDate(DateTime.parse(lastSync))}';
      });
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _saveConfig() async {
    final url = _urlController.text.trim();
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (url.isEmpty || username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('webdav_url', url);
    await prefs.setString('webdav_username', username);
    await _storage.write(key: 'webdav_password', value: password);

    setState(() => _isConfigured = true);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('WebDAV configuration saved')),
      );
    }
  }

  Future<void> _testConnection() async {
    setState(() => _isTesting = true);
    final config = WebDavConfig(
      url: _urlController.text.trim(),
      username: _usernameController.text.trim(),
      password: _passwordController.text.trim(),
    );
    final service = WebDavService(config: config);
    final ok = await service.testConnection();

    if (mounted) {
      setState(() => _isTesting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? 'Connection successful!' : 'Connection failed'),
          backgroundColor: ok ? AppColors.primary : AppColors.error,
        ),
      );
    }
  }

  Future<void> _syncNow() async {
    setState(() => _isLoading = true);

    final config = WebDavConfig(
      url: _urlController.text.trim(),
      username: _usernameController.text.trim(),
      password: _passwordController.text.trim(),
    );

    final assetRepo = ref.read(assetRepositoryProvider);
    final syncRepo = SyncRepository(assetRepo);
    syncRepo.configure(config);

    final result = await syncRepo.sync();

    if (mounted) {
      setState(() {
        _isLoading = false;
        _lastSyncInfo =
            'Last sync: ${_formatDate(DateTime.now())} (push: ${result.pushed}, pull: ${result.pulled})';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.success
              ? 'Sync complete (push: ${result.pushed}, pull: ${result.pulled})'
              : 'Sync failed: ${result.error}'),
          backgroundColor:
              result.success ? AppColors.primary : AppColors.error,
        ),
      );
    }
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // WebDAV Section
          const Text(
            'WebDAV Sync',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Configure your WebDAV server for cloud sync (Nextcloud, Synology, etc.)',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),

          // URL
          TextFormField(
            controller: _urlController,
            decoration: const InputDecoration(
              labelText: 'WebDAV URL',
              hintText: 'https://your-server.com/remote.php/dav/files/user/',
            ),
          ),
          const SizedBox(height: 16),

          // Username
          TextFormField(
            controller: _usernameController,
            decoration: const InputDecoration(labelText: 'Username'),
          ),
          const SizedBox(height: 16),

          // Password
          TextFormField(
            controller: _passwordController,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Password'),
          ),
          const SizedBox(height: 24),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isTesting ? null : _testConnection,
                  child: _isTesting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child:
                              CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Test Connection'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _saveConfig,
                  child: const Text('Save Config'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Sync Section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
              border:
                  Border.all(color: AppColors.outlineVariant.withAlpha(80)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Sync Status',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurfaceVariant,
                        letterSpacing: 0.24,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _isConfigured ? AppColors.primary : AppColors.outline,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _isConfigured ? 'Configured' : 'Not configured',
                      style: TextStyle(
                        fontSize: 11,
                        color: _isConfigured
                            ? AppColors.primary
                            : AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                if (_lastSyncInfo != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _lastSyncInfo!,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed:
                        (!_isConfigured || _isLoading) ? null : _syncNow,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child:
                                CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.sync, size: 18),
                    label: Text(_isLoading ? 'Syncing...' : 'Sync Now'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primaryContainer,
                      foregroundColor: AppColors.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // About Section
          const Text(
            'About',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
            ),
            child: const Column(
              children: [
                _AboutRow(label: 'App Name', value: 'Asset Sum'),
                Divider(color: AppColors.outlineVariant),
                _AboutRow(label: 'Version', value: '1.0.0'),
                Divider(color: AppColors.outlineVariant),
                _AboutRow(label: 'Data Storage', value: 'Local + WebDAV Sync'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AboutRow extends StatelessWidget {
  final String label;
  final String value;

  const _AboutRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
