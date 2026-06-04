import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:finance_buddy_app/design_system/design_system.dart';
import 'package:finance_buddy_app/providers/providers.dart';
import 'package:finance_buddy_app/utils/currency_utils.dart';
import 'package:finance_buddy_app/widgets/common/error_card.dart';

import 'home_format_helpers.dart';

/// Zone 2 — dark budget hero. Shows spend vs. budget with a status pill,
/// progress bar and per-day-to-stay-on-track footer. Tapping the card opens
/// the Plan/budget tab. When no budget is set, shows a light prompt card.
class BudgetProgressBar extends ConsumerWidget {
  const BudgetProgressBar({super.key});

  /// Index of the Plan tab in the shell `IndexedStack`.
  static const int _planTabIndex = 2;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expense = ref.watch(monthlyExpenseProvider);
    final budgetVal = ref.watch(monthlyBudgetProvider).valueOrNull;
    final symbol =
        currencySymbol(ref.watch(selectedCurrencyProvider).valueOrNull ?? 'inr');
    final month = ref.watch(selectedMonthProvider);

    final now = DateTime.now();
    final monthName = _monthName(month.month);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final daysLeft = month.year == now.year && month.month == now.month
        ? daysInMonth - now.day
        : 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md + 4,
        AppSpacing.lg,
        AppSpacing.xs,
      ),
      child: expense.when(
        data: (spent) {
          if (budgetVal == null || budgetVal <= 0) {
            return GestureDetector(
              onTap: () =>
                  ref.read(selectedTabProvider.notifier).state = _planTabIndex,
              child: const _NoBudgetCard(),
            );
          }
          return GestureDetector(
            onTap: () =>
                ref.read(selectedTabProvider.notifier).state = _planTabIndex,
            child: _buildHero(
              symbol: symbol,
              monthName: monthName,
              spent: spent,
              budget: budgetVal,
              daysLeft: daysLeft,
            ),
          );
        },
        loading: () => const SizedBox(height: 160),
        error: (_, _) => const ErrorCard(),
      ),
    );
  }

  Widget _buildHero({
    required String symbol,
    required String monthName,
    required double spent,
    required double budget,
    required int daysLeft,
  }) {
    final pct = (spent / budget).clamp(0.0, 1.0);
    final remaining = (budget - spent).clamp(0.0, double.infinity);
    final isOver = spent > budget;
    // Per-day budget left to stay on track.
    final perDay = daysLeft > 0
        ? formatHomeNumber(remaining / daysLeft)
        : formatHomeNumber(remaining);

    return DarkHeroCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label + status pill.
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Spent in $monthName',
                style: AppTextStyles.labelM.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                  color: AppColors.white.withValues(alpha: 0.6),
                ),
              ),
              _StatusPill(isOver: isOver),
            ],
          ),
          const SizedBox(height: 6),
          // Big mono hero amount.
          Text(
            '$symbol${formatHomeNumber(spent)}',
            style: AppTextStyles.displayXL.copyWith(
              color: AppColors.white,
              letterSpacing: -1.6,
            ),
          ),
          const SizedBox(height: AppSpacing.md + 2),
          // of <budget> · <remaining> left.
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'of $symbol${formatHomeNumber(budget)} budget',
                style: AppTextStyles.labelM.copyWith(
                  fontWeight: FontWeight.w500,
                  color: AppColors.white.withValues(alpha: 0.6),
                ),
              ),
              Text(
                '$symbol${formatHomeNumber(remaining)} left',
                style: AppTextStyles.numericM.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          // White progress bar on white-16 track.
          ClipRRect(
            borderRadius: AppRadius.full,
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 8,
              backgroundColor: AppColors.white.withValues(alpha: 0.16),
              valueColor: const AlwaysStoppedAnimation(AppColors.white),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          // Days left · per-day to stay on track.
          Text(
            '${daysLeft == 1 ? '1 day' : '$daysLeft days'} left'
            ' · $symbol$perDay/day to stay on track',
            style: AppTextStyles.labelS.copyWith(
              color: AppColors.white.withValues(alpha: 0.45),
            ),
          ),
        ],
      ),
    );
  }

  String _monthName(int month) {
    const names = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return names[(month - 1) % 12];
  }
}

/// Green "On track" / red "Over budget" pill shown in the hero top row.
class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.isOver});
  final bool isOver;

  @override
  Widget build(BuildContext context) {
    final bg = isOver
        ? AppColors.red.withValues(alpha: 0.16)
        : AppColors.green.withValues(alpha: 0.16);
    final fg = isOver ? AppColors.redLifted : AppColors.greenLifted;
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs, vertical: AppSpacing.xxs),
      decoration: BoxDecoration(color: bg, borderRadius: AppRadius.full),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOver
                ? PhosphorIcons.warning(PhosphorIconsStyle.bold)
                : PhosphorIcons.check(PhosphorIconsStyle.bold),
            size: 12,
            color: fg,
          ),
          const SizedBox(width: 5),
          Text(
            isOver ? 'Over budget' : 'On track',
            style: AppTextStyles.labelS.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

/// Light prompt shown when no monthly budget has been set yet.
class _NoBudgetCard extends StatelessWidget {
  const _NoBudgetCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: AppRadius.xl,
        boxShadow: AppShadows.sm,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: AppColors.gray100,
              borderRadius: AppRadius.md,
            ),
            child: Icon(
              PhosphorIcons.target(),
              size: 22,
              color: AppColors.gray500,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Set a monthly budget',
                  style: AppTextStyles.bodyM
                      .copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  'Track your spending against a limit',
                  style:
                      AppTextStyles.bodyS.copyWith(color: AppColors.gray500),
                ),
              ],
            ),
          ),
          Icon(
            PhosphorIcons.caretRight(),
            size: 18,
            color: AppColors.gray500,
          ),
        ],
      ),
    );
  }
}
