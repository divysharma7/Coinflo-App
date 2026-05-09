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
      padding: const EdgeInsets.all(PaisaSpacing.lg),
      decoration: BoxDecoration(
        color: PaisaColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: PaisaShadows.card,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Text(
            'PULSE',
            style: TextStyle(
              color: PaisaColors.textTertiary,
              fontSize: 12,
              letterSpacing: 2,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Weekly Summary',
            style: TextStyle(
              color: PaisaColors.textPrimary,
              fontSize: PaisaTypo.titleSize,
              fontWeight: PaisaTypo.titleWeight,
            ),
          ),
          Text(
            dateRange,
            style: const TextStyle(
              color: PaisaColors.textSecondary,
              fontSize: PaisaTypo.bodySize,
            ),
          ),
          const SizedBox(height: PaisaSpacing.lg),

          // Total — hero number style
          Container(
            padding: const EdgeInsets.all(PaisaSpacing.cardPadding),
            decoration: BoxDecoration(
              color: PaisaColors.surfaceSecondary,
              borderRadius: BorderRadius.circular(PaisaRadii.button),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Spent',
                  style: TextStyle(
                    color: PaisaColors.textSecondary,
                    fontSize: 16,
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    const Text(
                      'Rs',
                      style: TextStyle(
                        color: PaisaColors.textSecondary,
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      totalSpent.toStringAsFixed(0),
                      style: const TextStyle(
                        color: PaisaColors.accentYellow,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: PaisaSpacing.md),

          // Category breakdown
          ...categoryTotals.entries.take(4).map((e) {
            final cat = TransactionCategory.values.firstWhere(
              (c) => c.name == e.key,
              orElse: () => TransactionCategory.other,
            );
            final pct = totalSpent > 0 ? (e.value / totalSpent * 100) : 0;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(cat.icon, color: PaisaColors.categoryColor(cat), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      cat.label,
                      style: const TextStyle(
                        color: PaisaColors.textPrimary,
                        fontSize: PaisaTypo.bodySize,
                      ),
                    ),
                  ),
                  Text(
                    '₹${e.value.toStringAsFixed(0)} (${pct.toStringAsFixed(0)}%)',
                    style: const TextStyle(
                      color: PaisaColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: PaisaTypo.bodySize,
                    ),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 20),
          const Divider(color: PaisaColors.surfaceSecondary),
          const SizedBox(height: 8),
          const Text(
            'Feel your financial rhythm.',
            style: TextStyle(
              color: PaisaColors.textTertiary,
              fontSize: 11,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
