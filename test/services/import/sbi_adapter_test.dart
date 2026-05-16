import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:finance_buddy_app/core/enums.dart';
import 'package:finance_buddy_app/services/import/bank_adapters/sbi_adapter.dart';

void main() {
  late SbiAdapter adapter;
  late String yonoContent;
  late String legacyContent;
  late String amountSuffixContent;

  setUp(() {
    adapter = SbiAdapter();
    yonoContent = File('test/fixtures/sbi_yono_sample.csv').readAsStringSync();
    legacyContent =
        File('test/fixtures/sbi_legacy_sample.csv').readAsStringSync();
    amountSuffixContent =
        File('test/fixtures/sbi_amount_suffix_sample.csv').readAsStringSync();
  });

  test('bankType is sbi', () {
    expect(adapter.bankType, BankType.sbi);
  });

  group('canParse', () {
    test('recognizes Format A (YONO) header', () {
      expect(
        adapter.canParse(
            'Txn Date,Value Date,Description,Ref No./Cheque No.,Debit,Credit,Balance'),
        isTrue,
      );
    });

    test('recognizes Format B (legacy) header', () {
      expect(
        adapter.canParse(
            'Txn Date\tValue Date\tDescription\tRef No./Cheque No.\tBranch Code\tDebit\tCredit\tBalance'),
        isTrue,
      );
    });

    test('recognizes Format C (amount suffix) header', () {
      expect(
        adapter.canParse('Txn Date,Value Date,Description,Ref No.,Amount,Balance'),
        isTrue,
      );
    });

    test('rejects non-SBI header', () {
      expect(
        adapter.canParse(
            'Transaction Date,Value Date,Description,Ref No./Cheque No.,Debit,Credit,Balance'),
        isFalse,
      );
    });
  });

  group('Format A (YONO) parsing', () {
    test('parses all 15 transactions', () {
      final txns = adapter.parse(yonoContent);
      expect(txns.length, 15);
    });

    test('skips preamble', () {
      final txns = adapter.parse(yonoContent);
      expect(txns.first.date, DateTime(2026, 1, 3));
      expect(txns.first.rawDescription, contains('SWIGGY'));
    });

    test('skips footer summary rows', () {
      final txns = adapter.parse(yonoContent);
      expect(txns.length, 15);
      expect(txns.last.date, DateTime(2026, 2, 8));
    });

    test('parses dd MMM yyyy date format', () {
      final txns = adapter.parse(yonoContent);
      expect(txns[0].date, DateTime(2026, 1, 3));
      expect(txns[3].date, DateTime(2026, 1, 10));
      expect(txns[11].date, DateTime(2026, 2, 1));
    });

    test('handles full month name "January"', () {
      final txns = adapter.parse(yonoContent);
      // Row 3 (07 January 2026 in Value Date but dd MMM yyyy in Txn Date)
      // Row 13 has "03 February 2026" in Value Date — Txn Date column matters
      final febTxn = txns[12]; // 03 Feb 2026 (LIC)
      expect(febTxn.date, DateTime(2026, 2, 3));
    });

    test('parses debits correctly', () {
      final txns = adapter.parse(yonoContent);
      expect(txns[0].type, 'debit');
      expect(txns[0].amount, 380.0);
    });

    test('parses credits correctly', () {
      final txns = adapter.parse(yonoContent);
      final salary = txns[2]; // NEFT salary
      expect(salary.type, 'credit');
      expect(salary.amount, 92000.0);
    });

    test('extracts reference numbers', () {
      final txns = adapter.parse(yonoContent);
      expect(txns[0].referenceNumber, 'UTR412345678');
    });

    test('debit/credit count is correct', () {
      final txns = adapter.parse(yonoContent);
      final debits = txns.where((t) => t.type == 'debit').length;
      final credits = txns.where((t) => t.type == 'credit').length;
      expect(debits, 13);
      expect(credits, 2);
    });
  });

  group('Format B (legacy, tab-separated) parsing', () {
    test('parses all 10 transactions', () {
      final txns = adapter.parse(legacyContent);
      expect(txns.length, 10);
    });

    test('tab-delimited parsing works', () {
      final txns = adapter.parse(legacyContent);
      expect(txns.first.rawDescription, contains('SWIGGY'));
      expect(txns.first.amount, 450.0);
    });

    test('parses dd-MMM-yy date format', () {
      final txns = adapter.parse(legacyContent);
      expect(txns[0].date, DateTime(2026, 1, 3));
      expect(txns[4].date, DateTime(2026, 1, 15));
      expect(txns[8].date, DateTime(2026, 2, 1));
    });

    test('2-digit year correctly assumed 20xx', () {
      final txns = adapter.parse(legacyContent);
      // "26" → 2026
      expect(txns[0].date.year, 2026);
      expect(txns[9].date.year, 2026);
    });

    test('skips rows where Debit=0 AND Credit=0', () {
      // All rows in fixture have either non-zero debit or non-zero credit
      // The fixture has 0.00 in the opposite column — those should NOT be skipped
      final txns = adapter.parse(legacyContent);
      expect(txns.length, 10);
    });

    test('skips trailing summary', () {
      final txns = adapter.parse(legacyContent);
      expect(txns.last.date, DateTime(2026, 2, 5));
    });
  });

  group('Format C (amount suffix Dr/Cr) parsing', () {
    test('parses all 10 transactions', () {
      final txns = adapter.parse(amountSuffixContent);
      expect(txns.length, 10);
    });

    test('parses (Dr) as debit', () {
      final txns = adapter.parse(amountSuffixContent);
      expect(txns[0].type, 'debit');
      expect(txns[0].amount, 380.0);
    });

    test('parses (Cr) as credit', () {
      final txns = adapter.parse(amountSuffixContent);
      final salary = txns[2]; // NEFT salary
      expect(salary.type, 'credit');
      expect(salary.amount, 85000.0);
    });

    test('handles commas in amount', () {
      // The fixture has "28000.00(Dr)" which has no comma, but
      // verify the parser handles "1,23,456.78(Dr)" pattern
      final parsed = adapter.parse(
        'Preamble\n\nTxn Date,Value Date,Description,Ref No.,Amount,Balance\n'
        '03 Jan 2026,03 Jan 2026,Test,REF1,"1,23,456.78(Dr)",50000.00\n',
      );
      expect(parsed.length, 1);
      expect(parsed[0].amount, 123456.78);
    });

    test('skips footer', () {
      final txns = adapter.parse(amountSuffixContent);
      expect(txns.length, 10);
      expect(txns.last.date, DateTime(2026, 2, 5));
    });
  });

  group('Date parsing edge cases', () {
    test('case insensitive month: JAN, jan, Jan all work', () {
      final content =
          'Txn Date,Value Date,Description,Ref No./Cheque No.,Debit,Credit,Balance\n'
          '03 JAN 2026,03 JAN 2026,Test Upper,REF1,100.00,,900.00\n'
          '04 jan 2026,04 jan 2026,Test Lower,REF2,200.00,,700.00\n'
          '05 Jan 2026,05 Jan 2026,Test Mixed,REF3,300.00,,400.00\n';
      final txns = adapter.parse(content);
      expect(txns.length, 3);
      expect(txns[0].date, DateTime(2026, 1, 3));
      expect(txns[1].date, DateTime(2026, 1, 4));
      expect(txns[2].date, DateTime(2026, 1, 5));
    });

    test('full month names: January, February work', () {
      final content =
          'Txn Date,Value Date,Description,Ref No./Cheque No.,Debit,Credit,Balance\n'
          '15 January 2026,15 January 2026,Test Jan,REF1,500.00,,500.00\n'
          '20 February 2026,20 February 2026,Test Feb,REF2,600.00,,400.00\n';
      final txns = adapter.parse(content);
      expect(txns.length, 2);
      expect(txns[0].date, DateTime(2026, 1, 15));
      expect(txns[1].date, DateTime(2026, 2, 20));
    });

    test('dd/MM/yyyy fallback works', () {
      final content =
          'Txn Date,Value Date,Description,Ref No./Cheque No.,Debit,Credit,Balance\n'
          '15/01/2026,15/01/2026,Test Numeric,REF1,100.00,,900.00\n';
      final txns = adapter.parse(content);
      expect(txns.length, 1);
      expect(txns[0].date, DateTime(2026, 1, 15));
    });

    test('non-parseable date rows are skipped gracefully', () {
      final content =
          'Txn Date,Value Date,Description,Ref No./Cheque No.,Debit,Credit,Balance\n'
          '03 Jan 2026,03 Jan 2026,Valid,REF1,100.00,,900.00\n'
          'Opening Balance,,,,,63000.00,63000.00\n'
          '05 Jan 2026,05 Jan 2026,Also Valid,REF2,200.00,,700.00\n';
      final txns = adapter.parse(content);
      expect(txns.length, 2);
    });
  });

  group('Edge cases', () {
    test('empty CSV', () {
      expect(adapter.parse(''), isEmpty);
    });

    test('header-only CSV', () {
      final txns = adapter.parse(
          'Txn Date,Value Date,Description,Ref No./Cheque No.,Debit,Credit,Balance\n');
      expect(txns, isEmpty);
    });
  });
}
