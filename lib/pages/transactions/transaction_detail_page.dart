import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:finance_buddy_app/core/enums.dart';
import 'package:finance_buddy_app/design_system/design_system.dart';
import 'package:finance_buddy_app/data/db.dart';
import 'package:finance_buddy_app/providers/providers.dart';
import 'package:finance_buddy_app/pages/transactions/split_flow_sheet.dart';
import 'package:finance_buddy_app/widgets/common/neo_pop_button.dart';
import 'package:finance_buddy_app/widgets/common/spendler_bottom_sheet.dart';

class TransactionDetailPage extends ConsumerStatefulWidget {
  final int transactionId;

  const TransactionDetailPage({super.key, required this.transactionId});

  @override
  ConsumerState<TransactionDetailPage> createState() =>
      _TransactionDetailPageState();
}

class _TransactionDetailPageState
    extends ConsumerState<TransactionDetailPage> {
  bool _editing = false;

  // Edit fields
  late TextEditingController _amountCtrl;
  late TextEditingController _merchantCtrl;
  late TextEditingController _noteCtrl;
  TransactionCategory _category = TransactionCategory.foodAndDrink;
  DateTime _date = DateTime.now();
  TimeOfDay _time = TimeOfDay.now();
  bool _isExpense = true;
  bool _hasChanges = false;

  void _enterEditMode(SpendlerTransaction t) {
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
        if (discard == true) setState(() => _editing = false);
      });
    } else {
      setState(() => _editing = false);
    }
  }

  Future<void> _saveChanges(int id) async {
    final amount = double.tryParse(_amountCtrl.text.trim());
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
        merchant: Value(_merchantCtrl.text.trim().isEmpty
            ? null
            : _merchantCtrl.text.trim()),
        category: Value(_category.name),
        happenedAt: Value(happenedAt),
        note: Value(_noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim()),
      ),
    );
    if (mounted) {
      setState(() => _editing = false);
    }
  }

  InputDecoration _inputDecor(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppColors.gray500, fontSize: 13),
      filled: true,
      fillColor: AppColors.white,
      border: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.gray200)),
      enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.gray200)),
      focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.black)),
    );
  }

  @override
  void dispose() {
    if (_editing) {
      _amountCtrl.dispose();
      _merchantCtrl.dispose();
      _noteCtrl.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final txnAsync = ref.watch(singleTransactionProvider(widget.transactionId));

    return Scaffold(
      appBar: AppBar(
        leading: _editing
            ? TextButton(
                onPressed: _cancelEdit,
                child: const Text('Cancel',
                    style: TextStyle(color: AppColors.gray500)),
              )
            : null,
        title: Text(_editing ? 'Edit' : ''),
        actions: [
          if (!_editing)
            txnAsync.whenOrNull(
              data: (t) => t != null
                  ? IconButton(
                      icon: PhosphorIcon(PhosphorIcons.pencilSimple(),
                          color: AppColors.gray500),
                      onPressed: () => _enterEditMode(t),
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
                  style: TextStyle(color: AppColors.gray400)),
            );
          }
          return _editing ? _buildEditMode(t) : _buildReadMode(t);
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

  String get _sym => _currencySymbol(ref.watch(selectedCurrencyProvider).valueOrNull ?? 'inr');

  static String _currencySymbol(String code) {
    switch (code.toLowerCase()) {
      case 'inr': return '\u20B9';
      case 'usd': return '\$';
      case 'eur': return '\u20AC';
      case 'gbp': return '\u00A3';
      case 'jpy': return '\u00A5';
      default: return '\$';
    }
  }

  Widget _buildReadMode(SpendlerTransaction t) {
    final cat = TransactionCategory.values.firstWhere(
      (c) => c.name == t.category,
      orElse: () => TransactionCategory.foodAndDrink,
    );
    final catColor = AppColors.categoryColor(cat);
    final isUnconfirmed = t.status == 'unconfirmed';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: catColor.withValues(alpha: 0.15),
            child: Icon(cat.iconFill, color: catColor, size: 32),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                t.amount < 0 ? '-$_sym' : '+$_sym',
                style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w400,
                  color: t.amount < 0 ? AppColors.red : AppColors.green,
                ),
              ),
              Text(
                t.amount.abs().toStringAsFixed(0),
                style: TextStyle(
                  fontSize: 40, fontWeight: FontWeight.bold,
                  color: t.amount < 0 ? AppColors.red : AppColors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            t.merchant ?? cat.label,
            style: AppTextStyles.bodyM.copyWith(fontSize: 20),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            DateFormat('EEEE, d MMM yyyy • h:mm a').format(t.happenedAt),
            style: const TextStyle(color: AppColors.gray400),
          ),
          if (t.note != null && t.note!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(t.note!, style: const TextStyle(color: AppColors.gray500)),
          ],
          const SizedBox(height: AppSpacing.lg),

          // Details card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [Color(0xFF1E1E1E), AppColors.white],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppShadows.sm,
            ),
            child: Column(
              children: [
                _detailRow('Category', cat.label),
                _detailRow('Source', 'Manual'),
                _detailRow('Status', isUnconfirmed ? 'Unconfirmed' : 'Confirmed'),
                if (t.isSplit) ...[
                  _detailRow('Split', '${t.splitCount} people'),
                  _detailRow('My Share', '$_sym${t.splitMyShare?.toStringAsFixed(0) ?? "—"}'),
                  _detailRow('Pending', '$_sym${t.splitPendingAmount?.toStringAsFixed(0) ?? "0"}'),
                  _detailRow('Settled', t.splitSettled ? 'Yes' : 'No'),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Actions
          if (isUnconfirmed) ...[
            SizedBox(
              width: double.infinity, height: 56,
              child: FilledButton.icon(
                onPressed: () async {
                  final repo = ref.read(repositoryProvider);
                  await repo.confirmTransaction(t.id);
                  if (mounted) Navigator.pop(context);
                },
                icon: const Icon(Icons.check),
                label: const Text('Confirm This'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.black, foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          if (!t.isSplit && t.amount < 0)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  showSpendlerSheet<void>(
                    context: context,
                    builder: (_) => SplitFlowSheet(
                      transactionId: t.id, totalAmount: t.amount.abs(),
                    ),
                  );
                },
                icon: const Icon(Icons.group),
                label: const Text('Split This'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.black,
                  side: const BorderSide(color: AppColors.gray200),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Delete this transaction?'),
                    content: const Text('This cannot be undone.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                      TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
                    ],
                  ),
                );
                if (confirmed == true) {
                  final repo = ref.read(repositoryProvider);
                  await repo.deleteTransaction(t.id);
                  if (mounted) Navigator.pop(context);
                }
              },
              icon: const Icon(Icons.delete_outline, color: AppColors.red),
              label: const Text('Delete', style: TextStyle(color: AppColors.red)),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Edit Mode ─────────────────────────────────────

  Widget _buildEditMode(SpendlerTransaction t) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Type toggle
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: true, label: Text('Expense')),
              ButtonSegment(value: false, label: Text('Income')),
            ],
            selected: {_isExpense},
            onSelectionChanged: (v) => setState(() {
              _isExpense = v.first;
              _hasChanges = true;
            }),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Amount
          TextField(
            controller: _amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: AppTextStyles.headingL,
            cursorColor: AppColors.black,
            decoration: _inputDecor('Amount'),
            onChanged: (_) => _hasChanges = true,
          ),
          const SizedBox(height: AppSpacing.md),

          // Merchant
          TextField(
            controller: _merchantCtrl,
            textCapitalization: TextCapitalization.words,
            style: const TextStyle(color: AppColors.black, fontSize: 16),
            cursorColor: AppColors.black,
            decoration: _inputDecor('Merchant'),
            onChanged: (_) => _hasChanges = true,
          ),
          const SizedBox(height: AppSpacing.md),

          // Category picker
          GestureDetector(
            onTap: () => _pickCategory(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: const BoxDecoration(
                color: AppColors.white,
                border: Border(bottom: BorderSide(color: AppColors.gray200)),
              ),
              child: Row(
                children: [
                  Icon(_category.iconFill, color: AppColors.categoryColor(_category), size: 20),
                  const SizedBox(width: 10),
                  Text(_category.label, style: const TextStyle(color: AppColors.black, fontSize: 16)),
                  const Spacer(),
                  PhosphorIcon(PhosphorIcons.caretDown(), color: AppColors.gray400, size: 16),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Date + Time row
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _date,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) setState(() { _date = picked; _hasChanges = true; });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    decoration: const BoxDecoration(
                      color: AppColors.white,
                      border: Border(bottom: BorderSide(color: AppColors.gray200)),
                    ),
                    child: Row(
                      children: [
                        PhosphorIcon(PhosphorIcons.calendar(), color: AppColors.gray500, size: 18),
                        const SizedBox(width: 8),
                        Text(DateFormat('d MMM yyyy').format(_date),
                            style: const TextStyle(color: AppColors.black, fontSize: 14)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: _time,
                    );
                    if (picked != null) setState(() { _time = picked; _hasChanges = true; });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    decoration: const BoxDecoration(
                      color: AppColors.white,
                      border: Border(bottom: BorderSide(color: AppColors.gray200)),
                    ),
                    child: Row(
                      children: [
                        PhosphorIcon(PhosphorIcons.clock(), color: AppColors.gray500, size: 18),
                        const SizedBox(width: 8),
                        Text(_time.format(context),
                            style: const TextStyle(color: AppColors.black, fontSize: 14)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Note
          TextField(
            controller: _noteCtrl,
            style: const TextStyle(color: AppColors.black),
            cursorColor: AppColors.black,
            maxLength: 200,
            decoration: _inputDecor('Note (optional)'),
            onChanged: (_) => _hasChanges = true,
          ),

          // Source (read-only)
          const SizedBox(height: AppSpacing.md),
          _detailRow('Source', 'Manual'),

          const SizedBox(height: AppSpacing.xl),

          // Save button
          NeoPOPButton(
            label: 'Save Changes',
            onTap: () => _saveChanges(t.id),
          ),
        ],
      ),
    );
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
                color: selected ? catColor : AppColors.gray400,
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

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.gray400)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500, color: AppColors.black)),
        ],
      ),
    );
  }
}
