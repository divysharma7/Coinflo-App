import 'package:flutter_test/flutter_test.dart';
import 'package:finance_buddy_app/services/sms/sms_parser.dart';

void main() {
  group('SmsParser.parse()', () {
    group('SBI debit SMS', () {
      test('parses standard debit SMS with amount, isDebit, and merchant', () {
        final result = SmsParser.parse(
          'Your SBI a/c X1234 debited by Rs.340.00 on 01May25 trf to UBER INDIA',
        );

        expect(result, isNotNull);
        expect(result!.amount, 340.0);
        expect(result.isDebit, isTrue);
        expect(result.merchant, isNotNull);
        expect(result.merchant!.toUpperCase(), contains('UBER'));
      });

      test('parses alternate debit format "Rs.X has been debited"', () {
        final result = SmsParser.parse(
          'Rs.1200.50 has been debited from your SBI a/c',
        );

        expect(result, isNotNull);
        expect(result!.amount, 1200.50);
        expect(result.isDebit, isTrue);
      });

      test('parses alternate debit format "Rs.X is debited"', () {
        final result = SmsParser.parse(
          'Rs.500 is debited from your SBI a/c X9876',
        );

        expect(result, isNotNull);
        expect(result!.amount, 500.0);
        expect(result.isDebit, isTrue);
      });
    });

    group('SBI credit SMS', () {
      test('parses standard credit SMS with amount and isDebit=false', () {
        final result = SmsParser.parse(
          'Your SBI a/c X1234 credited by Rs.5000.00',
        );

        expect(result, isNotNull);
        expect(result!.amount, 5000.0);
        expect(result.isDebit, isFalse);
      });

      test('parses alternate credit format "Rs.X is credited"', () {
        final result = SmsParser.parse(
          'Rs.25000 is credited to your SBI a/c',
        );

        expect(result, isNotNull);
        expect(result!.amount, 25000.0);
        expect(result.isDebit, isFalse);
      });

      test('parses alternate credit format "Rs.X has been credited"', () {
        final result = SmsParser.parse(
          'Rs.7500.75 has been credited to your SBI a/c X4321',
        );

        expect(result, isNotNull);
        expect(result!.amount, 7500.75);
        expect(result.isDebit, isFalse);
      });
    });

    group('amount parsing', () {
      test('handles amounts with Indian comma formatting', () {
        final result = SmsParser.parse(
          'Your SBI a/c X1234 debited by Rs.1,00,000.00 on 15Apr25',
        );

        expect(result, isNotNull);
        expect(result!.amount, 100000.0);
        expect(result.isDebit, isTrue);
      });

      test('handles amounts with standard comma formatting', () {
        final result = SmsParser.parse(
          'Your SBI a/c X5678 debited by Rs.10,500.00',
        );

        expect(result, isNotNull);
        expect(result!.amount, 10500.0);
      });

      test('handles whole number amounts without decimals', () {
        final result = SmsParser.parse(
          'Your SBI a/c X1234 debited by Rs.200 on 05Apr25',
        );

        expect(result, isNotNull);
        expect(result!.amount, 200.0);
      });
    });

    group('merchant extraction', () {
      test('extracts merchant from "trf to SWIGGY INDIA"', () {
        final result = SmsParser.parse(
          'Your SBI a/c X1234 debited by Rs.450.00 on 10Apr25 trf to SWIGGY INDIA',
        );

        expect(result, isNotNull);
        expect(result!.merchant, isNotNull);
        expect(result.merchant!.toUpperCase(), contains('SWIGGY'));
      });

      test('extracts merchant from "at STARBUCKS"', () {
        final result = SmsParser.parse(
          'Your SBI a/c X1234 debited by Rs.550.00 at STARBUCKS INDIA',
        );

        expect(result, isNotNull);
        expect(result!.merchant, isNotNull);
        expect(result.merchant!.toUpperCase(), contains('STARBUCKS'));
      });

      test('extracts merchant from "trf to ZOMATO LTD"', () {
        final result = SmsParser.parse(
          'Your SBI a/c X1234 debited by Rs.999.00 trf to ZOMATO LTD',
        );

        expect(result, isNotNull);
        expect(result!.merchant, isNotNull);
        expect(result.merchant!.toUpperCase(), contains('ZOMATO'));
      });

      test('returns null merchant when no merchant pattern is found', () {
        final result = SmsParser.parse(
          'Your SBI a/c X1234 debited by Rs.100.00',
        );

        expect(result, isNotNull);
        expect(result!.merchant, isNull);
      });

      test('strips trailing common words like "on", "dated", "ref"', () {
        final result = SmsParser.parse(
          'Your SBI a/c X1234 debited by Rs.300.00 trf to FLIPKART on 20Apr25 Ref123',
        );

        expect(result, isNotNull);
        expect(result!.merchant, isNotNull);
        // Merchant should not contain "on 20Apr25 Ref123"
        expect(result.merchant!.toLowerCase(), isNot(contains('ref')));
        expect(result.merchant!.toUpperCase(), contains('FLIPKART'));
      });
    });

    group('non-bank and invalid SMS', () {
      test('returns null for non-bank SMS (OTP)', () {
        final result = SmsParser.parse('Your OTP is 123456');

        expect(result, isNull);
      });

      test('returns null for empty string', () {
        final result = SmsParser.parse('');

        expect(result, isNull);
      });

      test('returns null for promotional SMS', () {
        final result = SmsParser.parse(
          'SALE! Get 50% off on all items. Shop now at BigBazaar!',
        );

        expect(result, isNull);
      });

      test('returns null for SMS with no amount pattern', () {
        final result = SmsParser.parse(
          'Your SBI a/c X1234 has been blocked. Contact customer care.',
        );

        expect(result, isNull);
      });
    });

    group('rawText preservation', () {
      test('stores the original SMS body in rawText', () {
        const body =
            'Your SBI a/c X1234 debited by Rs.340.00 on 01May25 trf to UBER INDIA';
        final result = SmsParser.parse(body);

        expect(result, isNotNull);
        expect(result!.rawText, equals(body));
      });
    });

    group('receivedAt', () {
      test('sets receivedAt to approximately now', () {
        final before = DateTime.now();
        final result = SmsParser.parse(
          'Your SBI a/c X1234 debited by Rs.100.00',
        );
        final after = DateTime.now();

        expect(result, isNotNull);
        expect(
          result!.receivedAt.isAfter(before.subtract(const Duration(seconds: 1))),
          isTrue,
        );
        expect(
          result.receivedAt.isBefore(after.add(const Duration(seconds: 1))),
          isTrue,
        );
      });
    });
  });
}
