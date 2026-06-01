import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:finance_buddy_app/design_system/design_system.dart';
import 'package:finance_buddy_app/providers/providers.dart';
import 'package:finance_buddy_app/utils/currency_utils.dart';

import 'home_format_helpers.dart';

class QuickStatsRow extends ConsumerWidget {
  const QuickStatsRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayAsync = ref.watch(todaySpendingProvider);
    final monthExpense = ref.watch(monthlyExpenseProvider);
    final lastMonthAsync = ref.watch(lastMonthExpenseProvider);
    final currencyAsync = ref.watch(selectedCurrencyProvider);
    final symbol = currencySymbol(currencyAsync.valueOrNull ?? 'inr');

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.md),
      child: Row(
        children: [
          // Today
          Expanded(
            child: StatCard(
              label: 'Today',
              value: todayAsync.when(
                data: (v) => '$symbol${formatHomeNumber(v)}',
                loading: () => '—',
                error: (_, _) => '—',
              ),
              icon: PhosphorIcons.sun(),
              color: AppColors.black,
            ).animate().fadeIn(delay: 0.ms, duration: AppDurations.medium).slideX(begin: 0.1, duration: AppDurations.medium),
          ),
          const SizedBox(width: AppSpacing.sm),

          // This month
          Expanded(
            child: StatCard(
              label: 'This month',
              value: monthExpense.when(
                data: (v) => '$symbol${formatHomeNumber(v)}',
                loading: () => '—',
                error: (_, _) => '—',
              ),
              icon: PhosphorIcons.calendarBlank(),
              color: AppColors.black,
            ).animate().fadeIn(delay: 60.ms, duration: AppDurations.medium).slideX(begin: 0.1, duration: AppDurations.medium, delay: 60.ms),
          ),
          const SizedBox(width: AppSpacing.sm),

          // vs Last month
          Expanded(
            child: _vsLastMonthCard(context, ref, monthExpense, lastMonthAsync),
          ),
        ],
      ),
    );
  }

  Widget _vsLastMonthCard(
      BuildContext context, WidgetRef ref,
      AsyncValue<double> current, AsyncValue<double> last) {
    final curVal = current.valueOrNull ?? 0;
    final lastVal = last.valueOrNull ?? 0;

    String label;
    Color color;
    IconData icon;

    if (lastVal == 0) {
      label = '—';
      color = AppColors.gray500;
      icon = PhosphorIcons.trendUp();
    } else {
      final pct = ((curVal - lastVal) / lastVal * 100).round();
      if (pct >= 0) {
        label = '↑ $pct%';
        color = AppColors.red;
        icon = PhosphorIcons.trendUp();
      } else {
        label = '↓ ${pct.abs()}%';
        color = AppColors.green;
        icon = PhosphorIcons.trendDown();
      }
    }

    return GestureDetector(
      onTap: () => ref.read(selectedTabProvider.notifier).state = 1,
      child: StatCard(
        label: 'vs Last month',
        value: label,
        icon: icon,
        color: color,
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm + 2),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppRadius.mdLg,
        boxShadow: const [
          BoxShadow(
              color: AppColors.shadow, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.gray500),
          const SizedBox(height: AppSpacing.xs),
          Text(value,
              style: AppTextStyles.headingS
                  .copyWith(color: color, fontSize: 16)),
          const SizedBox(height: 2),
          Text(label,
              style:
                  AppTextStyles.labelS.copyWith(color: AppColors.gray500)),
        ],
      ),
    );
  }
}
