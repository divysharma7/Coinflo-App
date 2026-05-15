import 'package:flutter/material.dart';
import 'package:finance_buddy_app/design_system/design_system.dart';

class AmountText extends StatelessWidget {
  final double amount;
  final TextStyle? style;
  final bool showSign;
  final String symbol;

  const AmountText({
    super.key,
    required this.amount,
    this.style,
    this.showSign = true,
    this.symbol = '\$',
  });

  @override
  Widget build(BuildContext context) {
    final isNegative = amount < 0;
    final color = isNegative ? AppColors.red : AppColors.green;
    final sign = showSign ? (isNegative ? '-' : '+') : '';
    final formatted = '$sign$symbol${amount.abs().toStringAsFixed(0)}';

    return Text(
      formatted,
      style: (style ?? Theme.of(context).textTheme.titleMedium)?.copyWith(
        color: color,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
