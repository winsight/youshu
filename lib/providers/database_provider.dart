import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/database/app_database.dart';
import '../data/repository/asset_repository.dart';
import '../data/repository/statistics_repository.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

final assetRepositoryProvider = Provider<AssetRepository>((ref) {
  return AssetRepository(ref.watch(databaseProvider));
});

final statisticsRepositoryProvider = Provider<StatisticsRepository>((ref) {
  return StatisticsRepository(ref.watch(assetRepositoryProvider));
});
