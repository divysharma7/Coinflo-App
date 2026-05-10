import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:finance_buddy_app/design_system/design_system.dart';
import 'package:finance_buddy_app/models/category_budget_model.dart';
import 'package:finance_buddy_app/models/smart_rule_model.dart';
import 'package:finance_buddy_app/widgets/add_rule_sheet.dart';

class SmartRulesScreen extends StatefulWidget {
  const SmartRulesScreen({super.key});

  @override
  State<SmartRulesScreen> createState() => _SmartRulesScreenState();
}

class _SmartRulesScreenState extends State<SmartRulesScreen>
    with SingleTickerProviderStateMixin {
  final List<SmartRuleModel> _rules = [];
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

  late final AnimationController _enterController;
  late final Animation<double> _titleFade;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _cardFade;
  late final Animation<Offset> _cardSlide;
  late final Animation<double> _buttonFade;

  List<SmartRuleModel> get _sortedRules =>
      [..._rules]..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  String get _buttonLabel => _rules.isEmpty ? 'Skip for now' : 'Continue';

  @override
  void initState() {
    super.initState();

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

    _cardFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _enterController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOut),
      ),
    );
    _cardSlide = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _enterController,
      curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
    ));

    _buttonFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _enterController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
    );

    _enterController.forward();
  }

  @override
  void dispose() {
    _enterController.dispose();
    super.dispose();
  }

  void _openAddRuleSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => AddRuleSheet(
        existingKeywords: _rules.map((r) => r.keyword).toList(),
        onAdd: _addRule,
      ),
    );
  }

  void _addRule(SmartRuleModel rule) {
    setState(() => _rules.insert(0, rule));
    _listKey.currentState?.insertItem(0, duration: AppDurations.base);
  }

  void _deleteRule(int index) {
    final removed = _sortedRules[index];
    final actualIndex = _rules.indexWhere((r) => r.id == removed.id);
    setState(() => _rules.removeAt(actualIndex));
    _listKey.currentState?.removeItem(
      index,
      (context, animation) => _buildRuleRow(removed, animation),
      duration: AppDurations.fast,
    );
  }

  Future<void> _onContinue() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_rules.map((r) => r.toJson()).toList());
    await prefs.setString('smart_rules', encoded);
    if (mounted) await Navigator.pushNamed(context, '/onboarding/step8');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
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
                        'Smart Rules',
                        style: AppTextStyles.headingL
                            .copyWith(color: AppColors.black),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Tell us how you want things categorized — no AI needed.',
                        style: AppTextStyles.bodyM
                            .copyWith(color: AppColors.gray500),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Column(
                  children: [
                    // Explainer card
                    SlideTransition(
                      position: _cardSlide,
                      child: FadeTransition(
                        opacity: _cardFade,
                        child: _buildExplainerCard(),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Rules list
                    if (_rules.isNotEmpty)
                      AnimatedList(
                        key: _listKey,
                        initialItemCount: _sortedRules.length,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemBuilder: (context, index, animation) {
                          return _buildRuleRow(
                              _sortedRules[index], animation,
                              index: index);
                        },
                      ),

                    // Add a rule button
                    FadeTransition(
                      opacity: _buttonFade,
                      child: Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.md),
                        child: _buildAddButton(),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),
                  ],
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
            color: index < 7 ? AppColors.black : AppColors.gray200,
            borderRadius: AppRadius.full,
          ),
        );
      }),
    );
  }

  Widget _buildExplainerCard() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: AppRadius.xl,
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Row(
            children: [
              Icon(Icons.bolt, size: 18, color: AppColors.black),
              SizedBox(width: AppSpacing.xs),
              Text('How it works', style: AppTextStyles.headingS),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Body
          Text(
            'When you add a transaction with a title containing your keyword, '
            "it's instantly assigned to your chosen category — skipping AI entirely.",
            style: AppTextStyles.bodyM.copyWith(color: AppColors.gray600),
          ),
          const SizedBox(height: AppSpacing.md),

          // Example sub-card
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: const BoxDecoration(
              color: AppColors.gray100,
              borderRadius: AppRadius.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'EXAMPLE',
                  style: AppTextStyles.labelM
                      .copyWith(color: AppColors.gray400),
                ),
                const SizedBox(height: AppSpacing.sm),

                // Row 1: paneer → Groceries
                Row(
                  children: [
                    _buildKeywordChip(
                        'paneer', CategoryGroup.foodAndDrink.iconColor),
                    _buildArrow(),
                    Icon(Icons.shopping_cart_outlined,
                        size: 16,
                        color: CategoryGroup.foodAndDrink.iconColor),
                    const SizedBox(width: AppSpacing.xxs),
                    Text(
                      'Groceries',
                      style: AppTextStyles.bodyM
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),

                // Row 2: - diet → Gym & Fitness
                Row(
                  children: [
                    _buildKeywordChip(
                        '- diet', CategoryGroup.healthAndWellness.iconColor),
                    _buildArrow(),
                    Icon(Icons.monitor_heart_outlined,
                        size: 16,
                        color: CategoryGroup.healthAndWellness.iconColor),
                    const SizedBox(width: AppSpacing.xxs),
                    Text(
                      'Gym & Fitness',
                      style: AppTextStyles.bodyM
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),

                // Conflict note
                Text(
                  '"paneer - diet" → matches - diet → Gym & Fitness ✓',
                  style:
                      AppTextStyles.bodyS.copyWith(color: AppColors.gray400),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeywordChip(String keyword, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadius.xs,
      ),
      child: Text(
        keyword,
        style: AppTextStyles.bodyS
            .copyWith(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildArrow() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: Icon(Icons.arrow_forward, size: 14, color: AppColors.gray400),
    );
  }

  Widget _buildRuleRow(
    SmartRuleModel rule,
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
          // Keyword chip
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: const BoxDecoration(
              color: AppColors.gray100,
              borderRadius: AppRadius.full,
            ),
            child: Text(
              rule.keyword,
              style:
                  AppTextStyles.bodyM.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            child:
                Icon(Icons.arrow_forward, size: 14, color: AppColors.gray400),
          ),
          // Category
          Icon(rule.categoryIcon, size: 16, color: rule.categoryColor),
          const SizedBox(width: AppSpacing.xxs),
          Expanded(
            child: Text(
              rule.categoryName,
              style:
                  AppTextStyles.bodyM.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          // Delete button
          if (index != null)
            GestureDetector(
              onTap: () => _deleteRule(index),
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
      onTap: _openAddRuleSheet,
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
              'Add a rule',
              style: AppTextStyles.bodyM.copyWith(color: AppColors.gray500),
            ),
          ],
        ),
      ),
    );
  }
}
