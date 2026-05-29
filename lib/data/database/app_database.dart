import 'package:drift/drift.dart';
import 'package:drift_sqflite/drift_sqflite.dart';
import 'tables/assets_table.dart';
import 'tables/wishlist_table.dart';
import 'tables/sync_meta_table.dart';
import 'tables/categories_table.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [Assets, WishlistItems, SyncMeta, Categories],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(categories);
            await _seedCategories();
          }
          if (from < 3) {
            await m.addColumn(assets, assets.isDeleted);
          }
          if (from < 4) {
            await m.addColumn(assets, assets.stickerImagePath);
          }
        },
        beforeOpen: (details) async {
          final count = await (select(categories)..limit(1)).get();
          if (count.isEmpty) {
            await _seedCategories();
          }
        },
      );

  Future<void> _seedCategories() async {
    await customStatement(
      'INSERT OR IGNORE INTO categories (name, name_zh, icon_name, sort_order) VALUES '
      "('electronics', '数码', 'devices', 0),"
      "('transport', '交通', 'directions_car', 1),"
      "('collection', '收藏', 'palette', 2),"
      "('tools', '工具', 'build', 3),"
      "('other', '其他', 'category', 4)",
    );
  }

  static QueryExecutor _openConnection() {
    return LazyDatabase(() async {
      return SqfliteQueryExecutor.inDatabaseFolder(path: 'asset_sum.db');
    });
  }
}
