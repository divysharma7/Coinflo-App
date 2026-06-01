import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:finance_buddy_app/design_system/design_system.dart';

import 'package:finance_buddy_app/pages/report/widgets/report_bar_charts.dart';
import 'package:finance_buddy_app/pages/report/widgets/report_helpers.dart';
import 'package:finance_buddy_app/pages/report/widgets/report_scope.dart';

// ─── Bar Chart ──────────────────────────────────────────

class BarChartSection extends ConsumerWidget {
  const BarChartSection({super.key, required this.scope, required this.symbol});
  final ReportScope scope;
  final String symbol;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String title;
    switch (scope) {
      case ReportScope.week:
        title = 'Weekly Breakdown';
      case ReportScope.month:
        title = 'Monthly Overview';
      case ReportScope.year:
        title = 'Yearly Totals';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: reportCardDecor(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTextStyles.headingS.copyWith(color: AppColors.black)),
            const SizedBox(height: AppSpacing.lg),
            _buildChart(scope, symbol),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(ReportScope scope, String symbol) {
    switch (scope) {
      case ReportScope.week:
        return WeeklyBarChart(symbol: symbol);
      case ReportScope.month:
        return MonthlyBarChart(symbol: symbol);
      case ReportScope.year:
        return YearlyBarChart(symbol: symbol);
    }
  }
}
