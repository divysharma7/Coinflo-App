import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:finance_buddy_app/design_system/design_system.dart';
import 'package:finance_buddy_app/providers/auth_provider.dart';
import 'package:finance_buddy_app/providers/onboarding_provider.dart';
import 'package:finance_buddy_app/pages/splash/widgets/spinning_coin.dart';
import 'package:finance_buddy_app/pages/splash/widgets/rocket_trail_painter.dart';
import 'package:finance_buddy_app/pages/splash/widgets/coinflo_logo.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage>
    with SingleTickerProviderStateMixin {
  static const _totalDuration = Duration(milliseconds: 2700);

  late final AnimationController _ctrl;

  // Phase 1a: Coin scale in (0.00 – 0.15)
  late final Animation<double> _coinScale;
  // Phase 1b: Coin Y-rotation (0.15 – 0.44)
  late final Animation<double> _coinRotation;
  // Phase 2: Rocket launch (0.44 – 0.81)
  late final Animation<double> _rocketProgress;
  late final Animation<double> _rocketScale;
  late final Animation<double> _rocketTilt;
  // Phase 3: Logo fade + screen exit (0.81 – 1.0)
  late final Animation<double> _logoOpacity;
  late final Animation<double> _exitOpacity;
  late final Animation<Offset> _exitSlide;

  final _rng = Random(42);
  bool _navigated = false;

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(vsync: this, duration: _totalDuration);

    // Phase 1a: scale in with bounce
    _coinScale = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.15, curve: Curves.easeOutBack)),
    );

    // Phase 1b: 2 full Y rotations
    _coinRotation = Tween(begin: 0.0, end: 4 * pi).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.15, 0.44, curve: Curves.easeInOut)),
    );

    // Phase 2: rocket trail progress
    _rocketProgress = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.44, 0.81, curve: Curves.easeIn)),
    );
    _rocketScale = Tween(begin: 1.0, end: 0.5).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.44, 0.81, curve: Curves.easeIn)),
    );
    _rocketTilt = Tween(begin: 0.0, end: -25 * pi / 180).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.44, 0.55, curve: Curves.easeOut)),
    );

    // Phase 3: logo + exit
    _logoOpacity = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.81, 0.90, curve: Curves.easeOut)),
    );
    _exitOpacity = Tween(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.93, 1.0, curve: Curves.easeIn)),
    );
    _exitSlide = Tween(begin: Offset.zero, end: const Offset(0, -0.03)).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.93, 1.0, curve: Curves.easeIn)),
    );

    _ctrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) _navigate();
    });

    _start();
  }

  Future<void> _start() async {
    // Respect reduced-motion preference.
    final mq = WidgetsBinding.instance.platformDispatcher.accessibilityFeatures;
    if (mq.disableAnimations) {
      await Future<void>.delayed(const Duration(milliseconds: 800));
      await _navigate();
      return;
    }
    await _ctrl.forward();
  }

  void _skip() {
    if (_navigated) return;
    _ctrl.stop();
    _navigate();
  }

  Future<void> _navigate() async {
    if (_navigated || !mounted) return;
    _navigated = true;

    final prefs = await SharedPreferences.getInstance();
    await markFirstLaunchIfNeeded(prefs);
    final firebaseUid = FirebaseAuth.instance.currentUser?.uid;

    if (kDebugMode) {
      await prefs.setString('auth_token', 'test_hardcoded_token');
      await prefs.setString('user_uid', 'test_user_123');
      final onboardingDone = await resolveOnboardingStatus(prefs, firebaseUid);
      if (!mounted) return;
      context.go(onboardingDone ? '/home' : '/onboarding/step2');
    } else {
      final isReturning = await ref.read(isReturningUserProvider.future);
      final onboardingDone = await resolveOnboardingStatus(prefs, firebaseUid);
      if (!mounted) return;
      context.go((isReturning || onboardingDone) ? '/home' : '/onboarding/step2');
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final center = Offset(size.width / 2, size.height / 2);
    final exitPoint = Offset(size.width * 1.1, -50);
    final controlPt = Offset(size.width * 0.75, size.height * 0.15);

    // Read user's currency symbol.
    final currencyCode = ref.watch(selectedCurrencyProvider).valueOrNull ?? 'inr';
    final symbol = _symbolFor(currencyCode);

    return GestureDetector(
      onTap: _skip,
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: AnimatedBuilder(
          animation: _ctrl,
          builder: (context, _) {
            // Coin position along Bezier (Phase 2).
            final rp = _rocketProgress.value;
            final coinPos = rp > 0 ? _bezier(center, controlPt, exitPoint, rp) : center;

            // Particles.
            final particles = rp > 0
                ? generateParticles(
                    start: center,
                    controlPoint: controlPt,
                    end: exitPoint,
                    trailProgress: rp,
                    count: 5,
                    rng: _rng,
                  )
                : <TrailParticle>[];

            return SlideTransition(
              position: _exitSlide,
              child: FadeTransition(
                opacity: _exitOpacity,
                child: Stack(
                  children: [
                    // Trail painter
                    if (rp > 0)
                      Positioned.fill(
                        child: CustomPaint(
                          painter: RocketTrailPainter(
                            start: center,
                            controlPoint: controlPt,
                            end: exitPoint,
                            progress: rp,
                            particles: particles,
                          ),
                        ),
                      ),

                    // Coin
                    Positioned(
                      left: coinPos.dx - 40,
                      top: coinPos.dy - 40,
                      child: Transform.scale(
                        scale: _coinScale.value * _rocketScale.value,
                        child: Transform.rotate(
                          angle: _rocketTilt.value,
                          child: SpinningCoin(
                            rotationY: _coinRotation.value,
                            symbol: symbol,
                          ),
                        ),
                      ),
                    ),

                    // Logo (fades in during Phase 3)
                    Center(
                      child: Padding(
                        padding: EdgeInsets.only(top: size.height * 0.15),
                        child: CoinFloLogo(opacity: _logoOpacity.value),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Offset _bezier(Offset p0, Offset p1, Offset p2, double t) {
    final mt = 1 - t;
    return p0 * (mt * mt) + p1 * (2 * mt * t) + p2 * (t * t);
  }

  static String _symbolFor(String code) {
    switch (code.toLowerCase()) {
      case 'inr': return '\u20B9';
      case 'usd': return '\$';
      case 'eur': return '\u20AC';
      case 'gbp': return '\u00A3';
      case 'jpy': return '\u00A5';
      default: return '\u20B9';
    }
  }
}
