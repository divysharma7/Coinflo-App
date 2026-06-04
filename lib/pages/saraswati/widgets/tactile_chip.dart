import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:finance_buddy_app/design_system/design_system.dart';

// ─── Tactile Chip with Press State ───────────────────────────

class TactileChip extends StatefulWidget {
  const TactileChip({
    super.key,
    required this.label,
    required this.onTap,
    required this.delay,
  });

  final String label;
  final VoidCallback onTap;
  final Duration delay;

  @override
  State<TactileChip> createState() => _TactileChipState();
}

class _TactileChipState extends State<TactileChip> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.96),
      onTapUp: (_) {
        setState(() => _scale = 1.0);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: AppDurations.fast,
        child: Container(
          constraints: const BoxConstraints(minHeight: 36),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: AppRadius.base,
            border: Border.all(color: AppColors.gray200),
          ),
          child: Text(
            widget.label,
            style: AppTextStyles.bodyS.copyWith(
              fontWeight: FontWeight.w500,
              color: AppColors.black,
            ),
          ),
        ),
      ),
    ).animate()
        .fadeIn(delay: widget.delay, duration: AppDurations.fast)
        .slideY(
            begin: 0.1,
            delay: widget.delay,
            duration: AppDurations.fast);
  }
}
