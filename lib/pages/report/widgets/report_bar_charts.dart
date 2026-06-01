import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:finance_buddy_app/design_system/design_system.dart';
import 'package:finance_buddy_app/providers/providers.dart';
import 'package:finance_buddy_app/widgets/charts/spend_bar_chart.dart';

// ---------------------------------------------------------------------------
// Bar Chart Widgets
// ---------------------------------------------------------------------------

class WeeklyBarChart extends ConsumerWidget {
  const WeeklyBarChart({super.key, required this.symbol});
  final String symbol;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(weeklyTotalsForMonthProvider);
    return async.when(
      data: (v) => SpendBarChart(
          values: v,
          labels: const ['Week 1', 'Week 2', 'Week 3', 'Week 4'],
          currencySymbol: symbol),
      loading: () => const SizedBox(height: 180,
          child: Center(child: CircularProgressIndicator(color: AppColors.black))),
      error: (_, _) => const SizedBox(height: 180),
    );
  }
}

class MonthlyBarChart extends ConsumerWidget {
  const MonthlyBarChart({super.key, required this.symbol});
  final String symbol;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(monthlyTotalsForYearProvider);
    return async.when(
      data: (v) => SpendBarChart(
          values: v,
          labels: const ['J','F','M','A','M','J','J','A','S','O','N','D'],
          currencySymbol: symbol, height: 200),
      loading: () => const SizedBox(height: 200,
          child: Center(child: CircularProgressIndicator(color: AppColors.black))),
      error: (_, _) => const SizedBox(height: 200),
    );
  }
}

class YearlyBarChart extends ConsumerWidget {
  const YearlyBarChart({super.key, required this.symbol});
  final String symbol;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(yearlyTotalsProvider);
    return async.when(
      data: (data) {
        if (data.isEmpty) {
          return SizedBox(height: 180,
              child: Center(child: Text('Not enough data yet',
                  style: AppTextStyles.bodyM.copyWith(color: AppColors.gray500))));
        }
        final years = data.keys.toList()..sort();
        return SpendBarChart(
            values: years.map((y) => data[y]!).toList(),
            labels: years.map((y) => '$y').toList(),
            currencySymbol: symbol);
      },
      loading: () => const SizedBox(height: 180,
          child: Center(child: CircularProgressIndicator(color: AppColors.black))),
      error: (_, _) => const SizedBox(height: 180),
    );
  }
}
