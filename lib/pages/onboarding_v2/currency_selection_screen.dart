import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:finance_buddy_app/constants/currencies.dart';
import 'package:finance_buddy_app/design_system/design_system.dart';

class CurrencySelectionScreen extends StatefulWidget {
  const CurrencySelectionScreen({super.key});

  @override
  State<CurrencySelectionScreen> createState() =>
      _CurrencySelectionScreenState();
}

class _CurrencySelectionScreenState extends State<CurrencySelectionScreen>
    with TickerProviderStateMixin {
  late CurrencyModel _detectedCurrency;
  late CurrencyModel _selectedCurrency;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // Animations
  late final AnimationController _enterController;
  late final Animation<Offset> _cardSlideAnimation;
  late final Animation<double> _cardFadeAnimation;
  late final Animation<double> _listFadeAnimation;

  // Pulse animation for card update
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _detectedCurrency = _detectCurrency();
    _selectedCurrency = _detectedCurrency;

    // Enter animation
    _enterController = AnimationController(
      vsync: this,
      duration: AppDurations.slow,
    );
    _cardSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _enterController,
      curve: Curves.easeOutCubic,
    ));
    _cardFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _enterController,
        curve: Curves.easeOutCubic,
      ),
    );
    _listFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _enterController,
        curve: const Interval(0.25, 1.0, curve: Curves.easeOut),
      ),
    );
    _enterController.forward();

    // Pulse animation
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _pulseAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.02), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.02, end: 1.0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _enterController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  CurrencyModel _detectCurrency() {
    try {
      final locale =
          WidgetsBinding.instance.platformDispatcher.locale.toString();
      final format = NumberFormat.simpleCurrency(locale: locale);
      final code = format.currencyName ?? 'USD';
      return kSupportedCurrencies.firstWhere(
        (c) => c.code == code,
        orElse: () => kSupportedCurrencies.firstWhere((c) => c.code == 'USD'),
      );
    } on Exception catch (_) {
      return kSupportedCurrencies.firstWhere((c) => c.code == 'USD');
    }
  }

  List<CurrencyModel> get _filteredOtherCurrencies {
    return kSupportedCurrencies
        .where((c) => c.code != _detectedCurrency.code)
        .where((c) =>
            c.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            c.code.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  void _onCurrencyTap(CurrencyModel currency) {
    if (currency.code == _selectedCurrency.code) return;
    setState(() => _selectedCurrency = currency);
    _pulseController.forward(from: 0);
  }

  Future<void> _onContinue() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currency_code', _selectedCurrency.code);
    await prefs.setString('currency_name', _selectedCurrency.name);
    await prefs.setString('currency_symbol', _selectedCurrency.symbol);

    if (mounted) {
      await Navigator.pushNamed(context, '/onboarding/step2');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress indicator
            Padding(
              padding: const EdgeInsets.only(
                top: AppSpacing.md,
                left: AppSpacing.lg,
                right: AppSpacing.lg,
              ),
              child: _buildProgressIndicator(),
            ),

            // No back button on step 1 — splash was replaced, nothing to pop to
            const SizedBox(height: AppSpacing.md),

            // Title & subtitle
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
                    style: AppTextStyles.headingL
                        .copyWith(color: AppColors.black),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'This will be used across the app for all amounts.',
                    style: AppTextStyles.bodyM
                        .copyWith(color: AppColors.gray500),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // Detected currency card with enter animation
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: SlideTransition(
                position: _cardSlideAnimation,
                child: FadeTransition(
                  opacity: _cardFadeAnimation,
                  child: AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) => Transform.scale(
                      scale: _pulseAnimation.value,
                      child: child,
                    ),
                    child: _buildDetectedCard(),
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Divider + search + list (fades in)
            Expanded(
              child: FadeTransition(
                opacity: _listFadeAnimation,
                child: Column(
                  children: [
                    // "Other currencies" divider
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg),
                      child: Row(
                        children: [
                          const Expanded(
                              child: Divider(
                                  color: AppColors.gray200, thickness: 1)),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm),
                            child: Text(
                              'OTHER CURRENCIES',
                              style: AppTextStyles.labelM
                                  .copyWith(color: AppColors.gray400),
                            ),
                          ),
                          const Expanded(
                              child: Divider(
                                  color: AppColors.gray200, thickness: 1)),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Search bar
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg),
                      child: _buildSearchBar(),
                    ),

                    const SizedBox(height: AppSpacing.sm),

                    // Currency list
                    Expanded(child: _buildCurrencyList()),
                  ],
                ),
              ),
            ),

            // Continue button
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: AppButton(label: 'Continue', onTap: _onContinue),
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
          decoration: BoxDecoration(
            color: index == 0 ? AppColors.black : AppColors.gray200,
            borderRadius: AppRadius.full,
          ),
        );
      }),
    );
  }

  Widget _buildDetectedCard() {
    return AppCard(
      variant: AppCardVariant.dark,
      child: Row(
        children: [
          // Symbol icon box
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.gray600,
              borderRadius: AppRadius.sm,
            ),
            alignment: Alignment.center,
            child: Text(
              _selectedCurrency.symbol,
              style:
                  AppTextStyles.headingS.copyWith(color: AppColors.white),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          // Name, code, detected label
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedCurrency.name,
                  style: AppTextStyles.headingS
                      .copyWith(color: AppColors.white),
                ),
                const SizedBox(height: 2),
                Text(
                  _selectedCurrency.code,
                  style: AppTextStyles.labelM
                      .copyWith(color: AppColors.gray400),
                ),
                if (_selectedCurrency.code == _detectedCurrency.code) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Detected from your region',
                    style: AppTextStyles.labelS
                        .copyWith(color: AppColors.gray400),
                  ),
                ],
              ],
            ),
          ),
          // Checkmark
          const Icon(Icons.check, color: AppColors.green, size: 22),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 44,
      decoration: const BoxDecoration(
        color: AppColors.gray100,
        borderRadius: AppRadius.md,
      ),
      child: TextField(
        controller: _searchController,
        style: AppTextStyles.bodyM.copyWith(color: AppColors.black),
        decoration: InputDecoration(
          hintText: 'Search currency...',
          hintStyle: AppTextStyles.bodyM.copyWith(color: AppColors.gray400),
          prefixIcon:
              const Icon(Icons.search, color: AppColors.gray400, size: 20),
          suffixIcon: _searchQuery.isNotEmpty
              ? GestureDetector(
                  onTap: () => setState(() {
                    _searchQuery = '';
                    _searchController.clear();
                  }),
                  child: const Icon(Icons.close,
                      color: AppColors.gray400, size: 18),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
        onChanged: (val) => setState(() => _searchQuery = val),
      ),
    );
  }

  Widget _buildCurrencyList() {
    final currencies = _filteredOtherCurrencies;

    if (currencies.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Text(
            'No currencies found',
            style: AppTextStyles.bodyM.copyWith(color: AppColors.gray400),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      itemCount: currencies.length,
      separatorBuilder: (_, _) =>
          const Divider(height: 1, thickness: 1, color: AppColors.gray100),
      itemBuilder: (context, index) {
        final currency = currencies[index];
        final isSelected = currency.code == _selectedCurrency.code;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _onCurrencyTap(currency),
          child: SizedBox(
            height: 56,
            child: Row(
              children: [
                // Symbol icon
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: AppColors.gray100,
                    borderRadius: AppRadius.sm,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    currency.symbol,
                    style: AppTextStyles.headingS
                        .copyWith(color: AppColors.black),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                // Name + code
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currency.name,
                        style: AppTextStyles.bodyM
                            .copyWith(color: AppColors.gray600),
                      ),
                      Text(
                        currency.code,
                        style: AppTextStyles.labelS
                            .copyWith(color: AppColors.gray400),
                      ),
                    ],
                  ),
                ),
                // Checkmark if selected
                if (isSelected)
                  const Icon(Icons.check, color: AppColors.green, size: 20),
              ],
            ),
          ),
        );
      },
    );
  }
}
