import 'package:flutter/material.dart';
import 'package:finance_buddy_app/core/tokens.dart';

class UnconfirmedBadge extends StatelessWidget {
  final int count;
  final VoidCallback? onTap;

  const UnconfirmedBadge({
    super.key,
    required this.count,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SizedBox.shrink();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: PaisaSpacing.screenH,
          vertical: PaisaSpacing.sm,
        ),
        padding: const EdgeInsets.all(PaisaSpacing.cardPadding),
        decoration: BoxDecoration(
          color: PaisaColors.accentAmber.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(PaisaRadii.button),
          border: const Border(
            left: BorderSide(color: PaisaColors.accentAmber, width: 4),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.pending_actions, color: PaisaColors.accentAmber),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$count unconfirmed transaction${count > 1 ? 's' : ''}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: PaisaColors.textPrimary,
                    ),
                  ),
                  const Text(
                    'Tap to review & confirm',
                    style: TextStyle(
                      fontSize: 12,
                      color: PaisaColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: PaisaColors.textTertiary),
          ],
        ),
      ),
    );
  }
}
