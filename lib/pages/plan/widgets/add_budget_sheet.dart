import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:finance_buddy_app/core/enums.dart';
import 'package:finance_buddy_app/design_system/design_system.dart';
import 'package:finance_buddy_app/data/db.dart';
import 'package:finance_buddy_app/providers/providers.dart';

class AddBudgetSheet extends ConsumerStatefulWidget {
  const AddBudgetSheet({super.key, this.existingBudget});
  final CategoryBudget? existingBudget;

  @override
  ConsumerState<AddBudgetSheet> createState() => _AddBudgetSheetState();
}

class _AddBudgetSheetState extends ConsumerState<AddBudgetSheet> {
  TransactionCategory _selected = TransactionCategory.foodAndDrink;
  final _amountCtrl = TextEditingController();
  bool get _isEditing => widget.existingBudget != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingBudget;
    if (existing != null) {
      _selected = TransactionCategory.values.firstWhere(
        (c) => c.name == existing.category,
        orElse: () => TransactionCategory.other,
      );
      _amountCtrl.text = existing.monthlyLimit.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            _isEditing ? 'Edit Budget' : 'Set Budget',
            style: AppTextStyles.headingM.copyWith(
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          // Category picker
          IgnorePointer(
            ignoring: _isEditing,
            child: Opacity(
              opacity: _isEditing ? 0.6 : 1.0,
              child: Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: TransactionCategory.values.map((cat) {
              final isSelected = cat == _selected;
              final color = AppColors.categoryColor(cat);
              return GestureDetector(
                onTap: () => setState(() => _selected = cat),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? color.withValues(alpha: 0.15)
                        : AppColors.gray200,
                    borderRadius: AppRadius.full,
                    border: isSelected
                        ? Border.all(color: color, width: 1.5)
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PhosphorIcon(cat.icon, size: 16, color: color),
                      const SizedBox(width: 6),
                      Text(
                        cat.label,
                        style: AppTextStyles.bodyS.copyWith(
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: isSelected ? color : AppColors.gray500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          ),
          ),
          const SizedBox(height: AppSpacing.xl),
          // Amount field
          TextField(
            controller: _amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _save(),
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Monthly limit (₹)',
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
          // Save button
          AppButton(
            label: _isEditing ? 'Update Budget' : 'Set Budget',
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

    await upsertBudget(
      ref.read(repositoryProvider),
      category: _selected.name,
      monthlyLimit: amount,
    );

    // Invalidate spending cache so UI refreshes
    ref.invalidate(monthlyCategorySpendingProvider);
    invalidateAnalytics(ref);
    if (mounted) Navigator.pop(context);
  }
}
