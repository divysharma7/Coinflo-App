import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:finance_buddy_app/services/saraswati/entry/transaction_draft.dart';

void main() {
  group('TransactionKind JSON round-trip', () {
    for (final kind in TransactionKind.values) {
      test('${kind.name} survives toJson/fromJson', () {
        final json = kind.toJson();
        final restored = TransactionKind.fromJson(json);
        expect(restored, equals(kind));
      });
    }
  });

  group('PayerKind JSON round-trip', () {
    for (final payer in PayerKind.values) {
      test('${payer.name} survives toJson/fromJson', () {
        final json = payer.toJson();
        final restored = PayerKind.fromJson(json);
        expect(restored, equals(payer));
      });
    }
  });

  group('TransactionDraft JSON round-trip', () {
    final now = DateTime(2026, 5, 29, 10, 30);

    test('expense with all fields', () {
      final draft = TransactionDraft(
        kind: TransactionKind.expense,
        amount: 100.0,
        counterparty: 'Starbucks',
        category: 'food',
        date: now,
        note: 'morning coffee',
        source: 'quickadd',
        fieldConfidence: {
          'amount': 0.95,
          'category': 0.95,
          'date': 0.95,
        },
        rawInput: '100 coffee',
      );

      final json = draft.toJson();
      final restored = TransactionDraft.fromJson(json);

      expect(restored.kind, TransactionKind.expense);
      expect(restored.amount, 100.0);
      expect(restored.counterparty, 'Starbucks');
      expect(restored.category, 'food');
      expect(restored.date, now);
      expect(restored.note, 'morning coffee');
      expect(restored.source, 'quickadd');
      expect(restored.fieldConfidence['amount'], 0.95);
      expect(restored.rawInput, '100 coffee');
    });

    test('income with minimal fields', () {
      final draft = TransactionDraft(
        kind: TransactionKind.income,
        amount: 50000.0,
        category: 'salary',
        date: now,
        source: 'quickadd',
        fieldConfidence: {
          'amount': 0.95,
          'category': 0.95,
          'date': 0.95,
        },
        rawInput: 'salary 50000',
      );

      final json = draft.toJson();
      final restored = TransactionDraft.fromJson(json);

      expect(restored.kind, TransactionKind.income);
      expect(restored.amount, 50000.0);
      expect(restored.category, 'salary');
      expect(restored.counterparty, isNull);
      expect(restored.note, isNull);
    });

    test('transfer with counterparty', () {
      final draft = TransactionDraft(
        kind: TransactionKind.transfer,
        amount: 1000.0,
        counterparty: 'Mom',
        date: now,
        source: 'pattern',
        fieldConfidence: {
          'amount': 0.90,
          'counterparty': 0.90,
          'date': 0.90,
        },
        rawInput: '1000 to mom',
      );

      final json = draft.toJson();
      final restored = TransactionDraft.fromJson(json);

      expect(restored.kind, TransactionKind.transfer);
      expect(restored.counterparty, 'Mom');
      expect(restored.source, 'pattern');
    });

    test('split with splitWith list', () {
      final draft = TransactionDraft(
        kind: TransactionKind.split,
        amount: 600.0,
        splitWith: ['rahul', 'priya'],
        date: now,
        payer: PayerKind.splitEqual,
        source: 'llm',
        fieldConfidence: {
          'amount': 0.95,
          'split_with': 0.85,
          'date': 0.95,
          'payer': 0.90,
        },
        rawInput: 'split 600 with rahul,priya',
      );

      final json = draft.toJson();
      final restored = TransactionDraft.fromJson(json);

      expect(restored.kind, TransactionKind.split);
      expect(restored.splitWith, ['rahul', 'priya']);
      expect(restored.payer, PayerKind.splitEqual);
      expect(restored.source, 'llm');
    });

    test('null amount round-trips', () {
      final draft = TransactionDraft(
        kind: TransactionKind.expense,
        category: 'food',
        date: now,
        source: 'pattern',
        fieldConfidence: {'category': 0.6},
        rawInput: 'paid for lunch',
      );

      final json = draft.toJson();
      final restored = TransactionDraft.fromJson(json);

      expect(restored.amount, isNull);
      expect(restored.category, 'food');
    });

    test('empty confidence map round-trips', () {
      final draft = TransactionDraft(
        kind: TransactionKind.expense,
        amount: 500.0,
        date: now,
        source: 'cache',
        rawInput: '500',
      );

      final json = draft.toJson();
      final restored = TransactionDraft.fromJson(json);

      expect(restored.fieldConfidence, isEmpty);
    });

    test('counterpartyId round-trips', () {
      final draft = TransactionDraft(
        kind: TransactionKind.transfer,
        amount: 500.0,
        counterparty: 'Rahul',
        counterpartyId: '42',
        date: now,
        source: 'llm',
        fieldConfidence: {'amount': 0.95, 'counterparty': 0.92},
        rawInput: '500 to rahul',
      );

      final json = draft.toJson();
      final restored = TransactionDraft.fromJson(json);

      expect(restored.counterpartyId, '42');
    });
  });

  group('uncertainFields', () {
    final now = DateTime(2026, 5, 29);

    test('returns fields below default threshold 0.85', () {
      final draft = TransactionDraft(
        kind: TransactionKind.expense,
        amount: 100.0,
        category: 'food',
        date: now,
        source: 'llm',
        fieldConfidence: {
          'amount': 0.95,
          'category': 0.60,
          'date': 0.95,
        },
        rawInput: 'test',
      );

      expect(draft.uncertainFields(), ['category']);
    });

    test('returns empty list when all fields confident', () {
      final draft = TransactionDraft(
        kind: TransactionKind.expense,
        amount: 100.0,
        category: 'food',
        date: now,
        source: 'quickadd',
        fieldConfidence: {
          'amount': 0.95,
          'category': 0.95,
          'date': 0.95,
        },
        rawInput: 'test',
      );

      expect(draft.uncertainFields(), isEmpty);
    });

    test('custom threshold works', () {
      final draft = TransactionDraft(
        kind: TransactionKind.expense,
        amount: 100.0,
        category: 'food',
        date: now,
        source: 'llm',
        fieldConfidence: {
          'amount': 0.92,
          'category': 0.88,
          'date': 0.95,
        },
        rawInput: 'test',
      );

      expect(draft.uncertainFields(threshold: 0.90), ['category']);
      expect(draft.uncertainFields(threshold: 0.93), ['amount', 'category']);
    });

    test('empty confidence map returns empty list', () {
      final draft = TransactionDraft(
        kind: TransactionKind.expense,
        amount: 100.0,
        date: now,
        source: 'cache',
        rawInput: 'test',
      );

      expect(draft.uncertainFields(), isEmpty);
    });

    test('multiple uncertain fields', () {
      final draft = TransactionDraft(
        kind: TransactionKind.expense,
        amount: 100.0,
        category: 'food',
        counterparty: 'someone',
        date: now,
        source: 'llm',
        fieldConfidence: {
          'amount': 0.50,
          'category': 0.60,
          'counterparty': 0.40,
          'date': 0.95,
        },
        rawInput: 'test',
      );

      expect(draft.uncertainFields(), hasLength(3));
    });
  });

  group('missingRequiredFields', () {
    final now = DateTime(2026, 5, 29);

    test('expense: complete -> no missing', () {
      final draft = TransactionDraft(
        kind: TransactionKind.expense,
        amount: 100.0,
        category: 'food',
        date: now,
        source: 'quickadd',
        rawInput: 'test',
      );

      expect(draft.missingRequiredFields(), isEmpty);
    });

    test('expense: missing amount and category', () {
      final draft = TransactionDraft(
        kind: TransactionKind.expense,
        date: now,
        source: 'pattern',
        rawInput: 'test',
      );

      expect(draft.missingRequiredFields(), containsAll(['amount', 'category']));
    });

    test('expense: missing date', () {
      final draft = TransactionDraft(
        kind: TransactionKind.expense,
        amount: 100.0,
        category: 'food',
        source: 'quickadd',
        rawInput: 'test',
      );

      expect(draft.missingRequiredFields(), ['date']);
    });

    test('income: needs amount, category, date', () {
      final draft = TransactionDraft(
        kind: TransactionKind.income,
        source: 'llm',
        rawInput: 'test',
      );

      expect(
        draft.missingRequiredFields(),
        containsAll(['amount', 'date', 'category']),
      );
    });

    test('transfer: needs counterparty', () {
      final draft = TransactionDraft(
        kind: TransactionKind.transfer,
        amount: 500.0,
        date: now,
        source: 'pattern',
        rawInput: 'test',
      );

      expect(draft.missingRequiredFields(), ['counterparty']);
    });

    test('transfer: counterpartyId satisfies counterparty requirement', () {
      final draft = TransactionDraft(
        kind: TransactionKind.transfer,
        amount: 500.0,
        counterpartyId: '42',
        date: now,
        source: 'pattern',
        rawInput: 'test',
      );

      expect(draft.missingRequiredFields(), isEmpty);
    });

    test('split: needs counterparty/splitWith and payer', () {
      final draft = TransactionDraft(
        kind: TransactionKind.split,
        amount: 600.0,
        date: now,
        source: 'llm',
        rawInput: 'test',
      );

      expect(
        draft.missingRequiredFields(),
        containsAll(['counterparty', 'payer']),
      );
    });

    test('split: splitWith satisfies counterparty requirement', () {
      final draft = TransactionDraft(
        kind: TransactionKind.split,
        amount: 600.0,
        date: now,
        splitWith: ['rahul'],
        payer: PayerKind.splitEqual,
        source: 'llm',
        rawInput: 'test',
      );

      expect(draft.missingRequiredFields(), isEmpty);
    });

    test('split: empty splitWith does NOT satisfy counterparty', () {
      final draft = TransactionDraft(
        kind: TransactionKind.split,
        amount: 600.0,
        date: now,
        splitWith: [],
        payer: PayerKind.splitEqual,
        source: 'llm',
        rawInput: 'test',
      );

      expect(draft.missingRequiredFields(), ['counterparty']);
    });
  });

  group('copyWith', () {
    final now = DateTime(2026, 5, 29);
    final base = TransactionDraft(
      kind: TransactionKind.expense,
      amount: 100.0,
      category: 'food',
      date: now,
      source: 'quickadd',
      fieldConfidence: {'amount': 0.95},
      rawInput: '100 coffee',
    );

    test('changes kind', () {
      final updated = base.copyWith(kind: TransactionKind.income);
      expect(updated.kind, TransactionKind.income);
      expect(updated.amount, 100.0); // unchanged
    });

    test('sets nullable field to null', () {
      final updated = base.copyWith(category: () => null);
      expect(updated.category, isNull);
    });

    test('changes amount', () {
      final updated = base.copyWith(amount: () => 200.0);
      expect(updated.amount, 200.0);
    });

    test('changes confidence map', () {
      final updated = base.copyWith(
        fieldConfidence: {'amount': 1.0, 'category': 0.9},
      );
      expect(updated.fieldConfidence['amount'], 1.0);
      expect(updated.fieldConfidence['category'], 0.9);
    });
  });

  group('toExtractionMetaJson', () {
    test('produces valid JSON with source and confidence', () {
      final draft = TransactionDraft(
        kind: TransactionKind.expense,
        amount: 100.0,
        date: DateTime(2026, 5, 29),
        source: 'llm',
        fieldConfidence: {'amount': 0.95, 'category': 0.80},
        rawInput: 'test',
      );

      final metaJson = draft.toExtractionMetaJson();
      final parsed = jsonDecode(metaJson) as Map<String, dynamic>;

      expect(parsed['source'], 'llm');
      expect(parsed['field_confidence']['amount'], 0.95);
      expect(parsed['field_confidence']['category'], 0.80);
    });
  });
}
