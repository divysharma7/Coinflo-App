import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finance_buddy_app/data/db.dart';
import 'package:finance_buddy_app/data/repositories/local/local_import_repository.dart';

void main() {
  late SpendlerDatabase db;
  late LocalImportRepository repo;

  setUp(() {
    db = SpendlerDatabase.forTesting(NativeDatabase.memory());
    repo = LocalImportRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('ImportBatches', () {
    test('watchImportBatches returns empty initially', () async {
      final batches = await repo.watchImportBatches().first;
      expect(batches, isEmpty);
    });

    test('insertImportBatch and getImportBatch', () async {
      await repo.insertImportBatch(ImportBatchesCompanion.insert(
        id: 'batch-1',
        bankName: 'hdfc',
        fileName: 'test.csv',
        importedAt: DateTime(2026, 1, 15),
        transactionCount: 100,
        categorizedCount: 80,
        uncategorizedCount: 20,
        status: 'pendingReview',
      ));

      final batch = await repo.getImportBatch('batch-1');
      expect(batch, isNotNull);
      expect(batch!.bankName, 'hdfc');
      expect(batch.transactionCount, 100);
      expect(batch.status, 'pendingReview');
    });

    test('updateImportBatchStatus', () async {
      await repo.insertImportBatch(ImportBatchesCompanion.insert(
        id: 'batch-2',
        bankName: 'icici',
        fileName: 'stmt.csv',
        importedAt: DateTime(2026, 2, 1),
        transactionCount: 50,
        categorizedCount: 50,
        uncategorizedCount: 0,
        status: 'pendingReview',
      ));

      await repo.updateImportBatchStatus('batch-2', 'completed');
      final batch = await repo.getImportBatch('batch-2');
      expect(batch!.status, 'completed');
    });

    test('watchImportBatches ordered by importedAt desc', () async {
      await repo.insertImportBatch(ImportBatchesCompanion.insert(
        id: 'older',
        bankName: 'hdfc',
        fileName: 'jan.csv',
        importedAt: DateTime(2026, 1, 1),
        transactionCount: 10,
        categorizedCount: 10,
        uncategorizedCount: 0,
        status: 'completed',
      ));
      await repo.insertImportBatch(ImportBatchesCompanion.insert(
        id: 'newer',
        bankName: 'hdfc',
        fileName: 'feb.csv',
        importedAt: DateTime(2026, 2, 1),
        transactionCount: 20,
        categorizedCount: 20,
        uncategorizedCount: 0,
        status: 'completed',
      ));

      final batches = await repo.watchImportBatches().first;
      expect(batches.length, 2);
      expect(batches.first.id, 'newer');
    });
  });

  group('MerchantMappings', () {
    test('insertMerchantMapping and getMerchantMappingByToken', () async {
      final now = DateTime.now();
      await repo.insertMerchantMapping(MerchantMappingsCompanion.insert(
        id: 'map-1',
        merchantToken: 'swiggy',
        category: 'foodAndDrink',
        source: 'userCorrected',
        confidence: 1.0,
        createdAt: now,
        updatedAt: now,
      ));

      final mapping = await repo.getMerchantMappingByToken('swiggy', 'userCorrected');
      expect(mapping, isNotNull);
      expect(mapping!.category, 'foodAndDrink');
    });

    test('getMerchantMappings returns all', () async {
      final now = DateTime.now();
      await repo.insertMerchantMapping(MerchantMappingsCompanion.insert(
        id: 'map-a',
        merchantToken: 'zomato',
        category: 'foodAndDrink',
        source: 'shippedDictionary',
        confidence: 0.9,
        createdAt: now,
        updatedAt: now,
      ));
      await repo.insertMerchantMapping(MerchantMappingsCompanion.insert(
        id: 'map-b',
        merchantToken: 'uber',
        category: 'transport',
        source: 'shippedDictionary',
        confidence: 0.85,
        createdAt: now,
        updatedAt: now,
      ));

      final all = await repo.getMerchantMappings();
      expect(all.length, 2);
    });
  });

  group('CorrectionEvents', () {
    test('insertCorrectionEvent', () async {
      await repo.insertCorrectionEvent(CorrectionEventsCompanion.insert(
        id: 'corr-1',
        transactionId: '42',
        newCategory: 'transport',
        previousSource: 'dictionary',
        correctedAt: DateTime.now(),
        previousCategory: const Value('foodAndDrink'),
        backfillCount: const Value(3),
      ));

      final events = await repo.getCorrectionEvents();
      expect(events.length, 1);
      expect(events.first.newCategory, 'transport');
      expect(events.first.backfillCount, 3);
    });
  });

  group('Bulk operations', () {
    test('batchInsertTransactions inserts multiple', () async {
      final entries = List.generate(
        25,
        (i) => SpendlerTransactionsCompanion.insert(
          amount: 100.0 + i,
          category: 'foodAndDrink',
          rawHash: Value('hash-$i'),
          merchantToken: const Value('test'),
          importBatchId: const Value('batch-test'),
        ),
      );

      await repo.batchInsertTransactions(entries);

      final all = await db.select(db.spendlerTransactions).get();
      expect(all.length, 25);
    });

    test('batchInsertTransactions is atomic — all or nothing', () async {
      // Insert a row with a unique hash first.
      await db.into(db.spendlerTransactions).insert(
            SpendlerTransactionsCompanion.insert(
              amount: 50.0,
              category: 'other',
              rawHash: const Value('duplicate-hash'),
            ),
          );

      // Try batch insert with a duplicate — should fail the entire batch.
      final entries = [
        SpendlerTransactionsCompanion.insert(
          amount: 100.0,
          category: 'food',
          rawHash: const Value('unique-hash-a'),
        ),
        SpendlerTransactionsCompanion.insert(
          amount: 200.0,
          category: 'food',
          rawHash: const Value('duplicate-hash'), // CONFLICT
        ),
      ];

      try {
        await repo.batchInsertTransactions(entries);
      } on Exception {
        // Expected to fail.
      }

      // Only the original row should exist (atomicity).
      final all = await db.select(db.spendlerTransactions).get();
      expect(all.length, 1);
    });
  });

  group('Prefetch helpers', () {
    test('getExistingRawHashes', () async {
      await db.into(db.spendlerTransactions).insert(
            SpendlerTransactionsCompanion.insert(
              amount: 100.0,
              category: 'food',
              rawHash: const Value('hash-abc'),
            ),
          );
      await db.into(db.spendlerTransactions).insert(
            SpendlerTransactionsCompanion.insert(
              amount: 200.0,
              category: 'food',
              // No rawHash
            ),
          );

      final hashes = await repo.getExistingRawHashes();
      expect(hashes, {'hash-abc'});
    });

    test('getUncategorizedFromBatch', () async {
      await db.into(db.spendlerTransactions).insert(
            SpendlerTransactionsCompanion.insert(
              amount: 100.0,
              category: 'foodAndDrink',
              importBatchId: const Value('batch-x'),
              categorizationSource: const Value('dictionary'),
            ),
          );
      await db.into(db.spendlerTransactions).insert(
            SpendlerTransactionsCompanion.insert(
              amount: 200.0,
              category: 'other',
              importBatchId: const Value('batch-x'),
              categorizationSource: const Value('uncategorized'),
            ),
          );

      final uncat = await repo.getUncategorizedFromBatch('batch-x');
      expect(uncat.length, 1);
      expect(uncat.first.amount, 200.0);
    });
  });
}
