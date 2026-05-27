import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:finance_buddy_app/core/enums.dart';
import 'package:finance_buddy_app/design_system/design_system.dart';
import 'package:finance_buddy_app/providers/providers.dart';
import 'package:finance_buddy_app/providers/onboarding_provider.dart';
import 'package:finance_buddy_app/providers/auth_provider.dart';
import 'package:finance_buddy_app/pages/settings/profile_sheet.dart';
import 'package:finance_buddy_app/widgets/common/spendler_bottom_sheet.dart';
import 'package:finance_buddy_app/constants/faqs.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadNotificationPref();
  }

  Future<void> _loadNotificationPref() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      });
    }
  }

  Future<void> _saveNotificationPref(bool value) async {
    setState(() => _notificationsEnabled = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', value);
  }

  @override
  Widget build(BuildContext context) {
    final userName = ref.watch(userNameProvider);
    final userEmail = ref.watch(userEmailProvider);
    final currencyAsync = ref.watch(selectedCurrencyProvider);
    final trackIncomeAsync = ref.watch(trackIncomeProvider);
    final budgetAsync = ref.watch(monthlyBudgetProvider);

    final name = userName.valueOrNull ?? 'User';
    final email = userEmail.valueOrNull ?? 'Not set';
    final currencyCode = currencyAsync.valueOrNull ?? 'inr';
    final trackIncome = trackIncomeAsync.valueOrNull ?? true;
    final budget = budgetAsync.valueOrNull;

    final currency = Currency.values.firstWhere(
      (c) => c.name == currencyCode,
      orElse: () => Currency.inr,
    );
    final currencyDisplay = '${currency.code} (${currency.symbol})';

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 24, 0, 20),
                  child: Text('Settings',
                      style: AppTextStyles.headingL
                          .copyWith(color: AppColors.black)),
                ),

                // ─── Profile Card ────────────────────────
                GestureDetector(
                  onTap: () => _showProfileSheet(context),
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: const BoxDecoration(
                      color: AppColors.white,
                      borderRadius: AppRadius.xl,
                      boxShadow: AppShadows.sm,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: const BoxDecoration(
                            color: AppColors.gray100,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: PhosphorIcon(PhosphorIcons.user(),
                                color: AppColors.gray600, size: 18),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name,
                                  style: AppTextStyles.headingS
                                      .copyWith(color: AppColors.black),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 2),
                              Text(email,
                                  style: AppTextStyles.bodyS
                                      .copyWith(color: AppColors.gray500),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                        PhosphorIcon(PhosphorIcons.caretRight(),
                            color: AppColors.gray500, size: 18),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.xxl),

                // ─── GENERAL Section ─────────────────────
                _sectionLabel('GENERAL'),
                Container(
                  decoration: const BoxDecoration(
                    color: AppColors.white,
                    borderRadius: AppRadius.xl,
                  ),
                  child: Column(
                    children: [
                      _SettingsRow(
                        icon: PhosphorIcons.lightning(),
                        iconBg: AppColors.gray100,
                        iconColor: AppColors.gray600,
                        label: 'Ask Saraswati',
                        onTap: () => context.push('/settings/saraswati'),
                      ),
                      const _Divider(),
                      _SettingsRow(
                        icon: PhosphorIcons.usersThree(),
                        iconBg: AppColors.gray100,
                        iconColor: AppColors.gray600,
                        label: 'People & Debts',
                        onTap: () => context.push('/settings/people'),
                      ),
                      const _Divider(),
                      _SettingsRow(
                        icon: PhosphorIcons.creditCard(),
                        iconBg: AppColors.gray100,
                        iconColor: AppColors.gray600,
                        label: 'Accounts',
                        onTap: () => _showAccountsSheet(),
                      ),
                      const _Divider(),
                      _SettingsRow(
                        icon: PhosphorIcons.currencyDollar(),
                        iconBg: AppColors.gray100,
                        iconColor: AppColors.gray600,
                        label: 'Currency',
                        trailing: Text(currencyDisplay,
                            style: AppTextStyles.bodyS
                                .copyWith(color: AppColors.gray500)),
                        onTap: () => _showCurrencyPicker(currencyCode),
                      ),
                      const _Divider(),
                      _SettingsRow(
                        icon: PhosphorIcons.arrowsClockwise(),
                        iconBg: AppColors.gray100,
                        iconColor: AppColors.gray600,
                        label: 'Subscriptions',
                        onTap: () => context.push('/settings/subscriptions'),
                      ),
                      const _Divider(),
                      _SettingsRow(
                        icon: PhosphorIcons.tag(),
                        iconBg: AppColors.gray100,
                        iconColor: AppColors.gray600,
                        label: 'Categories',
                        onTap: () => _showCategoriesSheet(),
                      ),
                      const _Divider(),
                      _SettingsRow(
                        icon: PhosphorIcons.sliders(),
                        iconBg: AppColors.gray100,
                        iconColor: AppColors.gray600,
                        label: 'Monthly Budget',
                        trailing: Text(
                          budget != null ? '${currency.symbol}${budget.toStringAsFixed(0)}' : 'Not set',
                          style: AppTextStyles.bodyS
                              .copyWith(color: AppColors.gray500),
                        ),
                        onTap: () => _showBudgetEditor(budget),
                      ),
                      const _Divider(),
                      _SettingsToggleRow(
                        icon: PhosphorIcons.trendUp(),
                        iconBg: AppColors.gray100,
                        iconColor: AppColors.gray600,
                        label: 'Track Income',
                        value: trackIncome,
                        onChanged: (v) async {
                          await saveTrackIncome(v);
                          ref.invalidate(trackIncomeProvider);
                        },
                      ),
                      const _Divider(),
                      _SettingsToggleRow(
                        icon: PhosphorIcons.bell(),
                        iconBg: AppColors.gray100,
                        iconColor: AppColors.gray600,
                        label: 'Notifications',
                        value: _notificationsEnabled,
                        onChanged: _saveNotificationPref,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.xxl),

                // ─── DATA Section ───────────────────────
                _sectionLabel('DATA'),
                Container(
                  decoration: const BoxDecoration(
                    color: AppColors.white,
                    borderRadius: AppRadius.xl,
                  ),
                  child: Column(
                    children: [
                      _SettingsRow(
                        icon: PhosphorIcons.fileXls(),
                        iconBg: AppColors.gray100,
                        iconColor: AppColors.gray600,
                        label: 'Import from Excel',
                        onTap: () => context.push('/settings/excel-import'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.xxl),

                // ─── ABOUT Section ───────────────────────
                _sectionLabel('ABOUT'),
                Container(
                  decoration: const BoxDecoration(
                    color: AppColors.white,
                    borderRadius: AppRadius.xl,
                  ),
                  child: Column(
                    children: [
                      _SettingsRow(
                        icon: PhosphorIcons.question(),
                        iconBg: AppColors.gray100,
                        iconColor: AppColors.gray600,
                        label: 'Help & Support',
                        onTap: () => _showHelpSheet(),
                      ),
                      const _Divider(),
                      _SettingsRow(
                        icon: PhosphorIcons.info(),
                        iconBg: AppColors.gray100,
                        iconColor: AppColors.gray600,
                        label: 'Version',
                        trailing: Text('1.0.2',
                            style: AppTextStyles.bodyS
                                .copyWith(color: AppColors.gray500)),
                        showChevron: false,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.xxl),

                // ─── Log Out ─────────────────────────────
                GestureDetector(
                  onTap: () => _confirmLogout(),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: const BoxDecoration(
                      color: AppColors.gray100,
                      borderRadius: AppRadius.xl,
                    ),
                    child: Center(
                      child: Text('Log Out',
                          style: AppTextStyles.bodyM.copyWith(
                              color: AppColors.red, fontWeight: FontWeight.w500)),
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.sm),

                // ─── Delete Account ──────────────────────
                GestureDetector(
                  onTap: () => _confirmDeleteAccount(),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: const BoxDecoration(
                      color: AppColors.gray100,
                      borderRadius: AppRadius.xl,
                    ),
                    child: Center(
                      child: Text('Delete Account',
                          style: AppTextStyles.bodyM.copyWith(
                              color: AppColors.red, fontWeight: FontWeight.w500)),
                    ),
                  ),
                ),

                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(text,
          style: AppTextStyles.labelM.copyWith(color: AppColors.gray500)),
    );
  }

  // ─── Accounts Sheet ─────────────────────────────────────

  void _showAccountsSheet() async {
    final prefs = await SharedPreferences.getInstance();
    final currencyCode = prefs.getString('currency_code') ?? 'inr';
    final acctCurrency = Currency.values.firstWhere(
      (c) => c.name == currencyCode,
      orElse: () => Currency.inr,
    );
    final accountsJson = prefs.getString('accounts');
    List<dynamic> accounts = [];
    if (accountsJson != null) {
      try {
        accounts = List<dynamic>.from(jsonDecode(accountsJson) as List);
      } on FormatException catch (e) {
        debugPrint('Malformed accounts JSON: $e');
      }
    }

    if (!mounted) return;
    await showSpendlerSheet<void>(
      context: context,
      isScrollControlled: false,
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: SizedBox(height: AppSpacing.md),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Accounts',
                        style: AppTextStyles.headingS
                            .copyWith(color: AppColors.black)),
                    Text('${accounts.length} accounts',
                        style: AppTextStyles.bodyS
                            .copyWith(color: AppColors.gray500)),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                if (accounts.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.xl),
                      child: Text('No accounts configured.',
                          style: AppTextStyles.bodyM
                              .copyWith(color: AppColors.gray500)),
                    ),
                  )
                else
                  ...accounts.map((a) {
                    final account = a as Map<String, dynamic>;
                    final name = account['name'] as String? ?? '';
                    final type = account['type'] as String? ?? '';
                    final balance =
                        (account['openingBalance'] as num?)?.toDouble() ??
                            0;
                    return Container(
                      margin:
                          const EdgeInsets.only(bottom: AppSpacing.xs),
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.offWhite,
                        borderRadius: AppRadius.base,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: AppRadius.sm,
                            ),
                            child: Icon(
                              type == 'upi'
                                  ? PhosphorIcons.deviceMobile()
                                  : PhosphorIcons.wallet(),
                              size: 20,
                              color: AppColors.gray600,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(name,
                                    style: AppTextStyles.bodyM.copyWith(
                                        color: AppColors.black,
                                        fontWeight: FontWeight.w600)),
                                Text(
                                    type.toUpperCase(),
                                    style: AppTextStyles.labelS.copyWith(
                                        color: AppColors.gray500)),
                              ],
                            ),
                          ),
                          Text(
                            '${acctCurrency.symbol}${balance.toStringAsFixed(0)}',
                            style: AppTextStyles.numericL
                                .copyWith(color: AppColors.black),
                          ),
                        ],
                      ),
                    );
                  }),
                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── Currency Picker ───────────────────────────────────

  void _showCurrencyPicker(String currentCode) {
    showSpendlerSheet<void>(
      context: context,
      isScrollControlled: false,
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Select Currency',
                      style: AppTextStyles.headingS
                          .copyWith(color: AppColors.black)),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              ...Currency.values.map((c) {
                final isSelected = c.name == currentCode;
                return ListTile(
                  leading: Text(c.symbol,
                      style: const TextStyle(fontSize: 20)),
                  title: Text('${c.code} - ${c.label}',
                      style: AppTextStyles.bodyM.copyWith(
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w400)),
                  trailing: isSelected
                      ? const Icon(Icons.check, color: AppColors.black, size: 20)
                      : null,
                  onTap: () async {
                    await saveSelectedCurrency(c.name);
                    ref.invalidate(selectedCurrencyProvider);
                    if (mounted) Navigator.pop(context);
                  },
                );
              }),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        );
      },
    );
  }

  // ─── Categories Sheet ──────────────────────────────────

  void _showCategoriesSheet() {
    showSpendlerSheet<void>(
      context: context,
      builder: (_) {
        final categories = TransactionCategory.groups;
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          maxChildSize: 0.85,
          builder: (_, scrollController) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Categories',
                        style: AppTextStyles.headingS
                            .copyWith(color: AppColors.black)),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    itemCount: categories.length,
                    itemBuilder: (_, i) {
                      final cat = categories[i];
                      final subs = Subcategory.all
                          .where((s) => s.group == cat)
                          .toList();
                      return ExpansionTile(
                        leading: Icon(cat.iconFill, size: 22,
                            color: AppColors.gray600),
                        title: Text(cat.label,
                            style: AppTextStyles.bodyM.copyWith(
                                fontWeight: FontWeight.w600)),
                        children: subs.map((s) {
                          return ListTile(
                            dense: true,
                            leading: Icon(s.icon, size: 18,
                                color: AppColors.gray500),
                            title: Text(s.name,
                                style: AppTextStyles.bodyS),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ─── Budget Editor ─────────────────────────────────────

  void _showBudgetEditor(double? current) {
    final controller = TextEditingController(
        text: current != null ? current.toStringAsFixed(0) : '');
    showSpendlerSheet<void>(
      context: context,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Monthly Budget',
                  style: AppTextStyles.headingS
                      .copyWith(color: AppColors.black)),
              const SizedBox(height: 4),
              Text('This is your total spending limit across all categories for the month.',
                  style: AppTextStyles.bodyS
                      .copyWith(color: AppColors.gray500)),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: controller,
                autofocus: true,
                keyboardType: TextInputType.number,
                style: AppTextStyles.displayL,
                decoration: InputDecoration(
                  hintText: '0',
                  hintStyle: AppTextStyles.displayL
                      .copyWith(color: AppColors.gray300),
                  border: InputBorder.none,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  label: 'Save',
                  onTap: () async {
                    final val = double.tryParse(controller.text);
                    if (val != null && val > 0) {
                      await saveMonthlyBudget(val);
                      ref.invalidate(monthlyBudgetProvider);
                    }
                    if (mounted) Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── Help & Support ────────────────────────────────────

  void _showHelpSheet() {
    showSpendlerSheet<void>(
      context: context,
      builder: (_) => const _HelpSupportSheet(),
    );
  }

  // ─── Log Out ───────────────────────────────────────────

  void _confirmLogout() {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.white,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.lg),
          title: Text('Log Out',
              style: AppTextStyles.headingS.copyWith(color: AppColors.black)),
          content: Text('Are you sure you want to log out?',
              style: AppTextStyles.bodyM.copyWith(color: AppColors.gray500)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel',
                  style: AppTextStyles.bodyM
                      .copyWith(color: AppColors.gray500)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final authService = ref.read(authServiceProvider);
                await authService.signOut();
                if (mounted) context.go('/onboarding/step1');
              },
              child: Text('Log Out',
                  style: AppTextStyles.bodyM.copyWith(
                      color: AppColors.red, fontWeight: FontWeight.w700)),
            ),
          ],
        );
      },
    );
  }

  // ─── Delete Account ────────────────────────────────────

  void _confirmDeleteAccount() {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.white,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.lg),
          title: Text('Delete Account',
              style: AppTextStyles.headingS.copyWith(color: AppColors.red)),
          content: Text(
              'This will permanently delete your account and all data. This action cannot be undone.',
              style: AppTextStyles.bodyM.copyWith(color: AppColors.gray500)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel',
                  style: AppTextStyles.bodyM
                      .copyWith(color: AppColors.gray500)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  final authService = ref.read(authServiceProvider);
                  final user = authService.currentUser;
                  if (user != null) {
                    await user.delete();
                  }
                  await authService.clearLocalAuth();
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.clear();
                  if (mounted) context.go('/onboarding/step2');
                } on Exception {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Couldn\'t delete account. Please try again.')),
                    );
                  }
                }
              },
              child: Text('Delete',
                  style: AppTextStyles.bodyM.copyWith(
                      color: AppColors.red, fontWeight: FontWeight.w700)),
            ),
          ],
        );
      },
    );
  }

  void _showProfileSheet(BuildContext context) {
    showSpendlerSheet<void>(
      context: context,
      builder: (_) => const ProfileSheet(),
    );
  }
}

