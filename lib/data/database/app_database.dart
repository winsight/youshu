import 'package:drift/drift.dart';
import 'package:drift_sqflite/drift_sqflite.dart';
import 'tables/assets_table.dart';
import 'tables/wishlist_table.dart';
import 'tables/sync_meta_table.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [Assets, WishlistItems, SyncMeta],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return LazyDatabase(() async {
      return SqfliteQueryExecutor.inDatabaseFolder(path: 'asset_sum.db');
    });
  }
}
