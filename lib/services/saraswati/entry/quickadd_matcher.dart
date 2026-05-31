import 'package:finance_buddy_app/services/saraswati/entry/transaction_draft.dart';

/// Stage 0: deterministic regex patterns for common entry shapes.
///
/// Hand-written, no LLM. Field confidence = 0.95 for matched fields.
/// Returns `null` on no match.
class QuickaddMatcher {
  const QuickaddMatcher();

  static const _confidence = 0.95;

  /// Try all 15 patterns in order. First match wins.
  TransactionDraft? match(String normalized) {
    return _matchMealDrink(normalized) ??
        _matchTransport(normalized) ??
        _matchRent(normalized) ??
        _matchFuel(normalized) ??
        _matchGrocery(normalized) ??
        _matchUtilities(normalized) ??
        _matchFromPerson(normalized) ??
        _matchToPerson(normalized) ??
        _matchSalary(normalized) ??
        _matchHealthcare(normalized) ??
        _matchEntertainment(normalized) ??
        _matchShopping(normalized) ??
        _matchSplit(normalized) ??
        _matchFoodDelivery(normalized);
  }

  // ─── Helpers ──────────────────────────────────────────

  static DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  static Map<String, double> _expenseConf() => {
        'amount': _confidence,
        'category': _confidence,
        'date': _confidence,
      };

  // ─── 1. Coffee / chai / tea ───────────────────────────
  // ─── 2. Lunch / dinner / breakfast / snack ────────────
  // Combined: amount + meal/drink keyword
  static final _mealDrinkRe = RegExp(
    r'^(\d+(?:\.\d+)?)\s+(coffee|chai|tea|lunch|dinner|breakfast|snack)$',
  );

  TransactionDraft? _matchMealDrink(String q) {
    final m = _mealDrinkRe.firstMatch(q);
    if (m == null) return null;
    return TransactionDraft(
      kind: TransactionKind.expense,
      amount: double.parse(m.group(1)!),
      category: 'food',
      date: _today(),
      source: 'quickadd',
      fieldConfidence: _expenseConf(),
      rawInput: q,
    );
  }

  // ─── 3. Uber / ola / rapido / auto / cab / taxi ──────
  static final _transportRe = RegExp(
    r'^(\d+(?:\.\d+)?)\s+(uber|ola|rapido|auto|cab|taxi)$',
  );

  TransactionDraft? _matchTransport(String q) {
    final m = _transportRe.firstMatch(q);
    if (m == null) return null;
    return TransactionDraft(
      kind: TransactionKind.expense,
      amount: double.parse(m.group(1)!),
      category: 'transport',
      date: _today(),
      source: 'quickadd',
      fieldConfidence: _expenseConf(),
      rawInput: q,
    );
  }

  // ─── 4. Rent ──────────────────────────────────────────
  static final _rentRe = RegExp(r'^(\d+(?:\.\d+)?)\s+rent$');

  TransactionDraft? _matchRent(String q) {
    final m = _rentRe.firstMatch(q);
    if (m == null) return null;
    return TransactionDraft(
      kind: TransactionKind.expense,
      amount: double.parse(m.group(1)!),
      category: 'rent',
      date: _today(),
      source: 'quickadd',
      fieldConfidence: _expenseConf(),
      rawInput: q,
    );
  }

  // ─── 5. Petrol / fuel / gas ───────────────────────────
  static final _fuelRe = RegExp(
    r'^(\d+(?:\.\d+)?)\s+(petrol|fuel|gas)$',
  );

  TransactionDraft? _matchFuel(String q) {
    final m = _fuelRe.firstMatch(q);
    if (m == null) return null;
    return TransactionDraft(
      kind: TransactionKind.expense,
      amount: double.parse(m.group(1)!),
      category: 'transport',
      date: _today(),
      source: 'quickadd',
      fieldConfidence: _expenseConf(),
      rawInput: q,
    );
  }

  // ─── 6. Grocery / groceries / sabzi / vegetables ─────
  static final _groceryRe = RegExp(
    r'^(\d+(?:\.\d+)?)\s+(grocery|groceries|sabzi|vegetables)$',
  );

  TransactionDraft? _matchGrocery(String q) {
    final m = _groceryRe.firstMatch(q);
    if (m == null) return null;
    return TransactionDraft(
      kind: TransactionKind.expense,
      amount: double.parse(m.group(1)!),
      category: 'food',
      date: _today(),
      source: 'quickadd',
      fieldConfidence: _expenseConf(),
      rawInput: q,
    );
  }

  // ─── 7. Electricity / water / wifi / internet / gas bill
  static final _utilitiesRe = RegExp(
    r'^(\d+(?:\.\d+)?)\s+(electricity|water|wifi|internet|gas bill)$',
  );

  TransactionDraft? _matchUtilities(String q) {
    final m = _utilitiesRe.firstMatch(q);
    if (m == null) return null;
    return TransactionDraft(
      kind: TransactionKind.expense,
      amount: double.parse(m.group(1)!),
      category: 'utilities',
      date: _today(),
      source: 'quickadd',
      fieldConfidence: _expenseConf(),
      rawInput: q,
    );
  }

  // ─── 8. <amount> from <name> ──────────────────────────
  static final _fromPersonRe = RegExp(
    r'^(\d+(?:\.\d+)?)\s+from\s+(\w+)$',
  );

