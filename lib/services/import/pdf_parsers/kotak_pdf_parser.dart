import 'package:finance_buddy_app/core/enums.dart';
import 'package:finance_buddy_app/services/import/models/raw_transaction.dart';
import 'package:finance_buddy_app/services/import/pdf_parsers/pdf_bank_parser.dart';

/// Parses Kotak Mahindra Bank PDF statement text into transactions.
///
/// Kotak PDF layout (typical):
///   Sl No  Date        Description                    Amount     Dr/Cr   Balance
///   1      03/01/2026  UPI/SWIGGY/swiggy@axisbank     380.00     DR      55620.00
class KotakPdfParser extends PdfBankParser {
  @override
  BankType get bankType => BankType.kotak;

  @override
  bool canParse(String extractedText) {
    final lower = extractedText.toLowerCase();
    return lower.contains('kotak mahindra bank') &&
        (lower.contains('statement of account') ||
            lower.contains('account statement'));
  }

  // Pattern: date (dd/MM/yyyy) + description + amount + Dr/Cr indicator
  static final _txnPattern = RegExp(
    r'(\d{2}/\d{2}/\d{4})\s+(.+?)\s+([\d,]+\.\d{2})\s+(Dr|Cr|DR|CR)\s+([\d,]+\.\d{2})',
    multiLine: true,
    caseSensitive: false,
  );

  static final _simpleTxnPattern = RegExp(
    r'(\d{2}/\d{2}/\d{4})\s+(.+?)\s+([\d,]+\.\d{2})\s+(Dr|Cr|DR|CR)\s*$',
    multiLine: true,
    caseSensitive: false,
  );

  @override
  List<RawTransaction> parse(String extractedText) {
    final transactions = <RawTransaction>[];

    for (final match in _txnPattern.allMatches(extractedText)) {
      final dateStr = match.group(1)!;
      final description = match.group(2)!.trim();
      final amountStr = match.group(3)!;
      final indicator = match.group(4)!;

      final date = _parseDate(dateStr);
      if (date == null) continue;
      if (description.isEmpty) continue;

      final amount = _parseAmount(amountStr);
      if (amount == null || amount == 0) continue;

      final type = indicator.toLowerCase() == 'dr' ? 'debit' : 'credit';
      transactions.add(RawTransaction(
        date: date,
        amount: amount,
        type: type,
        rawDescription: description,
        sourceBank: BankType.kotak,
      ));
    }

    if (transactions.isEmpty) {
      for (final match in _simpleTxnPattern.allMatches(extractedText)) {
        final dateStr = match.group(1)!;
        final description = match.group(2)!.trim();
        final amountStr = match.group(3)!;
        final indicator = match.group(4)!;

        final date = _parseDate(dateStr);
        if (date == null) continue;

        final amount = _parseAmount(amountStr);
        if (amount == null || amount == 0) continue;

        final type = indicator.toLowerCase() == 'dr' ? 'debit' : 'credit';
        transactions.add(RawTransaction(
          date: date,
          amount: amount,
          type: type,
          rawDescription: description,
          sourceBank: BankType.kotak,
        ));
      }
    }

    return transactions;
  }

  DateTime? _parseDate(String s) {
    final parts = s.split('/');
    if (parts.length != 3) return null;
    try {
      final day = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final year = int.parse(parts[2]);
      return DateTime(year, month, day);
    } on FormatException {
      return null;
    }
  }

  double? _parseAmount(String s) {
    if (s.isEmpty) return null;
    final cleaned = s.replaceAll(',', '').trim();
    if (cleaned.isEmpty) return null;
    return double.tryParse(cleaned);
  }
}
