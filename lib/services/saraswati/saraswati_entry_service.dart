import 'package:finance_buddy_app/services/saraswati/entry/disambiguation_engine.dart';
import 'package:finance_buddy_app/services/saraswati/entry/entry_action.dart';
import 'package:finance_buddy_app/services/saraswati/entry/entry_cache_repository.dart';
import 'package:finance_buddy_app/services/saraswati/entry/entry_normalizer.dart';
import 'package:finance_buddy_app/services/saraswati/entry/pattern_matcher.dart';
import 'package:finance_buddy_app/services/saraswati/entry/personal_defaults_repository.dart';
import 'package:finance_buddy_app/services/saraswati/entry/quickadd_matcher.dart';
import 'package:finance_buddy_app/services/saraswati/entry/transaction_draft.dart';
import 'package:finance_buddy_app/services/saraswati/entry/llm/llm_entry_extractor.dart';

/// Orchestrates the entry pipeline: Stages 0->1->2->3 -> defaults -> disambig.
///
/// Parallel to [SaraswatiService] (which handles queries).
/// Called by the router when input is classified as an entry.
class SaraswatiEntryService {
  SaraswatiEntryService({
    required QuickaddMatcher quickaddMatcher,
    required PatternMatcher patternMatcher,
    required EntryCacheRepository cache,
    required LlmEntryExtractor llm,
    required PersonalDefaultsRepository defaults,
    required DisambiguationEngine disambiguation,
  })  : _quickadd = quickaddMatcher,
        _pattern = patternMatcher,
        _cache = cache,
        _llm = llm,
        _defaults = defaults,
        _disambiguation = disambiguation;

  final QuickaddMatcher _quickadd;
  final PatternMatcher _pattern;
  final EntryCacheRepository _cache;
  final LlmEntryExtractor _llm;
  final PersonalDefaultsRepository _defaults;
  final DisambiguationEngine _disambiguation;

  /// Process a raw entry input through the 4-stage pipeline.
  ///
  /// Returns an [EntryAction] that the UI should handle:
  /// - [SilentCommitAction]: commit + show undo
  /// - [AskOneQuestionAction]: show chip-based question
  /// - [QuickFormFallbackAction]: open quick-add form
  Future<EntryAction> processEntry(
    String rawInput, {
    double? userHistoricalMax,
    List<String> topCategories = const [],
    List<String> recentCounterparties = const [],
  }) async {
    final normalized = EntryNormalizer.normalize(rawInput);

    if (normalized.isEmpty) {
      return const QuickFormFallbackAction(reason: 'empty_input');
    }

    // Stage 0: Quickadd shortcuts (deterministic, instant).
    var draft = _quickadd.match(normalized);

    // Stage 1: Pattern templates (fuzzier, still no LLM).
    draft ??= _pattern.match(normalized);

    // Stage 2: Entry cache.
    draft ??= await _cache.lookup(normalized);

    // Stage 3: LLM extractor (Gemini function calling).
    draft ??= await _llm.extract(normalized);

    // Apply personal defaults (AFTER extraction, BEFORE disambiguation).
    if (draft != null) {
      draft = await _applyDefaults(draft);
    }

    // Disambiguation engine decides the action.
    return _disambiguation.evaluate(
      draft,
      userHistoricalMax: userHistoricalMax,
      topCategories: topCategories,
      recentCounterparties: recentCounterparties,
    );
  }

  /// Cache a successfully committed draft for future lookups.
  Future<void> cacheConfirmedEntry(
      String rawInput, TransactionDraft draft) async {
    final normalized = EntryNormalizer.normalize(rawInput);
    await _cache.insert(normalized, draft);
    await _cache.confirm(normalized);
  }

  // ─── Private ──────────────────────────────────────────

  /// Apply learned personal defaults to raise confidence on known patterns.
  Future<TransactionDraft> _applyDefaults(TransactionDraft draft) async {
    var updated = draft;
    final confidence = Map<String, double>.from(draft.fieldConfidence);

    // Try counterparty default (e.g. "rahul" -> split_equal).
    final counterpartyName =
        draft.counterparty?.toLowerCase() ?? draft.splitWith?.firstOrNull?.toLowerCase();
    if (counterpartyName != null) {
      final defaultPayer =
          await _defaults.getDefault('counterparty:$counterpartyName');
      if (defaultPayer != null && draft.payer == null) {
        final payerKind = PayerKind.values.firstWhere(
          (p) => p.toJson() == defaultPayer,
          orElse: () => PayerKind.user,
        );
        // If default says split, upgrade to split kind.
        if (payerKind == PayerKind.splitEqual ||
            payerKind == PayerKind.splitCustom) {
          updated = updated.copyWith(
            kind: TransactionKind.split,
            payer: () => payerKind,
          );
          confidence['payer'] = 0.90;
        }
      }
    }

    // Try category default (e.g. "groceries" -> "household").
    if (draft.counterparty != null && draft.category == null) {
      final defaultCategory = await _defaults
          .getDefault('category_for:${draft.counterparty!.toLowerCase()}');
      if (defaultCategory != null) {
        updated = updated.copyWith(category: () => defaultCategory);
        confidence['category'] = 0.90;
      }
    }

    return updated.copyWith(fieldConfidence: confidence);
  }
}
