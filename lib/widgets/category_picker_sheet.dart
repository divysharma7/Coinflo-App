import 'package:flutter/material.dart';

import 'package:finance_buddy_app/constants/app_categories.dart';
import 'package:finance_buddy_app/design_system/design_system.dart';
import 'package:finance_buddy_app/models/category_budget_model.dart';

class CategoryPickerSheet extends StatefulWidget {
  const CategoryPickerSheet({
    super.key,
    required this.onSelected,
    this.selectedCategory,
  });

  final ValueChanged<AppCategory> onSelected;
  final String? selectedCategory;

  @override
  State<CategoryPickerSheet> createState() => _CategoryPickerSheetState();
}

class _CategoryPickerSheetState extends State<CategoryPickerSheet> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  Map<CategoryGroup, List<AppCategory>> get _filteredCategories {
    if (_searchQuery.isEmpty) return kAllCategories;

    final query = _searchQuery.toLowerCase();
    final filtered = <CategoryGroup, List<AppCategory>>{};

    for (final entry in kAllCategories.entries) {
      final matching = entry.value
          .where((c) => c.name.toLowerCase().contains(query))
          .toList();
      if (matching.isNotEmpty) {
        filtered[entry.key] = matching;
      }
    }
    return filtered;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = _filteredCategories;

    return Container(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Select Category',
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
          ),

          const SizedBox(height: AppSpacing.md),

          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Container(
              height: 44,
              decoration: const BoxDecoration(
                color: AppColors.gray100,
                borderRadius: AppRadius.md,
              ),
              child: TextField(
                controller: _searchController,
                style: AppTextStyles.bodyM.copyWith(color: AppColors.black),
                decoration: InputDecoration(
                  hintText: 'Search category...',
                  hintStyle:
                      AppTextStyles.bodyM.copyWith(color: AppColors.gray400),
                  prefixIcon: const Icon(Icons.search,
                      color: AppColors.gray400, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? GestureDetector(
                          onTap: () => setState(() {
                            _searchQuery = '';
                            _searchController.clear();
                          }),
                          child: const Icon(Icons.close,
                              color: AppColors.gray400, size: 18),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onChanged: (val) => setState(() => _searchQuery = val),
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.sm),

          // Category list
          Expanded(
            child: categories.isEmpty
                ? Center(
                    child: Text(
                      'No categories found',
                      style: AppTextStyles.bodyM
                          .copyWith(color: AppColors.gray400),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg),
                    itemCount: _buildItems(categories).length,
                    itemBuilder: (context, index) {
                      return _buildItems(categories)[index];
                    },
                  ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildItems(Map<CategoryGroup, List<AppCategory>> categories) {
    final items = <Widget>[];

    for (final entry in categories.entries) {
      // Group header
      items.add(
        Padding(
          padding: EdgeInsets.only(
            top: items.isEmpty ? 0 : AppSpacing.lg,
            bottom: AppSpacing.xs,
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: entry.key.iconColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                entry.key.label.toUpperCase(),
                style:
                    AppTextStyles.labelM.copyWith(color: AppColors.gray400),
              ),
            ],
          ),
        ),
      );

      // Subcategory rows
      for (final category in entry.value) {
        final isSelected = category.name == widget.selectedCategory;
        items.add(
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => widget.onSelected(category),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: category.iconColor.withValues(alpha: 0.12),
                      borderRadius: AppRadius.sm,
                    ),
                    child: Icon(category.icon,
                        size: 18, color: category.iconColor),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(category.name, style: AppTextStyles.bodyM),
                  ),
                  if (isSelected)
                    const Icon(Icons.check, size: 18, color: AppColors.black),
                ],
              ),
            ),
          ),
        );
      }
    }

    return items;
  }
}
