import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:finance_buddy_app/design_system/design_system.dart';
import 'package:finance_buddy_app/providers/providers.dart';

import 'package:finance_buddy_app/pages/report/widgets/bar_chart_section.dart';
import 'package:finance_buddy_app/pages/report/widgets/budget_vs_actual_card.dart';
import 'package:finance_buddy_app/pages/report/widgets/category_breakdown_section.dart';
import 'package:finance_buddy_app/pages/report/widgets/period_navigator.dart';
import 'package:finance_buddy_app/pages/report/widgets/period_selector.dart';
import 'package:finance_buddy_app/pages/report/widgets/projection_card.dart';
import 'package:finance_buddy_app/pages/report/widgets/report_header.dart';
import 'package:finance_buddy_app/pages/report/widgets/report_helpers.dart';
import 'package:finance_buddy_app/pages/report/widgets/report_scope.dart';
import 'package:finance_buddy_app/pages/report/widgets/savings_goals_section.dart';
import 'package:finance_buddy_app/pages/report/widgets/spending_split_donut.dart';
import 'package:finance_buddy_app/pages/report/widgets/streak_badge.dart';

// ---------------------------------------------------------------------------
// Report Page
// ---------------------------------------------------------------------------

class ReportPage extends ConsumerWidget {
  const ReportPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scope = ref.watch(reportScopeProvider);
    final symbol = reportSym(ref.watch(selectedCurrencyProvider).valueOrNull ?? 'inr');

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.black,
          backgroundColor: AppColors.white,
          onRefresh: () async {
            ref.invalidate(monthCategoryTotalsProvider);
            ref.invalidate(prevMonthCategoryTotalsProvider);
            ref.invalidate(budgetsProvider);
            ref.invalidate(weeklyTotalsForMonthProvider);
            ref.invalidate(monthlyTotalsForYearProvider);
            ref.invalidate(yearlyTotalsProvider);
            ref.invalidate(monthEndProjectionProvider);
            ref.invalidate(goalsProvider);
            ref.invalidate(streakProvider);
            ref.invalidate(monthlyBudgetProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.md),
                const ReportHeader(),
                const SizedBox(height: AppSpacing.lg),
                const PeriodSelector(),
                const SizedBox(height: AppSpacing.lg),
                const PeriodNavigator(),
                const SizedBox(height: AppSpacing.xl),
                BarChartSection(scope: scope, symbol: symbol)
                    .animate().fadeIn(duration: AppDurations.slow).slideY(begin: 0.05, duration: AppDurations.slow),
                const SizedBox(height: AppSpacing.lg),
                ProjectionCard(symbol: symbol)
                    .animate().fadeIn(delay: 80.ms, duration: AppDurations.slow).slideY(begin: 0.05, delay: 80.ms, duration: AppDurations.slow),
                const SizedBox(height: AppSpacing.lg),
                BudgetVsActualCard(symbol: symbol)
                    .animate().fadeIn(delay: 160.ms, duration: AppDurations.slow).slideY(begin: 0.05, delay: 160.ms, duration: AppDurations.slow),
                const SizedBox(height: AppSpacing.lg),
                const SavingsGoalsSection()
                    .animate().fadeIn(delay: 240.ms, duration: AppDurations.slow).slideY(begin: 0.05, delay: 240.ms, duration: AppDurations.slow),
                const SizedBox(height: AppSpacing.lg),
                StreakBadge(symbol: symbol)
                    .animate().fadeIn(delay: 320.ms, duration: AppDurations.slow).slideY(begin: 0.05, delay: 320.ms, duration: AppDurations.slow),
                const SizedBox(height: AppSpacing.lg),
                SpendingSplitDonut(symbol: symbol)
                    .animate().fadeIn(delay: 400.ms, duration: AppDurations.slow).slideY(begin: 0.05, delay: 400.ms, duration: AppDurations.slow),
                const SizedBox(height: AppSpacing.xxl),
                CategoryBreakdownSection(symbol: symbol)
                    .animate().fadeIn(delay: 480.ms, duration: AppDurations.slow).slideY(begin: 0.05, delay: 480.ms, duration: AppDurations.slow),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
