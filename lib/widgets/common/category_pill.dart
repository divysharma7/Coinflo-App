import 'package:flutter/material.dart';
import 'package:finance_buddy_app/core/enums.dart';
import 'package:finance_buddy_app/core/tokens.dart';

class CategoryPill extends StatelessWidget {
  final TransactionCategory category;
  final double? amount;
  final bool selected;
  final VoidCallback? onTap;

  const CategoryPill({
    super.key,
    required this.category,
    this.amount,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Dominant category gets its active colour; rest stay muted.
    final activeColor = SpendlerColors.categoryColor(category);
    final color = selected ? activeColor : SpendlerColors.categoryMuted;
    final textColor = selected ? activeColor : SpendlerColors.textSecondary;

    final label = amount != null
        ? '${category.label} \$${amount!.toStringAsFixed(0)}'
        : category.label;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: selected ? 0.2 : 0.12),
          borderRadius: BorderRadius.circular(SpendlerRadii.pill),
          border: selected ? Border.all(color: activeColor, width: 1.5) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(category.icon, size: 14, color: textColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
