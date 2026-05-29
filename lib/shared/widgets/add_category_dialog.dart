import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/l10n/app_locale.dart';
import '../../data/models/category_model.dart';
import '../../providers/database_provider.dart';

final defaultCategories = {'electronics', 'transport', 'collection', 'tools', 'other'};

Future<CategoryInfo?> showAddCategoryDialog(BuildContext context, WidgetRef ref) async {
  final l10n = AppL10n.of(context);
  final nameController = TextEditingController();
  final nameZhController = TextEditingController();
  String selectedIcon = 'category';
  final existingCats = await ref.read(categoryRepositoryProvider).getAll();

  return showDialog<CategoryInfo>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) => AlertDialog(
        title: Text(l10n.isZh ? '管理分类' : 'Manage Categories'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // Existing categories with delete
            ...existingCats.map((cat) => ListTile(
                  dense: true,
                  leading: Icon(CategoryInfo.iconFor(cat.iconName), size: 22, color: AppColors.primary),
                  title: Text(l10n.isZh ? cat.nameZh : cat.name, style: const TextStyle(fontSize: 14)),
                  trailing: defaultCategories.contains(cat.name)
                      ? const SizedBox(width: 24)
                      : IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: ctx,
                              builder: (c) => AlertDialog(
                                title: Text(l10n.isZh ? '删除分类' : 'Delete Category'),
                                content: Text(l10n.isZh ? '确定删除 "${cat.nameZh}"？' : 'Delete "${cat.name}"?'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(c, false), child: Text(l10n.cancel)),
                                  TextButton(onPressed: () => Navigator.pop(c, true),
                                      child: Text(l10n.delete, style: const TextStyle(color: AppColors.error))),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              await ref.read(categoryRepositoryProvider).delete(cat.name);
                              ref.invalidate(categoriesProvider);
                              setDialogState(() {});
                            }
                          },
                        ),
                )),
            const Divider(),
            const SizedBox(height: 8),
            // Add new category
            Text(l10n.isZh ? '新增分类' : 'Add Category', style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(controller: nameController, decoration: InputDecoration(labelText: l10n.isZh ? '英文名' : 'English Name')),
            const SizedBox(height: 8),
            TextField(controller: nameZhController, decoration: InputDecoration(labelText: l10n.isZh ? '中文名' : 'Chinese Name')),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8,
              children: CategoryInfo.availableIcons.map((iconName) {
                final isSelected = selectedIcon == iconName;
                return GestureDetector(
                  onTap: () => setDialogState(() => selectedIcon = iconName),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary.withAlpha(30) : AppColors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(8),
                      border: isSelected ? Border.all(color: AppColors.primary) : null,
                    ),
                    child: Icon(CategoryInfo.iconFor(iconName), size: 24),
                  ),
                );
              }).toList(),
            ),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
          FilledButton(onPressed: () async {
            final name = nameController.text.trim();
            final nameZh = nameZhController.text.trim();
            if (name.isEmpty || nameZh.isEmpty) return;
            final info = CategoryInfo(name: name, nameZh: nameZh, iconName: selectedIcon, sortOrder: 99);
            await ref.read(categoryRepositoryProvider).add(info);
            ref.invalidate(categoriesProvider);
            if (ctx.mounted) Navigator.pop(ctx, info);
          }, child: Text(l10n.save)),
        ],
      ),
    ),
  );
}
