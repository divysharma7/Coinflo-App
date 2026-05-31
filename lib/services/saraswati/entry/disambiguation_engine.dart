import 'package:finance_buddy_app/services/saraswati/entry/amount_sanity_checker.dart';
import 'package:finance_buddy_app/services/saraswati/entry/entry_action.dart';
import 'package:finance_buddy_app/services/saraswati/entry/transaction_draft.dart';

/// The brain of the entry pipeline. Evaluates a [TransactionDraft] and
/// decides whether to commit silently, ask one question, or fall back to form.
///
/// Decision matrix (first match wins):
/// 1. kind == unknown OR draft is null -> QuickFormFallback
/// 2. Amount fails sanity check -> AskOneQuestion(amount)
/// 3. 2+ required fields missing or below 0.85 -> QuickFormFallback
/// 4. kind == split AND otherwise complete -> AskOneQuestion(split_with) [always confirm]
/// 5. Exactly 1 required field missing -> AskOneQuestion
/// 6. Exactly 1 field below 0.85 -> AskOneQuestion
/// 7. All good -> SilentCommit
class DisambiguationEngine {
  const DisambiguationEngine({
    this.sanityChecker = const AmountSanityChecker(),
  });

  final AmountSanityChecker sanityChecker;

  /// Evaluate a [draft] and return the appropriate [EntryAction].
  ///
  /// [userHistoricalMax] is the user's largest transaction amount for sanity checks.
  /// [topCategories] are the user's most frequent categories (for chip generation).
  /// [recentCounterparties] are the user's recent counterparties (for chip generation).
  EntryAction evaluate(
    TransactionDraft? draft, {
    double? userHistoricalMax,
    List<String> topCategories = const [],
    List<String> recentCounterparties = const [],
  }) {
    // Rule 1: null or unknown
    if (draft == null) {
      return const QuickFormFallbackAction(reason: 'unrecognized');
    }

    final missing = draft.missingRequiredFields();
    final uncertain = draft.uncertainFields();

    // Rule 2: amount sanity check
    if (draft.amount != null &&
        !sanityChecker.isSane(draft.amount!,
            userHistoricalMax: userHistoricalMax)) {
      return AskOneQuestionAction(
        partialDraft: draft,
        fieldToConfirm: 'amount',
        questionText: 'That amount seems unusual. Is it correct?',
        chipOptions: sanityChecker.chipSuggestions(draft.amount!),
      );
    }

    // Rule 3: 2+ fields problematic -> form fallback
    final problemCount = missing.length + uncertain.length;
    if (problemCount >= 2) {
      return QuickFormFallbackAction(
        partialDraft: draft,
        reason: 'too_uncertain',
      );
    }

    // Rule 4: splits always confirm
    if (draft.kind == TransactionKind.split &&
        missing.isEmpty &&
        uncertain.isEmpty) {
      final splitNames = draft.splitWith ?? [];
      final chipOptions = [
        if (splitNames.isNotEmpty) 'Yes, split with ${splitNames.join(", ")}',
        ...recentCounterparties.take(3),
        'Change people',
      ];
      return AskOneQuestionAction(
        partialDraft: draft,
        fieldToConfirm: 'split_with',
        questionText: 'Confirm split?',
        chipOptions: chipOptions,
      );
    }

    // Rule 5: exactly 1 required field missing
    if (missing.length == 1 && uncertain.isEmpty) {
      return _askForMissing(draft, missing.first,
          topCategories: topCategories,
          recentCounterparties: recentCounterparties);
    }

    // Rule 6: exactly 1 field uncertain
    if (missing.isEmpty && uncertain.length == 1) {
      return _askForUncertain(draft, uncertain.first,
          topCategories: topCategories,
          recentCounterparties: recentCounterparties);
    }

    // Edge: 1 missing + 0 uncertain or 0 missing + 1 uncertain already handled.
    // If we have 1 total problem (from combined missing+uncertain = 1), handle it.
    if (problemCount == 1) {
      final field = missing.isNotEmpty ? missing.first : uncertain.first;
      if (missing.isNotEmpty) {
        return _askForMissing(draft, field,
            topCategories: topCategories,
            recentCounterparties: recentCounterparties);
      }
      return _askForUncertain(draft, field,
          topCategories: topCategories,
          recentCounterparties: recentCounterparties);
    }

    // Rule 7: all good -> silent commit
    return SilentCommitAction(draft);
  }

  // ─── Chip Generation (deterministic, no LLM) ─────────

  EntryAction _askForMissing(
    TransactionDraft draft,
    String field, {
    required List<String> topCategories,
    required List<String> recentCounterparties,
  }) {
    return AskOneQuestionAction(
      partialDraft: draft,
      fieldToConfirm: field,
      questionText: _questionForField(field),
      chipOptions: _chipsForField(field,
          topCategories: topCategories,
          recentCounterparties: recentCounterparties),
    );
  }

  EntryAction _askForUncertain(
    TransactionDraft draft,
    String field, {
    required List<String> topCategories,
    required List<String> recentCounterparties,
  }) {
    // Include the LLM's guess as the first chip option.
    final guessChips = <String>[];
    switch (field) {
      case 'category':
        if (draft.category != null) guessChips.add(draft.category!);
      case 'counterparty':
        if (draft.counterparty != null) guessChips.add(draft.counterparty!);
      case 'amount':
        if (draft.amount != null) {
          guessChips.add(draft.amount!.toStringAsFixed(
              draft.amount == draft.amount!.roundToDouble() ? 0 : 2));
        }
    }

    final baseChips = _chipsForField(field,
        topCategories: topCategories,
        recentCounterparties: recentCounterparties);

    // Merge: guess first, then base options (deduplicated).
    final merged = <String>[...guessChips];
    for (final chip in baseChips) {
      if (!merged.contains(chip)) merged.add(chip);
    }

    return AskOneQuestionAction(
      partialDraft: draft,
      fieldToConfirm: field,
      questionText: _questionForField(field),
      chipOptions: merged.take(5).toList(),
    );
  }

  String _questionForField(String field) {
    return switch (field) {
      'amount' => 'How much was it?',
      'category' => 'What category is this?',
      'counterparty' => 'Who was this with?',
      'date' => 'When did this happen?',
      'payer' => 'Who paid?',
      'split_with' => 'Who are you splitting with?',
      _ => 'Can you clarify?',
    };
  }

  List<String> _chipsForField(
    String field, {
    required List<String> topCategories,
    required List<String> recentCounterparties,
  }) {
    return switch (field) {
      'category' => [
          ...topCategories.take(3),
          'Other',
        ],
      'counterparty' => [
          ...recentCounterparties.take(3),
          'Someone else',
        ],
      'amount' => ['Enter manually'],
      'date' => ['Today', 'Yesterday'],
      'payer' => ['I paid', 'They paid', 'Split equally'],
      _ => ['Enter manually'],
    };
  }
}
