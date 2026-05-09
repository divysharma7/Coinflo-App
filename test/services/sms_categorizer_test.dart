import 'package:flutter_test/flutter_test.dart';
import 'package:finance_buddy_app/core/enums.dart';
import 'package:finance_buddy_app/models/parsed_sms.dart';
import 'package:finance_buddy_app/services/sms/sms_categorizer.dart';

/// Helper to create a [ParsedSms] with sensible defaults for testing.
ParsedSms _makeSms({
  double amount = 100.0,
  bool isDebit = true,
  String? merchant,
  DateTime? receivedAt,
}) {
  return ParsedSms(
    amount: amount,
    isDebit: isDebit,
    merchant: merchant,
    rawText: 'test sms body',
    receivedAt: receivedAt ?? DateTime(2026, 5, 15), // mid-month default
  );
}

void main() {
  group('SmsCategorizer.categorize()', () {
    group('transport merchants', () {
      test('UBER merchant maps to TransactionCategory.transport', () {
        final sms = _makeSms(merchant: 'UBER INDIA');
        expect(
          SmsCategorizer.categorize(sms),
          equals(TransactionCategory.transport),
        );
      });

      test('OLA merchant maps to TransactionCategory.transport', () {
        final sms = _makeSms(merchant: 'OLA CABS');
        expect(
          SmsCategorizer.categorize(sms),
          equals(TransactionCategory.transport),
        );
      });

      test('RAPIDO merchant maps to TransactionCategory.transport', () {
        final sms = _makeSms(merchant: 'RAPIDO BIKE');
        expect(
          SmsCategorizer.categorize(sms),
          equals(TransactionCategory.transport),
        );
      });

      test('IRCTC merchant maps to TransactionCategory.transport', () {
        final sms = _makeSms(merchant: 'IRCTC WEB');
        expect(
          SmsCategorizer.categorize(sms),
          equals(TransactionCategory.transport),
        );
      });

      test('METRO merchant maps to TransactionCategory.transport', () {
        final sms = _makeSms(merchant: 'METRO SMART CARD');
        expect(
          SmsCategorizer.categorize(sms),
          equals(TransactionCategory.transport),
        );
      });
    });

    group('foodAndDrink merchants', () {
      test('SWIGGY merchant maps to TransactionCategory.foodAndDrink', () {
        final sms = _makeSms(merchant: 'SWIGGY INDIA');
        expect(
          SmsCategorizer.categorize(sms),
          equals(TransactionCategory.foodAndDrink),
        );
      });

      test('ZOMATO merchant maps to TransactionCategory.foodAndDrink', () {
        final sms = _makeSms(merchant: 'ZOMATO LTD');
        expect(
          SmsCategorizer.categorize(sms),
          equals(TransactionCategory.foodAndDrink),
        );
      });

      test('BLINKIT merchant maps to TransactionCategory.foodAndDrink', () {
        final sms = _makeSms(merchant: 'BLINKIT');
        expect(
          SmsCategorizer.categorize(sms),
          equals(TransactionCategory.foodAndDrink),
        );
      });

      test('DOMINOS merchant maps to TransactionCategory.foodAndDrink', () {
        final sms = _makeSms(merchant: 'DOMINOS PIZZA');
        expect(
          SmsCategorizer.categorize(sms),
          equals(TransactionCategory.foodAndDrink),
        );
      });

      test('STARBUCKS merchant maps to TransactionCategory.foodAndDrink', () {
        final sms = _makeSms(merchant: 'STARBUCKS COFFEE');
        expect(
          SmsCategorizer.categorize(sms),
          equals(TransactionCategory.foodAndDrink),
        );
      });
    });

    group('entertainment merchants', () {
      test('BOOKMYSHOW merchant maps to TransactionCategory.entertainment', () {
        final sms = _makeSms(merchant: 'BOOKMYSHOW');
        expect(
          SmsCategorizer.categorize(sms),
          equals(TransactionCategory.entertainment),
        );
      });

      test('PVR merchant maps to TransactionCategory.entertainment', () {
        final sms = _makeSms(merchant: 'PVR CINEMAS');
        expect(
          SmsCategorizer.categorize(sms),
          equals(TransactionCategory.entertainment),
        );
      });
    });

    group('case insensitivity', () {
      test('lowercase uber still maps to transport', () {
        final sms = _makeSms(merchant: 'uber india');
        expect(
          SmsCategorizer.categorize(sms),
          equals(TransactionCategory.transport),
        );
      });

      test('mixed case Swiggy still maps to foodAndDrink', () {
        final sms = _makeSms(merchant: 'Swiggy Delivery');
        expect(
          SmsCategorizer.categorize(sms),
          equals(TransactionCategory.foodAndDrink),
        );
      });

      test('ALL CAPS ZOMATO still maps to foodAndDrink', () {
        final sms = _makeSms(merchant: 'ZOMATO');
        expect(
          SmsCategorizer.categorize(sms),
          equals(TransactionCategory.foodAndDrink),
        );
      });
    });

    group('credit transactions', () {
      test('credit (isDebit=false) returns TransactionCategory.foodAndDrink', () {
        final sms = _makeSms(isDebit: false, amount: 5000);
        expect(
          SmsCategorizer.categorize(sms),
          equals(TransactionCategory.foodAndDrink),
        );
      });

      test(
        'credit returns foodAndDrink even if merchant matches a known rule',
        () {
          // Credit check happens before merchant matching in the code
          final sms = _makeSms(isDebit: false, merchant: 'UBER INDIA');
          expect(
            SmsCategorizer.categorize(sms),
            equals(TransactionCategory.foodAndDrink),
          );
        },
      );

      test('credit with large shopping-range amount still returns foodAndDrink', () {
        // receivedAt on day 1, amount in shopping range, but isDebit=false
        final sms = _makeSms(
          isDebit: false,
          amount: 21000,
          receivedAt: DateTime(2026, 5, 1),
        );
        expect(
          SmsCategorizer.categorize(sms),
          equals(TransactionCategory.foodAndDrink),
        );
      });
    });

    group('shopping heuristic', () {
      test(
        'large amount (21000) on day 1 of month returns TransactionCategory.shopping',
        () {
          final sms = _makeSms(
            amount: 21000,
            receivedAt: DateTime(2026, 5, 1),
          );
          expect(
            SmsCategorizer.categorize(sms),
            equals(TransactionCategory.shopping),
          );
        },
      );

      test('large amount (15000) on day 3 returns shopping', () {
        final sms = _makeSms(
          amount: 15000,
          receivedAt: DateTime(2026, 5, 3),
        );
        expect(
          SmsCategorizer.categorize(sms),
          equals(TransactionCategory.shopping),
        );
      });

      test('large amount (50000) on day 5 returns shopping', () {
        final sms = _makeSms(
          amount: 50000,
          receivedAt: DateTime(2026, 5, 5),
        );
        expect(
          SmsCategorizer.categorize(sms),
          equals(TransactionCategory.shopping),
        );
      });

      test(
        'large amount on day 6 does NOT return shopping (outside day 1-5 window)',
        () {
          final sms = _makeSms(
            amount: 25000,
            receivedAt: DateTime(2026, 5, 6),
          );
          expect(
            SmsCategorizer.categorize(sms),
            equals(TransactionCategory.foodAndDrink),
          );
        },
      );

      test('amount below 15000 on day 1 does NOT return shopping', () {
        final sms = _makeSms(
          amount: 14999,
          receivedAt: DateTime(2026, 5, 1),
        );
        expect(
          SmsCategorizer.categorize(sms),
          equals(TransactionCategory.foodAndDrink),
        );
      });

      test('amount above 50000 on day 1 does NOT return shopping', () {
        final sms = _makeSms(
          amount: 50001,
          receivedAt: DateTime(2026, 5, 1),
        );
        expect(
          SmsCategorizer.categorize(sms),
          equals(TransactionCategory.foodAndDrink),
        );
      });

      test('merchant match takes priority over shopping heuristic', () {
        // Even though amount and day match shopping, merchant rule comes first
        final sms = _makeSms(
          amount: 20000,
          merchant: 'UBER INDIA',
          receivedAt: DateTime(2026, 5, 1),
        );
        expect(
          SmsCategorizer.categorize(sms),
          equals(TransactionCategory.transport),
        );
      });
    });

    group('unknown / default', () {
      test('unknown merchant with no shopping match returns foodAndDrink', () {
        final sms = _makeSms(merchant: 'SOME RANDOM SHOP');
        expect(
          SmsCategorizer.categorize(sms),
          equals(TransactionCategory.foodAndDrink),
        );
      });

      test('null merchant with mid-month small amount returns foodAndDrink', () {
        final sms = _makeSms(
          merchant: null,
          amount: 200,
          receivedAt: DateTime(2026, 5, 15),
        );
        expect(
          SmsCategorizer.categorize(sms),
          equals(TransactionCategory.foodAndDrink),
        );
      });
    });
  });
}
