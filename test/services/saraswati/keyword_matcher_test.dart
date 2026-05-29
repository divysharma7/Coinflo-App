import 'package:flutter_test/flutter_test.dart';
import 'package:finance_buddy_app/services/saraswati/intent/keyword_intent_matcher.dart';
import 'package:finance_buddy_app/services/saraswati/intent/saraswati_intent.dart';

void main() {
  const matcher = KeywordIntentMatcher();

  group('1. Today spending', () {
    test('"spent today" -> TodaySpendingIntent', () {
      expect(matcher.match('spent today'), isA<TodaySpendingIntent>());
    });

    test('"aaj" -> TodaySpendingIntent', () {
      expect(matcher.match('aaj'), isA<TodaySpendingIntent>());
    });
  });

  group('2. This week', () {
    test('"this week" -> PeriodSpendingIntent(thisWeek)', () {
      final result = matcher.match('this week');
      expect(result, isA<PeriodSpendingIntent>());
      expect((result as PeriodSpendingIntent).period, Period.thisWeek);
    });

    test('"is hafte" -> PeriodSpendingIntent(thisWeek)', () {
      final result = matcher.match('is hafte');
      expect(result, isA<PeriodSpendingIntent>());
      expect((result as PeriodSpendingIntent).period, Period.thisWeek);
    });
  });

  group('3. This month', () {
    test('"this month" -> PeriodSpendingIntent(thisMonth)', () {
      final result = matcher.match('this month');
      expect(result, isA<PeriodSpendingIntent>());
      expect((result as PeriodSpendingIntent).period, Period.thisMonth);
    });

    test('"is mahine" -> PeriodSpendingIntent(thisMonth)', () {
      final result = matcher.match('is mahine');
      expect(result, isA<PeriodSpendingIntent>());
      expect((result as PeriodSpendingIntent).period, Period.thisMonth);
    });
  });

  group('4. Last month', () {
    test('"last month" -> PeriodSpendingIntent(lastMonth)', () {
      final result = matcher.match('last month');
      expect(result, isA<PeriodSpendingIntent>());
      expect((result as PeriodSpendingIntent).period, Period.lastMonth);
    });

    test('"pichla mahina" -> PeriodSpendingIntent(lastMonth)', () {
      final result = matcher.match('pichla mahina');
      expect(result, isA<PeriodSpendingIntent>());
      expect((result as PeriodSpendingIntent).period, Period.lastMonth);
    });
  });

  group('5. Category breakdown', () {
    test('"by category" -> CategoryBreakdownIntent(thisMonth)', () {
      final result = matcher.match('by category');
      expect(result, isA<CategoryBreakdownIntent>());
      expect((result as CategoryBreakdownIntent).period, Period.thisMonth);
    });

    test('"breakdown" -> CategoryBreakdownIntent(thisMonth)', () {
      final result = matcher.match('breakdown');
      expect(result, isA<CategoryBreakdownIntent>());
      expect((result as CategoryBreakdownIntent).period, Period.thisMonth);
    });
  });

  group('6. Category-specific', () {
    test('"food spending" -> CategorySpecificIntent(food)', () {
      final result = matcher.match('food spending');
      expect(result, isA<CategorySpecificIntent>());
      final r = result as CategorySpecificIntent;
      expect(r.category, 'food');
      expect(r.period, Period.thisMonth);
    });

    test('"how much on transport" -> CategorySpecificIntent(transport)', () {
      final result = matcher.match('how much on transport');
      expect(result, isA<CategorySpecificIntent>());
      final r = result as CategorySpecificIntent;
      expect(r.category, 'transport');
      expect(r.period, Period.thisMonth);
    });

    test('"zomato spend" -> CategorySpecificIntent(food, merchant=zomato)', () {
      final result = matcher.match('zomato spend');
      expect(result, isA<CategorySpecificIntent>());
      final r = result as CategorySpecificIntent;
      expect(r.category, 'food');
      expect(r.merchant, 'zomato');
    });
  });

  group('7. Top merchants', () {
    test('"top merchant" -> TopMerchantsIntent', () {
      final result = matcher.match('top merchant');
      expect(result, isA<TopMerchantsIntent>());
      expect((result as TopMerchantsIntent).period, Period.thisMonth);
    });

    test('"favourite" -> TopMerchantsIntent', () {
      final result = matcher.match('favourite');
      expect(result, isA<TopMerchantsIntent>());
    });
  });

  group('8. Week-over-week comparison', () {
    test('"vs last week" -> PeriodComparisonIntent(weekOverWeek)', () {
      final result = matcher.match('vs last week');
      expect(result, isA<PeriodComparisonIntent>());
      expect(
        (result as PeriodComparisonIntent).kind,
        ComparisonKind.weekOverWeek,
      );
    });
  });

  group('9. Month-over-month comparison', () {
    test('"month over month" -> PeriodComparisonIntent(monthOverMonth)', () {
      final result = matcher.match('month over month');
      expect(result, isA<PeriodComparisonIntent>());
      expect(
        (result as PeriodComparisonIntent).kind,
        ComparisonKind.monthOverMonth,
      );
    });
  });

  group('10. Biggest expense', () {
    test('"biggest" -> BiggestExpenseIntent(thisMonth)', () {
      final result = matcher.match('biggest');
      expect(result, isA<BiggestExpenseIntent>());
      expect((result as BiggestExpenseIntent).period, Period.thisMonth);
    });

    test('"sabse bada" -> BiggestExpenseIntent(thisMonth)', () {
      final result = matcher.match('sabse bada');
      expect(result, isA<BiggestExpenseIntent>());
      expect((result as BiggestExpenseIntent).period, Period.thisMonth);
    });
  });

  group('11. Transaction count', () {
    test('"how many transactions" -> TransactionCountIntent(thisMonth)', () {
      final result = matcher.match('how many transactions');
      expect(result, isA<TransactionCountIntent>());
      expect((result as TransactionCountIntent).period, Period.thisMonth);
    });
  });

  group('12. Daily average', () {
    test('"daily average" -> DailyAverageIntent(thisMonth)', () {
      final result = matcher.match('daily average');
      expect(result, isA<DailyAverageIntent>());
      expect((result as DailyAverageIntent).period, Period.thisMonth);
    });
  });

  group('13. Income', () {
    test('"income" -> IncomeIntent(thisMonth)', () {
      final result = matcher.match('income');
      expect(result, isA<IncomeIntent>());
      expect((result as IncomeIntent).period, Period.thisMonth);
    });

    test('"salary" -> IncomeIntent(thisMonth)', () {
      final result = matcher.match('salary');
      expect(result, isA<IncomeIntent>());
      expect((result as IncomeIntent).period, Period.thisMonth);
    });
  });

  group('14. Splits', () {
    test('"unsettled" -> SplitsIntent', () {
      expect(matcher.match('unsettled'), isA<SplitsIntent>());
    });

    test('"owe" -> SplitsIntent', () {
      expect(matcher.match('owe'), isA<SplitsIntent>());
    });
  });

  group('15. Help', () {
    test('"help" -> HelpIntent', () {
      expect(matcher.match('help'), isA<HelpIntent>());
    });

    test('"kya kar sakti" -> HelpIntent', () {
      expect(matcher.match('kya kar sakti'), isA<HelpIntent>());
    });
  });

  group('16. No match', () {
    test('"what is the weather" -> null', () {
      expect(matcher.match('what is the weather'), isNull);
    });

    test('"tell me a joke" -> null', () {
      expect(matcher.match('tell me a joke'), isNull);
    });
  });
}
