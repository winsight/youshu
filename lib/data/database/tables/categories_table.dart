import 'package:drift/drift.dart';

class Categories extends Table {
  TextColumn get name => text()();
  TextColumn get nameZh => text()();
  TextColumn get iconName => text().withDefault(const Constant('category'))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {name};
}
