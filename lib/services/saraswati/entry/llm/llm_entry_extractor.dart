import 'dart:async';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';
import 'package:finance_buddy_app/services/saraswati/entry/llm/entry_function_schema.dart';
import 'package:finance_buddy_app/services/saraswati/entry/transaction_draft.dart';

/// Extracts a [TransactionDraft] from natural language using Gemini
/// function calling. Stage 3 of the entry pipeline.
///
/// Returns `null` on any failure (timeout, network, parse error).
/// Never throws. Mirrors [LlmIntentClassifier].
class LlmEntryExtractor {
  LlmEntryExtractor(this._model);

  final GenerativeModel _model;

  /// Extract a transaction draft from [normalizedInput].
  ///
  /// - Truncates to 200 chars as a guard.
  /// - Enforces a 2-second timeout.
  /// - Returns `null` on any error — never throws.
  /// - `kind=unknown` returns a draft (let disambiguation handle it).
  Future<TransactionDraft?> extract(String normalizedInput) async {
    final input = normalizedInput.length > 200
        ? normalizedInput.substring(0, 200)
        : normalizedInput;

    try {
      final response = await _model
          .generateContent(
            [Content.text(input)],
            tools: [Tool.functionDeclarations([kExtractTransactionFunction])],
            toolConfig: ToolConfig(
              functionCallingConfig:
                  FunctionCallingConfig.any({'extract_transaction'}),
            ),
          )
          .timeout(const Duration(seconds: 2));

      final calls = response.functionCalls.toList();
      if (calls.isEmpty) {
        debugPrint('[Saraswati Entry] No function call in response');
        return null;
      }

      return _parseDraft(calls.first.args, normalizedInput);
    } on TimeoutException {
      debugPrint('[Saraswati Entry] Extractor timed out');
      return null;
    } on Exception catch (e) {
      debugPrint('[Saraswati Entry] Extractor failed: $e');
      return null;
    }
  }

  /// Parse the function call arguments into a [TransactionDraft].
  TransactionDraft? _parseDraft(
      Map<String, Object?> args, String rawInput) {
    final kindStr = args['kind'] as String?;
    if (kindStr == null) return null;

    final kind = _parseKind(kindStr);
    final amount = (args['amount'] as num?)?.toDouble();
    final counterparty = args['counterparty'] as String?;
    final category = args['category'] as String?;
    final dateRelative = args['date_relative'] as String?;
    final dateSpecific = args['date_specific'] as String?;
    final payerStr = args['payer'] as String?;
    final splitWithRaw = args['split_with'] as List<dynamic>?;
    final note = args['note'] as String?;
    final confMap = args['field_confidence'] as Map<String, Object?>?;

    // Resolve date.
    final date = _resolveDate(dateRelative, dateSpecific);

    // Parse payer.
    final payer = payerStr != null ? _parsePayer(payerStr) : null;

    // Parse split_with.
    final splitWith = splitWithRaw
        ?.map((e) => e.toString())
        .where((s) => s.isNotEmpty)
        .toList();

    // Parse field confidence.
    final fieldConfidence = <String, double>{};
    if (confMap != null) {
      for (final entry in confMap.entries) {
        final v = entry.value;
        if (v is num) fieldConfidence[entry.key] = v.toDouble();
      }
    }

    return TransactionDraft(
      kind: kind,
      amount: amount,
      counterparty: counterparty,
      category: category,
      date: date,
      payer: payer,
      splitWith: splitWith,
      note: note,
      source: 'llm',
      fieldConfidence: fieldConfidence,
      rawInput: rawInput,
    );
  }

  TransactionKind _parseKind(String raw) {
    return switch (raw) {
      'expense' => TransactionKind.expense,
      'income' => TransactionKind.income,
      'transfer' => TransactionKind.transfer,
      'split' => TransactionKind.split,
      _ => TransactionKind.expense, // unknown treated as expense for draft
    };
  }

  PayerKind _parsePayer(String raw) {
    return switch (raw) {
      'user' => PayerKind.user,
      'counterparty' => PayerKind.counterparty,
      'split_equal' => PayerKind.splitEqual,
      'split_custom' => PayerKind.splitCustom,
      _ => PayerKind.user,
    };
  }

  DateTime _resolveDate(String? relative, String? specific) {
    if (specific != null) {
      try {
        return DateTime.parse(specific);
      } on FormatException {
        // Fall through to relative handling.
      }
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return switch (relative) {
      'yesterday' => today.subtract(const Duration(days: 1)),
      'day_before_yesterday' => today.subtract(const Duration(days: 2)),
      'this_monday' => _dayOfThisWeek(today, DateTime.monday),
      'this_tuesday' => _dayOfThisWeek(today, DateTime.tuesday),
      'this_wednesday' => _dayOfThisWeek(today, DateTime.wednesday),
      'this_thursday' => _dayOfThisWeek(today, DateTime.thursday),
      'this_friday' => _dayOfThisWeek(today, DateTime.friday),
      'this_saturday' => _dayOfThisWeek(today, DateTime.saturday),
      'this_sunday' => _dayOfThisWeek(today, DateTime.sunday),
      'last_week' => today.subtract(const Duration(days: 7)),
      _ => today, // 'today' or null or unrecognized
    };
  }

  DateTime _dayOfThisWeek(DateTime today, int targetWeekday) {
    final diff = targetWeekday - today.weekday;
    return today.add(Duration(days: diff));
  }
}
