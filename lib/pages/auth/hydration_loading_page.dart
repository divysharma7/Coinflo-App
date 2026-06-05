import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:finance_buddy_app/design_system/design_system.dart';
import 'package:finance_buddy_app/providers/hydration_provider.dart';

/// Branded loading screen shown after sign-in while Firestore data is hydrated
/// into the local database. Surfaces an explicit error state with retry and a
/// "continue on this device" escape hatch instead of a bare spinner. (ISSUE 8)
class HydrationLoadingPage extends ConsumerStatefulWidget {
  const HydrationLoadingPage({super.key, required this.uid});

  final String uid;

  @override
  ConsumerState<HydrationLoadingPage> createState() =>
      _HydrationLoadingPageState();
}

class _HydrationLoadingPageState extends ConsumerState<HydrationLoadingPage> {
  bool _navigated = false;

  @override
  Widget build(BuildContext context) {
    final phase = ref.watch(hydrationControllerProvider(widget.uid));

    // Navigate home once hydration succeeds (post-frame to avoid nav-in-build).
    if (phase == HydrationPhase.success && !_navigated) {
      _navigated = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/home');
      });
    }

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: phase == HydrationPhase.error
                ? _buildError(context)
                : _buildLoading(),
          ),
        ),
      ),
    );
  }

  Widget _brandCoin() => Container(
        width: 80,
        height: 80,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.heroGradientTop, AppColors.black],
          ),
          boxShadow: AppShadows.hero,
        ),
        child: const Icon(
          Icons.currency_rupee_rounded,
          color: AppColors.white,
          size: 36,
        ),
      );

  Widget _buildLoading() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _brandCoin(),
        const SizedBox(height: AppSpacing.xl),
        Text(
          'Setting up your account…',
          style: AppTextStyles.headingS.copyWith(color: AppColors.black),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.lg),
        const SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: AppColors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildError(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _brandCoin(),
        const SizedBox(height: AppSpacing.xl),
        Text(
          "Couldn't sync your data",
          style: AppTextStyles.headingS.copyWith(color: AppColors.black),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Check your connection and try again, or continue on this device '
          'for now — your cloud data will still be there next time.',
          style: AppTextStyles.bodyM.copyWith(color: AppColors.gray500),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xl),
        AppButton(
          label: 'Retry',
          onTap: () =>
              ref.read(hydrationControllerProvider(widget.uid).notifier).run(),
        ),
        const SizedBox(height: AppSpacing.sm),
        AppButton(
          variant: AppButtonVariant.ghost,
          label: 'Skip, continue on this device',
          onTap: () => _skip(context),
        ),
      ],
    );
  }

  Future<void> _skip(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    // Let the user into the app and remember they opted out of cloud sync so
    // we don't keep forcing a retry on subsequent launches.
    await prefs.setBool('onboarding_completed', true);
    await prefs.setBool('local_only_mode', true);
    if (context.mounted) context.go('/home');
  }
}
