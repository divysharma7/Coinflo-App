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

class SubscriptionsPage extends ConsumerStatefulWidget {
  const SubscriptionsPage({super.key});

  @override
  ConsumerState<SubscriptionsPage> createState() => _SubscriptionsPageState();
}

class _SubscriptionsPageState extends ConsumerState<SubscriptionsPage> {
  bool _hasAnimatedInitial = false;

  @override
  Widget build(BuildContext context) {
    final subsAsync = ref.watch(allSubscriptionsProvider);
    final monthlyTotal = ref.watch(subscriptionMonthlyTotalProvider);
    final sym = currencySymbol(ref.watch(selectedCurrencyProvider).valueOrNull ?? 'inr');

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _PushedHeader(
                  onBack: () => Navigator.of(context).maybePop(),
                  onAdd: () => _showAddSheet(context),
                ),
                Expanded(
                  child: subsAsync.when(
                    data: (subs) => _buildList(subs, monthlyTotal, sym),
                    loading: () => const Center(
                      child: CircularProgressIndicator(color: AppColors.black),
                    ),
                    error: (_, _) => const Center(
                      child: Text('Something went wrong',
                          style: TextStyle(color: AppColors.gray500)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildList(
    List<Subscription> subs,
    AsyncValue<double> monthlyTotal,
    String sym,
  ) {
    if (subs.isEmpty) {
      return const EmptyState(
        icon: Icons.autorenew,
        message: 'No subscriptions tracked yet',
        subtitle: 'Tap + to add your first one.',
      );
    }

    final activeSubs = subs.where((s) => s.isActive).toList();
    final nextRenewal = _nextRenewal(activeSubs);

    // Only animate on first data load — skip on toggle/delete/refresh rebuilds.
    final shouldAnimate = !_hasAnimatedInitial;
    if (shouldAnimate) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _hasAnimatedInitial = true);
      });
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xs,
        AppSpacing.lg,
        100,
      ),
      children: [
        // ── Dark hero: monthly total + next renewal ──
        _SubscriptionHero(
          monthlyTotal: monthlyTotal,
          activeCount: activeSubs.length,
          nextRenewal: nextRenewal,
          symbol: sym,
        ),
        const SizedBox(height: AppSpacing.xl),

        // ── Active section ──
        const Padding(
          padding: EdgeInsets.only(bottom: AppSpacing.sm, left: 2),
          child: Text('Active', style: AppTextStyles.section),
        ),

        // ── One white card of subscription rows ──
        Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: AppRadius.xl,
            boxShadow: AppShadows.sm,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.xs,
          ),
          child: Column(
            children: [
              for (int i = 0; i < subs.length; i++) ...[
                if (i > 0) const Divider(height: 1, thickness: 1, color: AppColors.gray100),
                if (shouldAnimate)
                  _SubscriptionRow(
                    key: ValueKey(subs[i].id),
                    subscription: subs[i],
                    symbol: sym,
                    onToggle: () {
                      ref.read(repositoryProvider).toggleSubscriptionActive(
                          subs[i].id, !subs[i].isActive);
                    },
                    onDelete: () => _confirmDelete(subs[i]),
                  ).animate()
                      .fadeIn(delay: AppDurations.stagger * i, duration: AppDurations.medium)
                      .slideX(begin: 0.05, delay: AppDurations.stagger * i, duration: AppDurations.medium)
                else
                  _SubscriptionRow(
                    key: ValueKey(subs[i].id),
                    subscription: subs[i],
                    symbol: sym,
                    onToggle: () {
                      ref.read(repositoryProvider).toggleSubscriptionActive(
                          subs[i].id, !subs[i].isActive);
                    },
                    onDelete: () => _confirmDelete(subs[i]),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// The active subscription with the soonest upcoming billing date.
  static Subscription? _nextRenewal(List<Subscription> activeSubs) {
    if (activeSubs.isEmpty) return null;
    final sorted = [...activeSubs]
      ..sort((a, b) => a.nextBillingDate.compareTo(b.nextBillingDate));
    return sorted.first;
  }

  void _confirmDelete(Subscription sub) {
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

  void _showAddSheet(BuildContext context) {
    showSpendlerSheet<void>(
      context: context,
      builder: (_) => const _AddSubscriptionSheet(),
    );
  }
}

// ─── Pushed header (‹ · title · +) ────────────────────

class _PushedHeader extends StatelessWidget {
  const _PushedHeader({required this.onBack, required this.onAdd});

  final VoidCallback onBack;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xs,
        AppSpacing.lg,
        AppSpacing.xs,
      ),
      child: Row(
        children: [
          _IconButton(icon: PhosphorIcons.caretLeft(), onTap: onBack),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Subscriptions',
              style: AppTextStyles.displayL.copyWith(
                fontSize: 20,
                letterSpacing: -0.6,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          _IconButton(icon: PhosphorIcons.plus(), onTap: onAdd),
        ],
      ),
    );
  }
}

/// White circular icon button used in the pushed header.
class _IconButton extends StatelessWidget {
  const _IconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      shape: const CircleBorder(),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: AppShadows.sm,
          ),
          child: Icon(icon, size: 19, color: AppColors.black),
        ),
      ),
    );
  }
}

