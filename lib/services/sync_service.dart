import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../core/utils/logger.dart';
import '../data/models/asset.dart';
import '../data/repository/sync_db_interface.dart';
import 'cloud_storage.dart';

/// 同步结果
class SyncReport {
  final bool success;
  final String? error;
  final int pushed;
  final int pulled;
  final int imagesUploaded;
  final DateTime? syncTime;

  const SyncReport({
    required this.success,
    this.error,
    this.pushed = 0,
    this.pulled = 0,
    this.imagesUploaded = 0,
    this.syncTime,
  });

  @override
  String toString() =>
      'SyncReport(success=$success, pushed=$pushed, pulled=$pulled, error=$error)';
}

/// 云端单文件 (youshu/data.json) + 本地增量合并 同步引擎
///
/// 策略：
///   1. 拉取云端 youshu/data.json → List<Asset>
///   2. 与本地数据库逐条比对（Last-Write-Wins by updatedAt）
///   3. 合并完成后，将本地全部记录（含墓碑 isDeleted=true）序列化
///      为 JSON 覆盖上传 youshu/data.json
class SyncService {
  final ISyncDatabase _localDb;
  final CloudStorage _remote;

  SyncService({required ISyncDatabase localDb, required CloudStorage remote})
    : _localDb = localDb,
      _remote = remote;

  /// 云端数据文件路径
  static const remoteDataFile = 'youshu/data.json';
  static const remoteImageDir = 'youshu/images';

  /// 执行完整同步流程
  Future<SyncReport> sync() async {
    int pushed = 0;
    int pulled = 0;

    try {
      // ---- 1. 确保远端目录存在 ----
      await _remote.createDirectory('youshu');

      // ---- 2. 拉取云端 data.json ----
      List<Asset> remoteAssets;
      try {
        final raw = await _remote.readFile(remoteDataFile);
        if (raw == null || raw.trim().isEmpty) {
          remoteAssets = [];
          AppLogger.info('云端尚无 data.json，视为空列表');
        } else {
          final decoded = jsonDecode(raw) as List<dynamic>;
          remoteAssets = decoded
              .map((e) => Asset.fromJson(e as Map<String, dynamic>))
              .toList();
          AppLogger.info('拉取云端数据: ${remoteAssets.length} 条记录');
        }
      } catch (e) {
        // JSON 解析失败视为空列表（合并时本地数据会推上去）
        AppLogger.warn('云端 data.json 解析失败: $e');
        remoteAssets = [];
      }

      // ---- 3. 拉取本地全部数据（含墓碑） ----
      final localAssets = await _localDb.getAllIncludingDeleted();
      AppLogger.info('本地数据: ${localAssets.length} 条记录');
      final localMap = {for (final a in localAssets) a.id: a};
      final remoteMap = {for (final a in remoteAssets) a.id: a};

      // ---- 4. Last-Write-Wins 合并 ----
      // 追踪本次同步中从云端拉取（新增或更新）的资产 ID，用于后续下载图片
      final pulledIds = <String>[];

      // 4a. 云端有，本地无 → 直接插入
      for (final remote in remoteAssets) {
        if (!localMap.containsKey(remote.id)) {
          await _localDb.insert(remote);
          if (!remote.isDeleted) pulled++;
          pulledIds.add(remote.id);
          AppLogger.info('合并-插入: ${remote.id} (本地不存在)');
        }
      }

      // 4b. 本地有，云端也有 → 比较 updatedAt
      for (final local in localAssets) {
        final remote = remoteMap[local.id];
        if (remote == null) continue;

        if (remote.updatedAt.millisecondsSinceEpoch >
            local.updatedAt.millisecondsSinceEpoch) {
          await _localDb.update(remote);
          if (!remote.isDeleted) pulled++;
          pulledIds.add(local.id);
          AppLogger.info(
            '合并-覆盖: ${local.id} (云端 ${remote.updatedAt} > 本地 ${local.updatedAt})',
          );
        } else {
          AppLogger.info(
            '合并-保留本地: ${local.id} (本地 ${local.updatedAt} >= 云端 ${remote.updatedAt})',
          );
        }
      }

      // ---- 5. 下载本次拉取资产的关联图片 ----
      for (final id in pulledIds) {
        final remote = remoteMap[id];
        if (remote == null) continue;
        if (remote.imagePath != null && remote.imagePath!.isNotEmpty) {
          await _downloadImageIfNeeded(remote);
        }
      }

      // ---- 6. 闭环上传 —— 本地全部记录覆盖云端 data.json ----
      final allLocal = await _localDb.getAllIncludingDeleted();
      final activeLocal = allLocal.where((asset) => !asset.isDeleted).toList();
      final jsonList = allLocal.map((a) => a.toJson()).toList();
      final payload = const JsonEncoder.withIndent('  ').convert(jsonList);
      await _remote.writeFile(remoteDataFile, payload);
      pushed = activeLocal.length;
      AppLogger.info(
        '上传 data.json 完成: ${allLocal.length} 条记录，当前有效资产 $pushed 条',
      );

      // ---- 7. 上传所有本地图片（含贴纸） ----
      int imagesUploaded = 0;
      for (final local in allLocal) {
        if (local.isDeleted) continue;

        // 上传贴纸图（优先，因为更有展示价值）
        if (local.stickerImagePath != null &&
            local.stickerImagePath!.isNotEmpty) {
          final stickerFile = File(local.stickerImagePath!);
          if (await stickerFile.exists()) {
            try {
              final ext = local.stickerImagePath!.split('.').last;
              await _remote.uploadFile(
                '$remoteImageDir/${local.id}_sticker.$ext',
                stickerFile,
              );
              imagesUploaded++;
              AppLogger.info('上传贴纸图: ${local.id}_sticker.$ext');
            } catch (e) {
              AppLogger.warn('贴纸图上传失败 (${local.id}): $e');
            }
          }
        }

        // 上传原图
        if (local.imagePath != null && local.imagePath!.isNotEmpty) {
          final imageFile = File(local.imagePath!);
          if (await imageFile.exists()) {
            try {
              final ext = local.imagePath!.split('.').last;
              await _remote.uploadFile(
                '$remoteImageDir/${local.id}.$ext',
                imageFile,
              );
              imagesUploaded++;
              AppLogger.info('上传图片: ${local.id}.$ext');
            } catch (e) {
              AppLogger.warn('图片上传失败 (${local.id}): $e');
            }
          }
        }
      }
      AppLogger.info('图片上传完成: $imagesUploaded 张');

      return SyncReport(
        success: true,
        pushed: pushed,
        pulled: pulled,
        imagesUploaded: imagesUploaded,
        syncTime: DateTime.now(),
      );
    } catch (e, stack) {
      AppLogger.error('同步失败: $e\n$stack');
      return SyncReport(
        success: false,
        error: e.toString(),
        pushed: pushed,
        pulled: pulled,
      );
    }
  }

