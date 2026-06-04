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
              decoration: const BoxDecoration(
                color: AppColors.white,
                borderRadius: AppRadius.pill,
                boxShadow: AppShadows.sm,
              ),
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                style: AppTextStyles.bodyM.copyWith(
                  color: AppColors.black,
                ),
                decoration: InputDecoration(
                  hintText: hintText,
                  hintStyle: AppTextStyles.bodyM.copyWith(
                    color: AppColors.gray400,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                ),
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                enabled: !isProcessing,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          // Ink circular send button
          GestureDetector(
            onTap: isProcessing ? null : onSend,
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: isProcessing ? AppColors.gray300 : AppColors.black,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: PhosphorIcon(
                  PhosphorIcons.arrowUp(PhosphorIconsStyle.bold),
                  size: 20,
                  color: AppColors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
