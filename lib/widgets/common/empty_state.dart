import 'package:flutter/material.dart';
import 'package:finance_buddy_app/core/tokens.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? subtitle;

  const EmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(PaisaSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: PaisaColors.textTertiary),
            const SizedBox(height: PaisaSpacing.md),
            Text(
              message,
              style: PaisaTextStyles.emptyState,
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: PaisaSpacing.sm),
              Text(
                subtitle!,
                style: const TextStyle(
                  color: PaisaColors.textTertiary,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
