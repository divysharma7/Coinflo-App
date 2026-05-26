import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:finance_buddy_app/design_system/design_system.dart';
import 'package:finance_buddy_app/models/category_budget_model.dart';
import 'package:finance_buddy_app/widgets/add_category_budget_sheet.dart';

class CategoryBudgetsScreen extends StatefulWidget {
  const CategoryBudgetsScreen({super.key});

  @override
  State<CategoryBudgetsScreen> createState() => _CategoryBudgetsScreenState();
}

class _CategoryBudgetsScreenState extends State<CategoryBudgetsScreen>
    with TickerProviderStateMixin {
  final List<CategoryBudgetModel> _budgets = [];
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  int _totalMonthlyBudget = 5000;
  String _currencySymbol = '₹';
  final NumberFormat _formatter = NumberFormat.decimalPattern();

  // Enter animations
  late final AnimationController _enterController;
  late final Animation<double> _titleFade;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _contentFade;

  int get _totalAllocated =>
      _budgets.fold(0, (sum, b) => sum + b.monthlyLimit);
  bool get _isOverAllocated => _totalAllocated > _totalMonthlyBudget;

  List<CategoryGroup> get _availableGroups => CategoryGroup.values
      .where((g) => !_budgets.any((b) => b.group == g))
      .toList();

  String get _buttonLabel => _budgets.isEmpty ? 'Skip for now' : 'Continue';

  @override
  void initState() {
    super.initState();
    _loadData();

    _enterController = AnimationController(
      vsync: this,
      duration: AppDurations.slow,
    );
    _titleFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _enterController,
        curve: const Interval(0, 0.6, curve: Curves.easeOutCubic),
      ),
    );
    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _enterController,
      curve: const Interval(0, 0.6, curve: Curves.easeOutCubic),
    ));
    _contentFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _enterController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );
    _enterController.forward();
  }

  @override
  void dispose() {
    _enterController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final savedJson = prefs.getString('category_budgets');
    final List<CategoryBudgetModel> restored = [];
    if (savedJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(savedJson) as List<dynamic>;
        restored.addAll(decoded
            .map((e) => CategoryBudgetModel.fromJson(e as Map<String, dynamic>)));
      } on FormatException catch (_) {
        // Ignore malformed JSON.
      }
    }
    setState(() {
      _totalMonthlyBudget = (prefs.getDouble('monthly_budget') ?? prefs.getInt('monthly_budget') ?? 5000).toInt();
      _currencySymbol = prefs.getString('currency_symbol') ?? '₹';
      if (restored.isNotEmpty) {
        _budgets
          ..clear()
          ..addAll(restored);
      }
    });
  }

  void _openAddSheet() {
    if (_availableGroups.isEmpty) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => AddCategoryBudgetSheet(
        availableGroups: _availableGroups,
        onSave: _addBudget,
      ),
    );
  }

  void _openEditSheet(CategoryBudgetModel budget) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => AddCategoryBudgetSheet(
        availableGroups: _availableGroups,
        existingBudget: budget,
        onSave: _updateBudget,
      ),
    );
  }

  void _addBudget(CategoryBudgetModel budget) {
    setState(() => _budgets.add(budget));
    _listKey.currentState?.insertItem(
      _budgets.length - 1,
      duration: AppDurations.base,
    );
  }

  void _updateBudget(CategoryBudgetModel budget) {
    setState(() {
      final index = _budgets.indexWhere((b) => b.id == budget.id);
      if (index != -1) _budgets[index] = budget;
    });
  }

  void _deleteBudget(int index) {
    final removed = _budgets[index];
    setState(() => _budgets.removeAt(index));
    _listKey.currentState?.removeItem(
      index,
      (context, animation) => _buildBudgetRow(removed, animation),
      duration: AppDurations.base,
    );
  }

  Future<void> _onContinue() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_budgets.map((b) => b.toJson()).toList());
    await prefs.setString('category_budgets', encoded);
    if (mounted) await context.push('/onboarding/step5');
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
            SlideTransition(
              position: _titleSlide,
              child: FadeTransition(
                opacity: _titleFade,
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: AppSpacing.lg,
                    right: AppSpacing.lg,
                    top: AppSpacing.lg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Category Budgets',
                        style: AppTextStyles.headingL
                            .copyWith(color: AppColors.black),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Set spending limits per category group. Optional — add more later.',
                        style: AppTextStyles.bodyM
                            .copyWith(color: AppColors.gray500),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Allocation bar
            FadeTransition(
              opacity: _contentFade,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: _buildAllocationBar(),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Scrollable content
            Expanded(
              child: FadeTransition(
                opacity: _contentFade,
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: Column(
                    children: [
                      // Budget list
                      AnimatedList(
                        key: _listKey,
                        initialItemCount: _budgets.length,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemBuilder: (context, index, animation) {
                          return _buildBudgetRow(
                              _budgets[index], animation,
                              index: index);
                        },
                      ),

                      // Add button
                      if (_availableGroups.isNotEmpty)
                        Padding(
                          padding:
                              const EdgeInsets.only(top: AppSpacing.md),
                          child: _buildAddButton(),
                        ),

                      const SizedBox(height: AppSpacing.lg),
                    ],
                  ),
                ),
              ),
            ),

            // Continue / Skip button
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: AppButton(label: _buttonLabel, onTap: _onContinue),
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
            color: index < 4 ? AppColors.black : AppColors.gray200,
            borderRadius: AppRadius.full,
          ),
        );
      }),
    );
  }

  Widget _buildAllocationBar() {
    final progress =
        _totalMonthlyBudget > 0
            ? (_totalAllocated / _totalMonthlyBudget).clamp(0.0, 1.0)
            : 0.0;

    return Column(
      children: [
        Row(
          children: [
            Icon(
              Icons.pie_chart_outline,
              size: 16,
              color: _isOverAllocated ? AppColors.red : AppColors.gray400,
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                '$_currencySymbol${_formatter.format(_totalAllocated)} allocated of $_currencySymbol${_formatter.format(_totalMonthlyBudget)} monthly budget',
                style: AppTextStyles.bodyS.copyWith(
                  color:
                      _isOverAllocated ? AppColors.red : AppColors.gray500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: progress),
          duration: AppDurations.base,
          curve: Curves.easeOutCubic,
          builder: (context, value, _) {
            return ClipRRect(
              borderRadius: AppRadius.full,
              child: LinearProgressIndicator(
                value: value,
                backgroundColor: AppColors.gray100,
                valueColor: AlwaysStoppedAnimation(
                  _isOverAllocated ? AppColors.red : AppColors.black,
                ),
                minHeight: 2,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildBudgetRow(
    CategoryBudgetModel budget,
    Animation<double> animation, {
    int? index,
  }) {
    final row = Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: AppRadius.xl,
        boxShadow: AppShadows.sm,
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: budget.group.iconColor.withValues(alpha: 0.12),
              borderRadius: AppRadius.sm,
            ),
            child: Icon(
              budget.group.icon,
              color: budget.group.iconColor,
              size: 22,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          // Name + limit
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(budget.group.label, style: AppTextStyles.headingS),
                Text(
                  '$_currencySymbol${_formatter.format(budget.monthlyLimit)}/mo',
                  style:
                      AppTextStyles.bodyS.copyWith(color: AppColors.gray400),
                ),
              ],
            ),
          ),
          // Edit button
          GestureDetector(
            onTap: () => _openEditSheet(budget),
            child: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: AppColors.gray100,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.edit_outlined,
                  size: 16, color: AppColors.gray500),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          // Delete button
          if (index != null)
            GestureDetector(
              onTap: () => _deleteBudget(index),
              child: Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: AppColors.gray100,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.delete_outline,
                    size: 16, color: AppColors.gray500),
              ),
            ),
        ],
      ),
    );

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.1),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      )),
      child: FadeTransition(opacity: animation, child: row),
    );
  }

  Widget _buildAddButton() {
    return GestureDetector(
      onTap: _openAddSheet,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.gray200, width: 1.5),
          borderRadius: AppRadius.full,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add, size: 16, color: AppColors.gray500),
            const SizedBox(width: AppSpacing.xs),
            Text(
              'Add category budget',
              style: AppTextStyles.bodyM.copyWith(color: AppColors.gray500),
            ),
          ],
        ),
      ),
    );
  }
}