  /// 下载远端图片到本地，并将本地路径写回数据库
  Future<void> _downloadImageIfNeeded(Asset remote) async {
    if (remote.imagePath == null || remote.imagePath!.isEmpty) return;

    final appDir = await _getLocalImageDir();

    // 先尝试下载贴纸图（_sticker.png）
    final stickerFile = await _remote.downloadFile(
      '$remoteImageDir/${remote.id}_sticker.png',
      '$appDir/${remote.id}_sticker.png',
    );
    if (stickerFile != null && await stickerFile.exists()) {
      await _localDb.update(
        remote.copyWith(stickerImagePath: stickerFile.path),
      );
      AppLogger.info('下载贴纸图成功: ${remote.id}_sticker.png');
    }

    // 再尝试下载原图
    for (final ext in [
      'jpg',
      'jpeg',
      'png',
      'webp',
      'heic',
      'heif',
      'gif',
      'bmp',
    ]) {
      final localPath = '$appDir/${remote.id}.$ext';
      final file = await _remote.downloadFile(
        '$remoteImageDir/${remote.id}.$ext',
        localPath,
      );
      if (file != null && await file.exists()) {
        await _localDb.update(remote.copyWith(imagePath: file.path));
        AppLogger.info('下载图片成功: ${remote.id}.$ext');
        return;
      }
    }
    AppLogger.warn('图片下载失败: ${remote.id}');
  }

  Future<String> _getLocalImageDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDir.path}/images');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir.path;
  }
}
