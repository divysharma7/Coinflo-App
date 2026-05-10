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
        duration: SpendlerMotion.transition,
        curve: SpendlerMotion.surfaceCurve,
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
                  transitionDuration: SpendlerMotion.transition,
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
          transitionDuration: SpendlerMotion.transition,
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
      backgroundColor: SpendlerColors.scaffold,
      body: SafeArea(
        child: Column(
          children: [
            // Dot indicators
            Padding(
              padding: const EdgeInsets.all(SpendlerSpacing.lg),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_pageCount, (i) {
                  return AnimatedContainer(
                    duration: SpendlerMotion.transition,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: i == _currentPage ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == _currentPage
                          ? SpendlerColors.primary
                          : SpendlerColors.textTertiary,
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
        padding: const EdgeInsets.all(SpendlerSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '\$',
              style: SpendlerTextStyles.heroAmount.copyWith(
                fontSize: 80,
                color: SpendlerColors.primary,
              ),
            ),
            const SizedBox(height: SpendlerSpacing.lg),
            Text(
              'SPENDLER',
              style: SpendlerTextStyles.sectionLabel.copyWith(
                letterSpacing: 3.0,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: SpendlerSpacing.md),
            const Text(
              'Track your spending habits.',
              style: SpendlerTextStyles.onboardingBody,
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
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(SpendlerSpacing.xl),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight - SpendlerSpacing.xl * 2,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PhosphorIcon(
                  PhosphorIcons.user(),
                  color: SpendlerColors.primary,
                  size: 48,
                ),
                const SizedBox(height: SpendlerSpacing.lg),
                const Text(
                  'What should we\ncall you?',
                  style: SpendlerTextStyles.onboardingHeadline,
                ),
                const SizedBox(height: SpendlerSpacing.lg),
                TextField(
                  controller: controller,
                  autofocus: true,
                  style: SpendlerTextStyles.greeting,
                  cursorColor: SpendlerColors.primary,
                  decoration: const InputDecoration(
                    hintText: 'Your first name',
                    hintStyle: TextStyle(
                      color: SpendlerColors.textTertiary,
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                    border: UnderlineInputBorder(
                      borderSide: BorderSide(color: SpendlerColors.border),
                    ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: SpendlerColors.border),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: SpendlerColors.primary),
                    ),
                  ),
                  textCapitalization: TextCapitalization.words,
                  onSubmitted: (_) => onNext(),
                ),
                const SizedBox(height: SpendlerSpacing.xl),
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: onNext,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: SpendlerSpacing.md,
                        vertical: SpendlerSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: SpendlerColors.primary,
                        borderRadius: BorderRadius.circular(SpendlerRadii.pill),
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
          ),
        );
      },
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
        padding: const EdgeInsets.all(SpendlerSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PhosphorIcon(
              PhosphorIcons.chatText(),
              color: SpendlerColors.primary,
              size: 48,
            ),
            const SizedBox(height: SpendlerSpacing.lg),
            const Text(
              'Your spending,\nautomatically tracked.',
              style: SpendlerTextStyles.onboardingHeadline,
            ),
            const SizedBox(height: SpendlerSpacing.md),
            const Text(
              'Every bank SMS gets parsed instantly.\nYou just confirm.',
              style: SpendlerTextStyles.onboardingBody,
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
        padding: const EdgeInsets.all(SpendlerSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PhosphorIcon(
              PhosphorIcons.calendarCheck(),
              color: SpendlerColors.primary,
              size: 48,
            ),
            const SizedBox(height: SpendlerSpacing.lg),
            const Text(
              'A weekly mirror\nfor your money.',
              style: SpendlerTextStyles.onboardingHeadline,
            ),
            const SizedBox(height: SpendlerSpacing.md),
            const Text(
              'No budgets. No guilt.\nJust clear, honest awareness.',
              style: SpendlerTextStyles.onboardingBody,
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
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(SpendlerSpacing.xl),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight - SpendlerSpacing.xl * 2,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PhosphorIcon(
                  isGuideMode
                      ? PhosphorIcons.checkCircle()
                      : PhosphorIcons.rocketLaunch(),
                  color: SpendlerColors.primary,
                  size: 48,
                ),
                const SizedBox(height: SpendlerSpacing.lg),
                Text(
                  isGuideMode ? 'That\'s the whole idea.' : 'Let\'s get started.',
                  style: SpendlerTextStyles.onboardingHeadline,
                ),
                const SizedBox(height: SpendlerSpacing.md),
                Text(
                  isGuideMode
                      ? 'SMS gets parsed, you confirm,\nand your weekly rhythm appears.'
                      : 'Allow SMS access and we\'ll\nhandle the rest.',
                  style: SpendlerTextStyles.onboardingBody,
                ),
                const SizedBox(height: SpendlerSpacing.xxl),
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
                  const SizedBox(height: SpendlerSpacing.md),
                  Center(
                    child: TextButton(
                      onPressed: () => onFinish(requestSms: false),
                      child: const Text(
                        'I\'ll add manually',
                        style: TextStyle(
                          color: SpendlerColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
