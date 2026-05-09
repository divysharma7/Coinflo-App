import 'package:drift/drift.dart';
import 'package:finance_buddy_app/data/db.dart';
import 'package:finance_buddy_app/data/repositories/metrics_repository.dart';

class LocalMetricsRepository implements MetricsRepository {
  final SpendlerDatabase db;

  LocalMetricsRepository(this.db);

  @override
  Future<void> recordMetric(String metricType, {String? metadata}) {
    return db.into(db.appMetrics).insert(AppMetricsCompanion.insert(
      metricType: metricType,
      metadata: Value(metadata),
    ));
  }

  @override
  Future<int> getAppOpensThisWeek() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final monday = today.subtract(Duration(days: today.weekday - 1));
    final result = await (db.select(db.appMetrics)
          ..where((m) =>
              m.metricType.equals('app_open') &
              m.recordedAt.isBiggerOrEqualValue(monday)))
        .get();
    return result.length;
  }

  @override
  Future<int> getRetrospectionSessionsThisWeek() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final monday = today.subtract(Duration(days: today.weekday - 1));
    final result = await (db.select(db.appMetrics)
          ..where((m) =>
              m.metricType.equals('retrospection') &
              m.recordedAt.isBiggerOrEqualValue(monday)))
        .get();
    return result.length;
  }
}
