import 'package:flutter_test/flutter_test.dart';
import 'package:finance_buddy_app/core/enums.dart';
import 'package:finance_buddy_app/services/import/models/normalized_transaction.dart';
import 'package:finance_buddy_app/services/import/models/raw_transaction.dart';
import 'package:finance_buddy_app/services/import/transaction_normalizer.dart';

void main() {
  late TransactionNormalizer normalizer;

  setUp(() {
    normalizer = TransactionNormalizer();
  });

  NormalizedTransaction _normalize(String desc, {String type = 'debit'}) {
    return normalizer.normalize(RawTransaction(
      date: DateTime(2026, 1, 15),
      amount: 500.0,
      type: type,
      rawDescription: desc,
      sourceBank: BankType.hdfc,
    ));
  }

  group('Channel detection', () {
    test('detects UPI channel', () {
      final txn = _normalize('UPI-SWIGGY-swiggy@axisbank-HDFC0001234');
      expect(txn.channel, TransactionChannel.upi);
    });

    test('detects POS channel', () {
      final txn = _normalize('POS HDFC BIGBAZAAR MUM 5678****1234');
      expect(txn.channel, TransactionChannel.pos);
    });

    test('detects NEFT channel', () {
      final txn = _normalize('NEFT CR-ACME CORP-SALARY JAN 2026');
      expect(txn.channel, TransactionChannel.neft);
    });

    test('detects IMPS channel', () {
      final txn = _normalize('IMPS-JOHN DOE-ICICI-1234567890');
      expect(txn.channel, TransactionChannel.imps);
    });

    test('detects ATM channel', () {
      final txn = _normalize('ATM WDL-HDFC ATM ANDHERI-5678****1234');
      expect(txn.channel, TransactionChannel.atm);
    });

    test('defaults to other channel', () {
      final txn = _normalize('MONTHLY SALARY CREDIT');
      expect(txn.channel, TransactionChannel.other);
    });
  });

  group('Description cleaning', () {
    test('strips masked card numbers', () {
      final txn = _normalize('POS BIGBAZAAR 5678****1234');
      expect(txn.cleanedDescription, isNot(contains('5678****1234')));
    });

    test('strips reference IDs', () {
      final txn = _normalize('UPI TXN:ABC123DEF swiggy');
      expect(txn.cleanedDescription, isNot(contains('abc123def')));
    });

    test('strips dates in description', () {
      final txn = _normalize('POS SWIGGY 15/01/2026 MUM');
      expect(txn.cleanedDescription, isNot(contains('15/01/2026')));
    });

    test('collapses whitespace', () {
      final txn = _normalize('POS   HDFC   BIGBAZAAR   MUM');
      expect(txn.cleanedDescription, isNot(contains('  ')));
    });

    test('lowercases', () {
      final txn = _normalize('POS HDFC BIGBAZAAR MUM');
      expect(txn.cleanedDescription, txn.cleanedDescription.toLowerCase());
    });
  });

  group('Merchant token extraction', () {
    test('extracts longest alpha word from POS', () {
      final txn = _normalize('POS HDFC BIGBAZAAR MUM');
      expect(txn.merchantToken, 'bigbazaar');
    });

    test('extracts merchant from UPI description', () {
      final txn = _normalize('UPI-SWIGGY-swiggy@axisbank-HDFC0001234');
      expect(txn.merchantToken, 'swiggy');
    });

    test('extracts merchant from NEFT salary', () {
      final txn = _normalize('NEFT CR-ACME CORP-SALARY JAN 2026');
      expect(txn.merchantToken, 'salary');
    });

    test('extracts merchant from electricity bill', () {
      final txn = _normalize('BESCOM ELECTRICITY BILL BBPS');
      expect(txn.merchantToken, 'electricity');
    });

    test('extracts merchant from EMI', () {
      final txn = _normalize('EMI LOAN HDFC HOME LOAN AC 123456');
      expect(txn.merchantToken, 'loan');
    });

    test('handles empty description gracefully', () {
      final txn = _normalize('');
      expect(txn.merchantToken, isEmpty);
    });

    test('handles numeric-only description', () {
      final txn = _normalize('1234567890');
      expect(txn.merchantToken, isEmpty);
    });

    test('caps at 30 characters', () {
      final txn = _normalize(
          'ABCDEFGHIJKLMNOPQRSTUVWXYZABCDEFGHIJKLMNOPQRSTUVWXYZ');
      expect(txn.merchantToken.length, lessThanOrEqualTo(30));
    });
  });

  group('Hash computation', () {
    test('same input produces same hash', () {
      final a = _normalize('POS SWIGGY MUM');
      final b = _normalize('POS SWIGGY MUM');
      expect(a.rawHash, b.rawHash);
    });

    test('different amounts produce different hashes', () {
      final a = normalizer.normalize(RawTransaction(
        date: DateTime(2026, 1, 15),
        amount: 500.0,
        type: 'debit',
        rawDescription: 'POS SWIGGY MUM',
        sourceBank: BankType.hdfc,
      ));
      final b = normalizer.normalize(RawTransaction(
        date: DateTime(2026, 1, 15),
        amount: 600.0,
        type: 'debit',
        rawDescription: 'POS SWIGGY MUM',
        sourceBank: BankType.hdfc,
      ));
      expect(a.rawHash, isNot(b.rawHash));
    });

    test('different dates produce different hashes', () {
      final a = normalizer.normalize(RawTransaction(
        date: DateTime(2026, 1, 15),
        amount: 500.0,
        type: 'debit',
        rawDescription: 'POS SWIGGY MUM',
        sourceBank: BankType.hdfc,
      ));
      final b = normalizer.normalize(RawTransaction(
        date: DateTime(2026, 2, 15),
        amount: 500.0,
        type: 'debit',
        rawDescription: 'POS SWIGGY MUM',
        sourceBank: BankType.hdfc,
      ));
      expect(a.rawHash, isNot(b.rawHash));
    });

    test('hash is 64 char hex string (SHA256)', () {
      final txn = _normalize('POS SWIGGY MUM');
      expect(txn.rawHash.length, 64);
      expect(RegExp(r'^[a-f0-9]+$').hasMatch(txn.rawHash), isTrue);
    });
  });

  group('Golden tests — real-looking HDFC descriptions', () {
    test('Swiggy UPI', () {
      final txn = _normalize('UPI-SWIGGY-swiggy@axisbank-HDFC0001234-567890123456');
      expect(txn.channel, TransactionChannel.upi);
      expect(txn.merchantToken, 'swiggy');
    });

    test('Zomato UPI', () {
      final txn = _normalize('UPI-ZOMATO-zomato@paytm-HDFC0001234-987654321098');
      expect(txn.channel, TransactionChannel.upi);
      expect(txn.merchantToken, 'zomato');
    });

    test('Uber UPI', () {
      final txn = _normalize('UPI-UBER-uber@icici-HDFC0001234-111222333444');
      expect(txn.channel, TransactionChannel.upi);
      expect(txn.merchantToken, 'uber');
    });

    test('BigBazaar POS', () {
      final txn = _normalize('POS HDFC BIGBAZAAR MUM 5678****1234');
      expect(txn.channel, TransactionChannel.pos);
      expect(txn.merchantToken, 'bigbazaar');
    });

    test('Netflix POS', () {
      final txn = _normalize('POS NETFLIX.COM 5678****1234');
      expect(txn.channel, TransactionChannel.pos);
      // merchantToken will be longest alpha word
      expect(txn.merchantToken, isNotEmpty);
    });

    test('ATM withdrawal', () {
      final txn = _normalize('ATM WDL-HDFC ATM ANDHERI-5678****1234');
      expect(txn.channel, TransactionChannel.atm);
    });

    test('Salary credit NEFT', () {
      final txn = _normalize('NEFT CR-ACME CORP-SALARY JAN 2026');
      expect(txn.channel, TransactionChannel.neft);
      expect(txn.merchantToken, 'salary');
    });

    test('EMI debit', () {
      final txn = _normalize('EMI LOAN HDFC HOME LOAN AC 123456');
      expect(txn.channel, TransactionChannel.other);
    });

    test('BESCOM electricity', () {
      final txn = _normalize('BESCOM ELECTRICITY BILL BBPS');
      expect(txn.merchantToken, 'electricity');
    });

    test('IMPS transfer', () {
      final txn = _normalize('IMPS-JOHN DOE-ICICI-1234567890');
      expect(txn.channel, TransactionChannel.imps);
    });
  });
}
