import 'package:finance_buddy_app/core/enums.dart';
import 'package:finance_buddy_app/services/import/models/raw_transaction.dart';
import 'package:finance_buddy_app/services/import/pdf_parsers/pdf_bank_parser.dart';

/// Parses SBI PDF statement text into transactions.
///
/// Real SBI PDF format (extracted text):
///   Header: "Account Statement from {date} to {date}"
///   Columns: Txn Date | Value Date | Description | Ref No./Cheque No. | Debit | Credit | Balance
///   Dates use text months: "12 Mar 2021" (can wrap across lines: "12 Mar\n2021")
///   Descriptions start with "TO TRANSFER-" (debit) or "BY TRANSFER-" (credit)
///   Amounts use Indian comma format: "2,94,113.60"
///
/// Key challenge: dates and descriptions wrap across multiple lines in the PDF extraction.
class SbiPdfParser extends PdfBankParser {
  @override
  BankType get bankType => BankType.sbi;

  @override
  bool canParse(String extractedText) {
    final lower = extractedText.toLowerCase();
    return (lower.contains('state bank of india') ||
            lower.contains('sbin')) &&
        (lower.contains('account statement') ||
            lower.contains('txn date'));
  }

  static const _monthMap = {
    'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
    'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
  };

  // SBI transaction markers.
  static final _debitMarker = RegExp(r'TO TRANSFER-|TO SELF-|TO INT\.', caseSensitive: false);
  static final _creditMarker = RegExp(r'BY TRANSFER-|BY CLEARING-|BY INT\.|BY SALARY', caseSensitive: false);

  // Date pattern: "12 Mar 2021" or "12 Mar\n2021" (text month)
  static final _datePattern = RegExp(
    r'(\d{1,2})\s+(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\s*\n?\s*(\d{4})',
    caseSensitive: false,
  );

  // Amount at end of line: comma-separated Indian format
  static final _amountPattern = RegExp(r'([\d,]+\.\d{2})\s*$');

  @override
  List<RawTransaction> parse(String extractedText) {
    final transactions = <RawTransaction>[];

    // Normalize: collapse line breaks within transaction blocks.
    // SBI PDFs break dates and descriptions across lines aggressively.
    final normalized = extractedText
        .replaceAll(RegExp(r'\n(?=\d{4}\b)'), ' ') // Join year to previous line
        .replaceAll(RegExp(r'\n(?=[A-Z]{2,})'), ' '); // Join continuation lines

    final lines = normalized.split('\n');

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      // Look for debit or credit markers.
      final isDebit = _debitMarker.hasMatch(line);
      final isCredit = _creditMarker.hasMatch(line);
      if (!isDebit && !isCredit) continue;

      // Try to find a date nearby (in this line or preceding lines).
      DateTime? date;
      // Check current line and 2 lines before for a date.
      for (var j = i; j >= (i - 2).clamp(0, lines.length) && date == null; j--) {
        final dateMatch = _datePattern.firstMatch(lines[j]);
        if (dateMatch != null) {
          final day = int.parse(dateMatch.group(1)!);
          final month = _monthMap[dateMatch.group(2)!.toLowerCase().substring(0, 3)];
          final year = int.parse(dateMatch.group(3)!);
          if (month != null) date = DateTime(year, month, day);
        }
      }
      if (date == null) continue;

      // Collect the full description (may span multiple lines until next amount).
      final descBuffer = StringBuffer(line);
      var amountLine = line;

      // Look ahead for amount if not on current line.
      if (!_amountPattern.hasMatch(line)) {
        for (var j = i + 1; j < lines.length && j <= i + 3; j++) {
          descBuffer.write(' ${lines[j].trim()}');
          amountLine = lines[j].trim();
          if (_amountPattern.hasMatch(amountLine)) break;
        }
      }

      // Extract amount from the end.
      final fullText = descBuffer.toString();
      final amountMatch = _amountPattern.firstMatch(fullText);
      if (amountMatch == null) continue;

      final amount = _parseAmount(amountMatch.group(1)!);
      if (amount == null || amount == 0) continue;

      // Extract description (everything before the amount, cleaned up).
      var description = fullText.substring(0, amountMatch.start).trim();
      // Remove the transfer prefix for cleaner description.
      description = description
          .replaceFirst(RegExp(r'^(TO|BY)\s+TRANSFER-\s*', caseSensitive: false), '')
          .trim();

      transactions.add(RawTransaction(
        date: date,
        amount: amount,
        type: isDebit ? 'debit' : 'credit',
        rawDescription: description,
        sourceBank: BankType.sbi,
      ));
    }

    return transactions;
  }

  double? _parseAmount(String s) {
    if (s.isEmpty) return null;
    final cleaned = s.replaceAll(',', '').trim();
    if (cleaned.isEmpty) return null;
    return double.tryParse(cleaned);
  }
}
