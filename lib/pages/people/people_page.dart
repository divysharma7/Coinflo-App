import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:finance_buddy_app/core/tokens.dart';
import 'package:finance_buddy_app/data/db.dart';
import 'package:finance_buddy_app/providers/providers.dart';
import 'package:finance_buddy_app/widgets/common/animated_amount.dart';
import 'package:finance_buddy_app/widgets/common/neo_pop_button.dart';
import 'package:finance_buddy_app/pages/people/friend_creation_sheet.dart';
import 'package:finance_buddy_app/pages/people/add_split_sheet.dart';
import 'package:finance_buddy_app/pages/family/family_entry_sheet.dart';
import 'package:finance_buddy_app/widgets/common/paisa_bottom_sheet.dart';

class PeoplePage extends ConsumerWidget {
  const PeoplePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          SizedBox(height: MediaQuery.paddingOf(context).top + 16),
          // Header row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: PaisaSpacing.screenH),
            child: Row(
              children: [
                const Text('PEOPLE', style: PaisaTextStyles.sectionLabel),
                const Spacer(),
                // + button
                GestureDetector(
                  onTap: () => _showAddOptions(context),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: PaisaColors.yellow.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: PhosphorIcon(
                      PhosphorIcons.plus(),
                      color: PaisaColors.yellow,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: PaisaSpacing.md),

          // Tab bar
          const TabBar(
            indicatorColor: PaisaColors.yellow,
            labelColor: PaisaColors.yellow,
            unselectedLabelColor: PaisaColors.textTertiary,
            dividerColor: PaisaColors.border,
            tabs: [
              Tab(text: 'Friends'),
              Tab(text: 'Family'),
            ],
          ),

          // Tab content
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
    );
  }

  void _showAddOptions(BuildContext context) {
    showPaisaSheet<void>(
      context: context,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('ADD', style: PaisaTextStyles.sectionLabel),
          const SizedBox(height: PaisaSpacing.lg),
          _AddOptionTile(
            icon: PhosphorIcons.userPlus(),
            label: 'Add a friend',
            subtitle: 'Create a new contact for splits',
            color: PaisaColors.yellow,
            onTap: () {
              Navigator.pop(context);
              showPaisaSheet<void>(
                context: context,
                builder: (_) => const FriendCreationSheet(),
              );
            },
          ),
          const SizedBox(height: PaisaSpacing.sm),
          _AddOptionTile(
            icon: PhosphorIcons.splitVertical(),
            label: 'Add a split',
            subtitle: 'Record money owed or owing',
            color: PaisaColors.income,
            onTap: () {
              Navigator.pop(context);
              showPaisaSheet<void>(
                context: context,
                builder: (_) => const AddSplitSheet(),
              );
            },
          ),
          const SizedBox(height: PaisaSpacing.sm),
          _AddOptionTile(
            icon: PhosphorIcons.arrowsDownUp(),
            label: 'Family entry',
            subtitle: 'Inflow or outflow',
            color: PaisaColors.gold,
            onTap: () {
              Navigator.pop(context);
              showPaisaSheet<void>(
                context: context,
                builder: (_) => const FamilyEntrySheet(),
              );
            },
          ),
          const SizedBox(height: PaisaSpacing.md),
        ],
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
        padding: const EdgeInsets.all(PaisaSpacing.cardPadding),
        decoration: BoxDecoration(
          color: PaisaColors.surface,
          borderRadius: BorderRadius.circular(PaisaRadii.button),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: PhosphorIcon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(color: PaisaColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w500)),
                  Text(subtitle, style: const TextStyle(color: PaisaColors.textTertiary, fontSize: 12)),
                ],
              ),
            ),
            PhosphorIcon(PhosphorIcons.caretRight(), color: PaisaColors.textTertiary, size: 16),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
// Friends Tab
// ─────────────────────────────────────────────────────

class _FriendsTab extends ConsumerWidget {
  const _FriendsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balanceAsync = ref.watch(totalFriendBalanceProvider);
    final contactsAsync = ref.watch(friendContactsProvider);

