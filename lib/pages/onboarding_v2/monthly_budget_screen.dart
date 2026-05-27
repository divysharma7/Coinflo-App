import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:finance_buddy_app/design_system/design_system.dart';

const List<int> kBudgetPresets = [5000, 10000, 50000, 100000, 500000];

class MonthlyBudgetScreen extends StatefulWidget {
  const MonthlyBudgetScreen({super.key});

  @override
  State<MonthlyBudgetScreen> createState() => _MonthlyBudgetScreenState();
}

class _MonthlyBudgetScreenState extends State<MonthlyBudgetScreen>
    with TickerProviderStateMixin {
  int _selectedAmount = 5000;
  bool _isEditingCustom = false;
  String _currencySymbol = '₹';

  final TextEditingController _customController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final NumberFormat _formatter = NumberFormat.decimalPattern();

  // Enter animations
  late final AnimationController _enterController;
  late final Animation<double> _cardFade;
  late final Animation<Offset> _cardSlide;
  late final Animation<double> _pillsFade;

  int? get _activePreset =>
      kBudgetPresets.contains(_selectedAmount) ? _selectedAmount : null;

  @override
  void initState() {
    super.initState();
    _loadSavedData();

    _enterController = AnimationController(
      vsync: this,
      duration: AppDurations.slow,
    );
    _cardFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _enterController,
        curve: const Interval(0, 0.7, curve: Curves.easeOutCubic),
      ),
    );
    _cardSlide = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _enterController,
      curve: const Interval(0, 0.7, curve: Curves.easeOutCubic),
    ));
    _pillsFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _enterController,
        curve: const Interval(0.25, 1.0, curve: Curves.easeOut),
      ),
    );
    _enterController.forward();
  }

  @override
  void dispose() {
    _customController.dispose();
    _focusNode.dispose();
    _enterController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    final savedBudget = prefs.getDouble('monthly_budget') ??
        prefs.getInt('monthly_budget')?.toDouble();
    setState(() {
      _currencySymbol = prefs.getString('currency_symbol') ?? '₹';
      if (savedBudget != null && savedBudget > 0) {
        _selectedAmount = savedBudget.toInt();
      }
    });
  }

  void _onPresetTap(int amount) {
    setState(() {
      _selectedAmount = amount;
      _isEditingCustom = false;
    });
    _focusNode.unfocus();
  }

  void _onNumberTap() {
    setState(() => _isEditingCustom = true);
    _customController.text = _selectedAmount.toString();
    _customController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _customController.text.length,
    );
    Future.delayed(
      const Duration(milliseconds: 50),
      () => _focusNode.requestFocus(),
    );
  }

  void _onCustomChanged(String value) {
    final parsed = int.tryParse(value.replaceAll(',', ''));
    if (parsed != null && parsed > 0) {
      setState(() => _selectedAmount = parsed);
    }
  }

  Future<void> _onContinue() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('monthly_budget', _selectedAmount.toDouble());
    if (mounted) await context.push('/onboarding/step4');
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

            // Back button
            AppBackButton(onTap: () => context.pop()),

            // Title + subtitle
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
                    'Set a monthly budget',
                    style:
                        AppTextStyles.headingL.copyWith(color: AppColors.black),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'How much do you plan to spend each month?',
                    style:
                        AppTextStyles.bodyM.copyWith(color: AppColors.gray500),
                  ),
                ],
              ),
            ),

            // Centered content
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Budget display card
                  SlideTransition(
                    position: _cardSlide,
                    child: FadeTransition(
                      opacity: _cardFade,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg),
                        child: _buildBudgetCard(),
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // Preset pills
                  FadeTransition(
                    opacity: _pillsFade,
                    child: _buildPresetPills(),
                  ),
                ],
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
            color: index < 3 ? AppColors.black : AppColors.gray200,
            borderRadius: AppRadius.full,
          ),
        );
      }),
    );
  }

  Widget _buildBudgetCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.xxl,
        horizontal: AppSpacing.xl,
      ),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: AppRadius.xl,
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        children: [
          AnimatedSwitcher(
            duration: AppDurations.fast,
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.3),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: _isEditingCustom
                ? _buildEditField()
                : GestureDetector(
                    key: ValueKey(_selectedAmount),
                    onTap: _onNumberTap,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          _currencySymbol,
                          style: AppTextStyles.displayL
                              .copyWith(color: AppColors.black),
                        ),
                        Text(
                          _formatter.format(_selectedAmount),
                          style: AppTextStyles.displayXL
                              .copyWith(color: AppColors.black),
                        ),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'per month',
            style: AppTextStyles.bodyM.copyWith(color: AppColors.gray500),
          ),
        ],
      ),
    );
  }

  Widget _buildEditField() {
    return SizedBox(
      key: const ValueKey('editing'),
      width: 200,
      child: TextField(
        controller: _customController,
        focusNode: _focusNode,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        style: AppTextStyles.displayXL.copyWith(color: AppColors.black),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          border: InputBorder.none,
          prefixText: _currencySymbol,
          prefixStyle: AppTextStyles.displayL.copyWith(color: AppColors.black),
        ),
        onChanged: _onCustomChanged,
        onSubmitted: (_) {
          setState(() => _isEditingCustom = false);
        },
      ),
    );
  }

  String _presetLabel(int amount) {
    if (amount >= 100000) return '$_currencySymbol${(amount / 100000).toStringAsFixed(0)}L';
    if (amount >= 1000) return '$_currencySymbol${(amount / 1000).toStringAsFixed(0)}k';
    return '$_currencySymbol$amount';
  }

  Widget _buildPresetPills() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        children: kBudgetPresets.map((amount) {
          final isActive = amount == _activePreset;
          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.xs),
            child: GestureDetector(
              onTap: () => _onPresetTap(amount),
              child: AnimatedContainer(
                duration: AppDurations.fast,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.black : AppColors.white,
                  borderRadius: AppRadius.full,
                  border: Border.all(
                    color: isActive ? AppColors.black : AppColors.gray200,
                    width: 1.5,
                  ),
                ),
                child: Text(
                  _presetLabel(amount),
                  style: AppTextStyles.bodyM.copyWith(
                    color: isActive ? AppColors.white : AppColors.black,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
