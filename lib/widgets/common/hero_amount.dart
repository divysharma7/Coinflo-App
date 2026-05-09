import 'package:flutter/material.dart';
import 'package:finance_buddy_app/core/tokens.dart';
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
              style: SpendlerTextStyles.heroSymbol.copyWith(fontSize: symbolSize),
            ),
            const SizedBox(width: 2),
            AnimatedAmount(
              value: amount,
              prefix: '',
              style: SpendlerTextStyles.heroAmount.copyWith(
                fontSize: amountSize,
                letterSpacing: amountSize > 40 ? -2.0 : -1.0,
              ),
              duration: SpendlerMotion.number,
              curve: SpendlerMotion.numberCurve,
            ),
          ],
        ),
        if (deltaText != null) ...[
          const SizedBox(height: SpendlerSpacing.sm),
          ContextualPill(text: deltaText!, type: deltaType),
        ],
      ],
    );
  }
}
