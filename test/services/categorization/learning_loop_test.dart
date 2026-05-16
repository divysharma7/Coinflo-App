import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finance_buddy_app/data/db.dart';
import 'package:finance_buddy_app/services/categorization/learning_loop.dart';

void main() {
  late SpendlerDatabase db;
  late LearningLoop loop;

  setUp(() {
    db = SpendlerDatabase.forTesting(NativeDatabase.memory());
    loop = LearningLoop(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('correctCategory + backfill', () {
    late int txn1Id;
    late int txn2Id;
    late int txn3Id;
    late int swiggyId;

    setUp(() async {
      // Insert 3 uncategorized transactions with same merchantToken "bigbasket"
      txn1Id = await db.into(db.spendlerTransactions).insert(
            SpendlerTransactionsCompanion.insert(
              amount: 850.0,
              category: 'other',
              merchant: const Value('BigBasket'),
              merchantToken: const Value('bigbasket'),
              categorizationSource: const Value('uncategorized'),
              categorizationConfidence: const Value(0.0),
              importBatchId: const Value('batch-test'),
            ),
          );
      txn2Id = await db.into(db.spendlerTransactions).insert(
            SpendlerTransactionsCompanion.insert(
              amount: 1200.0,
              category: 'other',
              merchant: const Value('BigBasket'),
              merchantToken: const Value('bigbasket'),
              categorizationSource: const Value('uncategorized'),
              categorizationConfidence: const Value(0.0),
              importBatchId: const Value('batch-test'),
            ),
          );
      txn3Id = await db.into(db.spendlerTransactions).insert(
            SpendlerTransactionsCompanion.insert(
              amount: 650.0,
              category: 'other',
              merchant: const Value('BigBasket'),
              merchantToken: const Value('bigbasket'),
              categorizationSource: const Value('uncategorized'),
              categorizationConfidence: const Value(0.0),
              importBatchId: const Value('batch-test'),
            ),
          );

      // Insert 1 uncategorized transaction with different merchantToken "swiggy"
      swiggyId = await db.into(db.spendlerTransactions).insert(
            SpendlerTransactionsCompanion.insert(
              amount: 450.0,
              category: 'other',
              merchant: const Value('Swiggy'),
              merchantToken: const Value('swiggy'),
              categorizationSource: const Value('uncategorized'),
              categorizationConfidence: const Value(0.0),
              importBatchId: const Value('batch-test'),
            ),
          );
    });

    test('correcting first bigbasket txn backfills to other 2', () async {
      // Act: correct the first bigbasket transaction to foodAndDrink.
      final backfillCount = await loop.correctCategory(
        transactionId: txn1Id,
        newCategory: 'foodAndDrink',
      );

      // Assert: backfill count is 2 (the other 2 bigbasket txns, not counting the original).
      expect(backfillCount, 2);

      // All 3 bigbasket transactions should now have category = foodAndDrink.
      final bigbasketTxns = await (db.select(db.spendlerTransactions)
            ..where((t) => t.merchantToken.equals('bigbasket')))
          .get();
      for (final txn in bigbasketTxns) {
        expect(txn.category, 'foodAndDrink',
            reason: 'Transaction ${txn.id} should be foodAndDrink');
        expect(txn.categorizationSource, 'user');
        expect(txn.categorizationConfidence, 1.0);
      }
    });

    test('swiggy transaction is unchanged after bigbasket correction', () async {
      await loop.correctCategory(
        transactionId: txn1Id,
        newCategory: 'foodAndDrink',
      );

      final swiggyTxn = await (db.select(db.spendlerTransactions)
            ..where((t) => t.id.equals(swiggyId)))
          .getSingle();

      expect(swiggyTxn.category, 'other'); // Unchanged
      expect(swiggyTxn.categorizationSource, 'uncategorized'); // Unchanged
    });

    test('creates MerchantMapping with userCorrected source', () async {
      await loop.correctCategory(
        transactionId: txn1Id,
        newCategory: 'foodAndDrink',
      );

      final mappings = await (db.select(db.merchantMappings)
            ..where((m) => m.merchantToken.equals('bigbasket')))
          .get();

      expect(mappings.length, 1);
      expect(mappings.first.category, 'foodAndDrink');
      expect(mappings.first.source, 'userCorrected');
      expect(mappings.first.confidence, 1.0);
    });

    test('creates CorrectionEvent with correct backfillCount', () async {
      await loop.correctCategory(
        transactionId: txn1Id,
        newCategory: 'foodAndDrink',
      );

      final events = await db.select(db.correctionEvents).get();
      expect(events.length, 1);
      expect(events.first.transactionId, txn1Id.toString());
      expect(events.first.previousCategory, 'other');
      expect(events.first.newCategory, 'foodAndDrink');
      expect(events.first.previousSource, 'uncategorized');
      // backfillCount = 2 (the other 2 bigbasket txns)
      expect(events.first.backfillCount, 2);
    });

    test('second correction on same merchant updates existing mapping', () async {
      // First correction
      await loop.correctCategory(
        transactionId: txn1Id,
        newCategory: 'foodAndDrink',
      );

      // Second correction (user changes their mind)
      await loop.correctCategory(
        transactionId: txn2Id,
        newCategory: 'shopping',
      );

      final mappings = await (db.select(db.merchantMappings)
            ..where((m) => m.merchantToken.equals('bigbasket')))
          .get();

      expect(mappings.length, 1);
      expect(mappings.first.category, 'shopping'); // Updated
      expect(mappings.first.useCount, 1); // Incremented
    });

    test('does not backfill already-categorized transactions', () async {
      // Manually set txn2 to a real category (simulating prior correction).
      await (db.update(db.spendlerTransactions)
            ..where((t) => t.id.equals(txn2Id)))
          .write(const SpendlerTransactionsCompanion(
        category: Value('shopping'),
        categorizationSource: Value('user'),
        categorizationConfidence: Value(1.0),
      ));

      final backfillCount = await loop.correctCategory(
        transactionId: txn1Id,
        newCategory: 'foodAndDrink',
      );

      // Only txn3 should be backfilled (txn2 is already categorized as 'user').
      expect(backfillCount, 1);

      // txn2 should remain 'shopping' (not overwritten).
      final txn2 = await (db.select(db.spendlerTransactions)
            ..where((t) => t.id.equals(txn2Id)))
          .getSingle();
      expect(txn2.category, 'shopping');
    });
  });
}
