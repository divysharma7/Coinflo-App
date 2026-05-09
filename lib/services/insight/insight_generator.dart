import 'package:finance_buddy_app/core/enums.dart';

/// Generates a single factual insight sentence from weekly spending data.
///
/// Tone: factual, number-led, no exclamation marks, no congratulations.
String generateWeeklyInsight({
  required List<MapEntry<TransactionCategory, double>> sortedCats,
  required double totalSpent,
  required Map<String, int> merchantCounts,
}) {
  if (sortedCats.isEmpty || totalSpent == 0) {
    return '\$0 spent this week.';
  }

  final topCat = sortedCats.first.key;
  final topAmount = sortedCats.first.value;

  // Find the most frequent merchant
  String? topMerchant;
  int topMerchantCount = 0;
  for (final entry in merchantCounts.entries) {
    if (entry.value > topMerchantCount) {
      topMerchantCount = entry.value;
      topMerchant = entry.key;
    }
  }

  // Merchant frequency insight (3+ times)
  if (topMerchant != null && topMerchantCount >= 3) {
    return '$topMerchant ${topMerchantCount}x this week. \$${topAmount.toStringAsFixed(0)} on ${topCat.label.toLowerCase()}.';
  }

  // Category-based insights
  if (topCat == TransactionCategory.foodAndDrink && topAmount > 500) {
    return '\$${topAmount.toStringAsFixed(0)} on food and drink this week. Top category.';
  }
  if (topCat == TransactionCategory.transport && topAmount > 500) {
    return '\$${topAmount.toStringAsFixed(0)} on transport this week.';
  }
  if (topCat == TransactionCategory.entertainment && topAmount > 2000) {
    return '\$${topAmount.toStringAsFixed(0)} on entertainment this week.';
  }
  if (topCat == TransactionCategory.streaming) {
    return '\$${topAmount.toStringAsFixed(0)} on streaming subscriptions.';
  }
  if (topCat == TransactionCategory.gymFitness) {
    return '\$${topAmount.toStringAsFixed(0)} on gym and fitness.';
  }
  if (topCat == TransactionCategory.shopping) {
    return '\$${topAmount.toStringAsFixed(0)} on shopping this week.';
  }

  // Low spend
  if (totalSpent < 500) {
    return '\$${totalSpent.toStringAsFixed(0)} total this week. Light spending.';
  }

  // Default
  return '\$${totalSpent.toStringAsFixed(0)} this week across ${sortedCats.length} categories.';
}
