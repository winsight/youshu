import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/l10n/app_locale.dart';
import '../../../data/models/asset.dart';

class PurchaseSpecsList extends StatelessWidget {
  final Asset asset;

  const PurchaseSpecsList({super.key, required this.asset});

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
        border: Border.all(color: AppColors.outlineVariant.withAlpha(80)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.purchaseSpecs.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurfaceVariant,
                      letterSpacing: 0.24,
                    ),
                  ),
                ),
                const Icon(Icons.info_outline,
                    size: 16, color: AppColors.onSurfaceVariant),
              ],
            ),
          ),
          if (asset.merchant != null)
            _buildSpecRow(l10n.merchant, asset.merchant!),
          if (asset.warranty != null)
            _buildSpecRow(l10n.warranty, asset.warranty!),
          _buildSpecRow(l10n.category, l10n.getCategoryName(asset.category)),
          _buildSpecRow(l10n.daysUsed, '${asset.daysUsed} ${l10n.isZh ? '天' : 'days'}'),
        ],
      ),
    );
  }

  Widget _buildSpecRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
