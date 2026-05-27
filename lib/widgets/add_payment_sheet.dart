import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'package:finance_buddy_app/constants/app_categories.dart';
import 'package:finance_buddy_app/design_system/design_system.dart';
import 'package:finance_buddy_app/models/recurring_payment_model.dart';
import 'package:finance_buddy_app/widgets/category_picker_sheet.dart';
import 'package:finance_buddy_app/widgets/common/spendler_bottom_sheet.dart';

class AddPaymentSheet extends StatefulWidget {
  const AddPaymentSheet({
    super.key,
    required this.onSave,
    this.presetName,
    this.presetCategory,
  });

  final ValueChanged<RecurringPaymentModel> onSave;
  final String? presetName;
  final String? presetCategory;

  @override
  State<AddPaymentSheet> createState() => _AddPaymentSheetState();
}

class _AddPaymentSheetState extends State<AddPaymentSheet> {
  late final TextEditingController _nameController;
  final TextEditingController _amountController = TextEditingController();
  AppCategory? _selectedCategory;
  PaymentFrequency _frequency = PaymentFrequency.monthly;
  int _dueDay = 1;
  String _currencySymbol = '₹';

  bool get _isValid =>
      _nameController.text.trim().isNotEmpty &&
      (int.tryParse(_amountController.text) ?? 0) > 0;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.presetName ?? '');
    _loadCurrencySymbol();

    // Pre-fill category from preset
    if (widget.presetCategory != null) {
      for (final categories in kAllCategories.values) {
        for (final cat in categories) {
          if (cat.name == widget.presetCategory) {
            _selectedCategory = cat;
            break;
          }
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrencySymbol() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currencySymbol = prefs.getString('currency_symbol') ?? '₹';
    });
  }

  void _openCategoryPicker() {
    showSpendlerSheet<void>(
      context: context,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (_, _) => CategoryPickerSheet(
          selectedCategory: _selectedCategory?.name,
          onSelected: (category) {
            setState(() => _selectedCategory = category);
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  void _onSave() {
    final payment = RecurringPaymentModel(
      id: const Uuid().v4(),
      name: _nameController.text.trim(),
      categoryName: _selectedCategory?.name ?? 'Miscellaneous',
      categoryIcon: _selectedCategory?.icon ?? Icons.more_horiz,
      categoryColor: _selectedCategory?.iconColor ?? AppColors.gray500,
      amount: int.parse(_amountController.text),
      frequency: _frequency,
      dueDayOfMonth: _dueDay,
      accountId: 'system_cash',
      createdAt: DateTime.now(),
    );
    widget.onSave(payment);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Add Payment',
                    style:
                        AppTextStyles.headingM.copyWith(color: AppColors.black),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const SizedBox(
                    width: 32,
                    height: 32,
                    child: Center(
                      child: Icon(Icons.close,
                          size: 20, color: AppColors.gray500),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.xl),

            // Payment name
            Text(
              'PAYMENT NAME',
              style: AppTextStyles.labelM.copyWith(color: AppColors.gray500),
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: const BoxDecoration(
                color: AppColors.gray100,
                borderRadius: AppRadius.md,
              ),
              child: TextField(
                controller: _nameController,
                autofocus: widget.presetName == null,
                style: AppTextStyles.bodyM.copyWith(color: AppColors.black),
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  hintText: 'e.g. Netflix, Rent, Gym',
                  hintStyle:
                      AppTextStyles.bodyM.copyWith(color: AppColors.gray500),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Category
            Text(
              'CATEGORY',
              style: AppTextStyles.labelM.copyWith(color: AppColors.gray500),
            ),
            const SizedBox(height: AppSpacing.sm),
            GestureDetector(
              onTap: _openCategoryPicker,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.md,
                ),
                decoration: const BoxDecoration(
                  color: AppColors.gray100,
                  borderRadius: AppRadius.md,
                ),
                child: Row(
                  children: [
                    if (_selectedCategory != null) ...[
                      Icon(_selectedCategory!.icon,
                          size: 18, color: _selectedCategory!.iconColor),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(_selectedCategory!.name,
                            style: AppTextStyles.bodyM
                                .copyWith(color: AppColors.black)),
                      ),
                    ] else
                      Expanded(
                        child: Text('Select category',
                            style: AppTextStyles.bodyM
                                .copyWith(color: AppColors.gray500)),
                      ),
                    const Icon(Icons.chevron_right,
                        size: 20, color: AppColors.gray500),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Amount
            Text(
              'AMOUNT',
              style: AppTextStyles.labelM.copyWith(color: AppColors.gray500),
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: const BoxDecoration(
                color: AppColors.gray100,
                borderRadius: AppRadius.md,
              ),
              child: TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: AppTextStyles.bodyM.copyWith(color: AppColors.black),
                decoration: InputDecoration(
                  hintText: 'e.g. 680',
                  hintStyle:
                      AppTextStyles.bodyM.copyWith(color: AppColors.gray500),
                  prefixText: '$_currencySymbol ',
                  prefixStyle:
                      AppTextStyles.bodyM.copyWith(color: AppColors.gray500),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Frequency
            Text(
              'FREQUENCY',
              style: AppTextStyles.labelM.copyWith(color: AppColors.gray500),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: PaymentFrequency.values.map((freq) {
                final isSelected = freq == _frequency;
                final label = freq.name[0].toUpperCase() + freq.name.substring(1);
                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.xs),
                  child: GestureDetector(
                    onTap: () => setState(() => _frequency = freq),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isSelected ? AppColors.black : AppColors.gray100,
                        borderRadius: AppRadius.full,
                      ),
                      child: Text(
                        label,
                        style: AppTextStyles.bodyS.copyWith(
                          color: isSelected
                              ? AppColors.white
                              : AppColors.black,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Due day
            Text(
              'DUE DAY OF MONTH',
              style: AppTextStyles.labelM.copyWith(color: AppColors.gray500),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 31,
                itemBuilder: (context, index) {
                  final day = index + 1;
                  final isSelected = day == _dueDay;
                  return GestureDetector(
                    onTap: () => setState(() => _dueDay = day),
                    child: Container(
                      width: 40,
                      height: 40,
                      margin: const EdgeInsets.only(right: AppSpacing.xxs),
                      decoration: BoxDecoration(
                        color:
                            isSelected ? AppColors.black : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$day',
                        style: AppTextStyles.bodyS.copyWith(
                          color: isSelected
                              ? AppColors.white
                              : AppColors.black,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Cancel',
                    variant: AppButtonVariant.ghost,
                    onTap: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: AppButton(
                    label: 'Add Payment',
                    onTap: _onSave,
                    disabled: !_isValid,
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }
}
