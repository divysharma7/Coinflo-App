class AppConstants {
  AppConstants._();

  static const String appName = 'CoinFlo';
  static const String tagline = 'Track your spending habits.';

  // Notification channel
  static const String notificationChannelId = 'coinflo_reminders';
  static const String notificationChannelName = 'CoinFlo Reminders';
  static const String notificationChannelDescription = 'Transaction alerts and weekly digests';

  // Notification IDs
  static const int notifEveningCheckin = 200;
  static const int notifSundayDigest = 300;

  // Defaults
  static const int eveningCheckinHour = 21;
  static const int eveningCheckinMinute = 0;
  static const int sundayDigestHour = 19;
  static const int sundayDigestMinute = 0;

  // Subscription renewal reminders
  /// How many days before a subscription's billing date to remind (default).
  static const int subscriptionWarningDaysDefault = 3;
  /// Hour of day (local) at which subscription reminders fire.
  static const int subscriptionReminderHour = 9;
}
