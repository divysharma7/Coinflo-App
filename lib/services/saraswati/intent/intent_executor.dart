import 'package:finance_buddy_app/data/db.dart';
import 'package:finance_buddy_app/data/repositories/base_repository.dart';
import 'package:finance_buddy_app/services/saraswati/intent/saraswati_intent.dart';
import 'package:intl/intl.dart';

/// Executes a [SaraswatiIntent] by querying [BaseRepository] and
/// formatting the result as a markdown string.
///
/// The LLM never computes numbers — all math comes from the repo.
class IntentExecutor {
  IntentExecutor(this._repo);

  final BaseRepository _repo;

  static final _currencyFmt = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '\u20B9',
    decimalDigits: 0,
  );

  /// Execute [intent] and return a markdown-formatted reply.
  ///
  /// [financialContext] is appended to help responses when present.
  Future<String> execute(
    SaraswatiIntent intent, {
    String? financialContext,
  }) async {
    return switch (intent) {
      TodaySpendingIntent() => _execToday(),
      PeriodSpendingIntent(:final period) => _execPeriodSpending(period),
      CategorySpecificIntent(
        :final category,
        :final period,
      ) =>
        _execCategorySpecific(category, period),
      CategoryBreakdownIntent(:final period) => _execCategoryBreakdown(period),
      TopMerchantsIntent(:final limit) => _execTopMerchants(limit),
      PeriodComparisonIntent(:final kind) => _execComparison(kind),
      BiggestExpenseIntent(:final period) => _execBiggest(period),
      TransactionCountIntent(:final period) => _execCount(period),
      DailyAverageIntent(:final period) => _execDailyAvg(period),
      IncomeIntent(:final period) => _execIncome(period),
      SplitsIntent() => _execSplits(),
      HelpIntent() => _execHelp(financialContext),
      UnknownIntent() =>
        throw StateError('UnknownIntent should not reach executor'),
    };
  }

  // ─── Executors ─────────────────────────────────────────

  Future<String> _execToday() async {
    final amount = await _repo.getTodaySpending();
    final topCat = await _repo.getTodayTopCategory();

    if (amount == 0) {
      return "No spending recorded today — looks like a clean slate! "
          "I'll keep an eye out as the day goes on.";
    }

    final catNote =
        topCat != null ? '\n\nYour top category today is **$topCat**.' : '';
    return "You've spent **${_fmt(amount)}** today so far.$catNote";
  }

  Future<String> _execPeriodSpending(Period period) async {
    return switch (period) {
      Period.today => _execToday(),
      Period.thisWeek => _execThisWeek(),
      Period.lastWeek => _execLastWeek(),
      Period.thisMonth => _execThisMonth(),
      Period.lastMonth => _execLastMonth(),
    };
  }

  Future<String> _execThisWeek() async {
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

  Future<String> _execLastWeek() async {
    final now = DateTime.now();
    final monday = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    final lastMonday = monday.subtract(const Duration(days: 7));
    final total = await _repo.getTotalSpentForWeek(lastMonday);

    if (total == 0) {
      return "No spending recorded last week.";
    }

    return "Last week's spending was **${_fmt(total)}**.";
  }

  Future<String> _execThisMonth() async {
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

  Future<String> _execLastMonth() async {
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

  Future<String> _execCategorySpecific(String category, Period period) async {
    final dateTime = _periodToMonth(period);
    final catTotals = await _repo.getCategoryTotalsForMonth(dateTime);
    final amount = catTotals[category] ?? 0;

    if (amount == 0) {
      return "No **${_titleCase(category)}** expenses this month — "
          "that category is looking pretty quiet!";
    }

    final total = catTotals.values.fold<double>(0, (s, v) => s + v);
    final pct = total > 0 ? (amount / total * 100).toStringAsFixed(0) : '0';

    return "You've spent **${_fmt(amount)}** on **${_titleCase(category)}** "
        "this month — that's **$pct%** of your total spending.";
  }

  Future<String> _execCategoryBreakdown(Period period) async {
    final dateTime = _periodToMonth(period);
    final catTotals = await _repo.getCategoryTotalsForMonth(dateTime);

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

  Future<String> _execTopMerchants(int limit) async {
    final merchants = await _repo.getTopMerchants(limit);
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

  Future<String> _execComparison(ComparisonKind kind) async {
    return switch (kind) {
      ComparisonKind.weekOverWeek => _execWeekComparison(),
      ComparisonKind.monthOverMonth => _execMonthComparison(),
    };
  }

  Future<String> _execWeekComparison() async {
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

  Future<String> _execMonthComparison() async {
    final comparison = await _repo.getMonthlyComparison();
    if (comparison.isEmpty) {
      return "I need at least two months of data to make a comparison.";
    }

    final thisMonthTotal =
        comparison.values.fold<double>(0, (s, v) => s + v[0]);
    final lastMonthTotal =
        comparison.values.fold<double>(0, (s, v) => s + v[1]);

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

  Future<String> _execBiggest(Period period) async {
    final dateTime = _periodToMonth(period);
    final txns = await _repo.getTransactionsForMonth(dateTime);
    final expenses = txns.where((t) => t.amount < 0).toList();

    if (expenses.isEmpty) {
      return "No expenses recorded this month yet.";
    }

    expenses.sort((a, b) => a.amount.compareTo(b.amount));
    final top = expenses.first;
    final merchant = top.merchant ?? _titleCase(top.category);
    final date = DateFormat('d MMM').format(top.happenedAt);

    return "Your biggest expense this month is **${_fmt(top.amount.abs())}** "
        "at **$merchant** on $date.";
  }

  Future<String> _execCount(Period period) async {
    final dateTime = _periodToMonth(period);
    final txns = await _repo.getTransactionsForMonth(dateTime);
    final expenseCount = txns.where((t) => t.amount < 0).length;
    final incomeCount = txns.where((t) => t.amount >= 0).length;

    return "This month you have **${txns.length}** transactions — "
        "**$expenseCount** expenses and **$incomeCount** incomes.";
  }

  Future<String> _execDailyAvg(Period period) async {
    final dateTime = _periodToMonth(period);
    final txns = await _repo.getTransactionsForMonth(dateTime);
    final total = _sumExpenses(txns);
    final dayOfMonth = DateTime.now().day;
    final avg = dayOfMonth > 0 ? total / dayOfMonth : 0.0;

    return "Your daily average spending this month is **${_fmt(avg)}** "
        "(based on $dayOfMonth days so far).";
  }

  Future<String> _execIncome(Period period) async {
    final dateTime = _periodToMonth(period);
    final txns = await _repo.getTransactionsForMonth(dateTime);
    final incomes = txns.where((t) => t.amount >= 0).toList();
    final total = incomes.fold<double>(0, (s, t) => s + t.amount);

    if (incomes.isEmpty) {
      return "No income recorded this month yet.";
    }

    return "You've received **${_fmt(total)}** this month across "
        "**${incomes.length}** transaction${incomes.length == 1 ? '' : 's'}.";
  }

  Future<String> _execSplits() async {
    final splits = await _repo.getUnsettledSplits();
    if (splits.isEmpty) {
      return "All clear — no pending splits right now!";
    }

    final totalPending =
        splits.fold<double>(0, (s, t) => s + (t.splitPendingAmount ?? 0));

    return "You have **${splits.length}** unsettled "
        "split${splits.length == 1 ? '' : 's'} "
        "with **${_fmt(totalPending)}** still pending.";
  }

  String _execHelp(String? financialContext) {
    final buf = StringBuffer()
      ..writeln("I can help you understand your spending! Try asking me:")
      ..writeln()
      ..writeln("- *How much did I spend today?*")
      ..writeln("- *What's my spending this month?*")
      ..writeln("- *Show me a category breakdown*")
      ..writeln("- *What's my biggest expense?*")
      ..writeln("- *How do I compare to last week?*")
      ..writeln("- *Month over month comparison*")
      ..writeln("- *Who are my top merchants?*")
      ..writeln("- *What's my daily average?*")
      ..writeln("- *Any pending splits?*")
      ..writeln()
      ..write("Just ask in plain English — I'll crunch the numbers!");

    if (financialContext != null && financialContext.isNotEmpty) {
      buf.writeln();
      buf.writeln();
      buf.write('**Your snapshot:** $financialContext');
    }

    return buf.toString().trimRight();
  }

  // ─── Utilities ─────────────────────────────────────────

  /// Maps a [Period] to a [DateTime] suitable for month-based repo methods.
  DateTime _periodToMonth(Period period) {
    final now = DateTime.now();
    return switch (period) {
      Period.today => now,
      Period.thisWeek => now,
      Period.lastWeek => now,
      Period.thisMonth => now,
      Period.lastMonth => DateTime(now.year, now.month - 1),
    };
  }

  String _fmt(double amount) => _currencyFmt.format(amount);

  String _titleCase(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  double _sumExpenses(List<SpendlerTransaction> txns) {
    return txns
        .where((t) => t.amount < 0)
        .fold<double>(0, (s, t) => s + t.amount.abs());
  }

  String? _topEntry(Map<String, double> map) {
    if (map.isEmpty) return null;
    return map.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }
}
