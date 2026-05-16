import 'package:drift/drift.dart';
import 'package:finance_buddy_app/data/db.dart';

/// Repository for import-related data access: ImportBatchs, MerchantMappings,
/// CorrectionEvents, and bulk transaction operations.
///
/// This is the canonical batching pattern for high-volume operations.
/// Future repos needing batch inserts should follow this pattern.
class LocalImportRepository {
  final SpendlerDatabase db;

  LocalImportRepository(this.db);

  // ─── ImportBatchs ─────────────────────────────────

  Stream<List<ImportBatch>> watchImportBatches() {
    return (db.select(db.importBatches)
          ..orderBy([(t) => OrderingTerm.desc(t.importedAt)]))
        .watch();
  }

  Future<ImportBatch?> getImportBatch(String id) {
    return (db.select(db.importBatches)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<void> insertImportBatch(ImportBatchesCompanion entry) {
    return db.into(db.importBatches).insert(entry);
  }

  Future<void> updateImportBatchStatus(String id, String status) {
    return (db.update(db.importBatches)..where((t) => t.id.equals(id)))
        .write(ImportBatchesCompanion(status: Value(status)));
  }

  // ─── Uncategorized from batch ──────────────────────

  Future<List<SpendlerTransaction>> getUncategorizedFromBatch(String batchId) {
    return (db.select(db.spendlerTransactions)
          ..where((t) =>
              t.importBatchId.equals(batchId) &
              (t.categorizationSource.equals('uncategorized') |
                  t.categorizationSource.isNull())))
        .get();
  }

  // ─── Bulk transaction operations ───────────────────

  /// Batch insert transactions wrapped in a single DB transaction.
  /// Uses db.batch() for performance. This is the canonical pattern.
  Future<void> batchInsertTransactions(
      List<SpendlerTransactionsCompanion> entries) async {
    await db.transaction(() async {
      for (var i = 0; i < entries.length; i += 100) {
        final chunk = entries.skip(i).take(100);
        await db.batch((b) {
          for (final entry in chunk) {
            b.insert(db.spendlerTransactions, entry);
          }
        });
      }
    });
  }

  // ─── MerchantMappings ──────────────────────────────

  Stream<List<MerchantMapping>> watchMerchantMappings() {
    return db.select(db.merchantMappings).watch();
  }

  Future<List<MerchantMapping>> getMerchantMappings() {
    return db.select(db.merchantMappings).get();
  }

  Future<MerchantMapping?> getMerchantMappingByToken(
      String merchantToken, String source) {
    return (db.select(db.merchantMappings)
          ..where((m) =>
              m.merchantToken.equals(merchantToken) &
              m.source.equals(source)))
        .getSingleOrNull();
  }

  Future<void> insertMerchantMapping(MerchantMappingsCompanion entry) {
    return db.into(db.merchantMappings).insert(entry);
  }

  Future<void> updateMerchantMapping(
      String id, MerchantMappingsCompanion entry) {
    return (db.update(db.merchantMappings)..where((m) => m.id.equals(id)))
        .write(entry);
  }

  // ─── CorrectionEvents ─────────────────────────────

  Future<void> insertCorrectionEvent(CorrectionEventsCompanion entry) {
    return db.into(db.correctionEvents).insert(entry);
  }

  Future<List<CorrectionEvent>> getCorrectionEvents() {
    return (db.select(db.correctionEvents)
          ..orderBy([(t) => OrderingTerm.desc(t.correctedAt)]))
        .get();
  }

  // ─── Prefetch helpers (for orchestrator) ───────────

  Future<Set<String>> getExistingRawHashes() async {
    final rows = await (db.selectOnly(db.spendlerTransactions)
          ..addColumns([db.spendlerTransactions.rawHash])
          ..where(db.spendlerTransactions.rawHash.isNotNull()))
        .get();
    return rows
        .map((row) => row.read(db.spendlerTransactions.rawHash))
        .whereType<String>()
        .toSet();
  }

  Future<List<SpendlerTransaction>> getRecentTransactions(int days) {
    final since = DateTime.now().subtract(Duration(days: days));
    return (db.select(db.spendlerTransactions)
          ..where((t) => t.happenedAt.isBiggerOrEqualValue(since)))
        .get();
  }

  Future<List<SmartRule>> getSmartRules() {
    return db.select(db.smartRules).get();
  }
}
