import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finance_buddy_app/design_system/design_system.dart';
import 'package:finance_buddy_app/data/db.dart';
import 'package:finance_buddy_app/providers/providers.dart';
import 'package:finance_buddy_app/utils/currency_utils.dart';

class SettlementForm extends ConsumerStatefulWidget {
  const SettlementForm({super.key, required this.person, required this.balance});
  final Person person;
  final double balance;

  @override
  ConsumerState<SettlementForm> createState() => _SettlementFormState();
}

class _SettlementFormState extends ConsumerState<SettlementForm> {
  late final TextEditingController _amountController;

  @override
  void initState() {
    super.initState();
    _amountController =
        TextEditingController(text: widget.balance.abs().toStringAsFixed(2));
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sym = currencySymbol(
        ref.watch(selectedCurrencyProvider).valueOrNull ?? 'inr');
    final theyOweUser = widget.balance > 0;
    final directionLabel = theyOweUser ? 'Received from' : 'Paid to';

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Settle Up',
              style: AppTextStyles.headingS.copyWith(color: AppColors.black)),
          const SizedBox(height: AppSpacing.sm),
          Text('$directionLabel ${widget.person.name}',
              style: AppTextStyles.bodyM.copyWith(color: AppColors.gray500)),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: AppTextStyles.headingM.copyWith(color: AppColors.black),
            decoration: InputDecoration(
              prefixText: '$sym ',
              prefixStyle:
                  AppTextStyles.headingM.copyWith(color: AppColors.gray500),
              filled: true,
              fillColor: AppColors.gray100,
              border: OutlineInputBorder(
                borderRadius: AppRadius.base,
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          AppButton(label: 'Record Settlement', onTap: _save),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) return;

    await HapticFeedback.mediumImpact();
    final repo = ref.read(repositoryProvider);
    final theyOweUser = widget.balance > 0;

    await repo.insertTransaction(SpendlerTransactionsCompanion(
      amount: drift.Value(theyOweUser ? amount : -amount),
      category: const drift.Value('settlement'),
      txnType: const drift.Value('settlement'),
      counterpartyPersonId: drift.Value(widget.person.id),
      settlementDirection:
          drift.Value(theyOweUser ? 'received_from' : 'paid_to'),
      source: const drift.Value('manual'),
      status: const drift.Value('confirmed'),
      note: drift.Value('Settlement with ${widget.person.name}'),
    ));

    if (mounted) Navigator.pop(context);
  }
}
