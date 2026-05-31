/// Validates that a transaction amount is reasonable.
///
/// Thresholds: min 1, max = user's historical max x 1.5, hard cap 500,000.
class AmountSanityChecker {
  const AmountSanityChecker();

  static const double _hardCap = 500000.0;
  static const double _minAmount = 1.0;
  static const double _defaultHistoricalMax = 50000.0;

  /// Check if [amount] is sane given the user's historical max.
  ///
  /// Returns `true` if the amount passes all checks.
  bool isSane(double amount, {double? userHistoricalMax}) {
    if (amount < _minAmount) return false;
    if (amount > _hardCap) return false;
    final effectiveMax = userHistoricalMax ?? _defaultHistoricalMax;
    if (amount > effectiveMax * 1.5) return false;
    return true;
  }

  /// Generate chip options for an insane amount.
  ///
  /// Returns suggested alternatives: rounded values + original + manual entry.
  List<String> chipSuggestions(double amount) {
    final suggestions = <String>[];

    // Round to nearest 100
    final round100 = (amount / 100).round() * 100;
    if (round100 != amount.round()) {
      suggestions.add(round100.toString());
    }

    // Round to nearest 10
    final round10 = (amount / 10).round() * 10;
    if (round10 != amount.round() && round10 != round100) {
      suggestions.add(round10.toString());
    }

    // Original value
    suggestions.add(amount.toStringAsFixed(amount == amount.roundToDouble() ? 0 : 2));

    suggestions.add('Enter manually');

    return suggestions;
  }
}
