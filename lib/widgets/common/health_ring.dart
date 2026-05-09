import 'dart:math';

import 'package:flutter/material.dart';
import 'package:finance_buddy_app/core/tokens.dart';

/// Animated circular progress ring (Health Ring) for the "My Page" feature.
///
/// Animates from 0 to [progress] on first build, and smoothly transitions
/// when [progress] changes.
class HealthRing extends StatefulWidget {
  const HealthRing({
    super.key,
    required this.progress,
    this.size = 120,
    this.strokeWidth = 8,
    this.foregroundColor = SpendlerColors.yellow,
    this.backgroundColor = SpendlerColors.border,
    this.label,
  });

  /// Value between 0.0 and 1.0 representing how full the ring is.
  final double progress;

  /// Diameter of the ring widget.
  final double size;

  /// Thickness of the ring stroke.
  final double strokeWidth;

  /// Color of the filled arc.
  final Color foregroundColor;

  /// Color of the unfilled background arc.
  final Color backgroundColor;

  /// Optional text shown below the percentage (e.g., "remaining").
  final String? label;

  @override
  State<HealthRing> createState() => _HealthRingState();
}

class _HealthRingState extends State<HealthRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animation = Tween<double>(begin: 0, end: widget.progress).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant HealthRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      _animation = Tween<double>(
        begin: _animation.value,
        end: widget.progress,
      ).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
      );
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final value = _animation.value;
          return Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _HealthRingPainter(
                    progress: value,
                    strokeWidth: widget.strokeWidth,
                    foregroundColor: widget.foregroundColor,
                    backgroundColor: widget.backgroundColor,
                  ),
                ),
              ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${(value * 100).round()}%',
                      style: const TextStyle(
                        color: SpendlerColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    if (widget.label != null)
                      Text(
                        widget.label!,
                        style: const TextStyle(
                          color: SpendlerColors.textTertiary,
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HealthRingPainter extends CustomPainter {
  _HealthRingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.foregroundColor,
    required this.backgroundColor,
  });

  final double progress;
  final double strokeWidth;
  final Color foregroundColor;
  final Color backgroundColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Background arc (full circle).
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, 2 * pi, false, bgPaint);

    // Foreground arc (partial, starting from top).
    final fgPaint = Paint()
      ..color = foregroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    final sweepAngle = progress * 2 * pi;
    canvas.drawArc(rect, -pi / 2, sweepAngle, false, fgPaint);
  }

  @override
  bool shouldRepaint(covariant _HealthRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.foregroundColor != foregroundColor ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}
