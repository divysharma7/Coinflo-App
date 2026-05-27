import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'package:finance_buddy_app/design_system/design_system.dart';
import 'package:finance_buddy_app/models/category_budget_model.dart';

class AddCategoryBudgetSheet extends StatefulWidget {
  const AddCategoryBudgetSheet({
    super.key,
    required this.availableGroups,
    required this.onSave,
    this.existingBudget,
  });

  final List<CategoryGroup> availableGroups;
  final ValueChanged<CategoryBudgetModel> onSave;
  final CategoryBudgetModel? existingBudget;

  @override
  State<AddCategoryBudgetSheet> createState() => _AddCategoryBudgetSheetState();
}

class _AddCategoryBudgetSheetState extends State<AddCategoryBudgetSheet> {
  CategoryGroup? _selectedGroup;
  final TextEditingController _limitController = TextEditingController();
  String _currencySymbol = '₹';

  bool get _isEditMode => widget.existingBudget != null;

  bool get _isValid =>
      _selectedGroup != null &&
      (int.tryParse(_limitController.text) ?? 0) > 0;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      _selectedGroup = widget.existingBudget!.group;
      _limitController.text = widget.existingBudget!.monthlyLimit.toString();
    }
    _loadCurrencySymbol();
  }

  @override
  void dispose() {
    _limitController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrencySymbol() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currencySymbol = prefs.getString('currency_symbol') ?? '₹';
    });
  }

  void _onSave() {
    final budget = CategoryBudgetModel(
      id: _isEditMode ? widget.existingBudget!.id : const Uuid().v4(),
      group: _selectedGroup!,
      monthlyLimit: int.parse(_limitController.text),
    );
    widget.onSave(budget);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
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
                    _isEditMode
                        ? 'Edit Category Budget'
                        : 'Add Category Budget',
                    style: AppTextStyles.headingM
                        .copyWith(color: AppColors.black),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const SizedBox(
                    width: 32,
                    height: 32,
                    child: Center(
                      child:
                          Icon(Icons.close, size: 20, color: AppColors.gray500),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.xl),

            // Category group label
            Text(
              'CATEGORY GROUP',
              style: AppTextStyles.labelM.copyWith(color: AppColors.gray500),
            ),
            const SizedBox(height: AppSpacing.sm),

            // Category chips
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: (_isEditMode
                      ? [widget.existingBudget!.group]
                      : widget.availableGroups)
                  .map((group) => _buildGroupChip(group))
                  .toList(),
            ),

            const SizedBox(height: AppSpacing.xl),

            // Monthly limit label
            Text(
              'MONTHLY LIMIT',
              style: AppTextStyles.labelM.copyWith(color: AppColors.gray500),
            ),
            const SizedBox(height: AppSpacing.sm),

            // Amount input
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: const BoxDecoration(
                color: AppColors.gray100,
                borderRadius: AppRadius.md,
              ),
              child: Row(
                children: [
                  Text(
                    _currencySymbol,
                    style: AppTextStyles.displayL
                        .copyWith(color: AppColors.gray500),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: TextField(
                      controller: _limitController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: AppTextStyles.displayL
                          .copyWith(color: AppColors.black),
                      autofocus: !_isEditMode,
                      decoration: InputDecoration(
                        hintText: '0',
                        hintStyle: AppTextStyles.displayL
                            .copyWith(color: AppColors.gray500),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
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
                    label: _isEditMode ? 'Save Changes' : 'Add Budget',
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

  Widget _buildGroupChip(CategoryGroup group) {
    final isSelected = _selectedGroup == group;
    final canTap = !_isEditMode;

    return GestureDetector(
      onTap: canTap ? () => setState(() => _selectedGroup = group) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.black : AppColors.white,
          borderRadius: AppRadius.full,
          border: Border.all(
            color: isSelected ? AppColors.black : AppColors.gray200,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              group.icon,
              size: 14,
              color: isSelected ? AppColors.white : group.iconColor,
            ),
            const SizedBox(width: AppSpacing.xxs),
            Text(
              group.label,
              style: AppTextStyles.bodyS.copyWith(
                color: isSelected ? AppColors.white : AppColors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
