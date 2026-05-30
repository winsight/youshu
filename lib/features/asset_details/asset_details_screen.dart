import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/l10n/app_locale.dart';
import '../../data/models/category_model.dart';
import '../../providers/asset_providers.dart';
import '../../providers/database_provider.dart';
import 'widgets/service_life_progress.dart';
import 'widgets/bento_stats_grid.dart';
import 'widgets/purchase_specs_list.dart';

class AssetDetailsScreen extends ConsumerWidget {
  final String assetId;

  const AssetDetailsScreen({super.key, required this.assetId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final assetAsync = ref.watch(assetDetailProvider(assetId));

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(l10n.assetDetails),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (v) async {
              if (v == 'edit') {
                context.push('/asset/$assetId/edit');
              } else if (v == 'delete') {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(l10n.deleteAsset),
                    content: Text(l10n.deleteConfirm),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text(l10n.cancel),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text(
                          l10n.delete,
                          style: const TextStyle(color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
                );
                if (confirm == true && context.mounted) {
                  await ref.read(assetRepositoryProvider).deleteAsset(assetId);
                  // 刷新所有相关 provider，确保 UI 立即反映删除
                  ref.invalidate(assetListProvider);
                  ref.invalidate(filteredAssetsProvider);
                  ref.invalidate(dashboardSummaryProvider);
                  ref.invalidate(categoryDistributionProvider);
                  ref.invalidate(assetDetailProvider(assetId));
                  if (context.mounted) context.pop();
                }
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'edit', child: Text(l10n.edit)),
              PopupMenuItem(value: 'delete', child: Text(l10n.delete)),
            ],
          ),
        ],
      ),
      body: assetAsync.when(
        data: (asset) {
          if (asset == null) {
            return Center(child: Text(l10n.assetNotFound));
          }
          return _AssetDetailContent(asset: asset);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _AssetDetailContent extends StatelessWidget {
  final dynamic asset;

  const _AssetDetailContent({required this.asset});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildHeroSection(context),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: ServiceLifeProgress(asset: asset),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: BentoStatsGrid(asset: asset),
          ),
          if (asset.merchant != null || asset.warranty != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: PurchaseSpecsList(asset: asset),
            ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context) {
    final l10n = AppL10n.of(context);
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.primary.withAlpha(30), colors.surface],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(40)),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            height: 280,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: colors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(28),
            ),
            clipBehavior: Clip.antiAlias,
            child: Center(child: _buildImage()),
          ),
          const SizedBox(height: 16),
          Text(
            asset.name,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildCostItem(
                l10n.originalCost,
                '¥${asset.purchasePrice.toStringAsFixed(0)}',
              ),
              Container(
                width: 1,
                height: 24,
                color: AppColors.outlineVariant,
                margin: const EdgeInsets.symmetric(horizontal: 16),
              ),
              _buildCostItem(
                l10n.dailyCost,
                '¥${asset.dailyCost.toStringAsFixed(2)}/${l10n.isZh ? '天' : 'day'}',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImage() {
    final imageFile = _existingImageFile();
    if (imageFile != null) {
      return Padding(
        padding: const EdgeInsets.all(18),
        child: Image.file(
          imageFile,
          fit: BoxFit.contain,
          alignment: Alignment.center,
          width: double.infinity,
          height: double.infinity,
        ),
      );
    }
    return Center(
      child: Icon(
        CategoryInfo.iconFor(asset.category),
        size: 80,
        color: AppColors.outlineVariant,
      ),
    );
  }

  File? _existingImageFile() {
    for (final path in [asset.stickerImagePath, asset.imagePath]) {
      if (path == null || path.isEmpty) continue;
      final file = File(path);
      if (file.existsSync()) return file;
    }
    return null;
  }

  Widget _buildCostItem(String label, String value) {
    return Builder(
      builder: (context) {
        final colors = Theme.of(context).colorScheme;
        return Column(
          children: [
            Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: colors.onSurfaceVariant,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: colors.onSurface,
              ),
            ),
          ],
        );
      },
    );
  }
}
