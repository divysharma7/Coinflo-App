import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:finance_buddy_app/design_system/design_system.dart';
import 'package:finance_buddy_app/providers/auth_provider.dart';
import 'package:finance_buddy_app/providers/onboarding_provider.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage>
    with TickerProviderStateMixin {
  late final AnimationController _waveCtrl;
  late final AnimationController _fadeCtrl;
  late final Animation<double> _waveAnim;
  late final Animation<double> _wordmarkFade;
  late final Animation<double> _taglineFade;

  @override
  void initState() {
    super.initState();

    // Waveform draws over 800ms
    _waveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _waveAnim = CurvedAnimation(parent: _waveCtrl, curve: Curves.easeInOut);

    // Wordmark + tagline fade in after waveform
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _wordmarkFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _fadeCtrl,
        curve: const Interval(0, 0.5, curve: Curves.easeIn),
      ),
    );
    _taglineFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _fadeCtrl,
        curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
      ),
    );

    _startSequence();
  }

  Future<void> _startSequence() async {
    // Draw waveform
    await _waveCtrl.forward();
    // Fade in text
    await _fadeCtrl.forward();
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;

    if (kDebugMode) {
      // ── Debug mode: skip auth but respect onboarding ──
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', 'test_hardcoded_token');
      await prefs.setString('user_uid', 'test_user_123');

      final onboardingDone = prefs.getBool('onboarding_completed') ?? false;
      if (!mounted) return;

      if (onboardingDone) {
        context.go('/home');
      } else {
        context.go('/onboarding/step1');
      }
    } else {
      // ── Release mode: real auth flow ──
      final isReturning = await ref.read(isReturningUserProvider.future);
      final onboardingDone = await ref.read(hasCompletedOnboardingProvider.future);
      if (!mounted) return;

      if (isReturning && onboardingDone) {
        context.go('/home');
      } else {
        context.go('/onboarding/step1');
      }
    }
  }

  @override
  void dispose() {
    _waveCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // App icon — black rounded square with checkmark
            AnimatedBuilder(
              animation: _waveAnim,
              builder: (context, _) {
                return Transform.scale(
                  scale: _waveAnim.value,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
                      color: AppColors.black,
                      borderRadius: AppRadius.xl,
                    ),
                    child: const Icon(
                      Icons.attach_money,
                      size: 40,
                      color: AppColors.white,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.xl),

            // Wordmark
            FadeTransition(
              opacity: _wordmarkFade,
              child: Text(
                'COINFLO',
                style: AppTextStyles.headingL.copyWith(
                  color: AppColors.black,
                  letterSpacing: 4,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),

            // Tagline
            FadeTransition(
              opacity: _taglineFade,
              child: Text(
                'Track your spending habits.',
                style: AppTextStyles.bodyM.copyWith(
                  color: AppColors.gray500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

