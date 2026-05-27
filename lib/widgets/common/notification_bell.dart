import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:finance_buddy_app/design_system/design_system.dart';
import 'package:finance_buddy_app/providers/notification_providers.dart';
import 'package:finance_buddy_app/widgets/common/notification_sheet.dart';
import 'package:finance_buddy_app/widgets/common/spendler_bottom_sheet.dart';

/// Bell icon with a yellow unread dot. Taps open the notification centre sheet.
class NotificationBell extends ConsumerWidget {
  const NotificationBell({super.key, this.color});

  final Color? color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasUnread = ref.watch(hasUnreadNotifProvider);
    final iconColor = color ?? (hasUnread
        ? AppColors.black
        : AppColors.gray500);

    return GestureDetector(
      onTap: () {
        showSpendlerSheet<void>(
          context: context,
          builder: (_) => const NotificationSheet(),
        );
      },
      child: SizedBox(
        width: 40,
        height: 40,
        child: Stack(
          alignment: Alignment.center,
          children: [
            PhosphorIcon(
              hasUnread
                  ? PhosphorIconsFill.bellRinging
                  : PhosphorIcons.bell(),
              color: iconColor,
              size: 24,
            ),
            if (hasUnread)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.black,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
