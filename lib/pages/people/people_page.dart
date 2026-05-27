import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:finance_buddy_app/design_system/design_system.dart';
import 'package:finance_buddy_app/data/db.dart';
import 'package:finance_buddy_app/providers/providers.dart';
import 'package:finance_buddy_app/pages/people/person_creation_sheet.dart';
import 'package:finance_buddy_app/pages/people/person_edit_sheet.dart';
import 'package:finance_buddy_app/widgets/common/animated_amount.dart';
import 'package:finance_buddy_app/widgets/common/spendler_bottom_sheet.dart';
import 'package:finance_buddy_app/widgets/common/error_card.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:finance_buddy_app/utils/currency_utils.dart';

const _allTags = ['All', 'friend', 'family', 'colleague', 'other'];

class PeoplePage extends ConsumerStatefulWidget {
  const PeoplePage({super.key});

  @override
  ConsumerState<PeoplePage> createState() => _PeoplePageState();
}

class _PeoplePageState extends ConsumerState<PeoplePage> {
  String _activeTag = 'All';
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final personsAsync = _activeTag == 'All'
        ? ref.watch(allPersonsProvider)
        : ref.watch(personsByTagProvider(_activeTag));
    final sym = currencySymbol(
        ref.watch(selectedCurrencyProvider).valueOrNull ?? 'inr');

    return Scaffold(
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
                  onTap: () => showSpendlerSheet<void>(
                    context: context,
                    builder: (_) => const PersonCreationSheet(),
                  ),
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

          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v.trim()),
              style: AppTextStyles.bodyM.copyWith(color: AppColors.black),
              decoration: InputDecoration(
                hintText: 'Search people...',
                hintStyle:
                    AppTextStyles.bodyM.copyWith(color: AppColors.gray300),
                prefixIcon: const Icon(Icons.search,
                    color: AppColors.gray400, size: 20),
                filled: true,
                fillColor: AppColors.gray100,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                border: OutlineInputBorder(
                  borderRadius: AppRadius.pill,
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Tag filter chips
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              itemCount: _allTags.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(width: AppSpacing.xs),
              itemBuilder: (_, i) {
                final tag = _allTags[i];
                final selected = tag == _activeTag;
                final label = tag == 'All'
                    ? 'All'
                    : tag[0].toUpperCase() + tag.substring(1);
                return GestureDetector(
                  onTap: () => setState(() => _activeTag = tag),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md),
                    decoration: BoxDecoration(
                      color:
                          selected ? AppColors.black : AppColors.gray100,
                      borderRadius: AppRadius.pill,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      label,
                      style: AppTextStyles.bodyS.copyWith(
                        color: selected
                            ? AppColors.white
                            : AppColors.gray600,
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Person list
          Expanded(
            child: personsAsync.when(
              data: (persons) {
                final filtered = _searchQuery.isEmpty
                    ? persons
                    : persons
                        .where((p) => p.name
                            .toLowerCase()
                            .contains(_searchQuery.toLowerCase()))
                        .toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        PhosphorIcon(PhosphorIcons.usersThree(),
                            size: 48, color: AppColors.gray300),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'No matches found.'
                              : 'Add someone to start\ntracking balances.',
                          style: AppTextStyles.bodyM
                              .copyWith(color: AppColors.gray500),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) => Padding(
                    padding:
                        const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _PersonCard(person: filtered[i], symbol: sym),
                  ).animate().fadeIn(
                      delay: AppDurations.stagger * i,
                      duration: AppDurations.medium),
                );
              },
              loading: () => const Center(
                  child: CircularProgressIndicator(
                      color: AppColors.black, strokeWidth: 2)),
              error: (_, __) => const Center(child: ErrorCard()),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Person Card ──────────────────────────────────────────

class _PersonCard extends ConsumerWidget {
  const _PersonCard({required this.person, required this.symbol});
  final Person person;
  final String symbol;

  Color _avatarColor(String hex) {
    try {
      return Color(int.parse('FF${hex.replaceFirst('#', '')}', radix: 16));
    } on FormatException {
      return AppColors.gray500;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balanceAsync = ref.watch(personBalanceProvider(person.id));
    final c = _avatarColor(person.avatarColor);

    return GestureDetector(
      onTap: () => context.push('/people/${person.id}'),
      onLongPress: () {
        HapticFeedback.mediumImpact();
        showSpendlerSheet<void>(
          context: context,
          builder: (_) => PersonEditSheet(person: person),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
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
        child: Row(
          children: [
            // Avatar
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: c.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                person.name.isNotEmpty
                    ? person.name[0].toUpperCase()
                    : '?',
                style: TextStyle(
                    color: c, fontSize: 20, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),

            // Name + tag
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(person.name,
                      style: AppTextStyles.bodyM.copyWith(
                          color: AppColors.black,
                          fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  if (person.tag != null)
                    Text(
                      person.tag![0].toUpperCase() +
                          person.tag!.substring(1),
                      style: AppTextStyles.bodyS
                          .copyWith(color: AppColors.gray500),
                    ),
                ],
              ),
            ),

            // Balance
            balanceAsync.when(
              data: (balance) {
                if (balance == 0) {
                  return Text('Settled',
                      style: AppTextStyles.bodyS.copyWith(
                          color: AppColors.green,
                          fontWeight: FontWeight.w500));
                }
                final isPositive = balance > 0;
                return AnimatedAmount(
                  value: balance.abs(),
                  prefix: isPositive ? '+$symbol' : '-$symbol',
                  style: AppTextStyles.numericM.copyWith(
                    color:
                        isPositive ? AppColors.green : AppColors.orange,
                  ),
                );
              },
              loading: () => const SizedBox(width: 40),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
