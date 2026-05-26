import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dart:convert';

import 'package:drift/drift.dart' as drift;
import 'package:finance_buddy_app/data/db.dart';
import 'package:finance_buddy_app/design_system/design_system.dart';
import 'package:finance_buddy_app/providers/auth_provider.dart';
import 'package:finance_buddy_app/providers/providers.dart';
import 'package:lottie/lottie.dart';

class CompletionScreen extends ConsumerStatefulWidget {
  const CompletionScreen({super.key});

  @override
  ConsumerState<CompletionScreen> createState() => _CompletionScreenState();
}

class _CompletionScreenState extends ConsumerState<CompletionScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _enterController;
  late final Animation<double> _checkScale;
  late final Animation<double> _titleFade;
  late final Animation<double> _subtitleFade;
  late final Animation<double> _cardFade;
  late final Animation<Offset> _cardSlide;
  late final Animation<double> _buttonFade;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;

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
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _onCreateAccount() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    // Validate inputs
    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Please enter your email and password.');
      return;
    }
    if (password.length < 6) {
      setState(() => _errorMessage = 'Password must be at least 6 characters.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Save name to local storage before Firebase sync picks it up
    final name = _nameController.text.trim();
    if (name.isNotEmpty) {
      await saveUserName(name);
    }

    try {
      // Try Firebase signup — but continue without it
      bool firebaseSignupFailed = false;
      try {
        final authService = ref.read(authServiceProvider);
        final user = await authService.signUpWithEmail(email, password);
        if (user != null) {
          final firestoreService = ref.read(firestoreServiceProvider);
          await firestoreService.createUserWithOnboardingData(
            uid: user.uid,
            email: email,
          );
        }
      } on FirebaseAuthException catch (e) {
        debugPrint('Firebase signup skipped: ${e.message}');
        firebaseSignupFailed = true;
      } on Exception catch (e) {
        // Firestore or other errors — continue with local-only mode
        debugPrint('Firestore sync failed: $e');
        firebaseSignupFailed = true;
      }

      // Mark onboarding complete locally and save email
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_completed', true);
      await prefs.setString('user_email', email);

      // Sync onboarding data from SharedPreferences into the Drift database
      // so Plan page (which reads from Drift) shows the user's budgets and goals.
      final repo = ref.read(repositoryProvider);
      await _syncBudgetsToDrift(prefs, repo);
      await _syncGoalsToDrift(prefs, repo);

      // Refresh providers so home page reads the freshly-saved onboarding data
      ref.invalidate(monthlyBudgetProvider);
      ref.invalidate(selectedCurrencyProvider);
      ref.invalidate(userNameProvider);
      ref.invalidate(userEmailProvider);
      ref.invalidate(hasCompletedOnboardingProvider);

      if (mounted) {
        if (firebaseSignupFailed) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Account created locally. Cloud backup unavailable.'),
            ),
          );
        }
        context.go('/home');
      }
    } on Exception catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
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
            AppBackButton(onTap: () => context.pop()),

            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Column(
                  children: [
                    const SizedBox(height: AppSpacing.xl),

                    // Checkmark animation
                    ScaleTransition(
                      scale: _checkScale,
                      child: SizedBox(
                        width: 80,
                        height: 80,
                        child: Lottie.asset(
                          'assets/lottie/onboarding_done.json',
                          repeat: false,
                        ),
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
                        "Create your account so your data is\nsafely backed up and synced across devices.",
                        style: AppTextStyles.bodyM
                            .copyWith(color: AppColors.gray500),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xxl),

                    // Email & password fields + trust card
                    SlideTransition(
                      position: _cardSlide,
                      child: FadeTransition(
                        opacity: _cardFade,
                        child: Column(
                          children: [
                            // Name field
                            _buildTextField(
                              controller: _nameController,
                              hint: 'What should we call you?',
                              icon: Icons.person_outline,
                              keyboardType: TextInputType.name,
                            ),

                            const SizedBox(height: AppSpacing.md),

                            // Email field
                            _buildTextField(
                              controller: _emailController,
                              hint: 'Email address',
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                            ),

                            const SizedBox(height: AppSpacing.md),

                            // Password field
                            _buildTextField(
                              controller: _passwordController,
                              hint: 'Password (min 6 characters)',
                              icon: Icons.lock_outline,
                              obscure: _obscurePassword,
                              suffixIcon: GestureDetector(
                                onTap: () => setState(
                                    () => _obscurePassword = !_obscurePassword),
                                child: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: AppColors.gray400,
                                  size: 20,
                                ),
                              ),
                            ),

                            // Error message
                            if (_errorMessage != null) ...[
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                _errorMessage!,
                                style: AppTextStyles.bodyS
                                    .copyWith(color: AppColors.red),
                                textAlign: TextAlign.center,
                              ),
                            ],

                            const SizedBox(height: AppSpacing.xl),

                            // Trust points card
                            AppCard(
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
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
            ),

            // Create Account button + Skip
            FadeTransition(
              opacity: _buttonFade,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.sm,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 52,
                        child: Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: AppColors.black,
                            ),
                          ),
                        ),
                      )
                    : AppButton(
                        label: 'Create Account',
                        onTap: _onCreateAccount,
                      ),
              ),
            ),

            // Already have an account
            GestureDetector(
              onTap: () => context.push('/sign-in'),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Text.rich(
                  TextSpan(
                    text: 'Already have an account? ',
                    style: AppTextStyles.bodyS.copyWith(color: AppColors.gray500),
                    children: [
                      TextSpan(
                        text: 'Sign in',
                        style: AppTextStyles.bodyS.copyWith(
                          color: AppColors.black,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscure = false,
    Widget? suffixIcon,
  }) {
    return Container(
      height: 52,
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: AppRadius.md,
        boxShadow: AppShadows.sm,
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        style: AppTextStyles.bodyM.copyWith(color: AppColors.black),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTextStyles.bodyM.copyWith(color: AppColors.gray400),
          prefixIcon: Icon(icon, color: AppColors.gray400, size: 20),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
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

  /// Insert onboarding category budgets from SharedPreferences into Drift.
  Future<void> _syncBudgetsToDrift(SharedPreferences prefs, dynamic repo) async {
    final json = prefs.getString('category_budgets');
    if (json == null) return;
    try {
      final list = (jsonDecode(json) as List).cast<Map<String, dynamic>>();
      for (final b in list) {
        // Onboarding model uses 'group', Drift uses 'category'.
        final category = b['group'] as String? ?? '';
        final limit = (b['monthlyLimit'] as num?)?.toDouble() ?? 0;
        if (category.isEmpty || limit <= 0) continue;
        await repo.insertBudget(CategoryBudgetsCompanion(
          category: drift.Value(category),
          monthlyLimit: drift.Value(limit),
        ));
      }
    } on Exception catch (e) {
      debugPrint('Budget sync to Drift failed: $e');
    }
  }

  /// Insert onboarding savings goals from SharedPreferences into Drift.
  Future<void> _syncGoalsToDrift(SharedPreferences prefs, dynamic repo) async {
    final json = prefs.getString('savings_goals');
    if (json == null) return;
    try {
      final list = (jsonDecode(json) as List).cast<Map<String, dynamic>>();
      for (final g in list) {
        final name = g['name'] as String? ?? '';
        final target = (g['targetAmount'] as num?)?.toDouble() ?? 0;
        final icon = g['iconAsset'] as String? ?? 'star';
        if (name.isEmpty || target <= 0) continue;
        await repo.insertGoal(SavingsGoalsCompanion(
          name: drift.Value(name),
          targetAmount: drift.Value(target),
          iconName: drift.Value(icon),
        ));
      }
    } on Exception catch (e) {
      debugPrint('Goals sync to Drift failed: $e');
    }
  }
}
