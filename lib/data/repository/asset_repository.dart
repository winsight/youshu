import 'package:drift/drift.dart' show Value;
import '../database/app_database.dart' as db;
import '../models/asset_status.dart';
import '../models/asset.dart' as model;
import 'sync_db_interface.dart';

class AssetRepository implements ISyncDatabase {
  final db.AppDatabase _db;

  AssetRepository(this._db);

  // ========== ISyncDatabase 实现 ==========

  @override
  Future<List<model.Asset>> getAllIncludingDeleted() async {
    final rows = await _db.select(_db.assets).get();
    return rows.map<model.Asset>((row) => _toModel(row)).toList();
  }

  @override
  Future<model.Asset?> getById(String id) async {
    final query = _db.select(_db.assets)
      ..where((t) => t.id.equals(id))
      ..limit(1);
    final rows = await query.get();
    if (rows.isEmpty) return null;
    return _toModel(rows.first);
  }

  Future<void> _ensureCategory(String name) async {
    final exists = await (_db.select(_db.categories)
          ..where((t) => t.name.equals(name))
          ..limit(1))
        .get();
    if (exists.isEmpty) {
      await _db.into(_db.categories).insertOnConflictUpdate(
            db.CategoriesCompanion(
              name: Value(name),
              nameZh: Value(name),
              iconName: const Value('category'),
              sortOrder: const Value(99),
            ),
          );
    }
  }

  @override
  Future<void> insert(model.Asset asset) async {
    await _ensureCategory(asset.category);
    await _db.into(_db.assets).insert(
          db.AssetsCompanion(
            id: Value(asset.id),
            name: Value(asset.name),
            category: Value(asset.category),
            purchasePrice: Value(asset.purchasePrice),
            purchaseDate: Value(asset.purchaseDate),
            status: Value(asset.status.name),
            goalDays: Value(asset.goalDays),
            notes: Value(asset.notes),
            merchant: Value(asset.merchant),
            warranty: Value(asset.warranty),
            imagePath: Value(asset.imagePath),
            stickerImagePath: Value(asset.stickerImagePath),
            createdAt: Value(asset.createdAt),
            updatedAt: Value(asset.updatedAt),
            isDeleted: Value(asset.isDeleted),
            syncVersion: Value(asset.syncVersion),
          ),
          // 使用 insertOnConflictUpdate 但保持原值不变（等同于 insertOrIgnore）
        );
  }

  @override
  Future<void> update(model.Asset asset) async {
    await _ensureCategory(asset.category);
    await (_db.update(_db.assets)..where((t) => t.id.equals(asset.id))).write(
          db.AssetsCompanion(
            name: Value(asset.name),
            category: Value(asset.category),
            purchasePrice: Value(asset.purchasePrice),
            purchaseDate: Value(asset.purchaseDate),
            status: Value(asset.status.name),
            goalDays: Value(asset.goalDays),
            notes: Value(asset.notes),
            merchant: Value(asset.merchant),
            warranty: Value(asset.warranty),
            imagePath: Value(asset.imagePath),
            stickerImagePath: Value(asset.stickerImagePath),
            updatedAt: Value(asset.updatedAt),
            isDeleted: Value(asset.isDeleted),
            syncVersion: Value(asset.syncVersion),
          ),
        );
  }

  @override
  Future<void> softDelete(String id, DateTime deletedAt) async {
    await (_db.update(_db.assets)..where((t) => t.id.equals(id))).write(
          db.AssetsCompanion(
            isDeleted: const Value(true),
            updatedAt: Value(deletedAt),
          ),
        );
  }

  // ========== 业务查询（仅返回未删除的记录） ==========

  Future<List<model.Asset>> getAllAssets({String? sortBy}) async {
    final rows = await (_db.select(_db.assets)
          ..where((t) => t.isDeleted.equals(false)))
        .get();
    final assets = rows.map<model.Asset>((row) => _toModel(row)).toList();
    _sortAssets(assets, sortBy ?? 'purchaseDate');
    return assets;
  }

  Future<List<model.Asset>> getFilteredAssets({
    String? category,
    AssetStatus? status,
    String? sortBy,
  }) async {
    var query = _db.select(_db.assets)
      ..where((t) => t.isDeleted.equals(false));
    if (category != null) {
      query = query..where((t) => t.category.equals(category));
    }
    if (status != null) {
      query = query..where((t) => t.status.equals(status.name));
    }
    final rows = await query.get();
    final assets = rows.map<model.Asset>((row) => _toModel(row)).toList();
    _sortAssets(assets, sortBy ?? 'purchaseDate');
    return assets;
  }

