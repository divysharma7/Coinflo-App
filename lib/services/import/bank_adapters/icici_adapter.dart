import 'package:csv/csv.dart';
import 'package:finance_buddy_app/core/enums.dart';
import 'package:finance_buddy_app/services/import/bank_adapters/bank_adapter.dart';
import 'package:finance_buddy_app/services/import/models/raw_transaction.dart';

/// Parses ICICI Bank CSV statements.
///
/// Supports two export formats:
///
/// Format A (iMobile / newer Net Banking):
///   Transaction Date,Value Date,Description,Ref No./Cheque No.,Debit,Credit,Balance
///
/// Format B (legacy Net Banking):
///   S No.,Value Date,Transaction Date,Cheque Number,Transaction Remarks,Withdrawal Amount (INR ),Deposit Amount (INR ),Balance (INR )
class IciciAdapter extends BankAdapter {
  @override
  BankType get bankType => BankType.icici;

  @override
  bool canParse(String headerLine) {
    final lower = headerLine.toLowerCase();
    final hasTransactionDate = lower.contains('transaction date');
    final hasDescription =
        lower.contains('description') || lower.contains('transaction remarks');
    final hasAmountCol =
        lower.contains('debit') || lower.contains('withdrawal amount');
    return hasTransactionDate && hasDescription && hasAmountCol;
  }

  @override
  List<RawTransaction> parse(String csvContent) {
    final rows = const CsvToListConverter(eol: '\n', shouldParseNumbers: false)
        .convert(csvContent);

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

    // Detect which format we're dealing with.
    final format = _detectFormat(header);

    final transactions = <RawTransaction>[];

    for (var i = headerIdx + 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.length < format.minColumns) continue;

      final dateStr = row[format.dateIdx].toString().trim();
      if (dateStr.isEmpty) continue;

      final date = _parseDate(dateStr);
      if (date == null) continue; // Skip non-date rows (trailing summaries).

      final description = row[format.descIdx].toString().trim();
      if (description.isEmpty) continue;

      final debitStr = row[format.debitIdx].toString().trim();
      final creditStr = row[format.creditIdx].toString().trim();
      final debitAmount = _parseAmount(debitStr);
      final creditAmount = _parseAmount(creditStr);

      if (debitAmount == null && creditAmount == null) continue;

      final isDebit = debitAmount != null && debitAmount > 0;
      final amount = isDebit ? debitAmount : creditAmount!;

      final refStr = format.refIdx >= 0 && row.length > format.refIdx
          ? row[format.refIdx].toString().trim()
          : null;

      transactions.add(RawTransaction(
        date: date,
        amount: amount,
        type: isDebit ? 'debit' : 'credit',
        rawDescription: description,
        sourceBank: BankType.icici,
        referenceNumber: (refStr != null && refStr.isNotEmpty) ? refStr : null,
      ));
    }

    return transactions;
  }

  /// Check if a row looks like the full data header (both formats).
  bool _isDataHeader(List<String> cells) {
    final joined = cells.join(' ');
    final hasTransactionDate = joined.contains('transaction date');
    final hasDescription =
        joined.contains('description') || joined.contains('transaction remarks');
    final hasAmountCol =
        joined.contains('debit') || joined.contains('withdrawal amount');
    return hasTransactionDate && hasDescription && hasAmountCol;
  }

  /// Detect Format A vs Format B and return column indices.
  _ColumnMapping _detectFormat(List<String> header) {
    // Format B detection: has "transaction remarks" or "withdrawal amount"
    final isLegacy = header.any((c) => c.contains('transaction remarks')) ||
        header.any((c) => c.contains('withdrawal amount'));

    if (isLegacy) {
      return _ColumnMapping(
        dateIdx: header.indexWhere((c) => c.contains('transaction date')),
        descIdx: header.indexWhere((c) => c.contains('transaction remarks')),
        debitIdx: header.indexWhere((c) => c.contains('withdrawal amount')),
        creditIdx: header.indexWhere((c) => c.contains('deposit amount')),
        refIdx: header.indexWhere((c) => c.contains('cheque number')),
        minColumns: 6,
      );
    }

    // Format A
    return _ColumnMapping(
      dateIdx: header.indexWhere((c) => c == 'transaction date' || c.startsWith('transaction date')),
      descIdx: header.indexWhere((c) => c == 'description' || c.startsWith('description')),
      debitIdx: header.indexWhere((c) => c == 'debit' || c.startsWith('debit')),
      creditIdx: header.indexWhere((c) => c == 'credit' && !c.contains('balance')),
      refIdx: header.indexWhere((c) => c.contains('ref no') || c.contains('cheque')),
      minColumns: 5,
    );
  }

  /// Parse dd/MM/yyyy date format (4-digit year).
  DateTime? _parseDate(String s) {
    final parts = s.split('/');
    if (parts.length != 3) return null;
    try {
      final day = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final year = int.parse(parts[2]);
      if (year < 1900 || year > 2100) return null;
      return DateTime(year, month, day);
    } on FormatException {
      return null;
    }
  }

  /// Parse amount string like "5000.00" or "1,23,456.78".
  double? _parseAmount(String s) {
    if (s.isEmpty) return null;
    final cleaned = s.replaceAll(',', '').trim();
    if (cleaned.isEmpty) return null;
    return double.tryParse(cleaned);
  }
}

/// Column index mapping for the two ICICI formats.
class _ColumnMapping {
  final int dateIdx;
  final int descIdx;
  final int debitIdx;
  final int creditIdx;
  final int refIdx;
  final int minColumns;

  const _ColumnMapping({
    required this.dateIdx,
    required this.descIdx,
    required this.debitIdx,
    required this.creditIdx,
    required this.refIdx,
    required this.minColumns,
  });
}
