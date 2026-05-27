import 'package:finance_buddy_app/widgets/common/error_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:finance_buddy_app/design_system/design_system.dart';
import 'package:finance_buddy_app/data/db.dart';
import 'package:drift/drift.dart' as drift;
import 'package:finance_buddy_app/providers/providers.dart';
import 'package:finance_buddy_app/pages/people/friend_creation_sheet.dart';
import 'package:finance_buddy_app/pages/people/add_split_sheet.dart';
import 'package:finance_buddy_app/pages/family/family_entry_sheet.dart';
import 'package:finance_buddy_app/widgets/common/animated_amount.dart';
import 'package:finance_buddy_app/widgets/common/spendler_bottom_sheet.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:finance_buddy_app/utils/currency_utils.dart';

class PeoplePage extends ConsumerWidget {
  const PeoplePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.offWhite,
        body: Column(
          children: [
            SizedBox(height: MediaQuery.paddingOf(context).top + AppSpacing.md),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                children: [
                  Text('People',
                      style: AppTextStyles.headingL
                          .copyWith(color: AppColors.black)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => _showAddOptions(context),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: AppColors.gray100,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add,
                          color: AppColors.black, size: 20),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Tab bar
            TabBar(
              indicatorColor: AppColors.black,
              labelColor: AppColors.black,
              unselectedLabelColor: AppColors.gray500,
              dividerColor: AppColors.gray200,
              labelStyle: AppTextStyles.bodyM
                  .copyWith(fontWeight: FontWeight.w600),
              unselectedLabelStyle: AppTextStyles.bodyM,
              tabs: const [
                Tab(text: 'Friends'),
                Tab(text: 'Family'),
              ],
            ),

            const Expanded(
              child: TabBarView(
                children: [
                  _FriendsTab(),
                  _FamilyTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddOptions(BuildContext context) {
    showSpendlerSheet<void>(
      context: context,
      isScrollControlled: false,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _AddOptionTile(
                icon: PhosphorIcons.userPlus(),
                label: 'Add a friend',
                subtitle: 'Create a new contact for splits',
                color: AppColors.black,
                onTap: () {
                  Navigator.pop(context);
                  showSpendlerSheet<void>(
                    context: context,
                    builder: (_) => const FriendCreationSheet(),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              _AddOptionTile(
                icon: PhosphorIcons.splitVertical(),
                label: 'Add a split',
                subtitle: 'Record money owed or owing',
                color: AppColors.green,
                onTap: () {
                  Navigator.pop(context);
                  showSpendlerSheet<void>(
                    context: context,
                    builder: (_) => const AddSplitSheet(),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              _AddOptionTile(
                icon: PhosphorIcons.arrowsDownUp(),
                label: 'Family entry',
                subtitle: 'Inflow or outflow',
                color: AppColors.orange,
                onTap: () {
                  Navigator.pop(context);
                  showSpendlerSheet<void>(
                    context: context,
                    builder: (_) => const FamilyEntrySheet(),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddOptionTile extends StatelessWidget {
  const _AddOptionTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: AppRadius.mdLg,
          border: Border.all(color: AppColors.gray200),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: AppRadius.base,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: AppTextStyles.bodyM.copyWith(
                          color: AppColors.black,
                          fontWeight: FontWeight.w600)),
                  Text(subtitle,
                      style: AppTextStyles.bodyS
                          .copyWith(color: AppColors.gray500)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                color: AppColors.gray500, size: 20),
          ],
        ),
      ),
    );
  }
}

// ─── Friends Tab ────────────────────────────────────────

class _FriendsTab extends ConsumerWidget {
  const _FriendsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sym = currencySymbol(ref.watch(selectedCurrencyProvider).valueOrNull ?? 'inr');
    final balanceAsync = ref.watch(totalFriendBalanceProvider);
    final contactsAsync = ref.watch(friendContactsProvider);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        // Summary banner
        balanceAsync.when(
          data: (bal) {
            if (bal.totalReceivable == 0 && bal.totalPayable == 0) {
              return const SizedBox.shrink();
            }
            return Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: AppRadius.mdLg,
                boxShadow: AppShadows.sm,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('TO COLLECT',
                            style: AppTextStyles.labelM
                                .copyWith(color: AppColors.gray500)),
                        const SizedBox(height: 4),
                        AnimatedAmount(
                          value: bal.totalReceivable,
                          prefix: sym,
                          style: AppTextStyles.headingM
                              .copyWith(color: AppColors.green),
                        ),
                      ],
                    ),
                  ),
                  Container(
                      width: 1, height: 40, color: AppColors.gray200),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('TO PAY',
                              style: AppTextStyles.labelM
                                  .copyWith(color: AppColors.gray500)),
                          const SizedBox(height: 4),
                          AnimatedAmount(
                            value: bal.totalPayable,
                            prefix: sym,
                            style: AppTextStyles.headingM
                                .copyWith(color: AppColors.orange),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, _) => const ErrorCard(),
        ),

        // Friend cards
        contactsAsync.when(
          data: (contacts) {
            if (contacts.isEmpty) {
              return Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: AppSpacing.xxxl),
                child: Center(
                  child: Column(
                    children: [
                      PhosphorIcon(PhosphorIcons.usersThree(),
                          size: 48, color: AppColors.gray300),
                      const SizedBox(height: AppSpacing.md),
                      Text('Add someone to start\nsplitting expenses.',
                          style: AppTextStyles.bodyM
                              .copyWith(color: AppColors.gray500),
                          textAlign: TextAlign.center),
                    ],
                  ),
                ),
              );
            }
            return Column(
              children: contacts
                  .asMap().entries
                  .map((entry) => Padding(
                        padding:
                            const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: _FriendCard(contact: entry.value),
                      ).animate().fadeIn(delay: AppDurations.stagger * entry.key, duration: AppDurations.medium)
                          .slideX(begin: 0.05, delay: AppDurations.stagger * entry.key, duration: AppDurations.medium))
                  .toList(),
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.all(AppSpacing.xl),
            child: Center(
                child: CircularProgressIndicator(
                    color: AppColors.black, strokeWidth: 2)),
          ),
          error: (_, _) => const ErrorCard(),
        ),
      ],
    );
  }
}

// ─── Friend Card ────────────────────────────────────────

class _FriendCard extends ConsumerWidget {
  const _FriendCard({required this.contact});
  final FriendContact contact;

  Color _avatarColor(String hex) {
    try {
      return Color(
          int.parse('FF${hex.replaceFirst('#', '')}', radix: 16));
    } on FormatException {
      return AppColors.gray500;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sym = currencySymbol(ref.watch(selectedCurrencyProvider).valueOrNull ?? 'inr');
    final splitsAsync =
        ref.watch(friendPendingSplitsProvider(contact.id));
    final c = _avatarColor(contact.avatarColour);

    return GestureDetector(
      onLongPress: () => _showFriendActions(context, ref),
      child: Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppRadius.mdLg,
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                      color: c.withValues(alpha: 0.15),
                      shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: Text(
                    contact.name.isNotEmpty
                        ? contact.name[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                        color: c,
                        fontSize: 20,
                        fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(contact.name,
                          style: AppTextStyles.bodyM.copyWith(
                              color: AppColors.black,
                              fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      if (contact.note != null &&
                          contact.note!.isNotEmpty)
                        Text(contact.note!,
                            style: AppTextStyles.bodyS
                                .copyWith(color: AppColors.gray500)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Balance
          splitsAsync.when(
            data: (splits) {
              final theyOwe = splits
                  .where((s) => s.direction == 'they_owe_me')
                  .fold(0.0, (sum, s) => sum + (s.amount - s.amountCleared));
              final iOwe = splits
                  .where((s) => s.direction == 'i_owe_them')
                  .fold(0.0, (sum, s) => sum + (s.amount - s.amountCleared));

              if (theyOwe == 0 && iOwe == 0) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.green.withValues(alpha: 0.06),
                    borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(16)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle_outline,
                          color: AppColors.green, size: 16),
                      const SizedBox(width: 6),
                      Text('All settled',
                          style: AppTextStyles.bodyS.copyWith(
                              color: AppColors.green,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                );
              }

              return Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
                child: Column(
                  children: [
                    if (iOwe > 0)
                      _BalanceBar(
                          label: 'You owe',
                          amount: iOwe,
                          color: AppColors.orange,
                          symbol: sym),
                    if (iOwe > 0 && theyOwe > 0)
                      const SizedBox(height: 8),
                    if (theyOwe > 0)
                      _BalanceBar(
                          label: 'Owes you',
                          amount: theyOwe,
                          color: AppColors.green,
                          symbol: sym),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        if (iOwe > 0)
                          Expanded(
                            child: _ActionBtn(
                              label: 'I Paid',
                              color: AppColors.orange,
                              onTap: () => _markSettled(context, ref,
                                  contact.id, 'i_owe_them', splits),
                            ),
                          ),
                        if (iOwe > 0 && theyOwe > 0)
                          const SizedBox(width: 8),
                        if (theyOwe > 0)
                          Expanded(
                            child: _ActionBtn(
                              label: 'They Paid',
                              color: AppColors.green,
                              onTap: () => _markSettled(context, ref,
                                  contact.id, 'they_owe_me', splits),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: Center(
                  child: CircularProgressIndicator(
                      color: AppColors.black, strokeWidth: 2)),
            ),
            error: (_, _) => const ErrorCard(),
          ),
        ],
      ),
      ),
    );
  }

  void _showFriendActions(BuildContext context, WidgetRef ref) {
    HapticFeedback.mediumImpact();
    showSpendlerSheet<void>(
      context: context,
      isScrollControlled: false,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                contact.name,
                style: AppTextStyles.headingS.copyWith(color: AppColors.black),
              ),
              const SizedBox(height: AppSpacing.lg),
              _FriendActionTile(
                icon: PhosphorIcons.pencilSimple(),
                label: 'Edit',
                color: AppColors.black,
                onTap: () {
                  Navigator.pop(context);
                  showSpendlerSheet<void>(
                    context: context,
                    builder: (_) => _EditFriendSheet(contact: contact),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              _FriendActionTile(
                icon: PhosphorIcons.trash(),
                label: 'Delete',
                color: AppColors.red,
                onTap: () {
                  Navigator.pop(context);
                  _confirmDelete(context, ref);
                },
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove friend?'),
        content: Text(
          'Remove ${contact.name}? This won\'t delete their splits.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final db = ref.read(databaseProvider);
              (db.delete(db.friendContacts)
                    ..where((c) => c.id.equals(contact.id)))
                  .go();
              Navigator.pop(context);
            },
            child: const Text('Remove',
                style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
  }

  void _markSettled(BuildContext context, WidgetRef ref, int friendId,
      String direction, List<FriendSplit> splits) {
    final pending =
        splits.where((s) => s.direction == direction).toList();
    if (pending.isEmpty) return;

    if (pending.length == 1) {
      HapticFeedback.mediumImpact();
      settleSplit(ref.read(repositoryProvider), pending.first.id);
      return;
    }

    showSpendlerSheet<void>(
      context: context,
      isScrollControlled: false,
      builder: (_) => _SettlementPicker(
        splits: pending,
        friendName: contact.name,
        direction: direction,
      ),
    );
  }
}

// ─── Settlement Picker ──────────────────────────────────

class _SettlementPicker extends ConsumerStatefulWidget {
  const _SettlementPicker({
    required this.splits,
    required this.friendName,
    required this.direction,
  });

  final List<FriendSplit> splits;
  final String friendName;
  final String direction;

  @override
  ConsumerState<_SettlementPicker> createState() =>
      _SettlementPickerState();
}

class _SettlementPickerState extends ConsumerState<_SettlementPicker> {
  final Set<int> _selected = {};

  @override
  Widget build(BuildContext context) {
    final sym = currencySymbol(ref.watch(selectedCurrencyProvider).valueOrNull ?? 'inr');
    final title = widget.direction == 'they_owe_me'
        ? '${widget.friendName} paid which ones?'
        : 'You paid which ones?';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title,
                style: AppTextStyles.headingS
                    .copyWith(color: AppColors.black)),
            const SizedBox(height: AppSpacing.md),
            ...widget.splits.map((s) {
              final selected = _selected.contains(s.id);
              return GestureDetector(
                onTap: () => setState(() {
                  if (selected) {
                    _selected.remove(s.id);
                  } else {
                    _selected.add(s.id);
                  }
                }),
                child: Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.xs),
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.black.withValues(alpha: 0.05)
                        : AppColors.white,
                    borderRadius: AppRadius.base,
                    border: Border.all(
                      color: selected
                          ? AppColors.black
                          : AppColors.gray200,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        selected
                            ? Icons.check_circle
                            : Icons.circle_outlined,
                        color: selected
                            ? AppColors.black
                            : AppColors.gray300,
                        size: 20,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          '$sym${s.amount.toStringAsFixed(0)}',
                          style: AppTextStyles.bodyM.copyWith(
                              color: AppColors.black,
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                      Text(
                        DateFormat('d MMM').format(s.createdAt),
                        style: AppTextStyles.bodyS
                            .copyWith(color: AppColors.gray500),
                      ),
                    ],
                  ),
                ),
              );
            }),
            GestureDetector(
              onTap: () => setState(() {
                if (_selected.length == widget.splits.length) {
                  _selected.clear();
                } else {
                  _selected
                      .addAll(widget.splits.map((s) => s.id));
                }
              }),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.sm),
                child: Text(
                  _selected.length == widget.splits.length
                      ? 'Deselect all'
                      : 'Select all',
                  style: AppTextStyles.bodyS.copyWith(
                      color: AppColors.black,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: 'Mark Settled (${_selected.length})',
              onTap: _selected.isEmpty
                  ? () {}
                  : () async {
                      await HapticFeedback.mediumImpact();
                      await settleSplits(
                          ref.read(repositoryProvider), _selected);
                      if (context.mounted) Navigator.pop(context);
                    },
              disabled: _selected.isEmpty,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Family Tab ─────────────────────────────────────────

class _FamilyTab extends ConsumerWidget {
  const _FamilyTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wealth = ref.watch(totalFamilyWealthProvider);
    final inflows = ref.watch(familyInflowsProvider);
    final outflows = ref.watch(familyOutflowsProvider);
    final sym = currencySymbol(ref.watch(selectedCurrencyProvider).valueOrNull ?? 'inr');

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        // Total card
        wealth.when(
          data: (total) => Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.lg),
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: AppRadius.mdLg,
              boxShadow: AppShadows.sm,
            ),
            child: Column(
              children: [
                Text('NET FAMILY FLOW',
                    style: AppTextStyles.labelM
                        .copyWith(color: AppColors.gray500)),
                const SizedBox(height: AppSpacing.sm),
                AnimatedAmount(
                  value: total,
                  prefix: sym,
                  style: AppTextStyles.headingL
                      .copyWith(color: AppColors.orange),
                ),
              ],
            ),
          ),
          loading: () => const SizedBox.shrink(),
          error: (_, _) => const ErrorCard(),
        ),

        // Inflows
        _FamilyList(
          label: 'INFLOWS',
          data: inflows,
          icon: PhosphorIconsFill.arrowCircleDown,
          color: AppColors.green,
          titleBuilder: (e) =>
              '$sym${e.amount.toStringAsFixed(0)} from ${e.fromPerson}',
          emptyText: 'No inflows yet.',
        ),
        const SizedBox(height: AppSpacing.lg),

        // Outflows
        _FamilyList(
          label: 'OUTFLOWS',
          data: outflows,
          icon: PhosphorIconsFill.arrowCircleUp,
          color: AppColors.red,
          titleBuilder: (e) =>
              '$sym${e.amount.toStringAsFixed(0)} to ${e.fromPerson}',
          emptyText: 'No outflows yet.',
        ),
      ],
    );
  }
}

class _FamilyList extends StatelessWidget {
  const _FamilyList({
    required this.label,
    required this.data,
    required this.icon,
    required this.color,
    required this.titleBuilder,
    required this.emptyText,
  });

  final String label;
  final AsyncValue<List<FamilyEntry>> data;
  final IconData icon;
  final Color color;
  final String Function(FamilyEntry) titleBuilder;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style:
                AppTextStyles.labelM.copyWith(color: AppColors.gray500)),
        const SizedBox(height: AppSpacing.sm),
        data.when(
          data: (list) {
            if (list.isEmpty) {
              return Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Text(emptyText,
                    style: AppTextStyles.bodyS
                        .copyWith(color: AppColors.gray500)),
              );
            }
            return Column(
              children: list.map((e) {
                final sub =
                    '${DateFormat('d MMM yyyy').format(e.happenedAt)}'
                    '${e.note != null && e.note!.isNotEmpty ? " · ${e.note}" : ""}';
                return Padding(
                  padding:
                      const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: AppRadius.base,
                        ),
                        child: Icon(icon, color: color, size: 18),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(titleBuilder(e),
                                style: AppTextStyles.bodyM.copyWith(
                                    color: AppColors.black,
                                    fontWeight: FontWeight.w500),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 2),
                            Text(sub,
                                style: AppTextStyles.bodyS.copyWith(
                                    color: AppColors.gray500)),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, _) => const ErrorCard(),
        ),
      ],
    );
  }
}

// ─── Shared widgets ─────────────────────────────────────

class _BalanceBar extends StatelessWidget {
  const _BalanceBar(
      {required this.label, required this.amount, required this.color, required this.symbol});
  final String label;
  final double amount;
  final Color color;
  final String symbol;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: AppRadius.sm,
      ),
      child: Row(
        children: [
          Text(label,
              style: AppTextStyles.bodyS
                  .copyWith(color: color, fontWeight: FontWeight.w500)),
          const Spacer(),
          Text('$symbol${amount.toStringAsFixed(0)}',
              style: AppTextStyles.numericL.copyWith(color: color)),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn(
      {required this.label, required this.color, required this.onTap});
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          borderRadius: AppRadius.sm,
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        alignment: Alignment.center,
        child: Text(label,
            style: AppTextStyles.bodyS.copyWith(
                color: color, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

// ─── Friend Action Tile ────────────────────────────────

class _FriendActionTile extends StatelessWidget {
  const _FriendActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: AppRadius.mdLg,
          border: Border.all(color: AppColors.gray200),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: AppRadius.base,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(label,
                  style: AppTextStyles.bodyM.copyWith(
                      color: color, fontWeight: FontWeight.w600)),
            ),
            Icon(Icons.chevron_right, color: color.withValues(alpha: 0.5), size: 20),
          ],
        ),
      ),
    );
  }
}

// ─── Edit Friend Sheet ─────────────────────────────────

class _EditFriendSheet extends ConsumerStatefulWidget {
  const _EditFriendSheet({required this.contact});
  final FriendContact contact;

  @override
  ConsumerState<_EditFriendSheet> createState() => _EditFriendSheetState();
}

class _EditFriendSheetState extends ConsumerState<_EditFriendSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.contact.name);
    _noteController = TextEditingController(text: widget.contact.note ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Edit Friend',
              style: AppTextStyles.headingS.copyWith(color: AppColors.black)),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            maxLength: 30,
            style: AppTextStyles.bodyM.copyWith(color: AppColors.black),
            decoration: InputDecoration(
              labelText: 'Name',
              labelStyle:
                  AppTextStyles.bodyS.copyWith(color: AppColors.gray500),
              filled: true,
              fillColor: AppColors.gray100,
              border: OutlineInputBorder(
                borderRadius: AppRadius.base,
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _noteController,
            style: AppTextStyles.bodyM.copyWith(color: AppColors.black),
            decoration: InputDecoration(
              labelText: 'Note (optional)',
              hintText: 'roommate, college friend, etc',
              labelStyle:
                  AppTextStyles.bodyS.copyWith(color: AppColors.gray500),
              hintStyle:
                  AppTextStyles.bodyS.copyWith(color: AppColors.gray300),
              filled: true,
              fillColor: AppColors.gray100,
              border: OutlineInputBorder(
                borderRadius: AppRadius.base,
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: 'Save Changes',
            onTap: _nameController.text.trim().isEmpty ? () {} : _save,
            disabled: _nameController.text.trim().isEmpty,
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    await HapticFeedback.mediumImpact();
    final db = ref.read(databaseProvider);
    final note = _noteController.text.trim();

    await (db.update(db.friendContacts)
          ..where((c) => c.id.equals(widget.contact.id)))
        .write(FriendContactsCompanion(
      name: drift.Value(name),
      note: drift.Value(note.isEmpty ? null : note),
    ));

    if (mounted) Navigator.pop(context);
  }
}