// ---------------------------------------------------------------------------
// Help & Support Sheet
// ---------------------------------------------------------------------------

class _HelpSupportSheet extends StatefulWidget {
  const _HelpSupportSheet();

  @override
  State<_HelpSupportSheet> createState() => _HelpSupportSheetState();
}

class _HelpSupportSheetState extends State<_HelpSupportSheet> {
  int? _expandedFaq;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      builder: (_, scrollController) {
        return Column(
          children: [
            const SizedBox(height: AppSpacing.sm),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Help & Support',
                    style: AppTextStyles.headingS
                        .copyWith(color: AppColors.black)),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg),
                children: [
                  // Email Us
                  _helpTile(
                    icon: PhosphorIcons.envelope(),
                    title: 'Email Us',
                    subtitle: 'divysharma029@gmail.com',
                    onTap: () {
                      launchUrl(
                        Uri.parse(
                            'mailto:divysharma029@gmail.com?subject=CoinFlo%20Support'),
                        mode: LaunchMode.externalApplication,
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // Report a Bug
                  _helpTile(
                    icon: PhosphorIcons.bug(),
                    title: 'Report a Bug',
                    subtitle: 'Help us improve CoinFlo',
                    onTap: () {
                      Navigator.pop(context);
                      showDialog<void>(
                        context: context,
                        builder: (_) => const _ReportBugDialog(),
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // FAQ section
                  Text('FAQ',
                      style: AppTextStyles.labelM
                          .copyWith(color: AppColors.gray500)),
                  const SizedBox(height: AppSpacing.sm),

                  ...List.generate(kFaqs.length, (i) {
                    final faq = kFaqs[i];
                    final expanded = _expandedFaq == i;
                    return Container(
                      margin:
                          const EdgeInsets.only(bottom: AppSpacing.xs),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: AppRadius.base,
                        border: Border.all(
                          color: expanded
                              ? AppColors.black
                              : AppColors.gray200,
                        ),
                      ),
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: () => setState(() {
                              _expandedFaq = expanded ? null : i;
                            }),
                            behavior: HitTestBehavior.opaque,
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      faq['q']!,
                                      style: AppTextStyles.bodyM.copyWith(
                                        color: AppColors.black,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    expanded
                                        ? Icons.keyboard_arrow_up
                                        : Icons.keyboard_arrow_down,
                                    color: AppColors.gray500,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (expanded)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                  AppSpacing.md,
                                  0,
                                  AppSpacing.md,
                                  AppSpacing.md),
                              child: Text(
                                faq['a']!,
                                style: AppTextStyles.bodyS
                                    .copyWith(color: AppColors.gray500),
                              ),
                            ),
                        ],
                      ),
                    );
                  }),

                  const SizedBox(height: AppSpacing.lg),
                  Center(
                    child: Text('CoinFlo v1.0.2',
                        style: AppTextStyles.bodyS
                            .copyWith(color: AppColors.gray300)),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _helpTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.offWhite,
          borderRadius: AppRadius.md,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: AppRadius.sm,
              ),
              child: Icon(icon, size: 20, color: AppColors.gray600),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: AppTextStyles.bodyM
                          .copyWith(fontWeight: FontWeight.w600)),
                  Text(subtitle,
                      style: AppTextStyles.bodyS
                          .copyWith(color: AppColors.gray500)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                color: AppColors.gray500, size: 20),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Report a Bug Dialog
// ---------------------------------------------------------------------------

class _ReportBugDialog extends StatefulWidget {
  const _ReportBugDialog();

  @override
  State<_ReportBugDialog> createState() => _ReportBugDialogState();
}

class _ReportBugDialogState extends State<_ReportBugDialog> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.white,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.lg),
      insetPadding: const EdgeInsets.all(AppSpacing.lg),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.red.withValues(alpha: 0.1),
                    borderRadius: AppRadius.sm,
                  ),
                  child: const Icon(Icons.bug_report_outlined,
                      color: AppColors.red, size: 22),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text('Report a Bug',
                    style: AppTextStyles.headingS
                        .copyWith(color: AppColors.black)),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _titleCtrl,
              style: AppTextStyles.bodyM.copyWith(color: AppColors.black),
              decoration: InputDecoration(
                hintText: 'Brief title',
                hintStyle:
                    AppTextStyles.bodyM.copyWith(color: AppColors.gray300),
                filled: true,
                fillColor: AppColors.gray100,
                border: OutlineInputBorder(
                  borderRadius: AppRadius.base,
                  borderSide: BorderSide.none,
                ),
                isDense: true,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _descCtrl,
              style: AppTextStyles.bodyM.copyWith(color: AppColors.black),
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Describe what happened...',
                hintStyle:
                    AppTextStyles.bodyM.copyWith(color: AppColors.gray300),
                filled: true,
                fillColor: AppColors.gray100,
                border: OutlineInputBorder(
                  borderRadius: AppRadius.base,
                  borderSide: BorderSide.none,
                ),
                isDense: true,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.gray100,
                        borderRadius: AppRadius.base,
                      ),
                      alignment: Alignment.center,
                      child: Text('Cancel',
                          style: AppTextStyles.bodyM.copyWith(
                              color: AppColors.gray500,
                              fontWeight: FontWeight.w500)),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: GestureDetector(
                    onTap: _sending ? null : _submit,
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.black,
                        borderRadius: AppRadius.base,
                      ),
                      alignment: Alignment.center,
                      child: _sending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.white))
                          : Text('Submit',
                              style: AppTextStyles.bodyM.copyWith(
                                  color: AppColors.white,
                                  fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final title = _titleCtrl.text.trim();
    final desc = _descCtrl.text.trim();
    if (title.isEmpty && desc.isEmpty) return;

    setState(() => _sending = true);

    // Store in SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString('bug_reports') ?? '[]';
    final reports = List<dynamic>.from(jsonDecode(existing) as List);
    reports.add({
      'title': title,
      'description': desc,
      'timestamp': DateTime.now().toIso8601String(),
    });
    await prefs.setString('bug_reports', jsonEncode(reports));

    // Open email client
    final subject = Uri.encodeComponent('Bug Report: $title');
    final body = Uri.encodeComponent(
        'Title: $title\n\nDescription:\n$desc\n\nReported at: ${DateTime.now()}');
    await launchUrl(
      Uri.parse(
          'mailto:divysharma029@gmail.com?subject=$subject&body=$body'),
      mode: LaunchMode.externalApplication,
    );

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thanks for the report — we\'ll look into it.')),
      );
    }
  }
}

// ---------------------------------------------------------------------------
// Settings Row
// ---------------------------------------------------------------------------

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    this.trailing,
    this.onTap,
    this.showChevron = true,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
              child: Center(
                  child: PhosphorIcon(icon, color: iconColor, size: 18)),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(label,
                  style: AppTextStyles.bodyM.copyWith(color: AppColors.black),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ),
            if (trailing != null) ...[trailing!, const SizedBox(width: AppSpacing.xs)],
            if (showChevron)
              PhosphorIcon(PhosphorIcons.caretRight(),
                  color: AppColors.gray500, size: 16),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Settings Toggle Row
// ---------------------------------------------------------------------------

class _SettingsToggleRow extends StatelessWidget {
  const _SettingsToggleRow({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Center(
                child: PhosphorIcon(icon, color: iconColor, size: 18)),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(label,
                style: AppTextStyles.bodyM.copyWith(color: AppColors.black),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ),
          CupertinoSwitch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppColors.black,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Divider
// ---------------------------------------------------------------------------

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(left: 64),
      child: Divider(height: 1, thickness: 0.5, color: AppColors.gray200),
    );
  }
}
