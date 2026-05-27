import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:finance_buddy_app/core/constants.dart';
import 'package:finance_buddy_app/data/db.dart';
import 'package:finance_buddy_app/providers/database_providers.dart';
import 'package:finance_buddy_app/services/notifications/notification_scheduler.dart';
import 'package:finance_buddy_app/services/notifications/notification_service.dart';

// ---------------------------------------------------------------------------
// Stream / derived providers
// ---------------------------------------------------------------------------

/// Watches the unread notification count from the database.
final unreadNotifCountProvider = StreamProvider<int>((ref) {
  final repo = ref.watch(repositoryProvider);
  return repo.watchUnread().map((list) => list.length);
});

/// Whether the notification dot should show on the bell.
final hasUnreadNotifProvider = Provider<bool>((ref) {
  final asyncCount = ref.watch(unreadNotifCountProvider);
  return asyncCount.maybeWhen(data: (count) => count > 0, orElse: () => false);
});

/// Watches last 7 days of notifications for the notification sheet.
final recentNotificationsProvider =
    StreamProvider<List<AppNotification>>((ref) {
  final repo = ref.watch(repositoryProvider);
  return repo.watchRecent(7);
});

// ---------------------------------------------------------------------------
// Notification preferences
// ---------------------------------------------------------------------------

class NotifPrefs {
  final bool txnAlerts;
  final bool eveningCheckin;
  final bool sundayDigest;
  final bool subscriptionAlerts;
  final int checkinHour;
  final int checkinMinute;

  const NotifPrefs({
    this.txnAlerts = true,
    this.eveningCheckin = true,
    this.sundayDigest = true,
    this.subscriptionAlerts = true,
    this.checkinHour = 21,
    this.checkinMinute = 0,
  });

  NotifPrefs copyWith({
    bool? txnAlerts,
    bool? eveningCheckin,
    bool? sundayDigest,
    bool? subscriptionAlerts,
    int? checkinHour,
    int? checkinMinute,
  }) {
    return NotifPrefs(
      txnAlerts: txnAlerts ?? this.txnAlerts,
      eveningCheckin: eveningCheckin ?? this.eveningCheckin,
      sundayDigest: sundayDigest ?? this.sundayDigest,
      subscriptionAlerts: subscriptionAlerts ?? this.subscriptionAlerts,
      checkinHour: checkinHour ?? this.checkinHour,
      checkinMinute: checkinMinute ?? this.checkinMinute,
    );
  }
}

class NotifPrefsNotifier extends StateNotifier<NotifPrefs> {
  NotifPrefsNotifier(this._notifService) : super(const NotifPrefs()) {
    _load();
  }

  final NotificationService _notifService;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = NotifPrefs(
      txnAlerts: prefs.getBool('notif_txn') ?? true,
      eveningCheckin: prefs.getBool('notif_evening') ?? true,
      sundayDigest: prefs.getBool('notif_sunday') ?? true,
      subscriptionAlerts: prefs.getBool('notif_subscription') ?? true,
      checkinHour: prefs.getInt('notif_hour') ?? 21,
      checkinMinute: prefs.getInt('notif_minute') ?? 0,
    );
  }

  Future<void> setTxnAlerts(bool v) async {
    state = state.copyWith(txnAlerts: v);
    await (await SharedPreferences.getInstance()).setBool('notif_txn', v);
  }

  Future<void> setEveningCheckin(bool v) async {
    state = state.copyWith(eveningCheckin: v);
    await (await SharedPreferences.getInstance()).setBool('notif_evening', v);
    if (!v) {
      await _notifService.cancel(AppConstants.notifEveningCheckin);
    }
  }

  Future<void> setSundayDigest(bool v) async {
    state = state.copyWith(sundayDigest: v);
    await (await SharedPreferences.getInstance()).setBool('notif_sunday', v);
    if (!v) {
      await _notifService.cancel(AppConstants.notifSundayDigest);
    }
  }

  Future<void> setSubscriptionAlerts(bool v) async {
    state = state.copyWith(subscriptionAlerts: v);
    await (await SharedPreferences.getInstance())
        .setBool('notif_subscription', v);
  }

  Future<void> setCheckinTime(int hour, int minute) async {
    state = state.copyWith(checkinHour: hour, checkinMinute: minute);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('notif_hour', hour);
    await prefs.setInt('notif_minute', minute);
  }
}

final notifPrefsProvider =
    StateNotifierProvider<NotifPrefsNotifier, NotifPrefs>(
  (ref) => NotifPrefsNotifier(NotificationService()),
);

// ---------------------------------------------------------------------------
// Scheduler bootstrap — reads prefs, registers OS notifications accordingly
// ---------------------------------------------------------------------------

final notifSchedulerProvider = FutureProvider<void>((ref) async {
  final repo = ref.watch(repositoryProvider);
  final prefs = ref.watch(notifPrefsProvider);
  final scheduler = NotificationScheduler(NotificationService(), repo);

  if (prefs.eveningCheckin) {
    await scheduler.scheduleEveningCheckin(
      hour: prefs.checkinHour,
      minute: prefs.checkinMinute,
    );
  }
  if (prefs.sundayDigest) {
    await scheduler.scheduleSundayDigest();
  }
  if (prefs.subscriptionAlerts) {
    await scheduler.checkUpcomingSubscriptions();
  }
});