    return ListView(
      padding: const EdgeInsets.all(PaisaSpacing.screenH),
      children: [
        // Summary banner
        balanceAsync.when(
          data: (bal) {
            if (bal.totalReceivable == 0 && bal.totalPayable == 0) {
              return const SizedBox.shrink();
            }
            return Container(
              margin: const EdgeInsets.only(bottom: PaisaSpacing.md),
              padding: const EdgeInsets.all(PaisaSpacing.cardPadding),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF1E1E1E), PaisaColors.surface],
                ),
                borderRadius: BorderRadius.circular(PaisaRadii.card),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('TO COLLECT', style: PaisaTextStyles.sectionLabel),
                        const SizedBox(height: 4),
                        AnimatedAmount(
                          value: bal.totalReceivable,
                          prefix: '₹',
                          style: const TextStyle(color: PaisaColors.income, fontSize: 22, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 40, color: PaisaColors.border),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: PaisaSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('TO PAY', style: PaisaTextStyles.sectionLabel),
                          const SizedBox(height: 4),
                          AnimatedAmount(
                            value: bal.totalPayable,
                            prefix: '₹',
                            style: const TextStyle(color: PaisaColors.amber, fontSize: 22, fontWeight: FontWeight.w700),
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
          error: (_, _) => const SizedBox.shrink(),
        ),

        // Friend cards
        contactsAsync.when(
          data: (contacts) {
            if (contacts.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: PaisaSpacing.xxl),
                child: Center(
                  child: Column(
                    children: [
                      PhosphorIcon(PhosphorIcons.usersThree(), size: 48, color: PaisaColors.textTertiary),
                      const SizedBox(height: PaisaSpacing.md),
                      const Text('Add a friend to start\ntracking splits.', style: PaisaTextStyles.emptyState, textAlign: TextAlign.center),
                    ],
                  ),
                ),
              );
            }
            return Column(
              children: contacts
                  .map((c) => Padding(
                        padding: const EdgeInsets.only(bottom: PaisaSpacing.cardGap),
                        child: _FriendCard(contact: c),
                      ))
                  .toList(),
            );
          },
          loading: () => const Center(child: Padding(padding: EdgeInsets.all(PaisaSpacing.xl), child: CircularProgressIndicator(color: PaisaColors.yellow, strokeWidth: 2))),
          error: (_, _) => const SizedBox.shrink(),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────
// Friend Card
// ─────────────────────────────────────────────────────

class _FriendCard extends ConsumerWidget {
  const _FriendCard({required this.contact});
  final FriendContact contact;

  Color _color(String hex) {
    try {
      return Color(int.parse('FF${hex.replaceFirst('#', '')}', radix: 16));
    } on FormatException {
      return PaisaColors.textTertiary;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final splitsAsync = ref.watch(friendPendingSplitsProvider(contact.id));
    final c = _color(contact.avatarColour);

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1E1E1E), PaisaColors.surface],
        ),
        borderRadius: BorderRadius.circular(PaisaRadii.card),
        boxShadow: PaisaShadows.card,
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(color: c.withValues(alpha: 0.2), shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: Text(
                    contact.name.isNotEmpty ? contact.name[0].toUpperCase() : '?',
                    style: TextStyle(color: c, fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(contact.name, style: const TextStyle(color: PaisaColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
                      if (contact.note != null && contact.note!.isNotEmpty)
                        Text(contact.note!, style: const TextStyle(color: PaisaColors.textTertiary, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Balance
          splitsAsync.when(
            data: (splits) {
              final theyOwe = splits.where((s) => s.direction == 'they_owe_me').fold(0.0, (sum, s) => sum + s.amount);
              final iOwe = splits.where((s) => s.direction == 'i_owe_them').fold(0.0, (sum, s) => sum + s.amount);

              if (theyOwe == 0 && iOwe == 0) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: PaisaColors.income.withValues(alpha: 0.06),
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(PaisaRadii.card)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      PhosphorIcon(PhosphorIcons.checkCircle(), color: PaisaColors.income, size: 16),
                      const SizedBox(width: 6),
                      const Text('All settled', style: TextStyle(color: PaisaColors.income, fontSize: 13, fontWeight: FontWeight.w500)),
                    ],
                  ),
                );
              }

              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  children: [
                    if (iOwe > 0)
                      _BalanceBar(label: 'You owe', amount: iOwe, color: PaisaColors.amber, icon: PhosphorIcons.arrowUpRight()),
                    if (iOwe > 0 && theyOwe > 0)
                      const SizedBox(height: 8),
                    if (theyOwe > 0)
                      _BalanceBar(label: 'Owes you', amount: theyOwe, color: PaisaColors.income, icon: PhosphorIcons.arrowDownLeft()),
                    const SizedBox(height: 12),
                    // Settlement buttons
                    Row(
                      children: [
                        if (iOwe > 0)
                          Expanded(
                            child: _ActionBtn(
                              label: 'I Paid',
                              color: PaisaColors.amber,
                              onTap: () => _markSettled(context, ref, contact.id, 'i_owe_them', splits),
                            ),
                          ),
                        if (iOwe > 0 && theyOwe > 0)
                          const SizedBox(width: 8),
                        if (theyOwe > 0)
                          Expanded(
                            child: _ActionBtn(
                              label: 'They Paid',
                              color: PaisaColors.income,
                              onTap: () => _markSettled(context, ref, contact.id, 'they_owe_me', splits),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              );
            },
            loading: () => const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator(color: PaisaColors.yellow, strokeWidth: 2))),
            error: (_, _) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  void _markSettled(BuildContext context, WidgetRef ref, int friendId, String direction, List<FriendSplit> splits) {
    final pending = splits.where((s) => s.direction == direction).toList();
    if (pending.isEmpty) return;

    if (pending.length == 1) {
      // Single item — settle directly
      HapticFeedback.mediumImpact();
      ref.read(repositoryProvider).markSettled(pending.first.id, 'manual');
      return;
    }

    // Multiple items — show picker
    showPaisaSheet<void>(
      context: context,
      builder: (_) => _SettlementPicker(
        splits: pending,
        friendName: contact.name,
        direction: direction,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
// Settlement Picker (multi-item)
// ─────────────────────────────────────────────────────

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
  ConsumerState<_SettlementPicker> createState() => _SettlementPickerState();
}

class _SettlementPickerState extends ConsumerState<_SettlementPicker> {
  final Set<int> _selected = {};

  @override
  Widget build(BuildContext context) {
    final title = widget.direction == 'they_owe_me'
        ? '${widget.friendName} paid which ones?'
        : 'You paid which ones?';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title.toUpperCase(), style: PaisaTextStyles.sectionLabel),
        const SizedBox(height: PaisaSpacing.md),
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
              margin: const EdgeInsets.only(bottom: PaisaSpacing.sm),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: selected ? PaisaColors.yellow.withValues(alpha: 0.08) : PaisaColors.surface,
                borderRadius: BorderRadius.circular(PaisaRadii.button),
                border: Border.all(
                  color: selected ? PaisaColors.yellow : PaisaColors.border,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    selected ? Icons.check_circle : Icons.circle_outlined,
                    color: selected ? PaisaColors.yellow : PaisaColors.textTertiary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '₹${s.amount.toStringAsFixed(0)}',
                      style: const TextStyle(color: PaisaColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w500),
                    ),
                  ),
                  Text(
                    DateFormat('d MMM').format(s.createdAt),
                    style: const TextStyle(color: PaisaColors.textTertiary, fontSize: 12),
                  ),
                ],
              ),
            ),
          );
        }),
        // Mark all
        GestureDetector(
          onTap: () => setState(() {
            if (_selected.length == widget.splits.length) {
              _selected.clear();
            } else {
              _selected.addAll(widget.splits.map((s) => s.id));
            }
          }),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: PaisaSpacing.sm),
            child: Text(
              _selected.length == widget.splits.length ? 'Deselect all' : 'Select all',
              style: const TextStyle(color: PaisaColors.yellow, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ),
        const SizedBox(height: PaisaSpacing.md),
        NeoPOPButton(
          label: 'Mark Settled (${_selected.length})',
          onTap: _selected.isEmpty
              ? null
              : () async {
                  await HapticFeedback.mediumImpact();
                  final repo = ref.read(repositoryProvider);
                  for (final id in _selected) {
                    await repo.markSettled(id, 'manual');
                  }
                  if (context.mounted) Navigator.pop(context);
                },
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────
// Family Tab (inflows + outflows only, no investments)
// ─────────────────────────────────────────────────────

class _FamilyTab extends ConsumerWidget {
  const _FamilyTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wealth = ref.watch(totalFamilyWealthProvider);
    final inflows = ref.watch(familyInflowsProvider);
    final outflows = ref.watch(familyOutflowsProvider);

    return ListView(
      padding: const EdgeInsets.all(PaisaSpacing.screenH),
      children: [
        // Total card
        wealth.when(
          data: (total) => Container(
            margin: const EdgeInsets.only(bottom: PaisaSpacing.md),
            padding: const EdgeInsets.all(PaisaSpacing.cardPadding),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF1E1E1E), PaisaColors.surface],
              ),
              borderRadius: BorderRadius.circular(PaisaRadii.card),
            ),
            child: Column(
              children: [
                const Text('NET FAMILY FLOW', style: PaisaTextStyles.sectionLabel),
                const SizedBox(height: PaisaSpacing.sm),
                AnimatedAmount(
                  value: total,
                  prefix: '₹',
                  style: const TextStyle(color: PaisaColors.gold, fontSize: 28, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          loading: () => const SizedBox.shrink(),
          error: (_, _) => const SizedBox.shrink(),
        ),

        // Inflows
        _FamilyList(
          label: 'INFLOWS',
          data: inflows,
          icon: PhosphorIconsFill.arrowCircleDown,
          color: PaisaColors.income,
          titleBuilder: (e) => '₹${e.amount.toStringAsFixed(0)} from ${e.fromPerson}',
          emptyText: 'No inflows yet.',
        ),
        const SizedBox(height: PaisaSpacing.lg),

        // Outflows
        _FamilyList(
          label: 'OUTFLOWS',
          data: outflows,
          icon: PhosphorIconsFill.arrowCircleUp,
          color: PaisaColors.expense,
          titleBuilder: (e) => '₹${e.amount.toStringAsFixed(0)} to ${e.fromPerson}',
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
        Text(label, style: PaisaTextStyles.sectionLabel),
        const SizedBox(height: PaisaSpacing.sm),
        data.when(
          data: (list) {
            if (list.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: PaisaSpacing.sm),
                child: Text(emptyText, style: const TextStyle(color: PaisaColors.textTertiary, fontSize: 13)),
              );
            }
            return Column(
              children: list.map((e) {
                final sub = '${DateFormat('d MMM yyyy').format(e.happenedAt)}'
                    '${e.note != null && e.note!.isNotEmpty ? " · ${e.note}" : ""}';
                return Padding(
                  padding: const EdgeInsets.only(bottom: PaisaSpacing.sm),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                        child: Icon(icon, color: color, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(titleBuilder(e), style: const TextStyle(color: PaisaColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
                            const SizedBox(height: 2),
                            Text(sub, style: const TextStyle(color: PaisaColors.textTertiary, fontSize: 12)),
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
          error: (_, _) => const SizedBox.shrink(),
        ),
      ],
    );
  }
}

// ─── Shared small widgets ────────────────────────────

class _BalanceBar extends StatelessWidget {
  const _BalanceBar({required this.label, required this.amount, required this.color, required this.icon});
  final String label;
  final double amount;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          PhosphorIcon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: color, fontSize: 13)),
          const Spacer(),
          Text('₹${amount.toStringAsFixed(0)}', style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({required this.label, required this.color, required this.onTap});
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
          borderRadius: BorderRadius.circular(PaisaRadii.button),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        alignment: Alignment.center,
        child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
