import 'package:flutter/material.dart';
import 'package:finance_buddy_app/design_system/design_system.dart';

/// Reusable CoinFlo wordmark + tagline logo.
class CoinFloLogo extends StatelessWidget {
  const CoinFloLogo({super.key, this.opacity = 1.0});

  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'COINFLO',
            style: AppTextStyles.headingL.copyWith(
              color: AppColors.black,
              letterSpacing: 4,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Track your spending habits.',
            style: AppTextStyles.bodyM.copyWith(
              color: AppColors.gray500,
            ),
          ),
        ],
      ),
    );
  }
}
