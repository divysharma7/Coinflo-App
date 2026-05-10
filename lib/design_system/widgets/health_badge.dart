import 'package:flutter/material.dart';

import 'package:finance_buddy_app/design_system/app_colors.dart';
import 'package:finance_buddy_app/design_system/app_radius.dart';
import 'package:finance_buddy_app/design_system/app_spacing.dart';
import 'package:finance_buddy_app/design_system/app_text_styles.dart';
import 'package:finance_buddy_app/models/savings_goal_model.dart';
import 'package:finance_buddy_app/models/recurring_payment_model.dart';

class HealthBadge extends StatelessWidget {
  const HealthBadge._({
    required this.label,
    required this.bgColor,
    required this.textColor,
  });

  factory HealthBadge.fromGoalHealth(GoalHealth health) {
    switch (health) {
      case GoalHealth.onTrack:
        return const HealthBadge._(
          label: 'On Track',
          bgColor: AppColors.catGreenBg,
          textColor: AppColors.catGreenText,
        );
      case GoalHealth.atRisk:
        return const HealthBadge._(
          label: 'At Risk',
          bgColor: AppColors.orangeLight,
          textColor: AppColors.orange,
        );
      case GoalHealth.behind:
        return const HealthBadge._(
          label: 'Behind',
          bgColor: AppColors.redLight,
          textColor: AppColors.red,
        );
      case GoalHealth.completed:
        return const HealthBadge._(
          label: 'Completed',
          bgColor: AppColors.green,
          textColor: AppColors.white,
        );
    }
  }

  factory HealthBadge.fromPaymentHealth(PaymentHealth health) {
    switch (health) {
      case PaymentHealth.onTrack:
        return const HealthBadge._(
          label: 'On Track',
          bgColor: AppColors.catGreenBg,
          textColor: AppColors.catGreenText,
        );
      case PaymentHealth.atRisk:
        return const HealthBadge._(
          label: 'At Risk',
          bgColor: AppColors.orangeLight,
          textColor: AppColors.orange,
        );
      case PaymentHealth.behind:
        return const HealthBadge._(
          label: 'Behind',
          bgColor: AppColors.redLight,
          textColor: AppColors.red,
        );
    }
  }

  final String label;
  final Color bgColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: AppRadius.full,
      ),
      child: Text(
        label,
        style: AppTextStyles.labelS.copyWith(color: textColor),
      ),
    );
  }
}
