import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:finance_buddy_app/constants/goal_icons.dart';
import 'package:finance_buddy_app/design_system/design_system.dart';
import 'package:finance_buddy_app/models/savings_goal_model.dart';
import 'package:finance_buddy_app/pages/onboarding_v2/widgets/onboarding_progress_header.dart';
import 'package:finance_buddy_app/widgets/add_goal_sheet.dart';
import 'package:finance_buddy_app/widgets/common/animations.dart';
import 'package:finance_buddy_app/widgets/common/spendler_bottom_sheet.dart';

/// Quick-start goal suggestions — tapping one pre-fills the add sheet.
class _GoalTemplate {
  const _GoalTemplate(this.name, this.iconLabel);
  final String name;
  final String iconLabel; // matches a kGoalIcons label
}

const List<_GoalTemplate> _kGoalTemplates = [
  _GoalTemplate('Emergency Fund', 'Other'),
  _GoalTemplate('Trip', 'Travel'),
  _GoalTemplate('New Phone', 'Phone'),
  _GoalTemplate('Car', 'Vehicle'),
  _GoalTemplate('Home', 'Home'),
  _GoalTemplate('Wedding', 'Wedding'),
];

class SavingsGoalsScreen extends StatefulWidget {
  const SavingsGoalsScreen({super.key});

  @override
  State<SavingsGoalsScreen> createState() => _SavingsGoalsScreenState();
}

