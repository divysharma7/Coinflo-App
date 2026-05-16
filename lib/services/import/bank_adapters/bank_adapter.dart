import 'package:finance_buddy_app/core/enums.dart';
import 'package:finance_buddy_app/services/import/models/raw_transaction.dart';

/// Abstract interface for bank-specific CSV parsers.
/// Each adapter knows how to detect and parse one bank's statement format.
abstract class BankAdapter {
  /// The bank this adapter handles.
  BankType get bankType;

  /// Returns true if this adapter can parse the given CSV header line.
  bool canParse(String headerLine);

  /// Parse CSV content into raw transactions.
  /// [csvContent] is the full file content as a string.
  List<RawTransaction> parse(String csvContent);
}
