import 'package:finance_buddy_app/core/enums.dart';
import 'package:finance_buddy_app/services/import/bank_adapters/bank_adapter.dart';
import 'package:finance_buddy_app/services/import/bank_adapters/hdfc_adapter.dart';
import 'package:finance_buddy_app/services/import/bank_adapters/icici_adapter.dart';
import 'package:finance_buddy_app/services/import/bank_adapters/sbi_adapter.dart';
import 'package:finance_buddy_app/services/import/bank_adapters/axis_adapter.dart';
import 'package:finance_buddy_app/services/import/bank_adapters/kotak_adapter.dart';

/// Auto-detects which bank a CSV file came from by inspecting
/// the header line and/or filename.
class BankDetector {
  final List<BankAdapter> _adapters = [
    HdfcAdapter(),
    IciciAdapter(),
    SbiAdapter(),
    AxisAdapter(),
    KotakAdapter(),
  ];

  /// Detect bank from CSV content. Checks the first non-empty line as header.
  /// Falls back to filename-based detection if header matching fails.
  BankAdapter detect({required String csvContent, String? fileName}) {
    final headerLine = _extractHeaderLine(csvContent);

    // Try header-based detection first.
    for (final adapter in _adapters) {
      if (adapter.canParse(headerLine)) return adapter;
    }

    // Fallback: filename-based detection.
    if (fileName != null) {
      final lower = fileName.toLowerCase();
      if (lower.contains('hdfc')) return _adapters[0];
      if (lower.contains('icici')) return _adapters[1];
      if (lower.contains('sbi')) return _adapters[2];
      if (lower.contains('axis')) return _adapters[3];
      if (lower.contains('kotak')) return _adapters[4];
    }

    // Default to HDFC adapter as a reasonable guess for unknown formats.
    return _adapters[0];
  }

  /// Detect and return the BankType.
  BankType detectBankType({required String csvContent, String? fileName}) {
    return detect(csvContent: csvContent, fileName: fileName).bankType;
  }

  String _extractHeaderLine(String csvContent) {
    final lines = csvContent.split('\n');
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isNotEmpty) return trimmed;
    }
    return '';
  }
}
