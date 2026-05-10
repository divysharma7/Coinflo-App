import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:finance_buddy_app/core/enums.dart';
import 'package:finance_buddy_app/core/tokens.dart';
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
      backgroundColor: SpendlerColors.scaffold,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: SpendlerSpacing.screenH,
          ),
          children: [
            // Title
            const Padding(
              padding: EdgeInsets.fromLTRB(0, 24, 0, 20),
              child: Text(
                'Settings',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: SpendlerColors.textPrimary,
                ),
              ),
            ),

            // ─── Profile Card ────────────────────────
            GestureDetector(
              onTap: () => _showProfileSheet(context),
              child: Container(
                padding: const EdgeInsets.all(SpendlerSpacing.md),
                decoration: BoxDecoration(
                  color: SpendlerColors.surface,
                  borderRadius: BorderRadius.circular(SpendlerRadii.card),
                ),
                child: Row(
                  children: [
                    // Avatar
                    Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: SpendlerColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: PhosphorIcon(
                          PhosphorIcons.user(),
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: SpendlerSpacing.cardGap),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: SpendlerColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            email,
                            style: const TextStyle(
                              fontSize: 13,
                              color: SpendlerColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PhosphorIcon(
                      PhosphorIcons.caretRight(),
                      color: SpendlerColors.textTertiary,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: SpendlerSpacing.xl),

            // ─── GENERAL Section ─────────────────────
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 10),
              child: Text('GENERAL', style: SpendlerTextStyles.sectionLabel),
            ),
            Container(
              decoration: BoxDecoration(
                color: SpendlerColors.surface,
                borderRadius: BorderRadius.circular(SpendlerRadii.card),
              ),
              child: Column(
                children: [
                  _SettingsRow(
                    icon: PhosphorIcons.lightning(),
                    iconBg: const Color(0xFFFFF3E0),
                    iconColor: const Color(0xFFF59E0B),
                    label: 'Ask Penny',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(builder: (_) => const PennyPage()),
                    ),
                  ),
                  const _Divider(),
                  _SettingsRow(
                    icon: PhosphorIcons.crown(),
                    iconBg: const Color(0xFFFEF3C7),
                    iconColor: const Color(0xFFF59E0B),
                    label: 'Plans & Pricing',
                    onTap: () => _showComingSoon(),
                  ),
                  const _Divider(),
                  _SettingsRow(
                    icon: PhosphorIcons.crown(),
                    iconBg: const Color(0xFFFEF3C7),
                    iconColor: const Color(0xFFF59E0B),
                    label: 'Manage Subscription',
                    onTap: () => _showComingSoon(),
                  ),
                  const _Divider(),
                  _SettingsRow(
                    icon: PhosphorIcons.usersThree(),
                    iconBg: const Color(0xFFE3F2FD),
                    iconColor: const Color(0xFF3B82F6),
                    label: 'People & Debts',
                    onTap: () => _showComingSoon(),
                  ),
                  const _Divider(),
                  _SettingsRow(
                    icon: PhosphorIcons.currencyDollar(),
                    iconBg: const Color(0xFFDCFCE7),
                    iconColor: const Color(0xFF22C55E),
                    label: 'Currency',
                    trailing: Text(
                      currencyDisplay,
                      style: const TextStyle(
                        fontSize: 14,
                        color: SpendlerColors.textTertiary,
                      ),
                    ),
                    onTap: () => _showComingSoon(),
                  ),
                  const _Divider(),
                  _SettingsRow(
                    icon: PhosphorIcons.creditCard(),
                    iconBg: const Color(0xFFEDE7F6),
                    iconColor: const Color(0xFF8B5CF6),
                    label: 'Accounts',
                    onTap: () => _showComingSoon(),
                  ),
                  const _Divider(),
                  _SettingsRow(
                    icon: PhosphorIcons.arrowsClockwise(),
                    iconBg: const Color(0xFFE3F2FD),
                    iconColor: const Color(0xFF3B82F6),
                    label: 'Subscriptions',
                    onTap: () => _showComingSoon(),
                  ),
                  const _Divider(),
                  _SettingsRow(
                    icon: PhosphorIcons.tag(),
                    iconBg: const Color(0xFFFCE4EC),
                    iconColor: const Color(0xFFEC4899),
                    label: 'Categories',
                    onTap: () => _showComingSoon(),
                  ),
                  const _Divider(),
                  _SettingsRow(
                    icon: PhosphorIcons.sliders(),
                    iconBg: const Color(0xFFF5F5F7),
                    iconColor: SpendlerColors.textSecondary,
                    label: 'Monthly Budget',
                    onTap: () => _showComingSoon(),
                  ),
                  const _Divider(),
                  _SettingsRow(
                    icon: PhosphorIcons.lightning(),
                    iconBg: const Color(0xFFFFF3E0),
                    iconColor: const Color(0xFFF59E0B),
                    label: 'Smart Rules',
                    onTap: () => _showComingSoon(),
                  ),
                  const _Divider(),
                  _SettingsToggleRow(
                    icon: PhosphorIcons.trendUp(),
                    iconBg: const Color(0xFFDCFCE7),
                    iconColor: const Color(0xFF22C55E),
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
                    iconBg: const Color(0xFFE3F2FD),
                    iconColor: const Color(0xFF3B82F6),
                    label: 'Notifications',
                    value: _notificationsEnabled,
                    onChanged: (v) {
                      setState(() => _notificationsEnabled = v);
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: SpendlerSpacing.xl),

            // ─── ABOUT Section ───────────────────────
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 10),
              child: Text('ABOUT', style: SpendlerTextStyles.sectionLabel),
            ),
            Container(
              decoration: BoxDecoration(
                color: SpendlerColors.surface,
                borderRadius: BorderRadius.circular(SpendlerRadii.card),
              ),
              child: Column(
                children: [
                  _SettingsRow(
                    icon: PhosphorIcons.question(),
                    iconBg: const Color(0xFFF5F5F7),
                    iconColor: SpendlerColors.textSecondary,
                    label: 'Help & Support',
                    onTap: () => _showComingSoon(),
                  ),
                  const _Divider(),
                  _SettingsRow(
                    icon: PhosphorIcons.star(),
                    iconBg: const Color(0xFFFEF3C7),
                    iconColor: const Color(0xFFF59E0B),
                    label: 'Rate the App',
                    onTap: () => _showComingSoon(),
                  ),
                  const _Divider(),
                  _SettingsRow(
                    icon: PhosphorIcons.info(),
                    iconBg: const Color(0xFFF5F5F7),
                    iconColor: SpendlerColors.textSecondary,
                    label: 'Version',
                    trailing: const Text(
                      '1.0.2',
                      style: TextStyle(
                        fontSize: 14,
                        color: SpendlerColors.textTertiary,
                      ),
                    ),
                    showChevron: false,
                  ),
                ],
              ),
            ),

            const SizedBox(height: SpendlerSpacing.xl),

            // ─── Log Out ─────────────────────────────
            GestureDetector(
              onTap: () => _showComingSoon(),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: SpendlerColors.surface,
                  borderRadius: BorderRadius.circular(SpendlerRadii.card),
                ),
                child: const Center(
                  child: Text(
                    'Log Out',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: SpendlerColors.expense,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: SpendlerSpacing.cardGap),

            // ─── Delete Account ──────────────────────
            GestureDetector(
              onTap: () => _showComingSoon(),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: SpendlerColors.surface,
                  borderRadius: BorderRadius.circular(SpendlerRadii.card),
                ),
                child: const Center(
                  child: Text(
                    'Delete Account',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: SpendlerColors.expense,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 100),
          ],
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
          horizontal: SpendlerSpacing.md,
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
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: PhosphorIcon(icon, color: iconColor, size: 18),
              ),
            ),
            const SizedBox(width: SpendlerSpacing.cardGap),
            // Label
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: SpendlerColors.textPrimary,
                ),
              ),
            ),
            if (trailing != null) ...[
              trailing!,
              const SizedBox(width: SpendlerSpacing.sm),
            ],
            if (showChevron)
              PhosphorIcon(
                PhosphorIcons.caretRight(),
                color: SpendlerColors.textTertiary,
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
        horizontal: SpendlerSpacing.md,
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
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: PhosphorIcon(icon, color: iconColor, size: 18),
            ),
          ),
          const SizedBox(width: SpendlerSpacing.cardGap),
          // Label
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: SpendlerColors.textPrimary,
              ),
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeThumbColor: SpendlerColors.primary,
            activeTrackColor: SpendlerColors.primary.withValues(alpha: 0.3),
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
      child: Divider(height: 1, thickness: 0.5, color: SpendlerColors.border),
    );
  }
}
