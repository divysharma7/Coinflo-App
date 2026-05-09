import 'package:flutter/material.dart';
import 'package:finance_buddy_app/core/tokens.dart';

/// Animates a numeric value with a roll + overshoot (elasticOut) effect.
///
/// Every time [value] changes the displayed number smoothly rolls from the
/// old value to the new one over 400 ms with a slight spring overshoot.
class AnimatedAmount extends StatelessWidget {
  const AnimatedAmount({
    super.key,
    required this.value,
    this.prefix = '\$ ',
    this.style,
    this.duration = SpendlerMotion.numberRoll,
    this.curve = SpendlerMotion.numberRollCurve,
  });

  final double value;
  final String prefix;
  final TextStyle? style;
  final Duration duration;
  final Curve curve;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: value),
      duration: duration,
      curve: curve,
      builder: (context, v, _) {
        final formatted = _format(v);
        final effectiveStyle = style ??
            const TextStyle(
              fontSize: SpendlerTypo.heroSize,
              fontWeight: SpendlerTypo.heroWeight,
              color: SpendlerColors.textPrimary,
              height: 1,
            );
        return Text('$prefix$formatted', style: effectiveStyle);
      },
    );
  }

  static String _format(double v) {
    final intVal = v.round().abs();
    final str = intVal.toString();
    if (str.length <= 3) return str;
    final last3 = str.substring(str.length - 3);
    var rest = str.substring(0, str.length - 3);
    final buf = StringBuffer();
    while (rest.length > 2) {
      buf.write('${rest.substring(0, rest.length - 2)},');
      rest = rest.substring(rest.length - 2);
    }
    if (rest.isNotEmpty) buf.write(rest);
    return '$buf,$last3';
  }
}
