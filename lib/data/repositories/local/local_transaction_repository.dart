import 'package:drift/drift.dart';
import 'package:finance_buddy_app/data/db.dart';
import 'package:finance_buddy_app/data/repositories/transaction_repository.dart';

class LocalTransactionRepository implements TransactionRepository {
  final PaisaDatabase db;

  LocalTransactionRepository(this.db);

  @override
  Stream<List<PaisaTransaction>> watchTransactionsForWeek(DateTime weekStart) {
    final weekEnd = weekStart.add(const Duration(days: 7));
    return (db.select(db.paisaTransactions)
          ..where((t) => t.happenedAt.isBiggerOrEqualValue(weekStart) &
              t.happenedAt.isSmallerThanValue(weekEnd))
          ..orderBy([(t) => OrderingTerm.desc(t.happenedAt)]))
        .watch();
  }

  @override
  Stream<List<PaisaTransaction>> watchUnconfirmed() {
    return (db.select(db.paisaTransactions)
          ..where((t) => t.status.equals('unconfirmed'))
          ..orderBy([(t) => OrderingTerm.desc(t.happenedAt)]))
        .watch();
  }

  @override
  Stream<List<PaisaTransaction>> watchAll() {
    return (db.select(db.paisaTransactions)
          ..orderBy([(t) => OrderingTerm.desc(t.happenedAt)]))
        .watch();
  }

  @override
  Future<List<PaisaTransaction>> getTransactionsForDay(DateTime day) {
    final dayStart = DateTime(day.year, day.month, day.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    return (db.select(db.paisaTransactions)
          ..where((t) => t.happenedAt.isBiggerOrEqualValue(dayStart) &
              t.happenedAt.isSmallerThanValue(dayEnd))
          ..orderBy([(t) => OrderingTerm.desc(t.happenedAt)]))
        .get();
  }

  @override
  Future<List<PaisaTransaction>> getTransactionsForMonth(DateTime month) {
    final monthStart = DateTime(month.year, month.month);
    final monthEnd = DateTime(month.year, month.month + 1);
    return (db.select(db.paisaTransactions)
          ..where((t) => t.happenedAt.isBiggerOrEqualValue(monthStart) &
              t.happenedAt.isSmallerThanValue(monthEnd))
          ..orderBy([(t) => OrderingTerm.desc(t.happenedAt)]))
        .get();
  }

  @override
  Future<int> getUnconfirmedCount() async {
    final result = await (db.select(db.paisaTransactions)
          ..where((t) => t.status.equals('unconfirmed')))
        .get();
    return result.length;
  }

  @override
  Future<int> insertTransaction(PaisaTransactionsCompanion entry) {
    return db.into(db.paisaTransactions).insert(entry);
  }

  @override
  Future<void> confirmTransaction(int id) {
    return (db.update(db.paisaTransactions)..where((t) => t.id.equals(id)))
        .write(const PaisaTransactionsCompanion(status: Value('confirmed')));
  }

  @override
  Future<void> updateTransaction(int id, PaisaTransactionsCompanion entry) {
    return (db.update(db.paisaTransactions)..where((t) => t.id.equals(id)))
        .write(entry);
  }

  @override
  Future<void> deleteTransaction(int id) {
    return (db.delete(db.paisaTransactions)..where((t) => t.id.equals(id)))
        .go();
  }

  @override
  Future<void> markSplit(int id, int splitCount, double myShare, double pendingAmount) {
    return (db.update(db.paisaTransactions)..where((t) => t.id.equals(id)))
        .write(PaisaTransactionsCompanion(
      isSplit: const Value(true),
      splitCount: Value(splitCount),
      splitMyShare: Value(myShare),
      splitPendingAmount: Value(pendingAmount),
      splitSettled: const Value(false),
    ));
  }

  @override
  Future<void> settleSplit(int id) {
    return (db.update(db.paisaTransactions)..where((t) => t.id.equals(id)))
        .write(const PaisaTransactionsCompanion(
      splitSettled: Value(true),
      splitPendingAmount: Value(0),
    ));
  }

  @override
  Future<List<PaisaTransaction>> getUnsettledSplits() {
    return (db.select(db.paisaTransactions)
          ..where((t) =>
              t.isSplit.equals(true) & t.splitSettled.equals(false)))
        .get();
  }

  @override
  Future<Map<String, double>> getCategoryTotalsForMonth(DateTime month) async {
    final monthStart = DateTime(month.year, month.month);
    final monthEnd = DateTime(month.year, month.month + 1);
    final txns = await (db.select(db.paisaTransactions)
          ..where((t) =>
              t.happenedAt.isBiggerOrEqualValue(monthStart) &
              t.happenedAt.isSmallerThanValue(monthEnd) &
              t.amount.isSmallerThanValue(0)))
        .get();

    final totals = <String, double>{};
    for (final t in txns) {
      totals[t.category] = (totals[t.category] ?? 0) + t.amount.abs();
    }
    return totals;
  }

  @override
  Future<List<double>> getWeeklySpendingTrend(int weekCount) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final currentWeekday = today.weekday; // 1=Mon, 7=Sun
    final thisMonday = today.subtract(Duration(days: currentWeekday - 1));

    final rangeStart = thisMonday.subtract(Duration(days: (weekCount - 1) * 7));
    final rangeEnd = thisMonday.add(const Duration(days: 7));

    // Single query for all expense transactions in the full date range
    final txns = await (db.select(db.paisaTransactions)
          ..where((t) =>
              t.happenedAt.isBiggerOrEqualValue(rangeStart) &
              t.happenedAt.isSmallerThanValue(rangeEnd) &
              t.amount.isSmallerThanValue(0)))
        .get();

    // Group by week in Dart
    final results = List<double>.filled(weekCount, 0);
    for (final t in txns) {
      final daysSinceRangeStart = t.happenedAt.difference(rangeStart).inDays;
      final weekIndex = daysSinceRangeStart ~/ 7;
      if (weekIndex >= 0 && weekIndex < weekCount) {
        results[weekIndex] += t.amount.abs();
      }
    }
    return results;
  }

