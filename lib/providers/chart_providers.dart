import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finance_buddy_app/providers/database_providers.dart';

// ─── State: selected week for daily chart on home ────────

final selectedWeekStartProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  // Start of current week (Monday)
  return DateTime(now.year, now.month, now.day - (now.weekday - 1));
});

// ─── Daily spending for a given week (7 values, Mon–Sun) ─

final dailySpendingForWeekProvider =
    FutureProvider.autoDispose<List<double>>((ref) async {
  final weekStart = ref.watch(selectedWeekStartProvider);
  final repo = ref.watch(repositoryProvider);

  final weekEnd = weekStart.add(const Duration(days: 7));
  final allTxns = await repo.watchAll().first;
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

// ─── Weekly totals for a month (4–5 weeks) ───────────────

final selectedChartMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month);
});

final weeklyTotalsForMonthProvider =
    FutureProvider.autoDispose<List<double>>((ref) async {
  final month = ref.watch(selectedChartMonthProvider);
  final repo = ref.watch(repositoryProvider);
  final txns = await repo.getTransactionsForMonth(month);
  final expenses = txns.where((t) => t.amount < 0);

  final weekTotals = <double>[0, 0, 0, 0];

  for (final t in expenses) {
    final dayOfMonth = t.happenedAt.day;
    final weekIndex = ((dayOfMonth - 1) / 7).floor().clamp(0, 3);
    weekTotals[weekIndex] += t.amount.abs();
  }
  return weekTotals;
});

// ─── Monthly totals for a year (12 values, Jan–Dec) ──────

final selectedChartYearProvider = StateProvider<int>((ref) {
  return DateTime.now().year;
});

final monthlyTotalsForYearProvider =
    FutureProvider.autoDispose<List<double>>((ref) async {
  final year = ref.watch(selectedChartYearProvider);
  final repo = ref.watch(repositoryProvider);
  final allTxns = await repo.watchAll().first;

  final monthly = List<double>.filled(12, 0);
  for (final t in allTxns) {
    if (t.happenedAt.year == year && t.amount < 0) {
      monthly[t.happenedAt.month - 1] += t.amount.abs();
    }
  }
  return monthly;
});

// ─── Yearly totals (one bar per year with data) ──────────

final yearlyTotalsProvider =
    FutureProvider.autoDispose<Map<int, double>>((ref) async {
  final repo = ref.watch(repositoryProvider);
  final allTxns = await repo.watchAll().first;

  final yearly = <int, double>{};
  for (final t in allTxns) {
    if (t.amount < 0) {
      yearly[t.happenedAt.year] =
          (yearly[t.happenedAt.year] ?? 0) + t.amount.abs();
    }
  }
  return yearly;
});
