import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:finance_buddy_app/design_system/design_system.dart';
import 'package:finance_buddy_app/data/db.dart';
import 'package:finance_buddy_app/providers/providers.dart';
import 'package:finance_buddy_app/widgets/common/error_card.dart';

final _groupProvider = FutureProvider.family<Group?, int>((ref, id) async {
  final repo = ref.watch(repositoryProvider);
  return repo.getGroupById(id);
});

class GroupDetailPage extends ConsumerWidget {
  const GroupDetailPage({super.key, required this.groupId});
  final int groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupAsync = ref.watch(_groupProvider(groupId));
    final membersAsync = ref.watch(groupMembersProvider(groupId));

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: groupAsync.when(
        data: (group) {
          if (group == null) return const Center(child: Text('Group not found'));
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                backgroundColor: AppColors.offWhite,
                foregroundColor: AppColors.black,
                elevation: 0, pinned: true,
                title: Text(group.name,
                    style: AppTextStyles.headingS.copyWith(color: AppColors.black)),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (group.description != null) ...[
                        Text(group.description!,
                            style: AppTextStyles.bodyM.copyWith(color: AppColors.gray500)),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                      Text('MEMBERS',
                          style: AppTextStyles.labelM.copyWith(color: AppColors.gray500)),
                      const SizedBox(height: AppSpacing.sm),
                      membersAsync.when(
                        data: (members) {
                          if (members.isEmpty) {
                            return Text('No members yet.',
                                style: AppTextStyles.bodyS.copyWith(color: AppColors.gray400));
                          }
                          return Column(children: members.map((m) => _MemberRow(member: m)).toList());
                        },
                        loading: () => const SizedBox(height: 40),
                        error: (_, __) => const ErrorCard(),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        decoration: BoxDecoration(
                          color: AppColors.white, borderRadius: AppRadius.mdLg,
                          border: Border.all(color: AppColors.gray200)),
                        child: Column(children: [
                          PhosphorIcon(PhosphorIcons.receipt(), size: 36, color: AppColors.gray300),
                          const SizedBox(height: AppSpacing.sm),
                          Text('Group transactions will appear\nhere once splits are added.',
                              style: AppTextStyles.bodyS.copyWith(color: AppColors.gray500),
                              textAlign: TextAlign.center),
                        ]),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.black, strokeWidth: 2)),
        error: (_, __) => const Center(child: ErrorCard()),
      ),
    );
  }
}

class _MemberRow extends ConsumerWidget {
  const _MemberRow({required this.member});
  final GroupMember member;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final personAsync = FutureProvider<Person?>((ref) async {
      return ref.watch(repositoryProvider).getPersonById(member.personId);
    });
    final pAsync = ref.watch(personAsync);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: pAsync.when(
        data: (person) => Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(color: AppColors.white, borderRadius: AppRadius.base),
          child: Row(children: [
            const Icon(Icons.person_outline, color: AppColors.gray500, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Text(person?.name ?? 'Unknown',
                style: AppTextStyles.bodyM.copyWith(color: AppColors.black)),
          ]),
        ),
        loading: () => const SizedBox(height: 36),
        error: (_, __) => const SizedBox.shrink(),
      ),
    );
  }
}
