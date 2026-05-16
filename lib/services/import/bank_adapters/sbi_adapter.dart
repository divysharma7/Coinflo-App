import 'package:csv/csv.dart';
import 'package:finance_buddy_app/core/enums.dart';
import 'package:finance_buddy_app/services/import/bank_adapters/bank_adapter.dart';
import 'package:finance_buddy_app/services/import/models/raw_transaction.dart';

/// Parses SBI (State Bank of India) CSV statements.
///
/// Supports three export formats:
///
/// Format A (YONO / Net Banking "Download Statement"):
///   Txn Date,Value Date,Description,Ref No./Cheque No.,Debit,Credit,Balance
///   Date format: dd MMM yyyy (e.g. "15 Jan 2026")
///
/// Format B (Legacy "Detailed Statement" / Branch):
///   Txn Date,Value Date,Description,Ref No./Cheque No.,Branch Code,Debit,Credit,Balance
///   Date format: dd-MMM-yy (e.g. "15-Jan-26")
///   May be tab-separated.
///
/// Format C (Single amount column with Dr/Cr suffix):
///   Txn Date,Value Date,Description,Ref No.,Amount,Balance
///   Amount: "450.00(Dr)" or "85000.00(Cr)"
class SbiAdapter extends BankAdapter {
  @override
  BankType get bankType => BankType.sbi;

  @override
  bool canParse(String headerLine) {
    final lower = headerLine.toLowerCase();
    final hasTxnDate = lower.contains('txn date');
    final hasDescription = lower.contains('description');
    final hasAmountIndicator = lower.contains('debit') ||
        lower.contains('withdrawal') ||
        lower.contains('amount');
    return hasTxnDate && hasDescription && hasAmountIndicator;
  }

  @override
  List<RawTransaction> parse(String csvContent) {
    // H2: Detect delimiter from the header line.
    final delimiter = _detectDelimiter(csvContent);

    final rows = CsvToListConverter(
      eol: '\n',
      shouldParseNumbers: false,
      fieldDelimiter: delimiter,
    ).convert(csvContent);

    if (rows.isEmpty) return [];

    // Scan up to 30 lines for the data header row.
    int headerIdx = -1;
    for (var i = 0; i < rows.length && i < 30; i++) {
      final line = rows[i].map((e) => e.toString().toLowerCase().trim()).toList();
      if (_isDataHeader(line)) {
        headerIdx = i;
        break;
      }
    }
    if (headerIdx == -1) return [];

    final header =
        rows[headerIdx].map((e) => e.toString().toLowerCase().trim()).toList();

    final format = _detectFormat(header);
    final transactions = <RawTransaction>[];

    for (var i = headerIdx + 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.length < format.minColumns) continue;

      final dateStr = row[format.dateIdx].toString().trim();
      if (dateStr.isEmpty) continue;

      final date = _parseDate(dateStr);
      if (date == null) continue; // Skip non-date rows (footers/summaries).

      final description = row[format.descIdx].toString().trim();
      if (description.isEmpty) continue;

      final String type;
      final double? amount;

      if (format.isAmountSuffix) {
        // Format C: parse "450.00(Dr)" style.
        final parsed = _parseAmountSuffix(row[format.amountIdx].toString().trim());
        if (parsed == null) continue;
        type = parsed.type;
        amount = parsed.amount;
      } else {
        // Format A/B: separate Debit/Credit columns.
        final debitStr = row[format.debitIdx].toString().trim();
        final creditStr = row[format.creditIdx].toString().trim();
        final debitAmount = _parseAmount(debitStr);
        final creditAmount = _parseAmount(creditStr);

        // Skip rows where both are 0 or empty (opening balance / separators).
        if ((debitAmount == null || debitAmount == 0) &&
            (creditAmount == null || creditAmount == 0)) {
          continue;
        }

        final isDebit = debitAmount != null && debitAmount > 0;
        type = isDebit ? 'debit' : 'credit';
        amount = isDebit ? debitAmount : creditAmount;
      }

      if (amount == null || amount == 0) continue;

      final refStr = format.refIdx >= 0 && row.length > format.refIdx
          ? row[format.refIdx].toString().trim()
          : null;

      transactions.add(RawTransaction(
        date: date,
        amount: amount,
        type: type,
        rawDescription: description,
        sourceBank: BankType.sbi,
        referenceNumber: (refStr != null && refStr.isNotEmpty) ? refStr : null,
      ));
    }

