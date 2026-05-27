import 'package:drift/drift.dart';

class SyncMeta extends Table {
  TextColumn get assetId => text()();
  IntColumn get localVersion => integer().withDefault(const Constant(0))();
  IntColumn get remoteVersion => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastSyncedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {assetId};
}
