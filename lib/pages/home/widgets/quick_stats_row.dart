import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:finance_buddy_app/design_system/design_system.dart';
import 'package:finance_buddy_app/providers/providers.dart';
import 'package:finance_buddy_app/utils/currency_utils.dart';

import 'home_format_helpers.dart';

/// Zone 3 — three equal-width stat cards: Income, Net flow (tap → Report tab)
/// and Avg / day. Shows an em-dash placeholder while data is unavailable.
class QuickStatsRow extends ConsumerWidget {
  const QuickStatsRow({super.key});

  /// Index of the Report tab in the shell `IndexedStack`.
  static const int _reportTabIndex = 1;

  static const String _placeholder = '—';
  static const double _cardGap = 10;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incomeAsync = ref.watch(monthlyIncomeProvider);
    final expenseAsync = ref.watch(monthlyExpenseProvider);
    final month = ref.watch(selectedMonthProvider);
    final symbol =
        currencySymbol(ref.watch(selectedCurrencyProvider).valueOrNull ?? 'inr');

    final income = incomeAsync.valueOrNull ?? 0;
    final expense = expenseAsync.valueOrNull ?? 0;
    final netFlow = income - expense;

    // Average expense per elapsed day of the selected month.
    final now = DateTime.now();
    final isCurrentMonth = month.year == now.year && month.month == now.month;
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final elapsed = isCurrentMonth ? now.day : daysInMonth;
    final avgPerDay = elapsed > 0 ? expense / elapsed : 0;

    final hasIncome = incomeAsync.hasValue;
    final hasExpense = expenseAsync.hasValue;

    String money(num v) => '$symbol${formatHomeNumber(v.toDouble())}';

    return Container(
      height: 140,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Income — sum of positive amounts.
          Expanded(
            child: StatTile(
              icon: Icon(
                PhosphorIcons.arrowUpRight(PhosphorIconsStyle.bold),
                color: AppColors.catGreenText,
              ),
              label: 'Income',
              value: hasIncome ? money(income) : _placeholder,
            ),
          ),
          const SizedBox(width: _cardGap),
          // Net flow (income − expense) — tap → Report tab.
          Expanded(
            child: GestureDetector(
              onTap: () => ref.read(selectedTabProvider.notifier).state =
                  _reportTabIndex,
              child: StatTile(
                icon: Icon(
                  PhosphorIcons.pulse(PhosphorIconsStyle.bold),
                  color: AppColors.black,
                ),
                label: 'Net flow',
                value: (hasIncome && hasExpense)
                    ? '${netFlow >= 0 ? '+' : '-'}${money(netFlow.abs())}'
                    : _placeholder,
                valueColor:
                    netFlow >= 0 ? AppColors.catGreenText : AppColors.black,
              ),
            ),
          ),
          const SizedBox(width: _cardGap),
          // Avg / day — expense ÷ elapsed days.
          Expanded(
            child: StatTile(
              icon: Icon(
                PhosphorIcons.calendarBlank(PhosphorIconsStyle.bold),
                color: AppColors.black,
              ),
              label: 'Avg / day',
              value: hasExpense ? money(avgPerDay) : _placeholder,
            ),
          ),
        ],
      ),
    );
  }
}
