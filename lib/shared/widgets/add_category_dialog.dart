import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/l10n/app_locale.dart';
import '../../data/models/category_model.dart';
import '../../providers/database_provider.dart';

/// 可复用的新增分类弹窗
Future<CategoryInfo?> showAddCategoryDialog(
  BuildContext context,
  WidgetRef ref,
) async {
  final l10n = AppL10n.of(context);
  final nameController = TextEditingController();
  final nameZhController = TextEditingController();
  String selectedIcon = 'category';

  return showDialog<CategoryInfo>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) => AlertDialog(
        title: Text(l10n.isZh ? '新增分类' : 'New Category'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                    labelText: l10n.isZh ? '英文名' : 'English Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameZhController,
                decoration: InputDecoration(
                    labelText: l10n.isZh ? '中文名' : 'Chinese Name'),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: CategoryInfo.availableIcons.map((iconName) {
                  final isSelected = selectedIcon == iconName;
                  return GestureDetector(
                    onTap: () =>
                        setDialogState(() => selectedIcon = iconName),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withAlpha(30)
                            : AppColors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(8),
                        border: isSelected
                            ? Border.all(color: AppColors.primary)
                            : null,
                      ),
                      child: Icon(CategoryInfo.iconFor(iconName), size: 24),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final nameZh = nameZhController.text.trim();
              if (name.isEmpty || nameZh.isEmpty) return;

              final info = CategoryInfo(
                name: name,
                nameZh: nameZh,
                iconName: selectedIcon,
                sortOrder: 99,
              );
              await ref.read(categoryRepositoryProvider).add(info);
              ref.invalidate(categoriesProvider);
              if (ctx.mounted) Navigator.pop(ctx, info);
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    ),
  );
}
