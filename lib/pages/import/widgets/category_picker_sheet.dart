import 'package:flutter/material.dart';

import 'package:finance_buddy_app/core/enums.dart';
import 'package:finance_buddy_app/design_system/design_system.dart';
import 'package:finance_buddy_app/widgets/common/spendler_bottom_sheet.dart';

Future<String?> showCategoryPicker(BuildContext context) {
  return showSpendlerSheet<String>(
    context: context,
    builder: (ctx) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Choose category',
            style: AppTextStyles.headingS,
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            "We'll learn this for next time",
            style: AppTextStyles.bodyS.copyWith(
              color: AppColors.gray500,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: TransactionCategory.groups.length,
              itemBuilder: (context, index) {
                final category = TransactionCategory.groups[index];
                final categoryColor = AppColors.categoryColor(category);

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor:
                        categoryColor.withValues(alpha: 0.15),
                    child: Icon(
                      category.icon,
                      size: 20,
                      color: categoryColor,
                    ),
                  ),
                  title: Text(
                    category.label,
                    style: AppTextStyles.bodyM,
                  ),
                  onTap: () => Navigator.pop(context, category.name),
                );
              },
            ),
          ),
        ],
      );
    },
  );
}
