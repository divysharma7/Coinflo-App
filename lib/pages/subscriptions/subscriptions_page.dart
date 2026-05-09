import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:finance_buddy_app/core/enums.dart';
import 'package:finance_buddy_app/core/tokens.dart';
import 'package:finance_buddy_app/data/db.dart';
import 'package:finance_buddy_app/providers/providers.dart';
import 'package:finance_buddy_app/widgets/common/empty_state.dart';

class SubscriptionsPage extends ConsumerWidget {
  const SubscriptionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subsAsync = ref.watch(allSubscriptionsProvider);
    final monthlyTotal = ref.watch(subscriptionMonthlyTotalProvider);

    return Scaffold(
      backgroundColor: SpendlerColors.scaffold,
      appBar: AppBar(
        title: const Text(
          'Subscriptions',
          style: TextStyle(
            color: SpendlerColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: SpendlerColors.scaffold,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: SpendlerColors.textPrimary),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: SpendlerColors.accent,
        onPressed: () => _showAddSheet(context, ref),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: subsAsync.when(
        data: (subs) {
          if (subs.isEmpty) {
            return const EmptyState(
              icon: Icons.autorenew,
              message: 'No subscriptions yet',
              subtitle: 'Tap + to track your first subscription.',
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(
              SpendlerSpacing.screenH,
              SpendlerSpacing.sm,
              SpendlerSpacing.screenH,
              100,
            ),
            children: [
              // ── Monthly cost summary ──
              _MonthlySummaryCard(monthlyTotal: monthlyTotal, count: subs.where((s) => s.isActive).length),
              const SizedBox(height: SpendlerSpacing.lg),

              // ── Subscription cards ──
              for (final sub in subs) ...[
                _SubscriptionCard(
                  subscription: sub,
                  onToggle: () {
                    ref.read(repositoryProvider).toggleSubscriptionActive(sub.id, !sub.isActive);
                  },
                  onDelete: () => _confirmDelete(context, ref, sub),
                ),
                const SizedBox(height: SpendlerSpacing.cardGap),
              ],
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: SpendlerColors.accent),
        ),
        error: (_, _) => const Center(
          child: Text('Something went wrong', style: TextStyle(color: SpendlerColors.textSecondary)),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Subscription sub) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete subscription?'),
        content: Text('Remove "${sub.name}" from tracking?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(repositoryProvider).deleteSubscription(sub.id);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: SpendlerColors.destructive)),
          ),
        ],
      ),
    );
  }

  void _showAddSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: SpendlerColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(SpendlerRadii.card)),
      ),
      builder: (_) => const _AddSubscriptionSheet(),
    );
  }
}

// ─── Monthly Summary Card ─────────────────────────────

class _MonthlySummaryCard extends StatelessWidget {
  const _MonthlySummaryCard({required this.monthlyTotal, required this.count});

  final AsyncValue<double> monthlyTotal;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(SpendlerSpacing.lg),
      decoration: BoxDecoration(
        color: SpendlerColors.card,
        borderRadius: BorderRadius.circular(SpendlerRadii.card),
        border: Border.all(color: SpendlerColors.cardBorder),
      ),
      child: Column(
        children: [
          const Text(
            'MONTHLY COST',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: SpendlerColors.textTertiary,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: SpendlerSpacing.sm),
          monthlyTotal.when(
            data: (total) => Text(
              '\$${total.toStringAsFixed(0)}',
              style: const TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w700,
                color: SpendlerColors.textPrimary,
                fontFeatures: [FontFeature.tabularFigures()],
                letterSpacing: -1.5,
              ),
            ),
            loading: () => const Text(
              '...',
              style: TextStyle(fontSize: 40, color: SpendlerColors.textTertiary),
            ),
            error: (_, _) => const Text(
              '—',
              style: TextStyle(fontSize: 40, color: SpendlerColors.destructive),
            ),
          ),
          const SizedBox(height: SpendlerSpacing.xs),
          Text(
            '$count active subscription${count == 1 ? '' : 's'}',
            style: const TextStyle(
              fontSize: 13,
              color: SpendlerColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Subscription Card ────────────────────────────────

class _SubscriptionCard extends StatelessWidget {
  const _SubscriptionCard({
    required this.subscription,
    required this.onToggle,
    required this.onDelete,
  });

  final Subscription subscription;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final cat = TransactionCategory.values.firstWhere(
      (c) => c.name == subscription.category,
      orElse: () => TransactionCategory.other,
    );
    final catColor = subscription.isActive
        ? SpendlerColors.categoryColor(cat)
        : SpendlerColors.paused;
    final cycle = BillingCycle.values.firstWhere(
      (c) => c.name == subscription.billingCycle,
      orElse: () => BillingCycle.monthly,
    );

    return Container(
      padding: const EdgeInsets.all(SpendlerSpacing.cardPadding),
      decoration: BoxDecoration(
        color: SpendlerColors.card,
        borderRadius: BorderRadius.circular(SpendlerRadii.card),
        border: Border.all(
          color: subscription.isActive ? catColor.withValues(alpha: 0.3) : SpendlerColors.cardBorder,
        ),
      ),
      child: Row(
        children: [
          // Category icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: catColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(cat.icon, color: catColor, size: 22),
          ),
          const SizedBox(width: SpendlerSpacing.md),

          // Name + details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subscription.name,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: subscription.isActive
                        ? SpendlerColors.textPrimary
                        : SpendlerColors.textTertiary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '\$${subscription.amount.toStringAsFixed(0)}${cycle.shortLabel} · ${cat.label}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: SpendlerColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subscription.isActive
                      ? 'Next: ${DateFormat('d MMM yyyy').format(subscription.nextBillingDate)}'
                      : 'Paused',
                  style: TextStyle(
                    fontSize: 12,
                    color: subscription.isActive
                        ? SpendlerColors.textTertiary
                        : SpendlerColors.paused,
                    fontStyle: subscription.isActive ? FontStyle.normal : FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),

          // Actions
          IconButton(
            onPressed: onToggle,
            icon: Icon(
              subscription.isActive ? PhosphorIcons.pause() : PhosphorIcons.play(),
              color: subscription.isActive ? SpendlerColors.warning : SpendlerColors.success,
              size: 20,
            ),
            tooltip: subscription.isActive ? 'Pause' : 'Resume',
          ),
          IconButton(
            onPressed: onDelete,
            icon: Icon(
              PhosphorIcons.trash(),
              color: SpendlerColors.destructive.withValues(alpha: 0.7),
              size: 20,
            ),
            tooltip: 'Delete',
          ),
        ],
      ),
    );
  }
}

// ─── Add Subscription Sheet ───────────────────────────

class _AddSubscriptionSheet extends ConsumerStatefulWidget {
  const _AddSubscriptionSheet();

  @override
  ConsumerState<_AddSubscriptionSheet> createState() => _AddSubscriptionSheetState();
}

class _AddSubscriptionSheetState extends ConsumerState<_AddSubscriptionSheet> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  BillingCycle _cycle = BillingCycle.monthly;
  TransactionCategory _category = TransactionCategory.other;
  DateTime _nextDate = DateTime.now().add(const Duration(days: 30));

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        SpendlerSpacing.lg,
        SpendlerSpacing.lg,
        SpendlerSpacing.lg,
        MediaQuery.of(context).viewInsets.bottom + SpendlerSpacing.lg,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: SpendlerColors.textTertiary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: SpendlerSpacing.lg),

