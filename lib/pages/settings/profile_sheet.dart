import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:finance_buddy_app/design_system/design_system.dart';
import 'package:finance_buddy_app/providers/onboarding_provider.dart';

class ProfileSheet extends ConsumerWidget {
  const ProfileSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userName = ref.watch(userNameProvider);
    final userEmail = ref.watch(userEmailProvider);

    final name = userName.valueOrNull ?? 'User';
    final email = userEmail.valueOrNull ?? 'Not set';

    final parts = name.trim().split(RegExp(r'\s+'));
    final initials = parts.length >= 2
        ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
        : (name.length >= 2
            ? name.substring(0, 2).toUpperCase()
            : name.toUpperCase());

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Profile',
                  style: AppTextStyles.headingM
                      .copyWith(color: AppColors.black),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: AppColors.gray100,
                      borderRadius: AppRadius.sm,
                    ),
                    child: const Center(
                      child: Icon(Icons.close,
                          size: 18, color: AppColors.gray500),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Avatar
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: AppColors.black,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                initials,
                style: AppTextStyles.headingL
                    .copyWith(color: AppColors.white),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Name
          Text(
            name,
            style:
                AppTextStyles.headingM.copyWith(color: AppColors.black),
          ),
          const SizedBox(height: AppSpacing.xxs),

          // Email
          Text(
            email,
            style:
                AppTextStyles.bodyM.copyWith(color: AppColors.gray500),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Action rows card
          Container(
            decoration: const BoxDecoration(
              color: AppColors.white,
              borderRadius: AppRadius.xl,
              boxShadow: AppShadows.sm,
            ),
            child: Column(
              children: [
                // Settings row
                _buildRow(
                  icon: Icons.settings_outlined,
                  label: 'Settings',
                  onTap: () => Navigator.pop(context),
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 52),
                  child: Divider(
                      height: 1, thickness: 0.5, color: AppColors.gray200),
                ),
                // Accounts row
                _buildRow(
                  icon: Icons.credit_card_outlined,
                  label: 'Accounts',
                  onTap: () {
                    Navigator.pop(context);
                    // Navigate to settings tab which has the accounts option
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }

  Widget _buildRow({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 14,
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.gray500, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(label, style: AppTextStyles.bodyM),
            ),
            const Icon(Icons.chevron_right,
                color: AppColors.gray400, size: 20),
          ],
        ),
      ),
    );
  }
}
