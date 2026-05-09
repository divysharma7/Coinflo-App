import 'package:finance_buddy_app/data/db.dart';
import 'package:finance_buddy_app/data/repositories/base_repository.dart';
import 'package:intl/intl.dart';

/// Rule-based query processor for the Ask Penny chat assistant.
///
/// Matches user questions against common finance query patterns and computes
/// answers directly from transaction data — no external AI API needed.
class PennyService {
  PennyService(this._repo);

  final BaseRepository _repo;

  static final _currencyFmt = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '\u20B9',
    decimalDigits: 0,
  );

  /// Process a user query and return Penny's markdown-formatted answer.
  Future<String> ask(String query) async {
    final q = query.trim().toLowerCase();

    // Try each handler in priority order; first match wins.
    final handlers = <Future<String?> Function()>[
      () => _handleTodaySpending(q),
      () => _handleThisWeekSpending(q),
      () => _handleThisMonthSpending(q),
      () => _handleLastMonthSpending(q),
      () => _handleCategoryBreakdown(q),
      () => _handleCategorySpecific(q),
      () => _handleTopMerchants(q),
      () => _handleWeekComparison(q),
      () => _handleMonthComparison(q),
      () => _handleBiggestExpense(q),
      () => _handleTransactionCount(q),
      () => _handleDailyAverage(q),
      () => _handleIncome(q),
      () => _handleSplits(q),
      () => _handleHelp(q),
    ];

    for (final handler in handlers) {
      final result = await handler();
      if (result != null) return result;
    }

    return _fallback();
  }

  // ─── Handlers ──────────────────────────────────────────

  Future<String?> _handleTodaySpending(String q) async {
    if (!_matches(q, [
      'today', 'spent today', 'today spend', 'aaj', 'how much today',
    ])) return null;

    final amount = await _repo.getTodaySpending();
    final topCat = await _repo.getTodayTopCategory();

    if (amount == 0) {
      return "No spending recorded today — looks like a clean slate! "
          "I'll keep an eye out as the day goes on.";
    }

    final catNote = topCat != null ? '\n\nYour top category today is **$topCat**.' : '';
    return "You've spent **${_fmt(amount)}** today so far.$catNote";
  }

  Future<String?> _handleThisWeekSpending(String q) async {
    if (!_matches(q, [
      'this week', 'week spend', 'weekly', 'is hafte', 'current week',
    ])) return null;

    final now = DateTime.now();
    final monday = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    final total = await _repo.getTotalSpentForWeek(monday);
    final delta = await _repo.getWeekOverWeekDelta();

    final deltaNote = delta.abs() > 1
        ? '\n\nThat\'s **${delta > 0 ? '+' : ''}${delta.toStringAsFixed(0)}%** compared to last week.'
        : '';
    return "This week's spending stands at **${_fmt(total)}**.$deltaNote";
  }

  Future<String?> _handleThisMonthSpending(String q) async {
    if (!_matches(q, [
      'this month', 'month spend', 'monthly total', 'is mahine',
      'current month',
    ])) return null;

    final now = DateTime.now();
    final txns = await _repo.getTransactionsForMonth(now);
    final total = _sumExpenses(txns);
    final catTotals = await _repo.getCategoryTotalsForMonth(now);

    final topCat = _topEntry(catTotals);
    final lines = StringBuffer()
      ..writeln('Your spending this month is **${_fmt(total)}**.')
      ..writeln()
      ..writeln('**Category breakdown:**');

    final sorted = catTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    for (final e in sorted) {
      final pct = total > 0 ? (e.value / total * 100).toStringAsFixed(0) : '0';
      lines.writeln('- **${_titleCase(e.key)}**: ${_fmt(e.value)} ($pct%)');
    }

    if (topCat != null) {
      lines.writeln();
      lines.write('**${_titleCase(topCat)}** is leading the pack this month.');
    }

    return lines.toString().trimRight();
  }

  Future<String?> _handleLastMonthSpending(String q) async {
    if (!_matches(q, [
      'last month', 'previous month', 'pichla mahina',
    ])) return null;

    final now = DateTime.now();
    final lastMonth = DateTime(now.year, now.month - 1);
    final txns = await _repo.getTransactionsForMonth(lastMonth);
    final total = _sumExpenses(txns);

    if (total == 0) {
      return "I don't have any spending data for last month.";
    }

    final catTotals = await _repo.getCategoryTotalsForMonth(lastMonth);
    final monthName = DateFormat('MMMM').format(lastMonth);

    final lines = StringBuffer()
      ..writeln('In **$monthName**, you spent **${_fmt(total)}** total.')
      ..writeln();

    final sorted = catTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    for (final e in sorted) {
      lines.writeln('- **${_titleCase(e.key)}**: ${_fmt(e.value)}');
    }

    return lines.toString().trimRight();
  }

  Future<String?> _handleCategoryBreakdown(String q) async {
    if (!_matches(q, [
      'category breakdown', 'by category', 'categories',
      'where am i spending', 'where do i spend', 'breakdown',
    ])) return null;

    final now = DateTime.now();
    final catTotals = await _repo.getCategoryTotalsForMonth(now);

    if (catTotals.isEmpty) {
      return "No spending data this month yet — once transactions come in, "
          "I'll break it all down for you!";
    }

    final total = catTotals.values.fold<double>(0, (s, v) => s + v);
    final sorted = catTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final lines = StringBuffer()
      ..writeln("Here's your spending breakdown for this month:")
      ..writeln();

    for (final e in sorted) {
      final pct = (e.value / total * 100).toStringAsFixed(0);
      lines.writeln('- **${_titleCase(e.key)}**: ${_fmt(e.value)} ($pct%)');
    }

    return lines.toString().trimRight();
  }

  Future<String?> _handleCategorySpecific(String q) async {
    final categories = ['rent', 'transport', 'food', 'family', 'social', 'other'];
    String? matched;
    for (final cat in categories) {
      if (q.contains(cat)) {
        matched = cat;
        break;
      }
    }
    // Also match common aliases
    if (matched == null) {
      if (q.contains('travel') || q.contains('cab') || q.contains('uber') ||
          q.contains('ola')) matched = 'transport';
      if (q.contains('grocery') || q.contains('zomato') || q.contains('swiggy') ||
          q.contains('eat') || q.contains('restaurant')) matched = 'food';
      if (q.contains('housing') || q.contains('apartment')) matched = 'rent';
    }
    if (matched == null) return null;

    // Must also signal a spending question
    if (!_matches(q, [
      'how much', 'spend', 'spent', 'total', 'kitna', 'expense',
      matched, // allow bare category name as a question
    ])) return null;

    final now = DateTime.now();
    final catTotals = await _repo.getCategoryTotalsForMonth(now);
    final amount = catTotals[matched] ?? 0;

    if (amount == 0) {
      return "No **${_titleCase(matched)}** expenses this month — "
          "that category is looking pretty quiet!";
    }

    final total = catTotals.values.fold<double>(0, (s, v) => s + v);
    final pct = total > 0 ? (amount / total * 100).toStringAsFixed(0) : '0';

    return "You've spent **${_fmt(amount)}** on **${_titleCase(matched)}** "
        "this month — that's **$pct%** of your total spending.";
  }

  Future<String?> _handleTopMerchants(String q) async {
    if (!_matches(q, [
      'top merchant', 'where do i shop', 'most frequent', 'top places',
      'favourite', 'favorite', 'frequent merchant',
    ])) return null;

    final merchants = await _repo.getTopMerchants(5);
    if (merchants.isEmpty) {
      return "Not enough transaction data yet to identify your top merchants.";
    }

    final lines = StringBuffer()
      ..writeln("Here are your most frequent merchants this month:")
      ..writeln();

    for (var i = 0; i < merchants.length; i++) {
      final m = merchants[i];
      lines.writeln('${i + 1}. **${m.name}** — ${m.count} transactions, '
          '${_fmt(m.total)} total');
    }

    return lines.toString().trimRight();
  }

  Future<String?> _handleWeekComparison(String q) async {
    if (!_matches(q, [
      'week over week', 'compared to last week', 'vs last week',
      'week comparison', 'week trend',
    ])) return null;

    final delta = await _repo.getWeekOverWeekDelta();
    final now = DateTime.now();
    final monday = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    final thisWeek = await _repo.getTotalSpentForWeek(monday);
    final lastMonday = monday.subtract(const Duration(days: 7));
    final lastWeek = await _repo.getTotalSpentForWeek(lastMonday);

    final lines = StringBuffer()
      ..writeln('**This week:** ${_fmt(thisWeek)}')
      ..writeln('**Last week:** ${_fmt(lastWeek)}')
      ..writeln();

    if (delta.abs() < 1) {
      lines.write("Pretty much on par — no major change between weeks.");
    } else if (delta > 0) {
      lines.write("You're spending **${delta.toStringAsFixed(0)}% more** "
          "than last week. Might want to keep an eye on that!");
    } else {
      lines.write("Nice, you're down **${delta.abs().toStringAsFixed(0)}%** "
          "from last week. Keep it going!");
    }

    return lines.toString().trimRight();
  }

  Future<String?> _handleMonthComparison(String q) async {
    if (!_matches(q, [
      'month over month', 'compared to last month', 'vs last month',
      'month comparison', 'monthly trend',
    ])) return null;

    final comparison = await _repo.getMonthlyComparison();
    if (comparison.isEmpty) {
      return "I need at least two months of data to make a comparison.";
    }

    final thisMonthTotal = comparison.values
        .fold<double>(0, (s, v) => s + v[0]);
    final lastMonthTotal = comparison.values
        .fold<double>(0, (s, v) => s + v[1]);

    final lines = StringBuffer()
      ..writeln('**This month:** ${_fmt(thisMonthTotal)}')
      ..writeln('**Last month:** ${_fmt(lastMonthTotal)}')
      ..writeln()
      ..writeln('**By category:**');

    final sorted = comparison.entries.toList()
      ..sort((a, b) => b.value[0].compareTo(a.value[0]));
    for (final e in sorted) {
      final diff = e.value[0] - e.value[1];
      final arrow = diff > 0 ? '\u2191' : (diff < 0 ? '\u2193' : '\u2192');
      lines.writeln('- **${_titleCase(e.key)}**: ${_fmt(e.value[0])} '
          '$arrow (was ${_fmt(e.value[1])})');
    }

    return lines.toString().trimRight();
  }

  Future<String?> _handleBiggestExpense(String q) async {
    if (!_matches(q, [
      'biggest', 'largest', 'most expensive', 'highest', 'max spend',
      'sabse bada',
    ])) return null;

    final now = DateTime.now();
    final txns = await _repo.getTransactionsForMonth(now);
    final expenses = txns.where((t) => t.amount < 0).toList();

    if (expenses.isEmpty) {
      return "No expenses recorded this month yet.";
    }

    expenses.sort((a, b) => a.amount.compareTo(b.amount)); // most negative first
    final top = expenses.first;
    final merchant = top.merchant ?? _titleCase(top.category);
    final date = DateFormat('d MMM').format(top.happenedAt);

    return "Your biggest expense this month is **${_fmt(top.amount.abs())}** "
        "at **$merchant** on $date.";
  }

  Future<String?> _handleTransactionCount(String q) async {
    if (!_matches(q, [
      'how many transactions', 'transaction count', 'number of transactions',
      'kitne transactions',
    ])) return null;

    final now = DateTime.now();
    final txns = await _repo.getTransactionsForMonth(now);
    final expenses = txns.where((t) => t.amount < 0).length;
    final incomes = txns.where((t) => t.amount >= 0).length;

    return "This month you have **${txns.length}** transactions — "
        "**$expenses** expenses and **$incomes** incomes.";
  }

  Future<String?> _handleDailyAverage(String q) async {
    if (!_matches(q, [
      'daily average', 'average per day', 'per day', 'average spend',
      'avg spend',
    ])) return null;

    final now = DateTime.now();
    final txns = await _repo.getTransactionsForMonth(now);
    final total = _sumExpenses(txns);
    final dayOfMonth = now.day;
    final avg = dayOfMonth > 0 ? total / dayOfMonth : 0.0;

    return "Your daily average spending this month is **${_fmt(avg)}** "
        "(based on $dayOfMonth days so far).";
  }

  Future<String?> _handleIncome(String q) async {
    if (!_matches(q, [
      'income', 'earned', 'received', 'credit', 'salary',
    ])) return null;

    final now = DateTime.now();
    final txns = await _repo.getTransactionsForMonth(now);
    final incomes = txns.where((t) => t.amount >= 0).toList();
    final total = incomes.fold<double>(0, (s, t) => s + t.amount);

    if (incomes.isEmpty) {
      return "No income recorded this month yet.";
    }

    return "You've received **${_fmt(total)}** this month across "
        "**${incomes.length}** transaction${incomes.length == 1 ? '' : 's'}.";
  }

  Future<String?> _handleSplits(String q) async {
    if (!_matches(q, [
      'split', 'owe', 'pending split', 'unsettled', 'settle',
    ])) return null;

    final splits = await _repo.getUnsettledSplits();
    if (splits.isEmpty) {
      return "All clear — no pending splits right now!";
    }

    final totalPending = splits.fold<double>(
        0, (s, t) => s + (t.splitPendingAmount ?? 0));

    return "You have **${splits.length}** unsettled split${splits.length == 1 ? '' : 's'} "
        "with **${_fmt(totalPending)}** still pending.";
  }

  Future<String?> _handleHelp(String q) async {
    if (!_matches(q, [
      'help', 'what can you', 'can you do', 'commands', 'kya kar sakti',
    ])) return null;

    return "I can help you understand your spending! Try asking me:\n\n"
        "- *How much did I spend today?*\n"
        "- *What's my spending this month?*\n"
        "- *Show me a category breakdown*\n"
        "- *What's my biggest expense?*\n"
        "- *How do I compare to last week?*\n"
        "- *Month over month comparison*\n"
        "- *Who are my top merchants?*\n"
        "- *What's my daily average?*\n"
        "- *Any pending splits?*\n\n"
        "Just ask in plain English — I'll crunch the numbers!";
  }

  String _fallback() {
    return "Hmm, I'm not sure I follow that one! Try asking about your "
        "spending — like *\"how much did I spend today?\"* or "
        "*\"show me a category breakdown\"*. "
        "Type **help** to see everything I can do!";
  }

  // ─── Utilities ─────────────────────────────────────────

  bool _matches(String query, List<String> keywords) {
    return keywords.any((k) => query.contains(k));
  }

  String _fmt(double amount) => _currencyFmt.format(amount);

  String _titleCase(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  double _sumExpenses(List<PaisaTransaction> txns) {
    return txns
        .where((t) => t.amount < 0)
        .fold<double>(0, (s, t) => s + t.amount.abs());
  }

  String? _topEntry(Map<String, double> map) {
    if (map.isEmpty) return null;
    return map.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }
}
