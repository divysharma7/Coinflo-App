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

/// Month-end spending projection based on current pace.
class MonthProjection {
  final double spentSoFar;
  final double projected;
  final int daysLeft;
  final int? percentVsLast;
  const MonthProjection({
    required this.spentSoFar,
    required this.projected,
    required this.daysLeft,
    this.percentVsLast,
  });
}

final monthEndProjectionProvider = FutureProvider<MonthProjection?>((ref) async {
  final thisData = await ref.watch(thisMonthCumulativeProvider.future);
  if (thisData.isEmpty) return null;

  final lastData = await ref.watch(lastMonthCumulativeProvider.future);

  final today = DateTime.now().day;
  final spentSoFar = thisData[today - 1];
  final daysLeft = thisData.length - today;
  final dailyRate = today > 0 ? spentSoFar / today : 0.0;
  final projected = spentSoFar + (dailyRate * daysLeft);
  final lastTotal = lastData.isNotEmpty ? lastData.last : 0.0;

  int? percentVsLast;
  if (lastTotal > 0 && projected > 0) {
    percentVsLast = ((projected - lastTotal) / lastTotal * 100).round();
  }

  return MonthProjection(
    spentSoFar: spentSoFar,
    projected: projected,
    daysLeft: daysLeft,
    percentVsLast: percentVsLast,
  );
});
