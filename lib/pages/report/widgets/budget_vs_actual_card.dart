import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:finance_buddy_app/core/enums.dart';
import 'package:finance_buddy_app/design_system/design_system.dart';
import 'package:finance_buddy_app/providers/providers.dart';
import 'package:finance_buddy_app/widgets/common/animated_progress_bar.dart';
import 'package:finance_buddy_app/widgets/common/error_card.dart';

import 'package:finance_buddy_app/pages/report/widgets/report_helpers.dart';
import 'package:finance_buddy_app/pages/report/widgets/report_scope.dart';

// ─── Budget vs Actual (per category) ────────────────────

class BudgetVsActualCard extends ConsumerWidget {
  const BudgetVsActualCard({super.key, required this.symbol});
  final String symbol;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgets = ref.watch(budgetsProvider);
    final spending = ref.watch(monthCategoryTotalsProvider);

    return budgets.when(
      data: (budgetList) {
        if (budgetList.isEmpty) return const SizedBox.shrink();
        final spendMap = spending.valueOrNull ?? {};

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: reportCardDecor(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Budget Health',
                    style: AppTextStyles.headingS.copyWith(color: AppColors.black)),
                const SizedBox(height: 4),
                Text('How each category is tracking',
                    style: AppTextStyles.bodyS.copyWith(color: AppColors.gray500)),
                const SizedBox(height: AppSpacing.lg),
                ...budgetList.map((b) {
                  final cat = TransactionCategory.values.firstWhere(
                    (c) => c.name == b.category,
                    orElse: () => TransactionCategory.other,
                  );
                  final spent = spendMap[b.category] ?? 0;
                  final pct = b.monthlyLimit > 0
                      ? (spent / b.monthlyLimit).clamp(0.0, 1.0)
                      : 0.0;
                  final color = AppColors.categoryColor(cat);
                  final barColor = pct < 0.6
                      ? AppColors.green
                      : pct < 0.85
                          ? AppColors.amber
                          : AppColors.red;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(cat.iconFill, size: 16, color: color),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(cat.label,
                                  style: AppTextStyles.bodyM
                                      .copyWith(fontWeight: FontWeight.w500)),
                            ),
                            Text(
                              '$symbol${reportFmt(spent)} / $symbol${reportFmt(b.monthlyLimit)}',
                              style: AppTextStyles.bodyS.copyWith(color: AppColors.gray500),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        AnimatedProgressBar(
                          value: pct,
                          backgroundColor: AppColors.gray100,
                          valueColor: barColor,
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const ErrorCard(),
    );
  }
}
