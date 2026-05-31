import 'package:flutter_test/flutter_test.dart';
import 'package:finance_buddy_app/services/saraswati/entry/quickadd_matcher.dart';
import 'package:finance_buddy_app/services/saraswati/entry/transaction_draft.dart';

void main() {
  const matcher = QuickaddMatcher();

  group('1. Coffee/chai/tea', () {
    test('"100 coffee" -> expense, food, 100', () {
      final d = matcher.match('100 coffee')!;
      expect(d.kind, TransactionKind.expense);
      expect(d.amount, 100.0);
      expect(d.category, 'food');
      expect(d.source, 'quickadd');
      expect(d.fieldConfidence['amount'], 0.95);
    });

    test('"50.5 chai" -> expense, food, 50.5', () {
      final d = matcher.match('50.5 chai')!;
      expect(d.amount, 50.5);
      expect(d.category, 'food');
    });

    test('"30 tea" -> expense, food', () {
      final d = matcher.match('30 tea')!;
      expect(d.category, 'food');
    });
  });

  group('2. Lunch/dinner/breakfast/snack', () {
    test('"200 lunch" -> expense, food', () {
      final d = matcher.match('200 lunch')!;
      expect(d.amount, 200.0);
      expect(d.category, 'food');
    });

    test('"500 dinner" -> expense, food', () {
      expect(matcher.match('500 dinner')!.category, 'food');
    });

    test('"80 breakfast" -> expense, food', () {
      expect(matcher.match('80 breakfast')!.category, 'food');
    });

    test('"40 snack" -> expense, food', () {
      expect(matcher.match('40 snack')!.category, 'food');
    });
  });

  group('3. Transport (uber/ola/rapido/auto/cab/taxi)', () {
    test('"150 uber" -> expense, transport', () {
      final d = matcher.match('150 uber')!;
      expect(d.category, 'transport');
      expect(d.amount, 150.0);
    });

    test('"200 ola" -> transport', () {
      expect(matcher.match('200 ola')!.category, 'transport');
    });

    test('"100 auto" -> transport', () {
      expect(matcher.match('100 auto')!.category, 'transport');
    });
  });

  group('4. Rent', () {
    test('"15000 rent" -> expense, rent', () {
      final d = matcher.match('15000 rent')!;
      expect(d.amount, 15000.0);
      expect(d.category, 'rent');
    });
  });

  group('5. Petrol/fuel/gas', () {
    test('"1000 petrol" -> expense, transport', () {
      final d = matcher.match('1000 petrol')!;
      expect(d.category, 'transport');
    });

    test('"800 fuel" -> transport', () {
      expect(matcher.match('800 fuel')!.category, 'transport');
    });

    test('"500 gas" -> transport', () {
      expect(matcher.match('500 gas')!.category, 'transport');
    });
  });

  group('6. Grocery/groceries/sabzi/vegetables', () {
    test('"500 grocery" -> expense, food', () {
      final d = matcher.match('500 grocery')!;
      expect(d.category, 'food');
    });

    test('"300 sabzi" -> food', () {
      expect(matcher.match('300 sabzi')!.category, 'food');
    });

    test('"400 vegetables" -> food', () {
      expect(matcher.match('400 vegetables')!.category, 'food');
    });
  });

  group('7. Utilities', () {
    test('"2000 electricity" -> expense, utilities', () {
      final d = matcher.match('2000 electricity')!;
      expect(d.category, 'utilities');
    });

    test('"500 water" -> utilities', () {
      expect(matcher.match('500 water')!.category, 'utilities');
    });

    test('"1000 wifi" -> utilities', () {
      expect(matcher.match('1000 wifi')!.category, 'utilities');
    });

    test('"800 internet" -> utilities', () {
      expect(matcher.match('800 internet')!.category, 'utilities');
    });

    test('"600 gas bill" -> utilities', () {
      expect(matcher.match('600 gas bill')!.category, 'utilities');
    });
  });

  group('8. <amount> from <name>', () {
    test('"500 from raj" -> income, counterparty=Raj', () {
      final d = matcher.match('500 from raj')!;
      expect(d.kind, TransactionKind.income);
      expect(d.amount, 500.0);
      expect(d.counterparty, 'Raj');
    });
  });

  group('9. <amount> to <name>', () {
    test('"1000 to mom" -> transfer, counterparty=Mom', () {
      final d = matcher.match('1000 to mom')!;
      expect(d.kind, TransactionKind.transfer);
      expect(d.amount, 1000.0);
      expect(d.counterparty, 'Mom');
    });
  });

  group('10. salary <amount>', () {
    test('"salary 50000" -> income, salary, 50000', () {
      final d = matcher.match('salary 50000')!;
      expect(d.kind, TransactionKind.income);
      expect(d.amount, 50000.0);
      expect(d.category, 'salary');
    });
  });

  group('11. Healthcare', () {
    test('"300 medicine" -> expense, healthcare', () {
      final d = matcher.match('300 medicine')!;
      expect(d.category, 'healthcare');
    });

    test('"500 doctor" -> healthcare', () {
      expect(matcher.match('500 doctor')!.category, 'healthcare');
    });
  });

  group('12. Entertainment', () {
    test('"200 movie" -> expense, entertainment', () {
      final d = matcher.match('200 movie')!;
      expect(d.category, 'entertainment');
    });

    test('"199 netflix" -> entertainment', () {
      expect(matcher.match('199 netflix')!.category, 'entertainment');
    });

    test('"99 spotify" -> entertainment', () {
      expect(matcher.match('99 spotify')!.category, 'entertainment');
    });
  });

  group('13. Shopping', () {
    test('"1500 amazon" -> expense, shopping', () {
      final d = matcher.match('1500 amazon')!;
      expect(d.category, 'shopping');
    });

    test('"2000 flipkart" -> shopping', () {
      expect(matcher.match('2000 flipkart')!.category, 'shopping');
    });

    test('"800 myntra" -> shopping', () {
      expect(matcher.match('800 myntra')!.category, 'shopping');
    });
  });

  group('14. Split', () {
    test('"split 600 with rahul,priya" -> split, splitWith=[Rahul,Priya]', () {
      final d = matcher.match('split 600 with rahul,priya')!;
      expect(d.kind, TransactionKind.split);
      expect(d.amount, 600.0);
      expect(d.splitWith, ['Rahul', 'Priya']);
      expect(d.payer, PayerKind.splitEqual);
    });

    test('"split 300 with amit" -> split, splitWith=[Amit]', () {
      final d = matcher.match('split 300 with amit')!;
      expect(d.splitWith, ['Amit']);
    });
  });

  group('15. Food delivery (zomato/swiggy)', () {
    test('"400 zomato" -> expense, food, counterparty=zomato', () {
      final d = matcher.match('400 zomato')!;
      expect(d.category, 'food');
      expect(d.counterparty, 'zomato');
    });

    test('"350 swiggy" -> expense, food', () {
      final d = matcher.match('350 swiggy')!;
      expect(d.category, 'food');
      expect(d.counterparty, 'swiggy');
    });
  });

  group('No match', () {
    test('empty string -> null', () {
      expect(matcher.match(''), isNull);
    });

    test('"what did i spend today" -> null', () {
      expect(matcher.match('what did i spend today'), isNull);
    });

    test('"hello" -> null', () {
      expect(matcher.match('hello'), isNull);
    });
  });

  group('Metadata checks', () {
    test('all quickadd drafts have source=quickadd', () {
      final inputs = [
        '100 coffee', '200 lunch', '150 uber', '15000 rent',
        '1000 petrol', '500 grocery', '2000 electricity',
        '500 from raj', '1000 to mom', 'salary 50000',
        '300 medicine', '200 movie', '1500 amazon',
        'split 600 with rahul', '400 zomato',
      ];
      for (final input in inputs) {
        final d = matcher.match(input);
        expect(d, isNotNull, reason: 'Expected match for "$input"');
        expect(d!.source, 'quickadd', reason: 'Source for "$input"');
        expect(d.rawInput, input);
        expect(d.date, isNotNull, reason: 'Date for "$input"');
      }
    });

    test('confidence is 0.95 for matched fields', () {
      final d = matcher.match('100 coffee')!;
      expect(d.fieldConfidence['amount'], 0.95);
      expect(d.fieldConfidence['category'], 0.95);
      expect(d.fieldConfidence['date'], 0.95);
    });
  });
}
