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
import 'package:finance_buddy_app/pages/penny/penny_page.dart';
import 'package:finance_buddy_app/pages/people/people_page.dart';
import 'package:finance_buddy_app/pages/subscriptions/subscriptions_page.dart';
import 'package:finance_buddy_app/pages/settings/profile_sheet.dart';
import 'package:finance_buddy_app/widgets/common/spendler_bottom_sheet.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _notificationsEnabled = true;

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
                        label: 'Ask Penny',
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute<void>(builder: (_) => const PennyPage())),
                      ),
                      const _Divider(),
                      _SettingsRow(
                        icon: PhosphorIcons.usersThree(),
                        iconBg: AppColors.gray100,
                        iconColor: AppColors.gray600,
                        label: 'People & Debts',
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute<void>(builder: (_) => const PeoplePage())),
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
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute<void>(builder: (_) => const SubscriptionsPage())),
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
                          budget != null ? '\$${budget.toStringAsFixed(0)}' : 'Not set',
                          style: AppTextStyles.bodyS
                              .copyWith(color: AppColors.gray500),
                        ),
                        onTap: () => _showBudgetEditor(budget),
                      ),
                      const _Divider(),
                      _SettingsRow(
                        icon: PhosphorIcons.lightning(),
                        iconBg: AppColors.gray100,
                        iconColor: AppColors.gray600,
                        label: 'Smart Rules',
                        onTap: () => _showSmartRulesSheet(),
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
                        onChanged: (v) => setState(() => _notificationsEnabled = v),
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
                        icon: PhosphorIcons.star(),
                        iconBg: AppColors.gray100,
                        iconColor: AppColors.gray600,
                        label: 'Rate the App',
                        onTap: () => _showRateDialog(),
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
          style: AppTextStyles.labelM.copyWith(color: AppColors.gray400)),
    );
  }

  // ─── Currency Picker ───────────────────────────────────

  void _showCurrencyPicker(String currentCode) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: AppSpacing.md),
              Container(width: 40, height: 4,
                  decoration: BoxDecoration(
                      color: AppColors.gray300,
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: AppSpacing.lg),
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
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        final categories = TransactionCategory.groups;
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          maxChildSize: 0.85,
          builder: (_, scrollController) {
            return Column(
              children: [
                const SizedBox(height: AppSpacing.md),
                Container(width: 40, height: 4,
                    decoration: BoxDecoration(
                        color: AppColors.gray300,
                        borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: AppSpacing.lg),
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
                                color: AppColors.gray400),
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
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
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

  // ─── Smart Rules Sheet ─────────────────────────────────

  void _showSmartRulesSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.5,
          maxChildSize: 0.85,
          builder: (_, scrollController) {
            return FutureBuilder<SharedPreferences>(
              future: SharedPreferences.getInstance(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                      child: CircularProgressIndicator(color: AppColors.black));
                }
                final prefs = snapshot.data!;
                final rulesJson = prefs.getString('smart_rules');
                List<dynamic> rules = [];
                if (rulesJson != null) {
                  try {
                    rules = List<dynamic>.from(jsonDecode(rulesJson) as List);
                  } catch (_) {}
                }

                return Column(
                  children: [
                    const SizedBox(height: AppSpacing.md),
                    Container(width: 40, height: 4,
                        decoration: BoxDecoration(
                            color: AppColors.gray300,
                            borderRadius: BorderRadius.circular(2))),
                    const SizedBox(height: AppSpacing.lg),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Smart Rules',
                              style: AppTextStyles.headingS
                                  .copyWith(color: AppColors.black)),
                          Text('${rules.length} rules',
                              style: AppTextStyles.bodyS
                                  .copyWith(color: AppColors.gray400)),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Expanded(
                      child: rules.isEmpty
                          ? Center(
                              child: Text('No smart rules configured.',
                                  style: AppTextStyles.bodyM
                                      .copyWith(color: AppColors.gray400)))
                          : ListView.builder(
                              controller: scrollController,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md),
                              itemCount: rules.length,
                              itemBuilder: (_, i) {
                                final rule =
                                    rules[i] as Map<String, dynamic>;
                                return ListTile(
                                  leading: Container(
                                    width: 36,
                                    height: 36,
                                    decoration: const BoxDecoration(
                                      color: AppColors.gray100,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: PhosphorIcon(
                                        PhosphorIcons.lightning(),
                                        color: AppColors.gray600,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                      rule['keyword'] as String? ?? '',
                                      style: AppTextStyles.bodyM.copyWith(
                                          fontWeight: FontWeight.w500)),
                                  subtitle: Text(
                                      rule['categoryName'] as String? ?? '',
                                      style: AppTextStyles.bodyS
                                          .copyWith(color: AppColors.gray400)),
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
      },
    );
  }

  // ─── Help & Support ────────────────────────────────────

  void _showHelpSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(width: 40, height: 4,
                      decoration: BoxDecoration(
                          color: AppColors.gray300,
                          borderRadius: BorderRadius.circular(2))),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text('Help & Support',
                    style: AppTextStyles.headingS
                        .copyWith(color: AppColors.black)),
                const SizedBox(height: AppSpacing.lg),
                _helpRow(PhosphorIcons.envelope(), 'Email Us',
                    'support@spendler.app'),
                const SizedBox(height: AppSpacing.md),
                _helpRow(PhosphorIcons.chatCircle(), 'FAQ',
                    'Common questions answered'),
                const SizedBox(height: AppSpacing.md),
                _helpRow(PhosphorIcons.bug(), 'Report a Bug',
                    'Help us improve Spendler'),
                const SizedBox(height: AppSpacing.lg),
                Center(
                  child: Text('Spendler v1.0.2',
                      style: AppTextStyles.bodyS
                          .copyWith(color: AppColors.gray400)),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _helpRow(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            color: AppColors.gray100,
            borderRadius: AppRadius.md,
          ),
          child: Icon(icon, size: 20, color: AppColors.gray600),
        ),
        const SizedBox(width: AppSpacing.sm),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: AppTextStyles.bodyM
                    .copyWith(fontWeight: FontWeight.w600)),
            Text(subtitle,
                style: AppTextStyles.bodyS
                    .copyWith(color: AppColors.gray400)),
          ],
        ),
      ],
    );
  }

  // ─── Rate the App ──────────────────────────────────────

  void _showRateDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Enjoying Spendler?',
              style: AppTextStyles.headingS.copyWith(color: AppColors.black)),
          content: Text(
              'If you love using Spendler, please take a moment to rate us!',
              style: AppTextStyles.bodyM.copyWith(color: AppColors.gray500)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Not Now',
                  style: AppTextStyles.bodyM
                      .copyWith(color: AppColors.gray500)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                // Open Play Store listing
                launchUrl(
                  Uri.parse(
                      'https://play.google.com/store/apps/details?id=com.divysharma.finance_buddy_app'),
                  mode: LaunchMode.externalApplication,
                );
              },
              child: Text('Rate Now',
                  style: AppTextStyles.bodyM.copyWith(
                      color: AppColors.black, fontWeight: FontWeight.w700)),
            ),
          ],
        );
      },
    );
  }

  // ─── Log Out ───────────────────────────────────────────

  void _confirmLogout() {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                  if (mounted) context.go('/onboarding/step1');
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to delete account: $e')),
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
