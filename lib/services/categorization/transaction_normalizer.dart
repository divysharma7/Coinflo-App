import 'package:finance_buddy_app/services/categorization/models/normalized_transaction.dart';
import 'package:finance_buddy_app/services/categorization/models/raw_transaction.dart';

/// Cleans raw descriptions, extracts merchant tokens, and detects channels.
/// Fully stateless — safe to use in an isolate.
class TransactionNormalizer {
  TransactionNormalizer();

  // Pre-compiled noise-removal patterns (order matters).
  static final _maskedCard = RegExp(r'\b\d{4}\s?\*+\s?\d{4}\b');
  static final _refIds =
      RegExp(r'\b(?:ref|txn|utr|rrn)\s*[:.#]?\s*[a-z0-9]+\b', caseSensitive: false);
  static final _datesInDesc = RegExp(r'\d{2}[-/]\d{2}[-/]\d{2,4}');
  static final _excessWhitespace = RegExp(r'\s+');

  // Channel detection keywords (checked in priority order).
  static final _channelPatterns = <TransactionChannel, RegExp>{
    TransactionChannel.upi: RegExp(r'\bupi\b|\bvpa\b', caseSensitive: false),
    TransactionChannel.pos: RegExp(r'\bpos\b', caseSensitive: false),
    TransactionChannel.neft: RegExp(r'\bneft\b', caseSensitive: false),
    TransactionChannel.imps: RegExp(r'\bimps\b', caseSensitive: false),
    TransactionChannel.atm: RegExp(r'\batm\b', caseSensitive: false),
  };

  // Prefixes to strip when extracting merchant token.
  static final _tokenPrefixes =
      RegExp(r'^(pos|neft|imps|upi|vpa|txn|mps|bis)\s*', caseSensitive: false);

  // Extract the longest alphabetic word as the merchant token.
  static final _alphaWord = RegExp(r'[a-z]+');

  // Bank-related words to exclude from merchant token extraction.
  static final _bankWords = {
    'hdfc', 'icici', 'sbi', 'axis', 'kotak', 'bank', 'hdfcbank',
    'axisbank', 'icicibank', 'sbibank', 'kotakbank', 'okhdfcbank',
    'okicici', 'oksbi', 'ybl', 'paytm', 'gpay', 'phonepe',
    'mum', 'del', 'blr', 'che', 'hyd', 'pun', // city codes
    'india', 'ltd', 'pvt', 'inr', 'the',
  };

  /// Normalize a single raw transaction.
  NormalizedTransaction normalize(RawTransaction raw) {
    final cleaned = _cleanDescription(raw.rawDescription);
    final channel = _detectChannel(raw.rawDescription);
    final token = _extractMerchantToken(cleaned);

    return NormalizedTransaction.fromRaw(
      raw: raw,
      cleanedDescription: cleaned,
      merchantToken: token,
      channel: channel,
      rawHash: '', // Hash computation removed — was only needed for import dedup.
    );
  }

  /// Step 1-2: Lowercase + strip noise via regex.
  String _cleanDescription(String raw) {
    var s = raw.toLowerCase();
    s = s.replaceAll(_maskedCard, '');
    s = s.replaceAll(_refIds, '');
    s = s.replaceAll(_datesInDesc, '');
    s = s.replaceAll(_excessWhitespace, ' ').trim();
    return s;
  }

  /// Step 3: Detect the transaction channel.
  TransactionChannel _detectChannel(String raw) {
    final lower = raw.toLowerCase();
    for (final entry in _channelPatterns.entries) {
      if (entry.value.hasMatch(lower)) return entry.key;
    }
    return TransactionChannel.other;
  }

  /// Step 4: Extract a normalized merchant token.
  String _extractMerchantToken(String cleaned) {
    // Remove common channel prefixes.
    final s = cleaned.replaceFirst(_tokenPrefixes, '');

    // Find the longest alphabetic sequence that isn't a known bank/city word.
    final matches = _alphaWord.allMatches(s).toList();
    if (matches.isEmpty) return '';

    var longest = '';
    for (final m in matches) {
      final word = m.group(0)!;
      if (word.length < 3) continue; // Skip very short words.
      if (_bankWords.contains(word)) continue; // Skip bank/city names.
      if (word.length > longest.length) longest = word;
    }

    // If all words were filtered out, fall back to first 3+ char word.
    if (longest.isEmpty) {
      for (final m in matches) {
        final word = m.group(0)!;
        if (word.length >= 3) {
          longest = word;
          break;
        }
      }
    }

    // Max 30 chars, already lowercase + alpha only.
    if (longest.length > 30) longest = longest.substring(0, 30);
    return longest;
  }
}
