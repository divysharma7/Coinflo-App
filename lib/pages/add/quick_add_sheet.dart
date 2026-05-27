import 'dart:async';

import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:finance_buddy_app/core/enums.dart';
import 'package:finance_buddy_app/data/db.dart';
import 'package:finance_buddy_app/design_system/design_system.dart';
import 'package:finance_buddy_app/providers/providers.dart';
import 'package:finance_buddy_app/services/notifications/notification_service.dart';
import 'package:finance_buddy_app/services/notifications/spending_alert_service.dart';
import 'package:finance_buddy_app/widgets/common/spendler_bottom_sheet.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:finance_buddy_app/utils/currency_utils.dart';

class QuickAddSheet extends ConsumerStatefulWidget {
  const QuickAddSheet({super.key});

  @override
  ConsumerState<QuickAddSheet> createState() => _QuickAddSheetState();
}

class _QuickAddSheetState extends ConsumerState<QuickAddSheet> {
  final _amountController = TextEditingController();
  TransactionCategory _category = TransactionCategory.foodAndDrink;
  final _noteController = TextEditingController();
  final _noteFocus = FocusNode();
  final _amountFocus = FocusNode();
  bool _isExpense = true;
  bool _aiSuggested = false;
  bool _classifying = false;
  bool _hasTyped = false;
  bool _saving = false;
  DateTime _selectedDate = DateTime.now();
  Timer? _debounce;
  String _incomeSource = 'salary';

  static const List<String> _incomeSources = [
    'salary', 'freelance', 'refund', 'gift', 'other',
  ];

  static const Map<String, String> _incomeSourceLabels = {
    'salary': 'Salary',
    'freelance': 'Freelance',
    'refund': 'Refund',
    'gift': 'Gift',
    'other': 'Other',
  };

  @override
  void initState() {
    super.initState();
    _amountController.addListener(() => setState(() {}));
  }

  void _onNoteChanged(String text) {
    _debounce?.cancel();
    if (!_hasTyped && text.trim().isNotEmpty) {
      setState(() => _hasTyped = true);
    }
    if (text.trim().length < 3) {
      setState(() {
        _aiSuggested = false;
        _classifying = false;
      });
      return;
    }
    setState(() => _classifying = true);
    _debounce = Timer(AppDurations.debounce, () async {
      final classifier = ref.read(categoryClassifierProvider);
      final result = await classifier.classify(text.trim());
      if (mounted && result != null && _noteController.text.trim() == text.trim()) {
        setState(() {
          _category = result;
          _aiSuggested = true;
          _classifying = false;
        });
      } else if (mounted) {
        setState(() => _classifying = false);
      }
    });
  }

