import 'package:finance_buddy_app/data/db.dart';

abstract class NotificationRepository {
  Stream<List<AppNotification>> watchUnread();
  Stream<List<AppNotification>> watchRecent(int days);
  Future<int> insertNotification(AppNotificationsCompanion entry);
  Future<void> markAllRead();
  Future<void> markRead(int id);
  Future<void> purgeOlderThan(int days);
  Future<int> getUnreadCount();
}
