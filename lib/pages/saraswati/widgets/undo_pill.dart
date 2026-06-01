import 'package:flutter/material.dart';
import 'package:finance_buddy_app/design_system/design_system.dart';

// ─── Undo Pill with Countdown Bar ────────────────────────────

class UndoPill extends StatelessWidget {
  const UndoPill({super.key, required this.progress, required this.onTap});

  final AnimationController progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        height: 32,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.gray100,
          borderRadius: AppRadius.pill,
        ),
        child: Stack(
          children: [
            // Shrinking progress bar
            AnimatedBuilder(
              animation: progress,
              builder: (context, _) {
                return FractionallySizedBox(
                  widthFactor: 1.0 - progress.value,
                  child: Container(color: AppColors.gray200),
                );
              },
            ),
            // Label
            const Center(
              child: Text(
                'Undo',
                style: TextStyle(
                  color: AppColors.gray500,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
