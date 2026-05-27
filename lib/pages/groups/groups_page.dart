import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:finance_buddy_app/design_system/design_system.dart';
import 'package:finance_buddy_app/data/db.dart';
import 'package:finance_buddy_app/providers/providers.dart';
import 'package:finance_buddy_app/pages/groups/group_creation_sheet.dart';
import 'package:finance_buddy_app/widgets/common/spendler_bottom_sheet.dart';
import 'package:finance_buddy_app/widgets/common/error_card.dart';
import 'package:flutter_animate/flutter_animate.dart';

class GroupsPage extends ConsumerWidget {
  const GroupsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(allGroupsProvider);

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: AppBar(
        backgroundColor: AppColors.offWhite,
        foregroundColor: AppColors.black,
        elevation: 0,
        title: Text('Groups',
            style: AppTextStyles.headingL.copyWith(color: AppColors.black)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.black),
            onPressed: () => showSpendlerSheet<void>(
              context: context,
              builder: (_) => const GroupCreationSheet(),
            ),
          ),
        ],
      ),
      body: groupsAsync.when(
        data: (groups) {
          if (groups.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PhosphorIcon(PhosphorIcons.usersThree(),
                      size: 48, color: AppColors.gray300),
                  const SizedBox(height: AppSpacing.md),
                  Text('Create a group to split\nexpenses together.',
                      style: AppTextStyles.bodyM
                          .copyWith(color: AppColors.gray500),
                      textAlign: TextAlign.center),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: groups.length,
            itemBuilder: (_, i) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _GroupCard(group: groups[i]),
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
    );
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({required this.group});
  final Group group;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/groups/${group.id}'),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: AppRadius.mdLg,
          boxShadow: AppShadows.sm,
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: AppColors.gray100, borderRadius: AppRadius.base),
              child: const Icon(Icons.group, color: AppColors.gray500, size: 24),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(group.name,
                      style: AppTextStyles.bodyM.copyWith(
                          color: AppColors.black, fontWeight: FontWeight.w600)),
                  if (group.description != null)
                    Text(group.description!,
                        style: AppTextStyles.bodyS.copyWith(color: AppColors.gray500),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.gray400, size: 20),
          ],
        ),
      ),
    );
  }
}
