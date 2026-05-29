import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/l10n/app_locale.dart';
import '../../../data/models/asset_status.dart';
import '../../../providers/asset_providers.dart';

class SubFilterChips extends ConsumerWidget {
  final AssetStatus? selectedStatus;
  final ValueChanged<AssetStatus?> onSelected;
  final bool selectMode;
  final VoidCallback onToggleSelect;

  const SubFilterChips({
    super.key,
    required this.selectedStatus,
    required this.onSelected,
    this.selectMode = false,
    required this.onToggleSelect,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final colors = Theme.of(context).colorScheme;
    final notifier = ref.read(filterStateProvider.notifier);
    final state = ref.watch(filterStateProvider);

    return Row(
      children: [
        ...<AssetStatus?>[null, AssetStatus.inService, AssetStatus.retired].map((status) {
          final isSelected = selectedStatus == status;
          final label = status == null ? l10n.all : (status == AssetStatus.inService ? l10n.inService : l10n.retired);
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onSelected(status),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: isSelected ? colors.inverseSurface : colors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
                ),
                child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                    color: isSelected ? colors.onInverseSurface : colors.onSurfaceVariant)),
              ),
            ),
          );
        }),
        const Spacer(),
        // 多选按钮
        IconButton(
          icon: Icon(selectMode ? Icons.checklist : Icons.checklist_outlined, size: 20,
            color: selectMode ? AppColors.primary : colors.onSurfaceVariant),
          onPressed: onToggleSelect,
          tooltip: l10n.isZh ? '多选' : 'Select',
        ),
        // 排序按钮
        PopupMenuButton<String>(
          icon: Icon(Icons.sort, size: 20, color: colors.onSurfaceVariant),
          tooltip: l10n.isZh ? '排序' : 'Sort',
          onSelected: (v) => notifier.setSortBy(v),
          itemBuilder: (_) => FilterNotifier.sortOptions.entries.map((e) =>
            PopupMenuItem(value: e.key, child: Text(e.value, style: TextStyle(
              fontWeight: state.sortBy == e.key ? FontWeight.bold : FontWeight.normal)))).toList(),
        ),
      ],
    );
  }
}
