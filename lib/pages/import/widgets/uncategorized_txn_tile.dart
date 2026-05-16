import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:finance_buddy_app/design_system/design_system.dart';

class UncategorizedTxnTile extends StatelessWidget {
  const UncategorizedTxnTile({
    super.key,
    required this.merchantToken,
    required this.amount,
    required this.date,
    required this.onPickCategory,
  });

  final String merchantToken;
  final double amount;
  final DateTime date;
  final VoidCallback onPickCategory;

  @override
  Widget build(BuildContext context) {
    final dateFormatted = DateFormat('d MMM yyyy').format(date);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppRadius.md,
        border: Border.all(color: AppColors.gray200, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Left avatar
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.gray100,
                child: Icon(
                  PhosphorIcons.question(),
                  size: 20,
                  color: AppColors.gray500,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Center column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      merchantToken,
                      style: AppTextStyles.bodyM.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dateFormatted,
                      style: AppTextStyles.bodyS.copyWith(
                        color: AppColors.gray500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              // Right amount
              Text(
                '-${amount.toStringAsFixed(2)}',
                style: AppTextStyles.numericM.copyWith(
                  color: AppColors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          // Pick category button
          TextButton(
            onPressed: onPickCategory,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 32),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Pick category',
              style: AppTextStyles.bodyS.copyWith(
                color: AppColors.gray500,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
