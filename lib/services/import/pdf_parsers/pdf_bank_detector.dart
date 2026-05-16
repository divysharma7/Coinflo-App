import 'package:finance_buddy_app/core/enums.dart';
import 'package:finance_buddy_app/services/import/pdf_parsers/pdf_bank_parser.dart';
import 'package:finance_buddy_app/services/import/pdf_parsers/hdfc_pdf_parser.dart';
import 'package:finance_buddy_app/services/import/pdf_parsers/icici_pdf_parser.dart';
import 'package:finance_buddy_app/services/import/pdf_parsers/sbi_pdf_parser.dart';
import 'package:finance_buddy_app/services/import/pdf_parsers/axis_pdf_parser.dart';
import 'package:finance_buddy_app/services/import/pdf_parsers/kotak_pdf_parser.dart';

/// Auto-detects which bank a PDF statement belongs to by analyzing extracted text.
class PdfBankDetector {
  final List<PdfBankParser> _parsers = [
    HdfcPdfParser(),
    IciciPdfParser(),
    SbiPdfParser(),
    AxisPdfParser(),
    KotakPdfParser(),
  ];

  /// Detect bank from extracted PDF text.
  /// Returns the matching parser, or null if no bank detected.
  PdfBankParser? detect(String extractedText) {
    for (final parser in _parsers) {
      if (parser.canParse(extractedText)) return parser;
    }
    return null;
  }

  /// Detect bank type from extracted text.
  BankType detectBankType(String extractedText) {
    return detect(extractedText)?.bankType ?? BankType.unknown;
  }
}
