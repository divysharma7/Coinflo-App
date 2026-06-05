import 'package:finance_buddy_app/data/db.dart';

class MerchantStat {
  final String name;
  final int count;
  final double total;
  const MerchantStat(this.name, this.count, this.total);
}

abstract class TransactionRepository {
  Stream<List<SpendlerTransaction>> watchTransactionsForWeek(DateTime weekStart);
  Stream<List<SpendlerTransaction>> watchUnconfirmed();
  Stream<List<SpendlerTransaction>> watchAll();
  Future<SpendlerTransaction?> getById(int id);
  Future<List<SpendlerTransaction>> getTransactionsForDay(DateTime day);
  Future<List<SpendlerTransaction>> getTransactionsForMonth(DateTime month);

  /// Reactive variant of [getTransactionsForMonth] — emits a fresh list
  /// whenever the underlying table changes (e.g. a transaction is added).
  Stream<List<SpendlerTransaction>> watchTransactionsForMonth(DateTime month);
  Future<int> getUnconfirmedCount();
  Future<int> insertTransaction(SpendlerTransactionsCompanion entry);
  Future<void> confirmTransaction(int id);
  Future<void> updateTransaction(int id, SpendlerTransactionsCompanion entry);
  Future<void> deleteTransaction(int id);
  Future<void> markSplit(int id, int splitCount, double myShare, double pendingAmount);
  Future<void> settleSplit(int id);
  Future<List<SpendlerTransaction>> getUnsettledSplits();
  Future<Map<String, double>> getCategoryTotalsForMonth(DateTime month);

  /// Reactive variant of [getCategoryTotalsForMonth] — emits fresh category
  /// totals whenever the underlying table changes (add/edit/delete), so report
  /// aggregates stay live regardless of which screen triggered the write.
  Stream<Map<String, double>> watchCategoryTotalsForMonth(DateTime month);
  Future<List<double>> getWeeklySpendingTrend(int weekCount);
  Future<double> getTotalSpentForWeek(DateTime weekStart);
  Future<void> confirmAllUnconfirmed();
  Future<Map<String, List<double>>> getHeatmapData();
  Future<double> getTodaySpending();
  Future<String?> getTodayTopCategory();
  Future<double> getWeekOverWeekDelta();
  Future<Map<String, int>> getTopMerchantCountsForWeek(DateTime weekStart);

  /// Cumulative daily spending for a given month. Returns list of (day, cumulative total).
  Future<List<double>> getCumulativeSpendingForMonth(DateTime month);

  /// Average spending per day of week (Mon=0..Sun=6) over the last N weeks.
  Future<List<double>> getDayOfWeekAverages(int weekCount);

  /// Top merchants ranked by frequency, returns {merchant: {count, total}}.
  Future<List<MerchantStat>> getTopMerchants(int limit);

  /// Category totals for two months for comparison. Returns {category: [thisMonth, lastMonth]}.
  Future<Map<String, List<double>>> getMonthlyComparison();

  /// Consecutive completed weeks where total spending was under [target].
  Future<int> getStreakWeeksUnderTarget(double target);

  /// Alerts for unusual spending patterns this week (max 2).
  Future<List<String>> getWeeklyAlerts({double singleTxnThreshold = 2000});
}
