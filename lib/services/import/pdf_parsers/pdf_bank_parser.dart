import 'package:finance_buddy_app/core/enums.dart';
import 'package:finance_buddy_app/services/import/models/raw_transaction.dart';

/// Abstract interface for bank-specific PDF text parsers.
/// Each parser converts extracted PDF text into RawTransactions.
///
/// Separation from BankAdapter (CSV) is intentional:
/// - CSV detection uses header lines; PDF detection uses full text content
/// - PDF layouts are fundamentally different from CSV column structures
/// - Keeps existing CSV adapters untouched and stable
abstract class PdfBankParser {
  /// The bank this parser handles.
  BankType get bankType;

  /// Returns true if this parser can handle the extracted text.
  /// Detection is based on bank name, statement headers, account format, etc.
  bool canParse(String extractedText);

  /// Parse extracted PDF text into raw transactions.
  /// [extractedText] is the full text from all pages concatenated.
  List<RawTransaction> parse(String extractedText);
}
