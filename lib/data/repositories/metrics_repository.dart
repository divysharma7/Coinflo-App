abstract class MetricsRepository {
  Future<void> recordMetric(String metricType, {String? metadata});
  Future<int> getAppOpensThisWeek();
  Future<int> getRetrospectionSessionsThisWeek();
}
