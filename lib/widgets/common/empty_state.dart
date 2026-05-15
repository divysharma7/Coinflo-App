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
                  : Icon(icon, size: 64, color: AppColors.gray400);
              return visual.animate().scale(begin: const Offset(0.8, 0.8), duration: 400.ms, curve: Curves.easeOutCubic);
            }),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: AppColors.gray500,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 150.ms, duration: 300.ms),
            if (subtitle != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                subtitle!,
                style: const TextStyle(
                  color: AppColors.gray400,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 250.ms, duration: 300.ms),
            ],
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, duration: 400.ms);
  }
}
