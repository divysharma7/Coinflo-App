import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:finance_buddy_app/core/tokens.dart';
import 'package:finance_buddy_app/providers/onboarding_provider.dart';
import 'package:finance_buddy_app/widgets/common/neo_pop_button.dart';
import 'package:finance_buddy_app/pages/onboarding/sms_permission_page.dart';
import 'package:finance_buddy_app/pages/shell_page.dart';

class OnboardingPage extends StatefulWidget {
  /// When true, acts as a revisitable guide (no permission request, pops back).
  final bool isGuideMode;

  const OnboardingPage({super.key, this.isGuideMode = false});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _pageController = PageController();
  final _nameController = TextEditingController();
  int _currentPage = 0;

  // 5 screens in onboarding, 4 in guide mode (skip name)
  int get _pageCount => widget.isGuideMode ? 4 : 5;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentPage < _pageCount - 1) {
      _pageController.nextPage(
        duration: PaisaMotion.transition,
        curve: PaisaMotion.surfaceCurve,
      );
    }
  }

  Future<void> _finish({bool requestSms = false}) async {
    if (widget.isGuideMode) {
      Navigator.pop(context);
      return;
    }
    // Save name if entered
    final name = _nameController.text.trim();
    if (name.isNotEmpty) {
      await saveUserName(name);
    }
    await completeOnboarding();
    if (!mounted) return;

    if (requestSms) {
      // Navigate to dedicated SMS permission page with full rationale
      await Navigator.pushReplacement<void, void>(
        context,
        MaterialPageRoute<void>(
          builder: (_) => SmsPermissionPage(
            onComplete: () {
              Navigator.pushReplacement(
                context,
                PageRouteBuilder<void>(
                  pageBuilder: (ctx, anim, secAnim) => const ShellPage(),
                  transitionDuration: PaisaMotion.transition,
                  transitionsBuilder: (ctx, anim, secAnim, child) =>
                      FadeTransition(opacity: anim, child: child),
                ),
              );
            },
          ),
        ),
      );
    } else {
      await Navigator.pushReplacement<void, void>(
        context,
        PageRouteBuilder<void>(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const ShellPage(),
          transitionDuration: PaisaMotion.transition,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PaisaColors.scaffold,
      body: SafeArea(
        child: Column(
          children: [
            // Dot indicators
            Padding(
              padding: const EdgeInsets.all(PaisaSpacing.lg),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_pageCount, (i) {
                  return AnimatedContainer(
                    duration: PaisaMotion.transition,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: i == _currentPage ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == _currentPage
                          ? PaisaColors.yellow
                          : PaisaColors.textTertiary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),
            // Pages
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _currentPage = i),
                physics: const BouncingScrollPhysics(),
                children: [
                  _ScreenIdentity(onNext: _next),
                  if (!widget.isGuideMode)
                    _ScreenName(
                      controller: _nameController,
                      onNext: _next,
                    ),
                  _ScreenPromise(onNext: _next),
                  _ScreenMirror(onNext: _next),
                  _ScreenStart(
                    onFinish: _finish,
                    isGuideMode: widget.isGuideMode,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Screen: Identity ────────────────────────────────

class _ScreenIdentity extends StatelessWidget {
  const _ScreenIdentity({required this.onNext});
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onNext,
      child: Padding(
        padding: const EdgeInsets.all(PaisaSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '₹',
              style: PaisaTextStyles.heroAmount.copyWith(
                fontSize: 80,
                color: PaisaColors.yellow,
              ),
            ),
            const SizedBox(height: PaisaSpacing.lg),
            Text(
              'PULSE',
              style: PaisaTextStyles.sectionLabel.copyWith(
                letterSpacing: 3.0,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: PaisaSpacing.md),
            const Text(
              'Feel your financial rhythm.',
              style: PaisaTextStyles.onboardingBody,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Screen: What's your name? ───────────────────────

class _ScreenName extends StatelessWidget {
  const _ScreenName({required this.controller, required this.onNext});
  final TextEditingController controller;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(PaisaSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PhosphorIcon(
            PhosphorIcons.user(),
            color: PaisaColors.yellow,
            size: 48,
          ),
          const SizedBox(height: PaisaSpacing.lg),
          const Text(
            'What should we\ncall you?',
            style: PaisaTextStyles.onboardingHeadline,
          ),
          const SizedBox(height: PaisaSpacing.lg),
          TextField(
            controller: controller,
            autofocus: true,
            style: PaisaTextStyles.greeting,
            cursorColor: PaisaColors.yellow,
            decoration: const InputDecoration(
              hintText: 'Your first name',
              hintStyle: TextStyle(
                color: PaisaColors.textTertiary,
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
              border: UnderlineInputBorder(
                borderSide: BorderSide(color: PaisaColors.border),
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: PaisaColors.border),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: PaisaColors.yellow),
              ),
            ),
            textCapitalization: TextCapitalization.words,
            onSubmitted: (_) => onNext(),
          ),
          const SizedBox(height: PaisaSpacing.xl),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: onNext,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: PaisaSpacing.md,
                  vertical: PaisaSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: PaisaColors.yellow,
                  borderRadius: BorderRadius.circular(PaisaRadii.pill),
                ),
                child: const Text(
                  'Next →',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Screen: SMS Promise ─────────────────────────────

class _ScreenPromise extends StatelessWidget {
  const _ScreenPromise({required this.onNext});
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onNext,
      child: Padding(
        padding: const EdgeInsets.all(PaisaSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PhosphorIcon(
              PhosphorIcons.chatText(),
              color: PaisaColors.yellow,
              size: 48,
            ),
            const SizedBox(height: PaisaSpacing.lg),
            const Text(
              'Your spending,\nautomatically tracked.',
              style: PaisaTextStyles.onboardingHeadline,
            ),
            const SizedBox(height: PaisaSpacing.md),
            const Text(
              'Every bank SMS gets parsed instantly.\nYou just confirm.',
              style: PaisaTextStyles.onboardingBody,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Screen: Weekly Mirror ───────────────────────────

class _ScreenMirror extends StatelessWidget {
  const _ScreenMirror({required this.onNext});
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onNext,
      child: Padding(
        padding: const EdgeInsets.all(PaisaSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PhosphorIcon(
              PhosphorIcons.calendarCheck(),
              color: PaisaColors.yellow,
              size: 48,
            ),
            const SizedBox(height: PaisaSpacing.lg),
            const Text(
              'A weekly mirror\nfor your money.',
              style: PaisaTextStyles.onboardingHeadline,
            ),
            const SizedBox(height: PaisaSpacing.md),
            const Text(
              'No budgets. No guilt.\nJust clear, honest awareness.',
              style: PaisaTextStyles.onboardingBody,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Screen: Permission + Start ──────────────────────

class _ScreenStart extends StatelessWidget {
  const _ScreenStart({required this.onFinish, this.isGuideMode = false});
  final Future<void> Function({bool requestSms}) onFinish;
  final bool isGuideMode;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(PaisaSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PhosphorIcon(
            isGuideMode
                ? PhosphorIcons.checkCircle()
                : PhosphorIcons.rocketLaunch(),
            color: PaisaColors.yellow,
            size: 48,
          ),
          const SizedBox(height: PaisaSpacing.lg),
          Text(
            isGuideMode ? 'That\'s the whole idea.' : 'Let\'s get started.',
            style: PaisaTextStyles.onboardingHeadline,
          ),
          const SizedBox(height: PaisaSpacing.md),
          Text(
            isGuideMode
                ? 'SMS gets parsed, you confirm,\nand your weekly rhythm appears.'
                : 'Allow SMS access and we\'ll\nhandle the rest.',
            style: PaisaTextStyles.onboardingBody,
          ),
          const SizedBox(height: PaisaSpacing.xxl),
          if (isGuideMode)
            NeoPOPButton(
              label: 'Got it',
              onTap: () => onFinish(),
            )
          else ...[
            NeoPOPButton(
              label: 'Allow SMS Access',
              onTap: () {
                HapticFeedback.mediumImpact();
                onFinish(requestSms: true);
              },
            ),
            const SizedBox(height: PaisaSpacing.md),
            Center(
              child: TextButton(
                onPressed: () => onFinish(requestSms: false),
                child: const Text(
                  'I\'ll add manually',
                  style: TextStyle(
                    color: PaisaColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
