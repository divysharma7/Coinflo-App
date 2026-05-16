import 'package:csv/csv.dart';
import 'package:finance_buddy_app/core/enums.dart';
import 'package:finance_buddy_app/services/import/bank_adapters/bank_adapter.dart';
import 'package:finance_buddy_app/services/import/models/raw_transaction.dart';

/// Parses HDFC Bank CSV statements.
///
/// Expected CSV format:
///   Date,Narration,Value Dat,Debit Amount,Credit Amount,Chq/Ref Number,Closing Balance
///   03/05/26,POS HDFC SWGGY*ORD MUM 5678****1234,03/05/26,450.00,,034567,12345.67
class HdfcAdapter extends BankAdapter {
  @override
  BankType get bankType => BankType.hdfc;

  @override
  bool canParse(String headerLine) {
    final lower = headerLine.toLowerCase();
    return lower.contains('narration') && lower.contains('closing balance');
  }

  @override
  List<RawTransaction> parse(String csvContent) {
    final rows = const CsvToListConverter(eol: '\n', shouldParseNumbers: false)
        .convert(csvContent);

    if (rows.isEmpty) return [];

    // Find header row (skip any preamble lines).
    int headerIdx = -1;
    for (var i = 0; i < rows.length; i++) {
      final line = rows[i].map((e) => e.toString().toLowerCase()).toList();
      if (line.any((c) => c.contains('narration')) &&
          line.any((c) => c.contains('closing balance'))) {
        headerIdx = i;
        break;
      }
    }
    if (headerIdx == -1) return [];

    final header = rows[headerIdx].map((e) => e.toString().toLowerCase().trim()).toList();
    final dateIdx = header.indexWhere((c) => c.contains('date') && !c.contains('value'));
    final narrationIdx = header.indexWhere((c) => c.contains('narration'));
    final debitIdx = header.indexWhere((c) => c.contains('debit'));
    final creditIdx = header.indexWhere((c) => c.contains('credit') && !c.contains('closing'));
    final refIdx = header.indexWhere((c) => c.contains('chq') || c.contains('ref'));

    if (dateIdx == -1 || narrationIdx == -1 || debitIdx == -1 || creditIdx == -1) {
      return [];
    }

    final transactions = <RawTransaction>[];

    for (var i = headerIdx + 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.length <= narrationIdx) continue;

      final dateStr = row[dateIdx].toString().trim();
      final narration = row[narrationIdx].toString().trim();
      final debitStr = row[debitIdx].toString().trim();
      final creditStr = row[creditIdx].toString().trim();
      final refStr = refIdx >= 0 && row.length > refIdx
          ? row[refIdx].toString().trim()
          : null;

      if (dateStr.isEmpty || narration.isEmpty) continue;

      final date = _parseDate(dateStr);
      if (date == null) continue;

      final debitAmount = _parseAmount(debitStr);
      final creditAmount = _parseAmount(creditStr);

      // Skip rows with no amount.
      if (debitAmount == null && creditAmount == null) continue;

      final isDebit = debitAmount != null && debitAmount > 0;
      final amount = isDebit ? debitAmount : creditAmount!;

      transactions.add(RawTransaction(
        date: date,
        amount: amount,
        type: isDebit ? 'debit' : 'credit',
        rawDescription: narration,
        sourceBank: BankType.hdfc,
        referenceNumber: (refStr != null && refStr.isNotEmpty) ? refStr : null,
      ));
    }

    return transactions;
  }

  /// Parse dd/MM/yy or dd/MM/yyyy date format.
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

  /// Parse an amount string like "450.00" or "1,23,456.78".
  double? _parseAmount(String s) {
    if (s.isEmpty) return null;
    final cleaned = s.replaceAll(',', '').trim();
    if (cleaned.isEmpty) return null;
    return double.tryParse(cleaned);
  }
}
