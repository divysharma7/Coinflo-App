/// Routes user input to either the QUERY pipeline (read) or
/// the ENTRY pipeline (write).
enum SaraswatiRoute { question, entry, ambiguous }

/// Classifies whether user input is a question about data
/// or a transaction entry attempt.
class SaraswatiRouter {
  const SaraswatiRouter();

  /// Transaction verbs that signal an entry.
  static const _entryVerbs = {
    'paid', 'spent', 'bought', 'gave', 'transferred', 'sent',
    'received', 'deposited', 'withdrew', 'split', 'owe', 'lent',
    'diye', 'bheje', 'mila', 'liya', // Hindi verbs
  };

  /// Question signals.
  static const _questionStarts = {
    'how', 'what', 'when', 'where', 'why', 'which',
    'show', 'tell', 'kitna', 'kaise', 'kab', 'kahan',
  };

  static const _questionPhrases = {
    'show me', 'tell me', 'kitna', 'kaise', 'how much',
    'how many', 'compare', 'vs', 'breakdown', 'average',
    'total', 'top', 'biggest', 'category',
  };

  static final _hasNumber = RegExp(r'\d');

  /// Classify [normalized] input as question, entry, or ambiguous.
  SaraswatiRoute classify(String normalized) {
    if (normalized.isEmpty) return SaraswatiRoute.question;

    final isQuestion = _looksLikeQuestion(normalized);
    final isEntry = _looksLikeEntry(normalized);

    if (isEntry && !isQuestion) return SaraswatiRoute.entry;
    if (isQuestion && !isEntry) return SaraswatiRoute.question;
    if (isEntry && isQuestion) return SaraswatiRoute.ambiguous;

    // Neither signal: default to ambiguous (let both pipelines try).
    return SaraswatiRoute.ambiguous;
  }

  bool _looksLikeEntry(String q) {
    // Must contain a number AND a transaction verb.
    if (!_hasNumber.hasMatch(q)) return false;
    final words = q.split(' ');
    return words.any((w) => _entryVerbs.contains(w)) ||
        // Also match bare "<number> <keyword>" patterns (quickadd style).
        (words.length >= 2 && RegExp(r'^\d').hasMatch(words.first));
  }

  bool _looksLikeQuestion(String q) {
    // Ends with question mark.
    if (q.endsWith('?')) return true;

    // Starts with question word.
    final firstWord = q.split(' ').first;
    if (_questionStarts.contains(firstWord)) return true;

    // Contains question phrase.
    return _questionPhrases.any((p) => q.contains(p));
  }
}
