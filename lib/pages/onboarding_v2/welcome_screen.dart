import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:finance_buddy_app/design_system/design_system.dart';

/// 01 · Welcome — the dark, value-first opener.
///
/// Frames what CoinFlo does and the local-first promise *before* asking for any
/// data, so the very first screen isn't a blank form and trust is established up
/// front. The dark treatment bookends the flow (dark → light setup → dark
/// recap → light finish).
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _enter;
  late final Animation<double> _contentFade;
  late final Animation<Offset> _contentSlide;
  late final Animation<double> _cardFade;

  static const _bg = RadialGradient(
    center: Alignment(0.64, -1.06),
    radius: 1.3,
    colors: [Color(0xFF2D2D32), Color(0xFF141416), Color(0xFF0A0A0A)],
    stops: [0.0, 0.46, 1.0],
  );

  @override
  void initState() {
    super.initState();
    _enter = AnimationController(vsync: this, duration: AppDurations.slow);
    _contentFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _enter,
        curve: const Interval(0, 0.7, curve: Curves.easeOut),
      ),
    );
    _contentSlide =
        Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _enter,
            curve: const Interval(0, 0.7, curve: Curves.easeOutCubic),
          ),
        );
    _cardFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _enter,
        curve: const Interval(0.35, 1.0, curve: Curves.easeOut),
      ),
    );
    _enter.forward();
  }

  @override
  void dispose() {
    _enter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.black,
        body: DecoratedBox(
          decoration: const BoxDecoration(gradient: _bg),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.lg,
                AppSpacing.xl,
                AppSpacing.xl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _brandRow(),
                  const Spacer(),
                  FadeTransition(
                    opacity: _contentFade,
                    child: SlideTransition(
                      position: _contentSlide,
                      child: _valueBlock(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  FadeTransition(opacity: _cardFade, child: _trustCard()),
                  const SizedBox(height: AppSpacing.xl),
                  FadeTransition(opacity: _cardFade, child: _footer()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _brandRow() {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.07),
            borderRadius: AppRadius.base,
            border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
          ),
          child: const Icon(
            Icons.savings_outlined,
            color: AppColors.white,
            size: 22,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          'CoinFlo',
          style: AppTextStyles.headingM.copyWith(
            color: AppColors.white,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
          ),
        ),
      ],
    );
  }

  Widget _valueBlock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PERSONAL FINANCE · LOCAL-FIRST',
          style: AppTextStyles.labelS.copyWith(
            color: Colors.white.withValues(alpha: 0.38),
            fontWeight: FontWeight.w700,
            letterSpacing: 1.6,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Your money.\nYour rules.\nZero clutter.',
          style: AppTextStyles.displayL.copyWith(
            color: AppColors.white,
            fontSize: 37,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.5,
            height: 1.03,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Track spending, set budgets and save toward your '
          'goals — in a couple of taps a day.',
          style: AppTextStyles.bodyL.copyWith(
            color: Colors.white.withValues(alpha: 0.6),
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _trustCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: AppRadius.xl,
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          _trustRow(
            Icons.verified_user_outlined,
            'Saved on your device',
            'Works fully offline, no account needed',
          ),
          _trustDivider(),
          _trustRow(
            Icons.lock_outline,
            'Private & encrypted',
            'Your numbers stay yours',
          ),
          _trustDivider(),
          _trustRow(
            Icons.sync_outlined,
            'Optional cloud backup',
            'Sync across devices when you want',
          ),
        ],
      ),
    );
  }

  Widget _trustDivider() => Divider(
    height: 1,
    thickness: 1,
    color: Colors.white.withValues(alpha: 0.08),
  );

  Widget _trustRow(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: AppRadius.sm,
            ),
            child: Icon(icon, color: AppColors.white, size: 20),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyM.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: AppTextStyles.bodyS.copyWith(
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _footer() {
    return Column(
      children: [
        _GetStartedButton(onTap: () => context.push('/onboarding/currency')),
        const SizedBox(height: AppSpacing.md),
        Semantics(
          button: true,
          label: 'I already have an account',
          child: GestureDetector(
            onTap: () => context.push('/sign-in'),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Text(
                'I already have an account',
                style: AppTextStyles.bodyM.copyWith(
                  color: Colors.white.withValues(alpha: 0.65),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Inverted white CTA used only on the dark Welcome screen.
class _GetStartedButton extends StatefulWidget {
  const _GetStartedButton({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_GetStartedButton> createState() => _GetStartedButtonState();
}

class _GetStartedButtonState extends State<_GetStartedButton> {
  double _scale = 1;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Get started',
      child: GestureDetector(
        onTapDown: (_) => setState(() => _scale = 0.97),
        onTapUp: (_) => setState(() => _scale = 1),
        onTapCancel: () => setState(() => _scale = 1),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _scale,
          duration: AppDurations.fast,
          child: Container(
            width: double.infinity,
            height: 56,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.white,
              borderRadius: AppRadius.full,
              boxShadow: [
                BoxShadow(
                  color: Color(0x8C000000),
                  blurRadius: 30,
                  offset: Offset(0, 14),
                ),
              ],
            ),
            child: Text(
              'Get started',
              style: AppTextStyles.headingS.copyWith(color: AppColors.black),
            ),
          ),
        ),
      ),
    );
  }
}
