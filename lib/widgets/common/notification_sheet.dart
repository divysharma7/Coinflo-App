import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:finance_buddy_app/design_system/design_system.dart';
import 'package:finance_buddy_app/data/db.dart';
import 'package:finance_buddy_app/providers/database_providers.dart';
import 'package:finance_buddy_app/providers/notification_providers.dart';
import 'package:finance_buddy_app/pages/onboarding_v2/currency_selection_screen.dart';

/// Bottom sheet showing recent notifications and notification settings.
class NotificationSheet extends ConsumerStatefulWidget {
  const NotificationSheet({super.key});

  @override
  ConsumerState<NotificationSheet> createState() => _NotificationSheetState();
}

class _NotificationSheetState extends ConsumerState<NotificationSheet> {
  Timer? _autoMarkTimer;

  @override
  void initState() {
    super.initState();
    // Auto-mark all as read after 3 seconds
    _autoMarkTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        ref.read(repositoryProvider).markAllRead();
      }
    });
  }

  @override
  void dispose() {
    _autoMarkTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(notifPrefsProvider);
    final recentAsync = ref.watch(recentNotificationsProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
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
              // Header with mark all read
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('COINFLO', style: AppTextStyles.labelM.copyWith(
                    color: AppColors.gray400,
                    letterSpacing: 1.5,
                  )),
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

              // --- Section 1: Recent notifications ---
              Text(
                'RECENT',
                style: AppTextStyles.labelM.copyWith(
                  color: AppColors.gray400,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),

              recentAsync.when(
                data: (notifications) {
                  if (notifications.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: AppSpacing.xl,
                      ),
                      child: Center(
                        child: Text(
                          'No notifications yet',
                          style: TextStyle(
                            color: AppColors.gray400,
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
                error: (_, _) => const SizedBox.shrink(),
              ),

              const SizedBox(height: AppSpacing.xl),
              const Divider(color: AppColors.gray200, height: 1),
              const SizedBox(height: AppSpacing.md),

              // --- Section 2: Settings ---
              Text(
                'SETTINGS',
                style: AppTextStyles.labelM.copyWith(
                  color: AppColors.gray400,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),

              _ToggleRow(
                icon: PhosphorIcons.bell(),
                title: 'Transaction alerts',
                subtitle: 'When 3+ transactions pile up',
                value: prefs.txnAlerts,
                onChanged: (v) =>
                    ref.read(notifPrefsProvider.notifier).setTxnAlerts(v),
              ),
              const SizedBox(height: AppSpacing.xs),
              _ToggleRow(
                icon: PhosphorIcons.moon(),
                title: 'Evening check-in',
                subtitle:
                    '${_formatTime(prefs.checkinHour, prefs.checkinMinute)} if your queue isn\'t cleared',
                value: prefs.eveningCheckin,
                onChanged: (v) =>
                    ref.read(notifPrefsProvider.notifier).setEveningCheckin(v),
              ),
              const SizedBox(height: AppSpacing.xs),
              _ToggleRow(
                icon: PhosphorIcons.calendarCheck(),
                title: 'Sunday digest',
                subtitle: 'Weekly mirror at 7pm',
                value: prefs.sundayDigest,
                onChanged: (v) =>
                    ref.read(notifPrefsProvider.notifier).setSundayDigest(v),
              ),

              const SizedBox(height: AppSpacing.md),
              const Divider(color: AppColors.gray200, height: 1),
              const SizedBox(height: AppSpacing.md),

              // --- Check-in time ---
              GestureDetector(
                onTap: () => _pickTime(context, ref, prefs),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      PhosphorIcon(
                        PhosphorIcons.clock(),
                        color: AppColors.gray500,
                        size: 20,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'Check-in time: ${_formatTime(prefs.checkinHour, prefs.checkinMinute)}',
                          style: const TextStyle(
                            color: AppColors.black,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      PhosphorIcon(
                        PhosphorIcons.caretRight(),
                        color: AppColors.gray400,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(color: AppColors.gray200, height: 1),
              const SizedBox(height: AppSpacing.md),

              // --- How it works ---
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const CurrencySelectionScreen(),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      PhosphorIcon(
                        PhosphorIcons.question(),
                        color: AppColors.gray500,
                        size: 20,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      const Expanded(
                        child: Text(
                          'How CoinFlo works',
                          style: TextStyle(
                            color: AppColors.black,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      PhosphorIcon(
                        PhosphorIcons.caretRight(),
                        color: AppColors.gray400,
                        size: 18,
                      ),
                    ],
                  ),
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

  Future<void> _pickTime(
    BuildContext context,
    WidgetRef ref,
    NotifPrefs prefs,
  ) async {
    final picked = await showTimePicker(
      context: context,
      initialTime:
          TimeOfDay(hour: prefs.checkinHour, minute: prefs.checkinMinute),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: const TimePickerThemeData(
              backgroundColor: AppColors.white,
              hourMinuteTextColor: AppColors.black,
              dialHandColor: AppColors.black,
              dialBackgroundColor: AppColors.white,
            ),
          ),
          child: child!,
        );
      },
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.xs),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: notification.isRead
              ? null
              : const Border(
                  left: BorderSide(color: AppColors.orange, width: 3),
                ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PhosphorIcon(
              _iconForType(notification.type),
              color: _colorForType(notification.type),
              size: 20,
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
                color: AppColors.gray400,
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
        return const Color(0xFF8B5CF6); // purple accent
      case 'digest':
        return const Color(0xFF3B82F6); // blue accent
      default:
        return AppColors.gray500;
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
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          PhosphorIcon(icon, color: AppColors.gray500, size: 20),
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
                    color: AppColors.gray400,
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
            inactiveThumbColor: AppColors.gray400,
          ),
        ],
      ),
    );
  }
}
