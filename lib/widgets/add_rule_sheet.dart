import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import 'package:finance_buddy_app/constants/app_categories.dart';
import 'package:finance_buddy_app/design_system/design_system.dart';
import 'package:finance_buddy_app/models/smart_rule_model.dart';
import 'package:finance_buddy_app/widgets/category_picker_sheet.dart';

class AddRuleSheet extends StatefulWidget {
  const AddRuleSheet({
    super.key,
    required this.existingKeywords,
    required this.onAdd,
  });

  final List<String> existingKeywords;
  final ValueChanged<SmartRuleModel> onAdd;

  @override
  State<AddRuleSheet> createState() => _AddRuleSheetState();
}

class _AddRuleSheetState extends State<AddRuleSheet> {
  final TextEditingController _keywordController = TextEditingController();
  AppCategory? _selectedCategory;
  String? _keywordError;

  bool get _isValid =>
      _keywordController.text.trim().isNotEmpty &&
      _keywordError == null &&
      _selectedCategory != null;

  @override
  void dispose() {
    _keywordController.dispose();
    super.dispose();
  }

  void _onKeywordChanged(String value) {
    final trimmed = value.trim().toLowerCase();
    final isDuplicate =
        widget.existingKeywords.any((k) => k.toLowerCase() == trimmed);
    setState(() {
      _keywordError =
          isDuplicate ? 'A rule for "$trimmed" already exists' : null;
    });
  }

  void _openCategoryPicker() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (_, scrollController) => CategoryPickerSheet(
          selectedCategory: _selectedCategory?.name,
          onSelected: (category) {
            setState(() => _selectedCategory = category);
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  void _onAddRule() {
    final rule = SmartRuleModel(
      id: const Uuid().v4(),
      keyword: _keywordController.text.trim(),
      categoryName: _selectedCategory!.name,
      categoryIcon: _selectedCategory!.icon,
      categoryColor: _selectedCategory!.iconColor,
      createdAt: DateTime.now(),
    );
    widget.onAdd(rule);
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
            // Handle bar
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                decoration: const BoxDecoration(
                  color: AppColors.gray300,
                  borderRadius: AppRadius.full,
                ),
              ),
            ),

            // Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Add a Rule',
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

            // Keyword label
            Text(
              'KEYWORD',
              style: AppTextStyles.labelM.copyWith(color: AppColors.gray400),
            ),
            const SizedBox(height: AppSpacing.sm),

            // Keyword field
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: AppColors.gray100,
                borderRadius: AppRadius.md,
                border: _keywordError != null
                    ? Border.all(color: AppColors.red, width: 1.5)
                    : null,
              ),
              child: TextField(
                controller: _keywordController,
                autofocus: true,
                style: AppTextStyles.bodyM.copyWith(color: AppColors.black),
                decoration: InputDecoration(
                  hintText: 'e.g. netflix, - diet, rent',
                  hintStyle:
                      AppTextStyles.bodyM.copyWith(color: AppColors.gray400),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: _onKeywordChanged,
                textInputAction: TextInputAction.next,
              ),
            ),

            // Error text
            if (_keywordError != null)
              Padding(
                padding:
                    const EdgeInsets.only(top: AppSpacing.xxs, left: AppSpacing.xs),
                child: Text(
                  _keywordError!,
                  style:
                      AppTextStyles.labelS.copyWith(color: AppColors.red),
                ),
              ),

            const SizedBox(height: AppSpacing.xl),

            // Category label
            Text(
              'CATEGORY',
              style: AppTextStyles.labelM.copyWith(color: AppColors.gray400),
            ),
            const SizedBox(height: AppSpacing.sm),

            // Category selector
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
                        child: Text(
                          _selectedCategory!.name,
                          style: AppTextStyles.bodyM
                              .copyWith(color: AppColors.black),
                        ),
                      ),
                    ] else
                      Expanded(
                        child: Text(
                          'Select category',
                          style: AppTextStyles.bodyM
                              .copyWith(color: AppColors.gray400),
                        ),
                      ),
                    const Icon(Icons.chevron_right,
                        size: 20, color: AppColors.gray400),
                  ],
                ),
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
                    label: 'Add Rule',
                    onTap: _onAddRule,
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
