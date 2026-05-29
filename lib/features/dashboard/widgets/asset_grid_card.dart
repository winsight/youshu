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
    final goalDone = asset.goalAchieved;

    return GestureDetector(
      onTap: () => context.push('/asset/${asset.id}'),
      child: AssetCard(
        name: asset.name,
        originalPrice: asset.purchasePrice,
        daysUsed: asset.daysUsed,
        dailyCost: asset.dailyCost,
        progressPercent: asset.progressRatio * 100,
        remainingDays: goalDone ? null : asset.daysLeft,
        status: statusLabel,
        isActive: isActive,
        imageWidget: _buildImageWidget(),
      ),
    );
  }

  Widget _buildImageWidget() {
    final imgPath = asset.stickerImagePath ?? asset.imagePath;
    if (imgPath != null && File(imgPath).existsSync()) {
      // 白色底让 PNG 透明部分自然融入卡片
      return Container(
        color: Colors.white,
        child: Image.file(
          File(imgPath),
          fit: BoxFit.contain,
          alignment: Alignment.topLeft,
        ),
      );
    }
    return Container(
      color: Colors.white,
      child: Center(
        child: Icon(
          CategoryInfo.iconFor(asset.category),
          size: 36,
          color: Colors.grey.shade300,
        ),
      ),
    );
  }
}
