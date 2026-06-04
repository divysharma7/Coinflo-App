import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:finance_buddy_app/core/enums.dart';
import 'package:finance_buddy_app/design_system/design_system.dart';
import 'package:finance_buddy_app/data/db.dart';
import 'package:finance_buddy_app/providers/providers.dart';
import 'package:finance_buddy_app/widgets/common/empty_state.dart';
import 'package:finance_buddy_app/widgets/common/neo_pop_button.dart';
import 'package:finance_buddy_app/widgets/common/spendler_bottom_sheet.dart';
import 'package:finance_buddy_app/widgets/common/transaction_actions.dart';
import 'package:finance_buddy_app/widgets/common/animations.dart';
import 'package:finance_buddy_app/utils/currency_utils.dart';

class TransactionsPage extends ConsumerStatefulWidget {
  const TransactionsPage({super.key});

  @override
  ConsumerState<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends ConsumerState<TransactionsPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _hasAnimatedInitial = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Returns true if [t] matches the current [_searchQuery].
  bool _matchesSearch(SpendlerTransaction t) {
    if (_searchQuery.isEmpty) return true;
    final q = _searchQuery.toLowerCase();
    final merchant = (t.merchant ?? '').toLowerCase();
    final note = (t.note ?? '').toLowerCase();
    final catLabel = TransactionCategory.values
        .firstWhere(
          (c) => c.name == t.category,
          orElse: () => TransactionCategory.other,
        )
        .label
        .toLowerCase();
    return merchant.contains(q) || note.contains(q) || catLabel.contains(q);
  }

  @override
  Widget build(BuildContext context) {
    final filters = ref.watch(transactionFiltersProvider);
    final txns = ref.watch(filteredTransactionsProvider);
    // M9: Hoist currency symbol — resolve once per build, not per tile
    final sym = currencySymbol(ref.watch(selectedCurrencyProvider).valueOrNull ?? 'inr');

    return Column(
      children: [
        SizedBox(height: MediaQuery.paddingOf(context).top + AppSpacing.md),

        // "Pushed" month-nav header: ‹  [ Month YYYY ⌄ ]  ›
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: const _MonthNavHeader(),
        ),
        const SizedBox(height: 14),

        // Search field (white, rounded-14, soft shadow)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: AppRadius.md,
              boxShadow: AppShadows.sm,
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v.trim()),
              style: AppTextStyles.bodyM.copyWith(color: AppColors.black),
              decoration: InputDecoration(
                hintText: 'Search transactions…',
                hintStyle: AppTextStyles.bodyM.copyWith(color: AppColors.gray400),
                prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.gray400),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, size: 18, color: AppColors.gray500),
                        tooltip: 'Clear search',
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: false,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                border: const OutlineInputBorder(
                  borderRadius: AppRadius.md,
                  borderSide: BorderSide.none,
                ),
                enabledBorder: const OutlineInputBorder(
                  borderRadius: AppRadius.md,
                  borderSide: BorderSide.none,
                ),
                focusedBorder: const OutlineInputBorder(
                  borderRadius: AppRadius.md,
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Summary row: Expenses (dark) · Income · Net (green when +)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: _SummaryRow(sym: sym),
        ),
        const SizedBox(height: AppSpacing.sm),

