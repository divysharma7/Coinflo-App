import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:finance_buddy_app/design_system/design_system.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? subtitle;
  final String? lottieAsset;

  const EmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.subtitle,
    this.lottieAsset,
  });

  @override
  Widget build(BuildContext context) {
    final lottie = lottieAsset;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Builder(builder: (_) {
              final Widget visual = lottie != null
                  ? LottieBuilder.asset(lottie, width: 100, height: 100, repeat: true)
                  : Icon(icon, size: 64, color: AppColors.gray500);
              return visual.animate().scale(begin: const Offset(0.8, 0.8), duration: AppDurations.slow, curve: Curves.easeOutCubic);
            }),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              style: AppTextStyles.bodyL.copyWith(
                color: AppColors.gray500,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: AppDurations.fast, duration: AppDurations.medium),
            if (subtitle != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                subtitle!,
                style: AppTextStyles.labelM.copyWith(
                  color: AppColors.gray500,
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: AppDurations.base, duration: AppDurations.medium),
            ],
          ],
        ),
      ),
    ).animate().fadeIn(duration: AppDurations.slow).slideY(begin: 0.1, duration: AppDurations.slow);
  }
}
