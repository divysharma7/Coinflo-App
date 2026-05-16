import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:drift/drift.dart';

import 'package:finance_buddy_app/core/enums.dart';
import 'package:finance_buddy_app/data/db.dart';
import 'package:finance_buddy_app/data/repositories/local/local_import_repository.dart';
import 'package:finance_buddy_app/providers/classifier_provider.dart';
import 'package:finance_buddy_app/providers/database_providers.dart';
import 'package:finance_buddy_app/services/categorization/learning_loop.dart';
import 'package:finance_buddy_app/services/import/import_orchestrator.dart';
import 'package:finance_buddy_app/services/import/models/import_progress.dart';
import 'package:finance_buddy_app/services/import/models/processed_transaction.dart';

// ─── Repository provider ─────────────────────────────

final importRepositoryProvider = Provider<LocalImportRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return LocalImportRepository(db);
});

// ─── Orchestrator provider ───────────────────────────

final importOrchestratorProvider = Provider<ImportOrchestrator>((ref) {
  final db = ref.watch(databaseProvider);
  final dict = ref.watch(merchantDictionaryProvider);
  return ImportOrchestrator(db: db, merchantDictionary: dict);
});

// ─── Flow state ──────────────────────────────────────

class ImportFlowState {
  final ImportStep currentStep;
  final BankType? selectedBank;
  final File? selectedFile;
  final ImportProgress? progress;
  final ImportBatch? completedBatch;
  final List<ProcessedTransaction> uncategorized;
  final String? error;
  final ImportSource source;

  const ImportFlowState({
    this.currentStep = ImportStep.selectBank,
    this.selectedBank,
    this.selectedFile,
    this.progress,
    this.completedBatch,
    this.uncategorized = const [],
    this.error,
    this.source = ImportSource.settings,
  });

  ImportFlowState copyWith({
    ImportStep? currentStep,
    BankType? selectedBank,
    File? selectedFile,
    ImportProgress? progress,
    ImportBatch? completedBatch,
    List<ProcessedTransaction>? uncategorized,
    String? error,
    ImportSource? source,
  }) {
    return ImportFlowState(
      currentStep: currentStep ?? this.currentStep,
      selectedBank: selectedBank ?? this.selectedBank,
      selectedFile: selectedFile ?? this.selectedFile,
      progress: progress ?? this.progress,
      completedBatch: completedBatch ?? this.completedBatch,
      uncategorized: uncategorized ?? this.uncategorized,
      error: error,
      source: source ?? this.source,
    );
  }
}

// ─── Flow controller ─────────────────────────────────

class ImportFlowController extends StateNotifier<ImportFlowState> {
  final ImportOrchestrator _orchestrator;
  final SpendlerDatabase _db;

  ImportFlowController(this._orchestrator, this._db)
      : super(const ImportFlowState());

  void setSource(ImportSource source) {
    state = state.copyWith(source: source);
  }

  void selectBank(BankType bank) {
    state = state.copyWith(
      selectedBank: bank,
      currentStep: ImportStep.uploadFile,
    );
  }

  void selectFile(File file) {
    state = state.copyWith(selectedFile: file);
  }

  Future<void> startImport() async {
    final file = state.selectedFile;
    final bank = state.selectedBank;
    if (file == null || bank == null) return;

    state = state.copyWith(
      currentStep: ImportStep.processing,
      error: null,
    );

    final result = await _orchestrator.runImport(
      file: file,
      bankType: bank,
      onProgress: (progress) {
        state = state.copyWith(progress: progress);
      },
    );

    if (result.success) {
      // Fetch the completed batch record.
      final batch = await ((_db.select(_db.importBatches))
            ..where((t) => t.id.equals(result.batchId!)))
          .getSingleOrNull();

      state = state.copyWith(
        completedBatch: batch,
        uncategorized: result.uncategorizedTransactions,
        currentStep: result.uncategorizedTransactions.isNotEmpty
            ? ImportStep.review
            : ImportStep.summary,
      );
    } else {
      state = state.copyWith(
        error: result.errorMessage,
        currentStep: ImportStep.uploadFile,
      );
    }
  }

  /// Correct a transaction's category using the learning loop.
  /// Removes the corrected transaction AND all with the same merchantToken
  /// from the uncategorized list (since they were backfilled).
  /// Returns the backfill count.
  Future<int> correctCategory(int transactionId, String merchantToken, String newCategory) async {
    final loop = LearningLoop(_db);
    final backfillCount = await loop.correctCategory(
      transactionId: transactionId,
      newCategory: newCategory,
    );

    // Remove corrected txn + all with same merchantToken (they were backfilled).
    final remaining = state.uncategorized
        .where((t) => t.merchantToken != merchantToken)
        .toList();

    state = state.copyWith(uncategorized: remaining);
    return backfillCount;
  }

  void finishReview() {
    state = state.copyWith(currentStep: ImportStep.summary);

    // Update batch status to completed.
    if (state.completedBatch != null) {
      (_db.update(_db.importBatches)
            ..where((t) => t.id.equals(state.completedBatch!.id)))
          .write(const ImportBatchesCompanion(
        status: Value('completed'),
      ));
    }
  }

  void reset() {
    state = const ImportFlowState();
  }
}

// ─── Provider (autoDispose — resets when user leaves flow) ──

final importFlowControllerProvider =
    StateNotifierProvider.autoDispose<ImportFlowController, ImportFlowState>(
        (ref) {
  final orchestrator = ref.watch(importOrchestratorProvider);
  final db = ref.watch(databaseProvider);
  return ImportFlowController(orchestrator, db);
});
