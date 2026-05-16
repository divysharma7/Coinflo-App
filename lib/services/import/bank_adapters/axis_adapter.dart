import 'package:csv/csv.dart';
import 'package:finance_buddy_app/core/enums.dart';
import 'package:finance_buddy_app/services/import/bank_adapters/bank_adapter.dart';
import 'package:finance_buddy_app/services/import/models/raw_transaction.dart';

/// Parses Axis Bank CSV statements.
///
/// Canonical header format:
///   Tran Date,CHQNO,PARTICULARS,DR,CR,BAL,SOL
///
/// Also supports variant headers from different export paths (Mobile Banking,
/// Net Banking, corporate exports) via tolerant column-name alias matching.
///
/// Date format: dd-MM-yyyy (numeric, hyphen-separated, 4-digit year)
///
/// Detection: header contains (PARTICULARS|Description|Narration) AND
/// (SOL|Sol ID|Branch Code). The SOL column is unique to Axis.
class AxisAdapter extends BankAdapter {
  @override
  BankType get bankType => BankType.axis;

  // ─── Column name aliases ───────────────────────────────

  static const _dateAliases = ['tran date', 'tran. date', 'transaction date'];
  static const _refAliases = ['chqno', 'cheque no', 'cheque number', 'chq no', 'ref no'];
  static const _descAliases = ['particulars', 'description', 'narration'];
  static const _debitAliases = ['dr', 'debit', 'withdrawal amt', 'withdrawal amount'];
  static const _creditAliases = ['cr', 'credit', 'deposit amt', 'deposit amount'];
  static const _solAliases = ['sol', 'sol id', 'branch code'];

  @override
  bool canParse(String headerLine) {
    final lower = headerLine.toLowerCase();
    final hasDesc = _descAliases.any((a) => lower.contains(a));
    final hasSol = _solAliases.any((a) => lower.contains(a));
    return hasDesc && hasSol;
  }

  @override
  List<RawTransaction> parse(String csvContent) {
    final rows = const CsvToListConverter(eol: '\n', shouldParseNumbers: false)
        .convert(csvContent);

    if (rows.isEmpty) return [];

    // Scan up to 30 lines for the data header.
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

    // Resolve column indices via alias matching.
    final dateIdx = _findColumn(header, _dateAliases);
    final descIdx = _findColumn(header, _descAliases);
    final debitIdx = _findColumn(header, _debitAliases);
    final creditIdx = _findColumn(header, _creditAliases);
    final refIdx = _findColumn(header, _refAliases);

    if (dateIdx == -1 || descIdx == -1 || debitIdx == -1 || creditIdx == -1) {
      return [];
    }

    final transactions = <RawTransaction>[];

    for (var i = headerIdx + 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.length <= descIdx) continue;

      final dateStr = row[dateIdx].toString().trim();
      if (dateStr.isEmpty) continue;

      final date = _parseDate(dateStr);
      if (date == null) continue; // Skip non-date rows (summaries/footers).

      final description = row[descIdx].toString().trim();
      if (description.isEmpty) continue;

      final drStr = row.length > debitIdx ? row[debitIdx].toString().trim() : '';
      final crStr = row.length > creditIdx ? row[creditIdx].toString().trim() : '';
      final drAmount = _parseAmount(drStr);
      final crAmount = _parseAmount(crStr);

      // Skip rows where both are 0 or empty.
      if ((drAmount == null || drAmount == 0) &&
          (crAmount == null || crAmount == 0)) {
        continue;
      }

      final isDebit = drAmount != null && drAmount > 0;
      final amount = isDebit ? drAmount : crAmount;
      if (amount == null || amount == 0) continue;

      final refStr = refIdx >= 0 && row.length > refIdx
          ? row[refIdx].toString().trim()
          : null;

      transactions.add(RawTransaction(
        date: date,
        amount: amount,
        type: isDebit ? 'debit' : 'credit',
        rawDescription: description,
        sourceBank: BankType.axis,
        referenceNumber: (refStr != null && refStr.isNotEmpty) ? refStr : null,
      ));
    }

    return transactions;
  }

  bool _isDataHeader(List<String> cells) {
    final joined = cells.join(' ');
    final hasDesc = _descAliases.any((a) => joined.contains(a));
    final hasSol = _solAliases.any((a) => joined.contains(a));
    return hasDesc && hasSol;
  }

  /// Find the first column index matching any of the given aliases.
  /// Uses exact match to avoid substring false positives
  /// (e.g. "description" containing "cr").
  int _findColumn(List<String> header, List<String> aliases) {
    for (final alias in aliases) {
      final idx = header.indexWhere((c) => c == alias);
      if (idx != -1) return idx;
    }
    return -1;
  }

  /// Parse dd-MM-yyyy. Fallback: dd/MM/yyyy.
  DateTime? _parseDate(String s) {
    final hyphenParts = s.split('-');
    if (hyphenParts.length == 3) {
      return _parseDMY(hyphenParts[0], hyphenParts[1], hyphenParts[2]);
    }

    final slashParts = s.split('/');
    if (slashParts.length == 3) {
      return _parseDMY(slashParts[0], slashParts[1], slashParts[2]);
    }

    return null;
  }

  DateTime? _parseDMY(String dayStr, String monthStr, String yearStr) {
    try {
      final day = int.parse(dayStr);
      final month = int.parse(monthStr);
      var year = int.parse(yearStr);
      if (year < 100) year += 2000;
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
