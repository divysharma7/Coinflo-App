import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:finance_buddy_app/design_system/design_system.dart';
import 'package:finance_buddy_app/pages/shell_page.dart';

class CompletionScreen extends StatefulWidget {
  const CompletionScreen({super.key});

  @override
  State<CompletionScreen> createState() => _CompletionScreenState();
}

class _CompletionScreenState extends State<CompletionScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _enterController;
  late final Animation<double> _checkScale;
  late final Animation<double> _titleFade;
  late final Animation<double> _subtitleFade;
  late final Animation<double> _cardFade;
  late final Animation<Offset> _cardSlide;
  late final Animation<double> _buttonFade;

  @override
  void initState() {
    super.initState();

    _enterController = AnimationController(
      vsync: this,
      duration: AppDurations.slow,
    );

    _checkScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _enterController,
        curve: const Interval(0, 0.5, curve: Curves.elasticOut),
      ),
    );

    _titleFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _enterController,
        curve: const Interval(0.25, 0.55, curve: Curves.easeOut),
      ),
    );

    _subtitleFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _enterController,
        curve: const Interval(0.35, 0.65, curve: Curves.easeOut),
      ),
    );

    _cardFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _enterController,
        curve: const Interval(0.5, 0.8, curve: Curves.easeOut),
      ),
    );
    _cardSlide = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _enterController,
      curve: const Interval(0.5, 0.8, curve: Curves.easeOutCubic),
    ));

    _buttonFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _enterController,
        curve: const Interval(0.65, 1.0, curve: Curves.easeOut),
      ),
    );

    _enterController.forward();
  }

  @override
  void dispose() {
    _enterController.dispose();
    super.dispose();
  }

  Future<void> _onCreateAccount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    if (mounted) {
      await Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const ShellPage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator (all filled)
            Padding(
              padding: const EdgeInsets.only(
                top: AppSpacing.md,
                left: AppSpacing.lg,
                right: AppSpacing.lg,
              ),
              child: _buildProgressIndicator(),
            ),

            // Back button
            Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.md,
                top: AppSpacing.md,
              ),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const SizedBox(
                  width: 44,
                  height: 44,
                  child: Center(
                    child: Icon(
                      Icons.arrow_back_ios_new,
                      size: 20,
                      color: AppColors.black,
                    ),
                  ),
                ),
              ),
            ),

            // Centered content
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Checkmark icon
                    ScaleTransition(
                      scale: _checkScale,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: const BoxDecoration(
                          color: AppColors.black,
                          borderRadius: AppRadius.xl,
                        ),
                        child: const Icon(Icons.check,
                            color: AppColors.white, size: 40),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // Title
                    FadeTransition(
                      opacity: _titleFade,
                      child: Text(
                        "You're all set!",
                        style: AppTextStyles.headingL
                            .copyWith(color: AppColors.black),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.sm),

                    // Subtitle
                    FadeTransition(
                      opacity: _subtitleFade,
                      child: Text(
                        "Great choices! Now let's create your account\n"
                        'so your data is safely backed up and synced\nacross devices.',
                        style: AppTextStyles.bodyM
                            .copyWith(color: AppColors.gray500),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xxl),

                    // Trust points card
                    SlideTransition(
                      position: _cardSlide,
                      child: FadeTransition(
                        opacity: _cardFade,
                        child: AppCard(
                          child: Column(
                            children: [
                              _buildTrustRow(
                                Icons.shield_outlined,
                                'Your data is saved locally',
                              ),
                              const SizedBox(height: AppSpacing.md),
                              _buildTrustRow(
                                Icons.sync_outlined,
                                'Sign in to sync across devices',
                              ),
                              const SizedBox(height: AppSpacing.md),
                              _buildTrustRow(
                                Icons.lock_outline,
                                'Your data stays private and encrypted',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Create Account button
            FadeTransition(
              opacity: _buttonFade,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                child: AppButton(
                    label: 'Create Account', onTap: _onCreateAccount),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(8, (index) {
        return Container(
          width: 24,
          height: 3,
          margin: EdgeInsets.only(right: index < 7 ? AppSpacing.xs : 0),
          decoration: const BoxDecoration(
            color: AppColors.black,
            borderRadius: AppRadius.full,
          ),
        );
      }),
    );
  }

  Widget _buildTrustRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.black),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(text, style: AppTextStyles.bodyM),
        ),
      ],
    );
  }
}
