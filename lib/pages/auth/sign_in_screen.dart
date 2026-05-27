import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'dart:convert';

import 'package:drift/drift.dart' as drift;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:finance_buddy_app/data/db.dart';
import 'package:finance_buddy_app/design_system/design_system.dart';
import 'package:finance_buddy_app/main.dart' show firebaseInitialized;
import 'package:finance_buddy_app/providers/auth_provider.dart';
import 'package:finance_buddy_app/providers/providers.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _onSignIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Please enter your email and password.');
      return;
    }

    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(email)) {
      setState(() => _errorMessage = 'Please enter a valid email address.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = ref.read(authServiceProvider);
      final user = await authService.signInWithEmail(email, password);

      if (user == null) {
        if (mounted) {
          setState(() {
            _errorMessage = 'Sign in failed. Please try again.';
            _isLoading = false;
          });
        }
        return;
      }

      // Hydrate local data from Firestore
      if (firebaseInitialized) {
        final firestoreService = ref.read(firestoreServiceProvider);
        await firestoreService.hydrateLocalFromFirestore(user.uid);
      }

      // Sync hydrated budgets & goals from SharedPreferences into Drift
      await _syncOnboardingDataToDrift();

      if (mounted) context.go('/home');
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = _friendlyAuthError(e.code);
          _isLoading = false;
        });
      }
    } on Exception {
      if (mounted) {
        setState(() {
          _errorMessage = 'Something went wrong. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _syncOnboardingDataToDrift() async {
    final prefs = await SharedPreferences.getInstance();
    final repo = ref.read(repositoryProvider);

    // Sync category budgets
    final budgetsJson = prefs.getString('category_budgets');
    if (budgetsJson != null) {
      try {
        final list = (jsonDecode(budgetsJson) as List).cast<Map<String, dynamic>>();
        for (final b in list) {
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

    // Sync savings goals
    final goalsJson = prefs.getString('savings_goals');
    if (goalsJson != null) {
      try {
        final list = (jsonDecode(goalsJson) as List).cast<Map<String, dynamic>>();
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

  String _friendlyAuthError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'invalid-credential':
        return 'Invalid email or password.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: SafeArea(
        child: Column(
          children: [
            // Back button
            Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.md,
                top: AppSpacing.md,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () => context.pop(),
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
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Column(
                  children: [
                    const SizedBox(height: AppSpacing.xxl),

                    // Icon
                    Container(
                      width: 80,
                      height: 80,
                      decoration: const BoxDecoration(
                        color: AppColors.black,
                        borderRadius: AppRadius.xl,
                      ),
                      child: const Icon(
                        Icons.login,
                        color: AppColors.white,
                        size: 40,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    Text(
                      'Welcome back',
                      style: AppTextStyles.headingL
                          .copyWith(color: AppColors.black),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: AppSpacing.sm),

                    Text(
                      'Sign in to restore your data\nand sync across devices.',
                      style: AppTextStyles.bodyM
                          .copyWith(color: AppColors.gray500),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: AppSpacing.xxl),

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
                      hint: 'Password',
                      icon: Icons.lock_outline,
                      obscure: _obscurePassword,
                      suffixIcon: GestureDetector(
                        onTap: () =>
                            setState(() => _obscurePassword = !_obscurePassword),
                        child: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: AppColors.gray500,
                          size: 20,
                        ),
                      ),
                    ),

                    // Error message
                    if (_errorMessage != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        _errorMessage!,
                        style:
                            AppTextStyles.bodyS.copyWith(color: AppColors.red),
                        textAlign: TextAlign.center,
                      ),
                    ],

                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
            ),

            // Sign In button
            Padding(
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
                      label: 'Sign In',
                      onTap: _onSignIn,
                    ),
            ),

            // Navigate to onboarding / account creation
            GestureDetector(
              onTap: () => context.go('/onboarding/step2'),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Text.rich(
                  TextSpan(
                    text: "Don't have an account? ",
                    style:
                        AppTextStyles.bodyS.copyWith(color: AppColors.gray500),
                    children: [
                      TextSpan(
                        text: 'Start fresh',
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
          hintStyle: AppTextStyles.bodyM.copyWith(color: AppColors.gray500),
          prefixIcon: Icon(icon, color: AppColors.gray500, size: 20),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}