// ─── Dark hero: monthly total + next renewal ──────────

class _SubscriptionHero extends StatelessWidget {
  const _SubscriptionHero({
    required this.monthlyTotal,
    required this.activeCount,
    required this.nextRenewal,
    required this.symbol,
  });

  final AsyncValue<double> monthlyTotal;
  final int activeCount;
  final Subscription? nextRenewal;
  final String symbol;

  @override
  Widget build(BuildContext context) {
    final next = nextRenewal;
    return DarkHeroCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left — monthly total
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Monthly total',
                  style: AppTextStyles.labelM.copyWith(
                    color: AppColors.white.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 6),
                monthlyTotal.when(
                  data: (total) => Text(
                    '$symbol${total.toStringAsFixed(0)}',
                    style: AppTextStyles.displayXL.copyWith(
                      fontSize: 34,
                      color: AppColors.white,
                      letterSpacing: -1.6,
                    ),
                  ),
                  loading: () => Text(
                    '…',
                    style: AppTextStyles.displayXL.copyWith(
                      fontSize: 34,
                      color: AppColors.white.withValues(alpha: 0.6),
                    ),
                  ),
                  error: (_, _) => Text(
                    '—',
                    style: AppTextStyles.displayXL.copyWith(
                      fontSize: 34,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),

          // Right — next renewal
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Next renewal',
                style: AppTextStyles.labelS.copyWith(
                  color: AppColors.white.withValues(alpha: 0.55),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                next == null
                    ? '—'
                    : '${next.name} · ${DateFormat('d MMM').format(next.nextBillingDate)}',
                textAlign: TextAlign.right,
                style: AppTextStyles.bodyM.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: AppSpacing.xxs),
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.14),
                  borderRadius: AppRadius.full,
                ),
                child: Text(
                  '$activeCount active',
                  style: AppTextStyles.labelS.copyWith(color: AppColors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Subscription row (mono-tile + name + ₹amount/mo) ─

class _SubscriptionRow extends StatelessWidget {
  const _SubscriptionRow({
    super.key,
    required this.subscription,
    required this.onToggle,
    required this.onDelete,
    required this.symbol,
  });

  final Subscription subscription;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final String symbol;

  @override
  Widget build(BuildContext context) {
    final cat = TransactionCategory.values.firstWhere(
      (c) => c.name == subscription.category,
      orElse: () => TransactionCategory.other,
    );
    final isActive = subscription.isActive;
    final tileBg = isActive ? AppColors.categoryBg(cat) : AppColors.gray100;
    final tileFg = isActive ? AppColors.categoryFg(cat) : AppColors.gray500;
    final cycle = BillingCycle.values.firstWhere(
      (c) => c.name == subscription.billingCycle,
      orElse: () => BillingCycle.monthly,
    );
    final monogram = subscription.name.isEmpty
        ? '?'
        : subscription.name.characters.first.toUpperCase();
    final meta = isActive
        ? '${cycle.label} · renews ${DateFormat('d MMM').format(subscription.nextBillingDate)}'
        : 'Paused';

    return InkWell(
      onTap: onToggle,
      onLongPress: onDelete,
      borderRadius: AppRadius.md,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            // mono-tile monogram (46px, rounded-14)
            Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: tileBg,
                borderRadius: AppRadius.md,
              ),
              child: Text(
                monogram,
                style: AppTextStyles.headingS.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: tileFg,
                ),
              ),
            ),
            const SizedBox(width: 13),

            // name + meta
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subscription.name,
                    style: AppTextStyles.bodyM.copyWith(
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                      color: isActive ? AppColors.black : AppColors.gray500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    meta,
                    style: AppTextStyles.labelM.copyWith(color: AppColors.gray500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),

            // ₹amount + tiny /cycle
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$symbol${subscription.amount.toStringAsFixed(0)}',
                  style: AppTextStyles.numericM.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isActive ? AppColors.black : AppColors.gray500,
                  ),
                ),
                Text(
                  cycle.shortLabel,
                  style: AppTextStyles.labelS.copyWith(color: AppColors.gray400),
                ),
              ],
            ),
          ],
        ),
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
                      style: AppTextStyles.bodyS.copyWith(
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
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.base,
                  ),
                  elevation: 0,
                ),
                onPressed: _save,
                child: Text('Save', style: AppTextStyles.bodyM.copyWith(fontWeight: FontWeight.w600)),
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
          style: AppTextStyles.labelM.copyWith(
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
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
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
                    style: AppTextStyles.bodyS.copyWith(
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
