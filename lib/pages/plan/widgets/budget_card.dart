import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:finance_buddy_app/core/enums.dart';
import 'package:finance_buddy_app/design_system/design_system.dart';
import 'package:finance_buddy_app/data/db.dart';
import 'package:finance_buddy_app/widgets/common/spendler_bottom_sheet.dart';

/// Indian-style digit grouping for amounts (₹12,450 / ₹1,20,000).
String _grouped(num value) {
  final s = value.abs().toStringAsFixed(0);
  if (s.length <= 3) return s;
  final last3 = s.substring(s.length - 3);
  var rest = s.substring(0, s.length - 3);
  final groups = <String>[];
  while (rest.length > 2) {
    groups.insert(0, rest.substring(rest.length - 2));
    rest = rest.substring(0, rest.length - 2);
  }
  groups.insert(0, rest);
  return '${groups.join(',')},$last3';
}

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
    final isOver = spent > budget.monthlyLimit;
    // Over-budget renders the figure + bar in red, bar pinned to 100%.
    final barColor = isOver ? AppColors.red : AppColors.black;
    final barFraction = isOver ? 1.0 : progress;

    return GestureDetector(
      onLongPress: () => _showOptionsSheet(context),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.categoryBg(category),
                    borderRadius: AppRadius.sm,
                  ),
                  child: Center(
                    child: PhosphorIcon(
                      category.iconFill,
                      size: 18,
                      color: AppColors.categoryFg(category),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    category.label,
                    style: AppTextStyles.bodyM.copyWith(
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                      color: AppColors.black,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                RichText(
                  text: TextSpan(
                    style: AppTextStyles.numericM.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isOver ? AppColors.red : AppColors.black,
                    ),
                    children: [
                      TextSpan(text: '$symbol${_grouped(spent)} '),
                      TextSpan(
                        text: '/ $symbol${_grouped(budget.monthlyLimit)}',
                        style: AppTextStyles.numericM.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.gray400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            // Thin progress bar — 6pt tall, fully rounded.
            ClipRRect(
              borderRadius: AppRadius.full,
              child: SizedBox(
                height: 6,
                child: Stack(
                  children: [
                    Container(color: AppColors.gray100),
                    FractionallySizedBox(
                      widthFactor: barFraction.clamp(0.0, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: barColor,
                          borderRadius: AppRadius.full,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
                _confirmDelete(context);
              },
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    final category = TransactionCategory.values.firstWhere(
      (c) => c.name == budget.category,
      orElse: () => TransactionCategory.other,
    );
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Budget'),
        content: Text('${category.label}? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              onDelete();
            },
            child: Text('Delete',
                style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
  }
}
