import 'dart:io';
import 'dart:isolate';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'package:finance_buddy_app/core/enums.dart';
import 'package:finance_buddy_app/data/db.dart';
import 'package:finance_buddy_app/services/categorization/categorization_service.dart';
import 'package:finance_buddy_app/services/categorization/merchant_dictionary.dart';
import 'package:finance_buddy_app/services/detection/anomaly_detector.dart';
import 'package:finance_buddy_app/services/detection/recurring_detector.dart';
import 'package:finance_buddy_app/services/import/bank_adapters/bank_detector.dart';
import 'package:finance_buddy_app/services/import/pdf_parsers/pdf_bank_detector.dart';
import 'package:finance_buddy_app/services/import/pdf_parsers/pdf_text_extractor.dart';
import 'package:finance_buddy_app/services/import/models/import_progress.dart';
import 'package:finance_buddy_app/services/import/models/import_result.dart';
import 'package:finance_buddy_app/services/import/models/normalized_transaction.dart';
import 'package:finance_buddy_app/services/import/models/processed_transaction.dart';
import 'package:finance_buddy_app/services/import/models/raw_transaction.dart';
import 'package:finance_buddy_app/services/import/transaction_normalizer.dart';

const _uuid = Uuid();

/// Main conductor for the bank statement import pipeline.
///
/// Uses a hybrid isolate pattern:
///   1. Prefetch data from Drift (main thread)
///   2. Heavy CPU work in Isolate.run() (parse, normalize, categorize, detect)
///   3. Persist results back to Drift (main thread)
///
/// This avoids sharing the Drift database across the isolate boundary.
class ImportOrchestrator {
  final SpendlerDatabase _db;
  final MerchantDictionary _merchantDictionary;

  ImportOrchestrator({
    required SpendlerDatabase db,
    required MerchantDictionary merchantDictionary,
  })  : _db = db,
        _merchantDictionary = merchantDictionary;

  /// Run the full import pipeline.
  Future<ImportResult> runImport({
    required File file,
    required BankType bankType,
    required void Function(ImportProgress) onProgress,
  }) async {
    final batchId = _uuid.v4();
    final fileName = file.uri.pathSegments.last;

    try {
      // ── STEP 1: Read file on main thread ──────────────
      onProgress(const ImportProgress(phase: ImportPhase.parsing, message: 'Reading file...'));

      String csvContent;
      final isPdf = file.path.toLowerCase().endsWith('.pdf');

      if (isPdf) {
        // PDF: extract text on main thread (Syncfusion isn't isolate-safe),
        // then treat extracted text like CSV content for the isolate.
        final extractedText = await PdfExtractorService.extract(file);
        final pdfDetector = PdfBankDetector();
        final parser = pdfDetector.detect(extractedText);
        if (parser == null) {
          throw const FormatException(
            'Could not detect bank from PDF. Try downloading as CSV instead.',
          );
        }
        // Parse PDF text → RawTransactions → synthesize CSV-like content
        // Actually, we pass the raw transactions directly by serializing them.
        // Simpler: run PDF parsing on main thread (it's fast — just regex on text),
        // then pass the resulting RawTransactions into the isolate pipeline.
        final rawTxns = parser.parse(extractedText);
        // Convert to a synthetic CSV that the existing isolate pipeline can consume.
        csvContent = _rawTransactionsToCsv(rawTxns, bankType);
      } else {
        csvContent = await file.readAsString();
      }

      // ── STEP 2: Prefetch from Drift on main thread ────
      onProgress(const ImportProgress(phase: ImportPhase.normalizing, message: 'Preparing...'));
      final prefetched = await _prefetchData();

      // ── STEP 3: Heavy CPU work in isolate ─────────────
      final batch = await Isolate.run(() => _processInIsolate(
            csvContent: csvContent,
            bankType: bankType,
            existingRawHashes: prefetched.existingRawHashes,
            merchantMap: prefetched.merchantMap,
            smartRules: prefetched.smartRules,
            dictionaryEntries: prefetched.dictionaryEntries,
            historicalForRecurring: prefetched.historicalForRecurring,
            historicalForAnomaly: prefetched.historicalForAnomaly,
          ));

      onProgress(ImportProgress(
        phase: ImportPhase.categorizing,
        processed: batch.summary.totalParsed,
        total: batch.summary.totalParsed,
        message: 'Categorized ${batch.summary.categorizedCount} transactions',
      ));

      // ── STEP 4: Persist on main thread ────────────────
      onProgress(const ImportProgress(phase: ImportPhase.persisting, message: 'Saving...'));
      final persistedBatch = await _persist(
        batchId: batchId,
        bankType: bankType,
        fileName: fileName,
        batch: batch,
      );

      // ── STEP 5: Complete ──────────────────────────────
      final uncategorized = persistedBatch.transactions
          .where((t) => !t.isDuplicate && t.category == null)
          .toList();

      final result = ImportResult.success(
        batchId: batchId,
        summary: batch.summary,
        uncategorized: uncategorized,
      );

      onProgress(ImportProgress(
        phase: ImportPhase.complete,
        processed: batch.summary.totalParsed,
        total: batch.summary.totalParsed,
        message: 'Import complete',
      ));

      return result;
    } on Exception catch (e) {
      // Record the failed batch.
      try {
        await _db.into(_db.importBatches).insert(
              ImportBatchesCompanion.insert(
                id: batchId,
                bankName: bankType.name,
                fileName: fileName,
                importedAt: DateTime.now(),
                transactionCount: 0,
                categorizedCount: 0,
                uncategorizedCount: 0,
                status: ImportStatus.failed.name,
                errorMessage: Value(e.toString()),
              ),
            );
      } on Exception {
        // Don't let error recording mask the original error.
      }

      onProgress(ImportProgress(
        phase: ImportPhase.failed,
        message: e.toString(),
      ));

      return ImportResult.failure(e.toString());
    }
  }

