import 'package:flutter/material.dart';

import 'package:finance_buddy_app/design_system/app_colors.dart';
import 'package:finance_buddy_app/design_system/app_radius.dart';
import 'package:finance_buddy_app/design_system/app_spacing.dart';
import 'package:finance_buddy_app/design_system/app_text_styles.dart';

class _CategoryColors {
  final Color bg;
  final Color text;
  const _CategoryColors(this.bg, this.text);
}

const Map<String, _CategoryColors> _categoryColorMap = {
  'Streaming Services': _CategoryColors(AppColors.catPinkBg, AppColors.catPinkText),
  'Groceries': _CategoryColors(AppColors.catOrangeBg, AppColors.catOrangeText),
  'Gym & Fitness': _CategoryColors(AppColors.catGreenBg, AppColors.catGreenText),
  'Productivity Tools': _CategoryColors(AppColors.catPurpleBg, AppColors.catPurpleText),
  'Movies & Cinema': _CategoryColors(AppColors.catPinkBg, AppColors.catPinkText),
  'Miscellaneous': _CategoryColors(AppColors.catGrayBg, AppColors.catGrayText),
};

const _CategoryColors _defaultColors = _CategoryColors(AppColors.catGrayBg, AppColors.catGrayText);

class CategoryPill extends StatelessWidget {
  const CategoryPill({super.key, required this.category});

  final String category;

  @override
  Widget build(BuildContext context) {
    final colors = _categoryColorMap[category] ?? _defaultColors;

    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      decoration: BoxDecoration(
        color: colors.bg,
        borderRadius: AppRadius.full,
      ),
      alignment: Alignment.center,
      child: Text(
        category,
        style: AppTextStyles.labelS.copyWith(color: colors.text),
      ),
    );
  }
}
