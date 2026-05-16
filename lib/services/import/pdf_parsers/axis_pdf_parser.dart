import 'package:finance_buddy_app/core/enums.dart';
import 'package:finance_buddy_app/services/import/models/raw_transaction.dart';
import 'package:finance_buddy_app/services/import/pdf_parsers/pdf_bank_parser.dart';

/// Parses Axis Bank PDF statement text into transactions.
///
/// Axis PDF layout (typical):
///   Tran Date    Particulars                    Chq No    Debit      Credit     Balance
///   03-01-2026   UPI/SWIGGY/swiggy@axisbank    UPI445    420.00                58580.00
class AxisPdfParser extends PdfBankParser {
  @override
  BankType get bankType => BankType.axis;

  @override
  bool canParse(String extractedText) {
    final lower = extractedText.toLowerCase();
    return lower.contains('axis bank') &&
        (lower.contains('statement of account') ||
            lower.contains('account statement'));
  }

  // Pattern: dd-MM-yyyy date + description + amounts
  static final _txnPattern = RegExp(
    r'(\d{2}-\d{2}-\d{4})\s+(.+?)\s+([\d,]+\.\d{2})?\s*([\d,]+\.\d{2})?\s*([\d,]+\.\d{2})\s*$',
    multiLine: true,
  );

  static final _simpleTxnPattern = RegExp(
    r'(\d{2}-\d{2}-\d{4})\s+(.+?)\s+([\d,]+\.\d{2})\s*(Cr|Dr)?\s*$',
    multiLine: true,
  );

  @override
  List<RawTransaction> parse(String extractedText) {
    final transactions = <RawTransaction>[];

    for (final match in _txnPattern.allMatches(extractedText)) {
      final dateStr = match.group(1)!;
      final description = match.group(2)!.trim();
      final debitStr = match.group(3) ?? '';
      final creditStr = match.group(4) ?? '';

      final date = _parseDate(dateStr);
      if (date == null) continue;
      if (description.isEmpty) continue;

      final debit = _parseAmount(debitStr);
      final credit = _parseAmount(creditStr);

      if (debit == null && credit == null) continue;

      final isDebit = debit != null && debit > 0;
      transactions.add(RawTransaction(
        date: date,
        amount: isDebit ? debit : credit!,
        type: isDebit ? 'debit' : 'credit',
        rawDescription: description,
        sourceBank: BankType.axis,
      ));
    }

    if (transactions.isEmpty) {
      for (final match in _simpleTxnPattern.allMatches(extractedText)) {
        final dateStr = match.group(1)!;
        final description = match.group(2)!.trim();
        final amountStr = match.group(3)!;
        final indicator = match.group(4);

        final date = _parseDate(dateStr);
        if (date == null) continue;

        final amount = _parseAmount(amountStr);
        if (amount == null) continue;

        final type = indicator?.toLowerCase() == 'cr' ? 'credit' : 'debit';
        transactions.add(RawTransaction(
          date: date,
          amount: amount,
          type: type,
          rawDescription: description,
          sourceBank: BankType.axis,
        ));
      }
    }

    return transactions;
  }

  DateTime? _parseDate(String s) {
    final parts = s.split('-');
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
