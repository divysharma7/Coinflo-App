import 'package:finance_buddy_app/services/import/models/categorization_result.dart';
import 'package:finance_buddy_app/core/enums.dart';
import 'package:finance_buddy_app/services/categorization/merchant_dictionary.dart';

/// Parses UPI VPA patterns from transaction descriptions to determine category.
/// Stage 3 of the categorization cascade.
class UpiParser {
  final MerchantDictionary _dictionary;

  UpiParser(this._dictionary);

  // VPA pattern: user@handle (excludes hyphens from username to avoid
  // capturing UPI- prefix as part of the VPA).
  static final _vpaPattern = RegExp(r'([a-zA-Z0-9._]+)@([a-zA-Z0-9]+)');

  // Pure numeric recipient (10-digit mobile number).
  static final _mobileNumber = RegExp(r'^\d{10}$');

  // P2P wallet handles (no merchant, just payment app).
  static final _p2pHandles = {'paytm', 'gpay', 'phonepe', 'ybl', 'okhdfcbank', 'okicici', 'oksbi'};

  /// Attempt to categorize a UPI transaction from its description.
  /// Returns null if no UPI pattern detected or no category determined.
  CategorizationResult? parse(String description) {
    final match = _vpaPattern.firstMatch(description);
    if (match == null) return null;

    final recipient = match.group(1)!.toLowerCase();
    final handle = match.group(2)!.toLowerCase();

    // Rule 1: Recipient is a 10-digit mobile number → P2P transfer.
    if (_mobileNumber.hasMatch(recipient)) {
      return const CategorizationResult(
        category: 'other', // P2P transfer → other
        source: CategorizationSource.upi,
        confidence: 0.9,
      );
    }

    // Rule 2: Handle is a P2P wallet with no merchant-identifying prefix.
    if (_p2pHandles.contains(handle) && _looksLikePersonalVpa(recipient)) {
      return const CategorizationResult(
        category: 'other', // P2P transfer → other
        source: CategorizationSource.upi,
        confidence: 0.85,
      );
    }

    // Rule 3: Check if VPA prefix matches a known merchant in dictionary.
    final merchantLookup = _dictionary.lookup(recipient);
    if (merchantLookup != null) {
      return CategorizationResult(
        category: merchantLookup.category,
        source: CategorizationSource.upi,
        confidence: 0.85,
      );
    }

    // Also try the handle as a merchant identifier.
    final handleLookup = _dictionary.lookup(handle);
    if (handleLookup != null) {
      return CategorizationResult(
        category: handleLookup.category,
        source: CategorizationSource.upi,
        confidence: 0.8,
      );
    }

    return null;
  }

  /// Heuristic: personal VPAs tend to be names/numbers, not merchant identifiers.
  bool _looksLikePersonalVpa(String recipient) {
    // If it contains digits (like a phone number suffix) or is short, likely personal.
    if (RegExp(r'\d{2,}').hasMatch(recipient)) return true;
    // Very short recipients without known merchant patterns.
    if (recipient.length <= 6) return true;
    return false;
  }
}
