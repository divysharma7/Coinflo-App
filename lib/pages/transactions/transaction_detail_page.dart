import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:finance_buddy_app/core/enums.dart';
import 'package:finance_buddy_app/design_system/design_system.dart';
import 'package:finance_buddy_app/data/db.dart';
import 'package:finance_buddy_app/providers/providers.dart';
import 'package:finance_buddy_app/pages/transactions/split_flow_sheet.dart';
import 'package:finance_buddy_app/widgets/common/animations.dart';
import 'package:finance_buddy_app/widgets/common/spendler_bottom_sheet.dart';
import 'package:finance_buddy_app/services/attachment_service.dart';
import 'package:finance_buddy_app/utils/currency_utils.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class TransactionDetailPage extends ConsumerStatefulWidget {
  final int transactionId;
  final bool startInEditMode;

  const TransactionDetailPage({
    super.key,
    required this.transactionId,
    this.startInEditMode = false,
  });

  @override
  ConsumerState<TransactionDetailPage> createState() =>
      _TransactionDetailPageState();
}

class _TransactionDetailPageState
    extends ConsumerState<TransactionDetailPage> {
  bool _editing = false;
  bool _initialEditModePending = false;

  // Edit fields — nullable to avoid leak on save-then-dispose
  TextEditingController? _amountCtrl;
  TextEditingController? _merchantCtrl;
  TextEditingController? _noteCtrl;
  TransactionCategory _category = TransactionCategory.foodAndDrink;
  DateTime _date = DateTime.now();
  TimeOfDay _time = TimeOfDay.now();
  bool _isExpense = true;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _initialEditModePending = widget.startInEditMode;
  }

  void _enterEditMode(SpendlerTransaction t) {
    _amountCtrl?.dispose();
    _merchantCtrl?.dispose();
    _noteCtrl?.dispose();
    _amountCtrl = TextEditingController(text: t.amount.abs().toStringAsFixed(0));
    _merchantCtrl = TextEditingController(text: t.merchant ?? '');
    _noteCtrl = TextEditingController(text: t.note ?? '');
    _category = TransactionCategory.values.firstWhere(
      (c) => c.name == t.category,
      orElse: () => TransactionCategory.foodAndDrink,
    );
    _date = DateTime(t.happenedAt.year, t.happenedAt.month, t.happenedAt.day);
    _time = TimeOfDay.fromDateTime(t.happenedAt);
    _isExpense = t.amount < 0;
    _hasChanges = false;
    setState(() => _editing = true);
  }

  void _cancelEdit() {
    if (_hasChanges) {
      showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Discard changes?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Keep editing'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Discard'),
            ),
          ],
        ),
      ).then((discard) {
        if (discard == true && mounted) setState(() => _editing = false);
      });
    } else {
      setState(() => _editing = false);
    }
  }

  Future<void> _saveChanges(int id) async {
    final amount = double.tryParse(_amountCtrl!.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid amount'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final happenedAt = DateTime(
      _date.year, _date.month, _date.day,
      _time.hour, _time.minute,
    );

    await HapticFeedback.mediumImpact();
    final repo = ref.read(repositoryProvider);
    await repo.updateTransaction(
      id,
      SpendlerTransactionsCompanion(
        amount: Value(_isExpense ? -amount : amount),
        merchant: Value(_merchantCtrl!.text.trim().isEmpty
            ? null
            : _merchantCtrl!.text.trim()),
        category: Value(_category.name),
        happenedAt: Value(happenedAt),
        note: Value(_noteCtrl!.text.trim().isEmpty ? null : _noteCtrl!.text.trim()),
      ),
    );
    if (mounted) {
      setState(() => _editing = false);
    }
  }

  /// Borderless white field surface matching the Add-Expense note field
  /// (`fillColor: white`, `AppRadius.mdLg`). Section labels are rendered as
  /// uppercase eyebrows above each field via [_eyebrow], so no floating label.
  InputDecoration _inputDecor(String hint,
      {String? prefixText, TextStyle? prefixStyle}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTextStyles.bodyM.copyWith(color: AppColors.gray500),
      prefixText: prefixText,
      prefixStyle:
          prefixStyle ?? AppTextStyles.bodyL.copyWith(color: AppColors.black),
      filled: true,
      fillColor: AppColors.white,
      isDense: true,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
      border: const OutlineInputBorder(
          borderRadius: AppRadius.mdLg, borderSide: BorderSide.none),
      enabledBorder: const OutlineInputBorder(
          borderRadius: AppRadius.mdLg, borderSide: BorderSide.none),
      focusedBorder: const OutlineInputBorder(
          borderRadius: AppRadius.mdLg,
          borderSide: BorderSide(color: AppColors.black, width: 1.5)),
    );
  }

  /// Uppercase section eyebrow above a field — `.sec` in the Hi-Fi system.
  Widget _eyebrow(String text) => Padding(
        padding: const EdgeInsets.only(left: 2, bottom: 8),
        child: Text(text, style: AppTextStyles.section.copyWith(fontSize: 11)),
      );

  /// White picker surface (category / date / time) — shadowed card matching
  /// the Add-Expense chips & split row, replacing the old flat gray boxes.
  Widget _pickerCard({required Widget child}) => Container(
        constraints: const BoxConstraints(minHeight: 52),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: AppRadius.mdLg,
          boxShadow: AppShadows.sm,
        ),
        child: child,
      );

  @override
  void dispose() {
    _amountCtrl?.dispose();
    _merchantCtrl?.dispose();
    _noteCtrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final txnAsync = ref.watch(singleTransactionProvider(widget.transactionId));

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: AppBar(
        backgroundColor: AppColors.offWhite,
        scrolledUnderElevation: 0,
        leadingWidth: _editing ? 80 : 64,
        leading: _editing
            ? TextButton(
                onPressed: _cancelEdit,
                child: Text('Cancel',
                    style: AppTextStyles.bodyL.copyWith(color: AppColors.gray500)),
              )
            : Center(
                child: _HeaderIconButton(
                  icon: PhosphorIcons.caretLeft(),
                  tooltip: 'Back',
                  onTap: () => Navigator.pop(context),
                ),
              ),
        centerTitle: true,
        title: Text(_editing ? 'Edit' : 'Details',
            style: AppTextStyles.headingS.copyWith(color: AppColors.black)),
        actions: [
          if (!_editing)
            txnAsync.whenOrNull(
              data: (t) => t != null
                  ? Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.lg),
                      child: _HeaderIconButton(
                        icon: PhosphorIcons.dotsThreeOutline(),
                        tooltip: 'Edit transaction',
                        onTap: () => _enterEditMode(t),
                      ),
                    )
                  : null,
            ) ?? const SizedBox.shrink(),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: txnAsync.when(
        data: (t) {
          if (t == null) {
            return const Center(
              child: Text('Transaction not found',
                  style: TextStyle(color: AppColors.gray500)),
            );
          }
          // C1: Auto-enter edit mode when navigated with startInEditMode
          if (_initialEditModePending && !_editing) {
            _initialEditModePending = false;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _enterEditMode(t);
            });
          }
          return AnimatedSwitcher(
            duration: AppDurations.base,
            child: _editing ? _buildEditMode(t) : _buildReadMode(t),
          );
        },
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.black)),
        error: (_, _) => const Center(
            child: Text('Error', style: TextStyle(color: AppColors.red))),
          ),
        ),
      ),
    );
  }

  // ─── Read Mode ─────────────────────────────────────

  String get _sym => currencySymbol(ref.watch(selectedCurrencyProvider).valueOrNull ?? 'inr');

  Widget _buildReadMode(SpendlerTransaction t) {
    final cat = TransactionCategory.values.firstWhere(
      (c) => c.name == t.category,
      orElse: () => TransactionCategory.foodAndDrink,
    );
    final catColor = AppColors.categoryColor(cat);
    final isUnconfirmed = t.status == 'unconfirmed';
    final isExpense = t.amount < 0;
    final amountColor = isExpense ? AppColors.black : AppColors.green;
    final hasNote = t.note != null && t.note!.isNotEmpty && t.note != t.merchant;
    final amountStr =
        '$_sym${t.amount.abs().toStringAsFixed(t.amount.abs().truncateToDouble() == t.amount.abs() ? 0 : 2)}';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Hero record: 64px tile + name + big mono amount + pill·date ──
          Center(
            child: Column(
              children: [
                const SizedBox(height: AppSpacing.sm),
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.categoryBg(cat),
                    borderRadius: AppRadius.lg,
                  ),
                  child: Icon(cat.iconFill, color: catColor, size: 30),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  t.merchant ?? cat.label,
                  style: AppTextStyles.headingM
                      .copyWith(color: AppColors.black, fontSize: 20),
                ),
                const SizedBox(height: AppSpacing.sm),
                Semantics(
                  label:
                      '${isExpense ? "Expense" : "Income"}, $amountStr',
                  child: Text(
                    '${isExpense ? "−" : "+"}$amountStr',
                    softWrap: false,
                    overflow: TextOverflow.visible,
                    style: AppTextStyles.displayXL.copyWith(
                      fontSize: 38,
                      color: amountColor,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CategoryPill(category: cat.label),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      _relativeDateTime(t.happenedAt),
                      style: AppTextStyles.bodyS.copyWith(color: AppColors.gray500),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),

          // ── Meta card (definition list) ──
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: AppRadius.xl,
              boxShadow: AppShadows.sm,
            ),
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg, vertical: AppSpacing.xxs),
            child: Column(
              children: [
                _dlRows([
                  _DlRow(
                    'Type',
                    Text(isExpense ? 'Expense' : 'Income',
                        style: _dlValueStyle.copyWith(
                            color: isExpense ? AppColors.black : AppColors.green)),
                  ),
                  _DlRow('Category', Text(cat.label, style: _dlValueStyle)),
                  if (t.incomeSource != null)
                    _DlRow(
                        'Source',
                        Text(
                            t.incomeSource![0].toUpperCase() +
                                t.incomeSource!.substring(1),
                            style: _dlValueStyle)),
                  _DlRow('Date',
                      Text(DateFormat('d MMM yyyy').format(t.happenedAt), style: _dlValueStyle)),
                  _DlRow('Time',
                      Text(DateFormat('h:mm a').format(t.happenedAt), style: _dlValueStyle)),
                  _DlRow(
                    'Status',
                    Text(isUnconfirmed ? 'Unconfirmed' : 'Confirmed',
                        style: _dlValueStyle.copyWith(
                            color: isUnconfirmed
                                ? AppColors.orange
                                : AppColors.catGreenText)),
                  ),
                  _DlRow(
                    'Counts toward budget',
                    Text(isExpense ? 'Yes' : 'No',
                        style: _dlValueStyle.copyWith(
                            color: isExpense
                                ? AppColors.catGreenText
                                : AppColors.gray500)),
                  ),
                  if (t.isSplit) ...[
                    _DlRow('Split', Text('${t.splitCount} people', style: _dlValueStyle)),
                    _DlRow('My share',
                        Text('$_sym${t.splitMyShare?.toStringAsFixed(0) ?? "—"}',
                            style: _dlValueStyle)),
                    _DlRow('Pending',
                        Text('$_sym${t.splitPendingAmount?.toStringAsFixed(0) ?? "0"}',
                            style: _dlValueStyle)),
                    _DlRow(
                      'Settled',
                      Text(t.splitSettled ? 'Yes' : 'No',
                          style: _dlValueStyle.copyWith(
                              color: t.splitSettled
                                  ? AppColors.catGreenText
                                  : AppColors.gray500)),
                    ),
                  ],
                ]),
              ],
            ),
          ),

          // ── Note section ──
          if (hasNote) ...[
            const SizedBox(height: AppSpacing.xl),
            Text('Note', style: AppTextStyles.section),
            const SizedBox(height: AppSpacing.xs),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: AppRadius.xl,
                boxShadow: AppShadows.sm,
              ),
              child: Text(
                t.note!,
                style: AppTextStyles.bodyM
                    .copyWith(color: AppColors.gray600, height: 1.5),
              ),
            ),
          ],

          // ── Attachment ──
          if (t.attachmentPath != null) ...[
            const SizedBox(height: AppSpacing.lg),
            Semantics(
              label: 'Attached receipt image. Tap to view full size.',
              button: true,
              onTap: () => context.push('/attachment-viewer', extra: t.attachmentPath!),
              child: ExcludeSemantics(
                child: GestureDetector(
                  onTap: () => context.push('/attachment-viewer', extra: t.attachmentPath!),
                  child: ClipRRect(
                    borderRadius: AppRadius.lg,
                    child: Image.file(
                      File(t.attachmentPath!),
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.xl),

          // ── Secondary action chips (attach / split) ──
          Row(
            children: [
              Expanded(
                child: _actionChip(
                  icon: PhosphorIcons.paperclip(),
                  label: t.attachmentPath != null ? 'Replace bill' : 'Attach bill',
                  semanticLabel: t.attachmentPath != null ? 'Replace attached bill' : 'Attach a bill photo',
                  onTap: () => _pickAttachment(t),
                ),
              ),
              if (!t.isSplit && isExpense) ...[
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _actionChip(
                    icon: PhosphorIcons.users(),
                    label: 'Split',
                    semanticLabel: 'Split this expense',
                    onTap: () {
                      showSpendlerSheet<void>(
                        context: context,
                        builder: (_) => SplitFlowSheet(
                          transactionId: t.id, totalAmount: t.amount.abs(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),

          if (isUnconfirmed) ...[
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: () async {
                  final repo = ref.read(repositoryProvider);
                  await repo.confirmTransaction(t.id);
                  if (mounted) Navigator.pop(context);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.black,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(borderRadius: AppRadius.base),
                ),
                child: const Text('Confirm Transaction'),
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.lg),

          // ── Primary actions: Edit (ghost) + Delete (danger) ──
          Row(
            children: [
              Expanded(
                child: _bigButton(
                  icon: PhosphorIcons.pencilSimple(),
                  label: 'Edit',
                  foreground: AppColors.black,
                  onTap: () => _enterEditMode(t),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _bigButton(
                  icon: PhosphorIcons.trash(),
                  label: 'Delete',
                  foreground: AppColors.red,
                  onTap: () => _confirmDelete(t.id),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  /// Relative "Today/Yesterday · 9:02 PM" line, matching the Hi-Fi design.
  String _relativeDateTime(DateTime when) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(when.year, when.month, when.day);
    final diff = today.difference(day).inDays;
    final time = DateFormat('h:mm a').format(when);
    if (diff == 0) return 'Today · $time';
    if (diff == 1) return 'Yesterday · $time';
    return '${DateFormat('d MMM').format(when)} · $time';
  }

  static const TextStyle _dlValueStyle = TextStyle(
    fontFamily: AppTextStyles.uiFont,
    fontSize: 14.5,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    color: AppColors.black,
  );

  /// Renders a definition list with hairline dividers between rows.
  Widget _dlRows(List<_DlRow> rows) {
    final children = <Widget>[];
    for (var i = 0; i < rows.length; i++) {
      if (i > 0) {
        children.add(const Divider(height: 1, thickness: 1, color: AppColors.gray100));
      }
      children.add(rows[i]);
    }
    return Column(children: children);
  }

  Widget _bigButton({
    required IconData icon,
    required String label,
    required Color foreground,
    required VoidCallback onTap,
  }) {
    return PressableCard(
      onTap: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: AppRadius.full,
          boxShadow: AppShadows.sm,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            PhosphorIcon(icon, size: 18, color: foreground),
            const SizedBox(width: AppSpacing.xs),
            Text(label,
                style: AppTextStyles.headingS
                    .copyWith(color: foreground, fontSize: 15)),
          ],
        ),
      ),
    );
  }

  Widget _actionChip({
    required IconData icon,
    required String label,
    required String semanticLabel,
    required VoidCallback onTap,
  }) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: PressableCard(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: AppRadius.full,
            boxShadow: AppShadows.sm,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              PhosphorIcon(icon, size: 16, color: AppColors.gray600),
              const SizedBox(width: AppSpacing.xs),
              Text(label, style: AppTextStyles.bodyM.copyWith(color: AppColors.gray600, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickAttachment(SpendlerTransaction t) async {
    final source = await showSpendlerSheet<ImageSource>(
      context: context,
      isScrollControlled: false,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;
    final path = await AttachmentService().pickAndSave(source);
    if (path == null || !mounted) return;
    final repo = ref.read(repositoryProvider);
    await repo.updateTransaction(
      t.id,
      SpendlerTransactionsCompanion(attachmentPath: Value(path)),
    );
  }

  Future<void> _confirmDelete(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete this transaction?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final repo = ref.read(repositoryProvider);
      await repo.deleteTransaction(id);
      if (mounted) Navigator.pop(context);
    }
  }

  // ─── Edit Mode ─────────────────────────────────────

  Widget _buildEditMode(SpendlerTransaction t) {
    final amountStyle = AppTextStyles.numericL.copyWith(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
      color: AppColors.black,
    );
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Type toggle — design-system pill segmented control
          AppSegmentedControl(
            segments: const ['Expense', 'Income'],
            selectedIndex: _isExpense ? 0 : 1,
            onChanged: (i) => setState(() {
              _isExpense = i == 0;
              _hasChanges = true;
            }),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Amount
          _eyebrow('AMOUNT'),
          TextField(
            controller: _amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: amountStyle,
            cursorColor: AppColors.black,
            decoration: _inputDecor('0',
                prefixText: '$_sym ', prefixStyle: amountStyle),
            onChanged: (_) => _hasChanges = true,
          ),
          const SizedBox(height: AppSpacing.lg),

          // Merchant
          _eyebrow('MERCHANT'),
          TextField(
            controller: _merchantCtrl,
            textCapitalization: TextCapitalization.words,
            style: AppTextStyles.bodyL.copyWith(color: AppColors.black),
            cursorColor: AppColors.black,
            decoration: _inputDecor('Where was this?'),
            onChanged: (_) => _hasChanges = true,
          ),
          const SizedBox(height: AppSpacing.lg),

          // Category picker
          _eyebrow('CATEGORY'),
          Semantics(
            button: true,
            label: 'Category: ${_category.label}. Tap to change.',
            onTap: _pickCategory,
            child: ExcludeSemantics(
              child: PressableCard(
                onTap: _pickCategory,
                child: _pickerCard(
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: AppColors.categoryBg(_category),
                          borderRadius: AppRadius.xs,
                        ),
                        child: Icon(_category.iconFill,
                            color: AppColors.categoryColor(_category),
                            size: 17),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(_category.label,
                          style: AppTextStyles.bodyL
                              .copyWith(color: AppColors.black)),
                      const Spacer(),
                      PhosphorIcon(PhosphorIcons.caretDown(),
                          color: AppColors.gray500, size: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Date + Time row
          _eyebrow('WHEN'),
          Row(
            children: [
              Expanded(
                child: Semantics(
                  button: true,
                  label:
                      'Date: ${DateFormat('d MMM yyyy').format(_date)}. Tap to change.',
                  onTap: () => _pickDate(),
                  child: ExcludeSemantics(
                    child: PressableCard(
                      onTap: () => _pickDate(),
                      child: _pickerCard(
                        child: Row(
                          children: [
                            PhosphorIcon(PhosphorIcons.calendar(),
                                color: AppColors.gray500, size: 18),
                            const SizedBox(width: AppSpacing.xs),
                            Flexible(
                              child: Text(
                                  DateFormat('d MMM yyyy').format(_date),
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.bodyM
                                      .copyWith(color: AppColors.black)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Semantics(
                  button: true,
                  label: 'Time: ${_time.format(context)}. Tap to change.',
                  onTap: () => _pickTime(),
                  child: ExcludeSemantics(
                    child: PressableCard(
                      onTap: () => _pickTime(),
                      child: _pickerCard(
                        child: Row(
                          children: [
                            PhosphorIcon(PhosphorIcons.clock(),
                                color: AppColors.gray500, size: 18),
                            const SizedBox(width: AppSpacing.xs),
                            Flexible(
                              child: Text(_time.format(context),
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.bodyM
                                      .copyWith(color: AppColors.black)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Note
          _eyebrow('NOTE (OPTIONAL)'),
          TextField(
            controller: _noteCtrl,
            style: AppTextStyles.bodyM.copyWith(color: AppColors.black),
            cursorColor: AppColors.black,
            maxLength: 200,
            maxLines: 3,
            minLines: 1,
            decoration: _inputDecor('Add a note'),
            onChanged: (_) => _hasChanges = true,
          ),

          const SizedBox(height: AppSpacing.xl),

          // Save button — design-system pill (AppButton)
          AppButton(
            label: 'Save Changes',
            onTap: () => _saveChanges(t.id),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: monoPickerBuilder,
    );
    if (picked != null && mounted) {
      setState(() {
        _date = picked;
        _hasChanges = true;
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time,
      builder: monoPickerBuilder,
    );
    if (picked != null && mounted) {
      setState(() {
        _time = picked;
        _hasChanges = true;
      });
    }
  }

  void _pickCategory() {
    showSpendlerSheet<void>(
      context: context,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('CATEGORY', style: AppTextStyles.labelM),
          const SizedBox(height: AppSpacing.md),
          ...TransactionCategory.values.map((cat) {
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
                setState(() { _category = cat; _hasChanges = true; });
                Navigator.pop(context);
              },
            );
          }),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }

}

/// A single `.dl-row` — left key (gray500) and a right value widget.
class _DlRow extends StatelessWidget {
  const _DlRow(this.label, this.value);

  final String label;
  final Widget value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: AppTextStyles.bodyM.copyWith(
              color: AppColors.gray500,
              fontWeight: FontWeight.w500,
              height: 1.0,
            ),
          ),
          Flexible(
            child: Align(
              alignment: Alignment.centerRight,
              child: value,
            ),
          ),
        ],
      ),
    );
  }
}

/// Round white icon button used in the detail header (`.icon-btn`).
class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppColors.white,
        shape: const CircleBorder(),
        elevation: 0,
        shadowColor: Colors.transparent,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.white,
              shape: BoxShape.circle,
              boxShadow: AppShadows.sm,
            ),
            child: PhosphorIcon(icon, size: 19, color: AppColors.black),
          ),
        ),
      ),
    );
  }
}
