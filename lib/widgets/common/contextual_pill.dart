import 'package:flutter/material.dart';
import 'package:finance_buddy_app/design_system/design_system.dart';

enum DeltaType { positive, negative, neutral }

/// A tiny rounded-rect pill that shows a contextual delta or status.
/// e.g. "+10% VS LAST WEEK", "TOP CATEGORY", "ON TRACK".
class ContextualPill extends StatelessWidget {
  const ContextualPill({
    super.key,
    required this.text,
    this.type = DeltaType.neutral,
  });

  final String text;
  final DeltaType type;

  Color get _foreground => switch (type) {
        DeltaType.positive => AppColors.green,
        DeltaType.negative => AppColors.orange,
        DeltaType.neutral => AppColors.gray500,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _foreground.withValues(alpha: 0.15),
        borderRadius: AppRadius.full,
      ),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          color: _foreground,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
