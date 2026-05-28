import '../models/asset.dart';

/// 抽象数据库接口 — SyncService 通过此接口操作本地数据库，
/// 不依赖具体实现（Drift / sqflite / Hive 等）。
abstract class ISyncDatabase {
  /// 获取所有资产（含软删除墓碑数据 isDeleted == true）
  Future<List<Asset>> getAllIncludingDeleted();

  /// 按 id 查找单条资产（含已删除）
  Future<Asset?> getById(String id);

  /// 插入新资产。如果 id 已存在则忽略（不覆盖）
  Future<void> insert(Asset asset);

  /// 用云端数据覆盖本地记录（合并时用到）
  Future<void> update(Asset asset);

  /// 标记为软删除，更新 updatedAt
  Future<void> softDelete(String id, DateTime deletedAt);
}
