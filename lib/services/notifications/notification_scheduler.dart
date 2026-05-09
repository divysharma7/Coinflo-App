import 'package:finance_buddy_app/core/constants.dart';
import 'package:finance_buddy_app/data/db.dart';
import 'package:finance_buddy_app/data/repositories/base_repository.dart';
import 'package:finance_buddy_app/services/notifications/notification_copy.dart';
import 'package:finance_buddy_app/services/notifications/notification_service.dart';

class NotificationScheduler {
  final NotificationService _notifService;
  final BaseRepository _repository;

  NotificationScheduler(this._notifService, this._repository);

  /// Schedule the evening check-in (9 PM daily).
  Future<void> scheduleEveningCheckin() async {
    const copyText =
        'Your day isn\'t done yet — a few transactions need a quick look.';
    await _notifService.scheduleDailyReminder(
      AppConstants.notifEveningCheckin,
      'Spendler',
      copyText,
      AppConstants.eveningCheckinHour,
      AppConstants.eveningCheckinMinute,
    );
    await _repository.insertNotification(AppNotificationsCompanion.insert(
      type: 'checkin',
      title: 'Spendler',
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

  /// Fire an immediate notification when unconfirmed transactions pile up.
  Future<void> checkAndNotifyBatch() async {
    final count = await _repository.getUnconfirmedCount();
    if (count >= AppConstants.smsBatchThreshold) {
      final copyText = NotificationCopy.transactionDetected(count);
      await _notifService.show(
        AppConstants.notifTransactionDetectedBase,
        'Spendler',
        copyText,
      );
      await _repository.insertNotification(AppNotificationsCompanion.insert(
        type: 'transaction',
        title: 'Spendler',
        body: copyText,
      ));
    }
  }

  /// Set up all recurring notifications.
  Future<void> setupAll() async {
    await scheduleEveningCheckin();
    await scheduleSundayDigest();
  }
}
