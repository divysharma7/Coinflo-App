import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:finance_buddy_app/design_system/design_system.dart';
import 'package:finance_buddy_app/data/db.dart';
import 'package:finance_buddy_app/providers/providers.dart';
import 'package:finance_buddy_app/widgets/common/animated_amount.dart';
import 'package:finance_buddy_app/widgets/common/spendler_bottom_sheet.dart';
import 'package:finance_buddy_app/widgets/common/error_card.dart';
import 'package:finance_buddy_app/pages/people/person_edit_sheet.dart';
import 'package:finance_buddy_app/pages/add/settlement_form.dart';
import 'package:finance_buddy_app/utils/currency_utils.dart';

final _personProvider =
    FutureProvider.family<Person?, int>((ref, id) async {
  final repo = ref.watch(repositoryProvider);
  return repo.getPersonById(id);
});

class PersonDetailPage extends ConsumerWidget {
  const PersonDetailPage({super.key, required this.personId});
  final int personId;

  Color _avatarColor(String hex) {
    try {
      return Color(int.parse('FF${hex.replaceFirst('#', '')}', radix: 16));
    } on FormatException {
      return AppColors.gray500;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final personAsync = ref.watch(_personProvider(personId));
    final balanceAsync = ref.watch(personBalanceProvider(personId));
    final sym = currencySymbol(
        ref.watch(selectedCurrencyProvider).valueOrNull ?? 'inr');

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: personAsync.when(
        data: (person) {
          if (person == null) {
            return const Center(child: Text('Person not found'));
          }
          final c = _avatarColor(person.avatarColor);

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                backgroundColor: AppColors.offWhite,
                foregroundColor: AppColors.black,
                elevation: 0,
                pinned: true,
                actions: [
                  IconButton(
                    icon: PhosphorIcon(PhosphorIcons.pencilSimple(),
                        color: AppColors.black),
                    onPressed: () {
                      showSpendlerSheet<void>(
                        context: context,
                        builder: (_) => PersonEditSheet(person: person),
                      );
                    },
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg),
                  child: Column(
                    children: [
                      // Avatar
                      Container(
                        width: 72,
                        height: 72,
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
                              color: c,
                              fontSize: 32,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(person.name,
                          style: AppTextStyles.headingM
                              .copyWith(color: AppColors.black)),
                      if (person.tag != null) ...[
                        const SizedBox(height: AppSpacing.xxs),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: AppSpacing.xxs),
                          decoration: BoxDecoration(
                            color: AppColors.gray100,
                            borderRadius: AppRadius.pill,
                          ),
                          child: Text(
                            person.tag![0].toUpperCase() +
                                person.tag!.substring(1),
                            style: AppTextStyles.labelM
                                .copyWith(color: AppColors.gray500),
                          ),
                        ),
                      ],
                      if (person.note != null &&
                          person.note!.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(person.note!,
                            style: AppTextStyles.bodyS
                                .copyWith(color: AppColors.gray500)),
                      ],
                      const SizedBox(height: AppSpacing.lg),

                      // Balance card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: AppRadius.mdLg,
                          boxShadow: AppShadows.sm,
                        ),
                        child: balanceAsync.when(
                          data: (balance) {
                            final isPositive = balance > 0;
                            final isZero = balance == 0;
                            return Column(
                              children: [
                                Text(
                                  isZero
                                      ? 'SETTLED UP'
                                      : isPositive
                                          ? 'OWES YOU'
                                          : 'YOU OWE',
                                  style: AppTextStyles.labelM.copyWith(
                                      color: AppColors.gray500),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                AnimatedAmount(
                                  value: balance.abs(),
                                  prefix: sym,
                                  style: AppTextStyles.headingL.copyWith(
                                    color: isZero
                                        ? AppColors.gray500
                                        : isPositive
                                            ? AppColors.green
                                            : AppColors.orange,
                                  ),
                                ),
                              ],
                            );
                          },
                          loading: () => const SizedBox(height: 48),
                          error: (_, __) => const ErrorCard(),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Settle Up button
                      balanceAsync.when(
                        data: (balance) {
                          if (balance == 0) return const SizedBox.shrink();
                          return AppButton(
                            label: 'Settle Up',
                            onTap: () => showSpendlerSheet<void>(
                              context: context,
                              builder: (_) => SettlementForm(
                                person: person,
                                balance: balance,
                              ),
                            ),
                          );
                        },
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),

                      const SizedBox(height: AppSpacing.xl),

                      // Transaction history placeholder
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: AppRadius.mdLg,
                          border: Border.all(color: AppColors.gray200),
                        ),
                        child: Column(
                          children: [
                            PhosphorIcon(PhosphorIcons.receipt(),
                                size: 36, color: AppColors.gray300),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'Transaction history will appear here\nonce splits are added.',
                              style: AppTextStyles.bodyS
                                  .copyWith(color: AppColors.gray500),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxxl),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(
            child: CircularProgressIndicator(
                color: AppColors.black, strokeWidth: 2)),
        error: (_, __) => const Center(child: ErrorCard()),
      ),
    );
  }
}