  TransactionDraft? _matchFromPerson(String q) {
    final m = _fromPersonRe.firstMatch(q);
    if (m == null) return null;
    final name = m.group(2)!;
    return TransactionDraft(
      kind: TransactionKind.income,
      amount: double.parse(m.group(1)!),
      counterparty: name[0].toUpperCase() + name.substring(1),
      category: 'other',
      date: _today(),
      source: 'quickadd',
      fieldConfidence: {
        'amount': _confidence,
        'counterparty': _confidence,
        'category': 0.80, // "from X" could be payback or gift — slightly less confident
        'date': _confidence,
      },
      rawInput: q,
    );
  }

  // ─── 9. <amount> to <name> ────────────────────────────
  static final _toPersonRe = RegExp(
    r'^(\d+(?:\.\d+)?)\s+to\s+(\w+)$',
  );

  TransactionDraft? _matchToPerson(String q) {
    final m = _toPersonRe.firstMatch(q);
    if (m == null) return null;
    final name = m.group(2)!;
    return TransactionDraft(
      kind: TransactionKind.transfer,
      amount: double.parse(m.group(1)!),
      counterparty: name[0].toUpperCase() + name.substring(1),
      date: _today(),
      source: 'quickadd',
      fieldConfidence: {
        'amount': _confidence,
        'counterparty': _confidence,
        'date': _confidence,
      },
      rawInput: q,
    );
  }

  // ─── 10. salary <amount> ──────────────────────────────
  static final _salaryRe = RegExp(r'^salary\s+(\d+(?:\.\d+)?)$');

  TransactionDraft? _matchSalary(String q) {
    final m = _salaryRe.firstMatch(q);
    if (m == null) return null;
    return TransactionDraft(
      kind: TransactionKind.income,
      amount: double.parse(m.group(1)!),
      category: 'salary',
      date: _today(),
      source: 'quickadd',
      fieldConfidence: _expenseConf(),
      rawInput: q,
    );
  }

  // ─── 11. Medicine / medical / doctor / hospital ───────
  static final _healthcareRe = RegExp(
    r'^(\d+(?:\.\d+)?)\s+(medicine|medical|doctor|hospital)$',
  );

  TransactionDraft? _matchHealthcare(String q) {
    final m = _healthcareRe.firstMatch(q);
    if (m == null) return null;
    return TransactionDraft(
      kind: TransactionKind.expense,
      amount: double.parse(m.group(1)!),
      category: 'healthcare',
      date: _today(),
      source: 'quickadd',
      fieldConfidence: _expenseConf(),
      rawInput: q,
    );
  }

  // ─── 12. Movie / netflix / spotify ────────────────────
  static final _entertainmentRe = RegExp(
    r'^(\d+(?:\.\d+)?)\s+(movie|netflix|spotify)$',
  );

  TransactionDraft? _matchEntertainment(String q) {
    final m = _entertainmentRe.firstMatch(q);
    if (m == null) return null;
    return TransactionDraft(
      kind: TransactionKind.expense,
      amount: double.parse(m.group(1)!),
      category: 'entertainment',
      date: _today(),
      source: 'quickadd',
      fieldConfidence: _expenseConf(),
      rawInput: q,
    );
  }

  // ─── 13. Amazon / flipkart / myntra ───────────────────
  static final _shoppingRe = RegExp(
    r'^(\d+(?:\.\d+)?)\s+(amazon|flipkart|myntra)$',
  );

  TransactionDraft? _matchShopping(String q) {
    final m = _shoppingRe.firstMatch(q);
    if (m == null) return null;
    return TransactionDraft(
      kind: TransactionKind.expense,
      amount: double.parse(m.group(1)!),
      category: 'shopping',
      date: _today(),
      source: 'quickadd',
      fieldConfidence: _expenseConf(),
      rawInput: q,
    );
  }

  // ─── 14. split <amount> with <names> ──────────────────
  static final _splitRe = RegExp(
    r'^split\s+(\d+(?:\.\d+)?)\s+with\s+(.+)$',
  );

  TransactionDraft? _matchSplit(String q) {
    final m = _splitRe.firstMatch(q);
    if (m == null) return null;
    final names = m.group(2)!
        .split(RegExp(r'[,\s]+'))
        .where((n) => n.isNotEmpty)
        .map((n) => n[0].toUpperCase() + n.substring(1))
        .toList();
    if (names.isEmpty) return null;
    return TransactionDraft(
      kind: TransactionKind.split,
      amount: double.parse(m.group(1)!),
      splitWith: names,
      date: _today(),
      payer: PayerKind.splitEqual,
      source: 'quickadd',
      fieldConfidence: {
        'amount': _confidence,
        'split_with': _confidence,
        'date': _confidence,
        'payer': _confidence,
      },
      rawInput: q,
    );
  }

  // ─── 15. Zomato / swiggy ─────────────────────────────
  static final _foodDeliveryRe = RegExp(
    r'^(\d+(?:\.\d+)?)\s+(zomato|swiggy)$',
  );

  TransactionDraft? _matchFoodDelivery(String q) {
    final m = _foodDeliveryRe.firstMatch(q);
    if (m == null) return null;
    return TransactionDraft(
      kind: TransactionKind.expense,
      amount: double.parse(m.group(1)!),
      category: 'food',
      counterparty: m.group(2)!,
      date: _today(),
      source: 'quickadd',
      fieldConfidence: {
        ..._expenseConf(),
        'counterparty': _confidence,
      },
      rawInput: q,
    );
  }
}
