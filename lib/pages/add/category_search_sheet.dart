import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:finance_buddy_app/core/enums.dart';
import 'package:finance_buddy_app/design_system/design_system.dart';

/// State 04 ("Fix category") of the CoinFlo *Add Expense Flow* design.
///
/// Opens the pickable categories grouped into scannable sections, with a search
/// box and the AI's current guess pre-selected, so correcting a wrong auto-tag
/// is usually a single tap. Pops with the chosen [TransactionCategory], or
/// `null` if dismissed.
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

  /// Pickable expense categories grouped into scannable sections (income and
  /// settlement are not manually pickable here). Ordering puts the most-used
  /// everyday spend first.
  static const List<_Section> _sections = [
    _Section('Everyday', [
      TransactionCategory.foodAndDrink,
      TransactionCategory.transport,
      TransactionCategory.shopping,
      TransactionCategory.personalCare,
    ]),
    _Section('Bills & Home', [
      TransactionCategory.billsAndUtilities,
      TransactionCategory.insurance,
    ]),
    _Section('Lifestyle', [
      TransactionCategory.entertainment,
      TransactionCategory.healthAndWellness,
      TransactionCategory.travel,
      TransactionCategory.education,
    ]),
    _Section('Money', [
      TransactionCategory.cash,
      TransactionCategory.investments,
    ]),
    _Section('More', [
      TransactionCategory.other,
    ]),
  ];

  /// Sections with their categories filtered by the live search query; empty
  /// sections are dropped so a search collapses down to just the matches.
  List<_Section> get _filteredSections {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return _sections;
    final result = <_Section>[];
    for (final section in _sections) {
      final matches = section.categories
          .where((c) => c.label.toLowerCase().contains(query))
          .toList();
      if (matches.isNotEmpty) result.add(_Section(section.title, matches));
    }
    return result;
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
    final sections = _filteredSections;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.5;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header — "Category" + circular close button (≥44px hit target)
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
            Semantics(
              button: true,
              label: 'Close',
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.pop(context),
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: Center(
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: const BoxDecoration(
                        color: AppColors.white,
                        shape: BoxShape.circle,
                        boxShadow: AppShadows.sm,
                      ),
                      child: const Icon(Icons.close,
                          size: 18, color: AppColors.black),
                    ),
                  ),
                ),
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
                Semantics(
                  button: true,
                  label: 'Clear search',
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => setState(() {
                      _query = '';
                      _searchController.clear();
                    }),
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(Icons.close,
                          size: 18, color: AppColors.gray500),
                    ),
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.lg),

        // Grouped, selectable category pills — current selection filled (ink).
        ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: sections.isEmpty
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
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final section in sections) ...[
                        Padding(
                          padding:
                              const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: Text(
                            section.title.toUpperCase(),
                            style:
                                AppTextStyles.section.copyWith(fontSize: 11),
                          ),
                        ),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: section.categories.map(_pill).toList(),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                    ],
                  ),
                ),
        ),

        const SizedBox(height: AppSpacing.xs),
      ],
    );
  }

  Widget _pill(TransactionCategory cat) {
    final selected = cat == widget.selected;
    final catColor = AppColors.categoryColor(cat);
    return Semantics(
      button: true,
      selected: selected,
      label: cat.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _select(cat),
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
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
      ),
    );
  }
}

/// A titled group of pickable categories in the category search sheet.
class _Section {
  const _Section(this.title, this.categories);

  final String title;
  final List<TransactionCategory> categories;
}
