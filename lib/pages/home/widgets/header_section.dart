import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:finance_buddy_app/design_system/design_system.dart';
import 'package:finance_buddy_app/providers/providers.dart';
import 'package:finance_buddy_app/widgets/common/spendler_bottom_sheet.dart';

/// Zone 1 — greeting header: uppercase date eyebrow (tap → month picker),
/// large "Hi, FirstName" title, and an ink avatar with white initials.
class HeaderSection extends ConsumerWidget {
  const HeaderSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(selectedMonthProvider);
    final fullName = ref.watch(userNameProvider).valueOrNull;

    final dateLabel = DateFormat('EEEE, d MMM').format(DateTime.now());
    final hasName = fullName != null && fullName.trim().isNotEmpty;
    final firstName = hasName ? _firstName(fullName) : null;
    final greeting = firstName != null ? 'Hi, $firstName' : 'Hi there';

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        MediaQuery.paddingOf(context).top + AppSpacing.sm + 6,
        AppSpacing.lg,
        AppSpacing.xs,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Greeting: uppercase date eyebrow (tap to switch month) + big title.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => _showMonthPicker(context, ref, month),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                    child: Text(
                      dateLabel.toUpperCase(),
                      style: AppTextStyles.section.copyWith(
                        color: AppColors.gray400,
                      ),
                    ),
                  ),
                ),
                Text(
                  greeting,
                  style: AppTextStyles.displayL.copyWith(
                    color: AppColors.black,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          // Notifications bell with an unread dot.
          _NotificationBell(hasUnread: ref.watch(hasUnreadNotifProvider)),
          const SizedBox(width: AppSpacing.sm),
          // 46px ink circle avatar with white initials.
          hasName
              ? _UserAvatar(userName: fullName)
              : Container(
                  width: 46,
                  height: 46,
                  decoration: const BoxDecoration(
                    color: AppColors.black,
                    shape: BoxShape.circle,
                    boxShadow: AppShadows.md,
                  ),
                  child: Icon(
                    PhosphorIcons.user(),
                    color: AppColors.white.withValues(alpha: 0.7),
                    size: 20,
                  ),
                ),
        ],
      ),
    );
  }

  /// First whitespace-delimited token of the stored name.
  String _firstName(String name) => name.trim().split(RegExp(r'\s+')).first;

  void _showMonthPicker(BuildContext context, WidgetRef ref, DateTime current) {
    final now = DateTime.now();
    showSpendlerSheet<void>(
      context: context,
      isScrollControlled: false,
      builder: (_) {
        final months = List.generate(
          12,
          (i) => DateTime(now.year, now.month - i),
        );
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...months.map((m) {
                final isSelected =
                    m.year == current.year && m.month == current.month;
                return ListTile(
                  title: Text(
                    DateFormat('MMMM yyyy').format(m),
                    style: AppTextStyles.bodyM.copyWith(
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w400,
                      color: isSelected ? AppColors.black : AppColors.gray500,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(
                          Icons.check,
                          color: AppColors.black,
                          size: 20,
                        )
                      : null,
                  onTap: () {
                    ref.read(selectedMonthProvider.notifier).state = m;
                    Navigator.pop(context);
                  },
                );
              }),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        );
      },
    );
  }
}

class _NotificationBell extends StatelessWidget {
  const _NotificationBell({required this.hasUnread});
  final bool hasUnread;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/notifications'),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 46,
        height: 46,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: const BoxDecoration(
                color: AppColors.white,
                shape: BoxShape.circle,
                boxShadow: AppShadows.sm,
              ),
              child: Center(
                child: PhosphorIcon(PhosphorIcons.bell(),
                    color: AppColors.black, size: 20),
              ),
            ),
            if (hasUnread)
              Positioned(
                top: 12,
                right: 13,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: AppColors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.offWhite, width: 1.5),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  const _UserAvatar({this.userName});
  final String? userName;

  @override
  Widget build(BuildContext context) {
    final initials = _getInitials(userName);
    return Container(
      width: 46,
      height: 46,
      decoration: const BoxDecoration(
        color: AppColors.black,
        shape: BoxShape.circle,
        boxShadow: AppShadows.md,
      ),
      child: Center(
        child: Text(
          initials,
          style: AppTextStyles.headingS.copyWith(
            color: AppColors.white,
            fontSize: 16,
            letterSpacing: 0.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  String _getInitials(String? name) {
    if (name == null || name.isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }
}
