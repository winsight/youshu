import 'package:drift/drift.dart';

class WishlistItems extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get category => text()();
  RealColumn get estimatedPrice => real()();
  TextColumn get notes => text().nullable()();
  TextColumn get imagePath => text().nullable()();
  IntColumn get priority => integer().withDefault(const Constant(2))();
  BoolColumn get isAchieved => boolean().withDefault(const Constant(false))();
  TextColumn get url => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
