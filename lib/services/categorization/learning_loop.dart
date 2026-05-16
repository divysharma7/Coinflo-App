import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'package:finance_buddy_app/data/db.dart';

/// Handles user corrections to categorization and backfills the correction
/// to all transactions with the same merchantToken.
///
/// This runs on the main thread (needs DB access).
class LearningLoop {
  final SpendlerDatabase _db;
  static const _uuid = Uuid();

  LearningLoop(this._db);

  /// Process a user correction: update the transaction's category,
  /// upsert MerchantMappings, and backfill matching transactions.
  ///
  /// Returns the number of additional transactions updated (backfill count).
  Future<int> correctCategory({
    required int transactionId,
    required String newCategory,
  }) async {
    // 1. Fetch the transaction being corrected.
    final txn = await ((_db.select(_db.spendlerTransactions))
          ..where((t) => t.id.equals(transactionId)))
        .getSingleOrNull();
    if (txn == null) return 0;

    final merchantToken = txn.merchantToken;
    final previousCategory = txn.category;
    final previousSource = txn.categorizationSource ?? 'manual';

    // 2. Update this transaction.
    await (_db.update(_db.spendlerTransactions)
          ..where((t) => t.id.equals(transactionId)))
        .write(SpendlerTransactionsCompanion(
      category: Value(newCategory),
      categorizationSource: const Value('user'),
      categorizationConfidence: const Value(1.0),
    ));

    // 3. Upsert MerchantMappings (userCorrected source).
    if (merchantToken != null && merchantToken.isNotEmpty) {
      await _upsertMerchantMapping(merchantToken, newCategory);
    }

    // 4. Backfill: find other uncategorized/low-confidence txns with same merchantToken.
    var backfillCount = 0;
    if (merchantToken != null && merchantToken.isNotEmpty) {
      backfillCount = await _backfill(merchantToken, newCategory, transactionId);
    }

    // 5. Record the correction event.
    await _db.into(_db.correctionEvents).insert(
          CorrectionEventsCompanion.insert(
            id: _uuid.v4(),
            transactionId: transactionId.toString(),
            previousCategory: Value(previousCategory),
            newCategory: newCategory,
            previousSource: previousSource,
            correctedAt: DateTime.now(),
            backfillCount: Value(backfillCount),
          ),
        );

    return backfillCount;
  }

  /// Upsert a user-corrected merchant mapping.
  Future<void> _upsertMerchantMapping(String merchantToken, String category) async {
    final now = DateTime.now();

    // Check if a userCorrected mapping already exists.
    final existing = await ((_db.select(_db.merchantMappings))
          ..where((m) =>
              m.merchantToken.equals(merchantToken) &
              m.source.equals('userCorrected')))
        .getSingleOrNull();

    if (existing != null) {
      // Update existing mapping.
      await (_db.update(_db.merchantMappings)
            ..where((m) => m.id.equals(existing.id)))
          .write(MerchantMappingsCompanion(
        category: Value(category),
        updatedAt: Value(now),
        useCount: Value(existing.useCount + 1),
      ));
    } else {
      // Create new mapping.
      await _db.into(_db.merchantMappings).insert(
            MerchantMappingsCompanion.insert(
              id: _uuid.v4(),
              merchantToken: merchantToken,
              category: category,
              source: 'userCorrected',
              confidence: 1.0,
              createdAt: now,
              updatedAt: now,
            ),
          );
    }
  }

  /// Backfill: update all other transactions with the same merchantToken
  /// that are uncategorized or have low confidence.
  /// Returns the count of updated transactions.
  Future<int> _backfill(
      String merchantToken, String newCategory, int excludeId) async {
    final targets = await ((_db.select(_db.spendlerTransactions))
          ..where((t) =>
              t.merchantToken.equals(merchantToken) &
              t.id.equals(excludeId).not() &
              (t.categorizationSource.equals('uncategorized') |
                  t.categorizationSource.isNull())))
        .get();

    if (targets.isEmpty) return 0;

    for (final target in targets) {
      await (_db.update(_db.spendlerTransactions)
            ..where((t) => t.id.equals(target.id)))
          .write(SpendlerTransactionsCompanion(
        category: Value(newCategory),
        categorizationSource: const Value('user'),
        categorizationConfidence: const Value(1.0),
      ));
    }

    return targets.length;
  }
}
