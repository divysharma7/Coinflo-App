import 'package:flutter_riverpod/flutter_riverpod.dart';

final selectedTabProvider = StateProvider<int>((ref) => 0);

final selectedWeekProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  return today.subtract(Duration(days: today.weekday - 1)); // Monday
});

/// Selected month for the home screen period selector.
final selectedMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month);
});

/// Selected time period for Report page (0=Week, 1=Month, 2=Year)
final reportPeriodProvider = StateProvider<int>((ref) => 1);

/// Selected filter for Report page (0=Expenses, 1=Income, 2=Net)
final reportFilterProvider = StateProvider<int>((ref) => 0);
