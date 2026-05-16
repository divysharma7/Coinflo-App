import 'package:finance_buddy_app/core/enums.dart';
import 'package:finance_buddy_app/services/import/models/raw_transaction.dart';
import 'package:finance_buddy_app/services/import/pdf_parsers/pdf_bank_parser.dart';

/// Parses HDFC Bank PDF statement text into transactions.
///
/// HDFC Net Banking PDFs use the same "DETAILED STATEMENT" format as ICICI
/// when exported from Net Banking. Detection differentiates by looking for
/// "HDFC" in the account header or bank name.
///
/// Standard HDFC PDF layout:
///   Date       Narration                    Chq./Ref.No.  Withdrawal  Deposit  Closing Balance
///   03/01/22   UPI/SWIGGY/swiggy@axis...    567890        450.00               45230.50
///
/// Also handles the ICICI-like "DETAILED STATEMENT" format that some HDFC
/// exports use (same parser logic — serial + dates + amounts pattern).
class HdfcPdfParser extends PdfBankParser {
  @override
  BankType get bankType => BankType.hdfc;

  @override
  bool canParse(String extractedText) {
    final lower = extractedText.toLowerCase();
    // HDFC-specific: look for "hdfc bank" or HDFC account patterns.
    // Avoid matching ICICI statements.
    return lower.contains('hdfc bank') &&
        !lower.contains('icici') &&
        (lower.contains('statement of account') ||
            lower.contains('account statement') ||
            lower.contains('transaction history'));
  }

  // Pattern 1: Standard HDFC — date (dd/MM/yy or dd/MM/yyyy) + narration + amounts
  static final _standardPattern = RegExp(
    r'(\d{2}/\d{2}/\d{2,4})\s+(.+?)\s+([\d,]+\.\d{2})\s+([\d,]+\.\d{2})\s*$',
    multiLine: true,
  );

  // Pattern 2: ICICI-like format with serial numbers
  static final _serialPattern = RegExp(
    r'(\d+)(\d{2}/\d{2}/\d{4})\s+(\d{2}/\d{2}/\d{4})\s+',
  );

  static final _amountsEnd = RegExp(
    r'([\d,]+\.?\d*)\s+([\d,]+\.?\d*)\s+([\d,]+\.?\d*)\s*$',
  );

  @override
  List<RawTransaction> parse(String extractedText) {
    // Try ICICI-like serial format first (common for HDFC Net Banking exports).
    final serialResults = _parseSerialFormat(extractedText);
    if (serialResults.isNotEmpty) return serialResults;

    // Fallback to standard HDFC PDF layout.
    return _parseStandardFormat(extractedText);
  }

  List<RawTransaction> _parseSerialFormat(String extractedText) {
    final transactions = <RawTransaction>[];
    final lines = extractedText.split('\n');
    final blocks = <String>[];
    final buffer = StringBuffer();

    for (final line in lines) {
      if (_serialPattern.hasMatch(line) && buffer.isNotEmpty) {
        blocks.add(buffer.toString().trim());
        buffer.clear();
      }
      buffer.writeln(line);
    }
    if (buffer.isNotEmpty) blocks.add(buffer.toString().trim());

    for (final block in blocks) {
      final startMatch = _serialPattern.firstMatch(block);
      if (startMatch == null) continue;

      final dateStr = startMatch.group(2)!;
      final date = _parseDate(dateStr);
      if (date == null) continue;

      final flat = block.replaceAll('\n', ' ').replaceAll(RegExp(r'\s+'), ' ');
      final amountsMatch = _amountsEnd.firstMatch(flat);
      if (amountsMatch == null) continue;

      final withdrawalStr = amountsMatch.group(1)!;
      final depositStr = amountsMatch.group(2)!;

      final withdrawal = _parseAmount(withdrawalStr);
      final deposit = _parseAmount(depositStr);

      if ((withdrawal == null || withdrawal == 0) &&
          (deposit == null || deposit == 0)) {
        continue;
      }

      final descStart = startMatch.end;
      final descEnd = amountsMatch.start;
      var description = flat
          .substring(
            descStart.clamp(0, flat.length),
            descEnd.clamp(0, flat.length),
          )
          .trim();
      if (description.startsWith('- ')) {
        description = description.substring(2).trim();
      }

      final isDebit = withdrawal != null && withdrawal > 0;
      transactions.add(RawTransaction(
        date: date,
        amount: isDebit ? withdrawal : deposit!,
        type: isDebit ? 'debit' : 'credit',
        rawDescription: description,
        sourceBank: BankType.hdfc,
      ));
    }

    return transactions;
  }

  List<RawTransaction> _parseStandardFormat(String extractedText) {
    final transactions = <RawTransaction>[];

    for (final match in _standardPattern.allMatches(extractedText)) {
      final dateStr = match.group(1)!;
      final description = match.group(2)!.trim();
      final amount1Str = match.group(3)!;
      final amount2Str = match.group(4)!;

      final date = _parseDate(dateStr);
      if (date == null) continue;

      final amount1 = _parseAmount(amount1Str);
      final amount2 = _parseAmount(amount2Str);

      if (amount1 == null) continue;

      // In standard HDFC: if second amount is larger, first is the txn amount.
      // Heuristic: withdrawal is smaller, balance is larger.
      if (amount2 != null && amount2 > amount1) {
        transactions.add(RawTransaction(
          date: date,
          amount: amount1,
          type: 'debit',
          rawDescription: description,
          sourceBank: BankType.hdfc,
        ));
      } else {
        transactions.add(RawTransaction(
          date: date,
          amount: amount1,
          type: 'debit',
          rawDescription: description,
          sourceBank: BankType.hdfc,
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
