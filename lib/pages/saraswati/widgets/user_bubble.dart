import 'package:flutter/material.dart';
import 'package:finance_buddy_app/design_system/design_system.dart';

// ─── User Bubble ───────────────────────────────────────────

class UserBubble extends StatelessWidget {
  const UserBubble({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: AppSpacing.xxs,
        bottom: AppSpacing.xxs,
        left: 64,
      ),
      child: Align(
        alignment: Alignment.centerRight,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.82,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 13,
          ),
          decoration: const BoxDecoration(
            color: AppColors.black,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(6), // squared corner
            ),
          ),
          child: Text(
            text,
            style: AppTextStyles.bodyM.copyWith(
              color: AppColors.white,
              height: 1.46,
            ),
          ),
        ),
      ),
    );
  }
}
