import 'dart:convert';

import 'package:drift/drift.dart' as drift;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:finance_buddy_app/data/db.dart';
import 'package:finance_buddy_app/data/repositories/base_repository.dart';
import 'package:finance_buddy_app/design_system/design_system.dart';
import 'package:finance_buddy_app/providers/auth_provider.dart';
import 'package:finance_buddy_app/providers/providers.dart';

/// 09 · Create account — backup, not a wall.
///
/// Everything already works locally, so account creation is clearly optional:
/// a prominent "Maybe later" drops the user straight into the app, while the
/// form remains for those who want cloud backup + cross-device sync.
class CompletionScreen extends ConsumerStatefulWidget {
  const CompletionScreen({super.key});

  @override
  ConsumerState<CompletionScreen> createState() => _CompletionScreenState();
}

class _CompletionScreenState extends ConsumerState<CompletionScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _enter;
  late final Animation<double> _heroScale;
  late final Animation<double> _fade;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;

  static const _heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2D2D31), AppColors.black],
  );

  @override
  void initState() {
    super.initState();
    _enter = AnimationController(vsync: this, duration: AppDurations.slow);
    _heroScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _enter,
        curve: const Interval(0, 0.5, curve: Curves.elasticOut),
      ),
    );
    _fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _enter,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );
    _enter.forward();
  }

  @override
  void dispose() {
    _enter.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Marks onboarding complete locally and mirrors prefs data into Drift so the
  /// Plan/Home pages see the user's budgets and goals. Shared by both the
  /// create-account path and the "Maybe later" path.
  Future<void> _finishLocally({String? email}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    if (email != null) await prefs.setString('user_email', email);

    final repo = ref.read(repositoryProvider);
    await _syncBudgetsToDrift(prefs, repo);
    await _syncGoalsToDrift(prefs, repo);

    ref.invalidate(monthlyBudgetProvider);
    ref.invalidate(selectedCurrencyProvider);
    ref.invalidate(userNameProvider);
    ref.invalidate(userEmailProvider);
    ref.invalidate(hasCompletedOnboardingProvider);
  }

  Future<void> _onMaybeLater() async {
    await _finishLocally();
    if (mounted) context.go('/home');
  }

  Future<void> _onCreateAccount() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

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

    try {
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
        debugPrint('Firestore sync failed: $e');
        firebaseSignupFailed = true;
      }

      await _finishLocally(email: email);

      if (mounted) {
        if (firebaseSignupFailed) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "You're set! Sign in later to enable cloud backup.",
              ),
            ),
          );
        }
        context.go('/home');
      }
    } on Exception catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Column(
                  children: [
                    const SizedBox(height: AppSpacing.xxl),
                    ScaleTransition(
                      scale: _heroScale,
                      child: Container(
                        width: 66,
                        height: 66,
                        decoration: const BoxDecoration(
                          gradient: _heroGradient,
                          borderRadius: AppRadius.lg,
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x8C0A0A0A),
                              blurRadius: 32,
                              offset: Offset(0, 16),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.check,
                          color: AppColors.white,
                          size: 33,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    FadeTransition(
                      opacity: _fade,
                      child: Column(
                        children: [
                          Text(
                            "You're all set!",
                            style: AppTextStyles.headingL.copyWith(
                              color: AppColors.black,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'Create an account to back up your data and sync '
                            'across devices — totally optional.',
                            style: AppTextStyles.bodyM.copyWith(
                              color: AppColors.gray500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpacing.xxl),
                          _field(
                            controller: _emailController,
                            hint: 'Email address',
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _field(
                            controller: _passwordController,
                            hint: 'Password (min 6 characters)',
                            icon: Icons.lock_outline,
                            obscure: _obscurePassword,
                            suffixIcon: GestureDetector(
                              onTap: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                              child: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: AppColors.gray500,
                                size: 20,
                              ),
                            ),
                          ),
                          if (_errorMessage != null) ...[
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              _errorMessage!,
                              style: AppTextStyles.bodyS.copyWith(
                                color: AppColors.red,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
            ),
            FadeTransition(
              opacity: _fade,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.md,
                ),
                child: Column(
                  children: [
                    _isLoading
                        ? const SizedBox(
                            height: 56,
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
                            label: 'Create account',
                            onTap: _onCreateAccount,
                          ),
                    Semantics(
                      button: true,
                      label: 'Maybe later, keep it on this device',
                      child: GestureDetector(
                        onTap: _isLoading ? null : _onMaybeLater,
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.md,
                          ),
                          child: Text(
                            'Maybe later — keep it on this device',
                            style: AppTextStyles.bodyM.copyWith(
                              color: AppColors.black,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field({
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
          hintStyle: AppTextStyles.bodyM.copyWith(color: AppColors.gray500),
          prefixIcon: Icon(icon, color: AppColors.gray500, size: 20),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  /// Insert onboarding category budgets from SharedPreferences into Drift.
  Future<void> _syncBudgetsToDrift(
    SharedPreferences prefs,
    BaseRepository repo,
  ) async {
    final json = prefs.getString('category_budgets');
    if (json == null) return;
    try {
      final list = (jsonDecode(json) as List).cast<Map<String, dynamic>>();
      for (final b in list) {
        final category = b['group'] as String? ?? '';
        final limit = (b['monthlyLimit'] as num?)?.toDouble() ?? 0;
        if (category.isEmpty || limit <= 0) continue;
        await repo.insertBudget(
          CategoryBudgetsCompanion(
            category: drift.Value(category),
            monthlyLimit: drift.Value(limit),
          ),
        );
      }
    } on Exception catch (e) {
      debugPrint('Budget sync to Drift failed: $e');
    }
  }

  /// Insert onboarding savings goals from SharedPreferences into Drift.
  Future<void> _syncGoalsToDrift(
    SharedPreferences prefs,
    BaseRepository repo,
  ) async {
    final json = prefs.getString('savings_goals');
    if (json == null) return;
    try {
      final list = (jsonDecode(json) as List).cast<Map<String, dynamic>>();
      for (final g in list) {
        final name = g['name'] as String? ?? '';
        final target = (g['targetAmount'] as num?)?.toDouble() ?? 0;
        final icon = g['iconAsset'] as String? ?? 'star';
        if (name.isEmpty || target <= 0) continue;
        await repo.insertGoal(
          SavingsGoalsCompanion(
            name: drift.Value(name),
            targetAmount: drift.Value(target),
            iconName: drift.Value(icon),
          ),
        );
      }
    } on Exception catch (e) {
      debugPrint('Goals sync to Drift failed: $e');
    }
  }
}
