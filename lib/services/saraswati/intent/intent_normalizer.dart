/// Normalizes user queries for consistent matching and caching.
///
/// Lowercase, trim, collapse runs of whitespace to a single space.
class IntentNormalizer {
  const IntentNormalizer._();

  static final _whitespace = RegExp(r'\s+');

  static String normalize(String raw) {
    return raw.trim().toLowerCase().replaceAll(_whitespace, ' ');
  }
}
