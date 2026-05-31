import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repository/statistics_repository.dart';
import '../../providers/asset_providers.dart';
import '../../core/l10n/app_locale.dart';
import '../../data/models/category_model.dart';

Future<DateTimeRange?> _showPeriodPicker(BuildContext context) async {
  final l10n = AppL10n.of(context);
  final now = DateTime.now();

  final result = await showModalBottomSheet<String>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              l10n.isZh ? '选择时间范围' : 'Select Period',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.today),
            title: Text(l10n.isZh ? '本月' : 'This Month'),
            onTap: () => Navigator.pop(
              ctx,
              DateFormat('yyyy-MM-dd').format(DateTime(now.year, now.month, 1)),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.view_week),
            title: Text(l10n.isZh ? '近3个月' : 'Last 3 Months'),
            onTap: () => Navigator.pop(
              ctx,
              DateFormat(
                'yyyy-MM-dd',
              ).format(DateTime(now.year, now.month - 2, 1)),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.date_range),
            title: Text(l10n.isZh ? '近6个月' : 'Last 6 Months'),
            onTap: () => Navigator.pop(
              ctx,
              DateFormat(
                'yyyy-MM-dd',
              ).format(DateTime(now.year, now.month - 5, 1)),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.calendar_view_month),
            title: Text(l10n.isZh ? '近1年' : 'Last 1 Year'),
            onTap: () => Navigator.pop(ctx, '1year'),
          ),
          ListTile(
            leading: const Icon(Icons.all_inclusive),
            title: Text(l10n.isZh ? '全部' : 'All Time'),
            onTap: () => Navigator.pop(ctx, 'all'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.edit_calendar, color: AppColors.primary),
            title: Text(
              l10n.isZh ? '自定义范围...' : 'Custom Range...',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            onTap: () => Navigator.pop(ctx, '__custom__'),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );

  if (result == null) return null;

  if (result == '__custom__') {
    // Open date range picker calendar
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: now,
      initialDateRange: DateTimeRange(
        start: DateTime(now.year, now.month, 1),
        end: now,
      ),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(
            ctx,
          ).colorScheme.copyWith(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    return picked;
  }

  if (result == 'all') return null;

  // Parse the quick-select date and create a range
  DateTime start;
  if (result == '1year') {
    start = DateTime(now.year - 1, now.month, 1);
  } else {
    start = DateTime.parse('$result-01');
  }
  return DateTimeRange(start: start, end: now);
}

class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final distributionAsync = ref.watch(categoryDistributionProvider);
    final summaryAsync = ref.watch(dashboardSummaryProvider);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            _buildHeader(context, l10n),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildDistributionCard(context, distributionAsync),
                  const SizedBox(height: 16),
                  _buildCategoryInsights(context, distributionAsync),
                  const SizedBox(height: 16),
                  _buildLiquiditySummary(context, summaryAsync),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppL10n l10n) {
    final colors = Theme.of(context).colorScheme;
    return SliverToBoxAdapter(
      child: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topLeft,
            colors: [AppColors.primary.withAlpha(25), colors.surface],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.trends,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: colors.onSurface,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.calendar_today,
                        color: colors.primary,
                      ),
                      onPressed: () => _showPeriodPicker(context),
                    ),
                  ],
                ),
              ], // outer Row children
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDistributionCard(
    BuildContext context,
    AsyncValue<List<CategoryDistribution>> asyncDist,
  ) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
        border: Border.all(color: colors.outlineVariant.withAlpha(80)),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withAlpha(
              colors.brightness == Brightness.dark ? 70 : 10,
            ),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: asyncDist.when(
        data: (distributions) {
          if (distributions.isEmpty) {
            return const SizedBox(
              height: 200,
              child: Center(child: Text('No data')),
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppL10n.of(context).assetDistribution,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  // Donut chart
                  SizedBox(
                    width: 160,
                    height: 160,
                    child: PieChart(
                      PieChartData(
                        sections: _buildDonutSections(distributions),
                        centerSpaceRadius: 45,
                        sectionsSpace: 3,
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  // Legend
                  Expanded(
                    child: Column(
                      children: distributions.map((d) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: _getCategoryColor(d.category),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${AppL10n.of(context).getCategoryName(d.category)} (${d.percentage.toStringAsFixed(0)}%)',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: colors.onSurface,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
        loading: () => const SizedBox(
          height: 200,
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) =>
            SizedBox(height: 200, child: Center(child: Text('$e'))),
      ),
    );
  }

  List<PieChartSectionData> _buildDonutSections(
    List<CategoryDistribution> distributions,
  ) {
    final colors = [
      AppColors.primary,
      AppColors.secondary,
      AppColors.tertiaryContainer,
      AppColors.outline,
      AppColors.outlineVariant,
    ];

    return distributions.asMap().entries.map((entry) {
      final i = entry.key;
      final d = entry.value;
      return PieChartSectionData(
        value: d.percentage,
        color: colors[i % colors.length],
        radius: 35,
        title: '',
      );
    }).toList();
  }

  Color _getCategoryColor(dynamic category) {
    final cats = category.toString();
    if (cats.contains('electronics')) return AppColors.primary;
    if (cats.contains('transport')) return AppColors.secondary;
    if (cats.contains('collection')) return AppColors.tertiaryContainer;
    return AppColors.outline;
  }

  Widget _buildCategoryInsights(
    BuildContext context,
    AsyncValue<List<CategoryDistribution>> asyncDist,
  ) {
    final l10n = AppL10n.of(context);
    return asyncDist.when(
      data: (distributions) {
        if (distributions.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                l10n.isZh ? '分类洞察' : 'Category Insights',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ...distributions.map((d) => _buildInsightRow(context, d)),
          ],
        );
      },
      loading: () => const SizedBox(
        height: 80,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildInsightRow(BuildContext context, CategoryDistribution d) {
    final l10n = AppL10n.of(context);
    final colors = Theme.of(context).colorScheme;
    final catName = l10n.getCategoryName(d.category);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
        border: Border.all(color: colors.outlineVariant.withAlpha(80)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              CategoryInfo.iconFor(d.category),
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  catName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${d.count} ${l10n.isZh ? '件' : 'items'} · ${d.percentage.toStringAsFixed(0)}% ${l10n.isZh ? '占比' : 'of portfolio'}',
                  style: TextStyle(
                    fontSize: 13,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '¥${d.totalValue.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: colors.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiquiditySummary(
    BuildContext context,
    AsyncValue<DashboardSummary> asyncSummary,
  ) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
        border: Border.all(color: colors.outlineVariant.withAlpha(80)),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withAlpha(
              colors.brightness == Brightness.dark ? 70 : 10,
            ),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: asyncSummary.when(
        data: (summary) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppL10n.of(context).portfolioLiquidity,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '¥${summary.dailyAvgCost.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: colors.onSurface,
                    ),
                  ),
                  Row(
                    children: [
                      _buildMiniBar(
                        AppL10n.of(context).inService,
                        summary.inServiceCount,
                        AppColors.primary,
                      ),
                      const SizedBox(width: 16),
                      _buildMiniBar(
                        AppL10n.of(context).retired,
                        summary.retiredCount,
                        AppColors.secondary,
                      ),
                      const SizedBox(width: 16),
                      _buildMiniBar(
                        AppL10n.of(context).sold,
                        summary.soldCount,
                        AppColors.outline,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                AppL10n.of(context).averageDailyCost,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          );
        },
        loading: () => const SizedBox(
          height: 80,
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => SizedBox(height: 80, child: Center(child: Text('$e'))),
      ),
    );
  }

  Widget _buildMiniBar(String label, int count, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(4),
          ),
          alignment: Alignment.bottomCenter,
          child: Container(
            width: 14,
            height: 40 * ((count + 1) / 42).clamp(0.05, 1.0),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '$count',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 10),
        ),
      ],
    );
  }
}
