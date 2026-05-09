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
import 'package:finance_buddy_app/widgets/common/paisa_bottom_sheet.dart';

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
  TransactionCategory _category = TransactionCategory.other;
  DateTime _date = DateTime.now();
  TimeOfDay _time = TimeOfDay.now();
  bool _isExpense = true;
  bool _hasChanges = false;

  void _enterEditMode(PaisaTransaction t) {
    _amountCtrl = TextEditingController(text: t.amount.abs().toStringAsFixed(0));
    _merchantCtrl = TextEditingController(text: t.merchant ?? '');
    _noteCtrl = TextEditingController(text: t.note ?? '');
    _category = TransactionCategory.values.firstWhere(
      (c) => c.name == t.category,
      orElse: () => TransactionCategory.other,
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
      PaisaTransactionsCompanion(
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
      labelStyle: const TextStyle(color: PaisaColors.textSecondary, fontSize: 13),
      filled: true,
      fillColor: PaisaColors.surface,
      border: const UnderlineInputBorder(borderSide: BorderSide(color: PaisaColors.border)),
      enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: PaisaColors.border)),
      focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: PaisaColors.yellow)),
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
                    style: TextStyle(color: PaisaColors.textSecondary)),
              )
            : null,
        title: Text(_editing ? 'Edit' : ''),
        actions: [
          if (!_editing)
            txnAsync.whenOrNull(
              data: (t) => t != null
                  ? IconButton(
                      icon: PhosphorIcon(PhosphorIcons.pencilSimple(),
                          color: PaisaColors.textSecondary),
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
                  style: TextStyle(color: PaisaColors.textTertiary)),
            );
          }
          return _editing ? _buildEditMode(t) : _buildReadMode(t);
        },
        loading: () => const Center(
            child: CircularProgressIndicator(color: PaisaColors.yellow)),
        error: (_, _) => const Center(
            child: Text('Error', style: TextStyle(color: PaisaColors.expense))),
      ),
    );
  }

  // ─── Read Mode ─────────────────────────────────────

  Widget _buildReadMode(PaisaTransaction t) {
    final cat = TransactionCategory.values.firstWhere(
      (c) => c.name == t.category,
      orElse: () => TransactionCategory.other,
    );
    final catColor = PaisaColors.categoryColor(cat);
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
          const SizedBox(height: PaisaSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                t.amount < 0 ? '-₹' : '+₹',
                style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w400,
                  color: t.amount < 0 ? PaisaColors.expense : PaisaColors.income,
                ),
              ),
              Text(
                t.amount.abs().toStringAsFixed(0),
                style: TextStyle(
                  fontSize: 40, fontWeight: FontWeight.bold,
                  color: t.amount < 0 ? PaisaColors.expense : PaisaColors.income,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(t.merchant ?? cat.label, style: PaisaTextStyles.merchantName.copyWith(fontSize: 20)),
          Text(
            DateFormat('EEEE, d MMM yyyy • h:mm a').format(t.happenedAt),
            style: const TextStyle(color: PaisaColors.textTertiary),
          ),
          if (t.note != null && t.note!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(t.note!, style: const TextStyle(color: PaisaColors.textSecondary)),
          ],
          const SizedBox(height: PaisaSpacing.lg),

          // Details card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(PaisaSpacing.cardPadding),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [Color(0xFF1E1E1E), PaisaColors.surface],
              ),
              borderRadius: BorderRadius.circular(PaisaRadii.card),
              boxShadow: PaisaShadows.card,
            ),
            child: Column(
              children: [
                _detailRow('Category', cat.label),
                _detailRow('Source', t.source == 'sms_auto' ? 'SMS Auto' : 'Manual'),
                _detailRow('Status', isUnconfirmed ? 'Unconfirmed' : 'Confirmed'),
                if (t.isSplit) ...[
                  _detailRow('Split', '${t.splitCount} people'),
                  _detailRow('My Share', '₹${t.splitMyShare?.toStringAsFixed(0) ?? "—"}'),
                  _detailRow('Pending', '₹${t.splitPendingAmount?.toStringAsFixed(0) ?? "0"}'),
                  _detailRow('Settled', t.splitSettled ? 'Yes' : 'No'),
                ],
              ],
            ),
          ),
          const SizedBox(height: PaisaSpacing.lg),

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
                  backgroundColor: PaisaColors.yellow, foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(PaisaRadii.button)),
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
                  showPaisaSheet<void>(
                    context: context,
                    builder: (_) => SplitFlowSheet(
                      transactionId: t.id, totalAmount: t.amount.abs(),
                    ),
                  );
                },
                icon: const Icon(Icons.group),
                label: const Text('Split This'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: PaisaColors.textPrimary,
                  side: const BorderSide(color: PaisaColors.border),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(PaisaRadii.button)),
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
              icon: const Icon(Icons.delete_outline, color: PaisaColors.expense),
              label: const Text('Delete', style: TextStyle(color: PaisaColors.expense)),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Edit Mode ─────────────────────────────────────

  Widget _buildEditMode(PaisaTransaction t) {
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
          const SizedBox(height: PaisaSpacing.lg),

          // Amount
          TextField(
            controller: _amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: PaisaTextStyles.greeting,
            cursorColor: PaisaColors.yellow,
            decoration: _inputDecor('Amount'),
            onChanged: (_) => _hasChanges = true,
          ),
          const SizedBox(height: PaisaSpacing.md),

          // Merchant
          TextField(
            controller: _merchantCtrl,
            textCapitalization: TextCapitalization.words,
            style: const TextStyle(color: PaisaColors.textPrimary, fontSize: 16),
            cursorColor: PaisaColors.yellow,
            decoration: _inputDecor('Merchant'),
            onChanged: (_) => _hasChanges = true,
          ),
          const SizedBox(height: PaisaSpacing.md),

          // Category picker
          GestureDetector(
            onTap: () => _pickCategory(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: const BoxDecoration(
                color: PaisaColors.surface,
                border: Border(bottom: BorderSide(color: PaisaColors.border)),
              ),
              child: Row(
                children: [
                  Icon(_category.iconFill, color: PaisaColors.categoryColor(_category), size: 20),
                  const SizedBox(width: 10),
                  Text(_category.label, style: const TextStyle(color: PaisaColors.textPrimary, fontSize: 16)),
                  const Spacer(),
                  PhosphorIcon(PhosphorIcons.caretDown(), color: PaisaColors.textTertiary, size: 16),
                ],
              ),
            ),
          ),
          const SizedBox(height: PaisaSpacing.md),

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
                      color: PaisaColors.surface,
                      border: Border(bottom: BorderSide(color: PaisaColors.border)),
                    ),
                    child: Row(
                      children: [
                        PhosphorIcon(PhosphorIcons.calendar(), color: PaisaColors.textSecondary, size: 18),
                        const SizedBox(width: 8),
                        Text(DateFormat('d MMM yyyy').format(_date),
                            style: const TextStyle(color: PaisaColors.textPrimary, fontSize: 14)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: PaisaSpacing.sm),
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
                      color: PaisaColors.surface,
                      border: Border(bottom: BorderSide(color: PaisaColors.border)),
                    ),
                    child: Row(
                      children: [
                        PhosphorIcon(PhosphorIcons.clock(), color: PaisaColors.textSecondary, size: 18),
                        const SizedBox(width: 8),
                        Text(_time.format(context),
                            style: const TextStyle(color: PaisaColors.textPrimary, fontSize: 14)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: PaisaSpacing.md),

          // Note
          TextField(
            controller: _noteCtrl,
            style: const TextStyle(color: PaisaColors.textPrimary),
            cursorColor: PaisaColors.yellow,
            maxLength: 200,
            decoration: _inputDecor('Note (optional)'),
            onChanged: (_) => _hasChanges = true,
          ),

          // Source (read-only)
          const SizedBox(height: PaisaSpacing.md),
          _detailRow('Source', t.source == 'sms_auto' ? 'SMS Auto' : 'Manual'),

          const SizedBox(height: PaisaSpacing.xl),

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
    showPaisaSheet<void>(
      context: context,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('CATEGORY', style: PaisaTextStyles.sectionLabel),
          const SizedBox(height: PaisaSpacing.md),
          ...TransactionCategory.values.map((cat) {
            final selected = _category == cat;
            final catColor = PaisaColors.categoryColor(cat);
            return ListTile(
              leading: Icon(
                selected ? cat.iconFill : cat.icon,
                color: selected ? catColor : PaisaColors.textTertiary,
              ),
              title: Text(
                cat.label,
                style: TextStyle(
                  color: selected ? PaisaColors.textPrimary : PaisaColors.textSecondary,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
              trailing: selected
                  ? const Icon(Icons.check, color: PaisaColors.yellow, size: 20)
                  : null,
              onTap: () {
                setState(() { _category = cat; _hasChanges = true; });
                Navigator.pop(context);
              },
            );
          }),
          const SizedBox(height: PaisaSpacing.md),
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
          Text(label, style: const TextStyle(color: PaisaColors.textTertiary)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500, color: PaisaColors.textPrimary)),
        ],
      ),
    );
  }
}