  @override
  Future<void> confirmAllUnconfirmed() async {
    await (db.update(db.paisaTransactions)
          ..where((t) => t.status.equals('unconfirmed')))
        .write(const PaisaTransactionsCompanion(status: Value('confirmed')));
  }

  @override
  Future<Map<String, List<double>>> getHeatmapData() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final fourWeeksAgo = today.subtract(const Duration(days: 28));
    final currentWeekday = today.weekday;
    final thisMonday = today.subtract(Duration(days: currentWeekday - 1));

    final txns = await (db.select(db.paisaTransactions)
          ..where((t) =>
              t.happenedAt.isBiggerOrEqualValue(fourWeeksAgo) &
              t.happenedAt.isSmallerThanValue(today.add(const Duration(days: 1))) &
              t.amount.isSmallerThanValue(0) &
              t.status.equals('confirmed')))
        .get();

    // Group by category → week index (0=oldest, 3=this week)
    final result = <String, List<double>>{};
    final categories = ['rent', 'transport', 'food', 'family', 'social', 'other'];
    for (final cat in categories) {
      result[cat] = List.filled(4, 0.0);
    }

    for (final t in txns) {
      final daysSinceThisMonday = t.happenedAt.difference(thisMonday).inDays;
      int weekIndex;
      if (daysSinceThisMonday >= 0) {
        weekIndex = 3; // this week
      } else {
        weekIndex = 3 + (daysSinceThisMonday ~/ 7); // negative division
        if (daysSinceThisMonday % 7 != 0) weekIndex--; // floor for negatives
        weekIndex = weekIndex.clamp(0, 3);
      }

      final cat = result.containsKey(t.category) ? t.category : 'other';
      result[cat]![weekIndex] += t.amount.abs();
    }