  /// Prefetch all data needed by the isolate from Drift.
  Future<_PrefetchedData> _prefetchData() async {
    // Existing rawHashes for dedup.
    final hashRows = await (_db.selectOnly(_db.spendlerTransactions)
          ..addColumns([_db.spendlerTransactions.rawHash])
          ..where(_db.spendlerTransactions.rawHash.isNotNull()))
        .get();
    final existingHashes = hashRows
        .map((row) => row.read(_db.spendlerTransactions.rawHash))
        .whereType<String>()
        .toSet();

    // Merchant mappings (user corrections + ML).
    final mappingRows = await _db.select(_db.merchantMappings).get();
    final merchantMap = <String, MerchantMappingData>{};
    for (final m in mappingRows) {
      // User corrections take priority.
      if (!merchantMap.containsKey(m.merchantToken) ||
          m.source == 'userCorrected') {
        merchantMap[m.merchantToken] = MerchantMappingData(
          category: m.category,
          source: m.source,
          confidence: m.confidence,
        );
      }
    }

    // Smart rules.
    final ruleRows = await _db.select(_db.smartRules).get();
    final smartRules = ruleRows
        .map((r) => SmartRuleData(keyword: r.keyword, category: r.category))
        .toList();

    // Historical transactions for recurring detection (last 90 days).
    final ninetyDaysAgo = DateTime.now().subtract(const Duration(days: 90));
    final historicalRecurring = await (_db.select(_db.spendlerTransactions)
          ..where((t) => t.happenedAt.isBiggerOrEqualValue(ninetyDaysAgo)))
        .get();

    // Convert to ProcessedTransaction for isolate.
    final historicalForRecurring = historicalRecurring.map(_txnToProcessed).toList();

    // For anomaly detection — last 6 months.
    final sixMonthsAgo = DateTime.now().subtract(const Duration(days: 180));
    final historicalAnomaly = await (_db.select(_db.spendlerTransactions)
          ..where((t) => t.happenedAt.isBiggerOrEqualValue(sixMonthsAgo)))
        .get();
    final historicalForAnomaly = historicalAnomaly.map(_txnToProcessed).toList();

    return _PrefetchedData(
      existingRawHashes: existingHashes,
      merchantMap: merchantMap,
      smartRules: smartRules,
      dictionaryEntries: _merchantDictionary.allEntries,
      historicalForRecurring: historicalForRecurring,
      historicalForAnomaly: historicalForAnomaly,
    );
  }

