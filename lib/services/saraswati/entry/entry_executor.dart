import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:finance_buddy_app/data/db.dart';
import 'package:finance_buddy_app/data/repositories/base_repository.dart';
import 'package:finance_buddy_app/services/saraswati/entry/personal_defaults_repository.dart';
import 'package:finance_buddy_app/services/saraswati/entry/transaction_draft.dart';

/// Commits a confirmed [TransactionDraft] to the database via [BaseRepository].
///
/// Every chat-created transaction is audit-tagged with:
/// - `source = 'saraswati_chat'`
/// - `rawInput` = original chat text
/// - `extractionMeta` = JSON with per-field confidence + extraction stage
class EntryExecutor {
  EntryExecutor(this._repo, this._defaults);

  final BaseRepository _repo;
  final PersonalDefaultsRepository _defaults;

  /// Commit a draft to the database. Returns the inserted transaction ID.
  Future<int> commit(TransactionDraft draft) async {
    final isExpense = draft.kind == TransactionKind.expense;
    final isIncome = draft.kind == TransactionKind.income;

    // Amount sign: negative for expense, positive for income/transfer/split.
    final signedAmount = isExpense ? -(draft.amount!) : draft.amount!;

    final txnType = switch (draft.kind) {
      TransactionKind.expense => 'expense',
      TransactionKind.income => 'income',
      TransactionKind.transfer => 'transfer',
      TransactionKind.split => 'expense', // splits are expenses with split metadata
    };

    final category = draft.category ?? (isIncome ? 'income' : 'other');
    final merchant = draft.counterparty ?? draft.note;
    final extractionMeta = jsonEncode({
      'source': draft.source,
      'field_confidence': draft.fieldConfidence,
    });

    final txnId = await _repo.insertTransaction(
      SpendlerTransactionsCompanion.insert(
        amount: signedAmount,
        category: category,
        merchant: Value(merchant),
        note: Value(draft.note ?? draft.counterparty),
        happenedAt: Value(draft.date ?? DateTime.now()),
        source: const Value('saraswati_chat'),
        status: const Value('confirmed'),
        txnType: Value(txnType),
        rawInput: Value(draft.rawInput),
        extractionMeta: Value(extractionMeta),
        incomeSource: isIncome && category == 'salary'
            ? const Value('salary')
            : const Value(null),
      ),
    );

    // Update personal defaults for learning.
    await _learnDefaults(draft);

    return txnId;
  }

  /// Undo a committed transaction by deleting it.
  Future<void> undo(int transactionId) async {
    await _repo.deleteTransaction(transactionId);
  }

  /// Learn personal defaults from a successful commit.
  ///
  /// Only learns from SilentCommit and AskOneQuestion paths.
  /// Called automatically by [commit].
  Future<void> _learnDefaults(TransactionDraft draft) async {
    // Learn counterparty -> split pattern
    if (draft.kind == TransactionKind.split && draft.counterparty != null) {
      final key = 'counterparty:${draft.counterparty!.toLowerCase()}';
      final payerStr = draft.payer?.toJson() ?? 'splitEqual';
      await _defaults.updateDefault(key, payerStr);
    }

    // Learn counterparty from splitWith names
    if (draft.splitWith != null) {
      for (final name in draft.splitWith!) {
        final key = 'counterparty:${name.toLowerCase()}';
        final payerStr = draft.payer?.toJson() ?? 'splitEqual';
        await _defaults.updateDefault(key, payerStr);
      }
    }

    // Learn category for merchant/counterparty
    if (draft.counterparty != null && draft.category != null) {
      final key = 'category_for:${draft.counterparty!.toLowerCase()}';
      await _defaults.updateDefault(key, draft.category!);
    }
  }
}
