import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:finance_buddy_app/core/enums.dart';
import 'package:finance_buddy_app/design_system/design_system.dart';
import 'package:finance_buddy_app/data/db.dart';
import 'package:finance_buddy_app/providers/providers.dart';
import 'package:finance_buddy_app/widgets/common/empty_state.dart';

import 'package:flutter_animate/flutter_animate.dart';
import 'package:finance_buddy_app/utils/currency_utils.dart';
import 'package:finance_buddy_app/widgets/common/spendler_bottom_sheet.dart';

class SubscriptionsPage extends ConsumerWidget {
  const SubscriptionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subsAsync = ref.watch(allSubscriptionsProvider);
    final monthlyTotal = ref.watch(subscriptionMonthlyTotalProvider);
    final sym = currencySymbol(ref.watch(selectedCurrencyProvider).valueOrNull ?? 'inr');

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: AppBar(
        title: const Text(
          'Subscriptions',
          style: TextStyle(
            color: AppColors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppColors.offWhite,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: AppColors.black),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.black,
        onPressed: () => _showAddSheet(context, ref),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: subsAsync.when(
        data: (subs) {
          if (subs.isEmpty) {
            return const EmptyState(
              icon: Icons.autorenew,
              message: 'No subscriptions tracked yet',
              subtitle: 'Tap + to add your first one.',
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.xs,
              AppSpacing.lg,
              100,
            ),
            children: [
              // ── Monthly cost summary ──
              _MonthlySummaryCard(monthlyTotal: monthlyTotal, count: subs.where((s) => s.isActive).length, symbol: sym),
              const SizedBox(height: AppSpacing.xl),

              // ── Subscription cards ──
              for (int i = 0; i < subs.length; i++) ...[
                _SubscriptionCard(
                  subscription: subs[i],
                  symbol: sym,
                  onToggle: () {
                    ref.read(repositoryProvider).toggleSubscriptionActive(subs[i].id, !subs[i].isActive);
                  },
                  onDelete: () => _confirmDelete(context, ref, subs[i]),
                ).animate().fadeIn(delay: AppDurations.stagger * i, duration: AppDurations.medium)
                    .slideX(begin: 0.05, delay: AppDurations.stagger * i, duration: AppDurations.medium),
                const SizedBox(height: AppSpacing.sm),
              ],
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.black),
        ),
        error: (_, _) => const Center(
          child: Text('Something went wrong', style: TextStyle(color: AppColors.gray500)),
        ),
          ),
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
            child: const Text('Delete', style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
  }

  void _showAddSheet(BuildContext context, WidgetRef ref) {
    showSpendlerSheet<void>(
      context: context,
      builder: (_) => const _AddSubscriptionSheet(),
    );
  }
}

// ─── Monthly Summary Card ─────────────────────────────

class _MonthlySummaryCard extends StatelessWidget {
  const _MonthlySummaryCard({required this.monthlyTotal, required this.count, required this.symbol});

  final AsyncValue<double> monthlyTotal;
  final int count;
  final String symbol;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppRadius.lg,
        border: Border.all(color: AppColors.gray200),
      ),
      child: Column(
        children: [
          const Text(
            'MONTHLY COST',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.gray500,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          monthlyTotal.when(
            data: (total) => Text(
              '$symbol${total.toStringAsFixed(0)}',
              style: const TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w700,
                color: AppColors.black,
                fontFeatures: [FontFeature.tabularFigures()],
                letterSpacing: -1.5,
              ),
            ),
            loading: () => const Text(
              '...',
              style: TextStyle(fontSize: 40, color: AppColors.gray500),
            ),
            error: (_, _) => const Text(
              '—',
              style: TextStyle(fontSize: 40, color: AppColors.red),
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            '$count active subscription${count == 1 ? '' : 's'}',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.gray500,
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
    required this.symbol,
  });

  final Subscription subscription;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final String symbol;

  Widget _buildBillingDateRow() {
    if (!subscription.isActive) {
      return const Text(
        'Paused',
        style: TextStyle(
          fontSize: 12,
          color: AppColors.gray500,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final billing = DateTime(
      subscription.nextBillingDate.year,
      subscription.nextBillingDate.month,
      subscription.nextBillingDate.day,
    );
    final daysUntil = billing.difference(today).inDays;

    final dateText = 'Next: ${DateFormat('d MMM yyyy').format(subscription.nextBillingDate)}';

    if (daysUntil > 7 || daysUntil < 0) {
      return Text(
        dateText,
        style: const TextStyle(
          fontSize: 12,
          color: AppColors.gray500,
        ),
      );
    }

    // Billing is within 7 days — show urgency badge
    final badgeColor = daysUntil <= 2 ? AppColors.alertRed : AppColors.alertOrange;
    final String badgeLabel;
    if (daysUntil == 0) {
      badgeLabel = 'Due today';
    } else if (daysUntil == 1) {
      badgeLabel = 'Due tomorrow';
    } else {
      badgeLabel = 'Due in $daysUntil days';
    }

    return Row(
      children: [
        Text(
          dateText,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.gray500,
          ),
        ),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: badgeColor.withValues(alpha: 0.12),
            borderRadius: AppRadius.xxs,
          ),
          child: Text(
            badgeLabel,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: badgeColor,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final cat = TransactionCategory.values.firstWhere(
      (c) => c.name == subscription.category,
      orElse: () => TransactionCategory.other,
    );
    final catColor = subscription.isActive
        ? AppColors.categoryColor(cat)
        : AppColors.gray500;
    final cycle = BillingCycle.values.firstWhere(
      (c) => c.name == subscription.billingCycle,
      orElse: () => BillingCycle.monthly,
    );

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppRadius.lg,
        border: Border.all(
          color: subscription.isActive ? catColor.withValues(alpha: 0.3) : AppColors.gray200,
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
              borderRadius: AppRadius.base,
            ),
            child: Icon(cat.icon, color: catColor, size: 22),
          ),
          const SizedBox(width: AppSpacing.md),

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
                        ? AppColors.black
                        : AppColors.gray500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '$symbol${subscription.amount.toStringAsFixed(0)}${cycle.shortLabel} · ${cat.label}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.gray500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                _buildBillingDateRow(),
              ],
            ),
          ),

          // Actions column
          IconButton(
            onPressed: onToggle,
            icon: Icon(
              subscription.isActive ? PhosphorIcons.pause() : PhosphorIcons.play(),
              color: subscription.isActive ? AppColors.amber : AppColors.green,
              size: 20,
            ),
            tooltip: subscription.isActive ? 'Pause' : 'Resume',
          ),
          IconButton(
            onPressed: onDelete,
            icon: Icon(
              PhosphorIcons.trash(),
              color: AppColors.red.withValues(alpha: 0.7),
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
        AppSpacing.xl,
        AppSpacing.xl,
        AppSpacing.xl,
        MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.sm),

            const Text(
              'Add Subscription',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.black,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Name
            TextField(
              controller: _nameController,
              decoration: _inputDecoration('Name (e.g. Netflix)'),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: AppSpacing.md),

            // Amount
            TextField(
              controller: _amountController,
              decoration: _inputDecoration('Amount (\$)'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: AppSpacing.md),

            // Billing Cycle
            _SelectorRow(
              label: 'Cycle',
              options: BillingCycle.values.map((c) => c.label).toList(),
              selected: _cycle.index,
              onSelected: (i) => setState(() => _cycle = BillingCycle.values[i]),
            ),
            const SizedBox(height: AppSpacing.md),

            // Category
            _SelectorRow(
              label: 'Category',
              options: TransactionCategory.values.map((c) => c.label).toList(),
              selected: _category.index,
              onSelected: (i) => setState(() => _category = TransactionCategory.values[i]),
            ),
            const SizedBox(height: AppSpacing.md),

            // Next billing date
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.gray200),
                  borderRadius: AppRadius.base,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 18, color: AppColors.gray500),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'Next billing: ${DateFormat('d MMM yyyy').format(_nextDate)}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Save button
            SizedBox(
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.black,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.base,
                  ),
                  elevation: 0,
                ),
                onPressed: _save,
                child: const Text('Save', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.gray500),
      filled: true,
      fillColor: AppColors.offWhite,
      border: OutlineInputBorder(
        borderRadius: AppRadius.base,
        borderSide: const BorderSide(color: AppColors.gray200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadius.base,
        borderSide: const BorderSide(color: AppColors.gray200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadius.base,
        borderSide: const BorderSide(color: AppColors.black),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
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
            color: AppColors.gray500,
          ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            for (var i = 0; i < options.length; i++)
              GestureDetector(
                onTap: () => onSelected(i),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: i == selected
                        ? AppColors.black.withValues(alpha: 0.1)
                        : AppColors.offWhite,
                    borderRadius: AppRadius.pill,
                    border: Border.all(
                      color: i == selected ? AppColors.black : AppColors.gray200,
                    ),
                  ),
                  child: Text(
                    options[i],
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: i == selected ? FontWeight.w600 : FontWeight.w400,
                      color: i == selected ? AppColors.black : AppColors.gray500,
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
