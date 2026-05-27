import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';
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
      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File(p.join(dbFolder.path, 'asset_sum.db'));
      return NativeDatabase.createInBackground(file);
    });
  }
}
