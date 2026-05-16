import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:finance_buddy_app/core/enums.dart';
import 'package:finance_buddy_app/services/import/bank_adapters/kotak_adapter.dart';

void main() {
  late KotakAdapter adapter;
  late String fixtureContent;

  setUp(() {
    adapter = KotakAdapter();
    fixtureContent =
        File('test/fixtures/kotak_sample.csv').readAsStringSync();
  });

  test('bankType is kotak', () {
    expect(adapter.bankType, BankType.kotak);
  });

  group('canParse (detection signature)', () {
    test('recognizes Format A header (Sl. No. + Dr / Cr)', () {
      expect(
        adapter.canParse(
            'Sl. No.,Transaction Date,Value Date,Description,Chq / Ref No.,Amount,Dr / Cr,Balance'),
        isTrue,
      );
    });

    test('recognizes variant without spaces (Dr/Cr)', () {
      expect(
        adapter.canParse(
            'Sl. No.,Transaction Date,Value Date,Description,Ref No.,Amount,Dr/Cr,Balance'),
        isTrue,
      );
    });

    test('case insensitive', () {
      expect(
        adapter.canParse(
            'sl. no.,transaction date,value date,description,chq / ref no.,amount,dr / cr,balance'),
        isTrue,
      );
    });

    test('rejects Format B generic headers (no Sl. No., no Dr/Cr)', () {
      expect(
        adapter.canParse('Date,Description,Debit,Credit,Balance'),
        isFalse,
      );
    });

    test('rejects HDFC header', () {
      expect(
        adapter.canParse(
            'Date,Narration,Value Dat,Debit Amount,Credit Amount,Chq/Ref Number,Closing Balance'),
        isFalse,
      );
    });

    test('rejects ICICI header', () {
      expect(
        adapter.canParse(
            'Transaction Date,Value Date,Description,Ref No./Cheque No.,Debit,Credit,Balance'),
        isFalse,
      );
    });

    test('rejects SBI header', () {
      expect(
        adapter.canParse(
            'Txn Date,Value Date,Description,Ref No./Cheque No.,Debit,Credit,Balance'),
        isFalse,
      );
    });

    test('rejects Axis header', () {
      expect(
        adapter.canParse('Tran Date,CHQNO,PARTICULARS,DR,CR,BAL,SOL'),
        isFalse,
      );
    });
  });

  group('Format A parsing', () {
    test('parses all 15 transactions', () {
      final txns = adapter.parse(fixtureContent);
      expect(txns.length, 15);
    });

    test('skips preamble (5 lines + blank)', () {
      final txns = adapter.parse(fixtureContent);
      expect(txns.first.date, DateTime(2026, 1, 3));
      expect(txns.first.rawDescription, contains('SWIGGY'));
    });

    test('skips trailing summary rows', () {
      final txns = adapter.parse(fixtureContent);
      expect(txns.length, 15);
      expect(txns.last.date, DateTime(2026, 2, 8));
    });

    test('parses dd/MM/yyyy date format', () {
      final txns = adapter.parse(fixtureContent);
      expect(txns[0].date, DateTime(2026, 1, 3));
      expect(txns[5].date, DateTime(2026, 1, 15));
      expect(txns[11].date, DateTime(2026, 2, 1));
    });

    test('skips Sl. No. column correctly', () {
      // Verify description is not "1" (first serial number)
      final txns = adapter.parse(fixtureContent);
      expect(txns.first.rawDescription, isNot('1'));
      expect(txns.first.rawDescription, contains('UPI'));
    });

    test('extracts reference numbers', () {
      final txns = adapter.parse(fixtureContent);
      expect(txns[0].referenceNumber, 'UTR412345');
      expect(txns[2].referenceNumber, 'NEFT778899');
    });

    test('parses amount correctly (single Amount column)', () {
      final txns = adapter.parse(fixtureContent);
      expect(txns[0].amount, 380.0);
      expect(txns[2].amount, 92000.0);
      expect(txns[5].amount, 28000.0);
    });

    test('debit/credit count', () {
      final txns = adapter.parse(fixtureContent);
      final debits = txns.where((t) => t.type == 'debit').length;
      final credits = txns.where((t) => t.type == 'credit').length;
      expect(debits, 12);
      expect(credits, 3);
    });
  });

  group('Dr/Cr capitalization variants', () {
    test('DR (uppercase) → debit', () {
      final txns = adapter.parse(fixtureContent);
      expect(txns[0].type, 'debit'); // Row 1: DR
    });

    test('Dr (title case) → debit', () {
      final txns = adapter.parse(fixtureContent);
      expect(txns[1].type, 'debit'); // Row 2: Dr
    });

    test('dr (lowercase) → debit', () {
      final txns = adapter.parse(fixtureContent);
      expect(txns[3].type, 'debit'); // Row 4: dr
    });

    test('CR (uppercase) → credit', () {
      final txns = adapter.parse(fixtureContent);
      expect(txns[2].type, 'credit'); // Row 3: CR
    });

    test('Cr (title case) → credit', () {
      final txns = adapter.parse(fixtureContent);
      expect(txns[11].type, 'credit'); // Row 12: Cr
    });

    test('cr (lowercase) → credit', () {
      final txns = adapter.parse(fixtureContent);
      expect(txns[13].type, 'credit'); // Row 14: cr
    });
  });

  group('Dr/Cr error handling', () {
    test('unexpected Dr/Cr value throws FormatException', () {
      final badContent =
          'Sl. No.,Transaction Date,Value Date,Description,Chq / Ref No.,Amount,Dr / Cr,Balance\n'
          '1,03/01/2026,03/01/2026,Test transaction,REF1,500.00,Debit,50000.00\n';

      expect(
        () => adapter.parse(badContent),
        throwsA(isA<FormatException>().having(
          (e) => e.message,
          'message',
          contains('Debit'),
        )),
      );
    });
  });

  group('Regression — other bank fixtures not misdetected', () {
    test('HDFC fixture not parsed as Kotak', () {
      final content = File('test/fixtures/hdfc_sample.csv').readAsStringSync();
      final txns = adapter.parse(content);
      expect(txns, isEmpty);
    });

    test('ICICI fixture not parsed as Kotak', () {
      final content = File('test/fixtures/icici_sample.csv').readAsStringSync();
      final txns = adapter.parse(content);
      expect(txns, isEmpty);
    });

    test('SBI fixture not parsed as Kotak', () {
      final content =
          File('test/fixtures/sbi_yono_sample.csv').readAsStringSync();
      final txns = adapter.parse(content);
      expect(txns, isEmpty);
    });

    test('Axis fixture not parsed as Kotak', () {
      final content =
          File('test/fixtures/axis_standard_sample.csv').readAsStringSync();
      final txns = adapter.parse(content);
      expect(txns, isEmpty);
    });
  });

  group('Edge cases', () {
    test('empty CSV', () {
      expect(adapter.parse(''), isEmpty);
    });

    test('header-only CSV', () {
      final txns = adapter.parse(
          'Sl. No.,Transaction Date,Value Date,Description,Chq / Ref No.,Amount,Dr / Cr,Balance\n');
      expect(txns, isEmpty);
    });

    test('amount=0 rows are skipped', () {
      final content =
          'Sl. No.,Transaction Date,Value Date,Description,Chq / Ref No.,Amount,Dr / Cr,Balance\n'
          '1,03/01/2026,03/01/2026,Opening Balance,,-,DR,56000.00\n'
          '2,03/01/2026,03/01/2026,Real Txn,REF1,500.00,DR,55500.00\n';
      final txns = adapter.parse(content);
      expect(txns.length, 1);
      expect(txns.first.amount, 500.0);
    });
  });
}
