import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/l10n/app_locale.dart';
import '../../../data/repository/statistics_repository.dart';

class SummaryCard extends StatelessWidget {
  final DashboardSummary summary;

  const SummaryCard({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        children: [
          Row(
            children: [
              Text(
                l10n.assetOverview,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurfaceVariant,
                  letterSpacing: 0.24,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
                ),
                child: Text(
                  '${summary.inServiceCount}/${summary.totalAssets}',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  label: l10n.totalValue,
                  value: _formatCurrency(summary.totalValue),
                ),
              ),
              Expanded(
                child: _StatItem(
                  label: l10n.dailyAvg,
                  value: _formatCurrency(summary.dailyAvgCost),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _StatusBreakdown(
            inService: summary.inServiceCount,
            retired: summary.retiredCount,
            sold: summary.soldCount,
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double value) {
    if (value >= 10000) {
      return '¥${(value / 10000).toStringAsFixed(2)}w';
    }
    return '¥${value.toStringAsFixed(2)}';
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurfaceVariant,
            letterSpacing: 0.24,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurface,
          ),
        ),
      ],
    );
  }
}

class _StatusBreakdown extends StatelessWidget {
  final int inService;
  final int retired;
  final int sold;

  const _StatusBreakdown({
    required this.inService,
    required this.retired,
    required this.sold,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final total = inService + retired + sold;
    if (total == 0) return const SizedBox.shrink();

    return Row(
      children: [
        _StatusItem(
          label: l10n.inService,
          count: inService,
          total: total,
          color: AppColors.primary,
        ),
        const SizedBox(width: 16),
        _StatusItem(
          label: l10n.retired,
          count: retired,
          total: total,
          color: const Color(0xFFf4a261),
        ),
        const SizedBox(width: 16),
        _StatusItem(
          label: l10n.sold,
          count: sold,
          total: total,
          color: AppColors.outline,
        ),
      ],
    );
  }
}

class _StatusItem extends StatelessWidget {
  final String label;
  final int count;
  final int total;
  final Color color;

  const _StatusItem({
    required this.label,
    required this.count,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = total > 0 ? count / total : 0.0;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label $count',
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: SizedBox(
              height: 6,
              child: LinearProgressIndicator(
                value: ratio,
                backgroundColor: AppColors.surfaceVariant,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
