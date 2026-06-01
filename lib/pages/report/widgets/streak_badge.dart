import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:finance_buddy_app/design_system/design_system.dart';
import 'package:finance_buddy_app/providers/providers.dart';
import 'package:finance_buddy_app/widgets/common/error_card.dart';

// ---------------------------------------------------------------------------
// Streak Badge
// ---------------------------------------------------------------------------

class StreakBadge extends ConsumerWidget {
  const StreakBadge({super.key, required this.symbol});
  final String symbol;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streakAsync = ref.watch(streakProvider);
    return streakAsync.when(
      data: (weeks) {
        if (weeks <= 0) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.green.withValues(alpha: 0.08),
              borderRadius: AppRadius.lg,
              border: Border.all(
                  color: AppColors.green.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.green.withValues(alpha: 0.15),
                    borderRadius: AppRadius.md,
                  ),
                  child: const Icon(Icons.local_fire_department,
                      color: AppColors.green, size: 24),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$weeks-week streak!',
                          style: AppTextStyles.headingS.copyWith(
                              color: AppColors.green)),
                      Text('Consecutive weeks under your spending target',
                          style: AppTextStyles.bodyS
                              .copyWith(color: AppColors.gray500)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const ErrorCard(),
    );
  }
}
