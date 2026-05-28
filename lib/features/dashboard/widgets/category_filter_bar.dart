import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/l10n/app_locale.dart';
import '../../../providers/database_provider.dart';
import '../../../shared/widgets/add_category_dialog.dart';

class CategoryFilterBar extends ConsumerWidget {
  final String? selectedCategory;
  final ValueChanged<String?> onSelected;

  const CategoryFilterBar({
    super.key,
    required this.selectedCategory,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final catsAsync = ref.watch(categoriesProvider);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: catsAsync.when(
        data: (categories) => Row(
          children: [
            _buildChip(ref, null, l10n.all),
            ...categories.map((cat) => _buildChip(
                ref, cat.name, l10n.isZh ? cat.nameZh : cat.name)),
            // 新增分类按钮
            _buildAddButton(context, ref),
          ],
        ),
        loading: () => const SizedBox.shrink(),
        error: (e, s) => const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildChip(WidgetRef ref, String? category, String label) {
    final isSelected = selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onSelected(category),
          borderRadius: BorderRadius.circular(8),
          splashColor: AppColors.primary.withAlpha(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? AppColors.onSurface
                        : AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  height: 2,
                  width: isSelected ? 24 : 0,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddButton(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            await showAddCategoryDialog(context, ref);
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: const Icon(Icons.add_circle_outline,
                size: 20, color: AppColors.primary),
          ),
        ),
      ),
    );
  }
}
