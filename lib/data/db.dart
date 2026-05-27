import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'db.g.dart';

// ─── Tables ───────────────────────────────────────────

class SpendlerTransactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  RealColumn get amount => real()();
  TextColumn get category => text()(); // enum string: rent/transport/food/family/social/other
  TextColumn get merchant => text().nullable()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get happenedAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get source => text().withDefault(const Constant('manual'))();
  TextColumn get status => text().withDefault(const Constant('confirmed'))(); // unconfirmed / confirmed
  BoolColumn get isSplit => boolean().withDefault(const Constant(false))();
  IntColumn get splitCount => integer().nullable()();
  RealColumn get splitMyShare => real().nullable()();
  RealColumn get splitPendingAmount => real().nullable()();
  BoolColumn get splitSettled => boolean().withDefault(const Constant(false))();
  TextColumn get ledgerType => text().withDefault(const Constant('personal'))(); // personal / family
  TextColumn get syncId => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  // ─── Import module columns (added in schema v7) ──────
  TextColumn get rawHash => text().nullable()();                // SHA256(date|amount|cleaned_desc), unique
  TextColumn get merchantToken => text().nullable()();          // normalized lowercase merchant key
  TextColumn get categorizationSource => text().nullable()();   // CategorizationSource enum name
  RealColumn get categorizationConfidence => real().nullable()(); // 0.0 to 1.0
  TextColumn get importBatchId => text().nullable()();          // FK to ImportBatches.id
  BoolColumn get isAnomaly => boolean().withDefault(const Constant(false))();
  BoolColumn get isRecurring => boolean().withDefault(const Constant(false))();

  // ─── v8 columns ──────────────────────────────────────
  TextColumn get incomeSource => text().nullable()();       // salary, freelance, refund, gift, other
  TextColumn get attachmentPath => text().nullable()();     // local file path for receipt photo
}

class FamilyEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get type => text()(); // inflow / investment
  RealColumn get amount => real()();
  TextColumn get fromPerson => text()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get happenedAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get investmentType => text().nullable()(); // MF / stocks / FD / other
  TextColumn get syncId => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class WeeklyReflections extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get weekStartDate => dateTime()();
  RealColumn get totalSpent => real()();
  TextColumn get topCategory => text()();
  DateTimeColumn get openedAt => dateTime().nullable()();
  DateTimeColumn get llmReportGeneratedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class AppMetrics extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get metricType => text()(); // app_open / retrospection / llm_report / week_confirmed
  DateTimeColumn get recordedAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get metadata => text().nullable()();
}

class AppNotifications extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get type => text()(); // 'transaction', 'checkin', 'digest'
  TextColumn get title => text()();
  TextColumn get body => text()();
  DateTimeColumn get sentAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isRead => boolean().withDefault(const Constant(false))();
}

class FriendContacts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(max: 30)();
  TextColumn get note => text().nullable()();
  TextColumn get avatarColour => text()(); // hex colour string
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class FriendSplits extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get transactionId => integer()();
  IntColumn get friendContactId => integer()();
  RealColumn get amount => real()();
  TextColumn get direction => text()(); // 'they_owe_me' | 'i_owe_them'
  BoolColumn get isSettled => boolean().withDefault(const Constant(false))();
  BoolColumn get isWrittenOff => boolean().withDefault(const Constant(false))();
  DateTimeColumn get settledAt => dateTime().nullable()();
  TextColumn get settlementMethod => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  // ─── v8 columns ──────────────────────────────────────
  TextColumn get status => text().withDefault(const Constant('uncleared'))(); // uncleared, partiallyCleared, cleared
  RealColumn get amountCleared => real().withDefault(const Constant(0.0))();
}

class Subscriptions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  RealColumn get amount => real()();
  TextColumn get billingCycle => text()(); // weekly / monthly / yearly
  DateTimeColumn get nextBillingDate => dateTime()();
  TextColumn get category => text()(); // reuses TransactionCategory values
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class CategoryBudgets extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get category => text()(); // matches TransactionCategory name
  RealColumn get monthlyLimit => real()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class SavingsGoals extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  RealColumn get targetAmount => real()();
  RealColumn get currentAmount => real().withDefault(const Constant(0))();
  TextColumn get iconName => text()(); // Phosphor icon identifier
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class UserAccounts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get type => text()(); // cash, bank, creditCard, digitalWallet
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class SmartRules extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get keyword => text()();
  TextColumn get category => text()(); // TransactionCategory name
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// ============================================================
// IMPORT MODULE TABLES (added in v7)
// ============================================================
// See docs/import-architecture.md for the full import pipeline,
// cascade order, and bank adapter conventions.
// ============================================================

