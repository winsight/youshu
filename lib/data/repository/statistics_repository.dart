import '../models/asset.dart';
import '../models/asset_status.dart';
import 'asset_repository.dart';

class DashboardSummary {
  final double totalValue;
  final double dailyAvgCost;
  final int totalAssets;
  final int inServiceCount;
  final int retiredCount;
  final int soldCount;

  DashboardSummary({
    required this.totalValue,
    required this.dailyAvgCost,
    required this.totalAssets,
    required this.inServiceCount,
    required this.retiredCount,
    required this.soldCount,
  });
}

class CategoryDistribution {
  final String category;
  final int count;
  final double totalValue;
  final double percentage;

  CategoryDistribution({
    required this.category,
    required this.count,
    required this.totalValue,
    required this.percentage,
  });
}

class StatisticsRepository {
  final AssetRepository _assetRepo;

  StatisticsRepository(this._assetRepo);

  Future<DashboardSummary> getDashboardSummary() async {
    final assets = await _assetRepo.getAllAssets();
    final totalValue = assets.fold<double>(0, (sum, a) => sum + a.purchasePrice);
    final inService =
        assets.where((a) => a.status == AssetStatus.inService).toList();
    final retired =
        assets.where((a) => a.status == AssetStatus.retired).toList();
    final sold =
        assets.where((a) => a.status == AssetStatus.sold).toList();

    final totalDailyCost =
        assets.fold<double>(0, (sum, a) => sum + a.dailyCost);

    return DashboardSummary(
      totalValue: totalValue,
      dailyAvgCost: totalDailyCost,
      totalAssets: assets.length,
      inServiceCount: inService.length,
      retiredCount: retired.length,
      soldCount: sold.length,
    );
  }

  Future<List<CategoryDistribution>> getCategoryDistribution() async {
    final assets = await _assetRepo.getAllAssets();
    final totalValue =
        assets.fold<double>(0, (sum, a) => sum + a.purchasePrice);
    final map = <String, List<Asset>>{};

    for (final a in assets) {
      map.putIfAbsent(a.category, () => []).add(a);
    }

    return map.entries.map((entry) {
      final value =
          entry.value.fold<double>(0, (sum, a) => sum + a.purchasePrice);
      return CategoryDistribution(
        category: entry.key,
        count: entry.value.length,
        totalValue: value,
        percentage: totalValue > 0 ? (value / totalValue) * 100.0 : 0,
      );
    }).toList()
      ..sort((a, b) => b.totalValue.compareTo(a.totalValue));
  }

  Future<double> getTotalDailyCost() async {
    final assets = await _assetRepo.getAllAssets();
    if (assets.isEmpty) return 0;
    return assets.fold<double>(0, (sum, a) => sum + a.dailyCost);
  }

  Future<double> getAverageDailyCost() async {
    final assets = await _assetRepo.getAllAssets();
    if (assets.isEmpty) return 0;
    return assets.fold<double>(0, (sum, a) => sum + a.dailyCost) /
        assets.length;
  }
}
