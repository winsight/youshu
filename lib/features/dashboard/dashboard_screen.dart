import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/asset_providers.dart';
import '../../shared/widgets/states.dart';
import 'widgets/summary_card.dart';
import 'widgets/category_filter_bar.dart';
import 'widgets/sub_filter_chips.dart';
import 'widgets/asset_grid_card.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _showShadow = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      final shouldShowShadow = _scrollController.hasClients &&
          _scrollController.offset > 10;
      if (shouldShowShadow != _showShadow) {
        setState(() => _showShadow = shouldShowShadow);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(dashboardSummaryProvider);
    final filter = ref.watch(filterStateProvider);
    final assetsAsync = ref.watch(filteredAssetsProvider);

    return Scaffold(
      body: Column(
        children: [
          // Header
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              gradient: _showShadow
                  ? null
                  : RadialGradient(
                      center: Alignment.topLeft,
                      colors: [
                        AppColors.primary.withAlpha(25),
                        AppColors.background,
                      ],
                    ),
              color: _showShadow ? AppColors.surface : null,
              boxShadow: _showShadow
                  ? [
                      BoxShadow(
                        color: Colors.black.withAlpha(10),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Assets',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurface,
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.search,
                                  color: AppColors.onSurface),
                              onPressed: () {},
                            ),
                            IconButton(
                              icon: const Icon(Icons.menu,
                                  color: AppColors.onSurface),
                              onPressed: () {},
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    summaryAsync.when(
                      data: (summary) => SummaryCard(summary: summary),
                      loading: () => const SizedBox(
                        height: 130,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (e, _) => SizedBox(
                        height: 130,
                        child: Center(child: Text('$e')),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Filters
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: CategoryFilterBar(
              selectedCategory: filter.category,
              onSelected: (cat) =>
                  ref.read(filterStateProvider.notifier).setCategory(cat),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: SubFilterChips(
              selectedStatus: filter.status,
              onSelected: (status) =>
                  ref.read(filterStateProvider.notifier).setStatus(status),
            ),
          ),
          // Asset Grid
          Expanded(
            child: assetsAsync.when(
              data: (assets) {
                if (assets.isEmpty) {
                  return EmptyState(
                    icon: Icons.inventory_2_outlined,
                    title: 'No assets yet',
                    subtitle: 'Tap + to add your first asset',
                    actionLabel: 'Add Asset',
                    onAction: () => context.push('/add-asset'),
                  );
                }
                return GridView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.68,
                  ),
                  itemCount: assets.length,
                  itemBuilder: (context, index) =>
                      AssetGridCard(asset: assets[index]),
                );
              },
              loading: () => const ShimmerLoading(itemCount: 6, itemHeight: 200),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/add-asset'),
        child: const Icon(Icons.add, size: 32),
      ),
    );
  }
}
