import 'package:csv/csv.dart';
import 'package:finance_buddy_app/core/enums.dart';
import 'package:finance_buddy_app/services/import/bank_adapters/bank_adapter.dart';
import 'package:finance_buddy_app/services/import/models/raw_transaction.dart';

/// Parses Kotak Mahindra Bank CSV statements.
///
/// Supports ONLY Format A (Net Banking download):
///   Sl. No.,Transaction Date,Value Date,Description,Chq / Ref No.,Amount,Dr / Cr,Balance
///
/// Detection: header contains "Sl. No." AND ("Dr / Cr" OR "Dr/Cr" OR "Dr Cr")
///
/// Date format: dd/MM/yyyy (slash-separated, 4-digit year)
///
// TODO(v2): Generic CSV adapter for Date,Description,Debit,Credit,Balance pattern.
// This is currently too generic to auto-detect as any specific bank. Should become
// a GenericCsvAdapter activated only via manual bank selection.
class KotakAdapter extends BankAdapter {
  @override
  BankType get bankType => BankType.kotak;

  @override
  bool canParse(String headerLine) {
    final lower = headerLine.toLowerCase();
    final hasSlNo = lower.contains('sl. no') || lower.contains('sl no');
    final hasDrCr = lower.contains('dr / cr') ||
        lower.contains('dr/cr') ||
        lower.contains('dr cr');
    return hasSlNo && hasDrCr;
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

    // Resolve column indices.
    final dateIdx = _findIdx(header, ['transaction date']);
    final descIdx = _findIdx(header, ['description', 'narration']);
    final refIdx = _findIdx(header, ['chq / ref no', 'chq/ref no', 'chq / ref no.', 'ref no']);
    final amountIdx = _findIdx(header, ['amount']);
    final drCrIdx = _findIdx(header, ['dr / cr', 'dr/cr', 'dr cr']);

    if (dateIdx == -1 || descIdx == -1 || amountIdx == -1 || drCrIdx == -1) {
      return [];
    }

    final transactions = <RawTransaction>[];

    for (var i = headerIdx + 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.length <= drCrIdx) continue;

      final dateStr = row[dateIdx].toString().trim();
      if (dateStr.isEmpty) continue;

      final date = _parseDate(dateStr);
      if (date == null) continue; // Skip non-date rows (footers/summaries).

      final description = row[descIdx].toString().trim();
      if (description.isEmpty) continue;

      final amountStr = row[amountIdx].toString().trim();
      final amount = _parseAmount(amountStr);
      if (amount == null || amount == 0) continue; // Skip zero-amount rows.

      final drCrCell = row[drCrIdx].toString().trim();
      final type = _parseDrCr(drCrCell);

      final refStr = refIdx >= 0 && row.length > refIdx
          ? row[refIdx].toString().trim()
          : null;

      transactions.add(RawTransaction(
        date: date,
        amount: amount,
        type: type,
        rawDescription: description,
        sourceBank: BankType.kotak,
        referenceNumber: (refStr != null && refStr.isNotEmpty) ? refStr : null,
      ));
    }

    return transactions;
  }

  bool _isDataHeader(List<String> cells) {
    final joined = cells.join(' ');
    final hasSlNo = joined.contains('sl. no') || joined.contains('sl no');
    final hasDrCr = joined.contains('dr / cr') ||
        joined.contains('dr/cr') ||
        joined.contains('dr cr');
    return hasSlNo && hasDrCr;
  }

  int _findIdx(List<String> header, List<String> aliases) {
    for (final alias in aliases) {
      final idx = header.indexWhere((c) => c == alias);
      if (idx != -1) return idx;
    }
    return -1;
  }

  /// Parse the Dr/Cr indicator column.
  /// Throws FormatException for unexpected values — never silently skips.
  String _parseDrCr(String cell) {
    final indicator = cell.trim().toLowerCase();
    if (indicator == 'dr') return 'debit';
    if (indicator == 'cr') return 'credit';
    throw FormatException('Unexpected Dr/Cr value: "$cell"');
  }

  /// Parse dd/MM/yyyy date format.
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
