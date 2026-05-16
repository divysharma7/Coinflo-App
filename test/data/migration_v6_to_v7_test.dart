import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finance_buddy_app/data/db.dart';

/// In-memory database for testing migrations.
SpendlerDatabase _openTestDb() {
  return SpendlerDatabase.forTesting(NativeDatabase.memory());
}

void main() {
  group('Migration v6 → v7', () {
    late SpendlerDatabase db;

    setUp(() {
      db = _openTestDb();
    });

    tearDown(() async {
      await db.close();
    });

    test('new tables exist after migration', () async {
      // Verify MerchantMappings table is accessible
      final mappings = await db.select(db.merchantMappings).get();
      expect(mappings, isEmpty);

      // Verify CorrectionEvents table is accessible
      final corrections = await db.select(db.correctionEvents).get();
      expect(corrections, isEmpty);

      // Verify ImportBatches table is accessible
      final batches = await db.select(db.importBatches).get();
      expect(batches, isEmpty);
    });

    test('new columns on SpendlerTransactions have correct defaults', () async {
      // Insert a transaction using only the pre-v7 columns
      await db.into(db.spendlerTransactions).insert(
            SpendlerTransactionsCompanion.insert(
              amount: 250.0,
              category: 'foodAndDrink',
            ),
          );

      final txns = await db.select(db.spendlerTransactions).get();
      expect(txns, hasLength(1));

      final txn = txns.first;
      // New nullable columns should be null
      expect(txn.rawHash, isNull);
      expect(txn.merchantToken, isNull);
      expect(txn.categorizationSource, isNull);
      expect(txn.categorizationConfidence, isNull);
      expect(txn.importBatchId, isNull);
      // New boolean columns should default to false
      expect(txn.isAnomaly, isFalse);
      expect(txn.isRecurring, isFalse);
    });

    test('MerchantMappings insert and unique token constraint', () async {
      final now = DateTime.now();

      await db.into(db.merchantMappings).insert(
            MerchantMappingsCompanion.insert(
              id: 'uuid-1',
              merchantToken: 'swiggy',
              category: 'foodAndDrink',
              source: 'shippedDictionary',
              confidence: 0.95,
              createdAt: now,
              updatedAt: now,
            ),
          );

      final mappings = await db.select(db.merchantMappings).get();
      expect(mappings, hasLength(1));
      expect(mappings.first.merchantToken, 'swiggy');
      expect(mappings.first.useCount, 0);
    });

    test('ImportBatches insert with all fields', () async {
      await db.into(db.importBatches).insert(
            ImportBatchesCompanion.insert(
              id: 'batch-uuid-1',
              bankName: 'hdfc',
              fileName: 'statement_jan.csv',
              importedAt: DateTime(2026, 1, 15),
              transactionCount: 150,
              categorizedCount: 130,
              uncategorizedCount: 20,
              status: 'completed',
            ),
          );

      final batches = await db.select(db.importBatches).get();
      expect(batches, hasLength(1));
      expect(batches.first.bankName, 'hdfc');
      expect(batches.first.transactionCount, 150);
      expect(batches.first.duplicateCount, 0);
      expect(batches.first.errorMessage, isNull);
    });

    test('CorrectionEvents insert with backfill count', () async {
      await db.into(db.correctionEvents).insert(
            CorrectionEventsCompanion.insert(
              id: 'corr-uuid-1',
              transactionId: '42',
              newCategory: 'transport',
              previousSource: 'dictionary',
              correctedAt: DateTime.now(),
              previousCategory: const Value('foodAndDrink'),
              backfillCount: const Value(5),
            ),
          );

      final events = await db.select(db.correctionEvents).get();
      expect(events, hasLength(1));
      expect(events.first.newCategory, 'transport');
      expect(events.first.backfillCount, 5);
    });

    test('imported transaction links to batch and has categorization metadata',
        () async {
      // Create an import batch first
      await db.into(db.importBatches).insert(
            ImportBatchesCompanion.insert(
              id: 'batch-1',
              bankName: 'hdfc',
              fileName: 'test.csv',
              importedAt: DateTime.now(),
              transactionCount: 1,
              categorizedCount: 1,
              uncategorizedCount: 0,
              status: 'completed',
            ),
          );

      // Insert a transaction with import-specific columns
      await db.into(db.spendlerTransactions).insert(
            SpendlerTransactionsCompanion.insert(
              amount: 499.0,
              category: 'entertainment',
              merchant: const Value('Netflix'),
              rawHash: const Value('abc123hash'),
              merchantToken: const Value('netflix'),
              categorizationSource: const Value('dictionary'),
              categorizationConfidence: const Value(0.92),
              importBatchId: const Value('batch-1'),
              isRecurring: const Value(true),
            ),
          );

      final txns = await db.select(db.spendlerTransactions).get();
      final imported = txns.firstWhere((t) => t.importBatchId == 'batch-1');
      expect(imported.merchantToken, 'netflix');
      expect(imported.categorizationSource, 'dictionary');
      expect(imported.categorizationConfidence, 0.92);
      expect(imported.isRecurring, isTrue);
      expect(imported.isAnomaly, isFalse);
    });

    test('rawHash uniqueness is enforced', () async {
      await db.into(db.spendlerTransactions).insert(
            SpendlerTransactionsCompanion.insert(
              amount: 100.0,
              category: 'shopping',
              rawHash: const Value('unique-hash-1'),
            ),
          );

      // Inserting a duplicate rawHash should fail
      await expectLater(
        db.into(db.spendlerTransactions).insert(
              SpendlerTransactionsCompanion.insert(
                amount: 200.0,
                category: 'transport',
                rawHash: const Value('unique-hash-1'),
              ),
            ),
        throwsA(isA<SqliteException>()),
      );
    });

    test('same merchantToken + different source = allowed', () async {
      final now = DateTime.now();

      await db.into(db.merchantMappings).insert(
            MerchantMappingsCompanion.insert(
              id: 'uuid-a',
              merchantToken: 'zomato',
              category: 'foodAndDrink',
              source: 'shippedDictionary',
              confidence: 0.9,
              createdAt: now,
              updatedAt: now,
            ),
          );

      // Same token, different source — should succeed
      await db.into(db.merchantMappings).insert(
            MerchantMappingsCompanion.insert(
              id: 'uuid-b',
              merchantToken: 'zomato',
              category: 'foodAndDrink',
              source: 'userCorrected',
              confidence: 1.0,
              createdAt: now,
              updatedAt: now,
            ),
          );

      final mappings = await (db.select(db.merchantMappings)
            ..where((m) => m.merchantToken.equals('zomato')))
          .get();
      expect(mappings, hasLength(2));
    });

    test('same merchantToken + same source = constraint violation', () async {
      final now = DateTime.now();

      await db.into(db.merchantMappings).insert(
            MerchantMappingsCompanion.insert(
              id: 'uuid-c',
              merchantToken: 'swiggy',
              category: 'foodAndDrink',
              source: 'shippedDictionary',
              confidence: 0.9,
              createdAt: now,
              updatedAt: now,
            ),
          );

      // Same token AND same source — should fail
      await expectLater(
        db.into(db.merchantMappings).insert(
              MerchantMappingsCompanion.insert(
                id: 'uuid-d',
                merchantToken: 'swiggy',
                category: 'foodAndDrink',
                source: 'shippedDictionary',
                confidence: 0.85,
                createdAt: now,
                updatedAt: now,
              ),
            ),
        throwsA(isA<SqliteException>()),
      );
    });
  });
}
