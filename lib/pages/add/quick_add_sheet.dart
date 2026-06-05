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
import 'package:finance_buddy_app/services/split/split_calculator.dart';
import 'package:finance_buddy_app/data/repositories/split_repository.dart';
import 'package:finance_buddy_app/pages/add/category_search_sheet.dart';
import 'package:finance_buddy_app/pages/add/split_picker_sheet.dart';
import 'package:finance_buddy_app/widgets/common/spendler_bottom_sheet.dart';
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
  bool _saving = false;
  DateTime _selectedDate = DateTime.now();
  Timer? _debounce;
  String _incomeSource = 'salary';
  List<int> _splitPersonIds = [];

  static const List<String> _incomeSources = [
    'salary',
    'freelance',
    'refund',
    'gift',
    'other',
  ];

  static const Map<String, String> _incomeSourceLabels = {
    'salary': 'Salary',
    'freelance': 'Freelance',
    'refund': 'Refund',
    'gift': 'Gift',
    'other': 'Other',
  };

  /// True while the NOTE field is focused — i.e. the system keyboard is up.
  /// The custom numpad and the system keyboard are mutually exclusive (the
  /// design's hybrid model), so the numpad hides whenever this is true and the
  /// amount collapses to a compact summary row.
  bool get _noteEditing => _noteFocus.hasFocus;

  @override
  void initState() {
    super.initState();
    _amountController.addListener(() => setState(() {}));
    // Rebuild on note focus changes so we can swap the custom numpad for the
    // system keyboard (and back) and collapse/expand the amount.
    _noteFocus.addListener(() {
      if (mounted) setState(() {});
    });
  }

  /// Custom-numpad input handler. Mutates [_amountController] through the same
  /// constraints as the original TextField formatters (max 10 chars, up to 2
  /// decimals, single leading dot) so amount parsing/save logic is unchanged.
  void _onKeyTap(String key) {
    HapticFeedback.selectionClick();
    final current = _amountController.text;
    String next = current;
    if (key == '.') {
      if (current.contains('.')) return;
      next = current.isEmpty ? '0.' : '$current.';
    } else {
      if (current == '0') {
        next = key; // replace leading zero
      } else if (current.contains('.') &&
          current.substring(current.indexOf('.') + 1).length >= 2) {
        return; // already 2 decimals
      } else {
        next = '$current$key';
      }
    }
    if (next.length > 10) return;
    _amountController.text = next;
  }

  void _onBackspace() {
    HapticFeedback.selectionClick();
    final current = _amountController.text;
    if (current.isEmpty) return;
    _amountController.text = current.substring(0, current.length - 1);
  }

  /// Long-press the backspace key to clear the whole amount (fast correction).
  void _onClearAmount() {
    if (_amountController.text.isEmpty) return;
    HapticFeedback.mediumImpact();
    _amountController.clear();
  }

  /// Groups the integer part of the in-progress amount for the active currency
  /// locale (e.g. 1,00,000 for INR) while preserving the decimal portion and any
  /// trailing dot the user is mid-typing. The raw controller value is untouched
  /// so parsing/saving stays exact.
  String _formatAmount(String raw, String currency) {
    if (raw.isEmpty) return '0';
    final dotIndex = raw.indexOf('.');
    final intPart = dotIndex == -1 ? raw : raw.substring(0, dotIndex);
    final decPart = dotIndex == -1 ? '' : raw.substring(dotIndex);
    final intValue = int.tryParse(intPart) ?? 0;
    final grouped =
        NumberFormat.decimalPattern(localeFor(currency)).format(intValue);
    return '$grouped$decPart';
  }

  void _onNoteChanged(String text) {
    _debounce?.cancel();
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
      if (mounted &&
          result != null &&
          _noteController.text.trim() == text.trim()) {
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

  /// State 04 of the Add Expense Flow — tapping the category opens the full
  /// searchable list with the current guess pre-selected. A correction is
  /// usually a single tap, after which the AUTO tag is cleared.
  Future<void> _showCategoryPicker() async {
    final picked = await showSpendlerSheet<TransactionCategory>(
      context: context,
      builder: (_) => CategorySearchSheet(selected: _category),
    );
    if (picked != null && mounted) {
      setState(() {
        _category = picked;
        _aiSuggested = false;
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: monoPickerBuilder,
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
    // Whether the system keyboard is up (note focused). showSpendlerSheet already
    // pads the content by viewInsets.bottom, so we must NOT add the nav-bar
    // viewPadding on top of that or it double-counts and overflows by ~24px.
    final keyboardUp = MediaQuery.viewInsetsOf(context).bottom > 0;
    final amountValue = double.tryParse(_amountController.text) ?? 0;

    // ONE stable layout — no tree-swap on note focus. The amount, chips and note
    // keep their positions; only the custom numpad is removed while the system
    // keyboard is up so the two input methods never stack. Everything between the
    // header and the Add button scrolls, so a shrunk viewport (keyboard up) can
    // never overflow — it simply scrolls, and the focused note auto-scrolls into
    // view. The sheet chrome + keyboard-inset padding come from showSpendlerSheet.
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.9,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header — title + circular close button (≥44px hit target)
          Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _isExpense ? 'New expense' : 'New income',
                  style: AppTextStyles.headingM.copyWith(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                  ),
                ),
                _CloseButton(onTap: () => Navigator.pop(context)),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Expense / Income segmented control
          AppSegmentedControl(
            segments: const ['Expense', 'Income'],
            selectedIndex: _isExpense ? 0 : 1,
            onChanged: (i) => setState(() => _isExpense = i == 0),
          ),

          // Scrollable content — stable across amount/note modes.
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'AMOUNT',
                    style: AppTextStyles.section.copyWith(fontSize: 11),
                  ),
                  const SizedBox(height: 10),
                  // Tapping the amount drops the system keyboard (if up) and
                  // brings the numpad back.
                  Semantics(
                    button: true,
                    label:
                        'Amount $symbol${_formatAmount(_amountController.text, currency)}, tap to edit',
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _noteFocus.unfocus(),
                      child: _buildAmount(symbol, amountColor, currency),
                    ),
                  ),
                  const SizedBox(height: 18),
                  // Category + date chips stay visible even while the note is
                  // focused, so the live auto-tag is always confirmable.
                  _buildChips(),
                  const SizedBox(height: AppSpacing.lg),
                  // Note / merchant field (real AI classifier wiring)
                  _buildNoteField(),
                  if (!_isExpense) ...[
                    const SizedBox(height: AppSpacing.md),
                    _buildIncomeSources(),
                  ],
                  if (_isExpense) ...[
                    const SizedBox(height: AppSpacing.sm),
                    _buildSplitRow(),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                ],
              ),
            ),
          ),

          // Custom numpad — amount mode only (hidden while the system
          // keyboard is up for the note so the two never stack).
          if (!_noteEditing) ...[_buildKeypad(), const SizedBox(height: 14)],

          // Primary "Add expense" ink pill — normal-height (no flex)
          SizedBox(
            width: double.infinity,
            height: 54,
            child: _saving
                ? Container(
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: AppColors.black,
                      borderRadius: AppRadius.full,
                    ),
                    child: const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: AppColors.white,
                        strokeWidth: 2.5,
                      ),
                    ),
                  )
                : AppButton(
                    label: _isExpense ? 'Add expense' : 'Add income',
                    onTap: _save,
                    disabled: amountValue <= 0,
                  ),
          ),
          SizedBox(
            height: 8 +
                (keyboardUp ? 0.0 : MediaQuery.viewPaddingOf(context).bottom),
          ),
        ],
      ),
    );
  }

  // ── Big centered amount with blinking ink caret ──────────────
  Widget _buildAmount(String symbol, Color amountColor, String currency) {
    final text = _amountController.text;
    final amountStyle = AppTextStyles.displayXL.copyWith(
      fontSize: 52,
      fontWeight: FontWeight.w700,
      letterSpacing: -2,
      height: 1,
      color: amountColor,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(symbol, style: amountStyle),
        Flexible(
          child: Text(
            _formatAmount(text, currency),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: amountStyle.copyWith(
              color: text.isEmpty
                  ? amountColor.withValues(alpha: 0.4)
                  : amountColor,
            ),
          ),
        ),
        const SizedBox(width: 2),
        const _BlinkingCaret(),
      ],
    );
  }

  // ── Category / date chips (real pickers) ─────────────────────
  Widget _buildChips() {
    final catColor = AppColors.categoryColor(_category);
    final isToday =
        _selectedDate.year == DateTime.now().year &&
        _selectedDate.month == DateTime.now().month &&
        _selectedDate.day == DateTime.now().day;
    final dateLabel = isToday
        ? 'Today'
        : DateFormat('d MMM').format(_selectedDate);

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        // Category chip — expense only. Income has a single fixed category, so
        // no dead, non-functional chip is shown for it.
        if (_isExpense)
          _chip(
            onTap: _showCategoryPicker,
            leading: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: AppColors.categoryBg(_category),
                borderRadius: AppRadius.xs,
              ),
              child: Icon(_category.iconFill, size: 13, color: catColor),
            ),
            label: _category.label,
            highlight: _aiSuggested,
            semanticLabel:
                'Category ${_category.label}${_aiSuggested ? ', auto-tagged' : ''}, tap to change',
          ),
        _chip(
          onTap: _pickDate,
          leading: PhosphorIcon(
            PhosphorIcons.calendar(),
            size: 15,
            color: AppColors.black,
          ),
          label: dateLabel,
          semanticLabel: 'Date $dateLabel, tap to change',
        ),
      ],
    );
  }

  Widget _chip({
    required VoidCallback onTap,
    required Widget leading,
    required String label,
    bool highlight = false,
    String? semanticLabel,
  }) {
    return Semantics(
      button: true,
      label: semanticLabel ?? label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: AppRadius.full,
            boxShadow: AppShadows.sm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              leading,
              const SizedBox(width: 7),
              Text(
                label,
                style: AppTextStyles.bodyM.copyWith(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.black,
                ),
              ),
              if (highlight) ...[const SizedBox(width: 6), _autoBadge()],
            ],
          ),
        ),
      ),
    );
  }

  /// Sparkle + "AUTO" pill shown on the category chip once the AI classifier
  /// has filled it in — design state 02/03 trust signal (reversible in one tap).
  Widget _autoBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.aiPurple.withValues(alpha: 0.12),
        borderRadius: AppRadius.full,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PhosphorIcon(
            PhosphorIcons.sparkle(PhosphorIconsStyle.fill),
            size: 10,
            color: AppColors.aiPurple,
          ),
          const SizedBox(width: 3),
          const Text(
            'AUTO',
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: AppColors.aiPurple,
            ),
          ),
        ],
      ),
    );
  }

  // ── Note field (AI classifier wiring preserved) ──────────────
  // Design state 01: a "NOTE" field label, a pencil-prefixed input, and a
  // helper hint that promises the live auto-tag until the AI has tagged it.
  Widget _buildNoteField() {
    final showAutoTagHint = _isExpense && !_aiSuggested;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 8),
          child: Text(
            'NOTE',
            style: AppTextStyles.section.copyWith(fontSize: 11),
          ),
        ),
        TextField(
          controller: _noteController,
          focusNode: _noteFocus,
          onChanged: _onNoteChanged,
          onSubmitted: (_) => _noteFocus.unfocus(),
          textInputAction: TextInputAction.done,
          textCapitalization: TextCapitalization.sentences,
          style: AppTextStyles.bodyM.copyWith(color: AppColors.black),
          decoration: InputDecoration(
            hintText: 'What was this for?',
            hintStyle: AppTextStyles.bodyM.copyWith(color: AppColors.gray500),
            filled: true,
            fillColor: AppColors.white,
            border: const OutlineInputBorder(
              borderRadius: AppRadius.mdLg,
              borderSide: BorderSide.none,
            ),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.sm,
            ),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: AppSpacing.sm, right: AppSpacing.xs),
              child: PhosphorIcon(
                PhosphorIcons.pencilSimple(),
                size: 18,
                color: AppColors.gray500,
              ),
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 0,
              minHeight: 0,
            ),
            suffixIcon: _classifying
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.gray500,
                      ),
                    ),
                  )
                : null,
          ),
        ),
        if (showAutoTagHint)
          Padding(
            padding: const EdgeInsets.only(left: 2, top: 8),
            child: Text(
              "Type a note and we'll auto-tag the category.",
              style: AppTextStyles.bodyS.copyWith(color: AppColors.gray500),
            ),
          ),
      ],
    );
  }

  // ── Income source chips (income mode) ────────────────────────
  Widget _buildIncomeSources() {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: _incomeSources.map((source) {
        final selected = _incomeSource == source;
        return GestureDetector(
          onTap: () => setState(() => _incomeSource = source),
          child: AnimatedContainer(
            duration: AppDurations.normal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.green.withValues(alpha: 0.12)
                  : AppColors.white,
              borderRadius: AppRadius.full,
              boxShadow: selected ? null : AppShadows.sm,
              border: selected
                  ? Border.all(color: AppColors.green.withValues(alpha: 0.4))
                  : null,
            ),
            child: Text(
              _incomeSourceLabels[source]!,
              style: AppTextStyles.bodyM.copyWith(
                fontSize: 13.5,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected ? AppColors.green : AppColors.gray500,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Split-with row (expense mode) ────────────────────────────
  Widget _buildSplitRow() {
    final active = _splitPersonIds.isNotEmpty;
    return GestureDetector(
      onTap: _openSplitPicker,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: AppRadius.mdLg,
          boxShadow: AppShadows.sm,
          border: active
              ? Border.all(color: AppColors.black.withValues(alpha: 0.2))
              : null,
        ),
        child: Row(
          children: [
            PhosphorIcon(
              PhosphorIcons.users(),
              size: 18,
              color: active ? AppColors.black : AppColors.gray500,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                active
                    ? 'Split ${_splitPersonIds.length + 1} ways'
                    : 'Split with...',
                style: AppTextStyles.bodyM.copyWith(
                  color: active ? AppColors.black : AppColors.gray500,
                  fontWeight: active ? FontWeight.w500 : FontWeight.w400,
                ),
              ),
            ),
            if (active)
              GestureDetector(
                onTap: () => setState(() => _splitPersonIds = []),
                child: PhosphorIcon(
                  PhosphorIcons.x(),
                  size: 16,
                  color: AppColors.gray500,
                ),
              )
            else
              PhosphorIcon(
                PhosphorIcons.caretRight(),
                size: 14,
                color: AppColors.gray500,
              ),
          ],
        ),
      ),
    );
  }

  // ── Custom numpad — 3 cols × 4 rows, 56px keys, 4px gaps (design .keypad) ──
  Widget _buildKeypad() {
    Widget rowOf(List<Widget> cells) => Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(child: cells[0]),
          const SizedBox(width: 4),
          Expanded(child: cells[1]),
          const SizedBox(width: 4),
          Expanded(child: cells[2]),
        ],
      ),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        rowOf([
          _key(label: '1', onTap: () => _onKeyTap('1')),
          _key(label: '2', onTap: () => _onKeyTap('2')),
          _key(label: '3', onTap: () => _onKeyTap('3')),
        ]),
        rowOf([
          _key(label: '4', onTap: () => _onKeyTap('4')),
          _key(label: '5', onTap: () => _onKeyTap('5')),
          _key(label: '6', onTap: () => _onKeyTap('6')),
        ]),
        rowOf([
          _key(label: '7', onTap: () => _onKeyTap('7')),
          _key(label: '8', onTap: () => _onKeyTap('8')),
          _key(label: '9', onTap: () => _onKeyTap('9')),
        ]),
        rowOf([
          _key(
            label: '.',
            onTap: () => _onKeyTap('.'),
            semanticLabel: 'decimal point',
          ),
          _key(label: '0', onTap: () => _onKeyTap('0')),
          _key(
            onTap: _onBackspace,
            onLongPress: _onClearAmount,
            semanticLabel: 'backspace, long press to clear',
            child: PhosphorIcon(
              PhosphorIcons.backspace(),
              size: 24,
              color: AppColors.black,
            ),
          ),
        ]),
      ],
    );
  }

  Widget _key({
    String? label,
    Widget? child,
    required VoidCallback onTap,
    VoidCallback? onLongPress,
    String? semanticLabel,
  }) {
    return _NumKey(
      onTap: onTap,
      onLongPress: onLongPress,
      semanticLabel: semanticLabel ?? label,
      child:
          child ??
          Text(
            label!,
            style: AppTextStyles.numericL.copyWith(
              fontSize: 25,
              fontWeight: FontWeight.w600,
              color: AppColors.black,
            ),
          ),
    );
  }

  Future<void> _openSplitPicker() async {
    final result = await showSpendlerSheet<SplitPickerResult>(
      context: context,
      builder: (_) => const SplitPickerSheet(),
    );
    if (result != null && mounted) {
      setState(() => _splitPersonIds = result.personIds);
    }
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
          ref.read(selectedCurrencyProvider).valueOrNull ?? 'inr',
        );
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
    final hasSplit = _isExpense && _splitPersonIds.isNotEmpty;

    final splits = hasSplit
        ? SplitCalculator.equal(amount, _splitPersonIds)
        : <SplitEntry>[];
    final userShare = hasSplit
        ? splits.firstWhere((s) => s.personId == null).shareAmount
        : amount;

    final companion = SpendlerTransactionsCompanion.insert(
      amount: _isExpense ? -amount : amount,
      category: _isExpense ? _category.name : 'income',
      merchant: drift.Value(merchant),
      // The single free-text field is the merchant/description shown on tiles;
      // `note` stays null (a separate note can be added later from the detail
      // view) so the same string is never stored in two columns.
      note: const drift.Value(null),
      happenedAt: drift.Value(_selectedDate),
      source: const drift.Value('manual'),
      status: const drift.Value('confirmed'),
      incomeSource: _isExpense
          ? const drift.Value(null)
          : drift.Value(_incomeSource),
    );

    // Atomic: a split expense persists the transaction, its splits, and the
    // split-metadata columns in a single db.transaction so a crash can never
    // orphan splits or leave the full amount leaking into category totals.
    if (hasSplit) {
      await repo.insertTransactionWithSplits(
        companion,
        splits,
        splitCount: _splitPersonIds.length + 1,
        splitMyShare: userShare,
        splitPendingAmount: amount - userShare,
      );
    } else {
      await repo.insertTransaction(companion);
    }

    // ── Spending alerts (fire-and-forget) ────────────────
    unawaited(
      SpendingAlertService.instance.checkBudgetAlerts(
        repo,
        NotificationService(),
      ),
    );

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
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.sm),
        ),
      );
    }
  }
}