@DataClassName('MerchantMapping')
class MerchantMappings extends Table {
  TextColumn get id => text()();                               // UUID
  TextColumn get merchantToken => text()();                    // normalized, lowercase, alphanumeric
  TextColumn get category => text()();                         // TransactionCategory enum name
  TextColumn get source => text()();                           // MappingSource enum name
  RealColumn get confidence => real()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  IntColumn get useCount => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('CorrectionEvent')
class CorrectionEvents extends Table {
  TextColumn get id => text()();                               // UUID
  TextColumn get transactionId => text()();                    // references SpendlerTransactions.id (as string)
  TextColumn get previousCategory => text().nullable()();      // TransactionCategory enum name
  TextColumn get newCategory => text()();                      // TransactionCategory enum name
  TextColumn get previousSource => text()();                   // 'dictionary' / 'rule' / 'manual' etc
  DateTimeColumn get correctedAt => dateTime()();
  IntColumn get backfillCount => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('ImportBatch')
class ImportBatches extends Table {
  TextColumn get id => text()();                               // UUID
  TextColumn get bankName => text()();                         // BankType enum name
  TextColumn get fileName => text()();
  DateTimeColumn get importedAt => dateTime()();
  IntColumn get transactionCount => integer()();
  IntColumn get categorizedCount => integer()();
  IntColumn get uncategorizedCount => integer()();
  IntColumn get duplicateCount => integer().withDefault(const Constant(0))();
  TextColumn get status => text()();                           // ImportStatus enum name
  TextColumn get errorMessage => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// ─── Database ─────────────────────────────────────────

@DriftDatabase(tables: [
  SpendlerTransactions,
  FamilyEntries,
  WeeklyReflections,
  AppMetrics,
  AppNotifications,
  FriendContacts,
  FriendSplits,
  Subscriptions,
  CategoryBudgets,
  SavingsGoals,
  UserAccounts,
  SmartRules,
  MerchantMappings,
  CorrectionEvents,
  ImportBatches,
])
class SpendlerDatabase extends _$SpendlerDatabase {
  SpendlerDatabase() : super(_openConnection());

  /// Test-only constructor accepting any [QueryExecutor] (e.g. NativeDatabase.memory()).
  SpendlerDatabase.forTesting(super.e);

  // TODO: Rename DB file from spendler.sqlite → coinflo.sqlite in a separate migration PR.
  @override
  int get schemaVersion => 9;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
          await _createV7Indexes(m);
        },
        onUpgrade: (Migrator m, int from, int to) async {
          if (from < 2) {
            await m.createTable(appNotifications);
          }
          if (from < 3) {
            await m.createTable(friendContacts);
            await m.createTable(friendSplits);
          }
          if (from < 4) {
            await m.createTable(subscriptions);
          }
          if (from < 5) {
            await m.createTable(categoryBudgets);
            await m.createTable(savingsGoals);
          }
          if (from < 6) {
            await m.createTable(userAccounts);
            await m.createTable(smartRules);
          }
          if (from < 7) {
            // New tables for import module
            await m.createTable(merchantMappings);
            await m.createTable(correctionEvents);
            await m.createTable(importBatches);

            // New columns on SpendlerTransactions
            await m.addColumn(
              spendlerTransactions,
              spendlerTransactions.rawHash,
            );
            await m.addColumn(
              spendlerTransactions,
              spendlerTransactions.merchantToken,
            );
            await m.addColumn(
              spendlerTransactions,
              spendlerTransactions.categorizationSource,
            );
            await m.addColumn(
              spendlerTransactions,
              spendlerTransactions.categorizationConfidence,
            );
            await m.addColumn(
              spendlerTransactions,
              spendlerTransactions.importBatchId,
            );
            await m.addColumn(
              spendlerTransactions,
              spendlerTransactions.isAnomaly,
            );
            await m.addColumn(
              spendlerTransactions,
              spendlerTransactions.isRecurring,
            );

            // Indexes for import performance
            await _createV7Indexes(m);
          }
          if (from < 8) {
            // P3.2: Income source field
            await m.addColumn(
              spendlerTransactions,
              spendlerTransactions.incomeSource,
            );
            // P3.4: Attachment path field
            await m.addColumn(
              spendlerTransactions,
              spendlerTransactions.attachmentPath,
            );
            // P3.3: Split status + amountCleared
            await m.addColumn(
              friendSplits,
              friendSplits.status,
            );
            await m.addColumn(
              friendSplits,
              friendSplits.amountCleared,
            );
            // Backfill: existing income transactions get source 'other'
            await customStatement(
              "UPDATE spendler_transactions SET income_source = 'other' WHERE amount > 0 AND category = 'income'",
            );
            // Backfill: existing settled splits get status 'cleared' with full amount
            await customStatement(
              "UPDATE friend_splits SET status = 'cleared', amount_cleared = amount WHERE is_settled = 1",
            );
          }
          if (from < 9) {
            // Performance indexes for common query patterns
            await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_txn_happened_at ON spendler_transactions (happened_at)',
            );
            await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_txn_status ON spendler_transactions (status)',
            );
            await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_txn_category ON spendler_transactions (category)',
            );
          }
        },
      );

  Future<void> _createV7Indexes(Migrator m) async {
    await m.createIndex(Index('spendler_transactions',
        'CREATE UNIQUE INDEX IF NOT EXISTS idx_txn_raw_hash ON spendler_transactions (raw_hash) WHERE raw_hash IS NOT NULL'));
    await m.createIndex(Index('spendler_transactions',
        'CREATE INDEX IF NOT EXISTS idx_txn_merchant_token ON spendler_transactions (merchant_token) WHERE merchant_token IS NOT NULL'));
    await m.createIndex(Index('spendler_transactions',
        'CREATE INDEX IF NOT EXISTS idx_txn_import_batch ON spendler_transactions (import_batch_id) WHERE import_batch_id IS NOT NULL'));
    await m.createIndex(Index('merchant_mappings',
        'CREATE UNIQUE INDEX IF NOT EXISTS idx_merchant_mapping_token_source ON merchant_mappings (merchant_token, source)'));
    // Performance indexes for common query patterns (v9)
    await m.createIndex(Index('spendler_transactions',
        'CREATE INDEX IF NOT EXISTS idx_txn_happened_at ON spendler_transactions (happened_at)'));
    await m.createIndex(Index('spendler_transactions',
        'CREATE INDEX IF NOT EXISTS idx_txn_status ON spendler_transactions (status)'));
    await m.createIndex(Index('spendler_transactions',
        'CREATE INDEX IF NOT EXISTS idx_txn_category ON spendler_transactions (category)'));
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'spendler.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
