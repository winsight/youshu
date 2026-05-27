import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/asset_category.dart';

class CategoryFilterBar extends StatelessWidget {
  final AssetCategory? selectedCategory;
  final ValueChanged<AssetCategory?> onSelected;

  const CategoryFilterBar({
    super.key,
    required this.selectedCategory,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final categories = <AssetCategory?>[
      null,
      ...AssetCategory.values,
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: categories.map((cat) {
          final isSelected = selectedCategory == cat;
          final label = cat?.displayName ?? 'All';
          return Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () => onSelected(cat),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? AppColors.onSurface
                          : AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (isSelected)
                    Container(
                      height: 2,
                      width: 24,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
