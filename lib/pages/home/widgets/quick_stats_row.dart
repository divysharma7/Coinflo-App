import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:finance_buddy_app/design_system/design_system.dart';
import 'package:finance_buddy_app/providers/providers.dart';
import 'package:finance_buddy_app/utils/currency_utils.dart';

import 'home_format_helpers.dart';

class QuickStatsRow extends ConsumerWidget {
  const QuickStatsRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incomeAsync = ref.watch(monthlyIncomeProvider);
    final expenseAsync = ref.watch(monthlyExpenseProvider);
    final month = ref.watch(selectedMonthProvider);
    final currencyAsync = ref.watch(selectedCurrencyProvider);
    final symbol = currencySymbol(currencyAsync.valueOrNull ?? 'inr');

    final income = incomeAsync.valueOrNull ?? 0;
    final expense = expenseAsync.valueOrNull ?? 0;
    final netFlow = income - expense;

    // Average expense per elapsed day of the selected month.
    final now = DateTime.now();
    final isCurrentMonth = month.year == now.year && month.month == now.month;
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final elapsed = isCurrentMonth ? now.day : daysInMonth;
    final avgPerDay = elapsed > 0 ? expense / elapsed : 0;

    String money(num v) => '$symbol${formatHomeNumber(v.toDouble())}';
    final hasIncome = !incomeAsync.isLoading && incomeAsync.hasValue;
    final hasExpense = !expenseAsync.isLoading && expenseAsync.hasValue;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Income
          Expanded(
            child: StatTile(
              icon: Icon(PhosphorIcons.arrowUpRight(PhosphorIconsStyle.bold),
                  color: AppColors.catGreenText),
              label: 'Income',
              value: hasIncome ? money(income) : '—',
            ),
          ),
          const SizedBox(width: 10),
          // Net flow (tap → report tab)
          Expanded(
            child: GestureDetector(
              onTap: () => ref.read(selectedTabProvider.notifier).state = 1,
              child: StatTile(
                icon: Icon(PhosphorIcons.pulse(PhosphorIconsStyle.bold),
                    color: AppColors.black),
                label: 'Net flow',
                value: (hasIncome && hasExpense)
                    ? '${netFlow >= 0 ? '+' : '-'}${money(netFlow.abs())}'
                    : '—',
                valueColor:
                    netFlow >= 0 ? AppColors.catGreenText : AppColors.black,
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Avg / day
          Expanded(
            child: StatTile(
              icon: Icon(PhosphorIcons.calendarBlank(PhosphorIconsStyle.bold),
                  color: AppColors.black),
              label: 'Avg / day',
              value: hasExpense ? money(avgPerDay) : '—',
            ),
          ),
        ],
      ),
    );
  }
}
