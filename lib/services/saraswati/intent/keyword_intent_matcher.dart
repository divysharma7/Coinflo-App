import 'package:finance_buddy_app/services/saraswati/intent/saraswati_intent.dart';

/// Matches a normalized query against the 15 keyword rules (Stage 1).
///
/// Returns the first matching [SaraswatiIntent], or `null` if no
/// keyword rule fires. Priority order matches the original handler chain.
class KeywordIntentMatcher {
  const KeywordIntentMatcher();

  SaraswatiIntent? match(String q) {
    // Run the 15 keyword rules in priority order. First match wins.
    return _matchTodaySpending(q) ??
        _matchThisWeek(q) ??
        _matchThisMonth(q) ??
        _matchLastMonth(q) ??
        _matchCategoryBreakdown(q) ??
        _matchCategorySpecific(q) ??
        _matchTopMerchants(q) ??
        _matchWeekComparison(q) ??
        _matchMonthComparison(q) ??
        _matchBiggestExpense(q) ??
        _matchTransactionCount(q) ??
        _matchDailyAverage(q) ??
        _matchIncome(q) ??
        _matchSplits(q) ??
        _matchHelp(q);
  }

  // ─── 1. Today spending ─────────────────────────────────

  SaraswatiIntent? _matchTodaySpending(String q) {
    if (!_any(q, ['today', 'spent today', 'today spend', 'aaj', 'how much today'])) {
      return null;
    }
    return const TodaySpendingIntent();
  }

  // ─── 2. This week ──────────────────────────────────────

  SaraswatiIntent? _matchThisWeek(String q) {
    if (!_any(q, ['this week', 'week spend', 'weekly', 'is hafte', 'current week'])) {
      return null;
    }
    return const PeriodSpendingIntent(Period.thisWeek);
  }

  // ─── 3. This month ────────────────────────────────────

  SaraswatiIntent? _matchThisMonth(String q) {
    if (!_any(q, [
      'this month', 'month spend', 'monthly total', 'is mahine', 'current month',
    ])) {
      return null;
    }
    return const PeriodSpendingIntent(Period.thisMonth);
  }

  // ─── 4. Last month ────────────────────────────────────

  SaraswatiIntent? _matchLastMonth(String q) {
    if (!_any(q, ['last month', 'previous month', 'pichla mahina'])) {
      return null;
    }
    return const PeriodSpendingIntent(Period.lastMonth);
  }

  // ─── 5. Category breakdown ─────────────────────────────

  SaraswatiIntent? _matchCategoryBreakdown(String q) {
    if (!_any(q, [
      'category breakdown', 'by category', 'categories',
      'where am i spending', 'where do i spend', 'breakdown',
    ])) {
      return null;
    }
    return const CategoryBreakdownIntent(Period.thisMonth);
  }

  // ─── 6. Category-specific ──────────────────────────────

  SaraswatiIntent? _matchCategorySpecific(String q) {
    // Direct category matches
    final categories = ['rent', 'transport', 'food', 'family', 'social', 'other'];
    String? matched;
    for (final cat in categories) {
      if (q.contains(cat)) {
        matched = cat;
        break;
      }
    }

    // Merchant → category aliases
    String? merchant;
    if (matched == null) {
      if (q.contains('travel') || q.contains('cab') || q.contains('uber') ||
          q.contains('ola')) {
        matched = 'transport';
        if (q.contains('uber')) merchant = 'uber';
        if (q.contains('ola')) merchant = 'ola';
      }
      if (q.contains('grocery') || q.contains('zomato') || q.contains('swiggy') ||
          q.contains('eat') || q.contains('restaurant')) {
        matched = 'food';
        if (q.contains('zomato')) merchant = 'zomato';
        if (q.contains('swiggy')) merchant = 'swiggy';
      }
      if (q.contains('housing') || q.contains('apartment')) matched = 'rent';
    }
    if (matched == null) return null;

    // Must also signal a spending question
    if (!_any(q, [
      'how much', 'spend', 'spent', 'total', 'kitna', 'expense', matched,
    ])) {
      return null;
    }

    return CategorySpecificIntent(
      category: matched,
      period: Period.thisMonth,
      merchant: merchant,
    );
  }

  // ─── 7. Top merchants ─────────────────────────────────

  SaraswatiIntent? _matchTopMerchants(String q) {
    if (!_any(q, [
      'top merchant', 'where do i shop', 'most frequent', 'top places',
      'favourite', 'favorite', 'frequent merchant',
    ])) {
      return null;
    }
    return const TopMerchantsIntent(period: Period.thisMonth);
  }

  // ─── 8. Week-over-week comparison ──────────────────────

  SaraswatiIntent? _matchWeekComparison(String q) {
    if (!_any(q, [
      'week over week', 'compared to last week', 'vs last week',
      'week comparison', 'week trend',
    ])) {
      return null;
    }
    return const PeriodComparisonIntent(ComparisonKind.weekOverWeek);
  }

  // ─── 9. Month-over-month comparison ────────────────────

  SaraswatiIntent? _matchMonthComparison(String q) {
    if (!_any(q, [
      'month over month', 'compared to last month', 'vs last month',
      'month comparison', 'monthly trend',
    ])) {
      return null;
    }
    return const PeriodComparisonIntent(ComparisonKind.monthOverMonth);
  }

  // ─── 10. Biggest expense ───────────────────────────────

  SaraswatiIntent? _matchBiggestExpense(String q) {
    if (!_any(q, [
      'biggest', 'largest', 'most expensive', 'highest', 'max spend',
      'sabse bada',
    ])) {
      return null;
    }
    return const BiggestExpenseIntent(Period.thisMonth);
  }

  // ─── 11. Transaction count ─────────────────────────────

  SaraswatiIntent? _matchTransactionCount(String q) {
    if (!_any(q, [
      'how many transactions', 'transaction count', 'number of transactions',
      'kitne transactions',
    ])) {
      return null;
    }
    return const TransactionCountIntent(Period.thisMonth);
  }

  // ─── 12. Daily average ─────────────────────────────────

  SaraswatiIntent? _matchDailyAverage(String q) {
    if (!_any(q, [
      'daily average', 'average per day', 'per day', 'average spend',
      'avg spend',
    ])) {
      return null;
    }
    return const DailyAverageIntent(Period.thisMonth);
  }

  // ─── 13. Income ────────────────────────────────────────

  SaraswatiIntent? _matchIncome(String q) {
    if (!_any(q, ['income', 'earned', 'received', 'credit', 'salary'])) {
      return null;
    }
    return const IncomeIntent(Period.thisMonth);
  }

  // ─── 14. Splits ────────────────────────────────────────

  SaraswatiIntent? _matchSplits(String q) {
    if (!_any(q, ['split', 'owe', 'pending split', 'unsettled', 'settle'])) {
      return null;
    }
    return const SplitsIntent();
  }

  // ─── 15. Help ──────────────────────────────────────────

  SaraswatiIntent? _matchHelp(String q) {
    if (!_any(q, ['help', 'what can you', 'can you do', 'commands', 'kya kar sakti'])) {
      return null;
    }
    return const HelpIntent();
  }

  // ─── Utilities ─────────────────────────────────────────

  bool _any(String query, List<String> keywords) {
    return keywords.any((k) => query.contains(k));
  }
}
