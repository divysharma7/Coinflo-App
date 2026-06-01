import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finance_buddy_app/design_system/design_system.dart';
import 'package:finance_buddy_app/data/db.dart';
import 'package:finance_buddy_app/providers/providers.dart';
import 'package:finance_buddy_app/utils/currency_utils.dart';

class AddMoneySheet extends ConsumerStatefulWidget {
  const AddMoneySheet({super.key, required this.goal});
  final SavingsGoal goal;

  @override
  ConsumerState<AddMoneySheet> createState() => _AddMoneySheetState();
}

class _AddMoneySheetState extends ConsumerState<AddMoneySheet> {
  final _amountCtrl = TextEditingController();

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remaining = widget.goal.targetAmount - widget.goal.currentAmount;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Add to "${widget.goal.name}"',
            style: AppTextStyles.headingM.copyWith(
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${currencySymbol(ref.watch(selectedCurrencyProvider).valueOrNull ?? 'inr')}${remaining.toStringAsFixed(0)} remaining',
            style: AppTextStyles.bodyS.copyWith(
              color: AppColors.gray500,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          TextField(
            controller: _amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _save(),
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Amount (₹)',
              labelStyle: TextStyle(color: AppColors.gray500),
              enabledBorder: OutlineInputBorder(
                borderRadius: AppRadius.sm,
                borderSide: BorderSide(color: AppColors.gray200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: AppRadius.sm,
                borderSide: BorderSide(color: AppColors.black, width: 1.5),
              ),
            ),
            style: AppTextStyles.headingS.copyWith(
              color: AppColors.black,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: 'Add Money',
            onTap: _save,
          ),
        ],
      ),
    ),
    );
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amountCtrl.text.trim());
    if (amount == null || amount <= 0) return;

    await addMoneyToGoal(ref.read(repositoryProvider), widget.goal.id, amount);
    invalidateAnalytics(ref);
    if (mounted) Navigator.pop(context);
  }
}
