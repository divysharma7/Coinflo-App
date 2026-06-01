import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:finance_buddy_app/design_system/design_system.dart';
import 'package:finance_buddy_app/providers/providers.dart';

import 'package:finance_buddy_app/pages/report/widgets/report_scope.dart';

// ─── Period Navigator ───────────────────────────────────

class PeriodNavigator extends ConsumerWidget {
  const PeriodNavigator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scope = ref.watch(reportScopeProvider);
    final month = ref.watch(reportMonthProvider);
    final year = ref.watch(selectedChartYearProvider);

    String label;
    switch (scope) {
      case ReportScope.week:
        label = DateFormat('MMMM yyyy').format(month);
      case ReportScope.month:
        label = '$year';
      case ReportScope.year:
        label = 'All Time';
    }

    final canForward = _canForward(scope, month, year);
    final showNav = scope != ReportScope.year;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (showNav)
            GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                _navigate(ref, -1, scope, month, year);
              },
              child: const Icon(Icons.chevron_left, color: AppColors.gray500, size: 28),
            )
          else
            const SizedBox(width: 28),
          Text(label, style: AppTextStyles.headingS.copyWith(color: AppColors.black)),
          if (showNav)
            GestureDetector(
              onTap: canForward
                  ? () {
                      HapticFeedback.selectionClick();
                      _navigate(ref, 1, scope, month, year);
                    }
                  : null,
              child: Icon(Icons.chevron_right,
                  color: canForward ? AppColors.gray500 : AppColors.gray200,
                  size: 28),
            )
          else
            const SizedBox(width: 28),
        ],
      ),
    );
  }

  void _navigate(WidgetRef ref, int dir, ReportScope scope, DateTime month, int year) {
    switch (scope) {
      case ReportScope.week:
        final next = DateTime(month.year, month.month + dir);
        ref.read(reportMonthProvider.notifier).state = next;
        ref.read(selectedChartMonthProvider.notifier).state = next;
      case ReportScope.month:
        ref.read(selectedChartYearProvider.notifier).state = year + dir;
      case ReportScope.year:
        break;
    }
  }

  bool _canForward(ReportScope scope, DateTime month, int year) {
    final now = DateTime.now();
    switch (scope) {
      case ReportScope.week:
        final next = DateTime(month.year, month.month + 1);
        return next.isBefore(now) || (next.month == now.month && next.year == now.year);
      case ReportScope.month:
        return year < now.year;
      case ReportScope.year:
        return false;
    }
  }
}
