import 'package:finance_buddy_app/widgets/common/error_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:finance_buddy_app/design_system/design_system.dart';
import 'package:finance_buddy_app/providers/providers.dart';
import 'package:finance_buddy_app/widgets/common/animated_progress_bar.dart';
import 'package:finance_buddy_app/utils/currency_utils.dart';

import 'home_format_helpers.dart';

class BudgetProgressBar extends ConsumerWidget {
  const BudgetProgressBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expense = ref.watch(monthlyExpenseProvider);
    final budgetAsync = ref.watch(monthlyBudgetProvider);
    final currencyAsync = ref.watch(selectedCurrencyProvider);
    final month = ref.watch(selectedMonthProvider);
    final symbol = currencySymbol(currencyAsync.valueOrNull ?? 'inr');

    final budgetVal = budgetAsync.valueOrNull;
    final now = DateTime.now();
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final daysLeft = month.year == now.year && month.month == now.month
        ? daysInMonth - now.day
        : 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
      child: expense.when(
        data: (spent) {
          if (budgetVal == null || budgetVal <= 0) {
            return GestureDetector(
              onTap: () => ref.read(selectedTabProvider.notifier).state = 2,
              child: _noBudgetCard(context, ref),
            );
          }
          final pct = (spent / budgetVal).clamp(0.0, 1.0);
          final remaining = (budgetVal - spent).clamp(0.0, double.infinity);
          final barColor = pct < 0.6
              ? AppColors.green
              : pct < 0.85
                  ? AppColors.amber
                  : AppColors.red;

          return GestureDetector(
            onTap: () => ref.read(selectedTabProvider.notifier).state = 2,
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: AppRadius.lg,
                boxShadow: const [
                  BoxShadow(
                      color: AppColors.shadowMd,
                      blurRadius: 20,
                      offset: Offset(0, 4)),
                ],
              ),
              child: Column(
                children: [
                  // Spent / Budget labels
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('$symbol${formatHomeNumber(spent)} spent',
                          style: AppTextStyles.headingS
                              .copyWith(color: AppColors.black)),
                      Text('of $symbol${formatHomeNumber(budgetVal)}',
                          style: AppTextStyles.bodyM
                              .copyWith(color: AppColors.gray500)),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Progress bar
                  AnimatedProgressBar(
                    value: pct,
                    backgroundColor: AppColors.gray200,
                    valueColor: barColor,
                    minHeight: 12,
                    borderRadius: 6,
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // Stats below bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${(pct * 100).round()}% used',
                        style: AppTextStyles.bodyS.copyWith(color: barColor, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '$symbol${formatHomeNumber(remaining)} left · $daysLeft days',
                        style: AppTextStyles.bodyS.copyWith(color: AppColors.gray500),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const SizedBox(height: 100),
        error: (_, _) => const ErrorCard(),
      ),
    );
  }

  Widget _noBudgetCard(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppRadius.lg,
        border: Border.all(color: AppColors.gray200, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.gray100,
              borderRadius: AppRadius.base,
            ),
            child: Icon(PhosphorIcons.target(), size: 20, color: AppColors.gray500),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Set a monthly budget',
                    style: AppTextStyles.bodyM
                        .copyWith(fontWeight: FontWeight.w600)),
                Text('Track your spending against a limit',
                    style: AppTextStyles.bodyS
                        .copyWith(color: AppColors.gray500)),
              ],
            ),
          ),
          Icon(PhosphorIcons.caretRight(), size: 18, color: AppColors.gray500),
        ],
      ),
    );
  }
}
