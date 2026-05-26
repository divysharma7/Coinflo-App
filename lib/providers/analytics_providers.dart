import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finance_buddy_app/data/repositories/transaction_repository.dart';
import 'package:finance_buddy_app/providers/database_providers.dart';
import 'package:finance_buddy_app/providers/onboarding_provider.dart';

/// Cumulative spending for this month (day-by-day running total).
final thisMonthCumulativeProvider = FutureProvider<List<double>>((ref) {
  final repo = ref.watch(repositoryProvider);
  final now = DateTime.now();
  return repo.getCumulativeSpendingForMonth(DateTime(now.year, now.month));
});

/// Cumulative spending for last month.
final lastMonthCumulativeProvider = FutureProvider<List<double>>((ref) {
  final repo = ref.watch(repositoryProvider);
  final now = DateTime.now();
  return repo.getCumulativeSpendingForMonth(DateTime(now.year, now.month - 1));
});

/// Average spending per day of week over last 4 weeks.
final dayOfWeekAveragesProvider = FutureProvider<List<double>>((ref) {
  final repo = ref.watch(repositoryProvider);
  return repo.getDayOfWeekAverages(4);
});

/// Top 7 merchants by frequency this month.
final topMerchantsProvider = FutureProvider<List<MerchantStat>>((ref) {
  final repo = ref.watch(repositoryProvider);
  return repo.getTopMerchants(7);
});

/// Category comparison: this month vs last month.
final monthlyComparisonProvider =
    FutureProvider<Map<String, List<double>>>((ref) {
  final repo = ref.watch(repositoryProvider);
  return repo.getMonthlyComparison();
});

/// Consecutive completed weeks where spending was under the user's target.
final streakProvider = FutureProvider<int>((ref) async {
  final repo = ref.watch(repositoryProvider);
  final target = await ref.watch(spendingTargetProvider.future);
  if (target == null || target <= 0) return 0;
  return repo.getStreakWeeksUnderTarget(target);
});

/// Weekly alerts for unusual spending patterns (max 2).
final weeklyAlertsProvider = FutureProvider<List<String>>((ref) {
  final repo = ref.watch(repositoryProvider);
  return repo.getWeeklyAlerts();
});

// ─── Computed analytics providers ───────────────────

/// Month-end spending projection using last month's spending shape when
/// available, falling back to linear extrapolation for new users.
class MonthProjection {
  final double spentSoFar;
  final double projected;
  final int daysLeft;
  final int? percentVsLast;
  /// True when we have < 5 days of data — too early for a meaningful forecast.
  final bool isSparse;
  /// True when the projection used last month's spending shape instead of
  /// naive linear extrapolation.
  final bool usedShape;
  const MonthProjection({
    required this.spentSoFar,
    required this.projected,
    required this.daysLeft,
    this.percentVsLast,
    this.isSparse = false,
    this.usedShape = false,
  });
}

final monthEndProjectionProvider = FutureProvider<MonthProjection?>((ref) async {
  final thisData = await ref.watch(thisMonthCumulativeProvider.future);
  if (thisData.isEmpty) return null;

  final lastData = await ref.watch(lastMonthCumulativeProvider.future);

  final today = DateTime.now().day;
  final spentSoFar = thisData[today - 1];
  final daysLeft = thisData.length - today;
  final lastTotal = lastData.isNotEmpty ? lastData.last : 0.0;

  double projected;
  bool usedShape = false;

  // Use last month's spending shape if we have enough history.
  // Shape-based: if last month 60% was spent by day 10, and this month
  // we've spent X by day 10, project X / 0.6. This accounts for
  // front-loaded spending patterns (rent, subscriptions on day 1).
  if (lastData.isNotEmpty && lastData.length >= today && lastTotal > 0) {
    final fractionByThisDay = lastData[today - 1] / lastTotal;
    if (fractionByThisDay > 0.05) {
      projected = spentSoFar / fractionByThisDay;
      usedShape = true;
    } else {
      final dailyRate = today > 0 ? spentSoFar / today : 0.0;
      projected = spentSoFar + (dailyRate * daysLeft);
    }
  } else {
    final dailyRate = today > 0 ? spentSoFar / today : 0.0;
    projected = spentSoFar + (dailyRate * daysLeft);
  }

  int? percentVsLast;
  if (lastTotal > 0 && projected > 0) {
    percentVsLast = ((projected - lastTotal) / lastTotal * 100).round();
  }

  return MonthProjection(
    spentSoFar: spentSoFar,
    projected: projected,
    daysLeft: daysLeft,
    percentVsLast: percentVsLast,
    isSparse: today < 5,
    usedShape: usedShape,
  );
});

/// Invalidates all analytics providers so widgets refresh after writes.
void invalidateAnalytics(dynamic ref) {
  ref.invalidate(thisMonthCumulativeProvider);
  ref.invalidate(lastMonthCumulativeProvider);
  ref.invalidate(dayOfWeekAveragesProvider);
  ref.invalidate(topMerchantsProvider);
  ref.invalidate(monthlyComparisonProvider);
  ref.invalidate(monthEndProjectionProvider);
  ref.invalidate(streakProvider);
  ref.invalidate(weeklyAlertsProvider);
}
