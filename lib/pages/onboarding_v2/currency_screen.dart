import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:finance_buddy_app/design_system/design_system.dart';
import 'package:finance_buddy_app/pages/onboarding_v2/widgets/onboarding_progress_header.dart';

/// A selectable currency option. Restricted to the symbols the rest of the app
/// can render (see `currency_utils.dart`) so the choice stays consistent
/// everywhere — splash coin, amounts, recap.
class _CurrencyOption {
  const _CurrencyOption(this.code, this.symbol, this.name);
  final String code;
  final String symbol;
  final String name;
}

/// 02 · Currency — restored as an auto-detected, one-tap confirm.
///
/// Multi-currency was silently dropped (hard-locked to INR). INR stays the
/// detected default for most users, while the others are a tap away.
class CurrencyScreen extends StatefulWidget {
  const CurrencyScreen({super.key});

  @override
  State<CurrencyScreen> createState() => _CurrencyScreenState();
}

class _CurrencyScreenState extends State<CurrencyScreen> {
  static const List<_CurrencyOption> _all = [
    _CurrencyOption('inr', '₹', 'Indian Rupee'),
    _CurrencyOption('usd', '\$', 'US Dollar'),
    _CurrencyOption('eur', '€', 'Euro'),
    _CurrencyOption('gbp', '£', 'British Pound'),
    _CurrencyOption('jpy', '¥', 'Japanese Yen'),
  ];

  /// INR is the auto-detected default (v1 region lock relaxed to a confirm).
  String _selectedCode = 'inr';
  String _query = '';

  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final saved = prefs.getString('currency_code');
    if (saved != null && _all.any((c) => c.code == saved)) {
      setState(() => _selectedCode = saved);
    }
  }

  _CurrencyOption get _selected =>
      _all.firstWhere((c) => c.code == _selectedCode);

  List<_CurrencyOption> get _others {
    final q = _query.trim().toLowerCase();
    return _all.where((c) => c.code != _selectedCode).where((c) {
      if (q.isEmpty) return true;
      return c.name.toLowerCase().contains(q) ||
          c.code.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _onContinue() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currency_code', _selected.code);
    await prefs.setString('currency_symbol', _selected.symbol);
    if (mounted) await context.push('/onboarding/accounts');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(
                top: AppSpacing.md,
                left: AppSpacing.lg,
                right: AppSpacing.lg,
              ),
              child: OnboardingProgressHeader(step: 1),
            ),
            AppBackButton(onTap: () => context.pop()),
            Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                top: AppSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Choose your currency',
                    style: AppTextStyles.headingL.copyWith(
                      color: AppColors.black,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Auto-detected from your region — change it anytime in Settings.',
                    style: AppTextStyles.bodyM.copyWith(
                      color: AppColors.gray500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _selectedRow(),
                    const SizedBox(height: AppSpacing.md),
                    _searchField(),
                    const SizedBox(height: AppSpacing.md),
                    ..._others.map(_otherRow),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: AppButton(label: 'Continue', onTap: _onContinue),
            ),
          ],
        ),
      ),
    );
  }

  Widget _selectedRow() {
    final c = _selected;
    return Semantics(
      button: true,
      selected: true,
      label: '${c.name}, ${c.code.toUpperCase()}, selected',
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.white, Color(0xFFFBFBFA)],
          ),
          borderRadius: AppRadius.md,
          boxShadow: AppShadows.sm,
          border: Border.all(color: AppColors.black, width: 2),
        ),
        child: Row(
          children: [
            _badge(c.symbol, dark: true),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c.name, style: AppTextStyles.headingS),
                  Text(
                    '${c.code.toUpperCase()} · detected from your region',
                    style: AppTextStyles.labelS.copyWith(
                      color: AppColors.gray500,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: AppColors.black,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: AppColors.white, size: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _otherRow(_CurrencyOption c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Semantics(
        button: true,
        selected: false,
        label: '${c.name}, ${c.code.toUpperCase()}',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() => _selectedCode = c.code),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: const BoxDecoration(
              color: AppColors.white,
              borderRadius: AppRadius.md,
              boxShadow: AppShadows.sm,
            ),
            child: Row(
              children: [
                _badge(c.symbol, dark: false),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.name, style: AppTextStyles.headingS),
                      Text(
                        c.code.toUpperCase(),
                        style: AppTextStyles.labelS.copyWith(
                          color: AppColors.gray500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.gray200, width: 2),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _badge(String symbol, {required bool dark}) {
    return Container(
      width: 42,
      height: 42,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: dark
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF2A2A2E), AppColors.black],
              )
            : null,
        color: dark ? null : AppColors.gray100,
        borderRadius: AppRadius.sm,
        boxShadow: dark
            ? const [
                BoxShadow(
                  color: Color(0x800A0A0A),
                  blurRadius: 14,
                  offset: Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Text(
        symbol,
        style: AppTextStyles.headingM.copyWith(
          color: dark ? AppColors.white : AppColors.black,
        ),
      ),
    );
  }

  Widget _searchField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: const BoxDecoration(
        color: AppColors.gray100,
        borderRadius: AppRadius.md,
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: AppColors.gray400, size: 18),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              style: AppTextStyles.bodyM.copyWith(color: AppColors.black),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                hintText: 'Search currencies…',
                hintStyle: AppTextStyles.bodyM.copyWith(
                  color: AppColors.gray400,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