  /// Persist the processed batch to Drift in a single atomic transaction.
  /// Returns the batch with DB-assigned IDs populated on each transaction.
  /// Uses Option B: batch insert + follow-up SELECT by rawHash to capture IDs.
  Future<ProcessedBatch> _persist({
    required String batchId,
    required BankType bankType,
    required String fileName,
    required ProcessedBatch batch,
  }) async {
    final nonDuplicates =
        batch.transactions.where((t) => !t.isDuplicate).toList();

    await _db.transaction(() async {
      // Insert ImportBatch row.
      final status = batch.summary.uncategorizedCount > 0
          ? ImportStatus.pendingReview
          : ImportStatus.completed;

      await _db.into(_db.importBatches).insert(
            ImportBatchesCompanion.insert(
              id: batchId,
              bankName: bankType.name,
              fileName: fileName,
              importedAt: DateTime.now(),
              transactionCount: nonDuplicates.length,
              categorizedCount: batch.summary.categorizedCount,
              uncategorizedCount: batch.summary.uncategorizedCount,
              duplicateCount: Value(batch.summary.duplicateCount),
              status: status.name,
            ),
          );

      // Batch insert transactions (100 per batch).
      for (var i = 0; i < nonDuplicates.length; i += 100) {
        final chunk = nonDuplicates.skip(i).take(100);
        await _db.batch((b) {
          for (final txn in chunk) {
            b.insert(
              _db.spendlerTransactions,
              SpendlerTransactionsCompanion.insert(
                amount: txn.amount,
                category: txn.category ?? 'other',
                merchant: Value(txn.merchantToken.isNotEmpty
                    ? txn.merchantToken
                    : null),
                note: Value(txn.rawDescription),
                happenedAt: Value(txn.date),
                source: const Value('import'),
                status: const Value('confirmed'),
                rawHash: Value(txn.rawHash),
                merchantToken: Value(
                    txn.merchantToken.isNotEmpty ? txn.merchantToken : null),
                categorizationSource:
                    Value(txn.categorizationSource.name),
                categorizationConfidence:
                    Value(txn.categorizationConfidence),
                importBatchId: Value(batchId),
                isAnomaly: Value(txn.isAnomaly),
                isRecurring: Value(txn.isRecurring),
              ),
            );
          }
        });
      }
    });

    // Follow-up SELECT to capture DB-assigned IDs (Option B).
    final inserted = await (_db.select(_db.spendlerTransactions)
          ..where((t) => t.importBatchId.equals(batchId)))
        .get();

    final hashToId = <String, int>{};
    for (final row in inserted) {
      if (row.rawHash != null) hashToId[row.rawHash!] = row.id;
    }

    // Update ProcessedTransactions with real DB IDs.
    final updatedTxns = batch.transactions.map((t) {
      if (t.isDuplicate) return t;
      final id = hashToId[t.rawHash];
      return id != null ? t.copyWith(dbId: id) : t;
    }).toList();

    return ProcessedBatch(transactions: updatedTxns, summary: batch.summary);
  }

  /// Convert RawTransactions (from PDF parsing) into a synthetic CSV string
  /// that the existing isolate pipeline can consume via HDFC adapter format.
  String _rawTransactionsToCsv(List<RawTransaction> txns, BankType bank) {
    final buffer = StringBuffer();
    // Use HDFC-compatible format so the existing adapter can parse it.
    buffer.writeln('Date,Narration,Value Dat,Debit Amount,Credit Amount,Chq/Ref Number,Closing Balance');
    for (final txn in txns) {
      final dateStr = '${txn.date.day.toString().padLeft(2, '0')}/${txn.date.month.toString().padLeft(2, '0')}/${txn.date.year.toString().substring(2)}';
      final debit = txn.type == 'debit' ? txn.amount.toStringAsFixed(2) : '';
      final credit = txn.type == 'credit' ? txn.amount.toStringAsFixed(2) : '';
      final ref = txn.referenceNumber ?? '';
      final desc = txn.rawDescription.replaceAll(',', ' ');
      buffer.writeln('$dateStr,$desc,$dateStr,$debit,$credit,$ref,0.00');
    }
    return buffer.toString();
  }

  ProcessedTransaction _txnToProcessed(SpendlerTransaction txn) {
    return ProcessedTransaction(
      date: txn.happenedAt,
      amount: txn.amount,
      type: txn.amount >= 0 ? 'debit' : 'credit',
      rawDescription: txn.note ?? '',
      cleanedDescription: txn.note ?? '',
      merchantToken: txn.merchantToken ?? '',
      channel: 'other',
      rawHash: txn.rawHash ?? '',
      sourceBank: BankType.unknown,
      category: txn.category,
      categorizationSource: CategorizationSource.values.firstWhere(
        (s) => s.name == txn.categorizationSource,
        orElse: () => CategorizationSource.uncategorized,
      ),
      categorizationConfidence: txn.categorizationConfidence ?? 0.0,
      isRecurring: txn.isRecurring,
      isAnomaly: txn.isAnomaly,
    );
  }
}

