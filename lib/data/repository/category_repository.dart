import 'package:drift/drift.dart' show Value;
import '../database/app_database.dart';
import '../models/category_model.dart';

class CategoryRepository {
  final AppDatabase _db;

  CategoryRepository(this._db);

  Future<List<CategoryInfo>> getAll() async {
    final rows = await _db.select(_db.categories).get();
    return rows
        .map((r) => CategoryInfo(
              name: r.name,
              nameZh: r.nameZh,
              iconName: r.iconName,
              sortOrder: r.sortOrder,
            ))
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  Future<void> add(CategoryInfo info) async {
    await _db.into(_db.categories).insertOnConflictUpdate(
          CategoriesCompanion(
            name: Value(info.name),
            nameZh: Value(info.nameZh),
            iconName: Value(info.iconName),
            sortOrder: Value(info.sortOrder),
          ),
        );
  }

  Future<void> delete(String name) async {
    await (_db.delete(_db.categories)..where((t) => t.name.equals(name)))
        .go();
  }
}
