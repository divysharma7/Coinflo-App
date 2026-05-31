/// Normalizes raw entry input for consistent matching and caching.
///
/// Mirrors [IntentNormalizer] from the query pipeline.
class EntryNormalizer {
  EntryNormalizer._();

  /// Lowercase, trim, collapse whitespace.
  static String normalize(String raw) =>
      raw.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
}
