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

    final dateLabel = DateFormat('EEEE, d MMM').format(DateTime.now());
    final name = userName.valueOrNull;
    final hasName = name != null && name.trim().isNotEmpty;
    final greeting = hasName ? 'Hi, $name' : 'Hi there';

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
          // Greeting: date eyebrow + big grotesk title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => _showMonthPicker(context, ref, month),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(dateLabel,
                          style: AppTextStyles.section
                              .copyWith(color: AppColors.gray400)),
                      const SizedBox(width: 4),
                      const Icon(Icons.keyboard_arrow_down,
                          color: AppColors.gray400, size: 15),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(greeting,
                    style: AppTextStyles.displayL
                        .copyWith(color: AppColors.black)),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          // 46px ink circle avatar with white initials
          hasName
              ? _UserAvatar(userName: name)
              : Container(
                  width: 46,
                  height: 46,
                  decoration: const BoxDecoration(
                    color: AppColors.black,
                    shape: BoxShape.circle,
                    boxShadow: AppShadows.md,
                  ),
                  child: Icon(PhosphorIcons.user(),
                      color: AppColors.white.withValues(alpha: 0.7), size: 20),
                ),
          const SizedBox(width: AppSpacing.xs),
          const NotificationBell(color: AppColors.black),
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
      width: 46,
      height: 46,
      decoration: const BoxDecoration(
        color: AppColors.black,
        shape: BoxShape.circle,
        boxShadow: AppShadows.md,
      ),
      child: Center(
        child: Text(initials,
            style: AppTextStyles.headingS.copyWith(
                color: AppColors.white,
                fontSize: 16,
                letterSpacing: 0.5,
                fontWeight: FontWeight.w700)),
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