  void _showCategoryPicker() {
    showSpendlerSheet<void>(
      context: context,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('CATEGORY', style: AppTextStyles.labelM),
          const SizedBox(height: AppSpacing.md),
          ...TransactionCategory.groups.map((cat) {
            final selected = _category == cat;
            final catColor = AppColors.categoryColor(cat);
            return ListTile(
              leading: Icon(
                selected ? cat.iconFill : cat.icon,
                color: selected ? catColor : AppColors.gray500,
              ),
              title: Text(
                cat.label,
                style: TextStyle(
                  color: selected ? AppColors.black : AppColors.gray500,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
              trailing: selected
                  ? const Icon(Icons.check, color: AppColors.black, size: 20)
                  : null,
              onTap: () {
                setState(() {
                  _category = cat;
                  _aiSuggested = false;
                });
                Navigator.pop(context);
              },
            );
          }),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }


  @override
  void dispose() {
    _debounce?.cancel();
    _amountController.dispose();
    _amountFocus.dispose();
    _noteController.dispose();
    _noteFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currencyAsync = ref.watch(selectedCurrencyProvider);
    final currency = currencyAsync.valueOrNull ?? 'inr';
    final symbol = currencySymbol(currency);
    final amountColor = _isExpense ? AppColors.amountNeutral : AppColors.green;
    final bottomPad = MediaQuery.of(context).viewInsets.bottom;
    final catColor = AppColors.categoryColor(_category);
    final isToday = _selectedDate.year == DateTime.now().year &&
        _selectedDate.month == DateTime.now().month &&
        _selectedDate.day == DateTime.now().day;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomPad),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.88,
        child: Column(
          children: [
            // Amount display — tappable with cursor
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(symbol,
                    style: AppTextStyles.headingM.copyWith(color: amountColor)),
                const SizedBox(width: AppSpacing.xxs),
                IntrinsicWidth(
                  child: TextField(
                    controller: _amountController,
                    focusNode: _amountFocus,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                      LengthLimitingTextInputFormatter(10),
                    ],
                    showCursor: true,
                    cursorColor: amountColor,
                    style: AppTextStyles.displayXL.copyWith(color: amountColor),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      isCollapsed: true,
                      hintText: '0',
                      hintStyle: AppTextStyles.displayXL
                          .copyWith(color: amountColor.withValues(alpha: 0.4)),
                    ),
                  ),
                ),
              ],
            ).animate().fadeIn(duration: AppDurations.medium).slideY(begin: -0.1, duration: AppDurations.medium),
            const SizedBox(height: AppSpacing.sm),

            // Expense/Income toggle
            _buildToggle(),
            const SizedBox(height: AppSpacing.md),

            // Scrollable middle section
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date picker row
                    GestureDetector(
                      onTap: _pickDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.gray100,
                          borderRadius: AppRadius.base,
                        ),
                        child: Row(
                          children: [
                            PhosphorIcon(PhosphorIcons.calendar(),
                                size: 18, color: AppColors.gray500),
                            const SizedBox(width: 10),
                            Text(
                              isToday
                                  ? 'Today'
                                  : DateFormat('EEE, d MMM yyyy')
                                      .format(_selectedDate),
                              style: AppTextStyles.bodyM.copyWith(
                                color: isToday
                                    ? AppColors.gray500
                                    : AppColors.black,
                                fontWeight:
                                    isToday ? FontWeight.w400 : FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            PhosphorIcon(PhosphorIcons.caretDown(),
                                size: 14, color: AppColors.gray500),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    // Note / merchant field
                    TextField(
                      controller: _noteController,
                      focusNode: _noteFocus,
                      onChanged: _onNoteChanged,
                      textCapitalization: TextCapitalization.sentences,
                      style:
                          AppTextStyles.bodyM.copyWith(color: AppColors.black),
                      decoration: InputDecoration(
                        hintText: 'What was this for?',
                        hintStyle: AppTextStyles.bodyM
                            .copyWith(color: AppColors.gray500),
                        filled: true,
                        fillColor: AppColors.gray100,
                        border: OutlineInputBorder(
                          borderRadius: AppRadius.base,
                          borderSide: BorderSide.none,
                        ),
                        isDense: true,
                        suffixIcon: _classifying
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(
                                  width: 18, height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.gray500,
                                  ),
                                ),
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Category / Income Source — toggle-driven swap
                    if (_isExpense) ...[
                      Text('Category',
                          style: AppTextStyles.labelS
                              .copyWith(color: AppColors.gray500)),
                      const SizedBox(height: AppSpacing.xs),
                      GestureDetector(
                        onTap: _showCategoryPicker,
                        child: AnimatedContainer(
                          duration: AppDurations.base,
                          curve: Curves.easeOut,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: _aiSuggested || _hasTyped
                                ? catColor.withValues(alpha: 0.10)
                                : AppColors.gray100,
                            borderRadius: AppRadius.lgXl,
                            border: _aiSuggested || _hasTyped
                                ? Border.all(
                                    color: catColor.withValues(alpha: 0.3))
                                : null,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_aiSuggested) ...[
                                PhosphorIcon(
                                  PhosphorIcons.sparkle(
                                      PhosphorIconsStyle.fill),
                                  size: 14,
                                  color: AppColors.aiPurple,
                                ),
                                const SizedBox(width: 6),
                              ],
                              Icon(_category.iconFill, size: 16, color: catColor),
                              const SizedBox(width: 6),
                              Text(
                                _category.label,
                                style: AppTextStyles.bodyM.copyWith(
                                  fontWeight: _aiSuggested || _hasTyped
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  color: _aiSuggested || _hasTyped
                                      ? catColor
                                      : AppColors.gray500,
                                ),
                              ),
                              const SizedBox(width: 8),
                              PhosphorIcon(PhosphorIcons.caretDown(),
                                  size: 14, color: AppColors.gray500),
                            ],
                          ),
                        ),
                      ),
                    ] else ...[
                      Text('Source',
                          style: AppTextStyles.labelS
                              .copyWith(color: AppColors.gray500)),
                      const SizedBox(height: AppSpacing.xs),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _incomeSources.map((source) {
                          final selected = _incomeSource == source;
                          return GestureDetector(
                            onTap: () => setState(() => _incomeSource = source),
                            child: AnimatedContainer(
                              duration: AppDurations.normal,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: selected
                                    ? AppColors.green.withValues(alpha: 0.12)
                                    : AppColors.gray100,
                                borderRadius: AppRadius.lgXl,
                                border: selected
                                    ? Border.all(color: AppColors.green.withValues(alpha: 0.4))
                                    : null,
                              ),
                              child: Text(
                                _incomeSourceLabels[source]!,
                                style: AppTextStyles.bodyM.copyWith(
                                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                                  color: selected ? AppColors.green : AppColors.gray500,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],

                  ],
                ),
              ),
            ),

            // Done button
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: _saving
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.black, strokeWidth: 2.5))
                    : AppButton(
                        label: 'Done',
                        onTap: _save,
                        disabled: _amountController.text.isEmpty,
                      ),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  Widget _buildToggle() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: AppRadius.xxl,
        border: Border.all(color: AppColors.gray200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _toggleButton('Expense', _isExpense, () {
            setState(() => _isExpense = true);
          }),
          _toggleButton('Income', !_isExpense, () {
            setState(() => _isExpense = false);
          }),
        ],
      ),
    );
  }

  Widget _toggleButton(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppDurations.fast,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.black : Colors.transparent,
          borderRadius: AppRadius.xlSm,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              const Icon(Icons.check, size: 16, color: AppColors.white),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: AppTextStyles.bodyS.copyWith(
                fontWeight: FontWeight.w600,
                color: selected ? AppColors.white : AppColors.gray500,
              ),
            ),
          ],
        ),
      ),
    );
  }


  Future<void> _save() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0 || _saving) return;

    setState(() => _saving = true);
    await HapticFeedback.mediumImpact();

    final repo = ref.read(repositoryProvider);

    // ── Duplicate detection ──────────────────────────────
    try {
      final todayTxns = await repo.getTransactionsForDay(DateTime.now());
      final duplicate = todayTxns.any((t) {
        if (t.category != _category.name) return false;
        final existingAmt = t.amount.abs();
        return (existingAmt - amount).abs() <= amount * 0.01;
      });

      if (duplicate && mounted) {
        final symbol = currencySymbol(
            ref.read(selectedCurrencyProvider).valueOrNull ?? 'inr');
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Possible duplicate'),
            content: Text(
              'A similar ${_category.label} expense of $symbol${amount.toStringAsFixed(amount.truncateToDouble() == amount ? 0 : 2)} was already added today. Add anyway?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Add anyway'),
              ),
            ],
          ),
        );
        if (confirmed != true) {
          setState(() => _saving = false);
          return;
        }
      }
    } on Exception catch (_) {
      // Best-effort — proceed with save on error.
    }

    // ── Insert transaction ───────────────────────────────
    final note = _noteController.text.trim();
    final merchant = note.isNotEmpty ? note : null;

    await repo.insertTransaction(
          SpendlerTransactionsCompanion.insert(
            amount: _isExpense ? -amount : amount,
            category: _isExpense ? _category.name : 'income',
            merchant: drift.Value(merchant),
            note: drift.Value(merchant),
            happenedAt: drift.Value(_selectedDate),
            source: const drift.Value('manual'),
            status: const drift.Value('confirmed'),
            incomeSource: _isExpense
                ? const drift.Value(null)
                : drift.Value(_incomeSource),
          ),
        );

    // ── Spending alerts (fire-and-forget) ────────────────
    unawaited(SpendingAlertService.instance.checkBudgetAlerts(
      repo,
      NotificationService(),
    ));

    // Refresh FutureProvider data (StreamProviders auto-update via Drift)
    ref.invalidate(todaySpendingProvider);
    ref.invalidate(todayTopCategoryProvider);
    ref.invalidate(dailySpendingForWeekProvider);
    ref.invalidate(lastMonthExpenseProvider);
    ref.invalidate(monthlyTransactionsForHomeProvider);
    invalidateAnalytics(ref);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${_isExpense ? "Expense" : "Income"} of ${currencySymbol(ref.read(selectedCurrencyProvider).valueOrNull ?? "inr")}${amount.toStringAsFixed(amount.truncateToDouble() == amount ? 0 : 2)} added',
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: AppRadius.sm),
        ),
      );
    }
  }
}
