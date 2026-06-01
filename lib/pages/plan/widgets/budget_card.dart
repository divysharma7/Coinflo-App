import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:finance_buddy_app/core/enums.dart';
import 'package:finance_buddy_app/design_system/design_system.dart';
import 'package:finance_buddy_app/data/db.dart';
import 'package:finance_buddy_app/widgets/common/spendler_bottom_sheet.dart';

class BudgetCard extends StatelessWidget {
  const BudgetCard({
    super.key,
    required this.budget,
    required this.spent,
    required this.onDelete,
    required this.onEdit,
    required this.symbol,
  });

  final CategoryBudget budget;
  final double spent;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final String symbol;

  @override
  Widget build(BuildContext context) {
    final category = TransactionCategory.values.firstWhere(
      (c) => c.name == budget.category,
      orElse: () => TransactionCategory.other,
    );
    final progress = budget.monthlyLimit > 0
        ? (spent / budget.monthlyLimit).clamp(0.0, 1.0)
        : 0.0;
    final percent = budget.monthlyLimit > 0
        ? (spent / budget.monthlyLimit * 100)
        : 0.0;
    final isOver = spent > budget.monthlyLimit;
    final isCritical = percent > 150;
    final categoryColor = AppColors.categoryColor(category);
    final barColor = isCritical
        ? AppColors.red
        : isOver
            ? AppColors.orange
            : categoryColor;

    return GestureDetector(
      onLongPress: () => _showOptionsSheet(context),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: AppRadius.lg,
          boxShadow: AppShadows.sm,
          border: isCritical
              ? Border.all(color: AppColors.red.withValues(alpha: 0.4), width: 1.5)
              : isOver
                  ? Border.all(color: AppColors.orange.withValues(alpha: 0.3), width: 1)
                  : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isOver
                        ? barColor.withValues(alpha: 0.12)
                        : categoryColor.withValues(alpha: 0.12),
                    borderRadius: AppRadius.sm,
                  ),
                  child: Center(
                    child: PhosphorIcon(
                      category.iconFill,
                      size: 18,
                      color: isOver ? barColor : categoryColor,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.label,
                        style: AppTextStyles.bodyM.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.black,
                        ),
                      ),
                      if (isOver)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Row(
                            children: [
                              PhosphorIcon(
                                isCritical
                                    ? PhosphorIconsFill.warning
                                    : PhosphorIcons.warning(),
                                size: 12,
                                color: barColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isCritical
                                    ? 'Way over budget (${percent.toStringAsFixed(0)}%)'
                                    : 'Over budget (${percent.toStringAsFixed(0)}%)',
                                style: AppTextStyles.labelS.copyWith(
                                  color: barColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                Text(
                  '$symbol${spent.toStringAsFixed(0)} / $symbol${budget.monthlyLimit.toStringAsFixed(0)}',
                  style: AppTextStyles.bodyS.copyWith(
                    fontWeight: FontWeight.w500,
                    color: isOver ? barColor : AppColors.gray500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            // Progress bar — 6pt tall, fully rounded
            ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(3)),
              child: SizedBox(
                height: 6,
                child: Stack(
                  children: [
                    // Track
                    Container(
                      decoration: BoxDecoration(
                        color: isOver
                            ? barColor.withValues(alpha: 0.15)
                            : AppColors.gray200,
                        borderRadius:
                            const BorderRadius.all(Radius.circular(3)),
                      ),
                    ),
                    // Fill
                    FractionallySizedBox(
                      widthFactor: progress.clamp(0.0, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: barColor,
                          borderRadius:
                              const BorderRadius.all(Radius.circular(3)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (isOver) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                '$symbol${(spent - budget.monthlyLimit).toStringAsFixed(0)} over limit',
                style: AppTextStyles.labelS.copyWith(
                  color: barColor,
                  fontWeight: isCritical ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showOptionsSheet(BuildContext context) {
    showSpendlerSheet<void>(
      context: context,
      isScrollControlled: false,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: PhosphorIcon(PhosphorIcons.pencilSimple(), color: AppColors.black),
              title: const Text('Edit Budget'),
              onTap: () {
                Navigator.pop(ctx);
                onEdit();
              },
            ),
            ListTile(
              leading: PhosphorIcon(PhosphorIcons.trash(), color: AppColors.red),
              title: const Text('Delete Budget', style: TextStyle(color: AppColors.red)),
              onTap: () {
                Navigator.pop(ctx);
                onDelete();
              },
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }
}
