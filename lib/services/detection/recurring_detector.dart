import 'package:finance_buddy_app/core/enums.dart';
import 'package:finance_buddy_app/services/import/models/processed_transaction.dart';

/// Detects recurring transactions (subscriptions, EMIs) by analyzing
/// cadence patterns and amount stability across a merchant token group.
///
/// Operates purely on in-memory data — safe for isolate use.
class RecurringDetector {
  /// Monthly cadence: 28-32 day gaps.
  static const _monthlyMin = 26;
  static const _monthlyMax = 34;

  /// Weekly cadence: 6-8 day gaps.
  static const _weeklyMin = 5;
  static const _weeklyMax = 9;

  /// Minimum occurrences to consider a pattern recurring.
  static const _minOccurrences = 3;

  /// Percentage of gaps that must fit the cadence bucket (80%).
  static const _cadenceThreshold = 0.8;

  /// Amount stability: within ±10% of median.
  static const _amountTolerancePct = 0.10;

  /// Detect recurring patterns and return updated transactions with isRecurring flag.
  ///
  /// [newTransactions] — freshly imported transactions.
  /// [historicalTransactions] — last 90 days from DB (for cadence analysis).
  List<ProcessedTransaction> detect({
    required List<ProcessedTransaction> newTransactions,
    required List<ProcessedTransaction> historicalTransactions,
  }) {
    // Combine new + historical for pattern analysis.
    final allTxns = [...historicalTransactions, ...newTransactions];

    // Group by merchantToken.
    final groups = <String, List<ProcessedTransaction>>{};
    for (final txn in allTxns) {
      if (txn.merchantToken.isEmpty) continue;
      groups.putIfAbsent(txn.merchantToken, () => []).add(txn);
    }

    // Track which merchant tokens are recurring.
    final recurringTokens = <String>{};

    for (final entry in groups.entries) {
      final group = entry.value;
      if (group.length < _minOccurrences) continue;

      // Sort by date ascending.
      group.sort((a, b) => a.date.compareTo(b.date));

      // Compute time gaps between consecutive transactions.
      final gaps = <int>[];
      for (var i = 1; i < group.length; i++) {
        gaps.add(group[i].date.difference(group[i - 1].date).inDays);
      }

      // Check if 80%+ of gaps fall in monthly or weekly bucket.
      final isMonthly = _checkCadence(gaps, _monthlyMin, _monthlyMax);
      final isWeekly = !isMonthly && _checkCadence(gaps, _weeklyMin, _weeklyMax);

      if (!isMonthly && !isWeekly) continue;

      // Check amount stability (within ±10% of median).
      if (!_isAmountStable(group)) continue;

      recurringTokens.add(entry.key);
    }

    // Update only the NEW transactions (don't modify historical).
    return newTransactions.map((txn) {
      if (recurringTokens.contains(txn.merchantToken)) {
        return txn.copyWith(
          isRecurring: true,
          // If uncategorized, auto-assign to entertainment (subscriptions bucket).
          category: txn.category ?? 'entertainment',
          categorizationSource: txn.category == null
              ? CategorizationSource.rule
              : txn.categorizationSource,
          categorizationConfidence: txn.category == null
              ? 0.7
              : txn.categorizationConfidence,
        );
      }
      return txn;
    }).toList();
  }

  bool _checkCadence(List<int> gaps, int min, int max) {
    if (gaps.isEmpty) return false;
    final matchingCount = gaps.where((g) => g >= min && g <= max).length;
    return matchingCount / gaps.length >= _cadenceThreshold;
  }

  bool _isAmountStable(List<ProcessedTransaction> group) {
    final amounts = group.map((t) => t.amount).toList()..sort();
    final median = amounts[amounts.length ~/ 2];
    if (median == 0) return false;
    final tolerance = median * _amountTolerancePct;
    return amounts.every((a) => (a - median).abs() <= tolerance);
  }
}
