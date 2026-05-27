import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/utils/logger.dart';
import '../../services/webdav_service.dart';
import '../models/asset.dart';
import 'asset_repository.dart';

class SyncRepository {
  final AssetRepository _assetRepo;
  WebDavService? _webdav;

  SyncRepository(this._assetRepo);

  void configure(WebDavConfig config) {
    _webdav = WebDavService(config: config);
  }

  bool get isConfigured => _webdav != null;

  Future<bool> testConnection() async {
    if (_webdav == null) return false;
    return _webdav!.testConnection();
  }

  Future<SyncResult> sync() async {
    if (_webdav == null) {
      return SyncResult(success: false, error: 'WebDAV not configured');
    }

    final result = SyncResult();
    try {
      final prefs = await SharedPreferences.getInstance();

      // Ensure remote structure exists
      await _webdav!.createDirectory('/changes');
      await _webdav!.createDirectory('/images');

      // Push local changes
      final allAssets = await _assetRepo.getAllAssets();
      for (final asset in allAssets) {
        final lastAssetSync = prefs.getInt('sync_${asset.id}') ?? 0;
        if (asset.syncVersion > lastAssetSync) {
          try {
            // Push JSON
            final json = jsonEncode(asset.toJson());
            await _webdav!.writeFile('/changes/${asset.id}.json', json);
            result.pushed++;

            // Push image
            if (asset.imagePath != null) {
              final imageFile = File(asset.imagePath!);
              if (await imageFile.exists()) {
                await _webdav!.uploadFile('/images/${asset.id}.jpg', imageFile);
              }
            }

            await prefs.setInt('sync_${asset.id}', asset.syncVersion);
          } catch (e) {
            AppLogger.warn('Failed to push asset ${asset.id}: $e');
          }
        }
      }

      // Pull remote changes
      final files = await _webdav!.listFiles('/changes/');
      for (final file in files) {
        final id = file.split('/').last.replaceAll('.json', '');
        if (id.isEmpty) continue;

        // Pull remote changes that are newer than local
        final content = await _webdav!.readFile('/changes/$id.json');
        if (content != null) {
          try {
            final json = jsonDecode(content) as Map<String, dynamic>;
            final remoteAsset = Asset.fromJson(json);

            // Last-write-wins
            final localAsset = await _assetRepo.getAssetById(id);
            if (localAsset == null ||
                remoteAsset.updatedAt.isAfter(localAsset.updatedAt)) {
              await _assetRepo.upsertAsset(remoteAsset.copyWith(
                syncVersion: remoteAsset.syncVersion,
              ));
              result.pulled++;

              // Download image
              final imgFile = await _webdav!.downloadFile(
                '/images/$id.jpg',
                '${await _getImageDir()}/$id.jpg',
              );
              if (imgFile != null) {
                await _assetRepo.upsertAsset(remoteAsset.copyWith(
                  imagePath: imgFile.path,
                  syncVersion: remoteAsset.syncVersion,
                ));
              }
            }
            await prefs.setInt('sync_$id', remoteAsset.syncVersion);
          } catch (e) {
            AppLogger.warn('Failed to process remote asset $id: $e');
          }
        }
      }

      await prefs.setString('last_sync_time', DateTime.now().toIso8601String());
      result.success = true;
    } catch (e) {
      AppLogger.error('Sync failed: $e');
      result.success = false;
      result.error = e.toString();
    }

    return result;
  }

  Future<String> _getImageDir() async {
    final prefs = await SharedPreferences.getInstance();
    final dir = Directory('${prefs.getString('app_dir') ?? '.'}/images');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir.path;
  }
}

class SyncResult {
  bool success;
  String? error;
  int pushed;
  int pulled;

  SyncResult({
    this.success = false,
    this.error,
    this.pushed = 0,
    this.pulled = 0,
  });
}
