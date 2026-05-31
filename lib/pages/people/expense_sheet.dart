import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finance_buddy_app/design_system/design_system.dart';
import 'package:finance_buddy_app/data/db.dart';
import 'package:finance_buddy_app/data/repositories/split_repository.dart';
import 'package:finance_buddy_app/providers/providers.dart';
import 'package:finance_buddy_app/utils/currency_utils.dart';

/// Unified sheet that replaces both AddDebtSheet and SettlementForm.
///
/// When [balance] is non-zero a "Settle balance" toggle appears. Turning it on
/// pre-fills the amount with the outstanding balance and records a settlement
/// via the same expense+split mechanism used for regular debts (the old
/// settlement-only path was broken — settlement transactions had no splits, so
/// the INNER JOIN in the balance SQL never saw them).
class ExpenseSheet extends ConsumerStatefulWidget {
  const ExpenseSheet({
    super.key,
    required this.person,
    required this.balance,
  });

  final Person person;

  /// Current balance for this person. Pass 0 when balance is unknown / loading.
  final double balance;

  @override
  ConsumerState<ExpenseSheet> createState() => _ExpenseSheetState();
}

class _ExpenseSheetState extends ConsumerState<ExpenseSheet> {
  /// true = user paid ("You" chip), false = person paid ("{name}" chip).
  bool _userPaid = true;

  bool _settleOn = false;
  bool _saving = false;
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  bool get _hasBalance => widget.balance != 0;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  // ── helpers ──────────────────────────────────────────────

  void _toggleSettle(bool on) {
    setState(() {
      _settleOn = on;
      if (on) {
        _amountController.text = widget.balance.abs().toStringAsFixed(2);
      } else {
        _amountController.clear();
      }
    });
  }

  double get _parsedAmount =>
      double.tryParse(_amountController.text.trim()) ?? 0;

