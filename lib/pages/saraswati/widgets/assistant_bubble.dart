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
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.82,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 13,
          ),
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
              bottomRight: Radius.circular(20),
              bottomLeft: Radius.circular(6), // squared corner
            ),
            boxShadow: AppShadows.sm,
          ),
          child: MarkdownText(text: text),
        ),
      ),
    ).animate()
        .fadeIn(duration: AppDurations.base)
        .slideY(
            begin: 0.03,
            duration: AppDurations.base,
            curve: Curves.easeOutCubic);
  }
}
