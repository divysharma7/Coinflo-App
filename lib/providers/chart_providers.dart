import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finance_buddy_app/providers/database_providers.dart';

// ─── State: selected week for daily chart on home ────────

final selectedWeekStartProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  // Start of current week (Monday)
  return DateTime(now.year, now.month, now.day - (now.weekday - 1));
});

// ─── Daily spending for a given week (7 values, Mon–Sun) ─

// All chart providers below are StreamProviders backed by Drift `watch()` so
// they auto-refresh on any transaction write, regardless of the originating
// screen — no manual invalidation required. (ISSUE 11)
final dailySpendingForWeekProvider =
    StreamProvider.autoDispose<List<double>>((ref) {
  final weekStart = ref.watch(selectedWeekStartProvider);
  final repo = ref.watch(repositoryProvider);
  final weekEnd = weekStart.add(const Duration(days: 7));

  return repo.watchAll().map((allTxns) {
    final weekTxns = allTxns.where((t) =>
        t.happenedAt.isAfter(weekStart.subtract(const Duration(seconds: 1))) &&
        t.happenedAt.isBefore(weekEnd) &&
        t.amount < 0);

    final daily = List<double>.filled(7, 0);
    for (final t in weekTxns) {
      final dayIndex = t.happenedAt.weekday - 1; // Mon=0, Sun=6
      daily[dayIndex] += t.amount.abs();
    }
    return daily;
  });
});

// ─── Weekly totals for a month (4–5 weeks) ───────────────

final selectedChartMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month);
});

final weeklyTotalsForMonthProvider =
    StreamProvider.autoDispose<List<double>>((ref) {
  final month = ref.watch(selectedChartMonthProvider);
  final repo = ref.watch(repositoryProvider);

  return repo.watchTransactionsForMonth(month).map((txns) {
    final expenses = txns.where((t) => t.amount < 0);
    final weekTotals = <double>[0, 0, 0, 0];
    for (final t in expenses) {
      final dayOfMonth = t.happenedAt.day;
      final weekIndex = ((dayOfMonth - 1) / 7).floor().clamp(0, 3);
      weekTotals[weekIndex] += t.amount.abs();
    }
    return weekTotals;
  });
});

// ─── Monthly totals for a year (12 values, Jan–Dec) ──────

final selectedChartYearProvider = StateProvider<int>((ref) {
  return DateTime.now().year;
});

final monthlyTotalsForYearProvider =
    StreamProvider.autoDispose<List<double>>((ref) {
  final year = ref.watch(selectedChartYearProvider);
  final repo = ref.watch(repositoryProvider);

  return repo.watchAll().map((allTxns) {
    final monthly = List<double>.filled(12, 0);
    for (final t in allTxns) {
      if (t.happenedAt.year == year && t.amount < 0) {
        monthly[t.happenedAt.month - 1] += t.amount.abs();
      }
    }
    return monthly;
  });
});

// ─── Yearly totals (one bar per year with data) ──────────

final yearlyTotalsProvider =
    StreamProvider.autoDispose<Map<int, double>>((ref) {
  final repo = ref.watch(repositoryProvider);

  return repo.watchAll().map((allTxns) {
    final yearly = <int, double>{};
    for (final t in allTxns) {
      if (t.amount < 0) {
        yearly[t.happenedAt.year] =
            (yearly[t.happenedAt.year] ?? 0) + t.amount.abs();
      }
    }
    return yearly;
  });
});
