import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/database/app_database.dart';
import '../data/repository/asset_repository.dart';
import '../data/repository/statistics_repository.dart';
import '../data/repository/category_repository.dart';
import '../data/models/category_model.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

final assetRepositoryProvider = Provider<AssetRepository>((ref) {
  return AssetRepository(ref.watch(databaseProvider));
});

final statisticsRepositoryProvider = Provider<StatisticsRepository>((ref) {
  return StatisticsRepository(ref.watch(assetRepositoryProvider));
});

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository(ref.watch(databaseProvider));
});

final categoriesProvider = FutureProvider<List<CategoryInfo>>((ref) async {
  return ref.watch(categoryRepositoryProvider).getAll();
});
