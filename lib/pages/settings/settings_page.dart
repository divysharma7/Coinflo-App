import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:finance_buddy_app/core/enums.dart';
import 'package:finance_buddy_app/design_system/design_system.dart';
import 'package:finance_buddy_app/providers/providers.dart';
import 'package:finance_buddy_app/providers/onboarding_provider.dart';
import 'package:finance_buddy_app/pages/penny/penny_page.dart';
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

    final name = userName.valueOrNull ?? 'User';
    final email = userEmail.valueOrNull ?? 'Not set';
    final currencyCode = currencyAsync.valueOrNull ?? 'inr';
    final trackIncome = trackIncomeAsync.valueOrNull ?? true;

    // Resolve currency display
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
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
              ),
              children: [
                // Title
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 24, 0, 20),
                  child: Text(
                    'Settings',
                    style: AppTextStyles.headingL.copyWith(
                      color: AppColors.black,
                    ),
                  ),
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
                        // Avatar
                        Container(
                          width: 36,
                          height: 36,
                          decoration: const BoxDecoration(
                            color: AppColors.gray100,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: PhosphorIcon(
                              PhosphorIcons.user(),
                              color: AppColors.gray600,
                              size: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: AppTextStyles.headingS.copyWith(
                                  color: AppColors.black,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                email,
                                style: AppTextStyles.bodyS.copyWith(
                                  color: AppColors.gray500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        PhosphorIcon(
                          PhosphorIcons.caretRight(),
                          color: AppColors.gray500,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.xxl),

                // ─── GENERAL Section ─────────────────────
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 10),
                  child: Text(
                    'GENERAL',
                    style: AppTextStyles.labelM.copyWith(
                      color: AppColors.gray400,
                    ),
                  ),
                ),
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
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                              builder: (_) => const PennyPage()),
                        ),
                      ),
                      const _Divider(),
                      _SettingsRow(
                        icon: PhosphorIcons.crown(),
                        iconBg: AppColors.gray100,
                        iconColor: AppColors.gray600,
                        label: 'Plans & Pricing',
                        onTap: () => _showComingSoon(),
                      ),
                      const _Divider(),
                      _SettingsRow(
                        icon: PhosphorIcons.crown(),
                        iconBg: AppColors.gray100,
                        iconColor: AppColors.gray600,
                        label: 'Manage Subscription',
                        onTap: () => _showComingSoon(),
                      ),
                      const _Divider(),
                      _SettingsRow(
                        icon: PhosphorIcons.usersThree(),
                        iconBg: AppColors.gray100,
                        iconColor: AppColors.gray600,
                        label: 'People & Debts',
                        onTap: () => _showComingSoon(),
                      ),
                      const _Divider(),
                      _SettingsRow(
                        icon: PhosphorIcons.currencyDollar(),
                        iconBg: AppColors.gray100,
                        iconColor: AppColors.gray600,
                        label: 'Currency',
                        trailing: Text(
                          currencyDisplay,
                          style: AppTextStyles.bodyS.copyWith(
                            color: AppColors.gray500,
                          ),
                        ),
                        onTap: () => _showComingSoon(),
                      ),
                      const _Divider(),
                      _SettingsRow(
                        icon: PhosphorIcons.creditCard(),
                        iconBg: AppColors.gray100,
                        iconColor: AppColors.gray600,
                        label: 'Accounts',
                        onTap: () => _showComingSoon(),
                      ),
                      const _Divider(),
                      _SettingsRow(
                        icon: PhosphorIcons.arrowsClockwise(),
                        iconBg: AppColors.gray100,
                        iconColor: AppColors.gray600,
                        label: 'Subscriptions',
                        onTap: () => _showComingSoon(),
                      ),
                      const _Divider(),
                      _SettingsRow(
                        icon: PhosphorIcons.tag(),
                        iconBg: AppColors.gray100,
                        iconColor: AppColors.gray600,
                        label: 'Categories',
                        onTap: () => _showComingSoon(),
                      ),
                      const _Divider(),
                      _SettingsRow(
                        icon: PhosphorIcons.sliders(),
                        iconBg: AppColors.gray100,
                        iconColor: AppColors.gray600,
                        label: 'Monthly Budget',
                        onTap: () => _showComingSoon(),
                      ),
                      const _Divider(),
                      _SettingsRow(
                        icon: PhosphorIcons.lightning(),
                        iconBg: AppColors.gray100,
                        iconColor: AppColors.gray600,
                        label: 'Smart Rules',
                        onTap: () => _showComingSoon(),
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
                        onChanged: (v) {
                          setState(() => _notificationsEnabled = v);
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.xxl),

                // ─── ABOUT Section ───────────────────────
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 10),
                  child: Text(
                    'ABOUT',
                    style: AppTextStyles.labelM.copyWith(
                      color: AppColors.gray400,
                    ),
                  ),
                ),
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
                        onTap: () => _showComingSoon(),
                      ),
                      const _Divider(),
                      _SettingsRow(
                        icon: PhosphorIcons.star(),
                        iconBg: AppColors.gray100,
                        iconColor: AppColors.gray600,
                        label: 'Rate the App',
                        onTap: () => _showComingSoon(),
                      ),
                      const _Divider(),
                      _SettingsRow(
                        icon: PhosphorIcons.info(),
                        iconBg: AppColors.gray100,
                        iconColor: AppColors.gray600,
                        label: 'Version',
                        trailing: Text(
                          '1.0.2',
                          style: AppTextStyles.bodyS.copyWith(
                            color: AppColors.gray500,
                          ),
                        ),
                        showChevron: false,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.xxl),

                // ─── Log Out ─────────────────────────────
                GestureDetector(
                  onTap: () => _showComingSoon(),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: const BoxDecoration(
                      color: AppColors.gray100,
                      borderRadius: AppRadius.xl,
                    ),
                    child: Center(
                      child: Text(
                        'Log Out',
                        style: AppTextStyles.bodyM.copyWith(
                          color: AppColors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.sm),

                // ─── Delete Account ──────────────────────
                GestureDetector(
                  onTap: () => _showComingSoon(),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: const BoxDecoration(
                      color: AppColors.gray100,
                      borderRadius: AppRadius.xl,
                    ),
                    child: Center(
                      child: Text(
                        'Delete Account',
                        style: AppTextStyles.bodyM.copyWith(
                          color: AppColors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
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

  void _showComingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Coming soon')),
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
// Settings Row (tappable with icon circle, label, optional trailing, chevron)
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
          horizontal: AppSpacing.md,
          vertical: 13,
        ),
        child: Row(
          children: [
            // Icon circle
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconBg,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: PhosphorIcon(icon, color: iconColor, size: 18),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            // Label
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.bodyM.copyWith(
                  color: AppColors.black,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (trailing != null) ...[
              trailing!,
              const SizedBox(width: AppSpacing.xs),
            ],
            if (showChevron)
              PhosphorIcon(
                PhosphorIcons.caretRight(),
                color: AppColors.gray500,
                size: 16,
              ),
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
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 6,
      ),
      child: Row(
        children: [
          // Icon circle
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: PhosphorIcon(icon, color: iconColor, size: 18),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          // Label
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.bodyM.copyWith(
                color: AppColors.black,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
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
