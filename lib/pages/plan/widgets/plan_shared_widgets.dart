import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:finance_buddy_app/design_system/design_system.dart';

class PlanEmptyCard extends StatelessWidget {
  const PlanEmptyCard({super.key, required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.xxl,
      ),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: AppRadius.lg,
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        children: [
          PhosphorIcon(icon, size: 32, color: AppColors.gray500),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyS.copyWith(
              color: AppColors.gray500,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class PlanLoadingCard extends StatefulWidget {
  const PlanLoadingCard({super.key});

  @override
  State<PlanLoadingCard> createState() => _PlanLoadingCardState();
}

class _PlanLoadingCardState extends State<PlanLoadingCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmerCtrl;

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: AppDurations.shimmer,
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmerCtrl,
      builder: (context, child) {
        final shimmerValue = _shimmerCtrl.value;
        final baseColor = AppColors.gray200;
        final highlightColor = AppColors.gray100;
        final color = Color.lerp(
          baseColor,
          highlightColor,
          (0.5 + 0.5 * (shimmerValue * 2 - 1).abs()).clamp(0.0, 1.0),
        )!;
        return Column(
          children: [
            _SkeletonCard(color: color),
            const SizedBox(height: AppSpacing.sm),
            _SkeletonCard(color: color),
          ],
        );
      },
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: AppRadius.lg,
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Icon placeholder
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: AppRadius.sm,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Title placeholder
              Expanded(
                child: Container(
                  height: 14,
                  width: 100,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: AppRadius.xs,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xl),
              // Amount placeholder
              Container(
                height: 12,
                width: 60,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: AppRadius.xs,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          // Progress bar placeholder
          Container(
            height: 6,
            width: double.infinity,
            decoration: BoxDecoration(
              color: color,
              borderRadius: AppRadius.xxs,
            ),
          ),
        ],
      ),
    );
  }
}
