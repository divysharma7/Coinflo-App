import 'package:finance_buddy_app/core/enums.dart';

/// Generates a single friendly English insight sentence from weekly spending data.
///
/// Tone: confident, warm, specific. Like a friend who noticed something
/// interesting — not a financial advisor lecturing you.
String generateWeeklyInsight({
  required List<MapEntry<TransactionCategory, double>> sortedCats,
  required double totalSpent,
  required Map<String, int> merchantCounts,
}) {
  if (sortedCats.isEmpty || totalSpent == 0) {
    return 'Nothing spent this week. A clean slate.';
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
    if (topMerchant.toLowerCase().contains('uber')) {
      return 'Uber ${topMerchantCount}x this week. You\'re a regular — \$${topAmount.toStringAsFixed(0)} on transport.';
    }
    if (topMerchant.toLowerCase().contains('swiggy')) {
      return 'Swiggy ${topMerchantCount}x this week. Your kitchen is getting jealous.';
    }
    if (topMerchant.toLowerCase().contains('zomato')) {
      return 'Zomato ${topMerchantCount}x this week. Comfort food on repeat.';
    }
    return '$topMerchant ${topMerchantCount}x this week. That\'s becoming a habit.';
  }

  // Category-based insights
  if (topCat == TransactionCategory.foodAndDrink && topAmount > 500) {
    return 'Food led the week at \$${topAmount.toStringAsFixed(0)}. You ate well.';
  }
  if (topCat == TransactionCategory.transport && topAmount > 500) {
    return '\$${topAmount.toStringAsFixed(0)} on transport. You were moving this week.';
  }
  if (topCat == TransactionCategory.entertainment && topAmount > 2000) {
    return 'Entertainment spending hit \$${topAmount.toStringAsFixed(0)}. Good times aren\'t free.';
  }
  if (topCat == TransactionCategory.personalCare) {
    return 'Housing came through — \$${topAmount.toStringAsFixed(0)}. The essentials are covered.';
  }

  // Low spend
  if (totalSpent < 500) {
    return 'Light week. Just \$${totalSpent.toStringAsFixed(0)} total. Quiet and steady.';
  }

  // Default
  return '\$${totalSpent.toStringAsFixed(0)} this week — all tracked, all logged.';
}
