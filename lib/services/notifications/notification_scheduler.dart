import 'package:finance_buddy_app/core/constants.dart';
import 'package:finance_buddy_app/core/enums.dart';
import 'package:finance_buddy_app/data/db.dart';
import 'package:finance_buddy_app/data/repositories/base_repository.dart';
import 'package:finance_buddy_app/services/insight/insight_generator.dart';
import 'package:finance_buddy_app/services/notifications/notification_service.dart';
import 'package:intl/intl.dart';

class NotificationScheduler {
  final NotificationService _notifService;
  final BaseRepository _repository;

  NotificationScheduler(this._notifService, this._repository);

  /// Base notification ID for subscription reminders.
  /// Each subscription gets its own ID offset from this base.
  static const _notifSubscriptionBase = 400;

  /// Schedule the evening check-in at the user's preferred time.
  ///
  /// Only fires when there are unconfirmed transactions in the queue.
  /// Skips silently on clean days so the user isn't nagged.
  Future<void> scheduleEveningCheckin({
    int hour = AppConstants.eveningCheckinHour,
    int minute = AppConstants.eveningCheckinMinute,
  }) async {
    // Cancel previous schedule before re-registering at new time.
    await _notifService.cancel(AppConstants.notifEveningCheckin);

    final unconfirmed = await _repository.getUnconfirmedCount();
    if (unconfirmed == 0) return;

    final copyText = unconfirmed == 1
        ? '1 transaction waiting — takes a few seconds.'
        : '$unconfirmed transactions waiting — takes a minute.';

    await _notifService.scheduleDailyReminder(
      AppConstants.notifEveningCheckin,
      'CoinFlo',
      copyText,
      hour,
      minute,
    );
    await _repository.insertNotification(AppNotificationsCompanion.insert(
      type: 'checkin',
      title: 'CoinFlo',
      body: copyText,
    ));
  }

  /// Schedule the Sunday weekly digest at 7 PM with real spending data.
  Future<void> scheduleSundayDigest() async {
    await _notifService.cancel(AppConstants.notifSundayDigest);

    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final totalSpent = await _repository.getTotalSpentForWeek(weekStart);
    final merchantCounts =
        await _repository.getTopMerchantCountsForWeek(weekStart);

    // Build category totals for the week.
    final txns = await _repository.watchTransactionsForWeek(weekStart).first;
    final catTotals = <TransactionCategory, double>{};
    for (final t in txns) {
      if (t.amount < 0) {
        final cat = TransactionCategory.values.firstWhere(
          (c) => c.name == t.category,
          orElse: () => TransactionCategory.other,
        );
        catTotals[cat] = (catTotals[cat] ?? 0) + t.amount.abs();
      }
    }
    final sortedCats = catTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final insight = generateWeeklyInsight(
      sortedCats: sortedCats,
      totalSpent: totalSpent,
      merchantCounts: merchantCounts,
    );

    await _notifService.scheduleWeeklyReminder(
      AppConstants.notifSundayDigest,
      'Your Weekly Rhythm',
      insight,
      DateTime.sunday,
      AppConstants.sundayDigestHour,
      AppConstants.sundayDigestMinute,
    );
    await _repository.insertNotification(AppNotificationsCompanion.insert(
      type: 'digest',
      title: 'Your Weekly Rhythm',
      body: insight,
    ));
  }

  /// Check active subscriptions and fire a notification for any whose
  /// [nextBillingDate] is tomorrow.
  Future<void> checkUpcomingSubscriptions() async {
    final subs = await _repository.watchActiveSubscriptions().first;
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
        await _repository.insertNotification(AppNotificationsCompanion.insert(
          type: 'subscription',
          title: title,
          body: body,
        ));
      }
    }
  }

  /// Set up all recurring notifications.
  ///
  /// [checkinHour] and [checkinMinute] come from user preferences so the
  /// schedule matches what they chose in the notification sheet.
  Future<void> setupAll({
    int checkinHour = AppConstants.eveningCheckinHour,
    int checkinMinute = AppConstants.eveningCheckinMinute,
  }) async {
    await scheduleEveningCheckin(hour: checkinHour, minute: checkinMinute);
    await scheduleSundayDigest();
    await checkUpcomingSubscriptions();
  }
}
