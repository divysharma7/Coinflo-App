import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:finance_buddy_app/data/db.dart';
import 'package:finance_buddy_app/design_system/design_system.dart';
import 'package:finance_buddy_app/providers/providers.dart';
import 'package:finance_buddy_app/widgets/common/error_card.dart';

/// Notifications — real stored alerts (budget, check-in, digest, subscription),
/// grouped by recency. Mirrors the "More Screens" Hi-Fi mock.
class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifsAsync = ref.watch(recentNotificationsProvider);

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── Header: back · title · mark all read ──
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xs, AppSpacing.xs, AppSpacing.lg, AppSpacing.xs),
              child: Row(
                children: [
                  const AppBackButton(),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text('Notifications',
                        style: AppTextStyles.headingM
                            .copyWith(color: AppColors.black)),
                  ),
                  GestureDetector(
                    onTap: () => ref.read(repositoryProvider).markAllRead(),
                    behavior: HitTestBehavior.opaque,
                    child: Text('Mark all read',
                        style: AppTextStyles.bodyS.copyWith(
                            color: AppColors.gray500,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),

            Expanded(
              child: notifsAsync.when(
                data: (notifs) {
                  if (notifs.isEmpty) return const _EmptyNotifications();

                  final groups = _groupByRecency(notifs);
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.lg,
                        AppSpacing.md, AppSpacing.lg, AppSpacing.xxxl),
                    children: [
                      for (final g in groups) ...[
                        Padding(
                          padding: const EdgeInsets.only(
                              left: 2, bottom: AppSpacing.xs),
                          child: Text(g.label,
                              style: AppTextStyles.section
                                  .copyWith(color: AppColors.gray400)),
                        ),
                        _NotificationCard(items: g.items),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                    ],
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
      ),
    );
  }

  List<_NotifGroup> _groupByRecency(List<AppNotification> notifs) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final todayItems = <AppNotification>[];
    final yesterdayItems = <AppNotification>[];
    final earlierItems = <AppNotification>[];

    for (final n in notifs) {
      final d = DateTime(n.sentAt.year, n.sentAt.month, n.sentAt.day);
      if (d == today) {
        todayItems.add(n);
      } else if (d == yesterday) {
        yesterdayItems.add(n);
      } else {
        earlierItems.add(n);
      }
    }

    return [
      if (todayItems.isNotEmpty) _NotifGroup('Today', todayItems),
      if (yesterdayItems.isNotEmpty) _NotifGroup('Yesterday', yesterdayItems),
      if (earlierItems.isNotEmpty) _NotifGroup('Earlier', earlierItems),
    ];
  }
}

class _NotifGroup {
  const _NotifGroup(this.label, this.items);
  final String label;
  final List<AppNotification> items;
}

// ─── Grouped card of notification rows ───────────────────────

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.items});
  final List<AppNotification> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: AppRadius.xl,
        boxShadow: AppShadows.sm,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0)
              const Divider(height: 1, thickness: 1, color: AppColors.gray100),
            _NotificationRow(notif: items[i]),
          ],
        ],
      ),
    );
  }
}

class _NotificationRow extends StatelessWidget {
  const _NotificationRow({required this.notif});
  final AppNotification notif;

  @override
  Widget build(BuildContext context) {
    final style = _styleFor(notif.type);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon tile
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: style.bg,
              borderRadius: AppRadius.base,
            ),
            child: Center(
              child: PhosphorIcon(style.icon, size: 20, color: style.fg),
            ),
          ),
          const SizedBox(width: 13),
          // Title + body + time
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(notif.title,
                    style: AppTextStyles.bodyM.copyWith(
                        color: AppColors.black,
                        fontWeight: FontWeight.w600,
                        height: 1.2)),
                if (notif.body.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(notif.body,
                      style: AppTextStyles.bodyS.copyWith(
                          color: AppColors.gray500, height: 1.42)),
                ],
                const SizedBox(height: 5),
                Text(_timeLabel(notif.sentAt),
                    style: AppTextStyles.labelS.copyWith(
                        color: AppColors.gray400,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0)),
              ],
            ),
          ),
          // Unread dot
          if (!notif.isRead)
            Container(
              margin: const EdgeInsets.only(top: 7, left: 8),
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                  color: AppColors.black, shape: BoxShape.circle),
            ),
        ],
      ),
    );
  }

  String _timeLabel(DateTime sentAt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(sentAt.year, sentAt.month, sentAt.day);
    final time = _clock(sentAt);
    if (d == today) {
      final diff = now.difference(sentAt);
      if (diff.inMinutes < 60) {
        return diff.inMinutes <= 1 ? 'Just now' : '${diff.inMinutes}m ago';
      }
      if (diff.inHours < 12) return '${diff.inHours}h ago';
      return time;
    }
    if (d == today.subtract(const Duration(days: 1))) {
      return 'Yesterday · $time';
    }
    return '${sentAt.day}/${sentAt.month} · $time';
  }

  /// 12-hour clock without needing a BuildContext (e.g. "9:00 AM").
  String _clock(DateTime t) {
    final isPm = t.hour >= 12;
    final h12 = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final mm = t.minute.toString().padLeft(2, '0');
    return '$h12:$mm ${isPm ? 'PM' : 'AM'}';
  }
}

// Resolve icon + colors from the notification `type` string.
class _NotifStyle {
  const _NotifStyle(this.icon, this.bg, this.fg);
  final IconData icon;
  final Color bg;
  final Color fg;
}

_NotifStyle _styleFor(String type) {
  switch (type) {
    case 'transaction':
      return _NotifStyle(
          PhosphorIcons.warning(), AppColors.catOrangeBg, AppColors.catOrangeText);
    case 'subscription':
      return _NotifStyle(PhosphorIcons.arrowsClockwise(), AppColors.catPinkBg,
          AppColors.catPinkText);
    case 'digest':
      return _NotifStyle(
          PhosphorIcons.chartBar(), AppColors.gray100, AppColors.black);
    case 'checkin':
      return _NotifStyle(PhosphorIcons.bell(), AppColors.black, AppColors.white);
    default:
      return _NotifStyle(
          PhosphorIcons.bell(), AppColors.gray100, AppColors.gray600);
  }
}

// ─── Empty state ─────────────────────────────────────────────

class _EmptyNotifications extends StatelessWidget {
  const _EmptyNotifications();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PhosphorIcon(PhosphorIcons.bellSlash(),
              size: 48, color: AppColors.gray300),
          const SizedBox(height: AppSpacing.md),
          Text("You're all caught up.",
              style:
                  AppTextStyles.bodyM.copyWith(color: AppColors.gray500)),
          const SizedBox(height: AppSpacing.xxs),
          Text('Alerts about budgets, bills and goals\nwill show up here.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyS.copyWith(color: AppColors.gray400)),
        ],
      ),
    );
  }
}
