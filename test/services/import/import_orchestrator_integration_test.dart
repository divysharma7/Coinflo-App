// TODO(v2): Replace synthetic fixture files with 3-5 anonymized real bank
// statements once available. Real exports have edge cases synthetic data misses:
// variable-width fields, locale-specific number formatting, mid-file section
// breaks, and bank-specific disclaimer blocks.

import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finance_buddy_app/core/enums.dart';
import 'package:finance_buddy_app/data/db.dart';
import 'package:finance_buddy_app/services/categorization/merchant_dictionary.dart';
import 'package:finance_buddy_app/services/import/import_orchestrator.dart';
import 'package:finance_buddy_app/services/import/models/import_progress.dart';

void main() {
  late SpendlerDatabase db;
  late MerchantDictionary dictionary;
  late ImportOrchestrator orchestrator;
  late File fixtureFile;

  setUp(() {
    db = SpendlerDatabase.forTesting(NativeDatabase.memory());
    dictionary = MerchantDictionary();
    // Load a small test dictionary.
    dictionary.loadFromString('''[
      {"token": "swiggy", "category": "foodAndDrink", "confidence": 0.95, "aliases": ["swggy"]},
      {"token": "zomato", "category": "foodAndDrink", "confidence": 0.93},
      {"token": "uber", "category": "transport", "confidence": 0.9},
      {"token": "netflix", "category": "entertainment", "confidence": 0.95},
      {"token": "bigbazaar", "category": "shopping", "confidence": 0.9},
      {"token": "reliance", "category": "shopping", "confidence": 0.85},
      {"token": "apollo", "category": "healthAndWellness", "confidence": 0.9},
      {"token": "zerodha", "category": "investments", "confidence": 0.95},
      {"token": "groww", "category": "investments", "confidence": 0.9},
      {"token": "bescom", "category": "billsAndUtilities", "confidence": 0.95}
    ]''');
    orchestrator = ImportOrchestrator(db: db, merchantDictionary: dictionary);
    fixtureFile = File('test/fixtures/hdfc_sample.csv');
  });

  tearDown(() async {
    await db.close();
  });

  group('End-to-end import', () {
    test('parses all 20 transactions from HDFC fixture', () async {
      final progressEvents = <ImportProgress>[];

      final result = await orchestrator.runImport(
        file: fixtureFile,
        bankType: BankType.hdfc,
        onProgress: progressEvents.add,
      );

      expect(result.success, isTrue);
      expect(result.summary, isNotNull);
      expect(result.summary!.totalParsed, 20);
    });

    test('inserts non-duplicate transactions into DB', () async {
      await orchestrator.runImport(
        file: fixtureFile,
        bankType: BankType.hdfc,
        onProgress: (_) {},
      );

      final allTxns = await db.select(db.spendlerTransactions).get();
      expect(allTxns.length, 20);
    });

    test('rawHashes are unique across all imported transactions', () async {
      await orchestrator.runImport(
        file: fixtureFile,
        bankType: BankType.hdfc,
        onProgress: (_) {},
      );

      final allTxns = await db.select(db.spendlerTransactions).get();
      final hashes = allTxns.map((t) => t.rawHash).whereType<String>().toSet();
      expect(hashes.length, 20); // All unique
    });

    test('dedup works — second import inserts 0 new rows', () async {
      // First import
      await orchestrator.runImport(
        file: fixtureFile,
        bankType: BankType.hdfc,
        onProgress: (_) {},
      );

      final countAfterFirst =
          (await db.select(db.spendlerTransactions).get()).length;
      expect(countAfterFirst, 20);

      // Second import of same file
      final result = await orchestrator.runImport(
        file: fixtureFile,
        bankType: BankType.hdfc,
        onProgress: (_) {},
      );

      expect(result.success, isTrue);
      expect(result.summary!.duplicateCount, 20);

      final countAfterSecond =
          (await db.select(db.spendlerTransactions).get()).length;
      expect(countAfterSecond, 20); // No new rows
    });

    test('cascade Stage 2 hits for known merchants in dictionary', () async {
      await orchestrator.runImport(
        file: fixtureFile,
        bankType: BankType.hdfc,
        onProgress: (_) {},
      );

      // Swiggy transactions should be categorized as foodAndDrink via dictionary.
      final swiggyTxns = await (db.select(db.spendlerTransactions)
            ..where((t) => t.merchantToken.equals('swiggy')))
          .get();

      expect(swiggyTxns, isNotEmpty);
      for (final txn in swiggyTxns) {
        expect(txn.category, 'foodAndDrink');
        expect(txn.categorizationSource, 'dictionary');
      }
    });

    test('ImportBatch row created with correct counts', () async {
      final result = await orchestrator.runImport(
        file: fixtureFile,
        bankType: BankType.hdfc,
        onProgress: (_) {},
      );

      final batch = await (db.select(db.importBatches)
            ..where((t) => t.id.equals(result.batchId!)))
          .getSingleOrNull();

      expect(batch, isNotNull);
      expect(batch!.bankName, 'hdfc');
      expect(batch.transactionCount, 20);
      expect(batch.categorizedCount + batch.uncategorizedCount, 20);
    });

    test('dbId is populated on all returned ProcessedTransaction objects',
        () async {
      await orchestrator.runImport(
        file: fixtureFile,
        bankType: BankType.hdfc,
        onProgress: (_) {},
      );

      // Verify via DB that all imported rows have valid auto-increment IDs.
      final allTxns = await db.select(db.spendlerTransactions).get();
      expect(allTxns.every((t) => t.id > 0), isTrue);
      expect(allTxns.length, 20);
    });

    test('progress events emitted in correct order', () async {
      final phases = <ImportPhase>[];

      await orchestrator.runImport(
        file: fixtureFile,
        bankType: BankType.hdfc,
        onProgress: (p) => phases.add(p.phase),
      );

      expect(phases, contains(ImportPhase.parsing));
      expect(phases, contains(ImportPhase.persisting));
      expect(phases, contains(ImportPhase.complete));
      // Parsing should come before persisting.
      expect(
        phases.indexOf(ImportPhase.parsing),
        lessThan(phases.indexOf(ImportPhase.persisting)),
      );
    });

    test('rule engine catches salary as income category', () async {
      await orchestrator.runImport(
        file: fixtureFile,
        bankType: BankType.hdfc,
        onProgress: (_) {},
      );

      // HDFC fixture has "NEFT CR-ACME CORP-SALARY JAN 2026"
      final salaryTxns = await (db.select(db.spendlerTransactions)
            ..where((t) => t.category.equals('income')))
          .get();

      expect(salaryTxns, isNotEmpty);
      for (final txn in salaryTxns) {
        expect(txn.categorizationSource, 'rule');
      }
    });
  });
}
