import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finance_buddy_app/core/enums.dart';
import 'package:finance_buddy_app/design_system/design_system.dart';
import 'package:finance_buddy_app/providers/providers.dart';

class QuickAddSheet extends ConsumerStatefulWidget {
  const QuickAddSheet({super.key});

  @override
  ConsumerState<QuickAddSheet> createState() => _QuickAddSheetState();
}

class _QuickAddSheetState extends ConsumerState<QuickAddSheet> {
  String _amount = '';
  TransactionCategory _category = TransactionCategory.foodAndDrink;
  final _noteController = TextEditingController();
  bool _isExpense = true;

  /// Maps each TransactionCategory to its accent color.
  static const Map<TransactionCategory, Color> _categoryColors = {
    TransactionCategory.foodAndDrink: Color(0xFFFF8A4C),
    TransactionCategory.transport: Color(0xFF4A8FE7),
    TransactionCategory.shopping: Color(0xFFB19CD9),
    TransactionCategory.billsAndUtilities: Color(0xFFF59E0B),
    TransactionCategory.healthAndWellness: Color(0xFF22C55E),
    TransactionCategory.entertainment: Color(0xFFE91E63),
    TransactionCategory.streaming: Color(0xFFEC407A),
    TransactionCategory.gymFitness: Color(0xFF4CAF50),
    TransactionCategory.productivityTools: Color(0xFF9575CD),
    TransactionCategory.personalCare: Color(0xFFF8BBD0),
    TransactionCategory.education: Color(0xFF5C6BC0),
    TransactionCategory.travel: Color(0xFF14B8A6),
    TransactionCategory.other: Color(0xFF6E6E73),
  };

  Color _colorForCategory(TransactionCategory cat) =>
      _categoryColors[cat] ?? AppColors.gray500;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final amountColor = _isExpense ? AppColors.red : AppColors.green;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Amount display
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              '\$',
              style: AppTextStyles.headingM.copyWith(color: amountColor),
            ),
            const SizedBox(width: AppSpacing.xxs),
            Text(
              _amount.isEmpty ? '0' : _amount,
              style: AppTextStyles.displayXL.copyWith(color: amountColor),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),

        // Expense/Income toggle
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: true, label: Text('Expense')),
            ButtonSegment(value: false, label: Text('Income')),
          ],
          selected: {_isExpense},
          onSelectionChanged: (v) => setState(() => _isExpense = v.first),
        ),
        const SizedBox(height: AppSpacing.md),

        // Category grid
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 2.5,
          mainAxisSpacing: AppSpacing.xs,
          crossAxisSpacing: AppSpacing.xs,
          children: TransactionCategory.values.map((cat) {
            final selected = _category == cat;
            final catColor = _colorForCategory(cat);
            return GestureDetector(
              onTap: () => setState(() => _category = cat),
              child: Container(
                decoration: BoxDecoration(
                  color: selected
                      ? catColor.withValues(alpha: 0.12)
                      : AppColors.gray100,
                  borderRadius: AppRadius.sm,
                  border: selected
                      ? Border.all(color: catColor, width: 2)
                      : null,
                ),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(cat.icon,
                          size: 16,
                          color: selected ? catColor : AppColors.gray500),
                      const SizedBox(width: AppSpacing.xxs),
                      Text(
                        cat.label,
                        style: AppTextStyles.bodyS.copyWith(
                          fontWeight:
                              selected ? FontWeight.bold : FontWeight.normal,
                          color: selected ? catColor : AppColors.gray500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: AppSpacing.md),

        // Note field
        TextField(
          controller: _noteController,
          style: AppTextStyles.bodyM.copyWith(color: AppColors.black),
          decoration: InputDecoration(
            hintText: 'Note (optional)',
            hintStyle: AppTextStyles.bodyM.copyWith(color: AppColors.gray400),
            filled: true,
            fillColor: AppColors.gray100,
            border: const OutlineInputBorder(
              borderRadius: AppRadius.sm,
              borderSide: BorderSide.none,
            ),
            isDense: true,
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Numpad
        _buildNumpad(),
        const SizedBox(height: AppSpacing.md),

        // Save button
        AppButton(
          label: 'Done',
          onTap: _save,
          disabled: _amount.isEmpty,
        ),
      ],
    );
  }

  Widget _buildNumpad() {
    const keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '.', '0', '\u232B'];
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2,
      mainAxisSpacing: AppSpacing.xxs,
      crossAxisSpacing: AppSpacing.xxs,
      children: keys.map((key) {
        return InkWell(
          borderRadius: AppRadius.sm,
          onTap: () {
            setState(() {
              if (key == '\u232B') {
                if (_amount.isNotEmpty) {
                  _amount = _amount.substring(0, _amount.length - 1);
                }
              } else if (key == '.') {
                if (!_amount.contains('.')) _amount += '.';
              } else {
                _amount += key;
              }
            });
          },
          child: Container(
            decoration: const BoxDecoration(
              color: AppColors.gray100,
              borderRadius: AppRadius.sm,
            ),
            child: Center(
              child: Text(
                key,
                style: AppTextStyles.headingM.copyWith(color: AppColors.black),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amount);
    if (amount == null || amount <= 0) return;

    final note = _noteController.text.trim();
    await insertManualTransaction(
      ref.read(repositoryProvider),
      amount: _isExpense ? -amount : amount,
      category: _category.name,
      note: note.isEmpty ? null : note,
    );
    if (mounted) Navigator.pop(context);
  }
}
