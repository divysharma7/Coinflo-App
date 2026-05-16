import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:finance_buddy_app/core/enums.dart';
import 'package:finance_buddy_app/services/import/bank_adapters/icici_adapter.dart';

void main() {
  late IciciAdapter adapter;
  late String formatAContent;
  late String formatBContent;

  setUp(() {
    adapter = IciciAdapter();
    formatAContent = File('test/fixtures/icici_sample.csv').readAsStringSync();
    formatBContent =
        File('test/fixtures/icici_legacy_sample.csv').readAsStringSync();
  });

  test('bankType is icici', () {
    expect(adapter.bankType, BankType.icici);
  });

  group('canParse', () {
    test('recognizes Format A header', () {
      expect(
        adapter.canParse(
            'Transaction Date,Value Date,Description,Ref No./Cheque No.,Debit,Credit,Balance'),
        isTrue,
      );
    });

    test('recognizes Format B header', () {
      expect(
        adapter.canParse(
            'S No.,Value Date,Transaction Date,Cheque Number,Transaction Remarks,Withdrawal Amount (INR ),Deposit Amount (INR ),Balance (INR )'),
        isTrue,
      );
    });

    test('rejects non-ICICI header', () {
      expect(
        adapter.canParse(
            'Date,Narration,Value Dat,Debit Amount,Credit Amount,Chq/Ref Number,Closing Balance'),
        isFalse,
      );
    });

    test('case insensitive', () {
      expect(
        adapter.canParse(
            'transaction date,value date,description,ref no./cheque no.,debit,credit,balance'),
        isTrue,
      );
    });
  });

  group('Format A parsing', () {
    test('parses all 15 transactions from fixture', () {
      final txns = adapter.parse(formatAContent);
      expect(txns.length, 15);
    });

    test('skips 12-line preamble without errors', () {
      final txns = adapter.parse(formatAContent);
      // First transaction should be from 03/01/2026, not any preamble data
      expect(txns.first.date, DateTime(2026, 1, 3));
      expect(txns.first.rawDescription, contains('SWIGGY'));
    });

    test('skips trailing summary rows', () {
      final txns = adapter.parse(formatAContent);
      // Should be exactly 15, not 16 or 17 (summary rows excluded)
      expect(txns.length, 15);
      // Last valid transaction is from 08/02/2026
      expect(txns.last.date, DateTime(2026, 2, 8));
    });

    test('handles quoted description with internal commas', () {
      final txns = adapter.parse(formatAContent);
      // Third transaction has quoted description with comma
      final neftTxn = txns[2]; // 07/01/2026 NEFT
      expect(neftTxn.rawDescription, contains('ACME PVT LTD, MUMBAI'));
      expect(neftTxn.type, 'credit');
      expect(neftTxn.amount, 85000.0);
    });

    test('parses dates in dd/MM/yyyy format (4-digit year)', () {
      final txns = adapter.parse(formatAContent);
      expect(txns[0].date, DateTime(2026, 1, 3));
      expect(txns[5].date, DateTime(2026, 1, 15));
      expect(txns[11].date, DateTime(2026, 2, 1));
    });

    test('parses debit transactions correctly', () {
      final txns = adapter.parse(formatAContent);
      final swiggy = txns[0];
      expect(swiggy.type, 'debit');
      expect(swiggy.amount, 380.0);
      expect(swiggy.sourceBank, BankType.icici);
    });

    test('parses credit transactions correctly', () {
      final txns = adapter.parse(formatAContent);
      final salary = txns[2]; // NEFT credit
      expect(salary.type, 'credit');
      expect(salary.amount, 85000.0);
    });

    test('extracts reference numbers', () {
      final txns = adapter.parse(formatAContent);
      expect(txns[0].referenceNumber, 'UPI567890');
      expect(txns[2].referenceNumber, 'UTR123456');
    });

    test('counts debits and credits correctly', () {
      final txns = adapter.parse(formatAContent);
      final debits = txns.where((t) => t.type == 'debit').length;
      final credits = txns.where((t) => t.type == 'credit').length;
      expect(debits, 13);
      expect(credits, 2);
    });

    test('parses Indian comma-separated amounts', () {
      final txns = adapter.parse(formatAContent);
      // EMI: 28000.00
      final emi = txns[5];
      expect(emi.amount, 28000.0);
    });
  });

  group('Format B (legacy) parsing', () {
    test('parses all 10 transactions from legacy fixture', () {
      final txns = adapter.parse(formatBContent);
      expect(txns.length, 10);
    });

    test('skips preamble in legacy format', () {
      final txns = adapter.parse(formatBContent);
      expect(txns.first.date, DateTime(2026, 1, 3));
    });

    test('skips trailing summary in legacy format', () {
      final txns = adapter.parse(formatBContent);
      expect(txns.length, 10);
      expect(txns.last.date, DateTime(2026, 2, 5));
    });

    test('maps Transaction Remarks to description', () {
      final txns = adapter.parse(formatBContent);
      expect(txns[0].rawDescription, contains('SWIGGY'));
    });

    test('maps Withdrawal Amount to debit', () {
      final txns = adapter.parse(formatBContent);
      final swiggy = txns[0];
      expect(swiggy.type, 'debit');
      expect(swiggy.amount, 450.0);
    });

    test('maps Deposit Amount to credit', () {
      final txns = adapter.parse(formatBContent);
      final salary = txns[1]; // NEFT salary credit
      expect(salary.type, 'credit');
      expect(salary.amount, 75000.0);
    });

    test('extracts cheque numbers as reference', () {
      final txns = adapter.parse(formatBContent);
      expect(txns[0].referenceNumber, 'UPI445566');
    });
  });

  group('Edge cases', () {
    test('handles empty CSV', () {
      final txns = adapter.parse('');
      expect(txns, isEmpty);
    });

    test('handles header-only CSV', () {
      final txns = adapter.parse(
          'Transaction Date,Value Date,Description,Ref No./Cheque No.,Debit,Credit,Balance\n');
      expect(txns, isEmpty);
    });
  });
}
