import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:finance_buddy_app/core/enums.dart';
import 'package:finance_buddy_app/core/tokens.dart';
import 'package:finance_buddy_app/data/db.dart';
import 'package:finance_buddy_app/providers/onboarding_provider.dart';
import 'package:finance_buddy_app/pages/shell_page.dart';
import 'package:finance_buddy_app/widgets/common/spendler_bottom_sheet.dart';

// ---------------------------------------------------------------------------
// 10-step onboarding flow for Spendler.
// ---------------------------------------------------------------------------

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  static const _totalSteps = 10;

  final _pageController = PageController();
  int _currentStep = 0; // 0-9 = steps, 10 = completion

  // ── Step 1: Currency ──
  Currency _selectedCurrency = Currency.inr;
  String _currencySearch = '';

  // ── Step 2: Accounts ──
  final List<_AccountEntry> _accounts = [
    const _AccountEntry(name: 'Cash', type: AccountType.cash),
  ];
  bool _showAddAccount = false;
  final _accountNameController = TextEditingController();
  AccountType _newAccountType = AccountType.cash;

  // ── Step 3: Monthly budget ──
  double _monthlyBudget = 10000;
  final _budgetController = TextEditingController(text: '10000');

  // ── Step 4: Category budgets ──
  final List<_CategoryBudgetEntry> _categoryBudgets = [];

  // ── Step 5: Categories overview (read-only) ──

  // ── Step 6: Track income ──
  bool _trackIncome = true;

  // ── Step 7: Smart rules ──
  final List<_SmartRuleEntry> _smartRules = [];

  // ── Step 8: Recurring payments ──
  final List<_RecurringPaymentEntry> _recurringPayments = [];

  // ── Step 9: Notifications ──
  bool _notificationsEnabled = true;
  bool _dailyReminder = true;
  bool _weeklyReport = false;

  // ── Step 10: Savings goals ──
  final List<_SavingsGoalEntry> _savingsGoals = [];

  // DB instance for direct table access (UserAccounts, SmartRules).
  late final SpendlerDatabase _db;

  @override
  void initState() {
    super.initState();
    _db = SpendlerDatabase();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _accountNameController.dispose();
    _budgetController.dispose();
    _db.close();
    super.dispose();
  }

  // ── Navigation ──

  void _goForward() {
    if (_currentStep < _totalSteps) {
      setState(() => _currentStep++);
      _pageController.animateToPage(
        _currentStep,
        duration: SpendlerMotion.transition,
        curve: SpendlerMotion.surfaceCurve,
      );
    }
  }

  void _goBack() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(
        _currentStep,
        duration: SpendlerMotion.transition,
        curve: SpendlerMotion.surfaceCurve,
      );
    }
  }

  Future<void> _saveStep1() async {
    await saveSelectedCurrency(_selectedCurrency.name);
  }

  Future<void> _saveStep2() async {
    for (final a in _accounts) {
      await _db.customStatement(
        'INSERT INTO user_accounts (name, type, created_at) VALUES (?, ?, ?)',
        [a.name, a.type.name, DateTime.now().millisecondsSinceEpoch ~/ 1000],
      );
    }
  }

  Future<void> _saveStep3() async {
    await saveMonthlyBudget(_monthlyBudget);
  }

  Future<void> _saveStep4() async {
    for (final b in _categoryBudgets) {
      await _db.into(_db.categoryBudgets).insert(
            CategoryBudgetsCompanion.insert(
              category: b.category.name,
              monthlyLimit: b.monthlyLimit,
            ),
          );
    }
  }

  Future<void> _saveStep6() async {
    await saveTrackIncome(_trackIncome);
  }

  Future<void> _saveStep7() async {
    for (final r in _smartRules) {
      await _db.customStatement(
        'INSERT INTO smart_rules (keyword, category, created_at) VALUES (?, ?, ?)',
        [r.keyword, r.category.name, DateTime.now().millisecondsSinceEpoch ~/ 1000],
      );
    }
  }

  Future<void> _saveStep8() async {
    for (final p in _recurringPayments) {
      await _db.into(_db.subscriptions).insert(
            SubscriptionsCompanion.insert(
              name: p.name,
              amount: p.amount,
              billingCycle: p.isYearly ? 'yearly' : 'monthly',
              nextBillingDate: p.nextDate ?? DateTime.now(),
              category: 'billsAndUtilities',
            ),
          );
    }
  }

  Future<void> _saveStep10() async {
    for (final g in _savingsGoals) {
      await _db.into(_db.savingsGoals).insert(
            SavingsGoalsCompanion.insert(
              name: g.name,
              targetAmount: g.targetAmount,
              iconName: g.iconName,
            ),
          );
    }
  }

  Future<void> _handleContinue() async {
    await HapticFeedback.lightImpact();
    switch (_currentStep) {
      case 0:
        await _saveStep1();
      case 1:
        await _saveStep2();
      case 2:
        await _saveStep3();
      case 3:
        await _saveStep4();
      case 4:
        break; // categories overview - nothing to save
      case 5:
        await _saveStep6();
      case 6:
        await _saveStep7();
      case 7:
        await _saveStep8();
      case 8:
        break; // notifications - saved locally in step 9 prefs if needed
      case 9:
        await _saveStep10();
    }
    _goForward();
  }

  Future<void> _handleComplete() async {
    await HapticFeedback.mediumImpact();
    await completeOnboarding();
    if (!mounted) return;
    await Navigator.pushReplacement(
      context,
      PageRouteBuilder<void>(
        pageBuilder: (_, _, _) => const ShellPage(),
        transitionDuration: SpendlerMotion.transition,
        transitionsBuilder: (_, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SpendlerColors.scaffold,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              children: [
                // Dot indicators
                Padding(
                  padding: const EdgeInsets.all(SpendlerSpacing.lg),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_pageCount, (i) {
                      return AnimatedContainer(
                        duration: SpendlerMotion.transition,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: i == _currentPage ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: i == _currentPage
                              ? SpendlerColors.primary
                              : SpendlerColors.textTertiary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                ),
                // Pages
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (i) => setState(() => _currentPage = i),
                    physics: const BouncingScrollPhysics(),
                    children: [
                      _ScreenIdentity(onNext: _next),
                      if (!widget.isGuideMode)
                        _ScreenName(
                          controller: _nameController,
                          onNext: _next,
                        ),
                      _ScreenPromise(onNext: _next),
                      _ScreenMirror(onNext: _next),
                      _ScreenStart(
                        onFinish: _finish,
                        isGuideMode: widget.isGuideMode,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Top Bar ──

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: SpendlerSpacing.screenH,
        vertical: SpendlerSpacing.md,
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            GestureDetector(
              onTap: _goBack,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: SpendlerColors.surface,
                  borderRadius: BorderRadius.circular(SpendlerRadii.button),
                  border: Border.all(color: SpendlerColors.border),
                ),
                child: Icon(
                  PhosphorIcons.arrowLeft(),
                  size: 20,
                  color: SpendlerColors.textPrimary,
                ),
              ),
            )
          else
            const SizedBox(width: 40),
          const SizedBox(width: SpendlerSpacing.md),
          Expanded(child: _buildProgressBar()),
          const SizedBox(width: SpendlerSpacing.md + 40),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Row(
      children: List.generate(_totalSteps * 2 - 1, (i) {
        if (i.isOdd) return const SizedBox(width: 4);
        final step = i ~/ 2;
        final isFilled = step <= _currentStep;
        return Expanded(
          child: Container(
            height: 4,
            decoration: BoxDecoration(
              color: isFilled
                  ? SpendlerColors.textPrimary
                  : SpendlerColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }

  // ── Continue Button ──

  Widget _buildContinueButton(String label, {VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.all(SpendlerSpacing.screenH),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: Material(
          color: SpendlerColors.textPrimary,
          borderRadius: BorderRadius.circular(SpendlerRadii.button),
          child: InkWell(
            borderRadius: BorderRadius.circular(SpendlerRadii.button),
            onTap: onTap ?? _handleContinue,
            child: Center(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Step header ──

  Widget _buildStepHeader(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: SpendlerSpacing.screenH),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: SpendlerSpacing.sm),
          Text(title, style: SpendlerTextStyles.onboardingHeadline),
          const SizedBox(height: SpendlerSpacing.sm),
          Text(subtitle, style: SpendlerTextStyles.onboardingBody),
          const SizedBox(height: SpendlerSpacing.lg),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────────────
  // STEP 1: Choose your currency
  // ────────────────────────────────────────────────────────

  Widget _buildStep1Currency() {
    final filtered = Currency.values.where((c) {
      if (_currencySearch.isEmpty) return true;
      final q = _currencySearch.toLowerCase();
      return c.label.toLowerCase().contains(q) ||
          c.code.toLowerCase().contains(q) ||
          c.symbol.toLowerCase().contains(q);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeader(
          'Choose your currency',
          'This will be used across the app for all amounts.',
        ),
        // Search bar
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: SpendlerSpacing.screenH,
          ),
          child: TextField(
            onChanged: (v) => setState(() => _currencySearch = v),
            decoration: InputDecoration(
              hintText: 'Search currency...',
              hintStyle: const TextStyle(color: SpendlerColors.textTertiary),
              prefixIcon: Icon(PhosphorIcons.magnifyingGlass(),
                  color: SpendlerColors.textTertiary),
              filled: true,
              fillColor: SpendlerColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(SpendlerRadii.button),
                borderSide: const BorderSide(color: SpendlerColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(SpendlerRadii.button),
                borderSide: const BorderSide(color: SpendlerColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(SpendlerRadii.button),
                borderSide: const BorderSide(color: SpendlerColors.textPrimary),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: SpendlerSpacing.md,
                vertical: SpendlerSpacing.sm,
              ),
            ),
          ),
        ),
        const SizedBox(height: SpendlerSpacing.sm),
        // Currency list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(
              horizontal: SpendlerSpacing.screenH,
            ),
            itemCount: filtered.length,
            itemBuilder: (_, i) {
              final c = filtered[i];
              final selected = c == _selectedCurrency;
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: SpendlerSpacing.sm,
                  vertical: SpendlerSpacing.xs,
                ),
                leading: CircleAvatar(
                  radius: 20,
                  backgroundColor: SpendlerColors.surfaceSecondary,
                  child: Text(
                    c.symbol,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: SpendlerColors.textPrimary,
                    ),
                  ),
                ),
                title: Text(
                  c.label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                  ),
                ),
                subtitle: Text(
                  c.code,
                  style: const TextStyle(
                    color: SpendlerColors.textTertiary,
                    fontSize: 13,
                  ),
                ),
                trailing: selected
                    ? Icon(PhosphorIcons.checkCircle(PhosphorIconsStyle.fill),
                        color: SpendlerColors.textPrimary)
                    : null,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(SpendlerRadii.button),
                ),
                tileColor: selected
                    ? SpendlerColors.surfaceSecondary
                    : Colors.transparent,
                onTap: () => setState(() => _selectedCurrency = c),
              );
            },
          ),
        ),
        _buildContinueButton('Continue'),
      ],
    );
  }

  // ────────────────────────────────────────────────────────
  // STEP 2: Add your accounts
  // ────────────────────────────────────────────────────────

  Widget _buildStep2Accounts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeader(
          'Add your accounts',
          'Where do you keep your money? Add at least one account.',
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: SpendlerSpacing.screenH,
            ),
            children: [
              // Existing accounts
              ..._accounts.map((a) => Container(
                    margin:
                        const EdgeInsets.only(bottom: SpendlerSpacing.sm),
                    padding: const EdgeInsets.all(SpendlerSpacing.md),
                    decoration: BoxDecoration(
                      color: SpendlerColors.surface,
                      borderRadius:
                          BorderRadius.circular(SpendlerRadii.card),
                      border: Border.all(color: SpendlerColors.border),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: SpendlerColors.surfaceSecondary,
                          child: Icon(a.type.icon, size: 20,
                              color: SpendlerColors.textPrimary),
                        ),
                        const SizedBox(width: SpendlerSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(a.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15)),
                              Text(a.type.label,
                                  style: const TextStyle(
                                      color: SpendlerColors.textTertiary,
                                      fontSize: 13)),
                            ],
                          ),
                        ),
                        if (a.name != 'Cash')
                          GestureDetector(
                            onTap: () => setState(
                                () => _accounts.remove(a)),
                            child: Icon(PhosphorIcons.x(),
                                size: 18,
                                color: SpendlerColors.textTertiary),
                          ),
                      ],
                    ),
                  )),

              // Add account card
              if (_showAddAccount)
                Container(
                  margin:
                      const EdgeInsets.only(bottom: SpendlerSpacing.sm),
                  padding: const EdgeInsets.all(SpendlerSpacing.md),
                  decoration: BoxDecoration(
                    color: SpendlerColors.surface,
                    borderRadius:
                        BorderRadius.circular(SpendlerRadii.card),
                    border: Border.all(color: SpendlerColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ACCOUNT NAME',
                        style: SpendlerTextStyles.sectionLabel,
                      ),
                      const SizedBox(height: SpendlerSpacing.sm),
                      TextField(
                        controller: _accountNameController,
                        decoration: InputDecoration(
                          hintText: 'e.g. HDFC Bank, Paytm...',
                          hintStyle: const TextStyle(
                              color: SpendlerColors.textTertiary),
                          filled: true,
                          fillColor: SpendlerColors.surfaceSecondary,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                                SpendlerRadii.button),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: SpendlerSpacing.md,
                            vertical: SpendlerSpacing.sm,
                          ),
                        ),
                      ),
                      const SizedBox(height: SpendlerSpacing.md),
                      const Text('TYPE', style: SpendlerTextStyles.sectionLabel),
                      const SizedBox(height: SpendlerSpacing.sm),
                      Wrap(
                        spacing: SpendlerSpacing.sm,
                        runSpacing: SpendlerSpacing.sm,
                        children: AccountType.values.map((t) {
                          final selected = t == _newAccountType;
                          return GestureDetector(
                            onTap: () =>
                                setState(() => _newAccountType = t),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: SpendlerSpacing.md,
                                vertical: SpendlerSpacing.sm,
                              ),
                              decoration: BoxDecoration(
                                color: selected
                                    ? SpendlerColors.textPrimary
                                    : SpendlerColors.surfaceSecondary,
                                borderRadius: BorderRadius.circular(
                                    SpendlerRadii.pill),
                              ),
                              child: Text(
                                t.label,
                                style: TextStyle(
                                  color: selected
                                      ? Colors.white
                                      : SpendlerColors.textPrimary,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: SpendlerSpacing.md),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {
                              _accountNameController.clear();
                              setState(() => _showAddAccount = false);
                            },
                            child: const Text('Cancel',
                                style: TextStyle(
                                    color: SpendlerColors.textSecondary)),
                          ),
                          const SizedBox(width: SpendlerSpacing.sm),
                          FilledButton(
                            onPressed: () {
                              final name =
                                  _accountNameController.text.trim();
                              if (name.isNotEmpty) {
                                setState(() {
                                  _accounts.add(_AccountEntry(
                                    name: name,
                                    type: _newAccountType,
                                  ));
                                  _showAddAccount = false;
                                  _accountNameController.clear();
                                  _newAccountType = AccountType.cash;
                                });
                              }
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: SpendlerColors.textPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    SpendlerRadii.button),
                              ),
                            ),
                            child: const Text('Add'),
                          ),
                        ],
                      ),
                    ],
                  ),
                )
              else
                GestureDetector(
                  onTap: () => setState(() => _showAddAccount = true),
                  child: Container(
                    padding:
                        const EdgeInsets.all(SpendlerSpacing.md),
                    decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(SpendlerRadii.card),
                      border: Border.all(
                        color: SpendlerColors.border,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(PhosphorIcons.plus(),
                            size: 18,
                            color: SpendlerColors.textSecondary),
                        const SizedBox(width: SpendlerSpacing.sm),
                        const Text(
                          'Add another account',
                          style: TextStyle(
                            color: SpendlerColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        _buildContinueButton('Continue'),
      ],
    );
  }

  // ────────────────────────────────────────────────────────
  // STEP 3: Set a monthly budget
  // ────────────────────────────────────────────────────────

  Widget _buildStep3Budget() {
    final sym = _selectedCurrency.symbol;
    final quickPicks = <double>[5000, 10000, 50000, 100000, 500000];
    final quickLabels = [
      '${sym}5k',
      '${sym}10k',
      '${sym}50k',
      '${sym}100k',
      '${sym}500k',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeader(
          'Set a monthly budget',
          'How much do you plan to spend each month?',
        ),
        const Spacer(),
        // Hero amount card
        Center(
          child: Container(
            margin: const EdgeInsets.symmetric(
              horizontal: SpendlerSpacing.screenH,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: SpendlerSpacing.lg,
              vertical: SpendlerSpacing.xl,
            ),
            decoration: BoxDecoration(
              color: SpendlerColors.surface,
              borderRadius: BorderRadius.circular(SpendlerRadii.card),
              border: Border.all(color: SpendlerColors.border),
            ),
            child: Column(
              children: [
                GestureDetector(
                  onTap: () => _showBudgetEditor(),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sym,
                        style: SpendlerTextStyles.heroSymbol,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatAmount(_monthlyBudget),
                        style: SpendlerTextStyles.heroAmount,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: SpendlerSpacing.sm),
                const Text(
                  'per month',
                  style: TextStyle(
                    color: SpendlerColors.textTertiary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: SpendlerSpacing.lg),
        // Quick-pick chips
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: SpendlerSpacing.screenH,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(quickPicks.length, (i) {
              final selected = _monthlyBudget == quickPicks[i];
              return GestureDetector(
                onTap: () => setState(() {
                  _monthlyBudget = quickPicks[i];
                  _budgetController.text =
                      quickPicks[i].toInt().toString();
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: SpendlerSpacing.md,
                    vertical: SpendlerSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? SpendlerColors.textPrimary
                        : SpendlerColors.surfaceSecondary,
                    borderRadius:
                        BorderRadius.circular(SpendlerRadii.pill),
                  ),
                  child: Text(
                    quickLabels[i],
                    style: TextStyle(
                      color: selected
                          ? Colors.white
                          : SpendlerColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        const Spacer(),
        _buildContinueButton('Continue'),
      ],
    );
  }

  void _showBudgetEditor() {
    _budgetController.text = _monthlyBudget.toInt().toString();
    showSpendlerSheet<void>(
      context: context,
      builder: (ctx) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter Budget',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: SpendlerSpacing.md),
            TextField(
              controller: _budgetController,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                prefixText: '${_selectedCurrency.symbol} ',
                filled: true,
                fillColor: SpendlerColors.surfaceSecondary,
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(SpendlerRadii.button),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: SpendlerSpacing.md),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: () {
                  final v =
                      double.tryParse(_budgetController.text.trim());
                  if (v != null && v > 0) {
                    setState(() => _monthlyBudget = v);
                  }
                  Navigator.pop(ctx);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: SpendlerColors.textPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(SpendlerRadii.button),
                  ),
                ),
                child: const Text('Save'),
              ),
            ),
          ],
        );
      },
    );
  }

  // ────────────────────────────────────────────────────────
  // STEP 4: Category Budgets
  // ────────────────────────────────────────────────────────

  Widget _buildStep4CategoryBudgets() {
    final totalAllocated =
        _categoryBudgets.fold<double>(0, (s, b) => s + b.monthlyLimit);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeader(
          'Category Budgets',
          'Set spending limits per category group. Optional \u2014 add more later.',
        ),
        // Allocation bar
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: SpendlerSpacing.screenH,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_selectedCurrency.symbol}${_formatAmount(totalAllocated)} allocated of ${_selectedCurrency.symbol}${_formatAmount(_monthlyBudget)} monthly budget',
                style: const TextStyle(
                  fontSize: 13,
                  color: SpendlerColors.textSecondary,
                ),
              ),
              const SizedBox(height: SpendlerSpacing.sm),
              ClipRRect(
                borderRadius:
                    BorderRadius.circular(SpendlerRadii.progressBar),
                child: LinearProgressIndicator(
                  value: _monthlyBudget > 0
                      ? (totalAllocated / _monthlyBudget).clamp(0.0, 1.0)
                      : 0,
                  backgroundColor: SpendlerColors.progressTrack,
                  valueColor: AlwaysStoppedAnimation(
                    totalAllocated > _monthlyBudget
                        ? SpendlerColors.expense
                        : SpendlerColors.textPrimary,
                  ),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: SpendlerSpacing.md),
        // Budget list
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: SpendlerSpacing.screenH,
            ),
            children: [
              ..._categoryBudgets.asMap().entries.map((entry) {
                final i = entry.key;
                final b = entry.value;
                final hue = SpendlerColors.categoryHue[b.category] ??
                    SpendlerColors.textTertiary;
                return Container(
                  margin:
                      const EdgeInsets.only(bottom: SpendlerSpacing.sm),
                  padding: const EdgeInsets.symmetric(
                    horizontal: SpendlerSpacing.md,
                    vertical: SpendlerSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: SpendlerColors.surface,
                    borderRadius:
                        BorderRadius.circular(SpendlerRadii.card),
                    border: Border.all(color: SpendlerColors.border),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: hue.withValues(alpha: 0.15),
                        child: Icon(b.category.icon,
                            size: 18, color: hue),
                      ),
                      const SizedBox(width: SpendlerSpacing.md),
                      Expanded(
                        child: Text(
                          b.category.label,
                          style: const TextStyle(
                              fontWeight: FontWeight.w500, fontSize: 15),
                        ),
                      ),
                      Text(
                        '${_selectedCurrency.symbol}${_formatAmount(b.monthlyLimit)}/mo',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: SpendlerSpacing.sm),
                      GestureDetector(
                        onTap: () => _showAddCategoryBudgetSheet(
                            editIndex: i),
                        child: Icon(PhosphorIcons.pencilSimple(),
                            size: 18,
                            color: SpendlerColors.textTertiary),
                      ),
                      const SizedBox(width: SpendlerSpacing.sm),
                      GestureDetector(
                        onTap: () => setState(
                            () => _categoryBudgets.removeAt(i)),
                        child: Icon(PhosphorIcons.trash(),
                            size: 18,
                            color: SpendlerColors.textTertiary),
                      ),
                    ],
                  ),
                );
              }),
              // Add category budget button
              GestureDetector(
                onTap: () => _showAddCategoryBudgetSheet(),
                child: Container(
                  padding: const EdgeInsets.all(SpendlerSpacing.md),
                  decoration: BoxDecoration(
                    borderRadius:
                        BorderRadius.circular(SpendlerRadii.card),
                    border: Border.all(
                      color: SpendlerColors.border,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(PhosphorIcons.plus(),
                          size: 18,
                          color: SpendlerColors.textSecondary),
                      const SizedBox(width: SpendlerSpacing.sm),
                      const Text(
                        'Add category budget',
                        style: TextStyle(
                          color: SpendlerColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        _buildContinueButton(
          _categoryBudgets.isEmpty ? 'Skip for now' : 'Continue',
        ),
      ],
    );
  }

  void _showAddCategoryBudgetSheet({int? editIndex}) {
    final isEdit = editIndex != null;
    TransactionCategory? selectedGroup =
        isEdit ? _categoryBudgets[editIndex].category : null;
    final limitCtrl = TextEditingController(
      text: isEdit
          ? _categoryBudgets[editIndex].monthlyLimit.toInt().toString()
          : '',
    );

    // Exclude already-used categories (unless editing that one)
    final usedCats =
        _categoryBudgets.map((b) => b.category).toSet();
    if (isEdit) usedCats.remove(_categoryBudgets[editIndex].category);

    showSpendlerSheet<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        isEdit
                            ? 'Edit Category Budget'
                            : 'Add Category Budget',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Icon(PhosphorIcons.x(), size: 24),
                    ),
                  ],
                ),
                const SizedBox(height: SpendlerSpacing.lg),
                const Text('CATEGORY GROUP',
                    style: SpendlerTextStyles.sectionLabel),
                const SizedBox(height: SpendlerSpacing.sm),
                Wrap(
                  spacing: SpendlerSpacing.sm,
                  runSpacing: SpendlerSpacing.sm,
                  children: TransactionCategory.groups
                      .where((g) => !usedCats.contains(g))
                      .map((g) {
                    final sel = g == selectedGroup;
                    final hue = SpendlerColors.categoryHue[g] ??
                        SpendlerColors.textTertiary;
                    return GestureDetector(
                      onTap: () =>
                          setSheetState(() => selectedGroup = g),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: SpendlerSpacing.md,
                          vertical: SpendlerSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          color: sel
                              ? SpendlerColors.textPrimary
                              : SpendlerColors.surfaceSecondary,
                          borderRadius:
                              BorderRadius.circular(SpendlerRadii.pill),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(g.icon,
                                size: 16,
                                color: sel ? Colors.white : hue),
                            const SizedBox(width: 6),
                            Text(
                              g.label,
                              style: TextStyle(
                                color: sel
                                    ? Colors.white
                                    : SpendlerColors.textPrimary,
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: SpendlerSpacing.lg),
                const Text('MONTHLY LIMIT',
                    style: SpendlerTextStyles.sectionLabel),
                const SizedBox(height: SpendlerSpacing.sm),
                TextField(
                  controller: limitCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    prefixText: '${_selectedCurrency.symbol} ',
                    filled: true,
                    fillColor: SpendlerColors.surfaceSecondary,
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(SpendlerRadii.button),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: SpendlerSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                              color: SpendlerColors.border),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                SpendlerRadii.button),
                          ),
                          padding: const EdgeInsets.symmetric(
                              vertical: 14),
                        ),
                        child: const Text('Cancel',
                            style: TextStyle(
                                color: SpendlerColors.textSecondary)),
                      ),
                    ),
                    const SizedBox(width: SpendlerSpacing.md),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          final limit =
                              double.tryParse(limitCtrl.text.trim());
                          if (selectedGroup != null &&
                              limit != null &&
                              limit > 0) {
                            setState(() {
                              if (isEdit) {
                                _categoryBudgets[editIndex] =
                                    _CategoryBudgetEntry(
                                  category: selectedGroup!,
                                  monthlyLimit: limit,
                                );
                              } else {
                                _categoryBudgets.add(
                                  _CategoryBudgetEntry(
                                    category: selectedGroup!,
                                    monthlyLimit: limit,
                                  ),
                                );
                              }
                            });
                            Navigator.pop(ctx);
                          }
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: SpendlerColors.textPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                SpendlerRadii.button),
                          ),
                          padding: const EdgeInsets.symmetric(
                              vertical: 14),
                        ),
                        child: Text(isEdit ? 'Save' : 'Save'),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ────────────────────────────────────────────────────────
  // STEP 5: Categories overview
  // ────────────────────────────────────────────────────────

  Widget _buildStep5CategoriesOverview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeader(
          "We've got you covered",
          '40 categories are already set up for you. Add more if you need something specific.',
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: SpendlerSpacing.screenH,
            ),
            children: [
              ...TransactionCategory.groups.map((group) {
                final subs = Subcategory.forGroup(group);
                final hue = SpendlerColors.categoryHue[group] ??
                    SpendlerColors.textTertiary;
                return Padding(
                  padding:
                      const EdgeInsets.only(bottom: SpendlerSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: hue,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: SpendlerSpacing.sm),
                          Text(
                            group.label.toUpperCase(),
                            style: SpendlerTextStyles.sectionLabel,
                          ),
                        ],
                      ),
                      const SizedBox(height: SpendlerSpacing.sm),
                      Wrap(
                        spacing: SpendlerSpacing.sm,
                        runSpacing: SpendlerSpacing.sm,
                        children: subs.map((sub) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: SpendlerSpacing.md,
                              vertical: SpendlerSpacing.sm,
                            ),
                            decoration: BoxDecoration(
                              color: (SpendlerColors.categoryTint[group] ??
                                  SpendlerColors.surfaceSecondary),
                              borderRadius: BorderRadius.circular(
                                  SpendlerRadii.pill),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(sub.icon, size: 14, color: hue),
                                const SizedBox(width: 6),
                                Text(
                                  sub.name,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: SpendlerColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                );
              }),
              // Custom categories section
              Padding(
                padding:
                    const EdgeInsets.only(bottom: SpendlerSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'YOUR CUSTOM CATEGORIES',
                      style: SpendlerTextStyles.sectionLabel,
                    ),
                    const SizedBox(height: SpendlerSpacing.sm),
                    Container(
                      padding:
                          const EdgeInsets.all(SpendlerSpacing.md),
                      decoration: BoxDecoration(
                        borderRadius:
                            BorderRadius.circular(SpendlerRadii.card),
                        border: Border.all(color: SpendlerColors.border),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(PhosphorIcons.plus(),
                              size: 18,
                              color: SpendlerColors.textSecondary),
                          const SizedBox(width: SpendlerSpacing.sm),
                          const Text(
                            'Add category',
                            style: TextStyle(
                              color: SpendlerColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        _buildContinueButton('Continue'),
      ],
    );
  }

  // ────────────────────────────────────────────────────────
  // STEP 6: Track your income too?
  // ────────────────────────────────────────────────────────

  Widget _buildStep6TrackIncome() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeader(
          'Track your income too?',
          'Do you want to track both income and expenses, or just expenses?',
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: SpendlerSpacing.screenH,
          ),
          child: Column(
            children: [
              _buildIncomeOptionCard(
                icon: PhosphorIcons.trendUp(),
                title: 'Yes, track income & expenses',
                subtitle: 'See the full picture of your money flow',
                selected: _trackIncome,
                onTap: () => setState(() => _trackIncome = true),
              ),
              const SizedBox(height: SpendlerSpacing.md),
              _buildIncomeOptionCard(
                icon: PhosphorIcons.trendDown(),
                title: 'No, just expenses',
                subtitle: 'Focus only on tracking what you spend',
                selected: !_trackIncome,
                onTap: () => setState(() => _trackIncome = false),
              ),
            ],
          ),
        ),
        const Spacer(),
        _buildContinueButton('Continue'),
      ],
    );
  }

  Widget _buildIncomeOptionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(SpendlerSpacing.md),
        decoration: BoxDecoration(
          color: SpendlerColors.surface,
          borderRadius: BorderRadius.circular(SpendlerRadii.card),
          border: Border.all(
            color: selected
                ? SpendlerColors.textPrimary
                : SpendlerColors.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: selected
                  ? SpendlerColors.textPrimary
                  : SpendlerColors.surfaceSecondary,
              child: Icon(icon,
                  size: 22,
                  color: selected
                      ? Colors.white
                      : SpendlerColors.textTertiary),
            ),
            const SizedBox(width: SpendlerSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(
                          color: SpendlerColors.textTertiary,
                          fontSize: 13)),
                ],
              ),
            ),
            if (selected)
              Icon(PhosphorIcons.checkCircle(PhosphorIconsStyle.fill),
                  color: SpendlerColors.textPrimary, size: 24),
          ],
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────────
  // STEP 7: Smart Rules
  // ────────────────────────────────────────────────────────

  Widget _buildStep7SmartRules() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeader(
          'Smart Rules',
          'Tell us how you want things categorized \u2014 no AI needed.',
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: SpendlerSpacing.screenH,
            ),
            children: [
              // How it works card
              Container(
                padding: const EdgeInsets.all(SpendlerSpacing.md),
                decoration: BoxDecoration(
                  color: SpendlerColors.surface,
                  borderRadius:
                      BorderRadius.circular(SpendlerRadii.card),
                  border: Border.all(color: SpendlerColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(PhosphorIcons.lightning(),
                            size: 18,
                            color: SpendlerColors.accentAmber),
                        const SizedBox(width: SpendlerSpacing.sm),
                        const Text(
                          'How it works',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: SpendlerSpacing.sm),
                    const Text(
                      'When you add a transaction with a title containing your keyword, it\'s instantly assigned to your chosen category \u2014 skipping AI entirely.',
                      style: TextStyle(
                        color: SpendlerColors.textSecondary,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: SpendlerSpacing.md),
                    const Text('EXAMPLE',
                        style: SpendlerTextStyles.sectionLabel),
                    const SizedBox(height: SpendlerSpacing.sm),
                    _buildRuleExampleRow(
                        '"paneer"', 'Groceries'),
                    const SizedBox(height: 4),
                    _buildRuleExampleRow(
                        '"- diet"', 'Gym & Fitness'),
                  ],
                ),
              ),
              const SizedBox(height: SpendlerSpacing.md),
              // Existing rules
              ..._smartRules.asMap().entries.map((entry) {
                final i = entry.key;
                final r = entry.value;
                final hue = SpendlerColors.categoryHue[r.category] ??
                    SpendlerColors.textTertiary;
                return Container(
                  margin:
                      const EdgeInsets.only(bottom: SpendlerSpacing.sm),
                  padding: const EdgeInsets.symmetric(
                    horizontal: SpendlerSpacing.md,
                    vertical: SpendlerSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: SpendlerColors.surface,
                    borderRadius:
                        BorderRadius.circular(SpendlerRadii.card),
                    border: Border.all(color: SpendlerColors.border),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: hue.withValues(alpha: 0.15),
                        child: Icon(r.category.icon,
                            size: 16, color: hue),
                      ),
                      const SizedBox(width: SpendlerSpacing.md),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(
                                fontSize: 14,
                                color: SpendlerColors.textPrimary),
                            children: [
                              TextSpan(
                                text: '"${r.keyword}"',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600),
                              ),
                              const TextSpan(text: ' \u2192 '),
                              TextSpan(text: r.category.label),
                            ],
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () =>
                            setState(() => _smartRules.removeAt(i)),
                        child: Icon(PhosphorIcons.trash(),
                            size: 18,
                            color: SpendlerColors.textTertiary),
                      ),
                    ],
                  ),
                );
              }),
              // Add rule button
              GestureDetector(
                onTap: _showAddRuleSheet,
                child: Container(
                  padding: const EdgeInsets.all(SpendlerSpacing.md),
                  decoration: BoxDecoration(
                    borderRadius:
                        BorderRadius.circular(SpendlerRadii.card),
                    border: Border.all(color: SpendlerColors.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(PhosphorIcons.plus(),
                          size: 18,
                          color: SpendlerColors.textSecondary),
                      const SizedBox(width: SpendlerSpacing.sm),
                      const Text(
                        'Add a rule',
                        style: TextStyle(
                          color: SpendlerColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        _buildContinueButton(
          _smartRules.isEmpty ? 'Skip for now' : 'Continue',
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(SpendlerSpacing.xl),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight - SpendlerSpacing.xl * 2,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PhosphorIcon(
                  PhosphorIcons.user(),
                  color: SpendlerColors.primary,
                  size: 48,
                ),
                const SizedBox(height: SpendlerSpacing.lg),
                const Text(
                  'What should we\ncall you?',
                  style: SpendlerTextStyles.onboardingHeadline,
                ),
                const SizedBox(height: SpendlerSpacing.lg),
                TextField(
                  controller: controller,
                  autofocus: true,
                  style: SpendlerTextStyles.greeting,
                  cursorColor: SpendlerColors.primary,
                  decoration: const InputDecoration(
                    hintText: 'Your first name',
                    hintStyle: TextStyle(
                      color: SpendlerColors.textTertiary,
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                    border: UnderlineInputBorder(
                      borderSide: BorderSide(color: SpendlerColors.border),
                    ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: SpendlerColors.border),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: SpendlerColors.primary),
                    ),
                  ),
                  textCapitalization: TextCapitalization.words,
                  onSubmitted: (_) => onNext(),
                ),
                const SizedBox(height: SpendlerSpacing.xl),
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: onNext,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: SpendlerSpacing.md,
                        vertical: SpendlerSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: SpendlerColors.primary,
                        borderRadius: BorderRadius.circular(SpendlerRadii.pill),
                      ),
                      child: const Text(
                        'Next →',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── Screen: SMS Promise ─────────────────────────────

class _ScreenPromise extends StatelessWidget {
  const _ScreenPromise({required this.onNext});
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onNext,
      child: Padding(
        padding: const EdgeInsets.all(SpendlerSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PhosphorIcon(
              PhosphorIcons.chatText(),
              color: SpendlerColors.primary,
              size: 48,
            ),
            const SizedBox(height: SpendlerSpacing.lg),
            const Text(
              'Your spending,\nautomatically tracked.',
              style: SpendlerTextStyles.onboardingHeadline,
            ),
            const SizedBox(height: SpendlerSpacing.md),
            const Text(
              'Every bank SMS gets parsed instantly.\nYou just confirm.',
              style: SpendlerTextStyles.onboardingBody,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Screen: Weekly Mirror ───────────────────────────

class _ScreenMirror extends StatelessWidget {
  const _ScreenMirror({required this.onNext});
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onNext,
      child: Padding(
        padding: const EdgeInsets.all(SpendlerSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PhosphorIcon(
              PhosphorIcons.calendarCheck(),
              color: SpendlerColors.primary,
              size: 48,
            ),
            const SizedBox(height: SpendlerSpacing.lg),
            const Text(
              'A weekly mirror\nfor your money.',
              style: SpendlerTextStyles.onboardingHeadline,
            ),
            const SizedBox(height: SpendlerSpacing.md),
            const Text(
              'No budgets. No guilt.\nJust clear, honest awareness.',
              style: SpendlerTextStyles.onboardingBody,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Screen: Permission + Start ──────────────────────

class _ScreenStart extends StatelessWidget {
  const _ScreenStart({required this.onFinish, this.isGuideMode = false});
  final Future<void> Function({bool requestSms}) onFinish;
  final bool isGuideMode;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(SpendlerSpacing.xl),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight - SpendlerSpacing.xl * 2,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PhosphorIcon(
                  isGuideMode
                      ? PhosphorIcons.checkCircle()
                      : PhosphorIcons.rocketLaunch(),
                  color: SpendlerColors.primary,
                  size: 48,
                ),
                const SizedBox(height: SpendlerSpacing.lg),
                Text(
                  isGuideMode ? 'That\'s the whole idea.' : 'Let\'s get started.',
                  style: SpendlerTextStyles.onboardingHeadline,
                ),
                const SizedBox(height: SpendlerSpacing.md),
                Text(
                  isGuideMode
                      ? 'SMS gets parsed, you confirm,\nand your weekly rhythm appears.'
                      : 'Allow SMS access and we\'ll\nhandle the rest.',
                  style: SpendlerTextStyles.onboardingBody,
                ),
                const SizedBox(height: SpendlerSpacing.xxl),
                if (isGuideMode)
                  NeoPOPButton(
                    label: 'Got it',
                    onTap: () => onFinish(),
                  )
                else ...[
                  NeoPOPButton(
                    label: 'Allow SMS Access',
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      onFinish(requestSms: true);
                    },
                  ),
                  const SizedBox(height: SpendlerSpacing.md),
                  Center(
                    child: TextButton(
                      onPressed: () => onFinish(requestSms: false),
                      child: const Text(
                        'I\'ll add manually',
                        style: TextStyle(
                          color: SpendlerColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeatureRow(IconData icon, String text) {
    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: SpendlerColors.surfaceSecondary,
          child:
              Icon(icon, size: 20, color: SpendlerColors.textPrimary),
        ),
        const SizedBox(width: SpendlerSpacing.md),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: SpendlerColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  // ── Helpers ──

  String _formatAmount(double amount) {
    if (amount >= 100000) {
      final lakhs = amount / 100000;
      return lakhs == lakhs.truncateToDouble()
          ? '${lakhs.toInt()}L'
          : '${lakhs.toStringAsFixed(1)}L';
    }
    if (amount >= 1000) {
      final k = amount / 1000;
      return k == k.truncateToDouble()
          ? '${k.toInt()},${(amount % 1000).toInt().toString().padLeft(3, '0')}'
              .replaceAll(',000', 'k')
              .replaceFirst(RegExp(r',0+$'), 'k')
          : amount.toInt().toString();
    }
    return amount.toInt().toString();
  }
}

// ─── Local data classes ──────────────────────────────

class _AccountEntry {
  final String name;
  final AccountType type;
  const _AccountEntry({required this.name, required this.type});
}

class _CategoryBudgetEntry {
  final TransactionCategory category;
  final double monthlyLimit;
  const _CategoryBudgetEntry({
    required this.category,
    required this.monthlyLimit,
  });
}

class _SmartRuleEntry {
  final String keyword;
  final TransactionCategory category;
  const _SmartRuleEntry({required this.keyword, required this.category});
}

class _RecurringPaymentEntry {
  final String name;
  final double amount;
  final bool isYearly;
  final DateTime? nextDate;
  const _RecurringPaymentEntry({
    required this.name,
    required this.amount,
    this.isYearly = false,
    this.nextDate,
  });
}

class _SavingsGoalEntry {
  final String name;
  final double targetAmount;
  final String iconName;
  const _SavingsGoalEntry({
    required this.name,
    required this.targetAmount,
    required this.iconName,
  });
}
