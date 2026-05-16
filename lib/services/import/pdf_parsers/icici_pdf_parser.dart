import 'package:finance_buddy_app/core/enums.dart';
import 'package:finance_buddy_app/services/import/models/raw_transaction.dart';
import 'package:finance_buddy_app/services/import/pdf_parsers/pdf_bank_parser.dart';

/// Parses ICICI Bank PDF statement text into transactions.
///
/// Real ICICI Net Banking PDF format (extracted text):
///   Header: "DETAILED STATEMENT" + "Transactions List"
///   Columns: S No. | Value Date | Transaction Date | Cheque Number | Transaction Remarks | Withdrawal Amount (INR) | Deposit Amount (INR) | Balance (INR)
///   Row format: {serial}{date} {date} {chequeNo} {description}{withdrawal} {deposit} {balance}
///   Example: "126/02/2021 26/02/2021 - CMS/ INFY SALARY FOR FEB 21/INFOSYS LIMITED0.0 133666.0 140989.83"
///
/// Note: Serial number is concatenated directly to the first date (no space).
/// Description can wrap across lines. Amounts use single decimal (e.g. "0.0" not "0.00").
class IciciPdfParser extends PdfBankParser {
  @override
  BankType get bankType => BankType.icici;

  @override
  bool canParse(String extractedText) {
    final lower = extractedText.toLowerCase();
    return (lower.contains('icici') || lower.contains('detailed statement')) &&
        lower.contains('transaction remarks') &&
        lower.contains('withdrawal amount');
  }

  // Pattern: serial + date(dd/MM/yyyy) + date + chequeNo + description + 3 amounts at end
  // The serial is concatenated to the first date, e.g. "126/02/2021"
  // Amounts at end: withdrawal deposit balance (each is digits with optional comma and decimal)
  static final _rowStartPattern = RegExp(
    r'(\d+)(\d{2}/\d{2}/\d{4})\s+(\d{2}/\d{2}/\d{4})\s+',
  );

  // Amounts at end of a transaction block: 3 numbers
  static final _amountsPattern = RegExp(
    r'([\d,]+\.?\d*)\s+([\d,]+\.?\d*)\s+([\d,]+\.?\d*)\s*$',
  );

  @override
  List<RawTransaction> parse(String extractedText) {
    final transactions = <RawTransaction>[];

    // Split into lines and find transaction blocks.
    // Each transaction starts with a serial+date pattern.
    final lines = extractedText.split('\n');
    final blocks = <String>[];
    final buffer = StringBuffer();

    for (final line in lines) {
      if (_rowStartPattern.hasMatch(line) && buffer.isNotEmpty) {
        blocks.add(buffer.toString().trim());
        buffer.clear();
      }
      buffer.writeln(line);
    }
    if (buffer.isNotEmpty) blocks.add(buffer.toString().trim());

    for (final block in blocks) {
      final startMatch = _rowStartPattern.firstMatch(block);
      if (startMatch == null) continue;

      final dateStr = startMatch.group(2)!;
      final date = _parseDate(dateStr);
      if (date == null) continue;

      // Extract amounts from the end of the block (flattened to single line).
      final flat = block.replaceAll('\n', ' ').replaceAll(RegExp(r'\s+'), ' ');
      final amountsMatch = _amountsPattern.firstMatch(flat);
      if (amountsMatch == null) continue;

      final withdrawalStr = amountsMatch.group(1)!;
      final depositStr = amountsMatch.group(2)!;

      final withdrawal = _parseAmount(withdrawalStr);
      final deposit = _parseAmount(depositStr);

      // Skip if both are 0.
      if ((withdrawal == null || withdrawal == 0) &&
          (deposit == null || deposit == 0)) {
        continue;
      }

      // Extract description: everything between the start pattern and the amounts.
      final descStart = startMatch.end;
      final descEnd = amountsMatch.start;
      final flatDesc = flat.substring(
        descStart.clamp(0, flat.length),
        descEnd.clamp(0, flat.length),
      ).trim();

      // Clean up the description: remove cheque number prefix (usually "- " or a ref code).
      var description = flatDesc;
      if (description.startsWith('- ')) {
        description = description.substring(2).trim();
      }

      final isDebit = withdrawal != null && withdrawal > 0;
      transactions.add(RawTransaction(
        date: date,
        amount: isDebit ? withdrawal : deposit!,
        type: isDebit ? 'debit' : 'credit',
        rawDescription: description,
        sourceBank: BankType.icici,
      ));
    }

    return transactions;
  }

  DateTime? _parseDate(String s) {
    final parts = s.split('/');
    if (parts.length != 3) return null;
    try {
      final day = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      var year = int.parse(parts[2]);
      if (year < 100) year += 2000;
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
