class AppConstants {
  AppConstants._();

  static const String appName = 'Spendler';
  static const String tagline = 'Feel your financial rhythm.';

  // Notification channel
  static const String notificationChannelId = 'pulse_reminders';
  static const String notificationChannelName = 'Spendler Reminders';
  static const String notificationChannelDescription = 'Transaction alerts and weekly digests';

  // Notification IDs
  static const int notifTransactionDetectedBase = 1000;
  static const int notifEveningCheckin = 200;
  static const int notifSundayDigest = 300;

  // Defaults
  static const int eveningCheckinHour = 21;
  static const int eveningCheckinMinute = 0;
  static const int sundayDigestHour = 19;
  static const int sundayDigestMinute = 0;

  // SMS batch threshold
  static const int smsBatchThreshold = 3;
}
