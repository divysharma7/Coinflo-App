import 'package:flutter_test/flutter_test.dart';
import 'package:finance_buddy_app/services/saraswati/intent/saraswati_intent.dart';

void main() {
  group('Period JSON round-trip', () {
    for (final period in Period.values) {
      test('${period.name} survives toJson/fromJson', () {
        final json = period.toJson();
        final restored = Period.fromJson(json);
        expect(restored, equals(period));
      });
    }
  });

  group('ComparisonKind JSON round-trip', () {
    for (final kind in ComparisonKind.values) {
      test('${kind.name} survives toJson/fromJson', () {
        final json = kind.toJson();
        final restored = ComparisonKind.fromJson(json);
        expect(restored, equals(kind));
      });
    }
  });

  group('SaraswatiIntent JSON round-trip', () {
    test('TodaySpendingIntent', () {
      const intent = TodaySpendingIntent();
      final json = intent.toJson();
      expect(json, {'type': 'today_spending'});

      final restored = SaraswatiIntent.fromJson(json);
      expect(restored, isA<TodaySpendingIntent>());
    });

    test('PeriodSpendingIntent(thisMonth)', () {
      const intent = PeriodSpendingIntent(Period.thisMonth);
      final json = intent.toJson();
      expect(json, {'type': 'period_spending', 'period': 'thisMonth'});

      final restored = SaraswatiIntent.fromJson(json);
      expect(restored, isA<PeriodSpendingIntent>());
      expect((restored as PeriodSpendingIntent).period, Period.thisMonth);
    });

    test('CategorySpecificIntent with merchant', () {
      const intent = CategorySpecificIntent(
        category: 'food',
        period: Period.thisMonth,
        merchant: 'zomato',
      );
      final json = intent.toJson();
      expect(json, {
        'type': 'category_specific',
        'category': 'food',
        'period': 'thisMonth',
        'merchant': 'zomato',
      });

      final restored = SaraswatiIntent.fromJson(json);
      expect(restored, isA<CategorySpecificIntent>());
      final r = restored as CategorySpecificIntent;
      expect(r.category, 'food');
      expect(r.period, Period.thisMonth);
      expect(r.merchant, 'zomato');
    });

    test('CategorySpecificIntent without merchant', () {
      const intent = CategorySpecificIntent(
        category: 'rent',
        period: Period.lastMonth,
      );
      final json = intent.toJson();
      expect(json, {
        'type': 'category_specific',
        'category': 'rent',
        'period': 'lastMonth',
      });
      expect(json.containsKey('merchant'), isFalse);

      final restored = SaraswatiIntent.fromJson(json);
      expect(restored, isA<CategorySpecificIntent>());
      final r = restored as CategorySpecificIntent;
      expect(r.category, 'rent');
      expect(r.period, Period.lastMonth);
      expect(r.merchant, isNull);
    });

    test('CategoryBreakdownIntent(thisWeek)', () {
      const intent = CategoryBreakdownIntent(Period.thisWeek);
      final json = intent.toJson();
      expect(json, {'type': 'category_breakdown', 'period': 'thisWeek'});

      final restored = SaraswatiIntent.fromJson(json);
      expect(restored, isA<CategoryBreakdownIntent>());
      expect((restored as CategoryBreakdownIntent).period, Period.thisWeek);
    });

    test('TopMerchantsIntent with explicit limit', () {
      const intent = TopMerchantsIntent(period: Period.thisMonth, limit: 3);
      final json = intent.toJson();
      expect(json, {
        'type': 'top_merchants',
        'period': 'thisMonth',
        'limit': 3,
      });

      final restored = SaraswatiIntent.fromJson(json);
      expect(restored, isA<TopMerchantsIntent>());
      final r = restored as TopMerchantsIntent;
      expect(r.period, Period.thisMonth);
      expect(r.limit, 3);
    });

    test('TopMerchantsIntent with default limit', () {
      const intent = TopMerchantsIntent(period: Period.thisMonth);
      final json = intent.toJson();
      expect(json, {
        'type': 'top_merchants',
        'period': 'thisMonth',
        'limit': 5,
      });

      final restored = SaraswatiIntent.fromJson(json);
      expect(restored, isA<TopMerchantsIntent>());
      final r = restored as TopMerchantsIntent;
      expect(r.period, Period.thisMonth);
      expect(r.limit, 5);
    });

    test('PeriodComparisonIntent(weekOverWeek)', () {
      const intent = PeriodComparisonIntent(ComparisonKind.weekOverWeek);
      final json = intent.toJson();
      expect(json, {
        'type': 'period_comparison',
        'comparison_kind': 'weekOverWeek',
      });

      final restored = SaraswatiIntent.fromJson(json);
      expect(restored, isA<PeriodComparisonIntent>());
      expect(
        (restored as PeriodComparisonIntent).kind,
        ComparisonKind.weekOverWeek,
      );
    });

    test('PeriodComparisonIntent(monthOverMonth)', () {
      const intent = PeriodComparisonIntent(ComparisonKind.monthOverMonth);
      final json = intent.toJson();
      expect(json, {
        'type': 'period_comparison',
        'comparison_kind': 'monthOverMonth',
      });

      final restored = SaraswatiIntent.fromJson(json);
      expect(restored, isA<PeriodComparisonIntent>());
      expect(
        (restored as PeriodComparisonIntent).kind,
        ComparisonKind.monthOverMonth,
      );
    });

    test('BiggestExpenseIntent(thisMonth)', () {
      const intent = BiggestExpenseIntent(Period.thisMonth);
      final json = intent.toJson();
      expect(json, {'type': 'biggest_expense', 'period': 'thisMonth'});

      final restored = SaraswatiIntent.fromJson(json);
      expect(restored, isA<BiggestExpenseIntent>());
      expect((restored as BiggestExpenseIntent).period, Period.thisMonth);
    });

    test('TransactionCountIntent(lastMonth)', () {
      const intent = TransactionCountIntent(Period.lastMonth);
      final json = intent.toJson();
      expect(json, {'type': 'transaction_count', 'period': 'lastMonth'});

      final restored = SaraswatiIntent.fromJson(json);
      expect(restored, isA<TransactionCountIntent>());
      expect((restored as TransactionCountIntent).period, Period.lastMonth);
    });

    test('DailyAverageIntent(thisMonth)', () {
      const intent = DailyAverageIntent(Period.thisMonth);
      final json = intent.toJson();
      expect(json, {'type': 'daily_average', 'period': 'thisMonth'});

      final restored = SaraswatiIntent.fromJson(json);
      expect(restored, isA<DailyAverageIntent>());
      expect((restored as DailyAverageIntent).period, Period.thisMonth);
    });

    test('IncomeIntent(thisMonth)', () {
      const intent = IncomeIntent(Period.thisMonth);
      final json = intent.toJson();
      expect(json, {'type': 'income', 'period': 'thisMonth'});

      final restored = SaraswatiIntent.fromJson(json);
      expect(restored, isA<IncomeIntent>());
      expect((restored as IncomeIntent).period, Period.thisMonth);
    });

    test('SplitsIntent', () {
      const intent = SplitsIntent();
      final json = intent.toJson();
      expect(json, {'type': 'splits'});

      final restored = SaraswatiIntent.fromJson(json);
      expect(restored, isA<SplitsIntent>());
    });

    test('HelpIntent', () {
      const intent = HelpIntent();
      final json = intent.toJson();
      expect(json, {'type': 'help'});

      final restored = SaraswatiIntent.fromJson(json);
      expect(restored, isA<HelpIntent>());
    });

    test('UnknownIntent with reason', () {
      const intent = UnknownIntent(reason: 'not finance');
      final json = intent.toJson();
      expect(json, {'type': 'unknown', 'reason': 'not finance'});

      final restored = SaraswatiIntent.fromJson(json);
      expect(restored, isA<UnknownIntent>());
      expect((restored as UnknownIntent).reason, 'not finance');
    });

    test('fromJson with unrecognized type returns UnknownIntent', () {
      final restored = SaraswatiIntent.fromJson({'type': 'bogus'});
      expect(restored, isA<UnknownIntent>());
      expect(
        (restored as UnknownIntent).reason,
        contains('Unrecognized type'),
      );
    });
  });
}
