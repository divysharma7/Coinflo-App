import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:finance_buddy_app/core/enums.dart';
import 'package:finance_buddy_app/design_system/design_system.dart';
import 'package:finance_buddy_app/pages/import/widgets/import_progress_indicator.dart';
import 'package:finance_buddy_app/providers/import_provider.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class SummaryPage extends ConsumerStatefulWidget {
  const SummaryPage({super.key});

  @override
  ConsumerState<SummaryPage> createState() => _SummaryPageState();
}

class _SummaryPageState extends ConsumerState<SummaryPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _enterController;
  late final Animation<double> _heroFade;
  late final Animation<double> _cardsFade;

  @override
  void initState() {
    super.initState();
    _enterController = AnimationController(
      vsync: this,
      duration: AppDurations.entrance,
    );
    _heroFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _enterController, curve: const Interval(0, 0.5, curve: Curves.easeOut)),
    );
    _cardsFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _enterController, curve: const Interval(0.3, 1.0, curve: Curves.easeOut)),
    );
    _enterController.forward();
  }

  @override
  void dispose() {
    _enterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(importFlowControllerProvider);
    final batch = state.completedBatch;
    final txnCount = batch?.transactionCount ?? 0;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.offWhite,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: AppSpacing.md),
                const ImportProgressIndicator(currentStep: 5),
                const Spacer(),
                FadeTransition(
                  opacity: _heroFade,
                  child: Column(
                    children: [
                      Icon(
                        PhosphorIcons.checkCircle(),
                        size: 64,
                        color: AppColors.green,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        '$txnCount transactions imported',
                        style: AppTextStyles.displayL,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        batch != null
                            ? '${batch.bankName.toUpperCase()} • ${batch.fileName}'
                            : '',
                        style: AppTextStyles.bodyM.copyWith(color: AppColors.gray500),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                FadeTransition(
                  opacity: _cardsFade,
                  child: Column(
                    children: [
                      _HighlightCard(
                        icon: PhosphorIcons.repeat(),
                        text: 'Found subscriptions in your history',
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      if (batch != null && batch.categorizedCount > 0)
                        _HighlightCard(
                          icon: PhosphorIcons.tag(),
                          text: '${batch.categorizedCount} auto-categorized',
                        ),
                      const SizedBox(height: AppSpacing.sm),
                      _HighlightCard(
                        icon: PhosphorIcons.chartBar(),
                        text: 'Budget baseline calculated',
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                AppButton(
                  label: 'See my home screen',
                  onTap: () {
                    final source = ref.read(importFlowControllerProvider).source;
                    ref.read(importFlowControllerProvider.notifier).reset();
                    switch (source) {
                      case ImportSource.onboarding:
                        // Pop back to import_step_screen which advances to step3.
                        Navigator.of(context).pop();
                      default:
                        context.go('/home');
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                AppButton(
                  label: 'View import details',
                  variant: AppButtonVariant.ghost,
                  onTap: () => context.push('/import/history'),
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HighlightCard extends StatelessWidget {
  final IconData icon;
  final String text;

  const _HighlightCard({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.black),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(text, style: AppTextStyles.bodyM)),
        ],
      ),
    );
  }
}
