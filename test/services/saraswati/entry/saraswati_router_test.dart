import 'package:flutter_test/flutter_test.dart';
import 'package:finance_buddy_app/services/saraswati/saraswati_router.dart';

void main() {
  const router = SaraswatiRouter();

  group('Entry classification', () {
    test('"100 coffee" -> entry', () {
      expect(router.classify('100 coffee'), SaraswatiRoute.entry);
    });

    test('"200 lunch" -> entry', () {
      expect(router.classify('200 lunch'), SaraswatiRoute.entry);
    });

    test('"500 to mom" -> entry', () {
      expect(router.classify('500 to mom'), SaraswatiRoute.entry);
    });

    test('"salary 50000" -> ambiguous (no entry verb, no leading digit)', () {
      // "salary" is not a transaction verb; ambiguous path will try entry pipeline.
      expect(router.classify('salary 50000'), SaraswatiRoute.ambiguous);
    });

    test('"split 600 with rahul" -> entry', () {
      expect(router.classify('split 600 with rahul'), SaraswatiRoute.entry);
    });

    test('"paid 300 to priya" -> entry', () {
      expect(router.classify('paid 300 to priya'), SaraswatiRoute.entry);
    });

    test('"1500 amazon" -> entry', () {
      expect(router.classify('1500 amazon'), SaraswatiRoute.entry);
    });

    test('"rahul ko 500 diye" -> entry', () {
      expect(router.classify('rahul ko 500 diye'), SaraswatiRoute.entry);
    });
  });

  group('Question classification', () {
    test('"how much did i spend today" -> question', () {
      expect(
          router.classify('how much did i spend today'), SaraswatiRoute.question);
    });

    test('"what is my top category" -> question', () {
      expect(router.classify('what is my top category'), SaraswatiRoute.question);
    });

    test('"show me food spending" -> question', () {
      expect(router.classify('show me food spending'), SaraswatiRoute.question);
    });

    test('"kitna kharch hua" -> question', () {
      expect(router.classify('kitna kharch hua'), SaraswatiRoute.question);
    });

    test('"tell me about transport" -> question', () {
      expect(router.classify('tell me about transport'), SaraswatiRoute.question);
    });

    test('"category breakdown" -> question', () {
      expect(router.classify('category breakdown'), SaraswatiRoute.question);
    });

    test('"am i over budget?" -> question', () {
      expect(router.classify('am i over budget?'), SaraswatiRoute.question);
    });

    test('"compare this month vs last month" -> question', () {
      expect(router.classify('compare this month vs last month'),
          SaraswatiRoute.question);
    });
  });

  group('Ambiguous classification', () {
    test('"500" (just a number) -> ambiguous', () {
      expect(router.classify('500'), SaraswatiRoute.ambiguous);
    });

    test('empty string -> question', () {
      expect(router.classify(''), SaraswatiRoute.question);
    });

    test('"hello" -> ambiguous', () {
      expect(router.classify('hello'), SaraswatiRoute.ambiguous);
    });
  });

  group('Edge cases', () {
    test('"how much did i spent 500" -> ambiguous (both signals)', () {
      // Contains question word AND number+verb
      final route = router.classify('how much did i spent 500');
      expect(route, SaraswatiRoute.ambiguous);
    });

    test('"help" -> question (no number)', () {
      expect(router.classify('help'), SaraswatiRoute.ambiguous);
    });
  });
}
