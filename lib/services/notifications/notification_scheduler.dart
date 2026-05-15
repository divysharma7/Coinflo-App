import 'package:finance_buddy_app/core/constants.dart';
import 'package:finance_buddy_app/data/db.dart';
import 'package:finance_buddy_app/data/repositories/base_repository.dart';
import 'package:finance_buddy_app/services/notifications/notification_service.dart';
import 'package:intl/intl.dart';

class NotificationScheduler {
  final NotificationService _notifService;
  final BaseRepository _repository;

  NotificationScheduler(this._notifService, this._repository);

  /// Base notification ID for subscription reminders.
  /// Each subscription gets its own ID offset from this base.
  static const _notifSubscriptionBase = 400;

  /// Schedule the evening check-in (9 PM daily).
  Future<void> scheduleEveningCheckin() async {
    const copyText =
        'Your day isn\'t done yet — a few transactions need a quick look.';
    await _notifService.scheduleDailyReminder(
      AppConstants.notifEveningCheckin,
      'CoinFlo',
      copyText,
      AppConstants.eveningCheckinHour,
      AppConstants.eveningCheckinMinute,
    );
    await _repository.insertNotification(AppNotificationsCompanion.insert(
      type: 'checkin',
      title: 'CoinFlo',
      body: copyText,
    ));
  }

  /// Schedule the Sunday weekly digest (7 PM every Sunday).
  Future<void> scheduleSundayDigest() async {
    const copyText =
        'This week\'s spending summary is ready. See where it went.';
    await _notifService.scheduleWeeklyReminder(
      AppConstants.notifSundayDigest,
      'Your Weekly Rhythm',
      copyText,
      DateTime.sunday,
      AppConstants.sundayDigestHour,
      AppConstants.sundayDigestMinute,
    );
    await _repository.insertNotification(AppNotificationsCompanion.insert(
      type: 'digest',
      title: 'Your Weekly Rhythm',
      body: copyText,
    ));
  }

  /// Check active subscriptions and fire a notification for any whose
  /// [nextBillingDate] is tomorrow.
  Future<void> checkUpcomingSubscriptions(BaseRepository repo) async {
    final subs = await repo.watchActiveSubscriptions().first;
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);

    final currencyFmt = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '\u20B9',
      decimalDigits: 0,
    );

    for (var i = 0; i < subs.length; i++) {
      final sub = subs[i];
      final billingDay = DateTime(
        sub.nextBillingDate.year,
        sub.nextBillingDate.month,
        sub.nextBillingDate.day,
      );

      if (billingDay == tomorrow) {
        final title = 'Upcoming Bill';
        final body =
            '${sub.name} bill of ${currencyFmt.format(sub.amount)} is due tomorrow';
        final notifId = _notifSubscriptionBase + sub.id;

        await _notifService.show(notifId, title, body);
        await repo.insertNotification(AppNotificationsCompanion.insert(
          type: 'subscription',
          title: title,
          body: body,
        ));
      }
    }
  }

  /// Set up all recurring notifications.
  Future<void> setupAll() async {
    await scheduleEveningCheckin();
    await scheduleSundayDigest();
    await checkUpcomingSubscriptions(_repository);
  }
}
