import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/asset.dart';

class PurchaseSpecsList extends StatelessWidget {
  final Asset asset;

  const PurchaseSpecsList({super.key, required this.asset});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
        border: Border.all(color: AppColors.outlineVariant.withAlpha(80)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'PURCHASE SPECS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurfaceVariant,
                      letterSpacing: 0.24,
                    ),
                  ),
                ),
                Icon(Icons.info_outline, size: 16, color: AppColors.onSurfaceVariant),
              ],
            ),
          ),
          if (asset.merchant != null)
            _buildSpecRow('Merchant', asset.merchant!),
          if (asset.warranty != null)
            _buildSpecRow('Warranty', asset.warranty!),
          _buildSpecRow('Category', asset.category.displayName),
          _buildSpecRow('Days Used', '${asset.daysUsed} days'),
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