  Future<model.Asset?> getAssetById(String id) async {
    final query = _db.select(_db.assets)
      ..where((t) => t.id.equals(id))
      ..where((t) => t.isDeleted.equals(false))
      ..limit(1);
    final rows = await query.get();
    if (rows.isEmpty) return null;
    return _toModel(rows.first);
  }

  Future<String> upsertAsset(model.Asset asset) async {
    final now = DateTime.now().toUtc();
    final existing = await getById(asset.id);

    await _db.into(_db.assets).insertOnConflictUpdate(
          db.AssetsCompanion(
            id: Value(asset.id),
            name: Value(asset.name),
            category: Value(asset.category),
            purchasePrice: Value(asset.purchasePrice),
            purchaseDate: Value(asset.purchaseDate),
            status: Value(asset.status.name),
            goalDays: Value(asset.goalDays),
            notes: Value(asset.notes),
            merchant: Value(asset.merchant),
            warranty: Value(asset.warranty),
            imagePath: Value(asset.imagePath),
            stickerImagePath: Value(asset.stickerImagePath),
            createdAt: Value(existing?.createdAt ?? now),
            updatedAt: Value(now),
            isDeleted: Value(asset.isDeleted),
            syncVersion: Value(asset.syncVersion + 1),
          ),
        );
    return asset.id;
  }

  /// 从同步拉取的数据插入，不增加 syncVersion（避免回环同步）
  Future<String> upsertFromSync(model.Asset asset) async {
    final now = DateTime.now().toUtc();
    final existing = await getById(asset.id);

    await _db.into(_db.assets).insertOnConflictUpdate(
          db.AssetsCompanion(
            id: Value(asset.id),
            name: Value(asset.name),
            category: Value(asset.category),
            purchasePrice: Value(asset.purchasePrice),
            purchaseDate: Value(asset.purchaseDate),
            status: Value(asset.status.name),
            goalDays: Value(asset.goalDays),
            notes: Value(asset.notes),
            merchant: Value(asset.merchant),
            warranty: Value(asset.warranty),
            imagePath: Value(asset.imagePath),
            stickerImagePath: Value(asset.stickerImagePath),
            createdAt: Value(existing?.createdAt ?? now),
            updatedAt: Value(now),
            isDeleted: Value(asset.isDeleted),
            syncVersion: Value(asset.syncVersion),
          ),
        );
    return asset.id;
  }

  Future<void> updateStatus(String id, AssetStatus status) async {
    await (_db.update(_db.assets)..where((t) => t.id.equals(id))).write(
          db.AssetsCompanion(
            status: Value(status.name),
            updatedAt: Value(DateTime.now().toUtc()),
          ),
        );
  }

  /// 业务层删除（标记 isDeleted = true，不物理删除）
  Future<void> deleteAsset(String id) async {
    await softDelete(id, DateTime.now().toUtc());
  }

  Future<int> getAssetCountByStatus(AssetStatus status) async {
    final count = await (_db.select(_db.assets)
          ..where((t) => t.status.equals(status.name))
          ..where((t) => t.isDeleted.equals(false)))
        .get();
    return count.length;
  }

  Future<double> getTotalValue() async {
    final rows = await (_db.select(_db.assets)
          ..where((t) => t.isDeleted.equals(false)))
        .get();
    double sum = 0;
    for (final row in rows) {
      sum += row.purchasePrice;
    }
    return sum;
  }

  Future<Map<String, double>> getValueByCategory() async {
    final rows = await (_db.select(_db.assets)
          ..where((t) => t.isDeleted.equals(false)))
        .get();
    final map = <String, double>{};
    for (final row in rows) {
      map[row.category] = (map[row.category] ?? 0) + row.purchasePrice;
    }
    return map;
  }

  // ========== 内部方法 ==========

  model.Asset _toModel(db.Asset row) {
    return model.Asset(
      id: row.id,
      name: row.name,
      category: row.category,
      purchasePrice: row.purchasePrice,
      purchaseDate: row.purchaseDate,
      status: AssetStatus.values.firstWhere(
        (e) => e.name == row.status,
        orElse: () => AssetStatus.inService,
      ),
      goalDays: row.goalDays,
      imagePath: row.imagePath,
      stickerImagePath: row.stickerImagePath,
      notes: row.notes,
      merchant: row.merchant,
      warranty: row.warranty,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      isDeleted: row.isDeleted,
      syncVersion: row.syncVersion,
    );
  }

  void _sortAssets(List<model.Asset> assets, String sortBy) {
    switch (sortBy) {
      case 'dailyCost':
        assets.sort((a, b) => b.dailyCost.compareTo(a.dailyCost));
        break;
      case 'name':
        assets.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'purchaseDate':
      default:
        assets.sort((a, b) => b.purchaseDate.compareTo(a.purchaseDate));
        break;
    }
  }
}
