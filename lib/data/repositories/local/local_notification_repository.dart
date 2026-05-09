import 'package:drift/drift.dart';
import 'package:finance_buddy_app/data/db.dart';
import 'package:finance_buddy_app/data/repositories/notification_repository.dart';

class LocalNotificationRepository implements NotificationRepository {
  final PaisaDatabase db;

  LocalNotificationRepository(this.db);

  @override
  Stream<List<AppNotification>> watchUnread() {
    return (db.select(db.appNotifications)
          ..where((n) => n.isRead.equals(false))
          ..orderBy([(n) => OrderingTerm.desc(n.sentAt)]))
        .watch();
  }

  @override
  Stream<List<AppNotification>> watchRecent(int days) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return (db.select(db.appNotifications)
          ..where((n) => n.sentAt.isBiggerOrEqualValue(cutoff))
          ..orderBy([(n) => OrderingTerm.desc(n.sentAt)]))
        .watch();
  }

  @override
  Future<int> insertNotification(AppNotificationsCompanion entry) {
    return db.into(db.appNotifications).insert(entry);
  }

  @override
  Future<void> markAllRead() {
    return (db.update(db.appNotifications)
          ..where((n) => n.isRead.equals(false)))
        .write(const AppNotificationsCompanion(isRead: Value(true)));
  }

  @override
  Future<void> markRead(int id) {
    return (db.update(db.appNotifications)..where((n) => n.id.equals(id)))
        .write(const AppNotificationsCompanion(isRead: Value(true)));
  }

  @override
  Future<void> purgeOlderThan(int days) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return (db.delete(db.appNotifications)
          ..where((n) => n.sentAt.isSmallerThanValue(cutoff)))
        .go();
  }

  @override
  Future<int> getUnreadCount() async {
    final result = await (db.select(db.appNotifications)
          ..where((n) => n.isRead.equals(false)))
        .get();
    return result.length;
  }
}
