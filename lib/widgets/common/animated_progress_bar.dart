import 'package:flutter/material.dart';
import 'package:finance_buddy_app/design_system/design_system.dart';

/// A LinearProgressIndicator that animates smoothly when [value] changes.
class AnimatedProgressBar extends StatelessWidget {
  const AnimatedProgressBar({
    super.key,
    required this.value,
    this.backgroundColor = const Color(0xFFF0F0F0),
    this.valueColor = Colors.black,
    this.minHeight = 6,
    this.borderRadius = 3,
    this.duration = AppDurations.slow,
    this.curve = Curves.easeInOut,
  });

  final double value;
  final Color backgroundColor;
  final Color valueColor;
  final double minHeight;
  final double borderRadius;
  final Duration duration;
  final Curve curve;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.clamp(0.0, 1.0)),
      duration: duration,
      curve: curve,
      builder: (context, animValue, _) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: LinearProgressIndicator(
            value: animValue,
            backgroundColor: backgroundColor,
            valueColor: AlwaysStoppedAnimation(valueColor),
            minHeight: minHeight,
          ),
        );
      },
    );
  }
}
