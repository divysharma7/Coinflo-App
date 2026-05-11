import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finance_buddy_app/core/enums.dart';
import 'package:finance_buddy_app/design_system/design_system.dart';
import 'package:finance_buddy_app/providers/providers.dart';
import 'package:finance_buddy_app/providers/onboarding_provider.dart';

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

  String _currencySymbol(String code) {
    switch (code.toLowerCase()) {
      case 'inr':
        return '\u20B9';
      case 'usd':
        return '\$';
      case 'eur':
        return '\u20AC';
      case 'gbp':
        return '\u00A3';
      default:
        return '\$';
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currencyAsync = ref.watch(selectedCurrencyProvider);
    final currency = currencyAsync.valueOrNull ?? 'inr';
    final symbol = _currencySymbol(currency);
    final amountColor = _isExpense ? AppColors.red : AppColors.green;
    final bottomPad = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomPad),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.88,
        child: Column(
          children: [
            // Drag handle
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.gray300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Amount display
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(symbol,
                    style: AppTextStyles.headingM.copyWith(color: amountColor)),
                const SizedBox(width: AppSpacing.xxs),
                Text(
                  _amount.isEmpty ? '0' : _amount,
                  style: AppTextStyles.displayXL.copyWith(color: amountColor),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            // Expense/Income toggle
            _buildToggle(),
            const SizedBox(height: AppSpacing.md),

            // Scrollable content: categories + note
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Column(
                  children: [
                    // Category chips
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: TransactionCategory.values.map((cat) {
                        final selected = _category == cat;
                        final catColor = _colorForCategory(cat);
                        return GestureDetector(
                          onTap: () => setState(() => _category = cat),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                            decoration: BoxDecoration(
                              color: selected
                                  ? catColor.withValues(alpha: 0.12)
                                  : AppColors.gray100,
                              borderRadius: BorderRadius.circular(20),
                              border: selected
                                  ? Border.all(color: catColor, width: 1.5)
                                  : null,
                            ),
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
                                    fontWeight: selected
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                    color: selected ? catColor : AppColors.gray500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Note field
                    TextField(
                      controller: _noteController,
                      style: AppTextStyles.bodyM.copyWith(color: AppColors.black),
                      decoration: InputDecoration(
                        hintText: 'Note (optional)',
                        hintStyle:
                            AppTextStyles.bodyM.copyWith(color: AppColors.gray400),
                        filled: true,
                        fillColor: AppColors.gray100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                ),
              ),
            ),

            // Numpad + Done button pinned at bottom
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: _buildNumpad(),
            ),
            const SizedBox(height: AppSpacing.sm),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
              child: SizedBox(
                width: double.infinity,
                child: AppButton(
                  label: 'Done',
                  onTap: _save,
                  disabled: _amount.isEmpty,
                ),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  Widget _buildToggle() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _toggleButton('Expense', _isExpense, () {
            setState(() => _isExpense = true);
          }),
          _toggleButton('Income', !_isExpense, () {
            setState(() => _isExpense = false);
          }),
        ],
      ),
    );
  }

  Widget _toggleButton(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppDurations.fast,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.black : Colors.transparent,
          borderRadius: BorderRadius.circular(26),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              const Icon(Icons.check, size: 16, color: AppColors.white),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: AppTextStyles.bodyS.copyWith(
                fontWeight: FontWeight.w600,
                color: selected ? AppColors.white : AppColors.gray500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumpad() {
    const keys = [
      '1', '2', '3',
      '4', '5', '6',
      '7', '8', '9',
      '.', '0', '\u232B',
    ];
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.2,
      mainAxisSpacing: AppSpacing.xxs,
      crossAxisSpacing: AppSpacing.xxs,
      children: keys.map((key) {
        return InkWell(
          borderRadius: BorderRadius.circular(12),
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
            decoration: BoxDecoration(
              color: AppColors.gray100,
              borderRadius: BorderRadius.circular(12),
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
