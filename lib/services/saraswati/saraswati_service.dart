import 'package:finance_buddy_app/services/saraswati/cache/intent_cache_repository.dart';
import 'package:finance_buddy_app/services/saraswati/intent/intent_executor.dart';
import 'package:finance_buddy_app/services/saraswati/intent/intent_normalizer.dart';
import 'package:finance_buddy_app/services/saraswati/intent/keyword_intent_matcher.dart';
import 'package:finance_buddy_app/services/saraswati/intent/saraswati_intent.dart';
import 'package:finance_buddy_app/services/saraswati/llm/llm_intent_classifier.dart';

/// 4-tier intent resolution pipeline for the Ask Saraswati assistant.
///
/// Stage 0: Exact match (suggestion chips + user-confirmed cache entries)
/// Stage 1: 15 keyword handlers (deterministic, offline)
/// Stage 2: Intent cache (phrases previously classified by the LLM)
/// Stage 3: Gemini function-calling classifier → cache on success
///
/// The LLM never computes numbers — all math comes from [IntentExecutor]
/// via [BaseRepository].
class SaraswatiService {
  SaraswatiService({
    required IntentExecutor executor,
    required KeywordIntentMatcher keywordMatcher,
    required IntentCacheRepository cache,
    required LlmIntentClassifier llm,
  })  : _executor = executor,
        _keywordMatcher = keywordMatcher,
        _cache = cache,
        _llm = llm;

  final IntentExecutor _executor;
  final KeywordIntentMatcher _keywordMatcher;
  final IntentCacheRepository _cache;
  final LlmIntentClassifier _llm;

  /// Hardcoded suggestion chip phrases for Stage 0 exact matching.
  static const _suggestionPhrases = <String, SaraswatiIntent>{
    'how much did i spend this month?':
        PeriodSpendingIntent(Period.thisMonth),
    'what is my top spending category?':
        CategoryBreakdownIntent(Period.thisMonth),
    'show my spending by category':
        CategoryBreakdownIntent(Period.thisMonth),
    'how does this month compare to last month?':
        PeriodComparisonIntent(ComparisonKind.monthOverMonth),
  };

  /// Process a user query and return Saraswati's markdown-formatted answer.
  ///
  /// [context] is an optional financial summary injected from providers.
  Future<String> ask(String rawQuery, {String? context}) async {
    final normalized = IntentNormalizer.normalize(rawQuery);

    // Edge case: empty/whitespace query
    if (normalized.isEmpty) {
      return _executor.execute(
        const HelpIntent(),
        financialContext: context,
      );
    }

    // Stage 0: exact match (suggestion chips + confirmed cache)
    var intent = await _exactMatch(normalized);
    if (intent != null) {
      return _executor.execute(intent, financialContext: context);
    }

    // Stage 1: keyword handlers (existing 15 rules, deterministic)
    intent = _keywordMatcher.match(normalized);
    if (intent != null) {
      return _executor.execute(intent, financialContext: context);
    }

    // Stage 2: intent cache (previously classified by LLM)
    intent = await _cache.lookup(normalized);
    if (intent != null) {
      return _executor.execute(intent, financialContext: context);
    }

    // Stage 3: LLM classifier (Gemini function calling)
    intent = await _llm.classify(normalized);
    if (intent != null && intent is! UnknownIntent) {
      await _cache.insert(normalized, intent);
      return _executor.execute(intent, financialContext: context);
    }

    // Friendly fallback — never crashes, always returns something useful.
    return _buildFallback(context);
  }

  /// Correct a previous classification and re-execute.
  ///
  /// Invalidates the old cache entry, inserts the corrected intent,
  /// marks it as user-confirmed, and returns the new response.
  Future<String> correctIntent(
    String rawQuery,
    SaraswatiIntent correctedIntent, {
    String? context,
  }) async {
    final normalized = IntentNormalizer.normalize(rawQuery);
    await _cache.invalidate(normalized);
    await _cache.insert(normalized, correctedIntent);
    await _cache.confirm(normalized);
    return _executor.execute(correctedIntent, financialContext: context);
  }

  // ─── Private ───────────────────────────────────────────

  Future<SaraswatiIntent?> _exactMatch(String normalized) async {
    // Check suggestion chip phrases first
    final chipMatch = _suggestionPhrases[normalized];
    if (chipMatch != null) return chipMatch;

    // Check user-confirmed cache entries
    final confirmedQueries = await _cache.recentConfirmedQueries();
    if (confirmedQueries.contains(normalized)) {
      return _cache.lookup(normalized);
    }

    return null;
  }

  String _buildFallback(String? context) {
    final buf = StringBuffer()
      ..write("Hmm, I'm not sure I follow that one! Try asking about your "
          "spending — like *\"how much did I spend today?\"* or "
          "*\"show me a category breakdown\"*. "
          "Type **help** to see everything I can do!");

    if (context != null && context.isNotEmpty) {
      buf.writeln();
      buf.writeln();
      buf.write('Here\'s a quick snapshot: $context');
    }

    return buf.toString();
  }
}
