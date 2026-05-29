import 'package:firebase_ai/firebase_ai.dart';

/// Function declaration for Gemini intent classification.
///
/// The model must call this function with a typed intent + slots.
/// It never computes numbers — only resolves classification.
final kClassifyIntentFunction = FunctionDeclaration(
  'classify_finance_intent',
  'Classify a user\'s natural-language finance query into a typed '
  'intent with slots. Input may be English, Hindi (Devanagari), or '
  'Hinglish (Hindi in Latin script). Return intent=unknown if the '
  'query is not about personal finance.',
  parameters: {
    'intent': Schema.enumString(
      enumValues: [
        'today_spending',
        'period_spending',
        'category_specific',
        'category_breakdown',
        'top_merchants',
        'period_comparison',
        'biggest_expense',
        'transaction_count',
        'daily_average',
        'income',
        'splits',
        'help',
        'unknown',
      ],
      description: 'The classified intent type.',
    ),
    'period': Schema.enumString(
      enumValues: [
        'today',
        'this_week',
        'last_week',
        'this_month',
        'last_month',
      ],
      description: 'Time period for the query. Default to this_month if unstated.',
      nullable: true,
    ),
    'category': Schema.string(
      description: 'Canonical category name. Common values: food, rent, transport, '
          'entertainment, shopping, utilities, healthcare, family, social, other. '
          'Merchant-to-category mapping: zomato/swiggy→food, uber/ola/rapido→transport, '
          'netflix/spotify→entertainment, amazon/flipkart→shopping.',
      nullable: true,
    ),
    'merchant': Schema.string(
      description: 'Specific merchant name if mentioned (e.g. zomato, uber).',
      nullable: true,
    ),
    'limit': Schema.integer(
      description: 'Number of results for top_merchants (default 5).',
      nullable: true,
    ),
    'comparison_kind': Schema.enumString(
      enumValues: ['week_over_week', 'month_over_month'],
      description: 'Comparison type for period_comparison intent.',
      nullable: true,
    ),
    'reason': Schema.string(
      description: 'Reason for unknown intent classification.',
      nullable: true,
    ),
  },
  optionalParameters: [
    'period',
    'category',
    'merchant',
    'limit',
    'comparison_kind',
    'reason',
  ],
);
