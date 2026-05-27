import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/asset.dart';
import '../data/models/asset_status.dart';
import '../data/models/asset_category.dart';
import '../data/repository/statistics_repository.dart';
import 'database_provider.dart';

// Dashboard summary
final dashboardSummaryProvider = FutureProvider<DashboardSummary>((ref) async {
  final repo = ref.watch(statisticsRepositoryProvider);
  return repo.getDashboardSummary();
});

// All assets
final assetListProvider = FutureProvider<List<Asset>>((ref) async {
  final repo = ref.watch(assetRepositoryProvider);
  return repo.getAllAssets();
});

// Single asset by id
final assetDetailProvider = FutureProvider.family<Asset?, String>((ref, id) async {
  final repo = ref.watch(assetRepositoryProvider);
  return repo.getAssetById(id);
});

// Category distribution
final categoryDistributionProvider =
    FutureProvider<List<CategoryDistribution>>((ref) async {
  final repo = ref.watch(statisticsRepositoryProvider);
  return repo.getCategoryDistribution();
});

// Filter state
class FilterState {
  final AssetCategory? category;
  final AssetStatus? status;
  final String sortBy;

  const FilterState({
    this.category,
    this.status,
    this.sortBy = 'purchaseDate',
  });

  FilterState copyWith({
    AssetCategory? category,
    AssetStatus? status,
    String? sortBy,
    bool clearCategory = false,
    bool clearStatus = false,
  }) {
    return FilterState(
      category: clearCategory ? null : (category ?? this.category),
      status: clearStatus ? null : (status ?? this.status),
      sortBy: sortBy ?? this.sortBy,
    );
  }
}

class FilterNotifier extends StateNotifier<FilterState> {
  FilterNotifier() : super(const FilterState());

  void setCategory(AssetCategory? category) {
    state = state.copyWith(category: category, clearCategory: category == null);
  }

  void setStatus(AssetStatus? status) {
    state = state.copyWith(status: status, clearStatus: status == null);
  }

  void setSortBy(String sortBy) {
    state = state.copyWith(sortBy: sortBy);
  }
}

final filterStateProvider = StateNotifierProvider<FilterNotifier, FilterState>((ref) {
  return FilterNotifier();
});

final filteredAssetsProvider = FutureProvider<List<Asset>>((ref) async {
  final filter = ref.watch(filterStateProvider);
  final repo = ref.watch(assetRepositoryProvider);
  return repo.getFilteredAssets(
    category: filter.category,
    status: filter.status,
    sortBy: filter.sortBy,
  );
});