        // Filter button (kept; preserves filter sheet behaviour)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Row(
            children: [
              const Spacer(),
              Semantics(
                button: true,
                label: filters.hasAnyFilter
                    ? 'Filter transactions, ${_activeFilterCount(filters)} filters active'
                    : 'Filter transactions',
                hint: 'Opens filter options',
                child: GestureDetector(
                  onTap: () => _showFilterSheet(context, ref),
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: filters.hasAnyFilter
                          ? AppColors.black.withValues(alpha: 0.12)
                          : AppColors.white,
                      borderRadius: AppRadius.pill,
                      border: Border.all(
                        color: filters.hasAnyFilter ? AppColors.black : AppColors.gray200,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        PhosphorIcon(
                          PhosphorIcons.funnel(),
                          size: 14,
                          color: filters.hasAnyFilter ? AppColors.black : AppColors.gray500,
                        ),
                        const SizedBox(width: AppSpacing.xxs),
                        Text(
                          filters.hasAnyFilter ? 'Filtered' : 'Filter',
                          style: AppTextStyles.labelM.copyWith(
                            color: filters.hasAnyFilter ? AppColors.black : AppColors.gray500,
                          ),
                        ),
                        if (filters.hasAnyFilter) ...[
                          const SizedBox(width: AppSpacing.xxs),
                          Container(
                            width: 18,
                            height: 18,
                            decoration: const BoxDecoration(
                              color: AppColors.black,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${_activeFilterCount(filters)}',
                              style: const TextStyle(
                                color: AppColors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                height: 1,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        // Active filter chips
        if (filters.hasAnyFilter)
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.sm),
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        if (filters.direction != DirectionFilter.all)
                          _ActiveChip(
                            label: filters.direction == DirectionFilter.sent ? 'Sent' : 'Received',
                            onRemove: () => ref.read(transactionFiltersProvider.notifier).state =
                                filters.copyWith(direction: DirectionFilter.all),
                          ),
                        if (filters.amount != AmountFilter.all)
                          _ActiveChip(
                            label: _amountLabel(filters.amount, sym),
                            onRemove: () => ref.read(transactionFiltersProvider.notifier).state =
                                filters.copyWith(amount: AmountFilter.all),
                          ),
                        if (filters.date != DateFilter.all)
                          _ActiveChip(
                            label: filters.date == DateFilter.last30 ? '30 days' : '90 days',
                            onRemove: () => ref.read(transactionFiltersProvider.notifier).state =
                                filters.copyWith(date: DateFilter.all),
                          ),
                        if (filters.category != null)
                          _ActiveChip(
                            label: filters.category!.label,
                            onRemove: () => ref.read(transactionFiltersProvider.notifier).state =
                                filters.copyWith(clearCategory: true),
                          ),
                      ],
                    ),
                  ),
                ),
                Semantics(
                  button: true,
                  label: 'Clear all filters',
                  child: GestureDetector(
                    onTap: () => ref.read(transactionFiltersProvider.notifier).state = TransactionFilters.empty,
                    child: Padding(
                      padding: const EdgeInsets.only(left: AppSpacing.xs),
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                        alignment: Alignment.center,
                        child: Text('Clear all', style: AppTextStyles.labelM.copyWith(color: AppColors.black)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Transaction list
        Expanded(
          child: txns.when(
            data: (list) {
              final filtered = _searchQuery.isEmpty
                  ? list
                  : list.where(_matchesSearch).toList();

              if (filtered.isEmpty) {
                return EmptyState(
                  icon: Icons.receipt_long,
                  message: _searchQuery.isNotEmpty
                      ? 'Nothing matches that search.'
                      : 'Nothing matches these filters.',
                  subtitle: _searchQuery.isNotEmpty
                      ? 'Try different words.'
                      : 'Try loosening up the filters.',
                );
              }

              final unconfirmed = filtered.where((t) => t.status == 'unconfirmed').toList();
              final confirmed = filtered.where((t) => t.status != 'unconfirmed').toList();

              // H8: Only animate on first data load
              final shouldAnimate = !_hasAnimatedInitial;
              if (shouldAnimate) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) _hasAnimatedInitial = true;
                });
              }

              final items = <Widget>[];

              // "N transactions" count (grotesk w700)
              items.add(Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xs, AppSpacing.lg, 0),
                child: Text(
                  '${filtered.length} transaction${filtered.length == 1 ? '' : 's'}',
                  style: AppTextStyles.bodyM.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
              ));

              // Confirm All
              if (unconfirmed.length >= 2) {
                items.add(Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                  child: NeoPOPButton(
                    label: 'Confirm All (${unconfirmed.length})',
                    onTap: () async {
                      final didConfirm = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: Text(
                            'Confirm all ${unconfirmed.length} unconfirmed transactions?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Confirm'),
                            ),
                          ],
                        ),
                      );
                      if (didConfirm == true) {
                        await HapticFeedback.mediumImpact();
                        final repo = ref.read(repositoryProvider);
                        await repo.confirmAllUnconfirmed();
                        await HapticFeedback.heavyImpact();
                      }
                    },
                  ),
                ));
              }

