import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:finance_buddy_app/design_system/design_system.dart';

/// 08 · Recap — a confident finish line.
///
/// One scannable, dark "receipt" of everything configured, each row tappable to
/// fix — so the user commits with confidence instead of wondering what they
/// just set up.
class RecapScreen extends StatefulWidget {
  const RecapScreen({super.key});

  @override
  State<RecapScreen> createState() => _RecapScreenState();
}

class _RecapScreenState extends State<RecapScreen> {
  final NumberFormat _formatter = NumberFormat.decimalPattern();

  String _currencySymbol = '₹';
  String _currencyName = 'Indian Rupee';
  int _accountCount = 1;
  String _accountNames = 'Cash';
  double? _monthlyBudget;
  int _goalCount = 0;
  bool _dailyReminder = true;
  bool _loaded = false;

  static const _bg = RadialGradient(
    center: Alignment(0.72, -1.24),
    radius: 1.4,
    colors: [Color(0xFF2B2B30), Color(0xFF161618), Color(0xFF0A0A0A)],
    stops: [0.0, 0.46, 1.0],
  );

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();

    final code = prefs.getString('currency_code') ?? 'inr';
    final accountsJson = prefs.getString('accounts');
    final goalsJson = prefs.getString('savings_goals');

    var count = 1;
    var names = 'Cash';
    if (accountsJson != null) {
      try {
        final list = (jsonDecode(accountsJson) as List)
            .cast<Map<String, dynamic>>();
        if (list.isNotEmpty) {
          count = list.length;
          names = list
              .map((a) => a['name'] as String? ?? '')
              .where((n) => n.isNotEmpty)
              .join(', ');
        }
      } on FormatException catch (_) {
        // keep defaults
      }
    }

    var goals = 0;
    if (goalsJson != null) {
      try {
        goals = (jsonDecode(goalsJson) as List).length;
      } on FormatException catch (_) {
        // keep default
      }
    }

    if (!mounted) return;
    setState(() {
      _currencySymbol = prefs.getString('currency_symbol') ?? '₹';
      _currencyName = _nameForCode(code);
      _accountCount = count;
      _accountNames = names;
      _monthlyBudget =
          prefs.getDouble('monthly_budget') ??
          prefs.getInt('monthly_budget')?.toDouble();
      _goalCount = goals;
      _dailyReminder = prefs.getBool('daily_reminder_enabled') ?? true;
      _loaded = true;
    });
  }

  String _nameForCode(String code) {
    switch (code.toLowerCase()) {
      case 'usd':
        return 'US Dollar';
      case 'eur':
        return 'Euro';
      case 'gbp':
        return 'British Pound';
      case 'jpy':
        return 'Japanese Yen';
      case 'inr':
      default:
        return 'Indian Rupee';
    }
  }

  String get _budgetValue => _monthlyBudget != null && _monthlyBudget! > 0
      ? '$_currencySymbol${_formatter.format(_monthlyBudget!.toInt())} / month'
      : 'Skipped';

  String get _goalsValue {
    final goalPart = _goalCount == 0
        ? 'No goals yet'
        : '$_goalCount goal${_goalCount == 1 ? '' : 's'}';
    return '$goalPart · daily reminder ${_dailyReminder ? 'on' : 'off'}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppBackButton(onTap: () => context.pop()),
            Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                top: AppSpacing.xs,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Here's your setup",
                    style: AppTextStyles.headingL.copyWith(
                      color: AppColors.black,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Looks good? You can change any of this later in Settings.',
                    style: AppTextStyles.bodyM.copyWith(
                      color: AppColors.gray500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: AnimatedOpacity(
                  opacity: _loaded ? 1 : 0,
                  duration: AppDurations.base,
                  child: _receiptCard(),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: AppButton(
                label: 'Finish setup',
                onTap: () => context.push('/onboarding/complete'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _receiptCard() {
    final rows = <Widget>[
      _row(
        'Currency',
        '$_currencyName · $_currencySymbol',
        '/onboarding/currency',
      ),
      _row(
        'Accounts',
        '$_accountNames · $_accountCount added',
        '/onboarding/accounts',
      ),
      _row('Categories', '40 ready to use', '/onboarding/categories'),
      _row('Monthly budget', _budgetValue, '/onboarding/budget'),
      _row('Goals & reminders', _goalsValue, '/onboarding/reminders'),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: const BoxDecoration(
        gradient: _bg,
        borderRadius: AppRadius.xl,
        boxShadow: AppShadows.hero,
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            rows[i],
            if (i < rows.length - 1)
              Divider(
                height: 1,
                thickness: 1,
                color: Colors.white.withValues(alpha: 0.08),
              ),
          ],
        ],
      ),
    );
  }

  Widget _row(String label, String value, String route) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => context.push(route),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: AppColors.green,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: AppColors.white, size: 14),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.bodyM.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    value,
                    style: AppTextStyles.bodyS.copyWith(
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.white.withValues(alpha: 0.34),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
