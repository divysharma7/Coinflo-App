import 'dart:io';
import 'dart:typed_data';

import 'package:syncfusion_flutter_pdf/pdf.dart' as syncfusion;

/// On-device PDF text extraction service.
/// No OCR, no cloud calls — only text-based PDFs are supported.
///
/// NOTE: Uses Syncfusion community license. For commercial use at scale
/// (>$1M revenue), a paid Syncfusion license is required.
class PdfExtractorService {
  /// Minimum characters per page to consider the PDF text-based (not scanned).
  static const int _minCharsPerPage = 100;

  /// Extract all text from a PDF file.
  /// Throws [ScannedPdfException] if the PDF appears to be a scan.
  /// Throws [FormatException] if the PDF is empty or unreadable.
  static Future<String> extract(File file) async {
    final bytes = await file.readAsBytes();
    return extractFromBytes(bytes);
  }

  /// Extract text from raw PDF bytes. Useful for testing.
  static String extractFromBytes(Uint8List bytes) {
    final document = syncfusion.PdfDocument(inputBytes: bytes);

    try {
      final pageCount = document.pages.count;
      if (pageCount == 0) {
        throw const FormatException('PDF has no pages');
      }

      final extractor = syncfusion.PdfTextExtractor(document);
      final fullText = extractor.extractText();

      // Scanned PDF detection: if total text is too sparse relative to page count,
      // the PDF is likely a scan/image with no selectable text.
      if (fullText.trim().length < pageCount * _minCharsPerPage) {
        throw const ScannedPdfException(
          'This PDF appears to be a scan. Download the CSV version from your bank instead.',
        );
      }

      return fullText;
    } finally {
      document.dispose();
    }
  }
}

/// Thrown when a PDF appears to be a scanned image rather than text-based.
class ScannedPdfException implements Exception {
  final String message;
  const ScannedPdfException(this.message);

  @override
  String toString() => message;
}
