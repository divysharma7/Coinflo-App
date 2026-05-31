import 'package:flutter_test/flutter_test.dart';
import 'package:finance_buddy_app/services/saraswati/entry/pattern_matcher.dart';
import 'package:finance_buddy_app/services/saraswati/entry/transaction_draft.dart';

void main() {
  const matcher = PatternMatcher();

  group('Template 1: <amount> <free_text> (catch-all)', () {
    test('"500 birthday gift" -> expense, note=birthday gift, category conf 0.6',
        () {
      final d = matcher.match('500 birthday gift')!;
      expect(d.kind, TransactionKind.expense);
      expect(d.amount, 500.0);
      expect(d.note, 'birthday gift');
      expect(d.category, isNull);
      expect(d.source, 'pattern');
      expect(d.fieldConfidence['category'], 0.60);
      expect(d.fieldConfidence['amount'], 0.90);
    });

    test('"1200 random store" -> expense, note captures merchant text', () {
      final d = matcher.match('1200 random store')!;
      expect(d.note, 'random store');
    });
  });

  group('Template 2: paid <amount> to <name>', () {
    test('"paid 500 to rahul" -> transfer, Rahul', () {
      final d = matcher.match('paid 500 to rahul')!;
      expect(d.kind, TransactionKind.transfer);
      expect(d.amount, 500.0);
      expect(d.counterparty, 'Rahul');
      expect(d.source, 'pattern');
      expect(d.fieldConfidence['amount'], 0.90);
    });

    test('"paid 1000.50 to mom" -> transfer, Mom', () {
      final d = matcher.match('paid 1000.50 to mom')!;
      expect(d.amount, 1000.50);
      expect(d.counterparty, 'Mom');
    });
  });

  group('Template 3: <name> paid me <amount>', () {
    test('"rahul paid me 300" -> income, Rahul', () {
      final d = matcher.match('rahul paid me 300')!;
      expect(d.kind, TransactionKind.income);
      expect(d.amount, 300.0);
      expect(d.counterparty, 'Rahul');
      expect(d.source, 'pattern');
    });
  });

  group('Template 4: <name> owes me <amount>', () {
    test('"priya owes me 250" -> split, Priya, payer=user', () {
      final d = matcher.match('priya owes me 250')!;
      expect(d.kind, TransactionKind.split);
      expect(d.amount, 250.0);
      expect(d.counterparty, 'Priya');
      expect(d.payer, PayerKind.user);
    });
  });

  group('Template 5: i owe <name> <amount>', () {
    test('"i owe rahul 500" -> transfer, Rahul', () {
      final d = matcher.match('i owe rahul 500')!;
      expect(d.kind, TransactionKind.transfer);
      expect(d.amount, 500.0);
      expect(d.counterparty, 'Rahul');
    });
  });

  group('Priority: specific templates beat catch-all', () {
    test('"paid 500 to rahul" matches template 2, not catch-all', () {
      final d = matcher.match('paid 500 to rahul');
      // Template 2 returns transfer, not expense
      expect(d!.kind, TransactionKind.transfer);
      expect(d.source, 'pattern');
    });
  });

  group('No match', () {
    test('empty string -> null', () {
      expect(matcher.match(''), isNull);
    });

    test('"show me spending" -> null', () {
      expect(matcher.match('show me spending'), isNull);
    });

    test('"hello world" -> null (no number)', () {
      expect(matcher.match('hello world'), isNull);
    });
  });

  group('Metadata checks', () {
    test('all pattern drafts have source=pattern', () {
      final inputs = [
        'paid 500 to rahul',
        'rahul paid me 300',
        'priya owes me 250',
        'i owe rahul 500',
        '500 birthday gift',
      ];
      for (final input in inputs) {
        final d = matcher.match(input);
        expect(d, isNotNull, reason: 'Expected match for "$input"');
        expect(d!.source, 'pattern', reason: 'Source for "$input"');
        expect(d.rawInput, input);
        expect(d.date, isNotNull);
      }
    });

    test('confidence is 0.90 for matched fields', () {
      final d = matcher.match('paid 500 to rahul')!;
      expect(d.fieldConfidence['amount'], 0.90);
      expect(d.fieldConfidence['counterparty'], 0.90);
    });
  });
}
