import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finance_buddy_app/core/enums.dart';
import 'package:finance_buddy_app/core/tokens.dart';
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

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Amount display — hero number style
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              '\$',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w400,
                color: _isExpense ? SpendlerColors.accentRed : SpendlerColors.accentGreen,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              _amount.isEmpty ? '0' : _amount,
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: _isExpense ? SpendlerColors.accentRed : SpendlerColors.accentGreen,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Expense/Income toggle
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: true, label: Text('Expense')),
            ButtonSegment(value: false, label: Text('Income')),
          ],
          selected: {_isExpense},
          onSelectionChanged: (v) => setState(() => _isExpense = v.first),
        ),
        const SizedBox(height: SpendlerSpacing.cardGap),

        // Category grid
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 2.5,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          children: TransactionCategory.values.map((cat) {
            final selected = _category == cat;
            final catColor = SpendlerColors.categoryColor(cat);
            return GestureDetector(
              onTap: () => setState(() => _category = cat),
              child: Container(
                decoration: BoxDecoration(
                  color: selected
                      ? catColor.withValues(alpha: 0.2)
                      : SpendlerColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(10),
                  border: selected
                      ? Border.all(color: catColor, width: 2)
                      : null,
                ),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(cat.icon, size: 16, color: selected ? catColor : SpendlerColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        cat.label,
                        style: TextStyle(
                          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 13,
                          color: selected ? catColor : SpendlerColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: SpendlerSpacing.cardGap),

        // Note field
        TextField(
          controller: _noteController,
          style: const TextStyle(color: SpendlerColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Note (optional)',
            hintStyle: const TextStyle(color: SpendlerColors.textTertiary),
            filled: true,
            fillColor: SpendlerColors.surfaceSecondary,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(SpendlerRadii.button),
              borderSide: BorderSide.none,
            ),
            isDense: true,
          ),
        ),
        const SizedBox(height: SpendlerSpacing.cardGap),

        // Numpad
        _buildNumpad(),
        const SizedBox(height: SpendlerSpacing.cardGap),

        // Save button — full-width bottom CTA style
        SizedBox(
          width: double.infinity,
          height: 56,
          child: FilledButton(
            onPressed: _amount.isEmpty ? null : _save,
            style: FilledButton.styleFrom(
              backgroundColor: SpendlerColors.primary,
              foregroundColor: Colors.black,
              disabledBackgroundColor: SpendlerColors.surfaceSecondary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(SpendlerRadii.button),
              ),
            ),
            child: const Text(
              'Done',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNumpad() {
    const keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '.', '0', '⌫'];
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2,
      mainAxisSpacing: 4,
      crossAxisSpacing: 4,
      children: keys.map((key) {
        return InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            setState(() {
              if (key == '⌫') {
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
            decoration: BoxDecoration(
              color: SpendlerColors.surfaceSecondary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                key,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                  color: SpendlerColors.textPrimary,
                ),
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
