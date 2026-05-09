import 'package:finance_buddy_app/models/parsed_sms.dart';

class SmsParser {
  static final _debitRegex = RegExp(
    r'debited by Rs\.?\s*(\d+[\d,]*\.?\d*)',
    caseSensitive: false,
  );
  static final _creditRegex = RegExp(
    r'credited by Rs\.?\s*(\d+[\d,]*\.?\d*)',
    caseSensitive: false,
  );
  static final _debitAltRegex = RegExp(
    r'Rs\.?\s*(\d+[\d,]*\.?\d*)\s*(?:has been|is)\s*debited',
    caseSensitive: false,
  );
  static final _creditAltRegex = RegExp(
    r'Rs\.?\s*(\d+[\d,]*\.?\d*)\s*(?:has been|is)\s*credited',
    caseSensitive: false,
  );
  static final _merchantRegex = RegExp(
    r'(?:at|to|for|trf to)\s+([A-Z][A-Za-z0-9\s&.-]+)',
    caseSensitive: false,
  );

  /// Returns null if the SMS is not a recognized bank transaction.
  static ParsedSms? parse(String body) {
    double? amount;
    bool? isDebit;

    // Try debit patterns
    var match = _debitRegex.firstMatch(body) ?? _debitAltRegex.firstMatch(body);
    if (match != null) {
      amount = _parseAmount(match.group(1)!);
      isDebit = true;
    }

    // Try credit patterns
    if (amount == null) {
      match = _creditRegex.firstMatch(body) ?? _creditAltRegex.firstMatch(body);
      if (match != null) {
        amount = _parseAmount(match.group(1)!);
        isDebit = false;
      }
    }

    if (amount == null || isDebit == null) return null;

    // Extract merchant
    String? merchant;
    final merchantMatch = _merchantRegex.firstMatch(body);
    if (merchantMatch != null) {
      merchant = merchantMatch.group(1)?.trim();
      // Clean up trailing common words
      merchant = merchant
          ?.replaceAll(RegExp(r'\s*(on|dated|ref|Ref).*$', caseSensitive: false), '')
          .trim();
      if (merchant != null && merchant.isEmpty) merchant = null;
    }

    return ParsedSms(
      amount: amount,
      isDebit: isDebit,
      merchant: merchant,
      rawText: body,
      receivedAt: DateTime.now(),
    );
  }

  static double? _parseAmount(String raw) {
    return double.tryParse(raw.replaceAll(',', ''));
  }
}