/// Single numpad key — radius-16 cell that tints [AppColors.gray100] while
/// pressed, mirroring the `.key:active` rule in the CoinFlo Hi-Fi system.
class _NumKey extends StatefulWidget {
  const _NumKey({
    required this.onTap,
    required this.child,
    this.onLongPress,
    this.semanticLabel,
  });

  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final String? semanticLabel;
  final Widget child;

  @override
  State<_NumKey> createState() => _NumKeyState();
}

class _NumKeyState extends State<_NumKey> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: AnimatedContainer(
          duration: AppDurations.fast,
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _pressed ? AppColors.gray100 : Colors.transparent,
            borderRadius: AppRadius.mdLg,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

/// Self-contained blinking ink caret. Owns its own 550ms timer so the parent
/// sheet no longer rebuilds twice a second just to toggle the caret (the rest of
/// the form — amount, chips, numpad — stays still between keystrokes).
class _BlinkingCaret extends StatefulWidget {
  const _BlinkingCaret();

  @override
  State<_BlinkingCaret> createState() => _BlinkingCaretState();
}

class _BlinkingCaretState extends State<_BlinkingCaret> {
  bool _on = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 550), (_) {
      if (mounted) setState(() => _on = !_on);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        width: 3,
        height: 44,
        decoration: BoxDecoration(
          color: _on
              ? AppColors.black.withValues(alpha: 0.85)
              : Colors.transparent,
          borderRadius: AppRadius.xxs,
        ),
      ),
    );
  }
}

/// Circular close button — 34px visual puck inside a ≥44px hit target, labelled
/// for screen readers.
class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Close',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                color: AppColors.white,
                shape: BoxShape.circle,
                boxShadow: AppShadows.sm,
              ),
              child: const Icon(Icons.close, size: 18, color: AppColors.black),
            ),
          ),
        ),
      ),
    );
  }
}
