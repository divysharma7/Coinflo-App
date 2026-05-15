import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:finance_buddy_app/core/enums.dart';
import 'package:finance_buddy_app/design_system/design_system.dart';
import 'package:finance_buddy_app/data/db.dart';
import 'package:finance_buddy_app/providers/providers.dart';
import 'package:finance_buddy_app/widgets/common/amount_text.dart';
import 'package:finance_buddy_app/widgets/common/empty_state.dart';
import 'package:finance_buddy_app/widgets/common/neo_pop_button.dart';
import 'package:finance_buddy_app/pages/transactions/transaction_detail_page.dart';
import 'package:finance_buddy_app/widgets/common/spendler_bottom_sheet.dart';
import 'package:finance_buddy_app/widgets/common/animations.dart';
import 'package:flutter_animate/flutter_animate.dart';

class TransactionsPage extends ConsumerStatefulWidget {
  const TransactionsPage({super.key});

  @override
  ConsumerState<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends ConsumerState<TransactionsPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  static String _currencySymbol(String code) {
    switch (code.toLowerCase()) {
      case 'inr': return '\u20B9';
      case 'usd': return '\$';
      case 'eur': return '\u20AC';
      case 'gbp': return '\u00A3';
      case 'jpy': return '\u00A5';
      default: return '\$';
    }
  }

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

