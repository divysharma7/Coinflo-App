import 'package:flutter_test/flutter_test.dart';
import 'package:finance_buddy_app/services/saraswati/entry/amount_sanity_checker.dart';
import 'package:finance_buddy_app/services/saraswati/entry/disambiguation_engine.dart';
import 'package:finance_buddy_app/services/saraswati/entry/entry_action.dart';
import 'package:finance_buddy_app/services/saraswati/entry/transaction_draft.dart';

void main() {
  const engine = DisambiguationEngine();
  final today = DateTime(2026, 5, 29);

  group('Rule 1: null or unrecognized -> QuickFormFallback', () {
    test('null draft -> QuickFormFallback', () {
      final action = engine.evaluate(null);
      expect(action, isA<QuickFormFallbackAction>());
      expect((action as QuickFormFallbackAction).reason, 'unrecognized');
    });
  });

  group('Rule 2: amount fails sanity check -> AskOneQuestion(amount)', () {
    test('amount exceeds hard cap (500,000)', () {
      final draft = TransactionDraft(
        kind: TransactionKind.expense,
        amount: 999999.0,
        category: 'other',
        date: today,
        source: 'llm',
        fieldConfidence: {
          'amount': 0.95,
          'category': 0.95,
          'date': 0.95,
        },
        rawInput: '999999 something',
      );
      final action = engine.evaluate(draft, userHistoricalMax: 5000.0);
      expect(action, isA<AskOneQuestionAction>());
      expect((action as AskOneQuestionAction).fieldToConfirm, 'amount');
    });

    test('amount exceeds 1.5x historical max', () {
      final draft = TransactionDraft(
        kind: TransactionKind.expense,
        amount: 10000.0,
        category: 'food',
        date: today,
        source: 'llm',
        fieldConfidence: {
          'amount': 0.95,
          'category': 0.95,
          'date': 0.95,
        },
        rawInput: '10000 food',
      );
      // Historical max 5000, so 10000 > 5000*1.5 = 7500
      final action = engine.evaluate(draft, userHistoricalMax: 5000.0);
      expect(action, isA<AskOneQuestionAction>());
      expect((action as AskOneQuestionAction).fieldToConfirm, 'amount');
    });

    test('amount below minimum (0)', () {
      final draft = TransactionDraft(
        kind: TransactionKind.expense,
        amount: 0.5,
        category: 'food',
        date: today,
        source: 'llm',
        fieldConfidence: {
          'amount': 0.95,
          'category': 0.95,
          'date': 0.95,
        },
        rawInput: '0.5 food',
      );
      final action = engine.evaluate(draft);
      expect(action, isA<AskOneQuestionAction>());
    });
  });

  group('Rule 3: 2+ fields problematic -> QuickFormFallback', () {
    test('2 missing required fields', () {
      final draft = TransactionDraft(
        kind: TransactionKind.expense,
        date: today,
        source: 'llm',
        fieldConfidence: {'date': 0.95},
        rawInput: 'test',
      );
      // Missing: amount, category
      final action = engine.evaluate(draft);
      expect(action, isA<QuickFormFallbackAction>());
      expect(
          (action as QuickFormFallbackAction).reason, 'too_uncertain');
    });

    test('1 missing + 1 uncertain = 2 total', () {
      final draft = TransactionDraft(
        kind: TransactionKind.expense,
        amount: 100.0,
        date: today,
        source: 'llm',
        fieldConfidence: {
          'amount': 0.60, // uncertain
          'date': 0.95,
        },
        rawInput: 'test',
      );
      // Missing: category. Uncertain: amount. Total = 2.
      final action = engine.evaluate(draft);
      expect(action, isA<QuickFormFallbackAction>());
    });

    test('2 uncertain fields', () {
      final draft = TransactionDraft(
        kind: TransactionKind.expense,
        amount: 100.0,
        category: 'food',
        date: today,
        source: 'llm',
        fieldConfidence: {
          'amount': 0.60,
          'category': 0.50,
          'date': 0.95,
        },
        rawInput: 'test',
      );
      final action = engine.evaluate(draft);
      expect(action, isA<QuickFormFallbackAction>());
    });
  });

  group('Rule 4: splits always confirm', () {
    test('complete split draft -> AskOneQuestion(split_with)', () {
      final draft = TransactionDraft(
        kind: TransactionKind.split,
        amount: 600.0,
        splitWith: ['Rahul', 'Priya'],
        date: today,
        payer: PayerKind.splitEqual,
        source: 'quickadd',
        fieldConfidence: {
          'amount': 0.95,
          'split_with': 0.95,
          'date': 0.95,
          'payer': 0.95,
        },
        rawInput: 'split 600 with rahul,priya',
      );
      final action = engine.evaluate(draft);
      expect(action, isA<AskOneQuestionAction>());
      expect(
          (action as AskOneQuestionAction).fieldToConfirm, 'split_with');
      expect(action.questionText, 'Confirm split?');
    });
  });

  group('Rule 5: exactly 1 required field missing -> AskOneQuestion', () {
    test('missing category -> ask for category', () {
      final draft = TransactionDraft(
        kind: TransactionKind.expense,
        amount: 500.0,
        date: today,
        source: 'pattern',
        fieldConfidence: {
          'amount': 0.90,
          'date': 0.90,
        },
        rawInput: '500 something',
      );
      final action = engine.evaluate(draft,
          topCategories: ['food', 'transport', 'rent']);
      expect(action, isA<AskOneQuestionAction>());
      final ask = action as AskOneQuestionAction;
      expect(ask.fieldToConfirm, 'category');
      expect(ask.chipOptions, contains('food'));
      expect(ask.chipOptions, contains('Other'));
    });

    test('missing counterparty for transfer -> ask for counterparty', () {
      final draft = TransactionDraft(
        kind: TransactionKind.transfer,
        amount: 1000.0,
        date: today,
        source: 'llm',
        fieldConfidence: {
          'amount': 0.95,
          'date': 0.95,
        },
        rawInput: '1000 to someone',
      );
      final action = engine.evaluate(draft,
          recentCounterparties: ['Rahul', 'Mom', 'Priya']);
      expect(action, isA<AskOneQuestionAction>());
      expect(
          (action as AskOneQuestionAction).fieldToConfirm, 'counterparty');
    });
  });

  group('Rule 6: exactly 1 field uncertain -> AskOneQuestion', () {
    test('LLM 0.6 confidence on category -> ask for category', () {
      final draft = TransactionDraft(
        kind: TransactionKind.expense,
        amount: 100.0,
        category: 'food',
        date: today,
        source: 'llm',
        fieldConfidence: {
          'amount': 0.95,
          'category': 0.60,
          'date': 0.95,
        },
        rawInput: 'test',
      );
      final action = engine.evaluate(draft,
          topCategories: ['transport', 'rent']);
      expect(action, isA<AskOneQuestionAction>());
      final ask = action as AskOneQuestionAction;
      expect(ask.fieldToConfirm, 'category');
      // LLM's guess 'food' should be in chips
      expect(ask.chipOptions, contains('food'));
    });
  });

  group('Rule 7: all good -> SilentCommit', () {
    test('all-confident expense -> SilentCommit', () {
      final draft = TransactionDraft(
        kind: TransactionKind.expense,
        amount: 100.0,
        category: 'food',
        date: today,
        source: 'quickadd',
        fieldConfidence: {
          'amount': 0.95,
          'category': 0.95,
          'date': 0.95,
        },
        rawInput: '100 coffee',
      );
      final action = engine.evaluate(draft);
      expect(action, isA<SilentCommitAction>());
      expect((action as SilentCommitAction).draft, same(draft));
    });

    test('all-confident income -> SilentCommit', () {
      final draft = TransactionDraft(
        kind: TransactionKind.income,
        amount: 50000.0,
        category: 'salary',
        date: today,
        source: 'quickadd',
        fieldConfidence: {
          'amount': 0.95,
          'category': 0.95,
          'date': 0.95,
        },
        rawInput: 'salary 50000',
      );
      final action = engine.evaluate(draft);
      expect(action, isA<SilentCommitAction>());
    });

    test('all-confident transfer -> SilentCommit', () {
      final draft = TransactionDraft(
        kind: TransactionKind.transfer,
        amount: 1000.0,
        counterparty: 'Mom',
        date: today,
        source: 'quickadd',
        fieldConfidence: {
          'amount': 0.95,
          'counterparty': 0.95,
          'date': 0.95,
        },
        rawInput: '1000 to mom',
      );
      final action = engine.evaluate(draft);
      expect(action, isA<SilentCommitAction>());
    });
  });

  group('AmountSanityChecker', () {
    const checker = AmountSanityChecker();

    test('sane amounts pass', () {
      expect(checker.isSane(100.0, userHistoricalMax: 5000.0), isTrue);
      expect(checker.isSane(5000.0, userHistoricalMax: 5000.0), isTrue);
      expect(checker.isSane(7500.0, userHistoricalMax: 5000.0), isTrue);
    });

    test('amount exceeding 1.5x max fails', () {
      expect(checker.isSane(7501.0, userHistoricalMax: 5000.0), isFalse);
    });

    test('amount exceeding hard cap fails', () {
      expect(
          checker.isSane(500001.0, userHistoricalMax: 1000000.0), isFalse);
    });

    test('amount below minimum fails', () {
      expect(checker.isSane(0.5), isFalse);
      expect(checker.isSane(0.0), isFalse);
    });

    test('chipSuggestions includes rounded values', () {
      final chips = checker.chipSuggestions(1234.0);
      expect(chips, contains('1200'));
      expect(chips, contains('1230'));
      expect(chips, contains('1234'));
      expect(chips, contains('Enter manually'));
    });
  });
}