              var tileIndex = 0;

              // Wraps a list of transaction rows in a white card, inserting
              // hairline dividers between rows (matches the Hi-Fi `.card`).
              Widget cardFor(List<SpendlerTransaction> group, {bool unconfirmed = false}) {
                final rows = <Widget>[];
                for (var i = 0; i < group.length; i++) {
                  final tile = _buildTile(context, group[i], sym, isUnconfirmed: unconfirmed);
                  rows.add(shouldAnimate
                      ? StaggeredItem(index: tileIndex, child: tile)
                      : tile);
                  if (tileIndex < 20) tileIndex++;
                  if (i < group.length - 1) {
                    rows.add(const Divider(
                      height: 1, thickness: 1, color: AppColors.gray100,
                      indent: AppSpacing.sm, endIndent: AppSpacing.sm,
                    ));
                  }
                }
                return Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, 0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: AppRadius.xl,
                      boxShadow: AppShadows.sm,
                    ),
                    child: Column(children: rows),
                  ),
                );
              }

              Widget sectionEyebrow(String label) => Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xs),
                    child: Semantics(
                      header: true,
                      child: Text(label, style: AppTextStyles.section),
                    ),
                  );

              // Unconfirmed transactions — own section + white card.
              if (unconfirmed.isNotEmpty) {
                items.add(sectionEyebrow('Unconfirmed'));
                items.add(cardFor(unconfirmed, unconfirmed: true));
              }

              // Confirmed transactions — grouped by day, one white card per day.
              if (confirmed.isNotEmpty) {
                final byDay = <DateTime, List<SpendlerTransaction>>{};
                for (final t in confirmed) {
                  final d = DateTime(t.happenedAt.year, t.happenedAt.month, t.happenedAt.day);
                  byDay.putIfAbsent(d, () => []).add(t);
                }
                final days = byDay.keys.toList()..sort((a, b) => b.compareTo(a));
                for (final day in days) {
                  items.add(sectionEyebrow(_dayLabel(day)));
                  items.add(cardFor(byDay[day]!));
                }
              }
              items.add(const SizedBox(height: 80));

              return RefreshIndicator(
                color: AppColors.black,
                backgroundColor: AppColors.white,
                semanticsLabel: 'Pull to refresh transactions',
                onRefresh: () async {
                  ref.invalidate(filteredTransactionsProvider);
                },
                child: ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) => items[index],
                ),
              );
            },
            loading: () => Center(
              child: Semantics(
                label: 'Loading transactions',
                child: CircularProgressIndicator(color: AppColors.black),
              ),
            ),
            error: (_, __) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Something went wrong', style: AppTextStyles.bodyM.copyWith(color: AppColors.gray500)),
                  const SizedBox(height: AppSpacing.sm),
                  FilledButton(
                    onPressed: () => ref.invalidate(filteredTransactionsProvider),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.black,
                      foregroundColor: AppColors.white,
                      shape: RoundedRectangleBorder(borderRadius: AppRadius.s),
                    ),
                    child: const Text('Retry loading transactions'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTile(BuildContext context, SpendlerTransaction t, String sym, {bool isUnconfirmed = false}) {
    final cat = TransactionCategory.values.firstWhere(
      (c) => c.name == t.category,
      orElse: () => TransactionCategory.foodAndDrink,
    );
    final catBg = AppColors.categoryBg(cat);
    final catFg = AppColors.categoryFg(cat);
    final isSent = t.amount < 0;
    // Right-aligned mono amount: ink for expenses, green-deep for income.
    final amountText = '${isSent ? '−' : '+'}$sym${t.amount.abs().toStringAsFixed(0)}';

    return Semantics(
      label: '${t.merchant ?? cat.label}, '
          '${isSent ? "expense" : "income"}, '
          '$sym${t.amount.abs().toStringAsFixed(0)}, '
          '${DateFormat("d MMM").format(t.happenedAt)}'
          '${isUnconfirmed ? ", pending confirmation" : ""}',
      hint: 'Double-tap to view details. Double-tap and hold for more options.',
      button: true,
      onTap: () => context.push('/transaction/${t.id}'),
      onLongPressHint: 'Edit or delete',
      onLongPress: () => showTransactionActions(context, ref, t, sym),
      child: ExcludeSemantics(
        child: PressableCard(
          onTap: () => context.push('/transaction/${t.id}'),
          onLongPress: () => showTransactionActions(context, ref, t, sym),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 11),
            decoration: BoxDecoration(
              color: isUnconfirmed ? AppColors.amber.withValues(alpha: 0.06) : null,
              border: isUnconfirmed
                  ? const Border(left: BorderSide(color: AppColors.amber, width: 3))
                  : null,
              borderRadius: AppRadius.md,
            ),
            child: Row(
              children: [
                // Category tile (rounded-14, catBg/catFg)
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: catBg,
                    borderRadius: AppRadius.md,
                  ),
                  child: Icon(cat.iconFill, color: catFg, size: 22),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.merchant ?? cat.label,
                        style: AppTextStyles.bodyM.copyWith(
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      // Meta: category pill · time
                      Row(
                        children: [
                          CategoryPill(category: cat.label),
                          Flexible(
                            child: Text(
                              ' · ${DateFormat('h:mm a').format(t.happenedAt)}',
                              style: AppTextStyles.bodyS.copyWith(color: AppColors.gray500),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      amountText,
                      style: AppTextStyles.numericM.copyWith(
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.5,
                        color: isSent ? AppColors.black : AppColors.catGreenText,
                      ),
                    ),
                    if (isUnconfirmed)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.amber.withValues(alpha: 0.15),
                          borderRadius: AppRadius.pill,
                        ),
                        child: Text(
                          'Pending',
                          style: TextStyle(
                            color: AppColors.amber.withValues(alpha: 1.0),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Human day label for a section eyebrow: "Today" / "Yesterday" / "Sun, 10 May".
  static String _dayLabel(DateTime day) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return DateFormat('EEE, d MMM').format(day);
  }

  // Transaction actions and delete now use shared util from transaction_actions.dart

  void _showFilterSheet(BuildContext context, WidgetRef ref) {
    showSpendlerSheet<void>(
      context: context,
      builder: (_) => const _FilterSheet(),
    );
  }

  static int _activeFilterCount(TransactionFilters filters) {
    int count = 0;
    if (filters.direction != DirectionFilter.all) count++;
    if (filters.amount != AmountFilter.all) count++;
    if (filters.date != DateFilter.all) count++;
    if (filters.category != null) count++;
    return count;
  }

  String _amountLabel(AmountFilter f, String s) {
    switch (f) {
      case AmountFilter.upto200:
        return '\u2264 ${s}200';
      case AmountFilter.range200to500:
        return '${s}200\u2013500';
      case AmountFilter.range500to2000:
        return '${s}500\u20132K';
      case AmountFilter.above2000:
        return '> ${s}2K';
      case AmountFilter.all:
        return '';
    }
  }
}

// ─────────────────────────────────────────────────────
// Filter Bottom Sheet
// ─────────────────────────────────────────────────────

class _FilterSheet extends ConsumerStatefulWidget {
  const _FilterSheet();

  @override
  ConsumerState<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<_FilterSheet> {
  // M7: Use currencyUtils instead of duplicating symbol logic
  String get _sym => currencySymbol(ref.watch(selectedCurrencyProvider).valueOrNull ?? 'inr');

  late TransactionFilters _draft;

  @override
  void initState() {
    super.initState();
    _draft = ref.read(transactionFiltersProvider);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('FILTERS', style: AppTextStyles.labelM),
              Semantics(
                button: true,
                label: 'Clear all filters',
                child: GestureDetector(
                  onTap: () => setState(() => _draft = TransactionFilters.empty),
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                    alignment: Alignment.center,
                    child: Text('Clear all', style: AppTextStyles.labelM.copyWith(color: AppColors.black)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // ── Direction ──
          const Text('PAYMENT TYPE', style: AppTextStyles.labelM),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              _FilterTile(
                icon: PhosphorIcons.arrowUpRight(),
                label: 'Money Sent',
                color: AppColors.red,
                selected: _draft.direction == DirectionFilter.sent,
                onTap: () => setState(() => _draft = _draft.copyWith(
                  direction: _draft.direction == DirectionFilter.sent
                      ? DirectionFilter.all
                      : DirectionFilter.sent,
                )),
              ),
              const SizedBox(width: AppSpacing.sm),
              _FilterTile(
                icon: PhosphorIcons.arrowDownLeft(),
                label: 'Money Received',
                color: AppColors.green,
                selected: _draft.direction == DirectionFilter.received,
                onTap: () => setState(() => _draft = _draft.copyWith(
                  direction: _draft.direction == DirectionFilter.received
                      ? DirectionFilter.all
                      : DirectionFilter.received,
                )),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // ── Amount ──
          const Text('AMOUNT', style: AppTextStyles.labelM),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              _ChipOption(label: '≤ ${_sym}200', selected: _draft.amount == AmountFilter.upto200, onTap: () => setState(() => _draft = _draft.copyWith(amount: _draft.amount == AmountFilter.upto200 ? AmountFilter.all : AmountFilter.upto200))),
              _ChipOption(label: '${_sym}200 – 500', selected: _draft.amount == AmountFilter.range200to500, onTap: () => setState(() => _draft = _draft.copyWith(amount: _draft.amount == AmountFilter.range200to500 ? AmountFilter.all : AmountFilter.range200to500))),
              _ChipOption(label: '${_sym}500 – 2,000', selected: _draft.amount == AmountFilter.range500to2000, onTap: () => setState(() => _draft = _draft.copyWith(amount: _draft.amount == AmountFilter.range500to2000 ? AmountFilter.all : AmountFilter.range500to2000))),
              _ChipOption(label: '> ${_sym}2,000', selected: _draft.amount == AmountFilter.above2000, onTap: () => setState(() => _draft = _draft.copyWith(amount: _draft.amount == AmountFilter.above2000 ? AmountFilter.all : AmountFilter.above2000))),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // ── Date ──
          const Text('DATE', style: AppTextStyles.labelM),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              _ChipOption(label: 'Last 30 days', selected: _draft.date == DateFilter.last30, onTap: () => setState(() => _draft = _draft.copyWith(date: _draft.date == DateFilter.last30 ? DateFilter.all : DateFilter.last30))),
              _ChipOption(label: 'Last 90 days', selected: _draft.date == DateFilter.last90, onTap: () => setState(() => _draft = _draft.copyWith(date: _draft.date == DateFilter.last90 ? DateFilter.all : DateFilter.last90))),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // ── Category ──
          const Text('CATEGORY', style: AppTextStyles.labelM),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: TransactionCategory.values.map((cat) {
              final selected = _draft.category == cat;
              return _ChipOption(
                label: cat.label,
                selected: selected,
                onTap: () => setState(() => _draft = _draft.copyWith(
                  category: selected ? null : cat,
                  clearCategory: selected,
                )),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.xl),

          // ── Apply (H9: FilledButton instead of NeoPOPButton) ──
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: () {
                ref.read(transactionFiltersProvider.notifier).state = _draft;
                Navigator.pop(context);
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.black,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(borderRadius: AppRadius.base),
              ),
              child: const Text('Apply Filters'),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}

class _FilterTile extends StatelessWidget {
  const _FilterTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Semantics(
        label: label,
        checked: selected,
        button: true,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: AppDurations.fast,
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              color: selected ? color.withValues(alpha: 0.1) : AppColors.white,
              borderRadius: AppRadius.base,
              border: Border.all(
                color: selected ? color : AppColors.gray200,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                PhosphorIcon(icon, size: 18, color: selected ? color : AppColors.gray500),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  label,
                  style: AppTextStyles.bodyS.copyWith(
                    color: selected ? color : AppColors.black,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChipOption extends StatelessWidget {
  const _ChipOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      checked: selected,
      button: true,
      hint: selected ? 'Double-tap to remove filter' : 'Double-tap to apply filter',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
          decoration: BoxDecoration(
            color: selected ? AppColors.black.withValues(alpha: 0.12) : AppColors.white,
            borderRadius: AppRadius.pill,
            border: Border.all(
              color: selected ? AppColors.black : AppColors.gray200,
            ),
          ),
          child: Text(
            label,
            style: AppTextStyles.bodyS.copyWith(
              color: selected ? AppColors.black : AppColors.gray500,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}

class _ActiveChip extends StatelessWidget {
  const _ActiveChip({required this.label, required this.onRemove});
  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: AppSpacing.xs),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: AppSpacing.xxs),
      decoration: BoxDecoration(
        color: AppColors.black.withValues(alpha: 0.12),
        borderRadius: AppRadius.pill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: AppTextStyles.labelS.copyWith(color: AppColors.black)),
          const SizedBox(width: AppSpacing.xxs),
          IconButton(
            onPressed: onRemove,
            icon: PhosphorIcon(PhosphorIcons.x(), size: 12, color: AppColors.black),
            tooltip: 'Remove $label filter',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            iconSize: 12,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
// "Pushed" month-nav header  (‹  Month YYYY ⌄  ›)
// ─────────────────────────────────────────────────────

class _MonthNavHeader extends ConsumerWidget {
  const _MonthNavHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(selectedMonthProvider);
    final label = DateFormat('MMMM yyyy').format(month);

    void shift(int delta) => ref.read(selectedMonthProvider.notifier).state =
        DateTime(month.year, month.month + delta);

    return Row(
      children: [
        _RoundIconButton(
          icon: PhosphorIcons.caretLeft(),
          tooltip: 'Previous month',
          onTap: () => shift(-1),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Semantics(
            button: true,
            label: 'Selected month $label, change month',
            child: GestureDetector(
              onTap: () => _showMonthPicker(context, ref, month),
              child: Container(
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: AppRadius.full,
                  boxShadow: AppShadows.sm,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: AppTextStyles.headingS.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Icon(Icons.keyboard_arrow_down, size: 18, color: AppColors.gray400),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        _RoundIconButton(
          icon: PhosphorIcons.caretRight(),
          tooltip: 'Next month',
          onTap: () => shift(1),
        ),
      ],
    );
  }

  void _showMonthPicker(BuildContext context, WidgetRef ref, DateTime current) {
    final now = DateTime.now();
    showSpendlerSheet<void>(
      context: context,
      isScrollControlled: false,
      builder: (_) {
        final months = List.generate(12, (i) => DateTime(now.year, now.month - i));
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...months.map((m) {
                final isSelected = m.year == current.year && m.month == current.month;
                return ListTile(
                  title: Text(
                    DateFormat('MMMM yyyy').format(m),
                    style: AppTextStyles.bodyM.copyWith(
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                      color: isSelected ? AppColors.black : AppColors.gray500,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check, color: AppColors.black, size: 20)
                      : null,
                  onTap: () {
                    ref.read(selectedMonthProvider.notifier).state = m;
                    Navigator.pop(context);
                  },
                );
              }),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        );
      },
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.tooltip, required this.onTap});

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.white,
            shape: BoxShape.circle,
            boxShadow: AppShadows.sm,
          ),
          child: Center(child: PhosphorIcon(icon, size: 19, color: AppColors.black)),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
// Summary row — Expenses (dark) · Income · Net
// ─────────────────────────────────────────────────────

class _SummaryRow extends ConsumerWidget {
  const _SummaryRow({required this.sym});

  final String sym;

  String _fmt(double v) => '$sym${v.abs().toStringAsFixed(0)}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expense = ref.watch(monthlyExpenseProvider).valueOrNull ?? 0;
    final income = ref.watch(monthlyIncomeProvider).valueOrNull ?? 0;
    final net = income - expense;
    final netPositive = net >= 0;

    return Row(
      children: [
        Expanded(
          child: StatTile(
            dark: true,
            icon: PhosphorIcon(PhosphorIcons.arrowDownRight(), color: AppColors.white),
            label: 'Expenses',
            value: _fmt(expense),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: StatTile(
            icon: PhosphorIcon(PhosphorIcons.arrowUpRight(), color: AppColors.catGreenText),
            label: 'Income',
            value: _fmt(income),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: StatTile(
            icon: PhosphorIcon(PhosphorIcons.pulse(), color: AppColors.black),
            label: 'Net',
            value: '${netPositive ? '+' : '−'}${_fmt(net)}',
            valueColor: netPositive ? AppColors.catGreenText : AppColors.black,
          ),
        ),
      ],
    );
  }
}