    return transactions;
  }

  /// Detect the field delimiter by finding the data header line.
  /// Looks for lines containing "Txn Date" to determine format.
  String _detectDelimiter(String content) {
    final lines = content.split('\n');
    for (final line in lines) {
      final lower = line.toLowerCase();
      if (!lower.contains('txn date')) continue;
      // Found a candidate header line — check its delimiter.
      if (line.contains('\t')) return '\t';
      if (line.contains('|') && !line.contains(',')) return '|';
      return ',';
    }
    return ',';
  }

  bool _isDataHeader(List<String> cells) {
    final joined = cells.join(' ');
    return joined.contains('txn date') &&
        joined.contains('description') &&
        (joined.contains('debit') ||
            joined.contains('withdrawal') ||
            joined.contains('amount'));
  }

  _SbiColumnMapping _detectFormat(List<String> header) {
    // Format C: has "amount" but NOT "debit"/"credit"/"withdrawal"
    final hasAmountCol = header.any((c) => c == 'amount');
    final hasDebitCol = header.any((c) => c.contains('debit') || c.contains('withdrawal'));

    if (hasAmountCol && !hasDebitCol) {
      return _SbiColumnMapping(
        dateIdx: header.indexWhere((c) => c.contains('txn date')),
        descIdx: header.indexWhere((c) => c.contains('description')),
        refIdx: header.indexWhere((c) => c.contains('ref')),
        debitIdx: -1,
        creditIdx: -1,
        amountIdx: header.indexWhere((c) => c == 'amount'),
        isAmountSuffix: true,
        minColumns: 5,
      );
    }

    // Format B: has "branch code"
    final hasBranchCode = header.any((c) => c.contains('branch code'));

    final debitIdx = header.indexWhere((c) => c.contains('debit') || c.contains('withdrawal'));
    final creditIdx = header.indexWhere((c) => c.contains('credit') || c.contains('deposit'));

    return _SbiColumnMapping(
      dateIdx: header.indexWhere((c) => c.contains('txn date')),
      descIdx: header.indexWhere((c) => c.contains('description')),
      refIdx: header.indexWhere((c) => c.contains('ref') || c.contains('cheque')),
      debitIdx: debitIdx,
      creditIdx: creditIdx,
      amountIdx: -1,
      isAmountSuffix: false,
      minColumns: hasBranchCode ? 7 : 6,
    );
  }

  // ─── Date parsing (locale-independent) ─────────────────

  /// Hardcoded month map — no dependency on device locale.
  static const _monthAbbr = {
    'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
    'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
  };

  static const _monthFull = {
    'january': 1, 'february': 2, 'march': 3, 'april': 4, 'may': 5,
    'june': 6, 'july': 7, 'august': 8, 'september': 9, 'october': 10,
    'november': 11, 'december': 12,
  };

  /// Parse date supporting multiple SBI formats. Each row parsed independently.
  /// Patterns tried in order:
  ///   1. dd MMM yyyy  ("15 Jan 2026")
  ///   2. dd-MMM-yy    ("15-Jan-26")
  ///   3. dd/MM/yyyy   ("15/01/2026") — fallback for newer exports
  ///
  /// 2-digit year assumption: year < 100 → year + 2000.
  /// This means "26" = 2026. Valid for statements from 2000–2099.
  DateTime? _parseDate(String s) {
    // Try pattern 1: dd MMM yyyy (space-separated)
    final spaceParts = s.split(' ');
    if (spaceParts.length >= 3) {
      final result = _parseDayMonthYear(
        spaceParts[0],
        spaceParts[1],
        spaceParts[spaceParts.length - 1],
      );
      if (result != null) return result;
    }

    // Try pattern 2: dd-MMM-yy (hyphen-separated)
    final hyphenParts = s.split('-');
    if (hyphenParts.length == 3) {
      final result = _parseDayMonthYear(
        hyphenParts[0],
        hyphenParts[1],
        hyphenParts[2],
      );
      if (result != null) return result;
    }

    // Try pattern 3: dd/MM/yyyy (numeric, slash-separated)
    final slashParts = s.split('/');
    if (slashParts.length == 3) {
      try {
        final day = int.parse(slashParts[0]);
        final month = int.parse(slashParts[1]);
        var year = int.parse(slashParts[2]);
        if (year < 100) year += 2000; // 2-digit year assumption
        if (year < 1900 || year > 2100) return null;
        return DateTime(year, month, day);
      } on FormatException {
        return null;
      }
    }

    return null;
  }

  /// Parse day (numeric string), month (text), year (numeric string).
  DateTime? _parseDayMonthYear(String dayStr, String monthStr, String yearStr) {
    try {
      final day = int.parse(dayStr);
      final monthLower = monthStr.toLowerCase();

      // Try 3-char abbreviation first.
      int? month = _monthAbbr[monthLower.length >= 3 ? monthLower.substring(0, 3) : monthLower];
      // Fall back to full month name.
      month ??= _monthFull[monthLower];

      if (month == null) return null;

      var year = int.parse(yearStr);
      // 2-digit year assumption: add 2000. Covers statements from 2000–2099.
      if (year < 100) year += 2000;
      if (year < 1900 || year > 2100) return null;

      return DateTime(year, month, day);
    } on FormatException {
      return null;
    }
  }

  // ─── Amount parsing ────────────────────────────────────

  /// Parse "450.00(Dr)" or "85000.00(Cr)" suffix format.
  static final _amountSuffixPattern =
      RegExp(r'^([\d,]+\.?\d*)\s*\((Dr|Cr)\)\s*$', caseSensitive: false);

  _ParsedAmount? _parseAmountSuffix(String s) {
    if (s.isEmpty) return null;
    final match = _amountSuffixPattern.firstMatch(s);
    if (match == null) return null;

    final numericStr = match.group(1)!.replaceAll(',', '');
    final suffix = match.group(2)!.toLowerCase();
    final amount = double.tryParse(numericStr);
    if (amount == null || amount == 0) return null;

    return _ParsedAmount(
      amount: amount,
      type: suffix == 'dr' ? 'debit' : 'credit',
    );
  }

  /// Parse standard amount string like "5000.00" or "1,23,456.78".
  double? _parseAmount(String s) {
    if (s.isEmpty) return null;
    final cleaned = s.replaceAll(',', '').trim();
    if (cleaned.isEmpty) return null;
    return double.tryParse(cleaned);
  }
}

class _SbiColumnMapping {
  final int dateIdx;
  final int descIdx;
  final int refIdx;
  final int debitIdx;
  final int creditIdx;
  final int amountIdx;
  final bool isAmountSuffix;
  final int minColumns;

  const _SbiColumnMapping({
    required this.dateIdx,
    required this.descIdx,
    required this.refIdx,
    required this.debitIdx,
    required this.creditIdx,
    required this.amountIdx,
    required this.isAmountSuffix,
    required this.minColumns,
  });
}

class _ParsedAmount {
  final double amount;
  final String type;

  const _ParsedAmount({required this.amount, required this.type});
}
