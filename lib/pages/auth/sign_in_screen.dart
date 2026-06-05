import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:finance_buddy_app/design_system/design_system.dart';
import 'package:finance_buddy_app/providers/auth_provider.dart';

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

      // Hand off to the branded hydration screen, which downloads Firestore
      // data, dedupes it into Drift, and shows a proper loading/error state.
      if (mounted) context.go('/hydration', extra: user.uid);
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

  /// Local-first escape hatch: skip cloud sign-in and use the app on-device.
  /// Returning users (already onboarded) go straight home; otherwise onboard.
  Future<void> _continueLocally() async {
    final prefs = await SharedPreferences.getInstance();
    final onboarded = prefs.getBool('onboarding_completed') ?? false;
    if (!mounted) return;
    context.go(onboarded ? '/home' : '/onboarding/welcome');
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

                    // Brand icon — gradient coin
                    Container(
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
                      suffixIcon: IconButton(
                        onPressed: () =>
                            setState(() => _obscurePassword = !_obscurePassword),
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: AppColors.gray500,
                          size: 20,
                        ),
                        tooltip: _obscurePassword
                            ? 'Show password'
                            : 'Hide password',
                      ),
                    ),

                    const SizedBox(height: AppSpacing.sm),
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Password reset is coming soon.')),
                        ),
                        child: Text(
                          'Forgot password?',
                          style: AppTextStyles.bodyS.copyWith(
                              color: AppColors.gray500,
                              fontWeight: FontWeight.w600),
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

            // "or" divider
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.xs, AppSpacing.lg, AppSpacing.sm),
              child: Row(
                children: [
                  const Expanded(
                      child: Divider(color: AppColors.gray200, height: 1)),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    child: Text('or',
                        style: AppTextStyles.labelM
                            .copyWith(color: AppColors.gray400)),
                  ),
                  const Expanded(
                      child: Divider(color: AppColors.gray200, height: 1)),
                ],
              ),
            ),

            // Local-first escape hatch
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.sm),
              child: AppButton(
                variant: AppButtonVariant.ghost,
                label: 'Continue on this device',
                onTap: _continueLocally,
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
    return Semantics(
      textField: true,
      label: hint,
      child: Container(
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
      ),
    );
  }
}
