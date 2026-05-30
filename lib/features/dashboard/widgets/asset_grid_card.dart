import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/asset.dart';
import '../../../data/models/asset_status.dart';
import '../../../data/models/category_model.dart';
import '../../../shared/widgets/asset_card.dart';

class AssetGridCard extends StatelessWidget {
  final Asset asset;
  const AssetGridCard({super.key, required this.asset});

  @override
  Widget build(BuildContext context) {
    final isActive = asset.status == AssetStatus.inService;
    final statusLabel = switch (asset.status) {
      AssetStatus.inService => '服役中',
      AssetStatus.retired => '已退役',
      AssetStatus.sold => '已出售',
    };
    return GestureDetector(
      onTap: () => context.push('/asset/${asset.id}'),
      child: AssetCard(
        name: asset.name,
        originalPrice: asset.purchasePrice,
        daysUsed: asset.daysUsed,
        dailyCost: asset.dailyCost,
        progressPercent: asset.hasGoal ? asset.progressRatio * 100 : 0,
        remainingDays: asset.hasGoal ? asset.daysLeft : null,
        hasGoal: asset.hasGoal,
        status: statusLabel,
        isActive: isActive,
        imageWidget: _buildImageWidget(),
      ),
    );
  }

  Widget _buildImageWidget() {
    final imageFile = _existingImageFile();
    if (imageFile != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          imageFile,
          fit: BoxFit.contain,
          alignment: Alignment.topLeft,
        ),
      );
    }
    return Center(
      child: Icon(
        CategoryInfo.iconFor(asset.category),
        size: 36,
        color: Colors.grey,
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
}
