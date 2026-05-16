import 'package:finance_buddy_app/services/import/models/processed_transaction.dart';

/// Detects anomalous transactions per category using IQR-based outlier detection.
/// Flags transactions above Q3 + 1.5*IQR as anomalies.
///
/// Does NOT change category — only sets isAnomaly flag.
/// Operates purely on in-memory data — safe for isolate use.
class AnomalyDetector {
  /// IQR multiplier for outlier threshold.
  static const _iqrMultiplier = 1.5;

  /// Minimum transactions per category to compute stats.
  static const _minSampleSize = 5;

  /// Detect anomalies and return updated transactions with isAnomaly flag.
  ///
  /// [newTransactions] — freshly imported (already categorized).
  /// [historicalTransactions] — last 6 months from DB for baseline.
  List<ProcessedTransaction> detect({
    required List<ProcessedTransaction> newTransactions,
    required List<ProcessedTransaction> historicalTransactions,
  }) {
    // Combine all for stats computation.
    final allTxns = [...historicalTransactions, ...newTransactions];

    // Group by category and compute thresholds.
    final thresholds = <String, double>{};
    final categoryGroups = <String, List<double>>{};

    for (final txn in allTxns) {
      if (txn.category == null) continue;
      // Only consider debits for anomaly detection.
      if (txn.type != 'debit') continue;
      categoryGroups.putIfAbsent(txn.category!, () => []).add(txn.amount);
    }

    for (final entry in categoryGroups.entries) {
      final amounts = entry.value..sort();
      if (amounts.length < _minSampleSize) continue;
      thresholds[entry.key] = _computeThreshold(amounts);
    }

    // Flag new transactions that exceed their category's threshold.
    return newTransactions.map((txn) {
      if (txn.category == null || txn.type != 'debit') return txn;
      final threshold = thresholds[txn.category];
      if (threshold == null) return txn;
      if (txn.amount > threshold) {
        return txn.copyWith(isAnomaly: true);
      }
      return txn;
    }).toList();
  }

  /// Compute Q3 + 1.5*IQR threshold from sorted amounts.
  double _computeThreshold(List<double> sortedAmounts) {
    final n = sortedAmounts.length;
    final q1 = sortedAmounts[n ~/ 4];
    final q3 = sortedAmounts[(3 * n) ~/ 4];
    final iqr = q3 - q1;
    return q3 + _iqrMultiplier * iqr;
  }
}
