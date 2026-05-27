import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
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
    final assetAsync = ref.watch(assetDetailProvider(assetId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Asset Details'),
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
                    title: const Text('Delete Asset'),
                    content: const Text('This action cannot be undone.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child:
                            const Text('Delete', style: TextStyle(color: AppColors.error)),
                      ),
                    ],
                  ),
                );
                if (confirm == true && context.mounted) {
                  await ref
                      .read(assetRepositoryProvider)
                      .deleteAsset(assetId);
                  if (context.mounted) context.pop();
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'edit', child: Text('Edit')),
              const PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ],
      ),
      body: assetAsync.when(
        data: (asset) {
          if (asset == null) {
            return const Center(child: Text('Asset not found'));
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
          _buildHeroSection(),
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

  Widget _buildHeroSection() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primary.withAlpha(30),
            AppColors.background,
          ],
        ),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(40),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            height: 280,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
              color: AppColors.surfaceContainer,
            ),
            clipBehavior: Clip.antiAlias,
            child: _buildImage(),
          ),
          const SizedBox(height: 16),
          Text(
            asset.name,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildCostItem('Original Cost', '¥${asset.purchasePrice.toStringAsFixed(0)}'),
              Container(
                width: 1,
                height: 24,
                color: AppColors.outlineVariant,
                margin: const EdgeInsets.symmetric(horizontal: 16),
              ),
              _buildCostItem('Daily Cost', '¥${asset.dailyCost.toStringAsFixed(2)}/day'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImage() {
    if (asset.imagePath != null && File(asset.imagePath!).existsSync()) {
      return Image.file(
        File(asset.imagePath!),
        fit: BoxFit.contain,
      );
    }
    return Center(
      child: Icon(
        asset.category.icon,
        size: 80,
        color: AppColors.outlineVariant,
      ),
    );
  }

  Widget _buildCostItem(String label, String value) {
    return Column(
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.onSurfaceVariant,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurface,
          ),
        ),
      ],
    );
  }
}
