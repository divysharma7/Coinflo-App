import 'package:finance_buddy_app/services/saraswati/entry/transaction_draft.dart';

/// The output of the disambiguation engine.
///
/// Determines what happens after a [TransactionDraft] is extracted:
/// - [SilentCommitAction]: all fields confident, commit immediately + show undo
/// - [AskOneQuestionAction]: one field uncertain, ask user via chips
/// - [QuickFormFallbackAction]: multiple uncertain or LLM unavailable, open form
sealed class EntryAction {
  const EntryAction();
}

/// All required fields present and confident. Commit without asking.
class SilentCommitAction extends EntryAction {
  final TransactionDraft draft;
  const SilentCommitAction(this.draft);
}

/// One field needs confirmation. Show a chip-based question.
class AskOneQuestionAction extends EntryAction {
  final TransactionDraft partialDraft;
  final String fieldToConfirm; // 'amount' | 'counterparty' | 'category' | ...
  final String questionText; // human-readable question
  final List<String> chipOptions; // 2-5 short answers

  const AskOneQuestionAction({
    required this.partialDraft,
    required this.fieldToConfirm,
    required this.questionText,
    required this.chipOptions,
  });
}

/// Too uncertain or LLM unavailable. Open the quick-add form.
class QuickFormFallbackAction extends EntryAction {
  final TransactionDraft? partialDraft;
  final String reason; // for logging

  const QuickFormFallbackAction({
    this.partialDraft,
    required this.reason,
  });
}
