import 'package:flutter_riverpod/flutter_riverpod.dart';

final selectedTabProvider = StateProvider<int>((ref) => 0);

final selectedWeekProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  return today.subtract(Duration(days: today.weekday - 1)); // Monday
});
