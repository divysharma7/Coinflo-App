import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:finance_buddy_app/design_system/design_system.dart';
import 'package:finance_buddy_app/providers/providers.dart';
import 'package:finance_buddy_app/widgets/charts/spend_bar_chart.dart';
import 'package:finance_buddy_app/utils/currency_utils.dart';

class DailySpendChart extends ConsumerWidget {
  const DailySpendChart({super.key});

  static const _dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weekStart = ref.watch(selectedWeekStartProvider);
    final dailyAsync = ref.watch(dailySpendingForWeekProvider);
    final currencyAsync = ref.watch(selectedCurrencyProvider);
    final symbol = currencySymbol(currencyAsync.valueOrNull ?? 'inr');

    final weekEnd = weekStart.add(const Duration(days: 6));
    final label =
        '${DateFormat('d MMM').format(weekStart)} – ${DateFormat('d MMM').format(weekEnd)}';
    final now = DateTime.now();
    final currentWeekStart =
        DateTime(now.year, now.month, now.day - (now.weekday - 1));
    final canForward = weekStart.isBefore(currentWeekStart);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: AppRadius.lg,
          boxShadow: const [
            BoxShadow(
                color: AppColors.shadow,
                blurRadius: 16,
                offset: Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Daily Spend',
                    style: AppTextStyles.headingS
                        .copyWith(color: AppColors.black)),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => ref
                          .read(selectedWeekStartProvider.notifier)
                          .state = weekStart.subtract(const Duration(days: 7)),
                      child: const Icon(Icons.chevron_left,
                          color: AppColors.gray500, size: 22),
                    ),
                    Text(label,
                        style: AppTextStyles.labelS
                            .copyWith(color: AppColors.gray500)),
                    GestureDetector(
                      onTap: canForward
                          ? () => ref
                              .read(selectedWeekStartProvider.notifier)
                              .state = weekStart.add(const Duration(days: 7))
                          : null,
                      child: Icon(Icons.chevron_right,
                          color: canForward
                              ? AppColors.gray500
                              : AppColors.gray200,
                          size: 22),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            dailyAsync.when(
              data: (values) => SpendBarChart(
                values: values,
                labels: _dayLabels,
                currencySymbol: symbol,
                onBarTap: (i) {
                  final tappedDate = weekStart.add(Duration(days: i));
                  context.push('/daily-view', extra: tappedDate);
                },
              ),
              loading: () => const SizedBox(
                  height: 180,
                  child: Center(
                      child:
                          CircularProgressIndicator(color: AppColors.black))),
              error: (_, _) => const SizedBox(height: 180),
            ),
          ],
        ),
      ),
    );
  }
}
