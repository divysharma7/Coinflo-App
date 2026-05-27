import 'package:flutter/material.dart';

import 'package:finance_buddy_app/core/enums.dart';
import 'package:finance_buddy_app/design_system/app_colors.dart';
import 'package:finance_buddy_app/design_system/app_radius.dart';
import 'package:finance_buddy_app/design_system/app_spacing.dart';
import 'package:finance_buddy_app/design_system/app_text_styles.dart';

/// Resolves a subcategory display name to its parent [TransactionCategory].
TransactionCategory? _resolveCategory(String name) {
  // Check subcategory names first.
  for (final sub in Subcategory.all) {
    if (sub.name == name) return sub.group;
  }
  // Then check top-level category labels.
  for (final cat in TransactionCategory.values) {
    if (cat.label == name) return cat;
  }
  return null;
}

class CategoryPill extends StatelessWidget {
  const CategoryPill({super.key, required this.category});

  final String category;

  @override
  Widget build(BuildContext context) {
    final cat = _resolveCategory(category);
    final bg = cat != null ? AppColors.categoryBg(cat) : AppColors.catGrayBg;
    final fg = cat != null ? AppColors.categoryFg(cat) : AppColors.catGrayText;

    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.full,
      ),
      alignment: Alignment.center,
      child: Text(
        category,
        style: AppTextStyles.labelS.copyWith(color: fg),
      ),
    );
  }
}
