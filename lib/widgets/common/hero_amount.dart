import 'package:flutter/material.dart';
import 'package:finance_buddy_app/design_system/design_system.dart';
import 'package:finance_buddy_app/widgets/common/animated_amount.dart';
import 'package:finance_buddy_app/widgets/common/contextual_pill.dart';

/// Displays a large hero-style animated amount with the currency symbol smaller
/// and lighter, following the Cred hero-number pattern.
class HeroAmount extends StatelessWidget {
  const HeroAmount({
    super.key,
    required this.amount,
    this.symbol = '\$',
    this.deltaText,
    this.deltaType = DeltaType.neutral,
    this.amountSize = 64,
    this.symbolSize = 28,
  });

  final double amount;
  final String symbol;
  final String? deltaText;
  final DeltaType deltaType;
  final double amountSize;
  final double symbolSize;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              symbol,
              style: TextStyle(
                fontSize: symbolSize,
                fontWeight: FontWeight.w300,
                color: AppColors.gray500,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(width: 2),
            AnimatedAmount(
              value: amount,
              prefix: '',
              style: TextStyle(
                fontSize: amountSize,
                fontWeight: FontWeight.w700,
                color: AppColors.black,
                fontFeatures: const [FontFeature.tabularFigures()],
                letterSpacing: amountSize > 40 ? -2.0 : -1.0,
                height: 1,
              ),
              duration: AppDurations.base,
              curve: Curves.easeOut,
            ),
          ],
        ),
        if (deltaText != null) ...[
          const SizedBox(height: AppSpacing.xs),
          ContextualPill(text: deltaText!, type: deltaType),
        ],
      ],
    );
  }
}
