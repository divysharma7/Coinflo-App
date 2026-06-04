import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:finance_buddy_app/design_system/design_system.dart';

// ─── Saraswati Onboarding (suggestion grid empty state) ──────

class SaraswatiOnboarding extends StatelessWidget {
  const SaraswatiOnboarding({
    super.key,
    required this.entrySuggestions,
    required this.querySuggestions,
    required this.onSuggestionTap,
  });

  final List<String> entrySuggestions;
  final List<String> querySuggestions;
  final void Function(String) onSuggestionTap;

  @override
  Widget build(BuildContext context) {
    var delay = 0;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xxl,
      ),
      child: Column(
        children: [
          const SizedBox(height: 40),

          // Lightning icon in rounded square
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: AppColors.black,
              borderRadius: AppRadius.lg,
            ),
            child: Center(
              child: PhosphorIcon(
                PhosphorIcons.lightning(PhosphorIconsStyle.fill),
                color: AppColors.white,
                size: 30,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          const Text(
            "Hi, I'm Saraswati",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),

          Text(
            'Ask me anything about your finances, or log expenses by typing naturally.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyM.copyWith(
              color: AppColors.gray500,
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),

          // ─── Quick Log section ──────────────────────────
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('QUICK LOG', style: AppTextStyles.labelM),
          ),
          const SizedBox(height: AppSpacing.sm),

          ...entrySuggestions.map((s) {
            final d = Duration(milliseconds: delay);
            delay += AppDurations.listStagger.inMilliseconds;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: GestureDetector(
                onTap: () => onSuggestionTap(s),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.catGreenBg,
                    borderRadius: AppRadius.base,
                    border: Border.all(color: AppColors.green.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      PhosphorIcon(
                        PhosphorIcons.arrowUpRight(),
                        color: AppColors.catGreenText,
                        size: 16,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          s,
                          style: AppTextStyles.bodyM.copyWith(
                            fontWeight: FontWeight.w500,
                            color: AppColors.catGreenText,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ).animate()
                .fadeIn(delay: d, duration: AppDurations.slow)
                .slideY(begin: 0.05, delay: d, duration: AppDurations.slow);
          }),

          const SizedBox(height: AppSpacing.lg),

          // ─── Ask Saraswati section ──────────────────────
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('ASK SARASWATI', style: AppTextStyles.labelM),
          ),
          const SizedBox(height: AppSpacing.sm),

          ...querySuggestions.map((s) {
            final d = Duration(milliseconds: delay);
            delay += AppDurations.listStagger.inMilliseconds;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: GestureDetector(
                onTap: () => onSuggestionTap(s),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: AppRadius.base,
                    border: Border.all(color: AppColors.gray200),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          s,
                          style: AppTextStyles.bodyM.copyWith(
                            color: AppColors.black,
                          ),
                        ),
                      ),
                      PhosphorIcon(
                        PhosphorIcons.caretRight(),
                        color: AppColors.gray500,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ).animate()
                .fadeIn(delay: d, duration: AppDurations.slow)
                .slideY(begin: 0.05, delay: d, duration: AppDurations.slow);
          }),
        ],
      ),
    );
  }
}
