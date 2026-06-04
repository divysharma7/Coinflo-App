import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:finance_buddy_app/core/enums.dart';
import 'package:finance_buddy_app/design_system/design_system.dart';
import 'package:finance_buddy_app/providers/providers.dart';
import 'package:finance_buddy_app/providers/onboarding_provider.dart';
import 'package:finance_buddy_app/providers/auth_provider.dart';
import 'package:finance_buddy_app/pages/settings/profile_sheet.dart';
import 'package:finance_buddy_app/widgets/common/spendler_bottom_sheet.dart';
import 'package:finance_buddy_app/pages/settings/widgets/settings_row.dart';
import 'package:finance_buddy_app/pages/settings/widgets/settings_toggle_row.dart';
import 'package:finance_buddy_app/pages/settings/widgets/settings_divider.dart';
import 'package:finance_buddy_app/pages/settings/widgets/settings_help_support_sheet.dart';

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
    final trackIncomeAsync = ref.watch(trackIncomeProvider);
    final budgetAsync = ref.watch(monthlyBudgetProvider);

    final name = userName.valueOrNull ?? 'User';
    final email = userEmail.valueOrNull ?? 'Not set';
    final trackIncome = trackIncomeAsync.valueOrNull ?? true;
    final budget = budgetAsync.valueOrNull;

    const currency = Currency.inr;

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
                      style: AppTextStyles.displayL
                          .copyWith(color: AppColors.black)),
                ),

                // ─── Profile Card ────────────────────────
                GestureDetector(
                  onTap: () => _showProfileSheet(context),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: const BoxDecoration(
                      color: AppColors.white,
                      borderRadius: AppRadius.xl,
                      boxShadow: AppShadows.sm,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: const BoxDecoration(
                            color: AppColors.black,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(_initials(name),
                                style: AppTextStyles.bodyL.copyWith(
                                    color: AppColors.white,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0)),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name,
                                  style: AppTextStyles.headingS.copyWith(
                                      color: AppColors.black,
                                      fontWeight: FontWeight.w700),
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
                            color: AppColors.gray400, size: 18),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.xxl),

                // ─── GENERAL Section ─────────────────────
                _sectionLabel('GENERAL'),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  decoration: const BoxDecoration(
                    color: AppColors.white,
                    borderRadius: AppRadius.xl,
                    boxShadow: AppShadows.sm,
                  ),
                  child: Column(
                    children: [
                      SettingsRow(
                        icon: PhosphorIcons.lightning(),
                        iconBg: AppColors.gray100,
                        iconColor: AppColors.gray600,
                        label: 'Ask Saraswati',
                        onTap: () => context.push('/settings/saraswati'),
                      ),
                      const SettingsDivider(),
                      SettingsRow(
                        icon: PhosphorIcons.currencyInr(),
                        iconBg: AppColors.gray100,
                        iconColor: AppColors.gray600,
                        label: 'Currency',
                        trailing: Text(
                          '${currency.code} (${currency.symbol})',
                          style: AppTextStyles.bodyS
                              .copyWith(color: AppColors.gray500),
                        ),
                        showChevron: false,
                      ),
                      const SettingsDivider(),
                      SettingsRow(
                        icon: PhosphorIcons.usersThree(),
                        iconBg: AppColors.gray100,
                        iconColor: AppColors.gray600,
                        label: 'People & Debts',
                        onTap: () => context.push('/settings/people'),
                      ),
                      const SettingsDivider(),
                      SettingsRow(
                        icon: PhosphorIcons.creditCard(),
                        iconBg: AppColors.gray100,
                        iconColor: AppColors.gray600,
                        label: 'Accounts',
                        onTap: () => context.push('/accounts'),
                      ),
                      const SettingsDivider(),
                      SettingsRow(
                        icon: PhosphorIcons.arrowsClockwise(),
                        iconBg: AppColors.gray100,
                        iconColor: AppColors.gray600,
                        label: 'Subscriptions',
                        onTap: () => context.push('/settings/subscriptions'),
                      ),
                      const SettingsDivider(),
                      SettingsRow(
                        icon: PhosphorIcons.tag(),
                        iconBg: AppColors.gray100,
                        iconColor: AppColors.gray600,
                        label: 'Categories',
                        onTap: () => _showCategoriesSheet(),
                      ),
                      const SettingsDivider(),
                      SettingsRow(
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
                      const SettingsDivider(),
                      SettingsToggleRow(
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
                      const SettingsDivider(),
                      SettingsToggleRow(
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
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  decoration: const BoxDecoration(
                    color: AppColors.white,
                    borderRadius: AppRadius.xl,
                    boxShadow: AppShadows.sm,
                  ),
                  child: Column(
                    children: [
                      SettingsRow(
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
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  decoration: const BoxDecoration(
                    color: AppColors.white,
                    borderRadius: AppRadius.xl,
                    boxShadow: AppShadows.sm,
                  ),
                  child: Column(
                    children: [
                      SettingsRow(
                        icon: PhosphorIcons.question(),
                        iconBg: AppColors.gray100,
                        iconColor: AppColors.gray600,
                        label: 'Help & Support',
                        onTap: () => _showHelpSheet(),
                      ),
                      const SettingsDivider(),
                      SettingsRow(
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
          style: AppTextStyles.section.copyWith(color: AppColors.gray400)),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
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
      builder: (_) => const SettingsHelpSupportSheet(),
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
                if (mounted) context.go('/onboarding/welcome');
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
                  if (mounted) context.go('/onboarding/welcome');
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
