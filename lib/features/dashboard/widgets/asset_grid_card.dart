import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/asset.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../../shared/widgets/progress_bar.dart';

class AssetGridCard extends StatelessWidget {
  final Asset asset;

  const AssetGridCard({super.key, required this.asset});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/asset/${asset.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image area
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    color: AppColors.surfaceContainer,
                    child: _buildImage(),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: StatusBadge(status: asset.status),
                  ),
                ],
              ),
            ),
            // Info area
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      asset.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '¥${asset.purchasePrice.toStringAsFixed(0)} | Used ${asset.daysUsed} days',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '¥${asset.dailyCost.toStringAsFixed(2)}/day',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const Spacer(),
                    DailyCostProgressBar(
                      progressRatio: asset.progressRatio,
                      daysLeft: asset.daysLeft,
                      goalAchieved: asset.goalAchieved,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (asset.imagePath != null && File(asset.imagePath!).existsSync()) {
      return Image.file(
        File(asset.imagePath!),
        fit: BoxFit.cover,
        width: double.infinity,
      );
    }
    return Center(
      child: Icon(
        asset.category.icon,
        size: 48,
        color: AppColors.outlineVariant,
      ),
    );
  }
}
