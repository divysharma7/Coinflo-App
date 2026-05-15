import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'package:finance_buddy_app/constants/goal_icons.dart';
import 'package:finance_buddy_app/design_system/design_system.dart';
import 'package:finance_buddy_app/models/savings_goal_model.dart';

class AddGoalSheet extends StatefulWidget {
  const AddGoalSheet({super.key, required this.onSave});

  final ValueChanged<SavingsGoalModel> onSave;

  @override
  State<AddGoalSheet> createState() => _AddGoalSheetState();
}

class _AddGoalSheetState extends State<AddGoalSheet> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _targetController = TextEditingController();
  final TextEditingController _monthlyController = TextEditingController();
  int _selectedIconIndex = 7; // "Other" by default
  String _currencySymbol = '₹';

  bool get _isValid =>
      _nameController.text.trim().isNotEmpty &&
      (int.tryParse(_targetController.text) ?? 0) > 0 &&
      (int.tryParse(_monthlyController.text) ?? 0) > 0;

  @override
  void initState() {
    super.initState();
    _loadCurrencySymbol();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetController.dispose();
    _monthlyController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrencySymbol() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currencySymbol = prefs.getString('currency_symbol') ?? '₹';
    });
  }

  void _onSave() {
    final goal = SavingsGoalModel(
      id: const Uuid().v4(),
      name: _nameController.text.trim(),
      iconAsset: kGoalIcons[_selectedIconIndex].label,
      targetAmount: int.parse(_targetController.text),
      monthlyTarget: int.parse(_monthlyController.text),
      createdAt: DateTime.now(),
    );
    widget.onSave(goal);
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
                    'Add Goal',
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

            // Goal name
            Text(
              'GOAL NAME',
              style: AppTextStyles.labelM.copyWith(color: AppColors.gray400),
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
                autofocus: true,
                style: AppTextStyles.bodyM.copyWith(color: AppColors.black),
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  hintText: 'e.g. Bike, PS5, Goa Trip',
                  hintStyle:
                      AppTextStyles.bodyM.copyWith(color: AppColors.gray400),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Icon picker
            Text(
              'ICON',
              style: AppTextStyles.labelM.copyWith(color: AppColors.gray400),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              height: 64,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: kGoalIcons.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(width: AppSpacing.xs),
                itemBuilder: (context, index) {
                  final isSelected = index == _selectedIconIndex;
                  final goalIcon = kGoalIcons[index];
                  return GestureDetector(
                    onTap: () => setState(() => _selectedIconIndex = index),
                    child: Column(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.black
                                : AppColors.gray100,
                            borderRadius: AppRadius.md,
                          ),
                          child: Icon(
                            goalIcon.icon,
                            size: 22,
                            color: isSelected
                                ? AppColors.white
                                : AppColors.gray600,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          goalIcon.label,
                          style: AppTextStyles.labelS.copyWith(
                            color: isSelected
                                ? AppColors.black
                                : AppColors.gray400,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Target amount
            Text(
              'TARGET AMOUNT',
              style: AppTextStyles.labelM.copyWith(color: AppColors.gray400),
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
                controller: _targetController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: AppTextStyles.bodyM.copyWith(color: AppColors.black),
                decoration: InputDecoration(
                  hintText: 'e.g. 50000',
                  hintStyle:
                      AppTextStyles.bodyM.copyWith(color: AppColors.gray400),
                  prefixText: '$_currencySymbol ',
                  prefixStyle:
                      AppTextStyles.bodyM.copyWith(color: AppColors.gray400),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Monthly target
            Text(
              'MONTHLY TARGET',
              style: AppTextStyles.labelM.copyWith(color: AppColors.gray400),
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
                controller: _monthlyController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: AppTextStyles.bodyM.copyWith(color: AppColors.black),
                decoration: InputDecoration(
                  hintText: 'e.g. 5000',
                  hintStyle:
                      AppTextStyles.bodyM.copyWith(color: AppColors.gray400),
                  prefixText: '$_currencySymbol ',
                  prefixStyle:
                      AppTextStyles.bodyM.copyWith(color: AppColors.gray400),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: (_) => setState(() {}),
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
                    label: 'Add Goal',
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
