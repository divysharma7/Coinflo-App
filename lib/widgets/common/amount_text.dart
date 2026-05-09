import 'package:flutter/material.dart';
import 'package:finance_buddy_app/core/tokens.dart';

class AmountText extends StatelessWidget {
  final double amount;
  final TextStyle? style;
  final bool showSign;

  const AmountText({
    super.key,
    required this.amount,
    this.style,
    this.showSign = true,
  });

  @override
  Widget build(BuildContext context) {
    final isNegative = amount < 0;
    final color = isNegative ? SpendlerColors.accentRed : SpendlerColors.accentGreen;
    final sign = showSign ? (isNegative ? '-' : '+') : '';
    final formatted = '$sign\$\${amount.abs().toStringAsFixed(0)}';

    return Text(
      formatted,
      style: (style ?? Theme.of(context).textTheme.titleMedium)?.copyWith(
        color: color,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
