import 'package:drift/drift.dart';

class Assets extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get category => text()();
  RealColumn get purchasePrice => real()();
  DateTimeColumn get purchaseDate => dateTime()();
  TextColumn get status => text().withDefault(const Constant('inService'))();
  IntColumn get goalDays => integer().withDefault(const Constant(1095))();
  TextColumn get notes => text().nullable()();
  TextColumn get merchant => text().nullable()();
  TextColumn get warranty => text().nullable()();
  TextColumn get imagePath => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  IntColumn get syncVersion => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}
