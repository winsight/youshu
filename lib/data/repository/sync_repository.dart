import 'package:shared_preferences/shared_preferences.dart';
import '../../services/cloud_storage.dart';
import '../../services/cloud_storage_factory.dart';
import '../../services/sync_service.dart';
import 'asset_repository.dart';

class SyncRepository {
  final AssetRepository _assetRepo;
  CloudStorage? _storage;

  SyncRepository(this._assetRepo);

  void configure(StorageConfig config) {
    _storage = CloudStorageFactory.create(config);
  }

  bool get isConfigured => _storage?.isConfigured() ?? false;

  Future<bool> testConnection() async {
    if (_storage == null) return false;
    return _storage!.testConnection();
  }

  Future<SyncReport> sync() async {
    if (_storage == null) {
      return const SyncReport(success: false, error: 'Storage not configured');
    }

    // ensureValidToken 会先从安全存储恢复 token，再验证有效性
    if (!await _storage!.ensureValidToken()) {
      return const SyncReport(
        success: false,
        error: 'Not authenticated, please sign in first',
      );
    }

    final service = SyncService(localDb: _assetRepo, remote: _storage!);
    final report = await service.sync();

    if (report.success && report.syncTime != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_sync_time', report.syncTime!.toIso8601String());
    }

    return report;
  }
}
