import 'dart:math';
import 'package:flutter/material.dart';
import 'package:finance_buddy_app/design_system/design_system.dart';

/// A 3D-flipping coin that shows a currency symbol on the front face.
class SpinningCoin extends StatelessWidget {
  const SpinningCoin({
    super.key,
    required this.rotationY,
    required this.symbol,
    this.size = 80,
  });

  /// Current Y-axis rotation in radians.
  final double rotationY;

  /// Currency symbol displayed on the front face (e.g. "₹", "$").
  final String symbol;

  /// Diameter of the coin.
  final double size;

  @override
  Widget build(BuildContext context) {
    // Show symbol only when the front face is visible.
    final showFront = cos(rotationY) > 0;
    final symbolOpacity = showFront ? cos(rotationY).clamp(0.0, 1.0) : 0.0;

    final borderColor = Color.lerp(AppColors.black, Colors.black, 0.2)!;

    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.001) // perspective
        ..rotateY(rotationY),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.black,
          shape: BoxShape.circle,
          border: Border.all(color: borderColor, width: 2.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.25),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: Opacity(
            opacity: symbolOpacity,
            child: Text(
              symbol,
              style: TextStyle(
                fontSize: size * 0.4,
                fontWeight: FontWeight.w700,
                color: AppColors.white,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
