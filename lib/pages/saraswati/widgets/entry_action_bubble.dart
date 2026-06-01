import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:finance_buddy_app/design_system/design_system.dart';
import 'package:finance_buddy_app/providers/saraswati_providers.dart';
import 'package:finance_buddy_app/services/saraswati/entry/entry_action.dart';

import 'package:finance_buddy_app/pages/saraswati/widgets/markdown_text.dart';
import 'package:finance_buddy_app/pages/saraswati/widgets/tactile_chip.dart';
import 'package:finance_buddy_app/pages/saraswati/widgets/undo_pill.dart';

// ─── Entry Action Bubble ─────────────────────────────────────

class EntryActionBubble extends StatefulWidget {
  const EntryActionBubble({
    super.key,
    required this.message,
    required this.onChipTap,
    required this.onUndo,
    required this.onFormFallback,
  });

  final SaraswatiMessage message;
  final void Function(String field, String value) onChipTap;
  final VoidCallback onUndo;
  final VoidCallback onFormFallback;

  @override
  State<EntryActionBubble> createState() => _EntryActionBubbleState();
}

class _EntryActionBubbleState extends State<EntryActionBubble>
    with SingleTickerProviderStateMixin {
  bool _undoAvailable = false;
  bool _undoFading = false;
  Timer? _undoTimer;
  late final AnimationController _undoProgress;

  @override
  void initState() {
    super.initState();
    _undoProgress = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );
    if (widget.message.entryAction is SilentCommitAction) {
      _undoAvailable = true;
      _undoProgress.forward();
      _undoTimer = Timer(const Duration(seconds: 5), () {
        if (mounted) setState(() => _undoFading = true);
        // Fade out then remove.
        Future.delayed(AppDurations.fast, () {
          if (mounted) setState(() => _undoAvailable = false);
        });
      });
    }
    if (widget.message.entryAction is QuickFormFallbackAction) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onFormFallback();
      });
    }
  }

  @override
  void dispose() {
    _undoTimer?.cancel();
    _undoProgress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final action = widget.message.entryAction!;
    final isCommit = action is SilentCommitAction;

    return Padding(
      padding: const EdgeInsets.only(
        top: AppSpacing.xs,
        bottom: AppSpacing.xs,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isCommit ? AppColors.catGreenBg : AppColors.offWhite,
          borderRadius: AppRadius.lg,
          border: isCommit
              ? Border(
                  left: BorderSide(color: AppColors.green, width: 3))
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ─── Commit: checkmark + text ─────────────────
            if (isCommit)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PhosphorIcon(
                    PhosphorIcons.checkCircle(PhosphorIconsStyle.fill),
                    color: AppColors.catGreenText,
                    size: 18,
                  ).animate().scale(
                        begin: const Offset(0.5, 0.5),
                        duration: AppDurations.fast,
                        curve: Curves.easeOutBack,
                      ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(child: MarkdownText(text: widget.message.text)),
                ],
              )
            else
              MarkdownText(text: widget.message.text),

            // ─── Undo pill with countdown ─────────────────
            if (isCommit && _undoAvailable) ...[
              const SizedBox(height: AppSpacing.sm),
              AnimatedOpacity(
                opacity: _undoFading ? 0.0 : 1.0,
                duration: AppDurations.fast,
                child: UndoPill(
                  progress: _undoProgress,
                  onTap: () {
                    _undoTimer?.cancel();
                    _undoProgress.stop();
                    setState(() => _undoAvailable = false);
                    widget.onUndo();
                  },
                ),
              ),
            ],

            // ─── Chips for AskOneQuestion ─────────────────
            if (action is AskOneQuestionAction) ...[
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (var i = 0; i < action.chipOptions.length; i++)
                    TactileChip(
                      label: action.chipOptions[i],
                      onTap: () => widget.onChipTap(
                          action.fieldToConfirm, action.chipOptions[i]),
                      delay: Duration(milliseconds: 50 * i),
                    ),
                ],
              ),
            ],
          ],
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
