import 'package:flutter_test/flutter_test.dart';
import 'package:finance_buddy_app/core/enums.dart';
import 'package:finance_buddy_app/services/detection/recurring_detector.dart';
import 'package:finance_buddy_app/services/import/models/processed_transaction.dart';

ProcessedTransaction _makeTxn({
  required DateTime date,
  required double amount,
  required String merchantToken,
  String? category,
}) {
  return ProcessedTransaction(
    date: date,
    amount: amount,
    type: 'debit',
    rawDescription: 'test $merchantToken',
    cleanedDescription: 'test $merchantToken',
    merchantToken: merchantToken,
    channel: 'other',
    rawHash: '${date.toIso8601String()}_${amount}_$merchantToken',
    sourceBank: BankType.hdfc,
    category: category,
    categorizationSource: category != null
        ? CategorizationSource.dictionary
        : CategorizationSource.uncategorized,
    categorizationConfidence: category != null ? 0.9 : 0.0,
  );
}

void main() {
  late RecurringDetector detector;

  setUp(() {
    detector = RecurringDetector();
  });

  group('Monthly cadence detection', () {
    test('detects monthly subscription with stable amount', () {
      final txns = [
        _makeTxn(date: DateTime(2026, 1, 1), amount: 499, merchantToken: 'netflix'),
        _makeTxn(date: DateTime(2026, 2, 1), amount: 499, merchantToken: 'netflix'),
        _makeTxn(date: DateTime(2026, 3, 1), amount: 499, merchantToken: 'netflix'),
      ];

      final result = detector.detect(newTransactions: txns, historicalTransactions: []);
      final recurring = result.where((t) => t.isRecurring).toList();

      expect(recurring.length, 3);
    });

    test('detects monthly EMI', () {
      final txns = [
        _makeTxn(date: DateTime(2026, 1, 15), amount: 25000, merchantToken: 'hdfcloan'),
        _makeTxn(date: DateTime(2026, 2, 15), amount: 25000, merchantToken: 'hdfcloan'),
        _makeTxn(date: DateTime(2026, 3, 15), amount: 25000, merchantToken: 'hdfcloan'),
      ];

      final result = detector.detect(newTransactions: txns, historicalTransactions: []);
      expect(result.every((t) => t.isRecurring), isTrue);
    });

    test('uses historical transactions for cadence analysis', () {
      final historical = [
        _makeTxn(date: DateTime(2025, 11, 1), amount: 199, merchantToken: 'spotify'),
        _makeTxn(date: DateTime(2025, 12, 1), amount: 199, merchantToken: 'spotify'),
      ];
      final newTxns = [
        _makeTxn(date: DateTime(2026, 1, 1), amount: 199, merchantToken: 'spotify'),
      ];

      final result = detector.detect(
        newTransactions: newTxns,
        historicalTransactions: historical,
      );

      // With 3 total occurrences (2 historical + 1 new), should detect recurring.
      expect(result[0].isRecurring, isTrue);
    });
  });

  group('Amount stability', () {
    test('rejects irregular amounts', () {
      final txns = [
        _makeTxn(date: DateTime(2026, 1, 1), amount: 500, merchantToken: 'random'),
        _makeTxn(date: DateTime(2026, 2, 1), amount: 1200, merchantToken: 'random'),
        _makeTxn(date: DateTime(2026, 3, 1), amount: 300, merchantToken: 'random'),
      ];

      final result = detector.detect(newTransactions: txns, historicalTransactions: []);
      final recurring = result.where((t) => t.isRecurring).toList();

      expect(recurring, isEmpty);
    });

    test('allows small amount variation (within 10%)', () {
      final txns = [
        _makeTxn(date: DateTime(2026, 1, 1), amount: 500, merchantToken: 'gym'),
        _makeTxn(date: DateTime(2026, 2, 1), amount: 510, merchantToken: 'gym'),
        _makeTxn(date: DateTime(2026, 3, 1), amount: 495, merchantToken: 'gym'),
      ];

      final result = detector.detect(newTransactions: txns, historicalTransactions: []);
      expect(result.every((t) => t.isRecurring), isTrue);
    });
  });

  group('Non-recurring patterns', () {
    test('fewer than 3 occurrences → not recurring', () {
      final txns = [
        _makeTxn(date: DateTime(2026, 1, 1), amount: 499, merchantToken: 'netflix'),
        _makeTxn(date: DateTime(2026, 2, 1), amount: 499, merchantToken: 'netflix'),
      ];

      final result = detector.detect(newTransactions: txns, historicalTransactions: []);
      expect(result.every((t) => !t.isRecurring), isTrue);
    });

    test('irregular cadence → not recurring', () {
      final txns = [
        _makeTxn(date: DateTime(2026, 1, 1), amount: 500, merchantToken: 'store'),
        _makeTxn(date: DateTime(2026, 1, 15), amount: 500, merchantToken: 'store'),
        _makeTxn(date: DateTime(2026, 3, 20), amount: 500, merchantToken: 'store'),
      ];

      final result = detector.detect(newTransactions: txns, historicalTransactions: []);
      expect(result.every((t) => !t.isRecurring), isTrue);
    });
  });

  group('Auto-categorization', () {
    test('uncategorized recurring txns get auto-categorized', () {
      final txns = [
        _makeTxn(date: DateTime(2026, 1, 1), amount: 199, merchantToken: 'unknown', category: null),
        _makeTxn(date: DateTime(2026, 2, 1), amount: 199, merchantToken: 'unknown', category: null),
        _makeTxn(date: DateTime(2026, 3, 1), amount: 199, merchantToken: 'unknown', category: null),
      ];

      final result = detector.detect(newTransactions: txns, historicalTransactions: []);
      for (final t in result) {
        expect(t.category, 'entertainment');
      }
    });

    test('already categorized recurring txns keep their category', () {
      final txns = [
        _makeTxn(
            date: DateTime(2026, 1, 1), amount: 499, merchantToken: 'netflix', category: 'entertainment'),
        _makeTxn(
            date: DateTime(2026, 2, 1), amount: 499, merchantToken: 'netflix', category: 'entertainment'),
        _makeTxn(
            date: DateTime(2026, 3, 1), amount: 499, merchantToken: 'netflix', category: 'entertainment'),
      ];

      final result = detector.detect(newTransactions: txns, historicalTransactions: []);
      for (final t in result) {
        expect(t.category, 'entertainment');
        expect(t.isRecurring, isTrue);
      }
    });
  });
}
