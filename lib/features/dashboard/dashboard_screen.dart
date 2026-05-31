import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/l10n/app_locale.dart';
import '../../providers/asset_providers.dart';
import '../../providers/database_provider.dart';
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
  final _searchController = TextEditingController();
  bool _showShadow = false;
  bool _showSearch = false;
  bool _selectMode = false;
  final _selectedIds = <String>{};

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      final shouldShowShadow =
          _scrollController.hasClients && _scrollController.offset > 10;
      if (shouldShowShadow != _showShadow) {
        setState(() => _showShadow = shouldShowShadow);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final summaryAsync = ref.watch(dashboardSummaryProvider);
    final filter = ref.watch(filterStateProvider);
    final assetsAsync = ref.watch(filteredAssetsProvider);
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      body: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topLeft,
                colors: [AppColors.primary.withAlpha(25), colors.surface],
              ),
              boxShadow: _showShadow
                  ? [
                      BoxShadow(
                        color: colors.shadow.withAlpha(15),
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
                        Text(
                          l10n.assets,
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
                                _showSearch ? Icons.close : Icons.search,
                                color: colors.onSurface,
                              ),
                              onPressed: () {
                                setState(() {
                                  _showSearch = !_showSearch;
                                  if (!_showSearch) {
                                    _searchController.clear();
                                    ref
                                        .read(filterStateProvider.notifier)
                                        .setSearch('');
                                  }
                                });
                              },
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
          // Search bar
          if (_showSearch)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: l10n.isZh ? '搜索资产...' : 'Search assets...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            ref
                                .read(filterStateProvider.notifier)
                                .setSearch('');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.surfaceContainerLow,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
                onChanged: (v) {
                  setState(() {});
                  ref.read(filterStateProvider.notifier).setSearch(v);
                },
              ),
            ),
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
              onSelected: (status) => ref.read(filterStateProvider.notifier).setStatus(status),
              selectMode: _selectMode,
              onToggleSelect: () => setState(() { _selectMode = !_selectMode; _selectedIds.clear(); }),
            ),
          ),
          Expanded(
            child: assetsAsync.when(
              data: (assets) {
                if (assets.isEmpty) {
                  return EmptyState(
                    icon: Icons.inventory_2_outlined,
                    title: l10n.noAssets,
                    subtitle: l10n.addFirstAsset,
                    actionLabel: l10n.addAsset,
                    onAction: () => context.push('/add-asset'),
                  );
                }
                return GridView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.72,
                  ),
                  itemCount: assets.length,
                  itemBuilder: (context, index) {
                    final a = assets[index];
                    return GestureDetector(
                      onLongPress: () {
                        if (!_selectMode) {
                          setState(() => _selectMode = true);
                          _selectedIds.add(a.id);
                        }
                      },
                      onTap: _selectMode
                          ? () => setState(() => _selectedIds.contains(a.id) ? _selectedIds.remove(a.id) : _selectedIds.add(a.id))
                          : () => context.push('/asset/${a.id}'),
                      child: Stack(
                        children: [
                          AssetGridCard(asset: a),
                          if (_selectMode)
                            Positioned(
                              top: 4, right: 4,
                              child: Container(
                                width: 24, height: 24,
                                decoration: BoxDecoration(
                                  color: _selectedIds.contains(a.id) ? AppColors.primary : Colors.white70,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: _selectedIds.contains(a.id) ? AppColors.primary : Colors.grey, width: 2),
                                ),
                                child: _selectedIds.contains(a.id) ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
              loading: () =>
                  const ShimmerLoading(itemCount: 6, itemHeight: 200),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
      floatingActionButton: _selectMode
          ? null
          : FloatingActionButton(
              onPressed: () => context.push('/add-asset'),
              child: const Icon(Icons.add, size: 32),
            ),
      bottomSheet: _selectMode && _selectedIds.isNotEmpty
          ? Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              decoration: BoxDecoration(
                color: colors.surface,
                border: const Border(top: BorderSide(color: AppColors.outlineVariant)),
              ),
              child: Row(
                children: [
                  Text('${l10n.isZh ? '已选择' : 'Selected'} ${_selectedIds.length} ${l10n.isZh ? '项' : 'items'}'),
                  const Spacer(),
                  TextButton(
                    onPressed: () => setState(() { _selectMode = false; _selectedIds.clear(); }),
                    child: Text(l10n.cancel),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: Text(l10n.deleteAsset),
                          content: Text('${l10n.isZh ? '确定删除' : 'Delete'} ${_selectedIds.length} ${l10n.isZh ? '项资产？' : 'assets?'}'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
                            TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.delete, style: const TextStyle(color: AppColors.error))),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        for (final id in _selectedIds) {
                          await ref.read(assetRepositoryProvider).deleteAsset(id);
                        }
                        ref.invalidate(assetListProvider);
                        ref.invalidate(filteredAssetsProvider);
                        ref.invalidate(dashboardSummaryProvider);
                        setState(() { _selectMode = false; _selectedIds.clear(); });
                      }
                    },
                    icon: const Icon(Icons.delete, size: 18, color: Colors.white),
                    label: Text(l10n.delete, style: const TextStyle(color: Colors.white)),
                    style: FilledButton.styleFrom(backgroundColor: AppColors.error),
                  ),
                ],
              ),
            )
          : null,
    );
  }
}
