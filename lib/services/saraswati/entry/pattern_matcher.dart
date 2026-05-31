import 'package:finance_buddy_app/services/saraswati/entry/transaction_draft.dart';

/// Stage 1: fuzzy pattern templates for shapes Stage 0 missed.
///
/// Still no LLM. Confidence = 0.90 for matched fields.
/// Returns `null` on no match.
class PatternMatcher {
  const PatternMatcher();

  static const _confidence = 0.90;

  /// Try all 5 templates in order. First match wins.
  TransactionDraft? match(String normalized) {
    return _matchPaidTo(normalized) ??
        _matchNamePaidMe(normalized) ??
        _matchNameOwesMe(normalized) ??
        _matchIOwe(normalized) ??
        _matchAmountFreeText(normalized);
  }

  // ─── Helpers ──────────────────────────────────────────

  static DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  // ─── Template 2: paid <amount> to <name> ──────────────
  static final _paidToRe = RegExp(
    r'^paid\s+(\d+(?:\.\d+)?)\s+to\s+(\w+)$',
  );

  TransactionDraft? _matchPaidTo(String q) {
    final m = _paidToRe.firstMatch(q);
    if (m == null) return null;
    final name = m.group(2)!;
    return TransactionDraft(
      kind: TransactionKind.transfer,
      amount: double.parse(m.group(1)!),
      counterparty: name[0].toUpperCase() + name.substring(1),
      date: _today(),
      source: 'pattern',
      fieldConfidence: {
        'amount': _confidence,
        'counterparty': _confidence,
        'date': _confidence,
      },
      rawInput: q,
    );
  }

  // ─── Template 3: <name> paid me <amount> ──────────────
  static final _namePaidMeRe = RegExp(
    r'^(\w+)\s+paid\s+me\s+(\d+(?:\.\d+)?)$',
  );

  TransactionDraft? _matchNamePaidMe(String q) {
    final m = _namePaidMeRe.firstMatch(q);
    if (m == null) return null;
    final name = m.group(1)!;
    return TransactionDraft(
      kind: TransactionKind.income,
      amount: double.parse(m.group(2)!),
      counterparty: name[0].toUpperCase() + name.substring(1),
      category: 'other',
      date: _today(),
      source: 'pattern',
      fieldConfidence: {
        'amount': _confidence,
        'counterparty': _confidence,
        'category': 0.80,
        'date': _confidence,
      },
      rawInput: q,
    );
  }

  // ─── Template 4: <name> owes me <amount> ──────────────
  static final _nameOwesMeRe = RegExp(
    r'^(\w+)\s+owes\s+me\s+(\d+(?:\.\d+)?)$',
  );

  TransactionDraft? _matchNameOwesMe(String q) {
    final m = _nameOwesMeRe.firstMatch(q);
    if (m == null) return null;
    final name = m.group(1)!;
    return TransactionDraft(
      kind: TransactionKind.split,
      amount: double.parse(m.group(2)!),
      counterparty: name[0].toUpperCase() + name.substring(1),
      date: _today(),
      payer: PayerKind.user,
      source: 'pattern',
      fieldConfidence: {
        'amount': _confidence,
        'counterparty': _confidence,
        'date': _confidence,
        'payer': 0.80, // could be full transfer or split
      },
      rawInput: q,
    );
  }

  // ─── Template 5: i owe <name> <amount> ────────────────
  static final _iOweRe = RegExp(
    r'^i\s+owe\s+(\w+)\s+(\d+(?:\.\d+)?)$',
  );

  TransactionDraft? _matchIOwe(String q) {
    final m = _iOweRe.firstMatch(q);
    if (m == null) return null;
    final name = m.group(1)!;
    return TransactionDraft(
      kind: TransactionKind.transfer,
      amount: double.parse(m.group(2)!),
      counterparty: name[0].toUpperCase() + name.substring(1),
      date: _today(),
      source: 'pattern',
      fieldConfidence: {
        'amount': _confidence,
        'counterparty': _confidence,
        'date': _confidence,
      },
      rawInput: q,
    );
  }

  // ─── Template 1: <amount> <free_text> (catch-all) ────
  // Must be last — very broad. Category unknown (conf 0.6).
  static final _amountFreeTextRe = RegExp(
    r'^(\d+(?:\.\d+)?)\s+(.+)$',
  );

  TransactionDraft? _matchAmountFreeText(String q) {
    final m = _amountFreeTextRe.firstMatch(q);
    if (m == null) return null;
    final text = m.group(2)!.trim();
    if (text.isEmpty) return null;
    return TransactionDraft(
      kind: TransactionKind.expense,
      amount: double.parse(m.group(1)!),
      note: text,
      date: _today(),
      source: 'pattern',
      fieldConfidence: {
        'amount': _confidence,
        'category': 0.60, // unknown category — triggers ask
        'date': _confidence,
      },
      rawInput: q,
    );
  }
}
