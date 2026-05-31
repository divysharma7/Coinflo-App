import 'package:flutter_test/flutter_test.dart';
import 'package:finance_buddy_app/services/saraswati/entry/entry_normalizer.dart';
import 'package:finance_buddy_app/services/saraswati/entry/pattern_matcher.dart';
import 'package:finance_buddy_app/services/saraswati/entry/quickadd_matcher.dart';
import 'package:finance_buddy_app/services/saraswati/entry/transaction_draft.dart';
import 'package:finance_buddy_app/services/saraswati/saraswati_router.dart';

/// Smoke entry table: 50+ entries mixing English/Hindi/Hinglish.
/// Tests Stages 0-1 (deterministic) and router classification.
/// LLM (Stage 3) entries are marked and tested manually.
void main() {
  const quickadd = QuickaddMatcher();
  const pattern = PatternMatcher();
  const router = SaraswatiRouter();

  /// Try quickadd then pattern. Returns null if neither matches.
  TransactionDraft? extract(String raw) {
    final normalized = EntryNormalizer.normalize(raw);
    return quickadd.match(normalized) ?? pattern.match(normalized);
  }

  group('Smoke entries: Stage 0 (quickadd)', () {
    test('1. "100 coffee" -> expense, food, 100', () {
      final d = extract('100 coffee')!;
      expect(d.kind, TransactionKind.expense);
      expect(d.amount, 100);
      expect(d.category, 'food');
    });

    test('2. "200 lunch" -> expense, food, 200', () {
      final d = extract('200 lunch')!;
      expect(d.amount, 200);
      expect(d.category, 'food');
    });

    test('3. "150 uber" -> expense, transport, 150', () {
      final d = extract('150 uber')!;
      expect(d.category, 'transport');
    });

    test('4. "15000 rent" -> expense, rent', () {
      final d = extract('15000 rent')!;
      expect(d.category, 'rent');
    });

    test('5. "500 grocery" -> expense, food', () {
      expect(extract('500 grocery')!.category, 'food');
    });

    test('6. "2000 electricity" -> expense, utilities', () {
      expect(extract('2000 electricity')!.category, 'utilities');
    });

    test('7. "500 from raj" -> income, Raj', () {
      final d = extract('500 from raj')!;
      expect(d.kind, TransactionKind.income);
      expect(d.counterparty, 'Raj');
    });

    test('8. "1000 to mom" -> transfer, Mom', () {
      final d = extract('1000 to mom')!;
      expect(d.kind, TransactionKind.transfer);
      expect(d.counterparty, 'Mom');
    });

    test('9. "salary 50000" -> income, salary', () {
      final d = extract('salary 50000')!;
      expect(d.kind, TransactionKind.income);
      expect(d.category, 'salary');
    });

    test('10. "300 medicine" -> expense, healthcare', () {
      expect(extract('300 medicine')!.category, 'healthcare');
    });

    test('11. "200 movie" -> expense, entertainment', () {
      expect(extract('200 movie')!.category, 'entertainment');
    });

    test('12. "1500 amazon" -> expense, shopping', () {
      expect(extract('1500 amazon')!.category, 'shopping');
    });

    test('13. "split 600 with rahul,priya" -> split', () {
      final d = extract('split 600 with rahul,priya')!;
      expect(d.kind, TransactionKind.split);
      expect(d.splitWith, ['Rahul', 'Priya']);
    });

    test('14. "400 zomato" -> expense, food', () {
      final d = extract('400 zomato')!;
      expect(d.category, 'food');
      expect(d.counterparty, 'zomato');
    });

    test('15. "350 swiggy" -> expense, food', () {
      expect(extract('350 swiggy')!.category, 'food');
    });

    test('16. "50.5 chai" -> expense, food, 50.5', () {
      expect(extract('50.5 chai')!.amount, 50.5);
    });

    test('17. "80 breakfast" -> expense, food', () {
      expect(extract('80 breakfast')!.category, 'food');
    });

    test('18. "100 rapido" -> expense, transport', () {
      expect(extract('100 rapido')!.category, 'transport');
    });

    test('19. "800 fuel" -> expense, transport', () {
      expect(extract('800 fuel')!.category, 'transport');
    });

    test('20. "300 sabzi" -> expense, food', () {
      expect(extract('300 sabzi')!.category, 'food');
    });

    test('21. "1000 wifi" -> expense, utilities', () {
      expect(extract('1000 wifi')!.category, 'utilities');
    });

    test('22. "500 doctor" -> expense, healthcare', () {
      expect(extract('500 doctor')!.category, 'healthcare');
    });

    test('23. "99 spotify" -> expense, entertainment', () {
      expect(extract('99 spotify')!.category, 'entertainment');
    });

    test('24. "2000 flipkart" -> expense, shopping', () {
      expect(extract('2000 flipkart')!.category, 'shopping');
    });

    test('25. "40 snack" -> expense, food', () {
      expect(extract('40 snack')!.category, 'food');
    });
  });

  group('Smoke entries: Stage 1 (pattern)', () {
    test('26. "paid 500 to rahul" -> transfer, Rahul', () {
      final d = extract('paid 500 to rahul')!;
      expect(d.kind, TransactionKind.transfer);
      expect(d.counterparty, 'Rahul');
    });

    test('27. "rahul paid me 300" -> income, Rahul', () {
      final d = extract('rahul paid me 300')!;
      expect(d.kind, TransactionKind.income);
      expect(d.counterparty, 'Rahul');
    });

    test('28. "priya owes me 250" -> split, Priya', () {
      final d = extract('priya owes me 250')!;
      expect(d.kind, TransactionKind.split);
    });

    test('29. "i owe rahul 500" -> transfer, Rahul', () {
      final d = extract('i owe rahul 500')!;
      expect(d.kind, TransactionKind.transfer);
    });

    test('30. "500 birthday gift" -> expense, note=birthday gift', () {
      final d = extract('500 birthday gift')!;
      expect(d.kind, TransactionKind.expense);
      expect(d.note, 'birthday gift');
      expect(d.fieldConfidence['category'], 0.60);
    });
  });

  group('Smoke entries: Normalization', () {
    test('31. "  100   COFFEE  " -> normalizes and matches', () {
      expect(extract('  100   COFFEE  '), isNotNull);
    });

    test('32. "200 LUNCH" -> case insensitive', () {
      expect(extract('200 LUNCH')!.category, 'food');
    });
  });

  group('Smoke entries: Adversarial cases', () {
    test('33. Missing amount: "paid rahul" -> null (no match)', () {
      expect(extract('paid rahul'), isNull);
    });

    test('34. Ambiguous counterparty: "500 to a" -> transfer', () {
      final d = extract('500 to a')!;
      expect(d.kind, TransactionKind.transfer);
      expect(d.counterparty, 'A');
    });

    test('35. Very large: "500000 rent" -> matches but sanity checker will flag', () {
      final d = extract('500000 rent')!;
      expect(d.amount, 500000);
    });

    test('36. Just a number: "500" -> null (no keyword)', () {
      expect(extract('500'), isNull);
    });

    test('37. Empty input: "" -> null', () {
      expect(extract(''), isNull);
    });

    test('38. Split with 2+ people: "split 900 with a,b,c" -> split', () {
      final d = extract('split 900 with a,b,c')!;
      expect(d.splitWith, hasLength(3));
    });

    test('39. Decimal amount: "99.99 coffee" -> 99.99', () {
      expect(extract('99.99 coffee')!.amount, 99.99);
    });

    test('40. "split 0 with rahul" -> amount 0', () {
      final d = extract('split 0 with rahul')!;
      expect(d.amount, 0);
    });
  });

  group('Smoke entries: LLM-required (Stage 3, verify routing only)', () {
    // These inputs can't be parsed by Stages 0-1.
    // Verify router classifies them correctly; LLM tested manually.

    test('41. "rahul ko 500 diye dinner ke liye" -> router: entry', () {
      expect(router.classify('rahul ko 500 diye dinner ke liye'),
          SaraswatiRoute.entry);
    });

    test('42. "kal swiggy se 350 ka order kiya" -> router: ambiguous', () {
      // "kal" not a question word, has number but no entry verb in set
      final route = router.classify('kal swiggy se 350 ka order kiya');
      expect(route, isIn([SaraswatiRoute.entry, SaraswatiRoute.ambiguous]));
    });

    test('43. "mom ko 5000 bheje" -> router: entry', () {
      expect(router.classify('mom ko 5000 bheje'),
          SaraswatiRoute.entry);
    });

    test('44. "parso 200 ka auto liya" -> router: entry or ambiguous', () {
      final route = router.classify('parso 200 ka auto liya');
      expect(route, isIn([SaraswatiRoute.entry, SaraswatiRoute.ambiguous]));
    });

    test('45. "amazon se headphones liye 2500" -> router: entry or ambiguous', () {
      final route = router.classify('amazon se headphones liye 2500');
      expect(route, isIn([SaraswatiRoute.entry, SaraswatiRoute.ambiguous]));
    });
  });

  group('Smoke entries: Questions (must NOT route to entry)', () {
    test('46. "today spending" -> question or ambiguous (no number)', () {
      final route = router.classify('today spending');
      // No number, so entry heuristic fails. May be ambiguous if no question signal.
      expect(route, isIn([SaraswatiRoute.question, SaraswatiRoute.ambiguous]));
    });

    test('47. "show me food spending" -> question', () {
      expect(router.classify('show me food spending'),
          SaraswatiRoute.question);
    });

    test('48. "how much did i spend this week?" -> question', () {
      expect(router.classify('how much did i spend this week?'),
          SaraswatiRoute.question);
    });

    test('49. "kitna kharch hua is mahine" -> question', () {
      expect(router.classify('kitna kharch hua is mahine'),
          SaraswatiRoute.question);
    });

    test('50. "category breakdown" -> question', () {
      expect(router.classify('category breakdown'),
          SaraswatiRoute.question);
    });

    test('51. "compare this month vs last month" -> question', () {
      expect(router.classify('compare this month vs last month'),
          SaraswatiRoute.question);
    });

    test('52. "biggest expense this month" -> question', () {
      expect(router.classify('biggest expense this month'),
          SaraswatiRoute.question);
    });
  });

  group('Smoke entries: Mixed language patterns', () {
    test('53. "600 gas bill" -> expense, utilities', () {
      expect(extract('600 gas bill')!.category, 'utilities');
    });

    test('54. "split 1000 with amit" -> split', () {
      final d = extract('split 1000 with amit')!;
      expect(d.splitWith, ['Amit']);
    });

    test('55. "199 netflix" -> expense, entertainment', () {
      expect(extract('199 netflix')!.category, 'entertainment');
    });
  });
}