class _SavingsGoalsScreenState extends State<SavingsGoalsScreen>
    with SingleTickerProviderStateMixin {
  final List<SavingsGoalModel> _goals = [];
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  String _currencySymbol = '₹';
  final NumberFormat _formatter = NumberFormat.decimalPattern();

  late final AnimationController _enterController;
  late final Animation<double> _titleFade;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _contentFade;

  @override
  void initState() {
    super.initState();
    _loadSavedData();

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
    _titleSlide = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _enterController,
            curve: const Interval(0, 0.6, curve: Curves.easeOutCubic),
          ),
        );
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

  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final savedJson = prefs.getString('savings_goals');
    final List<SavingsGoalModel> restored = [];
    if (savedJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(savedJson) as List<dynamic>;
        restored.addAll(
          decoded.map(
            (e) => SavingsGoalModel.fromJson(e as Map<String, dynamic>),
          ),
        );
      } on FormatException catch (_) {
        // Ignore malformed JSON.
      }
    }
    setState(() {
      _currencySymbol = prefs.getString('currency_symbol') ?? '₹';
      if (restored.isNotEmpty) {
        _goals
          ..clear()
          ..addAll(restored);
      }
    });
  }

  void _openAddSheet({String? name, String? iconLabel}) {
    showSpendlerSheet<void>(
      context: context,
      builder: (_) => AddGoalSheet(
        onSave: _addGoal,
        initialName: name,
        initialIconLabel: iconLabel,
      ),
    );
  }

  void _addGoal(SavingsGoalModel goal) {
    setState(() => _goals.add(goal));
    _listKey.currentState?.insertItem(
      _goals.length - 1,
      duration: AppDurations.base,
    );
  }

  void _deleteGoal(int index) {
    final removed = _goals[index];
    setState(() => _goals.removeAt(index));
    _listKey.currentState?.removeItem(
      index,
      (context, animation) => _buildGoalRow(removed, animation),
      duration: AppDurations.fast,
    );
  }

  String get _buttonLabel => _goals.isEmpty ? 'Skip for now' : 'Continue';

  Future<void> _onContinue() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_goals.map((g) => g.toJson()).toList());
    await prefs.setString('savings_goals', encoded);
    if (mounted) await context.push('/onboarding/reminders');
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
              child: OnboardingProgressHeader(step: 5),
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
                        'What are you saving for?',
                        style: AppTextStyles.headingL.copyWith(
                          color: AppColors.black,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Optional. Pick a goal to stay motivated — or make your own.',
                        style: AppTextStyles.bodyM.copyWith(
                          color: AppColors.gray500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // Scrollable content
            Expanded(
              child: FadeTransition(
                opacity: _contentFade,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTemplates(),
                      const SizedBox(height: AppSpacing.md),
                      AnimatedList(
                        key: _listKey,
                        initialItemCount: _goals.length,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemBuilder: (context, index, animation) {
                          return _buildGoalRow(
                            _goals[index],
                            animation,
                            index: index,
                          );
                        },
                      ),
                      // Add goal button
                      _buildAddButton(),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                  ),
                ),
              ),
            ),

            // Continue button
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

  Widget _buildTemplates() {
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: _kGoalTemplates.map((t) {
        final icon = kGoalIcons.firstWhere(
          (g) => g.label == t.iconLabel,
          orElse: () => kGoalIcons.last,
        );
        return PressableCard(
          onTap: () => _openAddSheet(name: t.name, iconLabel: t.iconLabel),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: 9,
            ),
            decoration: const BoxDecoration(
              color: AppColors.white,
              borderRadius: AppRadius.full,
              boxShadow: AppShadows.sm,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon.icon, size: 15, color: AppColors.black),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  t.name,
                  style: AppTextStyles.bodyS.copyWith(
                    color: AppColors.black,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildGoalRow(
    SavingsGoalModel goal,
    Animation<double> animation, {
    int? index,
  }) {
    final goalIcon = kGoalIcons.firstWhere(
      (g) => g.label == goal.iconAsset,
      orElse: () => kGoalIcons.last,
    );

    final row = Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: AppRadius.xl,
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Icon
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: AppColors.gray100,
                  borderRadius: AppRadius.sm,
                ),
                child: Icon(goalIcon.icon, size: 24, color: AppColors.gray600),
              ),
              const SizedBox(width: AppSpacing.md),
              // Name + health badge
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(goal.name, style: AppTextStyles.headingS),
                        ),
                        HealthBadge.fromGoalHealth(goal.health),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      '$_currencySymbol${_formatter.format(goal.savedAmount)} of $_currencySymbol${_formatter.format(goal.targetAmount)}',
                      style: AppTextStyles.bodyS.copyWith(
                        color: AppColors.gray500,
                      ),
                    ),
                  ],
                ),
              ),
              // Delete
              if (index != null)
                Padding(
                  padding: const EdgeInsets.only(left: AppSpacing.xs),
                  child: Semantics(
                    button: true,
                    label: 'Delete goal',
                    child: GestureDetector(
                      onTap: () => _deleteGoal(index),
                      behavior: HitTestBehavior.opaque,
                      child: SizedBox(
                        width: 44,
                        height: 44,
                        child: Center(
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: const BoxDecoration(
                              color: AppColors.gray100,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.delete_outline,
                              size: 16,
                              color: AppColors.gray500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          // Progress bar
          ClipRRect(
            borderRadius: AppRadius.full,
            child: LinearProgressIndicator(
              value: goal.progress,
              backgroundColor: AppColors.gray100,
              valueColor: AlwaysStoppedAnimation(_progressColor(goal)),
              minHeight: 4,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '$_currencySymbol${_formatter.format(goal.monthlyTarget)}/mo · ${goal.monthsRemaining} months left',
              style: AppTextStyles.labelS.copyWith(color: AppColors.gray500),
            ),
          ),
        ],
      ),
    );

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.1),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
      child: FadeTransition(opacity: animation, child: row),
    );
  }

  Color _progressColor(SavingsGoalModel goal) {
    switch (goal.health) {
      case GoalHealth.completed:
        return AppColors.green;
      case GoalHealth.onTrack:
        return AppColors.black;
      case GoalHealth.atRisk:
        return AppColors.orange;
      case GoalHealth.behind:
        return AppColors.red;
    }
  }

  Widget _buildAddButton() {
    return PressableCard(
      onTap: _openAddSheet,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: AppRadius.xl,
          boxShadow: AppShadows.sm,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add, size: 18, color: AppColors.gray500),
            const SizedBox(width: AppSpacing.xs),
            Text(
              'Add Goal',
              style: AppTextStyles.bodyM.copyWith(color: AppColors.gray500),
            ),
          ],
        ),
      ),
    );
  }
}
