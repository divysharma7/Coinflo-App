import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:finance_buddy_app/core/tokens.dart';
import 'package:finance_buddy_app/data/db.dart';
import 'package:finance_buddy_app/providers/database_providers.dart';
import 'package:finance_buddy_app/providers/notification_providers.dart';
import 'package:finance_buddy_app/pages/onboarding/onboarding_page.dart';

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
            left: PaisaSpacing.screenH,
            right: PaisaSpacing.screenH,
            bottom: MediaQuery.viewInsetsOf(context).bottom + PaisaSpacing.lg,
          ),
          child: ListView(
            controller: scrollController,
            children: [
              // Header with mark all read
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('PULSE', style: PaisaTextStyles.sectionLabel),
                  GestureDetector(
                    onTap: () => ref.read(repositoryProvider).markAllRead(),
                    child: const Text(
                      'Mark all read',
                      style: TextStyle(
                        color: PaisaColors.yellow,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: PaisaSpacing.md),

              // ─── Section 1: Recent notifications ────────────
              const Text(
                'RECENT',
                style: PaisaTextStyles.sectionLabel,
              ),
              const SizedBox(height: PaisaSpacing.sm),

              recentAsync.when(
                data: (notifications) {
                  if (notifications.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: PaisaSpacing.xl,
                      ),
                      child: Center(
                        child: Text(
                          'No notifications yet',
                          style: TextStyle(
                            color: PaisaColors.textTertiary,
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
                  padding: EdgeInsets.symmetric(vertical: PaisaSpacing.xl),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: PaisaColors.yellow,
                      strokeWidth: 2,
                    ),
                  ),
                ),
                error: (_, _) => const SizedBox.shrink(),
              ),

              const SizedBox(height: PaisaSpacing.lg),
              const Divider(color: PaisaColors.border, height: 1),
              const SizedBox(height: PaisaSpacing.md),

              // ─── Section 2: Settings ────────────────────────
              const Text(
                'SETTINGS',
                style: PaisaTextStyles.sectionLabel,
              ),
              const SizedBox(height: PaisaSpacing.sm),

              _ToggleRow(
                icon: PhosphorIcons.bell(),
                title: 'Transaction alerts',
                subtitle: 'When 3+ transactions pile up',
                value: prefs.txnAlerts,
                onChanged: (v) =>
                    ref.read(notifPrefsProvider.notifier).setTxnAlerts(v),
              ),
              const SizedBox(height: PaisaSpacing.sm),
              _ToggleRow(
                icon: PhosphorIcons.moon(),
                title: 'Evening check-in',
                subtitle:
                    '${_formatTime(prefs.checkinHour, prefs.checkinMinute)} if your queue isn\'t cleared',
                value: prefs.eveningCheckin,
                onChanged: (v) =>
                    ref.read(notifPrefsProvider.notifier).setEveningCheckin(v),
              ),
              const SizedBox(height: PaisaSpacing.sm),
              _ToggleRow(
                icon: PhosphorIcons.calendarCheck(),
                title: 'Sunday digest',
                subtitle: 'Weekly mirror at 7pm',
                value: prefs.sundayDigest,
                onChanged: (v) =>
                    ref.read(notifPrefsProvider.notifier).setSundayDigest(v),
              ),

              const SizedBox(height: PaisaSpacing.md),
              const Divider(color: PaisaColors.border, height: 1),
              const SizedBox(height: PaisaSpacing.md),

              // --- Check-in time ---
              GestureDetector(
                onTap: () => _pickTime(context, ref, prefs),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: PaisaSpacing.md,
                    vertical: PaisaSpacing.cardGap,
                  ),
                  decoration: BoxDecoration(
                    color: PaisaColors.surface,
                    borderRadius: BorderRadius.circular(PaisaRadii.button),
                  ),
                  child: Row(
                    children: [
                      PhosphorIcon(
                        PhosphorIcons.clock(),
                        color: PaisaColors.textSecondary,
                        size: 20,
                      ),
                      const SizedBox(width: PaisaSpacing.cardGap),
                      Expanded(
                        child: Text(
                          'Check-in time: ${_formatTime(prefs.checkinHour, prefs.checkinMinute)}',
                          style: const TextStyle(
                            color: PaisaColors.textPrimary,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      PhosphorIcon(
                        PhosphorIcons.caretRight(),
                        color: PaisaColors.textTertiary,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(color: PaisaColors.border, height: 1),
              const SizedBox(height: PaisaSpacing.md),

              // --- How it works ---
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const OnboardingPage(isGuideMode: true),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: PaisaSpacing.md,
                    vertical: PaisaSpacing.cardGap,
                  ),
                  decoration: BoxDecoration(
                    color: PaisaColors.surface,
                    borderRadius: BorderRadius.circular(PaisaRadii.button),
                  ),
                  child: Row(
                    children: [
                      PhosphorIcon(
                        PhosphorIcons.question(),
                        color: PaisaColors.textSecondary,
                        size: 20,
                      ),
                      const SizedBox(width: PaisaSpacing.cardGap),
                      const Expanded(
                        child: Text(
                          'How Pulse works',
                          style: TextStyle(
                            color: PaisaColors.textPrimary,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      PhosphorIcon(
                        PhosphorIcons.caretRight(),
                        color: PaisaColors.textTertiary,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: PaisaSpacing.md),
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
              backgroundColor: PaisaColors.surfaceHigh,
              hourMinuteTextColor: PaisaColors.textPrimary,
              dialHandColor: PaisaColors.yellow,
              dialBackgroundColor: PaisaColors.surface,
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

// ─── Notification row ───────────────────────────────────

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
        margin: const EdgeInsets.only(bottom: PaisaSpacing.sm),
        padding: const EdgeInsets.symmetric(
          horizontal: PaisaSpacing.md,
          vertical: PaisaSpacing.cardGap,
        ),
        decoration: BoxDecoration(
          color: PaisaColors.surface,
          borderRadius: BorderRadius.circular(PaisaRadii.button),
          border: notification.isRead
              ? null
              : const Border(
                  left: BorderSide(color: PaisaColors.amber, width: 3),
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
            const SizedBox(width: PaisaSpacing.cardGap),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: TextStyle(
                      color: PaisaColors.textPrimary,
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
                      color: PaisaColors.textSecondary,
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: PaisaSpacing.sm),
            Text(
              _relativeTime(notification.sentAt),
              style: const TextStyle(
                color: PaisaColors.textTertiary,
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
        return PaisaColors.yellow;
      case 'checkin':
        return PaisaColors.accentPurple;
      case 'digest':
        return PaisaColors.accentBlue;
      default:
        return PaisaColors.textSecondary;
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

// ─── Toggle row (settings) ──────────────────────────────

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
        horizontal: PaisaSpacing.md,
        vertical: PaisaSpacing.cardGap,
      ),
      decoration: BoxDecoration(
        color: PaisaColors.surface,
        borderRadius: BorderRadius.circular(PaisaRadii.button),
      ),
      child: Row(
        children: [
          PhosphorIcon(icon, color: PaisaColors.textSecondary, size: 20),
          const SizedBox(width: PaisaSpacing.cardGap),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: PaisaColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: PaisaColors.textTertiary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeThumbColor: PaisaColors.yellow,
            activeTrackColor: PaisaColors.yellow.withValues(alpha: 0.3),
            inactiveTrackColor: PaisaColors.border,
            inactiveThumbColor: PaisaColors.textTertiary,
          ),
        ],
      ),
    );
  }
}
