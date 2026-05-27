import 'package:drift/drift.dart' show Value;
import '../database/app_database.dart' as db;
import '../models/asset_status.dart';
import '../models/asset_category.dart';
import '../models/asset.dart' as model;

class AssetRepository {
  final db.AppDatabase _db;

  AssetRepository(this._db);

  Future<List<model.Asset>> getAllAssets({String? sortBy}) async {
    final rows = await _db.select(_db.assets).get();
    final assets = rows.map<model.Asset>((row) => _toModel(row)).toList();
    _sortAssets(assets, sortBy ?? 'purchaseDate');
    return assets;
  }

  Future<List<model.Asset>> getFilteredAssets({
    AssetCategory? category,
    AssetStatus? status,
    String? sortBy,
  }) async {
    var query = _db.select(_db.assets);
    if (category != null) {
      query = query..where((t) => t.category.equals(category.name));
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
      ..limit(1);
    final rows = await query.get();
    if (rows.isEmpty) return null;
    return _toModel(rows.first);
  }

  Future<String> upsertAsset(model.Asset asset) async {
    final now = DateTime.now();
    final existing = await getAssetById(asset.id);

    await _db.into(_db.assets).insertOnConflictUpdate(
      db.AssetsCompanion(
        id: Value(asset.id),
        name: Value(asset.name),
        category: Value(asset.category.name),
        purchasePrice: Value(asset.purchasePrice),
        purchaseDate: Value(asset.purchaseDate),
        status: Value(asset.status.name),
        goalDays: Value(asset.goalDays),
        notes: Value(asset.notes),
        merchant: Value(asset.merchant),
        warranty: Value(asset.warranty),
        imagePath: Value(asset.imagePath),
        createdAt: Value(existing?.createdAt ?? now),
        updatedAt: Value(now),
        syncVersion: Value(asset.syncVersion + 1),
      ),
    );
    return asset.id;
  }

  Future<void> updateStatus(String id, AssetStatus status) async {
    await (_db.update(_db.assets)..where((t) => t.id.equals(id))).write(
      db.AssetsCompanion(
        status: Value(status.name),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> deleteAsset(String id) async {
    await (_db.delete(_db.assets)..where((t) => t.id.equals(id))).go();
  }

  Future<int> getAssetCountByStatus(AssetStatus status) async {
    final count = await (_db.select(_db.assets)
          ..where((t) => t.status.equals(status.name)))
        .get();
    return count.length;
  }

  Future<double> getTotalValue() async {
    final rows = await _db.select(_db.assets).get();
    double sum = 0;
    for (final row in rows) {
      sum += row.purchasePrice;
    }
    return sum;
  }

  Future<Map<AssetCategory, double>> getValueByCategory() async {
    final rows = await _db.select(_db.assets).get();
    final map = <AssetCategory, double>{};
    for (final row in rows) {
      final cat = AssetCategory.values.firstWhere(
        (e) => e.name == row.category,
        orElse: () => AssetCategory.other,
      );
      map[cat] = (map[cat] ?? 0) + row.purchasePrice;
    }
    return map;
  }

  model.Asset _toModel(db.Asset row) {
    return model.Asset(
      id: row.id,
      name: row.name,
      category: AssetCategory.values.firstWhere(
        (e) => e.name == row.category,
        orElse: () => AssetCategory.other,
      ),
      purchasePrice: row.purchasePrice,
      purchaseDate: row.purchaseDate,
      status: AssetStatus.values.firstWhere(
        (e) => e.name == row.status,
        orElse: () => AssetStatus.inService,
      ),
      goalDays: row.goalDays,
      imagePath: row.imagePath,
      notes: row.notes,
      merchant: row.merchant,
      warranty: row.warranty,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
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
