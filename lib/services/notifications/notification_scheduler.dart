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

  /// Schedule a renewal reminder for every active subscription, [warningDays]
  /// before its [nextBillingDate].
  ///
  /// Uses [NotificationService.scheduleOneTime] (zonedSchedule) so the reminder
  /// fires on the right day even if the app isn't open \u2014 replacing the old
  /// behaviour that only fired when the app happened to be running the day
  /// before. The matching in-app bell row is inserted once we're inside the
  /// reminder window, de-duplicated so repeated app opens don't spam the bell.
  Future<void> checkUpcomingSubscriptions({
    int warningDays = AppConstants.subscriptionWarningDaysDefault,
  }) async {
    final subs = await _repository.watchActiveSubscriptions().first;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final currencyFmt = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '\u20B9',
      decimalDigits: 0,
    );

    for (final sub in subs) {
      final notifId = _notifSubscriptionBase + sub.id;
      // Always clear any stale schedule first so date/amount edits re-register.
      await _notifService.cancel(notifId);

      final billingDay = DateTime(
        sub.nextBillingDate.year,
        sub.nextBillingDate.month,
        sub.nextBillingDate.day,
      );
      if (billingDay.isBefore(today)) continue; // already past

      final reminderDay = billingDay.subtract(Duration(days: warningDays));
      // If the reminder window has already opened, fire today; otherwise on the
      // reminder day. Either way the OS owns the schedule.
      final fireDay = reminderDay.isBefore(today) ? today : reminderDay;
      final fireAt = DateTime(
        fireDay.year,
        fireDay.month,
        fireDay.day,
        AppConstants.subscriptionReminderHour,
      );

      final daysAway = billingDay.difference(today).inDays;
      final whenPhrase = daysAway <= 0
          ? 'today'
          : daysAway == 1
              ? 'tomorrow'
              : 'in $daysAway days';
      const title = 'Upcoming Bill';
      final body =
          '${sub.name} bill of ${currencyFmt.format(sub.amount)} is due $whenPhrase';

      await _notifService.scheduleOneTime(notifId, title, body, fireAt);

      // Reflect in the in-app bell once inside the reminder window, but skip if
      // an identical subscription notification already exists recently.
      if (!today.isBefore(reminderDay)) {
        final recent = await _repository.watchRecent(warningDays + 1).first;
        final alreadyLogged = recent
            .any((n) => n.type == 'subscription' && n.body == body);
        if (!alreadyLogged) {
          await _repository.insertNotification(AppNotificationsCompanion.insert(
            type: 'subscription',
            title: title,
            body: body,
          ));
        }
      }
    }
  }

  /// Cancel every scheduled subscription reminder. Called when the user turns
  /// subscription alerts off so already-registered OS notifications stop firing.
  Future<void> cancelSubscriptionReminders() async {
    final subs = await _repository.watchActiveSubscriptions().first;
    for (final sub in subs) {
      await _notifService.cancel(_notifSubscriptionBase + sub.id);
    }
  }

  /// Set up all recurring notifications.
  ///
  /// [checkinHour] and [checkinMinute] come from user preferences so the
  /// schedule matches what they chose in the notification sheet.
  Future<void> setupAll({
    int checkinHour = AppConstants.eveningCheckinHour,
    int checkinMinute = AppConstants.eveningCheckinMinute,
    int subscriptionWarningDays = AppConstants.subscriptionWarningDaysDefault,
  }) async {
    await scheduleEveningCheckin(hour: checkinHour, minute: checkinMinute);
    await scheduleSundayDigest();
    await checkUpcomingSubscriptions(warningDays: subscriptionWarningDays);
  }
}
