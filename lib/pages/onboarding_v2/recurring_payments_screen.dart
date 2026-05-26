import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:finance_buddy_app/design_system/design_system.dart';
import 'package:finance_buddy_app/models/recurring_payment_model.dart';
import 'package:finance_buddy_app/widgets/add_payment_sheet.dart';

const List<Map<String, String>> kPaymentPresets = [
  {'name': 'Netflix', 'category': 'Streaming Services'},
  {'name': 'Spotify', 'category': 'Streaming Services'},
  {'name': 'YouTube Premium', 'category': 'Streaming Services'},
  {'name': 'Gym', 'category': 'Gym & Fitness'},
  {'name': 'Phone Bill', 'category': 'Internet & Phone'},
  {'name': 'Internet', 'category': 'Internet & Phone'},
  {'name': 'Electricity', 'category': 'Electricity & Gas'},
  {'name': 'Insurance', 'category': 'Insurance'},
  {'name': 'Rent', 'category': 'Rent & Mortgage'},
  {'name': 'Water Bill', 'category': 'Water'},
];

class RecurringPaymentsScreen extends StatefulWidget {
  const RecurringPaymentsScreen({super.key});

  @override
  State<RecurringPaymentsScreen> createState() =>
      _RecurringPaymentsScreenState();
}

class _RecurringPaymentsScreenState extends State<RecurringPaymentsScreen>
    with SingleTickerProviderStateMixin {
  final List<RecurringPaymentModel> _payments = [];
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  final Set<String> _usedPresets = {};
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

  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    final savedJson = prefs.getString('recurring_payments');
    final List<RecurringPaymentModel> restored = [];
    if (savedJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(savedJson) as List<dynamic>;
        restored.addAll(decoded
            .map((e) =>
                RecurringPaymentModel.fromJson(e as Map<String, dynamic>)));
      } on FormatException catch (_) {
        // Ignore malformed JSON.
      }
    }
    setState(() {
      _currencySymbol = prefs.getString('currency_symbol') ?? '₹';
      if (restored.isNotEmpty) {
        _payments
          ..clear()
          ..addAll(restored);
        _usedPresets.addAll(restored.map((p) => p.name));
      }
    });
  }

  void _openAddSheet({String? presetName, String? presetCategory}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => AddPaymentSheet(
        onSave: _addPayment,
        presetName: presetName,
        presetCategory: presetCategory,
      ),
    );
  }

  void _addPayment(RecurringPaymentModel payment) {
    setState(() {
      _payments.add(payment);
      _usedPresets.add(payment.name);
    });
    _listKey.currentState?.insertItem(
      _payments.length - 1,
      duration: AppDurations.base,
    );
  }

  void _deletePayment(int index) {
    final removed = _payments[index];
    setState(() {
      _payments.removeAt(index);
      _usedPresets.remove(removed.name);
    });
    _listKey.currentState?.removeItem(
      index,
      (context, animation) => _buildPaymentRow(removed, animation),
      duration: AppDurations.fast,
    );
  }

  String get _buttonLabel => _payments.isEmpty ? 'Skip for now' : 'Continue';

  Future<void> _onContinue() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_payments.map((p) => p.toJson()).toList());
    await prefs.setString('recurring_payments', encoded);
    if (mounted) await context.push('/onboarding/step9');
  }

  List<Map<String, String>> get _availablePresets =>
      kPaymentPresets.where((p) => !_usedPresets.contains(p['name'])).toList();

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
            AppBackButton(onTap: () => context.pop()),

            // Title
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
                        'Recurring payments',
                        style: AppTextStyles.headingL
                            .copyWith(color: AppColors.black),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Add subscriptions and bills you pay regularly.',
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
              child: FadeTransition(
                opacity: _contentFade,
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Preset chips
                      if (_availablePresets.isNotEmpty &&
                          _payments.length < 5)
                        Padding(
                          padding:
                              const EdgeInsets.only(bottom: AppSpacing.lg),
                          child: Wrap(
                            spacing: AppSpacing.xs,
                            runSpacing: AppSpacing.xs,
                            children: _availablePresets
                                .map((p) => _buildPresetChip(p))
                                .toList(),
                          ),
                        ),

                      // Payments list
                      AnimatedList(
                        key: _listKey,
                        initialItemCount: _payments.length,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemBuilder: (context, index, animation) {
                          return _buildPaymentRow(
                              _payments[index], animation,
                              index: index);
                        },
                      ),

                      // Add payment button
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

  Widget _buildProgressIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(8, (index) {
        return Container(
          width: 24,
          height: 3,
          margin: EdgeInsets.only(right: index < 7 ? AppSpacing.xs : 0),
          decoration: BoxDecoration(
            color: index < 8 ? AppColors.black : AppColors.gray200,
            borderRadius: AppRadius.full,
          ),
        );
      }),
    );
  }

  Widget _buildPresetChip(Map<String, String> preset) {
    return GestureDetector(
      onTap: () => _openAddSheet(
        presetName: preset['name'],
        presetCategory: preset['category'],
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: AppRadius.full,
          border: Border.all(color: AppColors.gray200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add, size: 14, color: AppColors.gray500),
            const SizedBox(width: AppSpacing.xxs),
            Text(
              preset['name']!,
              style: AppTextStyles.bodyS.copyWith(color: AppColors.black),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentRow(
    RecurringPaymentModel payment,
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
          // Category icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: payment.categoryColor.withValues(alpha: 0.12),
              borderRadius: AppRadius.sm,
            ),
            child: Icon(payment.categoryIcon,
                size: 22, color: payment.categoryColor),
          ),
          const SizedBox(width: AppSpacing.md),
          // Name, category, amount
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(payment.name,
                          style: AppTextStyles.headingS),
                    ),
                    HealthBadge.fromPaymentHealth(payment.health),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  '$_currencySymbol${_formatter.format(payment.amount)}${payment.frequencyLabel} · Due ${payment.dueDayOfMonth}${_daySuffix(payment.dueDayOfMonth)}',
                  style:
                      AppTextStyles.bodyS.copyWith(color: AppColors.gray500),
                ),
              ],
            ),
          ),
          // Delete
          if (index != null)
            Padding(
              padding: const EdgeInsets.only(left: AppSpacing.xs),
              child: GestureDetector(
                onTap: () => _deletePayment(index),
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

  String _daySuffix(int day) {
    if (day >= 11 && day <= 13) return 'th';
    switch (day % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }

  Widget _buildAddButton() {
    return GestureDetector(
      onTap: () => _openAddSheet(),
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
            const Icon(Icons.add, size: 18, color: AppColors.gray400),
            const SizedBox(width: AppSpacing.xs),
            Text(
              'Add Payment',
              style: AppTextStyles.bodyM.copyWith(color: AppColors.gray400),
            ),
          ],
        ),
      ),
    );
  }
}
