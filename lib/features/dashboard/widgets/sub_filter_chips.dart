import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/l10n/app_locale.dart';
import '../../../data/models/asset_status.dart';

class SubFilterChips extends StatelessWidget {
  final AssetStatus? selectedStatus;
  final ValueChanged<AssetStatus?> onSelected;

  const SubFilterChips({
    super.key,
    required this.selectedStatus,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final statuses = <AssetStatus?>[
      null,
      AssetStatus.inService,
      AssetStatus.retired,
    ];

    return Row(
      children: [
        ...statuses.map((status) {
          final isSelected = selectedStatus == status;
          final label = status == null
              ? l10n.all
              : status == AssetStatus.inService
                  ? l10n.inService
                  : l10n.retired;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onSelected(status),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.inverseSurface
                      : AppColors.surfaceContainerHigh,
                  borderRadius:
                      BorderRadius.circular(DesignTokens.radiusFull),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? AppColors.inverseOnSurface
                        : AppColors.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          );
        }),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.sort,
              size: 20, color: AppColors.onSurfaceVariant),
          onPressed: () {},
        ),
      ],
    );
  }
}
