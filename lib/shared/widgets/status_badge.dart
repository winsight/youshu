import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/l10n/app_locale.dart';
import '../../data/models/asset_status.dart';

class StatusBadge extends StatelessWidget {
  final AssetStatus status;
  final bool showDot;

  const StatusBadge({super.key, required this.status, this.showDot = true});

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(20),
        borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (showDot) ...[
          Container(width: 6, height: 6,
            decoration: BoxDecoration(color: _dotColor, shape: BoxShape.circle)),
          const SizedBox(width: 4),
        ],
        Text(_statusLabel(l10n),
          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.onPrimaryContainer)),
      ]),
    );
  }

  String _statusLabel(AppL10n l10n) => switch (status) {
    AssetStatus.inService => l10n.inService,
    AssetStatus.retired => l10n.retired,
    AssetStatus.sold => l10n.sold,
  };

  Color get _dotColor => switch (status) {
    AssetStatus.inService => AppColors.primary,
    AssetStatus.retired => const Color(0xFFf4a261),
    AssetStatus.sold => AppColors.outline,
  };
}
