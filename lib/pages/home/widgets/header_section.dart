import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:finance_buddy_app/design_system/design_system.dart';
import 'package:finance_buddy_app/providers/providers.dart';
import 'package:finance_buddy_app/widgets/common/notification_bell.dart';
import 'package:finance_buddy_app/widgets/common/spendler_bottom_sheet.dart';

class HeaderSection extends ConsumerWidget {
  const HeaderSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(selectedMonthProvider);
    final userName = ref.watch(userNameProvider);

    final monthLabel = DateFormat('MMMM yyyy').format(month);
    final name = userName.valueOrNull;
    final hasName = name != null && name.trim().isNotEmpty;
    final greeting = hasName ? 'Hi, $name' : 'Hi there';

    return Container(
      color: AppColors.black,
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        MediaQuery.paddingOf(context).top + AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Row(
        children: [
          // Avatar
          hasName
              ? _UserAvatar(userName: name)
              : Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.15),
                    borderRadius: AppRadius.sm,
                  ),
                  child: Icon(PhosphorIcons.user(),
                      color: AppColors.white.withValues(alpha: 0.6), size: 18),
                ),
          const SizedBox(width: AppSpacing.sm),
          // Greeting + month
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(greeting,
                    style: AppTextStyles.headingS
                        .copyWith(color: AppColors.white)),
                GestureDetector(
                  onTap: () => _showMonthPicker(context, ref, month),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(monthLabel,
                          style: AppTextStyles.bodyS.copyWith(
                              color: AppColors.white.withValues(alpha: 0.6))),
                      const SizedBox(width: 4),
                      Icon(Icons.keyboard_arrow_down,
                          color: AppColors.white.withValues(alpha: 0.6),
                          size: 16),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const NotificationBell(color: AppColors.white),
        ],
      ),
    );
  }

  void _showMonthPicker(BuildContext context, WidgetRef ref, DateTime current) {
    final now = DateTime.now();
    showSpendlerSheet<void>(
      context: context,
      isScrollControlled: false,
      builder: (_) {
        final months = List.generate(12, (i) => DateTime(now.year, now.month - i));
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...months.map((m) {
                final isSelected =
                    m.year == current.year && m.month == current.month;
                return ListTile(
                  title: Text(DateFormat('MMMM yyyy').format(m),
                      style: AppTextStyles.bodyM.copyWith(
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w400,
                          color: isSelected
                              ? AppColors.black
                              : AppColors.gray500)),
                  trailing: isSelected
                      ? const Icon(Icons.check, color: AppColors.black, size: 20)
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

class _UserAvatar extends StatelessWidget {
  const _UserAvatar({this.userName});
  final String? userName;

  @override
  Widget build(BuildContext context) {
    final initials = _getInitials(userName);
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.15),
        borderRadius: AppRadius.sm,
      ),
      child: Center(
        child: Text(initials,
            style: AppTextStyles.bodyS
                .copyWith(color: AppColors.white, fontWeight: FontWeight.w700)),
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
