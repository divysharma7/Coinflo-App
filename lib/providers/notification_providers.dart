import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:finance_buddy_app/data/db.dart';
import 'package:finance_buddy_app/providers/database_providers.dart';

/// Watches the unread notification count from the database.
final unreadNotifCountProvider = StreamProvider<int>((ref) {
  final repo = ref.watch(repositoryProvider);
  return repo.watchUnread().map((list) => list.length);
});

/// Whether the notification dot should show on the bell.
/// Derived from the stream — true when unread count > 0.
final hasUnreadNotifProvider = Provider<bool>((ref) {
  final asyncCount = ref.watch(unreadNotifCountProvider);
  return asyncCount.maybeWhen(data: (count) => count > 0, orElse: () => false);
});

/// Watches last 7 days of notifications for the notification sheet.
final recentNotificationsProvider = StreamProvider<List<AppNotification>>((ref) {
  final repo = ref.watch(repositoryProvider);
  return repo.watchRecent(7);
});

/// Notification toggle states persisted in SharedPreferences.
class NotifPrefs {
  final bool txnAlerts;
  final bool eveningCheckin;
  final bool sundayDigest;
  final int checkinHour;
  final int checkinMinute;

  const NotifPrefs({
    this.txnAlerts = true,
    this.eveningCheckin = true,
    this.sundayDigest = true,
    this.checkinHour = 21,
    this.checkinMinute = 0,
  });

  NotifPrefs copyWith({
    bool? txnAlerts,
    bool? eveningCheckin,
    bool? sundayDigest,
    int? checkinHour,
    int? checkinMinute,
  }) {
    return NotifPrefs(
      txnAlerts: txnAlerts ?? this.txnAlerts,
      eveningCheckin: eveningCheckin ?? this.eveningCheckin,
      sundayDigest: sundayDigest ?? this.sundayDigest,
      checkinHour: checkinHour ?? this.checkinHour,
      checkinMinute: checkinMinute ?? this.checkinMinute,
    );
  }
}

class NotifPrefsNotifier extends StateNotifier<NotifPrefs> {
  NotifPrefsNotifier() : super(const NotifPrefs()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = NotifPrefs(
      txnAlerts: prefs.getBool('notif_txn') ?? true,
      eveningCheckin: prefs.getBool('notif_evening') ?? true,
      sundayDigest: prefs.getBool('notif_sunday') ?? true,
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
  }

  Future<void> setSundayDigest(bool v) async {
    state = state.copyWith(sundayDigest: v);
    await (await SharedPreferences.getInstance()).setBool('notif_sunday', v);
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
  (ref) => NotifPrefsNotifier(),
);
