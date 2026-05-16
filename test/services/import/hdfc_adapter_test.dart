import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:finance_buddy_app/core/enums.dart';
import 'package:finance_buddy_app/services/import/bank_adapters/hdfc_adapter.dart';

void main() {
  late HdfcAdapter adapter;
  late String fixtureContent;

  setUp(() {
    adapter = HdfcAdapter();
    fixtureContent = File('test/fixtures/hdfc_sample.csv').readAsStringSync();
  });

  test('bankType is hdfc', () {
    expect(adapter.bankType, BankType.hdfc);
  });

  group('canParse', () {
    test('recognizes HDFC header', () {
      expect(
        adapter.canParse(
            'Date,Narration,Value Dat,Debit Amount,Credit Amount,Chq/Ref Number,Closing Balance'),
        isTrue,
      );
    });

    test('rejects non-HDFC header', () {
      expect(adapter.canParse('Transaction Date,Value Date,Description,Debit,Credit,Balance'), isFalse);
    });

    test('case insensitive', () {
      expect(
        adapter.canParse(
            'date,narration,value dat,debit amount,credit amount,chq/ref number,closing balance'),
        isTrue,
      );
    });
  });

  group('parse', () {
    test('parses all 20 transactions from fixture', () {
      final txns = adapter.parse(fixtureContent);
      expect(txns.length, 20);
    });

    test('parses debit transactions correctly', () {
      final txns = adapter.parse(fixtureContent);
      final swiggy = txns.first;
      expect(swiggy.type, 'debit');
      expect(swiggy.amount, 450.0);
      expect(swiggy.date, DateTime(2026, 1, 3));
      expect(swiggy.rawDescription, contains('SWIGGY'));
      expect(swiggy.sourceBank, BankType.hdfc);
    });

    test('parses credit transactions correctly', () {
      final txns = adapter.parse(fixtureContent);
      final salary = txns[2]; // Third row is salary credit
      expect(salary.type, 'credit');
      expect(salary.amount, 85000.0);
      expect(salary.rawDescription, contains('SALARY'));
    });

    test('parses dates in dd/MM/yy format', () {
      final txns = adapter.parse(fixtureContent);
      expect(txns[0].date, DateTime(2026, 1, 3));
      expect(txns[4].date, DateTime(2026, 1, 12));
      expect(txns[11].date, DateTime(2026, 2, 1));
    });

    test('extracts reference numbers', () {
      final txns = adapter.parse(fixtureContent);
      expect(txns[0].referenceNumber, isNotNull);
    });

    test('handles empty CSV', () {
      final txns = adapter.parse('');
      expect(txns, isEmpty);
    });

    test('handles header-only CSV', () {
      final txns = adapter.parse(
          'Date,Narration,Value Dat,Debit Amount,Credit Amount,Chq/Ref Number,Closing Balance\n');
      expect(txns, isEmpty);
    });

    test('counts debits and credits correctly', () {
      final txns = adapter.parse(fixtureContent);
      final debits = txns.where((t) => t.type == 'debit').length;
      final credits = txns.where((t) => t.type == 'credit').length;
      expect(debits, 18);
      expect(credits, 2);
    });
  });
}
