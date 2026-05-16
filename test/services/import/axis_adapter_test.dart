import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:finance_buddy_app/core/enums.dart';
import 'package:finance_buddy_app/services/import/bank_adapters/axis_adapter.dart';

void main() {
  late AxisAdapter adapter;
  late String standardContent;
  late String variantContent;

  setUp(() {
    adapter = AxisAdapter();
    standardContent =
        File('test/fixtures/axis_standard_sample.csv').readAsStringSync();
    variantContent =
        File('test/fixtures/axis_variant_sample.csv').readAsStringSync();
  });

  test('bankType is axis', () {
    expect(adapter.bankType, BankType.axis);
  });

  group('canParse', () {
    test('recognizes standard Axis header (PARTICULARS + SOL)', () {
      expect(
        adapter.canParse('Tran Date,CHQNO,PARTICULARS,DR,CR,BAL,SOL'),
        isTrue,
      );
    });

    test('recognizes variant header (Description + Branch Code)', () {
      expect(
        adapter.canParse(
            'Transaction Date,Cheque No,Description,Debit,Credit,Balance,Branch Code'),
        isTrue,
      );
    });

    test('recognizes Narration + Sol ID variant', () {
      expect(
        adapter.canParse('Tran. Date,CHEQUE NO,Narration,DR,CR,BAL,Sol ID'),
        isTrue,
      );
    });

    test('rejects HDFC header (has Narration but no SOL)', () {
      expect(
        adapter.canParse(
            'Date,Narration,Value Dat,Debit Amount,Credit Amount,Chq/Ref Number,Closing Balance'),
        isFalse,
      );
    });

    test('rejects ICICI header (has Description but no SOL)', () {
      expect(
        adapter.canParse(
            'Transaction Date,Value Date,Description,Ref No./Cheque No.,Debit,Credit,Balance'),
        isFalse,
      );
    });

    test('case insensitive', () {
      expect(
        adapter.canParse('tran date,chqno,particulars,dr,cr,bal,sol'),
        isTrue,
      );
    });
  });

  group('Standard format parsing', () {
    test('parses all 15 transactions', () {
      final txns = adapter.parse(standardContent);
      expect(txns.length, 15);
    });

    test('skips preamble rows', () {
      final txns = adapter.parse(standardContent);
      expect(txns.first.date, DateTime(2026, 1, 3));
      expect(txns.first.rawDescription, contains('SWIGGY'));
    });

    test('skips footer summary rows', () {
      final txns = adapter.parse(standardContent);
      expect(txns.length, 15);
      expect(txns.last.date, DateTime(2026, 2, 8));
    });

    test('parses dd-MM-yyyy date format', () {
      final txns = adapter.parse(standardContent);
      expect(txns[0].date, DateTime(2026, 1, 3));
      expect(txns[3].date, DateTime(2026, 1, 10));
      expect(txns[11].date, DateTime(2026, 2, 1));
    });

    test('parses debits correctly (DR column)', () {
      final txns = adapter.parse(standardContent);
      expect(txns[0].type, 'debit');
      expect(txns[0].amount, 420.0);
    });

    test('parses credits correctly (CR column)', () {
      final txns = adapter.parse(standardContent);
      final salary = txns[2]; // NEFT salary
      expect(salary.type, 'credit');
      expect(salary.amount, 88000.0);
    });

    test('extracts CHQNO as reference', () {
      final txns = adapter.parse(standardContent);
      expect(txns[0].referenceNumber, 'UPI445566');
      expect(txns[2].referenceNumber, 'NEFT112233');
    });

    test('debit/credit count', () {
      final txns = adapter.parse(standardContent);
      final debits = txns.where((t) => t.type == 'debit').length;
      final credits = txns.where((t) => t.type == 'credit').length;
      expect(debits, 13);
      expect(credits, 2);
    });

    test('Indian comma-separated amounts', () {
      final txns = adapter.parse(standardContent);
      final emi = txns[5]; // EMI 30000
      expect(emi.amount, 30000.0);
    });
  });

  group('Variant format parsing (alternate headers)', () {
    test('parses all 10 transactions', () {
      final txns = adapter.parse(variantContent);
      expect(txns.length, 10);
    });

    test('maps "Description" correctly (alias of PARTICULARS)', () {
      final txns = adapter.parse(variantContent);
      expect(txns[0].rawDescription, contains('SWIGGY'));
    });

    test('maps "Debit"/"Credit" correctly (alias of DR/CR)', () {
      final txns = adapter.parse(variantContent);
      expect(txns[0].type, 'debit');
      expect(txns[0].amount, 420.0);
      expect(txns[1].type, 'credit');
      expect(txns[1].amount, 88000.0);
    });

    test('maps "Transaction Date" correctly (alias of Tran Date)', () {
      final txns = adapter.parse(variantContent);
      expect(txns[0].date, DateTime(2026, 1, 3));
    });

    test('maps "Cheque No" correctly (alias of CHQNO)', () {
      final txns = adapter.parse(variantContent);
      expect(txns[0].referenceNumber, 'UPI445566');
    });

    test('maps "Branch Code" as SOL (for detection)', () {
      // If it parses, SOL detection worked
      final txns = adapter.parse(variantContent);
      expect(txns, isNotEmpty);
    });

    test('skips footer', () {
      final txns = adapter.parse(variantContent);
      expect(txns.last.date, DateTime(2026, 2, 8));
    });
  });

  group('Column alias matching', () {
    test('PARTICULARS and Description both map to rawDescription', () {
      final standardTxns = adapter.parse(standardContent);
      final variantTxns = adapter.parse(variantContent);
      // Both should have non-empty descriptions
      expect(standardTxns.first.rawDescription, isNotEmpty);
      expect(variantTxns.first.rawDescription, isNotEmpty);
      // Both first rows are Swiggy
      expect(standardTxns.first.rawDescription, contains('SWIGGY'));
      expect(variantTxns.first.rawDescription, contains('SWIGGY'));
    });
  });

  group('Detection regression — distinguishes from other banks', () {
    test('does not detect HDFC fixture as Axis', () {
      final hdfcContent =
          File('test/fixtures/hdfc_sample.csv').readAsStringSync();
      final txns = adapter.parse(hdfcContent);
      // Should fail to find header (no SOL column) and return empty
      expect(txns, isEmpty);
    });

    test('does not detect ICICI fixture as Axis', () {
      final iciciContent =
          File('test/fixtures/icici_sample.csv').readAsStringSync();
      final txns = adapter.parse(iciciContent);
      expect(txns, isEmpty);
    });
  });

  group('Edge cases', () {
    test('empty CSV', () {
      expect(adapter.parse(''), isEmpty);
    });

    test('header-only CSV', () {
      final txns = adapter.parse(
          'Tran Date,CHQNO,PARTICULARS,DR,CR,BAL,SOL\n');
      expect(txns, isEmpty);
    });
  });
}
