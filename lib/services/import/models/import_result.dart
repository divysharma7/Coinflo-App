import 'package:finance_buddy_app/services/import/models/processed_transaction.dart';

/// Summary statistics from an import run.
class ImportSummary {
  final int totalParsed;
  final int categorizedCount;
  final int uncategorizedCount;
  final int duplicateCount;
  final int recurringCount;
  final int anomalyCount;

  const ImportSummary({
    required this.totalParsed,
    required this.categorizedCount,
    required this.uncategorizedCount,
    required this.duplicateCount,
    this.recurringCount = 0,
    this.anomalyCount = 0,
  });
}

/// Final result returned by the ImportOrchestrator.
class ImportResult {
  final bool success;
  final String? batchId;
  final ImportSummary? summary;
  final List<ProcessedTransaction> uncategorizedTransactions;
  final String? errorMessage;

  const ImportResult._({
    required this.success,
    this.batchId,
    this.summary,
    this.uncategorizedTransactions = const [],
    this.errorMessage,
  });

  factory ImportResult.success({
    required String batchId,
    required ImportSummary summary,
    required List<ProcessedTransaction> uncategorized,
  }) {
    return ImportResult._(
      success: true,
      batchId: batchId,
      summary: summary,
      uncategorizedTransactions: uncategorized,
    );
  }

  factory ImportResult.failure(String error) {
    return ImportResult._(
      success: false,
      errorMessage: error,
    );
  }
}

/// What the isolate returns after processing.
class ProcessedBatch {
  final List<ProcessedTransaction> transactions;
  final ImportSummary summary;

  const ProcessedBatch({
    required this.transactions,
    required this.summary,
  });
}
