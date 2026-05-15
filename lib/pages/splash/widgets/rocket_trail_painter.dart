import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:finance_buddy_app/design_system/design_system.dart';

/// A particle in the rocket trail.
class TrailParticle {
  TrailParticle({
    required this.position,
    required this.color,
    required this.life, // 0.0 (born) → 1.0 (dead)
  });

  final Offset position;
  final Color color;
  final double life;
}

/// Paints a tapering trail behind the coin and scattered particles.
class RocketTrailPainter extends CustomPainter {
  RocketTrailPainter({
    required this.start,
    required this.controlPoint,
    required this.end,
    required this.progress,
    required this.particles,
  })  : _trailPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
        _particlePaint = Paint()..style = PaintingStyle.fill;

  final Offset start;
  final Offset controlPoint;
  final Offset end;

  /// 0.0 = no trail, 1.0 = full trail drawn.
  final double progress;

  final List<TrailParticle> particles;

  // Pre-allocated paints — no allocation in paint().
  final Paint _trailPaint;
  final Paint _particlePaint;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    _paintTrail(canvas);
    _paintParticles(canvas);
  }

  void _paintTrail(Canvas canvas) {
    // Draw the trail as segmented strokes that taper from thick to thin.
    const segments = 30;
    final drawSegments = (segments * progress).ceil();
    if (drawSegments < 2) return;

    for (int i = 0; i < drawSegments - 1; i++) {
      final t0 = i / segments;
      final t1 = (i + 1) / segments;
      final p0 = _bezierAt(t0);
      final p1 = _bezierAt(t1);

      // Taper: thick at head (near coin), thin at tail.
      final strokeWidth = ui.lerpDouble(2, 12, t0 / progress)!;
      final opacity = (t0 / progress).clamp(0.0, 1.0) * 0.5;

      _trailPaint
        ..strokeWidth = strokeWidth
        ..color = AppColors.black.withValues(alpha: opacity);

      canvas.drawLine(p0, p1, _trailPaint);
    }
  }

  void _paintParticles(Canvas canvas) {
    for (final p in particles) {
      final radius = 4.0 * (1.0 - p.life); // shrink as life increases
      final alpha = (1.0 - p.life).clamp(0.0, 1.0);
      if (alpha <= 0 || radius <= 0) continue;

      _particlePaint.color = p.color.withValues(alpha: alpha);
      canvas.drawCircle(p.position, radius, _particlePaint);
    }
  }

  /// Quadratic Bezier point at parameter t.
  Offset _bezierAt(double t) {
    final mt = 1 - t;
    return start * (mt * mt) + controlPoint * (2 * mt * t) + end * (t * t);
  }

  @override
  bool shouldRepaint(RocketTrailPainter old) =>
      old.progress != progress || old.particles.length != particles.length;
}

/// Generates particle positions along the Bezier trail.
List<TrailParticle> generateParticles({
  required Offset start,
  required Offset controlPoint,
  required Offset end,
  required double trailProgress,
  required int count,
  required Random rng,
}) {
  if (trailProgress <= 0) return const [];

  final colors = [AppColors.green, AppColors.orange];
  return List.generate(count, (i) {
    // Spread particles along the drawn portion of the trail.
    final t = (i / count) * trailProgress;
    final mt = 1 - t;
    final base = start * (mt * mt) + controlPoint * (2 * mt * t) + end * (t * t);

    // Small random offset.
    final jitter = Offset(
      (rng.nextDouble() - 0.5) * 16,
      (rng.nextDouble() - 0.5) * 16,
    );

    return TrailParticle(
      position: base + jitter,
      color: colors[i % colors.length],
      life: (1 - t / trailProgress).clamp(0.0, 1.0) * trailProgress,
    );
  });
}
