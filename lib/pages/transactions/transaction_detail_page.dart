import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:finance_buddy_app/core/enums.dart';
import 'package:finance_buddy_app/core/tokens.dart';
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
    if (amount == null || amount <= 0) return;

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
      labelStyle: const TextStyle(color: SpendlerColors.textSecondary, fontSize: 13),
      filled: true,
      fillColor: SpendlerColors.surface,
      border: const UnderlineInputBorder(borderSide: BorderSide(color: SpendlerColors.border)),
      enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: SpendlerColors.border)),
      focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: SpendlerColors.yellow)),
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
                    style: TextStyle(color: SpendlerColors.textSecondary)),
              )
            : null,
        title: Text(_editing ? 'Edit' : ''),
        actions: [
          if (!_editing)
            txnAsync.whenOrNull(
              data: (t) => t != null
                  ? IconButton(
                      icon: PhosphorIcon(PhosphorIcons.pencilSimple(),
                          color: SpendlerColors.textSecondary),
                      onPressed: () => _enterEditMode(t),
                    )
                  : null,
            ) ?? const SizedBox.shrink(),
        ],
      ),
      body: txnAsync.when(
        data: (t) {
          if (t == null) {
            return const Center(
              child: Text('Transaction not found',
                  style: TextStyle(color: SpendlerColors.textTertiary)),
            );
          }
          return _editing ? _buildEditMode(t) : _buildReadMode(t);
        },
        loading: () => const Center(
            child: CircularProgressIndicator(color: SpendlerColors.yellow)),
        error: (_, _) => const Center(
            child: Text('Error', style: TextStyle(color: SpendlerColors.expense))),
      ),
    );
  }

  // ─── Read Mode ─────────────────────────────────────

  Widget _buildReadMode(SpendlerTransaction t) {
    final cat = TransactionCategory.values.firstWhere(
      (c) => c.name == t.category,
      orElse: () => TransactionCategory.foodAndDrink,
    );
    final catColor = SpendlerColors.categoryColor(cat);
    final isUnconfirmed = t.status == 'unconfirmed';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: catColor.withValues(alpha: 0.15),
            child: Icon(cat.iconFill, color: catColor, size: 32),
          ),
          const SizedBox(height: SpendlerSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                t.amount < 0 ? '-\$' : '+\$',
                style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w400,
                  color: t.amount < 0 ? SpendlerColors.expense : SpendlerColors.income,
                ),
              ),
              Text(
                t.amount.abs().toStringAsFixed(0),
                style: TextStyle(
                  fontSize: 40, fontWeight: FontWeight.bold,
                  color: t.amount < 0 ? SpendlerColors.expense : SpendlerColors.income,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(t.merchant ?? cat.label, style: SpendlerTextStyles.merchantName.copyWith(fontSize: 20)),
          Text(
            DateFormat('EEEE, d MMM yyyy • h:mm a').format(t.happenedAt),
            style: const TextStyle(color: SpendlerColors.textTertiary),
          ),
          if (t.note != null && t.note!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(t.note!, style: const TextStyle(color: SpendlerColors.textSecondary)),
          ],
          const SizedBox(height: SpendlerSpacing.lg),

          // Details card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(SpendlerSpacing.cardPadding),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [Color(0xFF1E1E1E), SpendlerColors.surface],
              ),
              borderRadius: BorderRadius.circular(SpendlerRadii.card),
              boxShadow: SpendlerShadows.card,
            ),
            child: Column(
              children: [
                _detailRow('Category', cat.label),
                _detailRow('Source', t.source == 'sms_auto' ? 'SMS Auto' : 'Manual'),
                _detailRow('Status', isUnconfirmed ? 'Unconfirmed' : 'Confirmed'),
                if (t.isSplit) ...[
                  _detailRow('Split', '${t.splitCount} people'),
                  _detailRow('My Share', '\$${t.splitMyShare?.toStringAsFixed(0) ?? "—"}'),
                  _detailRow('Pending', '\$${t.splitPendingAmount?.toStringAsFixed(0) ?? "0"}'),
                  _detailRow('Settled', t.splitSettled ? 'Yes' : 'No'),
                ],
              ],
            ),
          ),
          const SizedBox(height: SpendlerSpacing.lg),

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
                  backgroundColor: SpendlerColors.yellow, foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SpendlerRadii.button)),
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
                  foregroundColor: SpendlerColors.textPrimary,
                  side: const BorderSide(color: SpendlerColors.border),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SpendlerRadii.button)),
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
              icon: const Icon(Icons.delete_outline, color: SpendlerColors.expense),
              label: const Text('Delete', style: TextStyle(color: SpendlerColors.expense)),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Edit Mode ─────────────────────────────────────

  Widget _buildEditMode(SpendlerTransaction t) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
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
          const SizedBox(height: SpendlerSpacing.lg),

          // Amount
          TextField(
            controller: _amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: SpendlerTextStyles.greeting,
            cursorColor: SpendlerColors.yellow,
            decoration: _inputDecor('Amount'),
            onChanged: (_) => _hasChanges = true,
          ),
          const SizedBox(height: SpendlerSpacing.md),

          // Merchant
          TextField(
            controller: _merchantCtrl,
            textCapitalization: TextCapitalization.words,
            style: const TextStyle(color: SpendlerColors.textPrimary, fontSize: 16),
            cursorColor: SpendlerColors.yellow,
            decoration: _inputDecor('Merchant'),
            onChanged: (_) => _hasChanges = true,
          ),
          const SizedBox(height: SpendlerSpacing.md),

          // Category picker
          GestureDetector(
            onTap: () => _pickCategory(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: const BoxDecoration(
                color: SpendlerColors.surface,
                border: Border(bottom: BorderSide(color: SpendlerColors.border)),
              ),
              child: Row(
                children: [
                  Icon(_category.iconFill, color: SpendlerColors.categoryColor(_category), size: 20),
                  const SizedBox(width: 10),
                  Text(_category.label, style: const TextStyle(color: SpendlerColors.textPrimary, fontSize: 16)),
                  const Spacer(),
                  PhosphorIcon(PhosphorIcons.caretDown(), color: SpendlerColors.textTertiary, size: 16),
                ],
              ),
            ),
          ),
          const SizedBox(height: SpendlerSpacing.md),

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
                      color: SpendlerColors.surface,
                      border: Border(bottom: BorderSide(color: SpendlerColors.border)),
                    ),
                    child: Row(
                      children: [
                        PhosphorIcon(PhosphorIcons.calendar(), color: SpendlerColors.textSecondary, size: 18),
                        const SizedBox(width: 8),
                        Text(DateFormat('d MMM yyyy').format(_date),
                            style: const TextStyle(color: SpendlerColors.textPrimary, fontSize: 14)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: SpendlerSpacing.sm),
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
                      color: SpendlerColors.surface,
                      border: Border(bottom: BorderSide(color: SpendlerColors.border)),
                    ),
                    child: Row(
                      children: [
                        PhosphorIcon(PhosphorIcons.clock(), color: SpendlerColors.textSecondary, size: 18),
                        const SizedBox(width: 8),
                        Text(_time.format(context),
                            style: const TextStyle(color: SpendlerColors.textPrimary, fontSize: 14)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: SpendlerSpacing.md),

          // Note
          TextField(
            controller: _noteCtrl,
            style: const TextStyle(color: SpendlerColors.textPrimary),
            cursorColor: SpendlerColors.yellow,
            maxLength: 200,
            decoration: _inputDecor('Note (optional)'),
            onChanged: (_) => _hasChanges = true,
          ),

          // Source (read-only)
          const SizedBox(height: SpendlerSpacing.md),
          _detailRow('Source', t.source == 'sms_auto' ? 'SMS Auto' : 'Manual'),

          const SizedBox(height: SpendlerSpacing.xl),

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
          const Text('CATEGORY', style: SpendlerTextStyles.sectionLabel),
          const SizedBox(height: SpendlerSpacing.md),
          ...TransactionCategory.values.map((cat) {
            final selected = _category == cat;
            final catColor = SpendlerColors.categoryColor(cat);
            return ListTile(
              leading: Icon(
                selected ? cat.iconFill : cat.icon,
                color: selected ? catColor : SpendlerColors.textTertiary,
              ),
              title: Text(
                cat.label,
                style: TextStyle(
                  color: selected ? SpendlerColors.textPrimary : SpendlerColors.textSecondary,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
              trailing: selected
                  ? const Icon(Icons.check, color: SpendlerColors.yellow, size: 20)
                  : null,
              onTap: () {
                setState(() { _category = cat; _hasChanges = true; });
                Navigator.pop(context);
              },
            );
          }),
          const SizedBox(height: SpendlerSpacing.md),
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
          Text(label, style: const TextStyle(color: SpendlerColors.textTertiary)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500, color: SpendlerColors.textPrimary)),
        ],
      ),
    );
  }
}
