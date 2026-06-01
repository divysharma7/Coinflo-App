import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:finance_buddy_app/design_system/design_system.dart';

import 'package:finance_buddy_app/pages/saraswati/widgets/markdown_text.dart';

// ─── Assistant Bubble ──────────────────────────────────────

class AssistantBubble extends StatelessWidget {
  const AssistantBubble({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: AppSpacing.xs,
        bottom: AppSpacing.xs,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.offWhite,
          borderRadius: AppRadius.lg,
        ),
        child: MarkdownText(text: text),
      ),
    ).animate()
        .fadeIn(duration: AppDurations.base)
        .slideY(
            begin: 0.03,
            duration: AppDurations.base,
            curve: Curves.easeOutCubic);
  }
}
