/// Phases the import pipeline goes through.
enum ImportPhase { parsing, normalizing, categorizing, detectingRecurring, detectingAnomalies, persisting, complete, failed }

/// Progress event emitted by the orchestrator during import.
class ImportProgress {
  final ImportPhase phase;
  final int processed;
  final int total;
  final String? message;

  const ImportProgress({
    required this.phase,
    this.processed = 0,
    this.total = 0,
    this.message,
  });

  double get progress => total > 0 ? processed / total : 0.0;

  @override
  String toString() => 'ImportProgress($phase, $processed/$total)';
}
