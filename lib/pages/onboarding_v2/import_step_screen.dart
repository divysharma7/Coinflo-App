import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:finance_buddy_app/core/enums.dart';
import 'package:finance_buddy_app/design_system/design_system.dart';
import 'package:finance_buddy_app/providers/import_provider.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Optional onboarding step offering bank statement import.
/// Sits between Add Accounts (step2) and Monthly Budget (step3).
class ImportStepScreen extends ConsumerStatefulWidget {
  const ImportStepScreen({super.key});

  @override
  ConsumerState<ImportStepScreen> createState() => _ImportStepScreenState();
}

class _ImportStepScreenState extends ConsumerState<ImportStepScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _enterController;
  late final Animation<double> _titleFade;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _contentFade;

  @override
  void initState() {
    super.initState();
    _enterController = AnimationController(
      vsync: this,
      duration: AppDurations.entrance,
    );
    _titleFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _enterController, curve: const Interval(0, 0.6, curve: Curves.easeOut)),
    );
    _titleSlide = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(
      CurvedAnimation(parent: _enterController, curve: const Interval(0, 0.6, curve: Curves.easeOut)),
    );
    _contentFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _enterController, curve: const Interval(0.3, 1.0, curve: Curves.easeOut)),
    );
    _enterController.forward();
  }

  @override
  void dispose() {
    _enterController.dispose();
    super.dispose();
  }

  Future<void> _onImport() async {
    ref.read(importFlowControllerProvider.notifier).setSource(ImportSource.onboarding);
    await context.push('/import');

    // After returning from import flow, record and advance.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_did_import', true);
    if (mounted) await context.push('/onboarding/step3');
  }

  Future<void> _onSkip() async {
    if (mounted) await context.push('/onboarding/step3');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.md),
              _buildProgressIndicator(),
              const SizedBox(height: AppSpacing.md),
              AppBackButton(onTap: () => context.pop()),
              const SizedBox(height: AppSpacing.xl),
              SlideTransition(
                position: _titleSlide,
                child: FadeTransition(
                  opacity: _titleFade,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Got 6 months of bank data?', style: AppTextStyles.headingL),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Import your statement and CoinFlo will set up your budgets, find your subscriptions, and show your real spending pattern.',
                        style: AppTextStyles.bodyM.copyWith(color: AppColors.gray500),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              FadeTransition(
                opacity: _contentFade,
                child: AppCard(
                  child: Column(
                    children: [
                      _unlockRow(PhosphorIcons.chartBar(), 'Real spending charts from day 1'),
                      const SizedBox(height: AppSpacing.md),
                      _unlockRow(PhosphorIcons.repeat(), 'Auto-detect your subscriptions'),
                      const SizedBox(height: AppSpacing.md),
                      _unlockRow(PhosphorIcons.target(), 'Budget baselines from real data'),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              AppButton(
                label: 'Import statement',
                onTap: _onImport,
              ),
              const SizedBox(height: AppSpacing.sm),
              AppButton(
                label: 'Maybe later',
                variant: AppButtonVariant.ghost,
                onTap: _onSkip,
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _unlockRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.green),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(text, style: AppTextStyles.bodyM)),
      ],
    );
  }

  Widget _buildProgressIndicator() {
    // This step is optional — show 8 segments like existing onboarding, step 2 of 8 filled.
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(8, (index) {
        return Container(
          width: 24,
          height: 3,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: index < 2 ? AppColors.black : AppColors.gray200,
            borderRadius: AppRadius.full,
          ),
        );
      }),
    );
  }
}
