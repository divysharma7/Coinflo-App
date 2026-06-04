import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:finance_buddy_app/design_system/design_system.dart';
import 'package:finance_buddy_app/pages/onboarding_v2/widgets/onboarding_progress_header.dart';

const int kBudgetMax = 200000;
const int kBudgetStep = 1000;
const int kBudgetDefault = 60000;

/// 05 · Budget — now *optional*.
///
/// With no spending logged yet, forcing a budget on day zero is friction. It's
/// skippable, and per-category limits are folded in as one optional row rather
/// than a separate mandatory step.
class MonthlyBudgetScreen extends StatefulWidget {
  const MonthlyBudgetScreen({super.key});

  @override
  State<MonthlyBudgetScreen> createState() => _MonthlyBudgetScreenState();
}

class _MonthlyBudgetScreenState extends State<MonthlyBudgetScreen>
    with TickerProviderStateMixin {
  int _amount = kBudgetDefault;
  bool _isEditing = false;
  String _currencySymbol = '₹';

  final TextEditingController _customController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final NumberFormat _formatter = NumberFormat.decimalPattern();

  late final AnimationController _enter;
  late final Animation<double> _cardFade;
  late final Animation<Offset> _cardSlide;
  late final Animation<double> _restFade;

  @override
  void initState() {
    super.initState();
    _loadSavedData();
    _enter = AnimationController(vsync: this, duration: AppDurations.slow);
    _cardFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _enter,
        curve: const Interval(0, 0.7, curve: Curves.easeOutCubic),
      ),
    );
    _cardSlide = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _enter,
            curve: const Interval(0, 0.7, curve: Curves.easeOutCubic),
          ),
        );
    _restFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _enter,
        curve: const Interval(0.25, 1.0, curve: Curves.easeOut),
      ),
    );
    _enter.forward();
  }

  @override
  void dispose() {
    _customController.dispose();
    _focusNode.dispose();
    _enter.dispose();
    super.dispose();
  }

  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    final saved =
        prefs.getDouble('monthly_budget') ??
        prefs.getInt('monthly_budget')?.toDouble();
    if (!mounted) return;
    setState(() {
      _currencySymbol = prefs.getString('currency_symbol') ?? '₹';
      if (saved != null && saved > 0) {
        _amount = saved.toInt().clamp(0, kBudgetMax);
      }
    });
  }

  void _onSliderChanged(double value) {
    final stepped = (value / kBudgetStep).round() * kBudgetStep;
    setState(() {
      _amount = stepped.clamp(0, kBudgetMax);
      _isEditing = false;
    });
    _focusNode.unfocus();
  }

  void _startEditing() {
    setState(() => _isEditing = true);
    _customController.text = _amount.toString();
    _customController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _customController.text.length,
    );
    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted) _focusNode.requestFocus();
    });
  }

  void _onCustomChanged(String value) {
    final parsed = int.tryParse(value.replaceAll(',', ''));
    if (parsed != null) {
      setState(() => _amount = parsed.clamp(0, kBudgetMax));
    }
  }

  Future<void> _onContinue() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('monthly_budget', _amount.toDouble());
    if (mounted) await context.push('/onboarding/goals');
  }

  Future<void> _onSkip() async {
    if (mounted) await context.push('/onboarding/goals');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      resizeToAvoidBottomInset: true,
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
              child: OnboardingProgressHeader(step: 4),
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
                    'Set a monthly budget',
                    style: AppTextStyles.headingL.copyWith(
                      color: AppColors.black,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    "Optional. A ceiling we'll nudge you toward — "
                    'fine-tune per category later.',
                    style: AppTextStyles.bodyM.copyWith(
                      color: AppColors.gray500,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.xl,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                child: Column(
                  children: [
                    SlideTransition(
                      position: _cardSlide,
                      child: FadeTransition(
                        opacity: _cardFade,
                        child: _budgetCard(),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    FadeTransition(
                      opacity: _restFade,
                      child: _perCategoryRow(),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              child: Column(
                children: [
                  AppButton(label: 'Continue', onTap: _onContinue),
                  Semantics(
                    button: true,
                    label: 'Skip for now',
                    child: GestureDetector(
                      onTap: _onSkip,
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.sm,
                        ),
                        child: Text(
                          'Skip for now',
                          style: AppTextStyles.bodyM.copyWith(
                            color: AppColors.gray500,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _budgetCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: AppRadius.xl,
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'MONTHLY BUDGET',
            style: AppTextStyles.labelS.copyWith(
              color: AppColors.gray400,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          _isEditing ? _editField() : _amountDisplay(),
          const SizedBox(height: AppSpacing.lg),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 6,
              activeTrackColor: AppColors.black,
              inactiveTrackColor: AppColors.gray200,
              thumbColor: AppColors.white,
              overlayColor: const Color(0x1A0A0A0A),
              thumbShape: const RoundSliderThumbShape(
                enabledThumbRadius: 13,
                elevation: 3,
              ),
              trackShape: const RoundedRectSliderTrackShape(),
            ),
            child: Slider(
              value: _amount.toDouble().clamp(0, kBudgetMax.toDouble()),
              max: kBudgetMax.toDouble(),
              onChanged: _onSliderChanged,
              semanticFormatterCallback: (value) {
                final stepped = ((value / kBudgetStep).round() * kBudgetStep)
                    .clamp(0, kBudgetMax);
                return '$_currencySymbol${_formatter.format(stepped)}';
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_currencySymbol}0',
                  style: AppTextStyles.labelS.copyWith(
                    color: AppColors.gray400,
                  ),
                ),
                Text(
                  '$_currencySymbol${_formatter.format(kBudgetMax)}',
                  style: AppTextStyles.labelS.copyWith(
                    color: AppColors.gray400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _amountDisplay() {
    return Semantics(
      button: true,
      label:
          'Monthly budget amount, $_currencySymbol${_formatter.format(_amount)}',
      hint: 'Edit budget amount',
      child: ExcludeSemantics(
        child: GestureDetector(
          onTap: _startEditing,
          behavior: HitTestBehavior.opaque,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                _currencySymbol,
                style: AppTextStyles.displayL.copyWith(color: AppColors.black),
              ),
              Text(
                _formatter.format(_amount),
                style: AppTextStyles.displayXL.copyWith(color: AppColors.black),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _editField() {
    return SizedBox(
      child: TextField(
        controller: _customController,
        focusNode: _focusNode,
        keyboardType: TextInputType.number,
        style: AppTextStyles.displayXL.copyWith(color: AppColors.black),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          isDense: true,
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
          prefixText: _currencySymbol,
          prefixStyle: AppTextStyles.displayL.copyWith(color: AppColors.black),
        ),
        onChanged: _onCustomChanged,
        onSubmitted: (_) => setState(() => _isEditing = false),
        onTapOutside: (_) {
          _focusNode.unfocus();
          setState(() => _isEditing = false);
        },
      ),
    );
  }

  Widget _perCategoryRow() {
    return Semantics(
      button: true,
      label: 'Set per-category limits, optional',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => context.push('/onboarding/budget/categories'),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: AppRadius.md,
            boxShadow: AppShadows.sm,
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: AppColors.gray100,
                  borderRadius: AppRadius.sm,
                ),
                child: const Icon(Icons.tune, size: 18, color: AppColors.black),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Set per-category limits',
                      style: AppTextStyles.bodyM.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Optional · do it now or later',
                      style: AppTextStyles.bodyS.copyWith(
                        color: AppColors.gray400,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppColors.gray300,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
