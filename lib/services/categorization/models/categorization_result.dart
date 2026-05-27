import 'package:finance_buddy_app/core/enums.dart';

/// Result of the categorization cascade.
class CategorizationResult {
  /// The matched category (TransactionCategory enum name), or null if uncategorized.
  final String? category;

  /// Which stage produced this result.
  final CategorizationSource source;

  /// Confidence score from 0.0 to 1.0.
  final double confidence;

  const CategorizationResult({
    required this.category,
    required this.source,
    required this.confidence,
  });

  /// Whether this result should be treated as successfully categorized.
  bool get isCategorized =>
      category != null && source != CategorizationSource.uncategorized && confidence >= 0.65;

  static const uncategorized = CategorizationResult(
    category: null,
    source: CategorizationSource.uncategorized,
    confidence: 0.0,
  );

  @override
  String toString() => 'CategorizationResult($category, $source, $confidence)';
}
