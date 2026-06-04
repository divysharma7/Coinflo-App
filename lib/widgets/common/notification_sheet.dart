import 'package:finance_buddy_app/widgets/common/error_card.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:finance_buddy_app/design_system/design_system.dart';
import 'package:finance_buddy_app/data/db.dart';
import 'package:finance_buddy_app/providers/database_providers.dart';
import 'package:finance_buddy_app/providers/notification_providers.dart';

/// Bottom sheet showing recent notifications and notification settings.
class NotificationSheet extends ConsumerWidget {
  const NotificationSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(notifPrefsProvider);
    final recentAsync = ref.watch(recentNotificationsProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.xl,
          ),
          child: ListView(
            controller: scrollController,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'COINFLO',
                    style: AppTextStyles.labelM.copyWith(
                      color: AppColors.gray500,
                      letterSpacing: 1.5,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => ref.read(repositoryProvider).markAllRead(),
                    child: const Text(
                      'Mark all read',
                      style: TextStyle(
                        color: AppColors.black,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // --- Recent notifications ---
              Text(
                'RECENT',
                style: AppTextStyles.labelM.copyWith(
                  color: AppColors.gray500,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),

              recentAsync.when(
                data: (notifications) {
                  if (notifications.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                      child: Center(
                        child: Text(
                          'All quiet — no notifications yet',
                          style: TextStyle(
                            color: AppColors.gray500,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    );
                  }
                  return Column(
                    children: notifications
                        .map((n) => _NotificationRow(
                              notification: n,
                              onTap: () =>
                                  ref.read(repositoryProvider).markRead(n.id),
                            ))
                        .toList(),
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.black,
                      strokeWidth: 2,
                    ),
                  ),
                ),
                error: (_, _) => const ErrorCard(),
              ),

              const SizedBox(height: AppSpacing.xl),
              const Divider(color: AppColors.gray200, height: 1),
              const SizedBox(height: AppSpacing.md),

              // --- Settings (grouped card) ---
              Text(
                'SETTINGS',
                style: AppTextStyles.labelM.copyWith(
                  color: AppColors.gray500,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),

              Container(
                decoration: const BoxDecoration(
                  color: AppColors.white,
                  borderRadius: AppRadius.base,
                ),
                child: Column(
                  children: [
                    _ToggleRow(
                      icon: PhosphorIcons.bell(),
                      iconBg: const Color(0x1AF97316), // orangeLight
                      iconColor: AppColors.orange,
                      title: 'Budget alerts',
                      subtitle: 'When a category crosses 80%',
                      value: prefs.txnAlerts,
                      onChanged: (v) =>
                          ref.read(notifPrefsProvider.notifier).setTxnAlerts(v),
                    ),
                    const Divider(
                        color: AppColors.gray200, height: 1, indent: 56),
                    _ToggleRow(
                      icon: PhosphorIcons.moon(),
                      iconBg: const Color(0x1A8B5CF6), // aiPurple 10%
                      iconColor: AppColors.aiPurple,
                      title: 'Evening check-in',
                      subtitle:
                          '${_formatTime(prefs.checkinHour, prefs.checkinMinute)} \u00b7 only when queue has items',
                      value: prefs.eveningCheckin,
                      onChanged: (v) => ref
                          .read(notifPrefsProvider.notifier)
                          .setEveningCheckin(v),
                    ),
                    // Inline check-in time picker — only when toggle is ON
                    if (prefs.eveningCheckin)
                      GestureDetector(
                        onTap: () => _pickTime(context, ref, prefs),
                        child: Padding(
                          padding: const EdgeInsets.only(
                            left: 56,
                            right: AppSpacing.md,
                            bottom: AppSpacing.sm,
                          ),
                          child: Row(
                            children: [
                              PhosphorIcon(
                                PhosphorIcons.clock(),
                                color: AppColors.gray400,
                                size: 16,
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              const Text(
                                'Change time',
                                style: TextStyle(
                                  color: AppColors.gray500,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                _formatTime(
                                    prefs.checkinHour, prefs.checkinMinute),
                                style: const TextStyle(
                                  color: AppColors.gray400,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.xxs),
                              PhosphorIcon(
                                PhosphorIcons.caretRight(),
                                color: AppColors.gray400,
                                size: 14,
                              ),
                            ],
                          ),
                        ),
                      ),
                    const Divider(
                        color: AppColors.gray200, height: 1, indent: 56),
                    _ToggleRow(
                      icon: PhosphorIcons.calendarCheck(),
                      iconBg: AppColors.catBlueBg,
                      iconColor: AppColors.catBlueText,
                      title: 'Sunday digest',
                      subtitle: 'Weekly spending summary at 7pm',
                      value: prefs.sundayDigest,
                      onChanged: (v) => ref
                          .read(notifPrefsProvider.notifier)
                          .setSundayDigest(v),
                    ),
                    const Divider(
                        color: AppColors.gray200, height: 1, indent: 56),
                    _ToggleRow(
                      icon: PhosphorIcons.creditCard(),
                      iconBg: AppColors.catGreenBg,
                      iconColor: AppColors.catGreenText,
                      title: 'Subscription reminders',
                      subtitle: 'Day before a bill is due',
                      value: prefs.subscriptionAlerts,
                      onChanged: (v) => ref
                          .read(notifPrefsProvider.notifier)
                          .setSubscriptionAlerts(v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        );
      },
    );
  }

  static String _formatTime(int hour, int minute) {
    final period = hour >= 12 ? 'PM' : 'AM';
    final h = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m $period';
  }

  static Future<void> _pickTime(
    BuildContext context,
    WidgetRef ref,
    NotifPrefs prefs,
  ) async {
    final picked = await showTimePicker(
      context: context,
      initialTime:
          TimeOfDay(hour: prefs.checkinHour, minute: prefs.checkinMinute),
      builder: monoPickerBuilder,
    );
    if (picked != null) {
      await ref
          .read(notifPrefsProvider.notifier)
          .setCheckinTime(picked.hour, picked.minute);
    }
  }
}

// --- Notification row ---

class _NotificationRow extends StatelessWidget {
  const _NotificationRow({
    required this.notification,
    required this.onTap,
  });

  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = _colorForType(notification.type);
    final bgColor = _bgForType(notification.type);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.xs),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: notification.isRead ? AppColors.white : AppColors.offWhite,
          borderRadius: AppRadius.base,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: PhosphorIcon(
                _iconForType(notification.type),
                color: color,
                size: 16,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: TextStyle(
                      color: AppColors.black,
                      fontSize: 14,
                      fontWeight: notification.isRead
                          ? FontWeight.w400
                          : FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    notification.body,
                    style: const TextStyle(
                      color: AppColors.gray500,
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              _relativeTime(notification.sentAt),
              style: const TextStyle(
                color: AppColors.gray500,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static IconData _iconForType(String type) {
    switch (type) {
      case 'transaction':
        return PhosphorIcons.lightning();
      case 'checkin':
        return PhosphorIcons.moon();
      case 'digest':
        return PhosphorIcons.calendarCheck();
      default:
        return PhosphorIcons.bell();
    }
  }

  static Color _colorForType(String type) {
    switch (type) {
      case 'transaction':
        return AppColors.black;
      case 'checkin':
        return AppColors.aiPurple;
      case 'digest':
        return AppColors.catBlueText;
      case 'subscription':
        return AppColors.orange;
      default:
        return AppColors.gray500;
    }
  }

  static Color _bgForType(String type) {
    switch (type) {
      case 'transaction':
        return AppColors.gray100;
      case 'checkin':
        return const Color(0x1A8B5CF6); // aiPurple 10%
      case 'digest':
        return AppColors.catBlueBg;
      case 'subscription':
        return const Color(0x1AF97316); // orangeLight
      default:
        return AppColors.gray100;
    }
  }

  static String _relativeTime(DateTime sentAt) {
    final now = DateTime.now();
    final diff = now.difference(sentAt);

    if (diff.inMinutes < 1) return 'Now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${diff.inDays ~/ 7}w ago';
  }
}

// --- Toggle row (settings) ---

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: PhosphorIcon(icon, color: iconColor, size: 16),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.black,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.gray500,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.black,
            activeTrackColor: AppColors.black.withValues(alpha: 0.3),
            inactiveTrackColor: AppColors.gray200,
            inactiveThumbColor: AppColors.gray500,
          ),
        ],
      ),
    );
  }
}
