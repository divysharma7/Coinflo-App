import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:finance_buddy_app/core/tokens.dart';
import 'package:finance_buddy_app/data/db.dart';
import 'package:finance_buddy_app/providers/providers.dart';
import 'package:finance_buddy_app/widgets/common/empty_state.dart';
import 'package:finance_buddy_app/widgets/common/hero_amount.dart';

class FamilyPage extends ConsumerWidget {
  const FamilyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wealth = ref.watch(totalFamilyWealthProvider);
    final inflows = ref.watch(familyInflowsProvider);
    final outflows = ref.watch(familyOutflowsProvider);
    final investments = ref.watch(familyInvestmentsProvider);

    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          // Total wealth header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(
              PaisaSpacing.screenH,
              PaisaSpacing.screenTop + 16,
              PaisaSpacing.screenH,
              PaisaSpacing.lg,
            ),
            color: PaisaColors.gold.withValues(alpha: 0.04),
            child: Column(
              children: [
                const Text('TOTAL FAMILY WEALTH', style: PaisaTextStyles.sectionLabel),
                const SizedBox(height: PaisaSpacing.sm),
                wealth.when(
                  data: (total) => HeroAmount(amount: total, amountSize: 40, symbolSize: 20),
                  loading: () => const Text('...', style: TextStyle(color: PaisaColors.textTertiary)),
                  error: (_, _) => const Text('—', style: TextStyle(color: PaisaColors.expense)),
                ),
              ],
            ),
          ),

          // Tab bar — 3 tabs
          const TabBar(
            indicatorColor: PaisaColors.gold,
            labelColor: PaisaColors.gold,
            unselectedLabelColor: PaisaColors.textTertiary,
            tabs: [
              Tab(text: 'Inflows'),
              Tab(text: 'Outflows'),
              Tab(text: 'Investments'),
            ],
          ),

          // Tab views
          Expanded(
            child: TabBarView(
              children: [
                // Inflows
                _FamilyList(
                  data: inflows,
                  icon: PhosphorIcons.arrowCircleDown(),
                  color: PaisaColors.income,
                  titleBuilder: (e) => '₹${e.amount.toStringAsFixed(0)} from ${e.fromPerson}',
                  emptyMessage: 'Family finances live here.',
                  emptySubtitle: 'Add your first entry to get started.',
                ),

                // Outflows
                _FamilyList(
                  data: outflows,
                  icon: PhosphorIcons.arrowCircleUp(),
                  color: PaisaColors.expense,
                  titleBuilder: (e) => '₹${e.amount.toStringAsFixed(0)} to ${e.fromPerson}',
                  emptyMessage: 'No outflows recorded.',
                  emptySubtitle: 'Money sent to family shows up here.',
                ),

                // Investments
                _FamilyList(
                  data: investments,
                  icon: PhosphorIcons.trendUp(),
                  color: PaisaColors.gold,
                  titleBuilder: (e) => '₹${e.amount.toStringAsFixed(0)} — ${e.investmentType ?? "Other"}',
                  subtitleBuilder: (e) => 'Via ${e.fromPerson} · ${DateFormat('d MMM').format(e.happenedAt)}'
                      '${e.note != null && e.note!.isNotEmpty ? " · ${e.note}" : ""}',
                  emptyMessage: 'No investments tracked yet.',
                  emptySubtitle: 'Tap + to add.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Reusable family list widget for each tab.
class _FamilyList extends StatelessWidget {
  const _FamilyList({
    required this.data,
    required this.icon,
    required this.color,
    required this.titleBuilder,
    this.subtitleBuilder,
    required this.emptyMessage,
    required this.emptySubtitle,
  });

  final AsyncValue<List<FamilyEntry>> data;
  final IconData icon;
  final Color color;
  final String Function(FamilyEntry e) titleBuilder;
  final String Function(FamilyEntry e)? subtitleBuilder;
  final String emptyMessage;
  final String emptySubtitle;

  @override
  Widget build(BuildContext context) {
    return data.when(
      data: (list) {
        if (list.isEmpty) {
          return EmptyState(
            icon: Icons.family_restroom,
            message: emptyMessage,
            subtitle: emptySubtitle,
          );
        }
        return ListView.builder(
          itemCount: list.length,
          itemBuilder: (_, i) {
            final e = list[i];
            final sub = subtitleBuilder != null
                ? subtitleBuilder!(e)
                : '${DateFormat('d MMM yyyy').format(e.happenedAt)}'
                    '${e.note != null && e.note!.isNotEmpty ? " · ${e.note}" : ""}';
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.15),
                child: PhosphorIcon(icon, color: color, size: 22),
              ),
              title: Text(titleBuilder(e), style: PaisaTextStyles.merchantName),
              subtitle: Text(
                sub,
                style: const TextStyle(color: PaisaColors.textTertiary, fontSize: 12),
              ),
            );
          },
        );
      },
      loading: () => Center(child: CircularProgressIndicator(color: color)),
      error: (_, _) => const Center(child: Text('Error', style: TextStyle(color: PaisaColors.expense))),
    );
  }
}
