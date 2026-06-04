import 'package:flutter/material.dart';

import 'package:finance_buddy_app/design_system/app_radius.dart';
import 'package:finance_buddy_app/design_system/app_shadows.dart';
import 'package:finance_buddy_app/design_system/app_spacing.dart';

/// Near-black radial-gradient hero card — the single elevated surface per
/// dashboard in the CoinFlo Hi-Fi system. Renders a soft white highlight
/// blob in the top-right corner and deep layered shadow.
class DarkHeroCard extends StatelessWidget {
  const DarkHeroCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(22),
    this.borderRadius = AppRadius.xl,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: AppShadows.lg,
        gradient: const RadialGradient(
          center: Alignment(0.7, -1.2),
          radius: 1.35,
          colors: [Color(0xFF2C2C2E), Color(0xFF141415), Color(0xFF0A0A0A)],
          stops: [0.0, 0.45, 1.0],
        ),
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Stack(
          children: [
            // Soft highlight blob, top-right.
            Positioned(
              right: -40,
              top: -60,
              child: Container(
                width: 200,
                height: 200,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [Color(0x14FFFFFF), Color(0x00FFFFFF)],
                    stops: [0.0, 0.7],
                  ),
                ),
              ),
            ),
            Padding(padding: padding, child: child),
          ],
        ),
      ),
    );
  }
}

/// Convenience spacing constant used by hero content rows.
const double kHeroGap = AppSpacing.md;
