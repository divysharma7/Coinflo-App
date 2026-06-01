import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:finance_buddy_app/design_system/design_system.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'widgets/header_section.dart';
import 'widgets/budget_progress_bar.dart';
import 'widgets/quick_stats_row.dart';
import 'widgets/daily_spend_chart.dart';
import 'widgets/top_categories_section.dart';
import 'widgets/savings_goals_section.dart';
import 'widgets/recent_transactions_section.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(child: HeaderSection()),
        SliverToBoxAdapter(child: const BudgetProgressBar()
            .animate().fadeIn(duration: AppDurations.slow).slideY(begin: 0.05, duration: AppDurations.slow)),
        SliverToBoxAdapter(child: const QuickStatsRow()
            .animate().fadeIn(delay: 80.ms, duration: AppDurations.slow).slideY(begin: 0.05, duration: AppDurations.slow, delay: 80.ms)),
        SliverToBoxAdapter(child: const DailySpendChart()
            .animate().fadeIn(delay: 160.ms, duration: AppDurations.slow).slideY(begin: 0.05, duration: AppDurations.slow, delay: 160.ms)),
        SliverToBoxAdapter(child: const TopCategoriesSection()
            .animate().fadeIn(delay: 240.ms, duration: AppDurations.slow).slideY(begin: 0.05, duration: AppDurations.slow, delay: 240.ms)),
        SliverToBoxAdapter(child: const SavingsGoalsSection()
            .animate().fadeIn(delay: 320.ms, duration: AppDurations.slow).slideY(begin: 0.05, duration: AppDurations.slow, delay: 320.ms)),
        SliverToBoxAdapter(child: const RecentTransactionsSection()
            .animate().fadeIn(delay: 400.ms, duration: AppDurations.slow).slideY(begin: 0.05, duration: AppDurations.slow, delay: 400.ms)),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }
}