    return Column(
      children: [
        SizedBox(height: MediaQuery.paddingOf(context).top + AppSpacing.md),

        // Header + filter button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Row(
            children: [
              const Text('TRANSACTIONS', style: AppTextStyles.labelM),
              const Spacer(),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  GestureDetector(
                    onTap: () => _showFilterSheet(context, ref),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: filters.hasAnyFilter
                            ? AppColors.black.withValues(alpha: 0.12)
                            : AppColors.white,
                        borderRadius: BorderRadius.circular(100),
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
                          const SizedBox(width: 4),
                          Text(
                            filters.hasAnyFilter ? 'Filtered' : 'Filter',
                            style: TextStyle(
                              color: filters.hasAnyFilter ? AppColors.black : AppColors.gray500,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (filters.hasAnyFilter)
                    Positioned(
                      top: -6,
                      right: -6,
                      child: Container(
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
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        // Search bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: TextField(
            controller: _searchController,
            onChanged: (v) => setState(() => _searchQuery = v.trim()),
            style: const TextStyle(fontSize: 14, color: AppColors.black),
            decoration: InputDecoration(
              hintText: 'Search by merchant, note, or category',
              hintStyle: const TextStyle(fontSize: 13, color: AppColors.gray400),
              prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.gray400),
              suffixIcon: _searchQuery.isNotEmpty
                  ? GestureDetector(
                      onTap: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                      child: const Icon(Icons.close, size: 18, color: AppColors.gray400),
                    )
                  : null,
              filled: true,
              fillColor: AppColors.gray100,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(100),
                borderSide: BorderSide.none,
              ),
            ),
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
                            label: _amountLabel(filters.amount),
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
                GestureDetector(
                  onTap: () => ref.read(transactionFiltersProvider.notifier).state = TransactionFilters.empty,
                  child: const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Text('Clear all', style: TextStyle(color: AppColors.black, fontSize: 12, fontWeight: FontWeight.w500)),
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
                      ? 'No transactions match your search.'
                      : 'No transactions match these filters.',
                  subtitle: _searchQuery.isNotEmpty
                      ? 'Try a different search term.'
                      : 'Try adjusting your filters.',
                );
              }

              final unconfirmed = filtered.where((t) => t.status == 'unconfirmed').toList();
              final confirmed = filtered.where((t) => t.status != 'unconfirmed').toList();

              final items = <Widget>[];

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
              if (unconfirmed.isNotEmpty) {
                items.add(const Padding(
                  padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xs),
                  child: Text('UNCONFIRMED', style: AppTextStyles.labelM),
                ).animate().fadeIn(duration: 200.ms).slideX(begin: -0.1, duration: 200.ms));
                for (final t in unconfirmed) {
                  final delay = Duration(milliseconds: 30 * tileIndex);
                  items.add(_buildTile(context, t, isUnconfirmed: true)
                      .animate().fadeIn(delay: delay, duration: 300.ms).slideX(begin: 0.05, delay: delay, duration: 300.ms));
                  if (tileIndex < 20) tileIndex++;
                }
                items.add(const Divider(color: AppColors.gray200));
              }
              if (confirmed.isNotEmpty) {
                items.add(const Padding(
                  padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xs),
                  child: Text('CONFIRMED', style: AppTextStyles.labelM),
                ).animate().fadeIn(duration: 200.ms).slideX(begin: -0.1, duration: 200.ms));
                for (final t in confirmed) {
                  final delay = Duration(milliseconds: 30 * tileIndex);
                  items.add(_buildTile(context, t)
                      .animate().fadeIn(delay: delay, duration: 300.ms).slideX(begin: 0.05, delay: delay, duration: 300.ms));
                  if (tileIndex < 20) tileIndex++;
                }
              }
              items.add(const SizedBox(height: 80));

              return ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) => items[index],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.black)),
            error: (_, _) => const Center(child: Text('Error loading', style: TextStyle(color: AppColors.red))),
          ),
        ),
      ],
    );
  }

  Widget _buildTile(BuildContext context, SpendlerTransaction t, {bool isUnconfirmed = false}) {
    final cat = TransactionCategory.values.firstWhere(
      (c) => c.name == t.category,
      orElse: () => TransactionCategory.foodAndDrink,
    );
    final catColor = AppColors.categoryColor(cat);
    final isSent = t.amount < 0;

    return PressableCard(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => TransactionDetailPage(transactionId: t.id),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 10),
        decoration: BoxDecoration(
          color: isUnconfirmed ? const Color(0xFFF59E0B).withValues(alpha: 0.06) : null,
          border: isUnconfirmed
              ? const Border(left: BorderSide(color: Color(0xFFF59E0B), width: 3))
              : null,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: catColor.withValues(alpha: 0.15),
              child: Icon(cat.iconFill, color: catColor, size: 20),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          t.merchant ?? cat.label,
                          style: AppTextStyles.bodyM,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      PhosphorIcon(
                        isSent ? PhosphorIcons.arrowUpRight() : PhosphorIcons.arrowDownLeft(),
                        size: 14,
                        color: isSent ? AppColors.red : AppColors.green,
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('d MMM, h:mm a').format(t.happenedAt),
                    style: const TextStyle(fontSize: 12, color: AppColors.gray400),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                AmountText(
                  amount: t.amount.toDouble(),
                  symbol: _currencySymbol(ref.watch(selectedCurrencyProvider).valueOrNull ?? 'inr'),
                ),
                if (isUnconfirmed)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: const Text(
                      'Pending',
                      style: TextStyle(
                        color: Color(0xFFF59E0B),
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
    );
  }

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

  String _amountLabel(AmountFilter f) {
    final s = _currencySymbol(ref.watch(selectedCurrencyProvider).valueOrNull ?? 'inr');
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
  String get _sym {
    final code = ref.watch(selectedCurrencyProvider).valueOrNull ?? 'inr';
    switch (code.toLowerCase()) {
      case 'inr': return '\u20B9';
      case 'usd': return '\$';
      case 'eur': return '\u20AC';
      case 'gbp': return '\u00A3';
      case 'jpy': return '\u00A5';
      default: return '\$';
    }
  }

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
              GestureDetector(
                onTap: () => setState(() => _draft = TransactionFilters.empty),
                child: const Text('Clear all', style: TextStyle(color: AppColors.black, fontSize: 12, fontWeight: FontWeight.w500)),
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
            spacing: 8,
            runSpacing: 8,
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
            spacing: 8,
            runSpacing: 8,
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
            spacing: 8,
            runSpacing: 8,
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

          // ── Apply ──
          NeoPOPButton(
            label: 'Apply Filters',
            onTap: () {
              ref.read(transactionFiltersProvider.notifier).state = _draft;
              Navigator.pop(context);
            },
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
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.1) : AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? color : AppColors.gray200,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              PhosphorIcon(icon, size: 18, color: selected ? color : AppColors.gray500),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: selected ? color : AppColors.black,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.black.withValues(alpha: 0.12) : AppColors.white,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: selected ? AppColors.black : AppColors.gray200,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.black : AppColors.gray500,
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
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
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.black.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(color: AppColors.black, fontSize: 11, fontWeight: FontWeight.w500)),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: PhosphorIcon(PhosphorIcons.x(), size: 12, color: AppColors.black),
          ),
        ],
      ),
    );
  }
}
