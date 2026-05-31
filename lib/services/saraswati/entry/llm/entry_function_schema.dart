import 'package:firebase_ai/firebase_ai.dart';

/// Function declaration for Gemini transaction extraction.
///
/// The model must call this function with a structured transaction draft.
/// It never computes totals or looks up data — only extracts from text.
final kExtractTransactionFunction = FunctionDeclaration(
  'extract_transaction',
  'Extract a structured personal-finance transaction from natural language. '
  'Input may be English, Hindi (Devanagari), or Hinglish (Hindi in Latin '
  'script). Return per-field confidence (0.0-1.0) so the app can decide '
  'whether to ask for confirmation. Use low confidence when guessing; '
  'do NOT invent values to make the response look complete.',
  parameters: {
    'kind': Schema.enumString(
      enumValues: ['expense', 'income', 'transfer', 'split', 'unknown'],
      description: 'The transaction type.',
    ),
    'amount': Schema.number(
      description: 'Transaction amount as a positive number.',
      nullable: true,
    ),
    'counterparty': Schema.string(
      description: 'Person or merchant name as written.',
      nullable: true,
    ),
    'category': Schema.string(
      description:
          'Canonical category: food, rent, transport, entertainment, shopping, '
          'utilities, healthcare, salary, other. Merchant mapping: '
          'zomato/swiggy->food, ola/uber/rapido->transport, '
          'netflix/spotify->entertainment, amazon/flipkart->shopping.',
      nullable: true,
    ),
    'date_relative': Schema.enumString(
      enumValues: [
        'today',
        'yesterday',
        'day_before_yesterday',
        'this_monday',
        'this_tuesday',
        'this_wednesday',
        'this_thursday',
        'this_friday',
        'this_saturday',
        'this_sunday',
        'last_week',
        'specific',
      ],
      description: 'Relative date reference. Default to today if unstated.',
      nullable: true,
    ),
    'date_specific': Schema.string(
      description: 'YYYY-MM-DD only if an explicit date is given.',
      nullable: true,
    ),
    'payer': Schema.enumString(
      enumValues: ['user', 'counterparty', 'split_equal', 'split_custom'],
      description: 'Who paid. Default to user for expenses.',
      nullable: true,
    ),
    'split_with': Schema.array(
      items: Schema.string(),
      description: 'Names of people to split with.',
      nullable: true,
    ),
    'note': Schema.string(
      description: 'Any additional context from the input.',
      nullable: true,
    ),
    'field_confidence': Schema.object(
      properties: {
        'amount': Schema.number(description: 'Confidence for amount.'),
        'counterparty':
            Schema.number(description: 'Confidence for counterparty.'),
        'category': Schema.number(description: 'Confidence for category.'),
        'date': Schema.number(description: 'Confidence for date.'),
        'payer': Schema.number(description: 'Confidence for payer.'),
        'split_with':
            Schema.number(description: 'Confidence for split_with.'),
      },
      optionalProperties: [
        'amount',
        'counterparty',
        'category',
        'date',
        'payer',
        'split_with',
      ],
      description:
          'Confidence 0.0-1.0 per field you populated. '
          '0.95+ for explicit values, 0.75-0.9 for clear inference, '
          'below 0.7 means you are guessing.',
    ),
  },
  optionalParameters: [
    'amount',
    'counterparty',
    'category',
    'date_relative',
    'date_specific',
    'payer',
    'split_with',
    'note',
    'field_confidence',
  ],
);
