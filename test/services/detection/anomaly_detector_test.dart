import 'package:flutter_test/flutter_test.dart';
import 'package:finance_buddy_app/core/enums.dart';
import 'package:finance_buddy_app/services/detection/anomaly_detector.dart';
import 'package:finance_buddy_app/services/import/models/processed_transaction.dart';

ProcessedTransaction _makeTxn({
  required double amount,
  String category = 'foodAndDrink',
  String type = 'debit',
  bool isHistorical = false,
}) {
  return ProcessedTransaction(
    date: DateTime(2026, 1, 15),
    amount: amount,
    type: type,
    rawDescription: 'test',
    cleanedDescription: 'test',
    merchantToken: 'test',
    channel: 'other',
    rawHash: '${amount}_${isHistorical ? 'hist' : 'new'}_${DateTime.now().microsecondsSinceEpoch}',
    sourceBank: BankType.hdfc,
    category: category,
    categorizationSource: CategorizationSource.dictionary,
    categorizationConfidence: 0.9,
  );
}

void main() {
  late AnomalyDetector detector;

  setUp(() {
    detector = AnomalyDetector();
  });

  group('IQR-based anomaly detection', () {
    test('flags outliers above Q3 + 1.5*IQR', () {
      // Create a baseline of normal foodAndDrink transactions.
      final historical = List.generate(10, (i) => _makeTxn(
        amount: 200.0 + (i * 20), // 200 to 380
        isHistorical: true,
      ));

      // Add one extreme outlier in the new batch.
      final newTxns = [
        _makeTxn(amount: 250.0),   // Normal
        _makeTxn(amount: 5000.0),  // Outlier
      ];

      final result = detector.detect(
        newTransactions: newTxns,
        historicalTransactions: historical,
      );

      expect(result[0].isAnomaly, isFalse);
      expect(result[1].isAnomaly, isTrue);
    });

    test('does not flag normal transactions', () {
      final historical = List.generate(10, (i) => _makeTxn(
        amount: 300.0 + (i * 10),
        isHistorical: true,
      ));

      final newTxns = [
        _makeTxn(amount: 350.0),
        _makeTxn(amount: 320.0),
      ];

      final result = detector.detect(
        newTransactions: newTxns,
        historicalTransactions: historical,
      );

      expect(result.every((t) => !t.isAnomaly), isTrue);
    });

    test('does not change category of anomalous transactions', () {
      final historical = List.generate(10, (i) => _makeTxn(
        amount: 100.0 + (i * 5),
        isHistorical: true,
      ));

      final newTxns = [_makeTxn(amount: 10000.0)];

      final result = detector.detect(
        newTransactions: newTxns,
        historicalTransactions: historical,
      );

      expect(result[0].isAnomaly, isTrue);
      expect(result[0].category, 'foodAndDrink'); // Unchanged
    });
  });

  group('Per-category thresholds', () {
    test('different categories have independent thresholds', () {
      final historical = [
        ...List.generate(8, (i) => _makeTxn(
          amount: 200.0 + (i * 10), category: 'foodAndDrink', isHistorical: true,
        )),
        ...List.generate(8, (i) => _makeTxn(
          amount: 5000.0 + (i * 100), category: 'travel', isHistorical: true,
        )),
      ];

      final newTxns = [
        _makeTxn(amount: 800.0, category: 'foodAndDrink'),  // Outlier for food
        _makeTxn(amount: 6000.0, category: 'travel'),        // Normal for travel
      ];

      final result = detector.detect(
        newTransactions: newTxns,
        historicalTransactions: historical,
      );

      expect(result[0].isAnomaly, isTrue);  // Food outlier
      expect(result[1].isAnomaly, isFalse); // Travel normal
    });
  });

  group('Edge cases', () {
    test('skips categories with fewer than 5 samples', () {
      final historical = List.generate(3, (i) => _makeTxn(
        amount: 100.0, isHistorical: true,
      ));

      final newTxns = [_makeTxn(amount: 10000.0)];

      final result = detector.detect(
        newTransactions: newTxns,
        historicalTransactions: historical,
      );

      // Not enough samples — should not flag.
      expect(result[0].isAnomaly, isFalse);
    });

    test('skips credit transactions', () {
      final historical = List.generate(10, (i) => _makeTxn(
        amount: 100.0, isHistorical: true,
      ));

      final newTxns = [_makeTxn(amount: 85000.0, type: 'credit')];

      final result = detector.detect(
        newTransactions: newTxns,
        historicalTransactions: historical,
      );

      expect(result[0].isAnomaly, isFalse);
    });

    test('handles empty inputs', () {
      final result = detector.detect(
        newTransactions: [],
        historicalTransactions: [],
      );
      expect(result, isEmpty);
    });
  });
}
