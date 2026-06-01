import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:finance_buddy_app/design_system/design_system.dart';

// ─── Input Bar ─────────────────────────────────────────────

class InputBar extends StatelessWidget {
  const InputBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onSend,
    required this.isProcessing,
    required this.hintText,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSend;
  final bool isProcessing;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.xs,
        bottom: AppSpacing.xs + bottomPadding,
      ),
      decoration: const BoxDecoration(
        color: AppColors.offWhite,
        border: Border(
          top: BorderSide(color: AppColors.gray200, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: AppRadius.pill,
              ),
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                style: const TextStyle(
                  color: AppColors.black,
                  fontSize: 15,
                ),
                decoration: InputDecoration(
                  hintText: hintText,
                  hintStyle: const TextStyle(
                    color: AppColors.gray500,
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                ),
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                enabled: !isProcessing,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          // Circular black send button
          GestureDetector(
            onTap: isProcessing ? null : onSend,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isProcessing
                    ? AppColors.white
                    : AppColors.black,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.gray200, width: 1),
              ),
              child: Center(
                child: PhosphorIcon(
                  PhosphorIcons.arrowUp(PhosphorIconsStyle.bold),
                  size: 20,
                  color: isProcessing
                      ? AppColors.gray500
                      : Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
