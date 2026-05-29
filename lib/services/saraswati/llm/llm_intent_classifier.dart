import 'dart:async';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';
import 'package:finance_buddy_app/services/saraswati/intent/saraswati_intent.dart';
import 'package:finance_buddy_app/services/saraswati/llm/intent_function_schema.dart';


/// Classifies a user query into a [SaraswatiIntent] using Gemini
/// function calling. Stage 3 of the intent resolution pipeline.
///
/// Returns `null` on any failure (timeout, network, parse error).
/// Never throws.
class LlmIntentClassifier {
  LlmIntentClassifier(this._model);

  final GenerativeModel _model;

  /// Classify [normalizedQuery] into a typed intent.
  ///
  /// - Truncates to 200 chars as a guard.
  /// - Enforces a 2-second timeout.
  /// - Returns `null` on any error — never throws.
  Future<SaraswatiIntent?> classify(String normalizedQuery) async {
    final query = normalizedQuery.length > 200
        ? normalizedQuery.substring(0, 200)
        : normalizedQuery;

    try {
      final response = await _model
          .generateContent(
            [Content.text(query)],
            tools: [Tool.functionDeclarations([kClassifyIntentFunction])],
            toolConfig: ToolConfig(
              functionCallingConfig:
                  FunctionCallingConfig.any({'classify_finance_intent'}),
            ),
          )
          .timeout(const Duration(seconds: 2));

      final calls = response.functionCalls.toList();
      if (calls.isEmpty) {
        debugPrint('[Saraswati LLM] No function call in response');
        return null;
      }

      return _parseIntent(calls.first.args);
    } on TimeoutException {
      debugPrint('[Saraswati LLM] Classifier timed out');
      return null;
    } on Exception catch (e) {
      debugPrint('[Saraswati LLM] Classifier failed: $e');
      return null;
    }
  }

  /// Parse the function call arguments into a [SaraswatiIntent].
  ///
  /// Returns `null` if required slots are missing for the chosen intent.
  SaraswatiIntent? _parseIntent(Map<String, Object?> args) {
    final intentStr = args['intent'] as String?;
    if (intentStr == null) return null;

    final periodStr = args['period'] as String?;
    final period =
        periodStr != null ? _parsePeriod(periodStr) : Period.thisMonth;
    final category = args['category'] as String?;
    final merchant = args['merchant'] as String?;
    final limit = args['limit'] as int? ?? 5;
    final comparisonStr = args['comparison_kind'] as String?;
    final reason = args['reason'] as String?;

    return switch (intentStr) {
      'today_spending' => const TodaySpendingIntent(),
      'period_spending' => PeriodSpendingIntent(period),
      'category_specific' => category != null
          ? CategorySpecificIntent(
              category: category,
              period: period,
              merchant: merchant,
            )
          : null, // Missing required slot
      'category_breakdown' => CategoryBreakdownIntent(period),
      'top_merchants' => TopMerchantsIntent(period: period, limit: limit),
      'period_comparison' => PeriodComparisonIntent(
          comparisonStr != null
              ? _parseComparison(comparisonStr)
              : ComparisonKind.monthOverMonth,
        ),
      'biggest_expense' => BiggestExpenseIntent(period),
      'transaction_count' => TransactionCountIntent(period),
      'daily_average' => DailyAverageIntent(period),
      'income' => IncomeIntent(period),
      'splits' => const SplitsIntent(),
      'help' => const HelpIntent(),
      'unknown' => UnknownIntent(reason: reason ?? 'not finance'),
      _ => null,
    };
  }

  Period _parsePeriod(String raw) {
    return switch (raw) {
      'today' => Period.today,
      'this_week' => Period.thisWeek,
      'last_week' => Period.lastWeek,
      'this_month' => Period.thisMonth,
      'last_month' => Period.lastMonth,
      _ => Period.thisMonth,
    };
  }

  ComparisonKind _parseComparison(String raw) {
    return switch (raw) {
      'week_over_week' => ComparisonKind.weekOverWeek,
      'month_over_month' => ComparisonKind.monthOverMonth,
      _ => ComparisonKind.monthOverMonth,
    };
  }
}
