import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:finance_buddy_app/core/tokens.dart';
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
            left: SpendlerSpacing.screenH,
            right: SpendlerSpacing.screenH,
            bottom: MediaQuery.viewInsetsOf(context).bottom + SpendlerSpacing.lg,
          ),
          child: ListView(
            controller: scrollController,
            children: [
              // Header with mark all read
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('SPENDLER', style: SpendlerTextStyles.sectionLabel),
                  GestureDetector(
                    onTap: () => ref.read(repositoryProvider).markAllRead(),
                    child: const Text(
                      'Mark all read',
                      style: TextStyle(
                        color: SpendlerColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: SpendlerSpacing.md),

              // ─── Section 1: Recent notifications ────────────
              const Text(
                'RECENT',
                style: SpendlerTextStyles.sectionLabel,
              ),
              const SizedBox(height: SpendlerSpacing.sm),

              recentAsync.when(
                data: (notifications) {
                  if (notifications.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: SpendlerSpacing.xl,
                      ),
                      child: Center(
                        child: Text(
                          'No notifications yet',
                          style: TextStyle(
                            color: SpendlerColors.textTertiary,
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
                  padding: EdgeInsets.symmetric(vertical: SpendlerSpacing.xl),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: SpendlerColors.primary,
                      strokeWidth: 2,
                    ),
                  ),
                ),
                error: (_, _) => const SizedBox.shrink(),
              ),

              const SizedBox(height: SpendlerSpacing.lg),
              const Divider(color: SpendlerColors.border, height: 1),
              const SizedBox(height: SpendlerSpacing.md),

              // ─── Section 2: Settings ────────────────────────
              const Text(
                'SETTINGS',
                style: SpendlerTextStyles.sectionLabel,
              ),
              const SizedBox(height: SpendlerSpacing.sm),

              _ToggleRow(
                icon: PhosphorIcons.bell(),
                title: 'Transaction alerts',
                subtitle: 'When 3+ transactions pile up',
                value: prefs.txnAlerts,
                onChanged: (v) =>
                    ref.read(notifPrefsProvider.notifier).setTxnAlerts(v),
              ),
              const SizedBox(height: SpendlerSpacing.sm),
              _ToggleRow(
                icon: PhosphorIcons.moon(),
                title: 'Evening check-in',
                subtitle:
                    '${_formatTime(prefs.checkinHour, prefs.checkinMinute)} if your queue isn\'t cleared',
                value: prefs.eveningCheckin,
                onChanged: (v) =>
                    ref.read(notifPrefsProvider.notifier).setEveningCheckin(v),
              ),
              const SizedBox(height: SpendlerSpacing.sm),
              _ToggleRow(
                icon: PhosphorIcons.calendarCheck(),
                title: 'Sunday digest',
                subtitle: 'Weekly mirror at 7pm',
                value: prefs.sundayDigest,
                onChanged: (v) =>
                    ref.read(notifPrefsProvider.notifier).setSundayDigest(v),
              ),

              const SizedBox(height: SpendlerSpacing.md),
              const Divider(color: SpendlerColors.border, height: 1),
              const SizedBox(height: SpendlerSpacing.md),

              // --- Check-in time ---
              GestureDetector(
                onTap: () => _pickTime(context, ref, prefs),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: SpendlerSpacing.md,
                    vertical: SpendlerSpacing.cardGap,
                  ),
                  decoration: BoxDecoration(
                    color: SpendlerColors.surface,
                    borderRadius: BorderRadius.circular(SpendlerRadii.button),
                  ),
                  child: Row(
                    children: [
                      PhosphorIcon(
                        PhosphorIcons.clock(),
                        color: SpendlerColors.textSecondary,
                        size: 20,
                      ),
                      const SizedBox(width: SpendlerSpacing.cardGap),
                      Expanded(
                        child: Text(
                          'Check-in time: ${_formatTime(prefs.checkinHour, prefs.checkinMinute)}',
                          style: const TextStyle(
                            color: SpendlerColors.textPrimary,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      PhosphorIcon(
                        PhosphorIcons.caretRight(),
                        color: SpendlerColors.textTertiary,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(color: SpendlerColors.border, height: 1),
              const SizedBox(height: SpendlerSpacing.md),

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
                    horizontal: SpendlerSpacing.md,
                    vertical: SpendlerSpacing.cardGap,
                  ),
                  decoration: BoxDecoration(
                    color: SpendlerColors.surface,
                    borderRadius: BorderRadius.circular(SpendlerRadii.button),
                  ),
                  child: Row(
                    children: [
                      PhosphorIcon(
                        PhosphorIcons.question(),
                        color: SpendlerColors.textSecondary,
                        size: 20,
                      ),
                      const SizedBox(width: SpendlerSpacing.cardGap),
                      const Expanded(
                        child: Text(
                          'How Spendler works',
                          style: TextStyle(
                            color: SpendlerColors.textPrimary,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      PhosphorIcon(
                        PhosphorIcons.caretRight(),
                        color: SpendlerColors.textTertiary,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: SpendlerSpacing.md),
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
              backgroundColor: SpendlerColors.surfaceHigh,
              hourMinuteTextColor: SpendlerColors.textPrimary,
              dialHandColor: SpendlerColors.primary,
              dialBackgroundColor: SpendlerColors.surface,
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
        margin: const EdgeInsets.only(bottom: SpendlerSpacing.sm),
        padding: const EdgeInsets.symmetric(
          horizontal: SpendlerSpacing.md,
          vertical: SpendlerSpacing.cardGap,
        ),
        decoration: BoxDecoration(
          color: SpendlerColors.surface,
          borderRadius: BorderRadius.circular(SpendlerRadii.button),
          border: notification.isRead
              ? null
              : const Border(
                  left: BorderSide(color: SpendlerColors.warning, width: 3),
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
            const SizedBox(width: SpendlerSpacing.cardGap),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: TextStyle(
                      color: SpendlerColors.textPrimary,
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
                      color: SpendlerColors.textSecondary,
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: SpendlerSpacing.sm),
            Text(
              _relativeTime(notification.sentAt),
              style: const TextStyle(
                color: SpendlerColors.textTertiary,
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
        return SpendlerColors.primary;
      case 'checkin':
        return SpendlerColors.accentPurple;
      case 'digest':
        return SpendlerColors.accentBlue;
      default:
        return SpendlerColors.textSecondary;
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
        horizontal: SpendlerSpacing.md,
        vertical: SpendlerSpacing.cardGap,
      ),
      decoration: BoxDecoration(
        color: SpendlerColors.surface,
        borderRadius: BorderRadius.circular(SpendlerRadii.button),
      ),
      child: Row(
        children: [
          PhosphorIcon(icon, color: SpendlerColors.textSecondary, size: 20),
          const SizedBox(width: SpendlerSpacing.cardGap),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: SpendlerColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: SpendlerColors.textTertiary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeThumbColor: SpendlerColors.primary,
            activeTrackColor: SpendlerColors.primary.withValues(alpha: 0.3),
            inactiveTrackColor: SpendlerColors.border,
            inactiveThumbColor: SpendlerColors.textTertiary,
          ),
        ],
      ),
    );
  }
}