  // ── build ────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final sym = currencySymbol(
        ref.watch(selectedCurrencyProvider).valueOrNull ?? 'inr');
    final name = widget.person.name;
    final canSave = _parsedAmount > 0 && !_saving;

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Record expense',
              style: AppTextStyles.headingS.copyWith(color: AppColors.black)),
          const SizedBox(height: AppSpacing.xs),
          Text('with $name',
              style: AppTextStyles.bodyM.copyWith(color: AppColors.gray500)),
          const SizedBox(height: AppSpacing.lg),

          // ── Who paid? chips (disabled when settle toggle is on) ──
          Text('Who paid?',
              style: AppTextStyles.labelM.copyWith(color: AppColors.gray500)),
          const SizedBox(height: AppSpacing.xs),
          IgnorePointer(
            ignoring: _settleOn,
            child: AnimatedOpacity(
              duration: AppDurations.fast,
              opacity: _settleOn ? 0.4 : 1.0,
              child: Row(
                children: [
                  _chip(label: 'You', selected: _userPaid, onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() => _userPaid = true);
                  }),
                  const SizedBox(width: AppSpacing.sm),
                  _chip(label: name, selected: !_userPaid, onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() => _userPaid = false);
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // ── Settle balance toggle (conditional) ──
          if (_hasBalance) ...[
            _buildSettleToggle(sym),
            const SizedBox(height: AppSpacing.lg),
          ],

          // ── Amount (editable even when settle is on — allows partial) ──
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: AppTextStyles.headingM.copyWith(color: AppColors.black),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              prefixText: '$sym ',
              prefixStyle:
                  AppTextStyles.headingM.copyWith(color: AppColors.gray500),
              hintText: '0.00',
              hintStyle:
                  AppTextStyles.headingM.copyWith(color: AppColors.gray300),
              filled: true,
              fillColor: AppColors.gray100,
              border: OutlineInputBorder(
                borderRadius: AppRadius.base,
                borderSide: BorderSide.none,
              ),
            ),
          ),
          // ── Remaining balance indicator (partial settlement) ──
          if (_settleOn && _parsedAmount > 0 && _parsedAmount < widget.balance.abs()) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Remaining: $sym${(widget.balance.abs() - _parsedAmount).toStringAsFixed(2)}',
              style: AppTextStyles.bodyS.copyWith(color: AppColors.orange),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),

          // ── Note ──
          TextField(
            controller: _noteController,
            textCapitalization: TextCapitalization.sentences,
            style: AppTextStyles.bodyM.copyWith(color: AppColors.black),
            decoration: InputDecoration(
              hintText: 'What for? (optional)',
              hintStyle:
                  AppTextStyles.bodyM.copyWith(color: AppColors.gray400),
              filled: true,
              fillColor: AppColors.gray100,
              border: OutlineInputBorder(
                borderRadius: AppRadius.base,
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          AppButton(
            label: _settleOn
                ? (_parsedAmount >= widget.balance.abs()
                    ? 'Settle in full'
                    : 'Settle partially')
                : 'Save',
            onTap: _save,
            disabled: !canSave,
          ),
        ],
      ),
    );
  }

  // ── chip widget ──────────────────────────────────────────

  Widget _chip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppDurations.fast,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: selected ? AppColors.black : AppColors.white,
            borderRadius: AppRadius.pill,
            border: Border.all(
              color: selected ? AppColors.black : AppColors.gray200,
            ),
          ),
          child: Text(
            label,
            style: AppTextStyles.bodyS.copyWith(
              color: selected ? AppColors.white : AppColors.gray500,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  // ── settle toggle row ────────────────────────────────────

  Widget _buildSettleToggle(String sym) {
    final absBalance = widget.balance.abs();
    return Row(
      children: [
        Expanded(
          child: Text.rich(
            TextSpan(children: [
              TextSpan(
                text: 'Settle balance',
                style:
                    AppTextStyles.bodyM.copyWith(color: AppColors.black),
              ),
              TextSpan(
                text: '  $sym${absBalance.toStringAsFixed(2)}',
                style:
                    AppTextStyles.bodyM.copyWith(color: AppColors.gray500),
              ),
            ]),
          ),
        ),
        Switch.adaptive(
          value: _settleOn,
          activeTrackColor: AppColors.black,
          onChanged: _toggleSettle,
        ),
      ],
    );
  }

  // ── save ─────────────────────────────────────────────────

  Future<void> _save() async {
    final amount = _parsedAmount;
    if (amount <= 0 || _saving) return;

    setState(() => _saving = true);
    await HapticFeedback.mediumImpact();
    final repo = ref.read(repositoryProvider);
    final note = _noteController.text.trim();

    try {
      if (_settleOn) {
        // Settlement via the split-based accounting path.
        //
        // The old SettlementForm wrote a txnType='settlement' transaction with
        // NO splits. The balance SQL does INNER JOIN transaction_splits, so
        // those settlements were invisible. Instead we record a reverse
        // expense+split that uses the same terms 1 & 2 the balance query
        // already handles correctly:
        //
        //   balance > 0 (they owe user) → person "pays back"
        //     txn: payerPersonId = person.id
        //     split: personId = null (user's share) → term 2 fires: −amount
        //
        //   balance < 0 (user owes person) → user "pays back"
        //     txn: payerPersonId = null
        //     split: personId = person.id (person's share) → term 1 fires: +amount
        final theyOweUser = widget.balance > 0;
        final txnId = await repo.insertTransaction(SpendlerTransactionsCompanion(
          amount: drift.Value(theyOweUser ? amount : -amount),
          category: const drift.Value('settlement'),
          txnType: drift.Value(theyOweUser ? 'income' : 'expense'),
          payerPersonId: theyOweUser
              ? drift.Value(widget.person.id)
              : const drift.Value.absent(),
          source: const drift.Value('manual'),
          status: const drift.Value('confirmed'),
          note: note.isNotEmpty
              ? drift.Value(note)
              : drift.Value('Settlement with ${widget.person.name}'),
        ));

        await repo.createSplits(txnId, [
          SplitEntry(
            personId: theyOweUser ? null : widget.person.id,
            shareAmount: amount,
          ),
        ]);
      } else {
        // Regular expense path.
        final txnId = await repo.insertTransaction(SpendlerTransactionsCompanion(
          amount: drift.Value(amount),
          category: const drift.Value('debt'),
          txnType: const drift.Value('expense'),
          payerPersonId: _userPaid
              ? const drift.Value.absent()
              : drift.Value(widget.person.id),
          source: const drift.Value('manual'),
          status: const drift.Value('confirmed'),
          note: note.isNotEmpty
              ? drift.Value('$note — with ${widget.person.name}')
              : drift.Value('Expense with ${widget.person.name}'),
        ));

        await repo.createSplits(txnId, [
          SplitEntry(
            personId: _userPaid ? widget.person.id : null,
            shareAmount: amount,
          ),
        ]);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }

    if (mounted) Navigator.pop(context);
  }
}
