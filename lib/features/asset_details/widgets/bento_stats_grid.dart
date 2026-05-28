import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/l10n/app_locale.dart';
import '../../../data/models/asset.dart';

class BentoStatsGrid extends StatelessWidget {
  final Asset asset;

  const BentoStatsGrid({super.key, required this.asset});

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    return Row(
      children: [
        Expanded(
          child: _BentoStat(
            icon: Icons.trending_down,
            label: l10n.estDepreciation,
            value: '¥${asset.depreciation.toStringAsFixed(0)}',
            valueColor: AppColors.error,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _BentoStat(
            icon: Icons.payments,
            label: l10n.resaleValue,
            value: '¥${asset.resaleValue.toStringAsFixed(0)}',
            valueColor: AppColors.primary,
          ),
        ),
      ],
    );
  }
}

class _BentoStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color valueColor;

  const _BentoStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
        border: Border.all(color: AppColors.outlineVariant.withAlpha(80)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: AppColors.primary),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
