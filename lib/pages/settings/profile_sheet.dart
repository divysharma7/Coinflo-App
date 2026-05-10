import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:finance_buddy_app/core/tokens.dart';
import 'package:finance_buddy_app/providers/onboarding_provider.dart';

/// Profile bottom sheet shown when tapping the profile card in Settings.
class ProfileSheet extends ConsumerWidget {
  const ProfileSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userName = ref.watch(userNameProvider);
    final userEmail = ref.watch(userEmailProvider);

    final name = userName.valueOrNull ?? 'User';
    final email = userEmail.valueOrNull ?? 'Not set';

    // Get initials (up to 2 characters)
    final parts = name.trim().split(RegExp(r'\s+'));
    final initials = parts.length >= 2
        ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
        : (name.length >= 2 ? name.substring(0, 2).toUpperCase() : name.toUpperCase());

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header: "Profile" + close button
        Padding(
          padding: const EdgeInsets.only(bottom: SpendlerSpacing.lg),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Profile',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: SpendlerColors.textPrimary,
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: SpendlerColors.surfaceSecondary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.close,
                      size: 18,
                      color: SpendlerColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Avatar circle with initials
        Container(
          width: 80,
          height: 80,
          decoration: const BoxDecoration(
            color: SpendlerColors.primary,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              initials,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(height: SpendlerSpacing.md),

        // Name
        Text(
          name,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: SpendlerColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),

        // Email
        Text(
          email,
          style: const TextStyle(
            fontSize: 14,
            color: SpendlerColors.textTertiary,
          ),
        ),
        const SizedBox(height: SpendlerSpacing.xl),

        // Action items card
        Container(
          decoration: BoxDecoration(
            color: SpendlerColors.surface,
            borderRadius: BorderRadius.circular(SpendlerRadii.card),
            border: Border.all(color: SpendlerColors.border),
          ),
          child: Column(
            children: [
              // Settings row
              GestureDetector(
                onTap: () => Navigator.pop(context),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: SpendlerSpacing.md,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      PhosphorIcon(
                        PhosphorIcons.gear(),
                        color: SpendlerColors.textSecondary,
                        size: 20,
                      ),
                      const SizedBox(width: SpendlerSpacing.cardGap),
                      const Expanded(
                        child: Text(
                          'Settings',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                            color: SpendlerColors.textPrimary,
                          ),
                        ),
                      ),
                      PhosphorIcon(
                        PhosphorIcons.caretRight(),
                        color: SpendlerColors.textTertiary,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(left: 52),
                child: Divider(
                  height: 1,
                  thickness: 0.5,
                  color: SpendlerColors.border,
                ),
              ),
              // Accounts row
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Coming soon')),
                  );
                },
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: SpendlerSpacing.md,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      PhosphorIcon(
                        PhosphorIcons.creditCard(),
                        color: SpendlerColors.textSecondary,
                        size: 20,
                      ),
                      const SizedBox(width: SpendlerSpacing.cardGap),
                      const Expanded(
                        child: Text(
                          'Accounts',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                            color: SpendlerColors.textPrimary,
                          ),
                        ),
                      ),
                      PhosphorIcon(
                        PhosphorIcons.caretRight(),
                        color: SpendlerColors.textTertiary,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: SpendlerSpacing.lg),
      ],
    );
  }
}