    // Remove categories with all zeros
    result.removeWhere((_, v) => v.every((e) => e == 0));
    return result;
  }

  @override
  Future<double> getTotalSpentForWeek(DateTime weekStart) async {
    final weekEnd = weekStart.add(const Duration(days: 7));
    final txns = await (db.select(db.paisaTransactions)
          ..where((t) =>
              t.happenedAt.isBiggerOrEqualValue(weekStart) &
              t.happenedAt.isSmallerThanValue(weekEnd) &
              t.amount.isSmallerThanValue(0)))
        .get();
    return txns.fold<double>(0, (sum, t) => sum + t.amount.abs());
  }

  @override
  Future<double> getTodaySpending() async {
    final now = DateTime.now();
    final dayStart = DateTime(now.year, now.month, now.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    final txns = await (db.select(db.paisaTransactions)
          ..where((t) =>
              t.happenedAt.isBiggerOrEqualValue(dayStart) &
              t.happenedAt.isSmallerThanValue(dayEnd) &
              t.amount.isSmallerThanValue(0)))
        .get();
    return txns.fold<double>(0, (sum, t) => sum + t.amount.abs());
  }

  @override
  Future<String?> getTodayTopCategory() async {
    final now = DateTime.now();
    final dayStart = DateTime(now.year, now.month, now.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    final txns = await (db.select(db.paisaTransactions)
          ..where((t) =>
              t.happenedAt.isBiggerOrEqualValue(dayStart) &
              t.happenedAt.isSmallerThanValue(dayEnd) &
              t.amount.isSmallerThanValue(0)))
        .get();
    if (txns.isEmpty) return null;
    final totals = <String, double>{};
    for (final t in txns) {
      totals[t.category] = (totals[t.category] ?? 0) + t.amount.abs();
    }
    return totals.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  @override
  Future<double> getWeekOverWeekDelta() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final thisMonday = today.subtract(Duration(days: today.weekday - 1));
    final lastMonday = thisMonday.subtract(const Duration(days: 7));

    final thisWeek = await getTotalSpentForWeek(thisMonday);
    final lastWeek = await getTotalSpentForWeek(lastMonday);

    if (lastWeek == 0) return 0;
    return ((thisWeek - lastWeek) / lastWeek * 100);
  }

  @override
  Future<Map<String, int>> getTopMerchantCountsForWeek(DateTime weekStart) async {
    final weekEnd = weekStart.add(const Duration(days: 7));
    final txns = await (db.select(db.paisaTransactions)
          ..where((t) =>
              t.happenedAt.isBiggerOrEqualValue(weekStart) &
              t.happenedAt.isSmallerThanValue(weekEnd) &
              t.amount.isSmallerThanValue(0)))
        .get();
    final counts = <String, int>{};
    for (final t in txns) {
      final name = t.merchant ?? t.category;
      counts[name] = (counts[name] ?? 0) + 1;
    }
    return counts;
  }

  @override
  Future<List<double>> getCumulativeSpendingForMonth(DateTime month) async {
    final monthStart = DateTime(month.year, month.month);
    final monthEnd = DateTime(month.year, month.month + 1);
    final daysInMonth = monthEnd.difference(monthStart).inDays;

    final txns = await (db.select(db.paisaTransactions)
          ..where((t) =>
              t.happenedAt.isBiggerOrEqualValue(monthStart) &
              t.happenedAt.isSmallerThanValue(monthEnd) &
              t.amount.isSmallerThanValue(0))
          ..orderBy([(t) => OrderingTerm.asc(t.happenedAt)]))
        .get();

    // Build daily totals, then accumulate
    final daily = List<double>.filled(daysInMonth, 0);
    for (final t in txns) {
      final dayIndex = t.happenedAt.difference(monthStart).inDays;
      if (dayIndex >= 0 && dayIndex < daysInMonth) {
        daily[dayIndex] += t.amount.abs();
      }
    }

    // Cumulative
    final cumulative = List<double>.filled(daysInMonth, 0);
    cumulative[0] = daily[0];
    for (int i = 1; i < daysInMonth; i++) {
      cumulative[i] = cumulative[i - 1] + daily[i];
    }
    return cumulative;
  }

  @override
  Future<List<double>> getDayOfWeekAverages(int weekCount) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final rangeStart = today.subtract(Duration(days: weekCount * 7));

    final txns = await (db.select(db.paisaTransactions)
          ..where((t) =>
              t.happenedAt.isBiggerOrEqualValue(rangeStart) &
              t.happenedAt.isSmallerThanValue(today.add(const Duration(days: 1))) &
              t.amount.isSmallerThanValue(0)))
        .get();

    // Sum per day of week (Mon=0..Sun=6)
    final sums = List<double>.filled(7, 0);
    final counts = List<int>.filled(7, 0);
    for (final t in txns) {
      final dow = t.happenedAt.weekday - 1; // 1-based to 0-based
      sums[dow] += t.amount.abs();
      counts[dow]++;
    }

    // Average per occurrence (or per weekCount if no txns that day)
    return List.generate(7, (i) {
      if (counts[i] == 0) return 0;
      // Average = total / number of that weekday in range
      return sums[i] / weekCount;
    });
  }

  @override
  Future<List<MerchantStat>> getTopMerchants(int limit) async {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month);
    final txns = await (db.select(db.paisaTransactions)
          ..where((t) =>
              t.happenedAt.isBiggerOrEqualValue(monthStart) &
              t.amount.isSmallerThanValue(0)))
        .get();

    final stats = <String, _MerchantAccum>{};
    for (final t in txns) {
      final name = t.merchant ?? t.category;
      final a = stats.putIfAbsent(name, () => _MerchantAccum());
      a.count++;
      a.total += t.amount.abs();
    }

    final sorted = stats.entries.toList()
      ..sort((a, b) => b.value.count.compareTo(a.value.count));

    return sorted
        .take(limit)
        .map((e) => MerchantStat(e.key, e.value.count, e.value.total))
        .toList();
  }

  @override
  Future<Map<String, List<double>>> getMonthlyComparison() async {
    final now = DateTime.now();
    final thisMonthStart = DateTime(now.year, now.month);
    final lastMonthStart = DateTime(now.year, now.month - 1);
    final thisMonthEnd = DateTime(now.year, now.month + 1);

    final txns = await (db.select(db.paisaTransactions)
          ..where((t) =>
              t.happenedAt.isBiggerOrEqualValue(lastMonthStart) &
              t.happenedAt.isSmallerThanValue(thisMonthEnd) &
              t.amount.isSmallerThanValue(0)))
        .get();

    final categories = ['rent', 'transport', 'food', 'family', 'social', 'other'];
    final result = <String, List<double>>{};
    for (final cat in categories) {
      result[cat] = [0, 0]; // [thisMonth, lastMonth]
    }

    for (final t in txns) {
      final cat = result.containsKey(t.category) ? t.category : 'other';
      if (t.happenedAt.isBefore(thisMonthStart)) {
        result[cat]![1] += t.amount.abs(); // last month
      } else {
        result[cat]![0] += t.amount.abs(); // this month
      }
    }

    // Remove categories with all zeros
    result.removeWhere((_, v) => v[0] == 0 && v[1] == 0);
    return result;
  }

  @override
  Future<int> getStreakWeeksUnderTarget(double target) async {
    final weeklyTotals = await getWeeklySpendingTrend(12);
    // Walk backward from the most recent completed week (index 10, since 11 is current)
    int streak = 0;
    for (int i = weeklyTotals.length - 2; i >= 0; i--) {
      if (weeklyTotals[i] < target) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  @override
  Future<List<String>> getWeeklyAlerts({double singleTxnThreshold = 2000}) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final thisMonday = today.subtract(Duration(days: today.weekday - 1));
    final nextMonday = thisMonday.add(const Duration(days: 7));

    // Get this week's expense transactions
    final thisWeekTxns = await (db.select(db.paisaTransactions)
          ..where((t) =>
              t.happenedAt.isBiggerOrEqualValue(thisMonday) &
              t.happenedAt.isSmallerThanValue(nextMonday) &
              t.amount.isSmallerThanValue(0)))
        .get();

    // Category totals for this week
    final thisWeekCatTotals = <String, double>{};
    for (final t in thisWeekTxns) {
      thisWeekCatTotals[t.category] =
          (thisWeekCatTotals[t.category] ?? 0) + t.amount.abs();
    }

    // Get last 4 weeks of transactions (excluding this week)
    final fourWeeksAgo = thisMonday.subtract(const Duration(days: 28));
    final pastTxns = await (db.select(db.paisaTransactions)
          ..where((t) =>
              t.happenedAt.isBiggerOrEqualValue(fourWeeksAgo) &
              t.happenedAt.isSmallerThanValue(thisMonday) &
              t.amount.isSmallerThanValue(0)))
        .get();

    // Category averages over 4 weeks
    final pastCatTotals = <String, double>{};
    for (final t in pastTxns) {
      pastCatTotals[t.category] =
          (pastCatTotals[t.category] ?? 0) + t.amount.abs();
    }
    final pastCatAverages = <String, double>{};
    for (final entry in pastCatTotals.entries) {
      pastCatAverages[entry.key] = entry.value / 4;
    }

    final alerts = <String>[];

    // Category anomalies (prioritized)
    for (final entry in thisWeekCatTotals.entries) {
      final avg = pastCatAverages[entry.key];
      if (avg != null && avg > 0 && entry.value > 2 * avg) {
        final ratio = (entry.value / avg).toStringAsFixed(1);
        alerts.add('${entry.key} ${ratio}x higher than your 4-week average');
      }
    }

    // Sort category alerts by ratio descending
    alerts.sort((a, b) {
      final ratioA = double.tryParse(a.split(' ')[1].replaceAll('x', '')) ?? 0;
      final ratioB = double.tryParse(b.split(' ')[1].replaceAll('x', '')) ?? 0;
      return ratioB.compareTo(ratioA);
    });

    // Large single transaction alert
    if (thisWeekTxns.isNotEmpty) {
      final largest = thisWeekTxns.reduce(
          (a, b) => a.amount.abs() > b.amount.abs() ? a : b);
      if (largest.amount.abs() > singleTxnThreshold) {
        final merchant = largest.merchant ?? largest.category;
        alerts.add(
            'Large: \u20B9${largest.amount.abs().toStringAsFixed(0)} at $merchant');
      }
    }

    // Return at most 2 alerts, prioritizing category anomalies
    return alerts.take(2).toList();
  }
}

class _MerchantAccum {
  int count = 0;
  double total = 0;
}