            const Text(
              'Add Subscription',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: SpendlerColors.textPrimary,
              ),
            ),
            const SizedBox(height: SpendlerSpacing.lg),

            // Name
            TextField(
              controller: _nameController,
              decoration: _inputDecoration('Name (e.g. Netflix)'),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: SpendlerSpacing.md),

            // Amount
            TextField(
              controller: _amountController,
              decoration: _inputDecoration('Amount (\$)'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: SpendlerSpacing.md),

            // Billing Cycle
            _SelectorRow(
              label: 'Cycle',
              options: BillingCycle.values.map((c) => c.label).toList(),
              selected: _cycle.index,
              onSelected: (i) => setState(() => _cycle = BillingCycle.values[i]),
            ),
            const SizedBox(height: SpendlerSpacing.md),

            // Category
            _SelectorRow(
              label: 'Category',
              options: TransactionCategory.values.map((c) => c.label).toList(),
              selected: _category.index,
              onSelected: (i) => setState(() => _category = TransactionCategory.values[i]),
            ),
            const SizedBox(height: SpendlerSpacing.md),

            // Next billing date
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: SpendlerSpacing.md,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: SpendlerColors.cardBorder),
                  borderRadius: BorderRadius.circular(SpendlerRadii.button),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 18, color: SpendlerColors.textSecondary),
                    const SizedBox(width: SpendlerSpacing.sm),
                    Text(
                      'Next billing: ${DateFormat('d MMM yyyy').format(_nextDate)}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: SpendlerColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: SpendlerSpacing.lg),

            // Save button
            SizedBox(
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: SpendlerColors.accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(SpendlerRadii.button),
                  ),
                  elevation: 0,
                ),
                onPressed: _save,
                child: const Text('Save', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
              ),
            ),
            const SizedBox(height: SpendlerSpacing.sm),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: SpendlerColors.textTertiary),
      filled: true,
      fillColor: SpendlerColors.scaffold,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(SpendlerRadii.button),
        borderSide: const BorderSide(color: SpendlerColors.cardBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(SpendlerRadii.button),
        borderSide: const BorderSide(color: SpendlerColors.cardBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(SpendlerRadii.button),
        borderSide: const BorderSide(color: SpendlerColors.accent),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: SpendlerSpacing.md,
        vertical: 14,
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _nextDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) setState(() => _nextDate = picked);
  }

  void _save() {
    final name = _nameController.text.trim();
    final amount = double.tryParse(_amountController.text.trim());
    if (name.isEmpty || amount == null || amount <= 0) return;

    ref.read(repositoryProvider).insertSubscription(
      SubscriptionsCompanion.insert(
        name: name,
        amount: amount,
        billingCycle: _cycle.name,
        nextBillingDate: _nextDate,
        category: _category.name,
      ),
    );
    Navigator.pop(context);
  }
}

// ─── Selector row (cycle / category picker) ───────────

class _SelectorRow extends StatelessWidget {
  const _SelectorRow({
    required this.label,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final List<String> options;
  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: SpendlerColors.textSecondary,
          ),
        ),
        const SizedBox(height: SpendlerSpacing.xs),
        Wrap(
          spacing: SpendlerSpacing.sm,
          runSpacing: SpendlerSpacing.sm,
          children: [
            for (var i = 0; i < options.length; i++)
              GestureDetector(
                onTap: () => onSelected(i),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: i == selected
                        ? SpendlerColors.accent.withValues(alpha: 0.1)
                        : SpendlerColors.scaffold,
                    borderRadius: BorderRadius.circular(SpendlerRadii.pill),
                    border: Border.all(
                      color: i == selected ? SpendlerColors.accent : SpendlerColors.cardBorder,
                    ),
                  ),
                  child: Text(
                    options[i],
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: i == selected ? FontWeight.w600 : FontWeight.w400,
                      color: i == selected ? SpendlerColors.accent : SpendlerColors.textSecondary,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
