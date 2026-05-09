import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:finance_buddy_app/core/enums.dart';
import 'package:finance_buddy_app/core/tokens.dart';
import 'package:finance_buddy_app/data/db.dart';
import 'package:finance_buddy_app/providers/providers.dart';
import 'package:finance_buddy_app/widgets/common/amount_text.dart';
import 'package:finance_buddy_app/widgets/common/empty_state.dart';
import 'package:finance_buddy_app/widgets/common/neo_pop_button.dart';
import 'package:finance_buddy_app/pages/transactions/transaction_detail_page.dart';
import 'package:finance_buddy_app/widgets/common/spendler_bottom_sheet.dart';
import 'package:finance_buddy_app/widgets/common/animations.dart';

class TransactionsPage extends ConsumerWidget {
  const TransactionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(transactionFiltersProvider);
    final txns = ref.watch(filteredTransactionsProvider);

    return Column(
      children: [
        SizedBox(height: MediaQuery.paddingOf(context).top + 16),

        // Header + filter button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: SpendlerSpacing.screenH),
          child: Row(
            children: [
              const Text('TRANSACTIONS', style: SpendlerTextStyles.sectionLabel),
              const Spacer(),
              GestureDetector(
                onTap: () => _showFilterSheet(context, ref),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: filters.hasAnyFilter
                        ? SpendlerColors.yellow.withValues(alpha: 0.12)
                        : SpendlerColors.surface,
                    borderRadius: BorderRadius.circular(SpendlerRadii.pill),
                    border: Border.all(
                      color: filters.hasAnyFilter ? SpendlerColors.yellow : SpendlerColors.border,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PhosphorIcon(
                        PhosphorIcons.funnel(),
                        size: 14,
                        color: filters.hasAnyFilter ? SpendlerColors.yellow : SpendlerColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        filters.hasAnyFilter ? 'Filtered' : 'Filter',
                        style: TextStyle(
                          color: filters.hasAnyFilter ? SpendlerColors.yellow : SpendlerColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: SpendlerSpacing.sm),

        // Active filter chips
        if (filters.hasAnyFilter)
          Padding(
            padding: const EdgeInsets.fromLTRB(SpendlerSpacing.screenH, 0, SpendlerSpacing.screenH, SpendlerSpacing.sm),
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
                    child: Text('Clear all', style: TextStyle(color: SpendlerColors.yellow, fontSize: 12, fontWeight: FontWeight.w500)),
                  ),
                ),
              ],
            ),
          ),

        // Transaction list
        Expanded(
          child: txns.when(
            data: (list) {
              if (list.isEmpty) {
                return const EmptyState(
                  icon: Icons.receipt_long,
                  message: 'No transactions match these filters.',
                  subtitle: 'Try adjusting your filters.',
                );
              }

              final unconfirmed = list.where((t) => t.status == 'unconfirmed').toList();
              final confirmed = list.where((t) => t.status != 'unconfirmed').toList();

              final items = <Widget>[];

              // Confirm All
              if (unconfirmed.length >= 2) {
                items.add(Padding(
                  padding: const EdgeInsets.symmetric(horizontal: SpendlerSpacing.screenH, vertical: SpendlerSpacing.sm),
                  child: NeoPOPButton(
                    label: 'Confirm All (${unconfirmed.length})',
                    onTap: () async {
                      await HapticFeedback.mediumImpact();
                      final repo = ref.read(repositoryProvider);
                      await repo.confirmAllUnconfirmed();
                      await HapticFeedback.heavyImpact();
                    },
                  ),
                ));
              }

              if (unconfirmed.isNotEmpty) {
                items.add(const Padding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Text('UNCONFIRMED', style: SpendlerTextStyles.sectionLabel),
                ));
                for (final t in unconfirmed) {
                  items.add(_buildTile(context, t, isUnconfirmed: true));
                }
                items.add(const Divider(color: SpendlerColors.border));
              }
              if (confirmed.isNotEmpty) {
                items.add(const Padding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Text('CONFIRMED', style: SpendlerTextStyles.sectionLabel),
                ));
                for (final t in confirmed) {
                  items.add(_buildTile(context, t));
                }
              }
              items.add(const SizedBox(height: 80));

              return ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) => items[index],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator(color: SpendlerColors.yellow)),
            error: (_, _) => const Center(child: Text('Error loading', style: TextStyle(color: SpendlerColors.expense))),
          ),
        ),
      ],
    );
  }

  Widget _buildTile(BuildContext context, SpendlerTransaction t, {bool isUnconfirmed = false}) {
    final cat = TransactionCategory.values.firstWhere(
      (c) => c.name == t.category,
      orElse: () => TransactionCategory.food,
    );
    final catColor = SpendlerColors.categoryColor(cat);
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
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isUnconfirmed ? SpendlerColors.amber.withValues(alpha: 0.06) : null,
          border: isUnconfirmed
              ? const Border(left: BorderSide(color: SpendlerColors.amber, width: 3))
              : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: catColor.withValues(alpha: 0.15),
              child: Icon(cat.iconFill, color: catColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(t.merchant ?? cat.label, style: SpendlerTextStyles.merchantName),
                      ),
                      PhosphorIcon(
                        isSent ? PhosphorIcons.arrowUpRight() : PhosphorIcons.arrowDownLeft(),
                        size: 14,
                        color: isSent ? SpendlerColors.expense : SpendlerColors.income,
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('d MMM, h:mm a').format(t.happenedAt),
                    style: const TextStyle(fontSize: 12, color: SpendlerColors.textTertiary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            AmountText(amount: t.amount.toDouble()),
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

  static String _amountLabel(AmountFilter f) {
    switch (f) {
      case AmountFilter.upto200:
        return '≤ \$200';
      case AmountFilter.range200to500:
        return '\$200–500';
      case AmountFilter.range500to2000:
        return '\$500–2K';
      case AmountFilter.above2000:
        return '> \$2K';
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
              const Text('FILTERS', style: SpendlerTextStyles.sectionLabel),
              GestureDetector(
                onTap: () => setState(() => _draft = TransactionFilters.empty),
                child: const Text('Clear all', style: TextStyle(color: SpendlerColors.yellow, fontSize: 12, fontWeight: FontWeight.w500)),
              ),
            ],
          ),
          const SizedBox(height: SpendlerSpacing.lg),

          // ── Direction ──
          const Text('PAYMENT TYPE', style: SpendlerTextStyles.sectionLabel),
          const SizedBox(height: SpendlerSpacing.sm),
          Row(
            children: [
              _FilterTile(
                icon: PhosphorIcons.arrowUpRight(),
                label: 'Money Sent',
                color: SpendlerColors.expense,
                selected: _draft.direction == DirectionFilter.sent,
                onTap: () => setState(() => _draft = _draft.copyWith(
                  direction: _draft.direction == DirectionFilter.sent
                      ? DirectionFilter.all
                      : DirectionFilter.sent,
                )),
              ),
              const SizedBox(width: SpendlerSpacing.sm),
              _FilterTile(
                icon: PhosphorIcons.arrowDownLeft(),
                label: 'Money Received',
                color: SpendlerColors.income,
                selected: _draft.direction == DirectionFilter.received,
                onTap: () => setState(() => _draft = _draft.copyWith(
                  direction: _draft.direction == DirectionFilter.received
                      ? DirectionFilter.all
                      : DirectionFilter.received,
                )),
              ),
            ],
          ),
          const SizedBox(height: SpendlerSpacing.lg),

          // ── Amount ──
          const Text('AMOUNT', style: SpendlerTextStyles.sectionLabel),
          const SizedBox(height: SpendlerSpacing.sm),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ChipOption(label: '≤ \$200', selected: _draft.amount == AmountFilter.upto200, onTap: () => setState(() => _draft = _draft.copyWith(amount: _draft.amount == AmountFilter.upto200 ? AmountFilter.all : AmountFilter.upto200))),
              _ChipOption(label: '\$200 – 500', selected: _draft.amount == AmountFilter.range200to500, onTap: () => setState(() => _draft = _draft.copyWith(amount: _draft.amount == AmountFilter.range200to500 ? AmountFilter.all : AmountFilter.range200to500))),
              _ChipOption(label: '\$500 – 2,000', selected: _draft.amount == AmountFilter.range500to2000, onTap: () => setState(() => _draft = _draft.copyWith(amount: _draft.amount == AmountFilter.range500to2000 ? AmountFilter.all : AmountFilter.range500to2000))),
              _ChipOption(label: '> \$2,000', selected: _draft.amount == AmountFilter.above2000, onTap: () => setState(() => _draft = _draft.copyWith(amount: _draft.amount == AmountFilter.above2000 ? AmountFilter.all : AmountFilter.above2000))),
            ],
          ),
          const SizedBox(height: SpendlerSpacing.lg),

          // ── Date ──
          const Text('DATE', style: SpendlerTextStyles.sectionLabel),
          const SizedBox(height: SpendlerSpacing.sm),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ChipOption(label: 'Last 30 days', selected: _draft.date == DateFilter.last30, onTap: () => setState(() => _draft = _draft.copyWith(date: _draft.date == DateFilter.last30 ? DateFilter.all : DateFilter.last30))),
              _ChipOption(label: 'Last 90 days', selected: _draft.date == DateFilter.last90, onTap: () => setState(() => _draft = _draft.copyWith(date: _draft.date == DateFilter.last90 ? DateFilter.all : DateFilter.last90))),
            ],
          ),
          const SizedBox(height: SpendlerSpacing.lg),

          // ── Category ──
          const Text('CATEGORY', style: SpendlerTextStyles.sectionLabel),
          const SizedBox(height: SpendlerSpacing.sm),
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
          const SizedBox(height: SpendlerSpacing.xl),

          // ── Apply ──
          NeoPOPButton(
            label: 'Apply Filters',
            onTap: () {
              ref.read(transactionFiltersProvider.notifier).state = _draft;
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: SpendlerSpacing.md),
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
          duration: SpendlerMotion.micro,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.1) : SpendlerColors.surface,
            borderRadius: BorderRadius.circular(SpendlerRadii.button),
            border: Border.all(
              color: selected ? color : SpendlerColors.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              PhosphorIcon(icon, size: 18, color: selected ? color : SpendlerColors.textSecondary),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: selected ? color : SpendlerColors.textPrimary,
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
          color: selected ? SpendlerColors.yellow.withValues(alpha: 0.12) : SpendlerColors.surface,
          borderRadius: BorderRadius.circular(SpendlerRadii.pill),
          border: Border.all(
            color: selected ? SpendlerColors.yellow : SpendlerColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? SpendlerColors.yellow : SpendlerColors.textSecondary,
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
        color: SpendlerColors.yellow.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(SpendlerRadii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(color: SpendlerColors.yellow, fontSize: 11, fontWeight: FontWeight.w500)),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: PhosphorIcon(PhosphorIcons.x(), size: 12, color: SpendlerColors.yellow),
          ),
        ],
      ),
    );
  }
}
