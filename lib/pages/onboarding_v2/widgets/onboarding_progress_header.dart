import 'package:flutter/material.dart';

import 'package:finance_buddy_app/design_system/design_system.dart';

/// Honest "x of 6" onboarding progress — a label row above a thin gradient
/// track. Replaces the old 8-dash bar that filled dishonestly on screen one.
///
/// Only the six *setup* steps are counted (Currency, Accounts, Categories,
/// Budget, Goals, Reminders); the Welcome, Recap and Create-account screens
/// sit outside the count, so the bar always tells the truth.
class OnboardingProgressHeader extends StatelessWidget {
  const OnboardingProgressHeader({
    super.key,
    required this.step,
    this.totalSteps = 6,
  }) : assert(step >= 1);

  /// 1-based index of the current setup step.
  final int step;
  final int totalSteps;

  static const _trackFill = LinearGradient(
    colors: [Color(0xFF3A3A3A), AppColors.black],
  );

  @override
  Widget build(BuildContext context) {
    final fraction = (step / totalSteps).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'SETUP',
              style: AppTextStyles.labelS.copyWith(
                color: AppColors.gray500,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
              ),
            ),
            Text(
              '$step of $totalSteps',
              style: AppTextStyles.labelS.copyWith(
                color: AppColors.gray500,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        ClipRRect(
          borderRadius: AppRadius.full,
          child: SizedBox(
            height: 4,
            child: Stack(
              children: [
                const ColoredBox(
                  color: AppColors.gray200,
                  child: SizedBox(width: double.infinity, height: 4),
                ),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: fraction),
                  duration: AppDurations.slow,
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) => FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: value,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: _trackFill,
                        borderRadius: AppRadius.full,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x400A0A0A),
                            blurRadius: 2,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
