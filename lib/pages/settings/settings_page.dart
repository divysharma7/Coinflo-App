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
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: SpendlerSpacing.screenH,
          vertical: SpendlerSpacing.md,
        ),
        children: [
          // ─── Section 1: Profile ──────────────────
          const Text('PROFILE', style: SpendlerTextStyles.sectionLabel),
          const SizedBox(height: SpendlerSpacing.cardGap),

          _EditableRow(
            icon: PhosphorIcons.user(),
            label: 'Name',
            value: userName.valueOrNull ?? 'Not set',
            onTap: () => _editText(
              title: 'Your name',
              current: userName.valueOrNull ?? '',
              onSave: (v) async {
                await saveUserName(v);
                ref.invalidate(userNameProvider);
              },
            ),
          ),
          const SizedBox(height: SpendlerSpacing.sm),
          _EditableRow(
            icon: PhosphorIcons.wallet(),
            label: 'Monthly salary',
            value: salary.valueOrNull != null
                ? '\$${salary.valueOrNull!.toStringAsFixed(0)}'
                : 'Not set',
            onTap: () => _editNumber(
              title: 'Monthly salary',
              current: salary.valueOrNull,
              onSave: (v) async {
                await saveMonthlySalary(v);
                ref.invalidate(monthlySalaryProvider);
              },
            ),
          ),
          const SizedBox(height: SpendlerSpacing.sm),
          _EditableRow(
            icon: PhosphorIcons.target(),
            label: 'Spending target',
            value: target.valueOrNull != null
                ? '\$${target.valueOrNull!.toStringAsFixed(0)}/month'
                : 'Not set',
            onTap: () => _editNumber(
              title: 'Monthly spending target',
              current: target.valueOrNull,
              onSave: (v) async {
                await saveSpendingTarget(v);
                ref.invalidate(spendingTargetProvider);
              },
            ),
          ),

          const SizedBox(height: SpendlerSpacing.xl),

          // ─── Section 2: Notifications ────────────
          const Text('NOTIFICATIONS', style: SpendlerTextStyles.sectionLabel),
          const SizedBox(height: SpendlerSpacing.cardGap),

          _ToggleRow(
            icon: PhosphorIcons.bell(),
            title: 'Transaction alerts',
            subtitle: 'When 3+ transactions pile up',
            value: prefs.txnAlerts,
            onChanged: (v) =>
                ref.read(notifPrefsProvider.notifier).setTxnAlerts(v),
          ),
          const SizedBox(height: SpendlerSpacing.sm),
          _ToggleRow(
            icon: PhosphorIcons.moon(),
            title: 'Evening check-in',
            subtitle:
                '${_formatTime(prefs.checkinHour, prefs.checkinMinute)} if unconfirmed',
            value: prefs.eveningCheckin,
            onChanged: (v) =>
                ref.read(notifPrefsProvider.notifier).setEveningCheckin(v),
          ),
          const SizedBox(height: SpendlerSpacing.sm),
          _ToggleRow(
            icon: PhosphorIcons.calendarCheck(),
            title: 'Sunday digest',
            subtitle: 'Weekly rhythm at 7pm',
            value: prefs.sundayDigest,
            onChanged: (v) =>
                ref.read(notifPrefsProvider.notifier).setSundayDigest(v),
          ),
          const SizedBox(height: SpendlerSpacing.sm),
          _TappableRow(
            icon: PhosphorIcons.clock(),
            label: 'Check-in time',
            value: _formatTime(prefs.checkinHour, prefs.checkinMinute),
            onTap: () => _pickTime(prefs),
          ),

          const SizedBox(height: SpendlerSpacing.xl),

          // ─── Section 3: Data ─────────────────────
          const Text('DATA', style: SpendlerTextStyles.sectionLabel),
          const SizedBox(height: SpendlerSpacing.cardGap),

          _TappableRow(
            icon: PhosphorIcons.export(),
            label: 'Export my data',
            value: 'JSON',
            onTap: _exportData,
          ),
          const SizedBox(height: SpendlerSpacing.sm),
          _TappableRow(
            icon: PhosphorIcons.trash(),
            label: 'Clear all data',
            value: '',
            color: SpendlerColors.expense,
            onTap: _clearData,
          ),
          const SizedBox(height: SpendlerSpacing.sm),
          _TappableRow(
            icon: PhosphorIcons.shieldCheck(),
            label: 'Privacy policy',
            value: '',
            onTap: () {
              // TODO: Open privacy policy URL when hosted
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Privacy policy will be available soon.'),
                ),
              );
            },
          ),

          const SizedBox(height: SpendlerSpacing.xl),

          // ─── Section 4: App ──────────────────────
          const Text('APP', style: SpendlerTextStyles.sectionLabel),
          const SizedBox(height: SpendlerSpacing.cardGap),

          _TappableRow(
            icon: PhosphorIcons.question(),
            label: 'How Spendler works',
            value: '',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => const OnboardingPage(isGuideMode: true),
                ),
              );
            },
          ),
          const SizedBox(height: SpendlerSpacing.sm),
          _InfoRow(
            icon: PhosphorIcons.info(),
            label: 'Version',
            value: '1.0.0',
          ),

          const SizedBox(height: 80),
        ],
      ),
        ),
      ),
    );
  }

  static String _formatTime(int hour, int minute) {
    final period = hour >= 12 ? 'PM' : 'AM';
    final h = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m $period';
  }

  Future<void> _pickTime(NotifPrefs prefs) async {
    final picked = await showTimePicker(
      context: context,
      initialTime:
          TimeOfDay(hour: prefs.checkinHour, minute: prefs.checkinMinute),
    );
    if (picked != null) {
      await ref
          .read(notifPrefsProvider.notifier)
          .setCheckinTime(picked.hour, picked.minute);
    }
  }

  Future<void> _editText({
    required String title,
    required String current,
    required Future<void> Function(String) onSave,
  }) async {
    final ctrl = TextEditingController(text: current);
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          style: const TextStyle(color: SpendlerColors.textPrimary),
          cursorColor: SpendlerColors.primary,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, ctrl.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (result != null && result.isNotEmpty) {
      await onSave(result);
    }
  }

  Future<void> _editNumber({
    required String title,
    required double? current,
    required Future<void> Function(double) onSave,
  }) async {
    final ctrl = TextEditingController(
      text: current?.toStringAsFixed(0) ?? '',
    );
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(color: SpendlerColors.textPrimary),
          cursorColor: SpendlerColors.primary,
          decoration: const InputDecoration(prefixText: '\$ '),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, ctrl.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (result != null && result.isNotEmpty) {
      final value = double.tryParse(result);
      if (value != null && value > 0) {
        await onSave(value);
      }
    }
  }

  Future<void> _exportData() async {
    // TODO: Implement JSON/CSV export
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Export coming soon.')),
    );
  }

  Future<void> _clearData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear all data?'),
        content: const Text(
          'This will permanently delete all transactions, family entries, and notification history. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete Everything',
              style: TextStyle(color: SpendlerColors.expense),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await HapticFeedback.heavyImpact();
      await ref.read(repositoryProvider).clearAll();

      // Invalidate all providers so UI refreshes immediately
      ref.invalidate(weeklyTransactionsProvider);
      ref.invalidate(unconfirmedQueueProvider);
      ref.invalidate(allTransactionsProvider);
      ref.invalidate(todaySpendingProvider);
      ref.invalidate(todayTopCategoryProvider);
      ref.invalidate(weekOverWeekDeltaProvider);
      ref.invalidate(weeklyMerchantCountsProvider);
      ref.invalidate(totalFamilyWealthProvider);
      ref.invalidate(familyInflowsProvider);
      ref.invalidate(familyOutflowsProvider);
      ref.invalidate(familyInvestmentsProvider);
      ref.invalidate(thisMonthCumulativeProvider);
      ref.invalidate(lastMonthCumulativeProvider);
      ref.invalidate(dayOfWeekAveragesProvider);
      ref.invalidate(topMerchantsProvider);
      ref.invalidate(monthlyComparisonProvider);
      ref.invalidate(friendContactsProvider);
      ref.invalidate(totalFriendBalanceProvider);
      ref.invalidate(settledSplitsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All data cleared.')),
        );
        // Pop back to home so the user sees fresh state
        Navigator.pop(context);
      }
    }
  }
}

// ─── Reusable row widgets ────────────────────────────

class _EditableRow extends StatelessWidget {
  const _EditableRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: SpendlerSpacing.md,
          vertical: SpendlerSpacing.cardGap,
        ),
        decoration: BoxDecoration(
          color: SpendlerColors.surface,
          borderRadius: BorderRadius.circular(SpendlerRadii.button),
        ),
        child: Row(
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
            Flexible(
              child: Text(
                value,
                style: const TextStyle(
                  color: SpendlerColors.textSecondary,
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
                style: TextStyle(color: color ?? SpendlerColors.textPrimary, fontSize: 15),
              ),
            ),
            if (value.isNotEmpty)
              Flexible(
                child: Text(
                  value,
                  style: const TextStyle(
                    color: SpendlerColors.textSecondary,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
