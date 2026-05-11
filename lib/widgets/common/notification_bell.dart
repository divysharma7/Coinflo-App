import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:finance_buddy_app/core/tokens.dart';
import 'package:finance_buddy_app/providers/notification_providers.dart';
import 'package:finance_buddy_app/widgets/common/notification_sheet.dart';

/// Bell icon with a yellow unread dot. Taps open the notification centre sheet.
class NotificationBell extends ConsumerWidget {
  const NotificationBell({super.key, this.color});

  final Color? color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasUnread = ref.watch(hasUnreadNotifProvider);
    final iconColor = color ?? (hasUnread
        ? SpendlerColors.primary
        : SpendlerColors.textSecondary);

    return GestureDetector(
      onTap: () {
        showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          backgroundColor: SpendlerColors.surfaceHigh,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(SpendlerRadii.sheet),
            ),
          ),
          showDragHandle: true,
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
                    color: SpendlerColors.primary,
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
