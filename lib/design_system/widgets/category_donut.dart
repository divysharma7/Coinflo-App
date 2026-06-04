import 'dart:math' as math;

import 'package:flutter/material.dart';

/// One slice of a [CategoryDonut].
class DonutSegment {
  const DonutSegment({required this.value, required this.color});
  final double value;
  final Color color;
}

/// Multi-segment donut chart with an optional center widget.
/// Contiguous arcs (butt caps) starting at 12 o'clock, matching the
/// CoinFlo Hi-Fi report donut. Animates in on first build.
class CategoryDonut extends StatefulWidget {
  const CategoryDonut({
    super.key,
    required this.segments,
    this.size = 148,
    this.strokeWidth = 22,
    this.center,
    this.trackColor = const Color(0xFFF0F0F0),
  });

  final List<DonutSegment> segments;
  final double size;
  final double strokeWidth;
  final Widget? center;
  final Color trackColor;

  @override
  State<CategoryDonut> createState() => _CategoryDonutState();
}

class _CategoryDonutState extends State<CategoryDonut>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    )..forward();
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
        animation: _controller,
        builder: (context, _) {
          return Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _DonutPainter(
                    segments: widget.segments,
                    strokeWidth: widget.strokeWidth,
                    trackColor: widget.trackColor,
                    t: Curves.easeOutCubic.transform(_controller.value),
                  ),
                ),
              ),
              if (widget.center != null) widget.center!,
            ],
          );
        },
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({
    required this.segments,
    required this.strokeWidth,
    required this.trackColor,
    required this.t,
  });

  final List<DonutSegment> segments;
  final double strokeWidth;
  final Color trackColor;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final track = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawArc(rect, 0, 2 * math.pi, false, track);

    final total = segments.fold<double>(0, (s, e) => s + e.value);
    if (total <= 0) return;

    const gap = 0.012; // tiny separation between slices (radians)
    var start = -math.pi / 2;
    for (final seg in segments) {
      final sweep = (seg.value / total) * 2 * math.pi * t;
      if (sweep <= 0) continue;
      final paint = Paint()
        ..color = seg.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(rect, start + gap, math.max(0, sweep - gap), false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) =>
      old.t != t || old.segments != segments;
}