/// Data prefetched from Drift on the main thread, passed into the isolate.
class _PrefetchedData {
  final Set<String> existingRawHashes;
  final Map<String, MerchantMappingData> merchantMap;
  final List<SmartRuleData> smartRules;
  final List<MerchantEntry> dictionaryEntries;
  final List<ProcessedTransaction> historicalForRecurring;
  final List<ProcessedTransaction> historicalForAnomaly;

  const _PrefetchedData({
    required this.existingRawHashes,
    required this.merchantMap,
    required this.smartRules,
    required this.dictionaryEntries,
    required this.historicalForRecurring,
    required this.historicalForAnomaly,
  });
}

/// Pure CPU processing that runs inside Isolate.run().
/// Zero Drift/DB coupling — operates entirely on the data passed in.
ProcessedBatch _processInIsolate({
  required String csvContent,
  required BankType bankType,
  required Set<String> existingRawHashes,
  required Map<String, MerchantMappingData> merchantMap,
  required List<SmartRuleData> smartRules,
  required List<MerchantEntry> dictionaryEntries,
  required List<ProcessedTransaction> historicalForRecurring,
  required List<ProcessedTransaction> historicalForAnomaly,
}) {
  // Set up services inside the isolate (no DB access).
  final detector = BankDetector();
  final adapter = detector.detect(csvContent: csvContent);
  final normalizer = TransactionNormalizer();

  final dictionary = MerchantDictionary();
  dictionary.loadFromEntries(dictionaryEntries);

  final categorizationService = CategorizationService(
    smartRules: smartRules,
    userMerchantMap: merchantMap,
    dictionary: dictionary,
  );

  final recurringDetector = RecurringDetector();
  final anomalyDetector = AnomalyDetector();

  // ── Phase A: Parse ──────────────────────────────────
  final List<RawTransaction> rawTxns;
  try {
    rawTxns = adapter.parse(csvContent);
  } on Exception {
    return const ProcessedBatch(
      transactions: [],
      summary: ImportSummary(
        totalParsed: 0,
        categorizedCount: 0,
        uncategorizedCount: 0,
        duplicateCount: 0,
      ),
    );
  }

  // ── Phase B: Normalize + dedup ──────────────────────
  final normalized = <NormalizedTransaction>[];
  var duplicateCount = 0;

  for (final raw in rawTxns) {
    final norm = normalizer.normalize(raw);
    normalized.add(norm);
  }

  // ── Phase C: Categorize ─────────────────────────────
  var categorizedCount = 0;
  var uncategorizedCount = 0;

  final processed = <ProcessedTransaction>[];
  for (final norm in normalized) {
    // Check dedup.
    if (existingRawHashes.contains(norm.rawHash)) {
      processed.add(ProcessedTransaction.fromNormalized(
        normalized: norm,
        category: null,
        source: CategorizationSource.uncategorized,
        confidence: 0.0,
      ).copyWith(isDuplicate: true));
      duplicateCount++;
      continue;
    }

    final result = categorizationService.categorize(norm);
    if (result.isCategorized) {
      categorizedCount++;
    } else {
      uncategorizedCount++;
    }

    processed.add(ProcessedTransaction.fromNormalized(
      normalized: norm,
      category: result.category,
      source: result.source,
      confidence: result.confidence,
    ));
  }

  // ── Phase D: Detect recurring ───────────────────────
  final nonDuplicates = processed.where((t) => !t.isDuplicate).toList();
  final withRecurring = recurringDetector.detect(
    newTransactions: nonDuplicates,
    historicalTransactions: historicalForRecurring,
  );

  // ── Phase E: Detect anomalies ───────────────────────
  final withAnomalies = anomalyDetector.detect(
    newTransactions: withRecurring,
    historicalTransactions: historicalForAnomaly,
  );

  // Reassemble: duplicates + processed non-duplicates.
  final duplicates = processed.where((t) => t.isDuplicate).toList();
  final finalList = [...withAnomalies, ...duplicates];

  final recurringCount =
      withAnomalies.where((t) => t.isRecurring).length;
  final anomalyCount = withAnomalies.where((t) => t.isAnomaly).length;

  return ProcessedBatch(
    transactions: finalList,
    summary: ImportSummary(
      totalParsed: rawTxns.length,
      categorizedCount: categorizedCount,
      uncategorizedCount: uncategorizedCount,
      duplicateCount: duplicateCount,
      recurringCount: recurringCount,
      anomalyCount: anomalyCount,
    ),
  );
}
