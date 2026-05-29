/// Time period for finance queries.
enum Period {
  today,
  thisWeek,
  lastWeek,
  thisMonth,
  lastMonth;

  String toJson() => name;

  static Period fromJson(String json) => Period.values.firstWhere(
        (e) => e.name == json,
        orElse: () => Period.thisMonth,
      );
}

/// Comparison kind for period-vs-period queries.
enum ComparisonKind {
  weekOverWeek,
  monthOverMonth;

  String toJson() => name;

  static ComparisonKind fromJson(String json) =>
      ComparisonKind.values.firstWhere(
        (e) => e.name == json,
        orElse: () => ComparisonKind.monthOverMonth,
      );
}

/// Sealed intent hierarchy for Saraswati query classification.
///
/// Every user query resolves to exactly one intent. The executor
/// maps intents to [BaseRepository] calls and formats the reply.
sealed class SaraswatiIntent {
  const SaraswatiIntent();

  Map<String, dynamic> toJson();

  static SaraswatiIntent fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    return switch (type) {
      'today_spending' => const TodaySpendingIntent(),
      'period_spending' => PeriodSpendingIntent(
          Period.fromJson(json['period'] as String),
        ),
      'category_specific' => CategorySpecificIntent(
          category: json['category'] as String,
          period: Period.fromJson(json['period'] as String),
          merchant: json['merchant'] as String?,
        ),
      'category_breakdown' => CategoryBreakdownIntent(
          Period.fromJson(json['period'] as String),
        ),
      'top_merchants' => TopMerchantsIntent(
          period: Period.fromJson(json['period'] as String),
          limit: json['limit'] as int? ?? 5,
        ),
      'period_comparison' => PeriodComparisonIntent(
          ComparisonKind.fromJson(json['comparison_kind'] as String),
        ),
      'biggest_expense' => BiggestExpenseIntent(
          Period.fromJson(json['period'] as String),
        ),
      'transaction_count' => TransactionCountIntent(
          Period.fromJson(json['period'] as String),
        ),
      'daily_average' => DailyAverageIntent(
          Period.fromJson(json['period'] as String),
        ),
      'income' => IncomeIntent(
          Period.fromJson(json['period'] as String),
        ),
      'splits' => const SplitsIntent(),
      'help' => const HelpIntent(),
      'unknown' => UnknownIntent(reason: json['reason'] as String? ?? ''),
      _ => UnknownIntent(reason: 'Unrecognized type: $type'),
    };
  }
}

class TodaySpendingIntent extends SaraswatiIntent {
  const TodaySpendingIntent();

  @override
  Map<String, dynamic> toJson() => {'type': 'today_spending'};
}

class PeriodSpendingIntent extends SaraswatiIntent {
  final Period period;
  const PeriodSpendingIntent(this.period);

  @override
  Map<String, dynamic> toJson() => {
        'type': 'period_spending',
        'period': period.toJson(),
      };
}

class CategorySpecificIntent extends SaraswatiIntent {
  final String category;
  final Period period;
  final String? merchant;

  const CategorySpecificIntent({
    required this.category,
    required this.period,
    this.merchant,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'category_specific',
        'category': category,
        'period': period.toJson(),
        if (merchant != null) 'merchant': merchant,
      };
}

class CategoryBreakdownIntent extends SaraswatiIntent {
  final Period period;
  const CategoryBreakdownIntent(this.period);

  @override
  Map<String, dynamic> toJson() => {
        'type': 'category_breakdown',
        'period': period.toJson(),
      };
}

class TopMerchantsIntent extends SaraswatiIntent {
  final Period period;
  final int limit;

  const TopMerchantsIntent({required this.period, this.limit = 5});

  @override
  Map<String, dynamic> toJson() => {
        'type': 'top_merchants',
        'period': period.toJson(),
        'limit': limit,
      };
}

class PeriodComparisonIntent extends SaraswatiIntent {
  final ComparisonKind kind;
  const PeriodComparisonIntent(this.kind);

  @override
  Map<String, dynamic> toJson() => {
        'type': 'period_comparison',
        'comparison_kind': kind.toJson(),
      };
}

class BiggestExpenseIntent extends SaraswatiIntent {
  final Period period;
  const BiggestExpenseIntent(this.period);

  @override
  Map<String, dynamic> toJson() => {
        'type': 'biggest_expense',
        'period': period.toJson(),
      };
}

class TransactionCountIntent extends SaraswatiIntent {
  final Period period;
  const TransactionCountIntent(this.period);

  @override
  Map<String, dynamic> toJson() => {
        'type': 'transaction_count',
        'period': period.toJson(),
      };
}

class DailyAverageIntent extends SaraswatiIntent {
  final Period period;
  const DailyAverageIntent(this.period);

  @override
  Map<String, dynamic> toJson() => {
        'type': 'daily_average',
        'period': period.toJson(),
      };
}

class IncomeIntent extends SaraswatiIntent {
  final Period period;
  const IncomeIntent(this.period);

  @override
  Map<String, dynamic> toJson() => {
        'type': 'income',
        'period': period.toJson(),
      };
}

class SplitsIntent extends SaraswatiIntent {
  const SplitsIntent();

  @override
  Map<String, dynamic> toJson() => {'type': 'splits'};
}

class HelpIntent extends SaraswatiIntent {
  const HelpIntent();

  @override
  Map<String, dynamic> toJson() => {'type': 'help'};
}

class UnknownIntent extends SaraswatiIntent {
  final String reason;
  const UnknownIntent({required this.reason});

  @override
  Map<String, dynamic> toJson() => {
        'type': 'unknown',
        'reason': reason,
      };
}
