import 'package:flutter/material.dart';
import 'package:finance_buddy_app/core/enums.dart';
import 'package:finance_buddy_app/core/tokens.dart';

class WeeklySummaryPoster extends StatelessWidget {
  final DateTime weekStart;
  final double totalSpent;
  final Map<String, double> categoryTotals;
  final List<double> dailyTotals;

  const WeeklySummaryPoster({
    super.key,
    required this.weekStart,
    required this.totalSpent,
    required this.categoryTotals,
    required this.dailyTotals,
  });

  @override
  Widget build(BuildContext context) {
    final weekEnd = weekStart.add(const Duration(days: 6));
    final dateRange =
        '${weekStart.day}/${weekStart.month} - ${weekEnd.day}/${weekEnd.month}';

    return Container(
      width: 400,
      padding: const EdgeInsets.all(SpendlerSpacing.lg),
      decoration: BoxDecoration(
        color: SpendlerColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: SpendlerShadows.card,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Text(
            'SPENDLER',
            style: TextStyle(
              color: SpendlerColors.textTertiary,
              fontSize: 12,
              letterSpacing: 2,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Weekly Summary',
            style: TextStyle(
              color: SpendlerColors.textPrimary,
              fontSize: SpendlerTypo.titleSize,
              fontWeight: SpendlerTypo.titleWeight,
            ),
          ),
          Text(
            dateRange,
            style: const TextStyle(
              color: SpendlerColors.textSecondary,
              fontSize: SpendlerTypo.bodySize,
            ),
          ),
          const SizedBox(height: SpendlerSpacing.lg),

          // Total — hero number style
          Container(
            padding: const EdgeInsets.all(SpendlerSpacing.cardPadding),
            decoration: BoxDecoration(
              color: SpendlerColors.surfaceSecondary,
              borderRadius: BorderRadius.circular(SpendlerRadii.button),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Spent',
                  style: TextStyle(
                    color: SpendlerColors.textSecondary,
                    fontSize: 16,
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    const Text(
                      '\$',
                      style: TextStyle(
                        color: SpendlerColors.textSecondary,
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      totalSpent.toStringAsFixed(0),
                      style: const TextStyle(
                        color: SpendlerColors.accentYellow,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: SpendlerSpacing.md),

          // Category breakdown
          ...categoryTotals.entries.take(4).map((e) {
            final cat = TransactionCategory.values.firstWhere(
              (c) => c.name == e.key,
              orElse: () => TransactionCategory.foodAndDrink,
            );
            final pct = totalSpent > 0 ? (e.value / totalSpent * 100) : 0;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(cat.icon, color: SpendlerColors.categoryColor(cat), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      cat.label,
                      style: const TextStyle(
                        color: SpendlerColors.textPrimary,
                        fontSize: SpendlerTypo.bodySize,
                      ),
                    ),
                  ),
                  Text(
                    '\$${e.value.toStringAsFixed(0)} (${pct.toStringAsFixed(0)}%)',
                    style: const TextStyle(
                      color: SpendlerColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: SpendlerTypo.bodySize,
                    ),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 20),
          const Divider(color: SpendlerColors.surfaceSecondary),
          const SizedBox(height: 8),
          const Text(
            'Track your spending habits.',
            style: TextStyle(
              color: SpendlerColors.textTertiary,
              fontSize: 11,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
