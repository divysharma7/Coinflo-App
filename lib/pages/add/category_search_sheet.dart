import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:finance_buddy_app/core/enums.dart';
import 'package:finance_buddy_app/design_system/design_system.dart';

/// State 04 ("Fix category") of the CoinFlo *Add Expense Flow* design.
///
/// Opens the full category list with a search box and the AI's current guess
/// pre-selected, so correcting a wrong auto-tag is usually a single tap. Pops
/// with the chosen [TransactionCategory], or `null` if dismissed.
class CategorySearchSheet extends StatefulWidget {
  const CategorySearchSheet({super.key, required this.selected});

  /// The currently-applied category (AI guess or manual) — pre-selected.
  final TransactionCategory selected;

  @override
  State<CategorySearchSheet> createState() => _CategorySearchSheetState();
}

class _CategorySearchSheetState extends State<CategorySearchSheet> {
  final _searchController = TextEditingController();
  String _query = '';

  /// Pickable expense categories (income/settlement excluded), filtered by the
  /// live search query against the human label.
  List<TransactionCategory> get _results {
    final all = TransactionCategory.pickableGroups
        .where((c) => c != TransactionCategory.income)
        .toList();
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return all;
    return all.where((c) => c.label.toLowerCase().contains(query)).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _select(TransactionCategory cat) {
    HapticFeedback.selectionClick();
    Navigator.pop(context, cat);
  }

  @override
  Widget build(BuildContext context) {
    final results = _results;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.5;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header — "Category" + circular close button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Category',
              style: AppTextStyles.headingM.copyWith(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.4,
              ),
            ),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(
                  color: AppColors.white,
                  shape: BoxShape.circle,
                  boxShadow: AppShadows.sm,
                ),
                child: const Icon(Icons.close, size: 18, color: AppColors.black),
              ),
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.md),

        // Search field (.pick-search — gray fill, rounded, search icon)
        Container(
          decoration: const BoxDecoration(
            color: AppColors.gray100,
            borderRadius: AppRadius.mdLg,
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Row(
            children: [
              const Icon(Icons.search, size: 20, color: AppColors.gray500),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _query = v),
                  textCapitalization: TextCapitalization.none,
                  style: AppTextStyles.bodyM.copyWith(color: AppColors.black),
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    hintText: 'Search categories…',
                    hintStyle:
                        AppTextStyles.bodyM.copyWith(color: AppColors.gray500),
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  ),
                ),
              ),
              if (_query.isNotEmpty)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() {
                    _query = '';
                    _searchController.clear();
                  }),
                  child: const Icon(Icons.close,
                      size: 18, color: AppColors.gray500),
                ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.lg),

        // Selectable category pills — AI guess pre-selected (ink fill)
        ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: SingleChildScrollView(
            child: results.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 28),
                    child: Center(
                      child: Text(
                        'No categories found',
                        style: AppTextStyles.bodyM
                            .copyWith(color: AppColors.gray500),
                      ),
                    ),
                  )
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: results.map(_pill).toList(),
                  ),
          ),
        ),

        const SizedBox(height: AppSpacing.md),
      ],
    );
  }

  Widget _pill(TransactionCategory cat) {
    final selected = cat == widget.selected;
    final catColor = AppColors.categoryColor(cat);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _select(cat),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
        decoration: BoxDecoration(
          color: selected ? AppColors.black : AppColors.white,
          borderRadius: AppRadius.full,
          boxShadow: AppShadows.sm,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              cat.iconFill,
              size: 15,
              color: selected ? AppColors.white : catColor,
            ),
            const SizedBox(width: 7),
            Text(
              cat.label,
              style: AppTextStyles.bodyM.copyWith(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: selected ? AppColors.white : AppColors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
