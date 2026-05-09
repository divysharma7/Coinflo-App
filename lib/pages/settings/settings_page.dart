import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:finance_buddy_app/core/tokens.dart';
import 'package:finance_buddy_app/providers/providers.dart';
import 'package:finance_buddy_app/pages/onboarding/onboarding_page.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(notifPrefsProvider);
    final userName = ref.watch(userNameProvider);
    final salary = ref.watch(monthlySalaryProvider);
    final target = ref.watch(spendingTargetProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      backgroundColor: SpendlerColors.scaffold,
      body: ListView(
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
            PhosphorIcon(icon, color: SpendlerColors.textSecondary, size: 20),
            const SizedBox(width: SpendlerSpacing.cardGap),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: SpendlerColors.textPrimary,
                  fontSize: 15,
                ),
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                color: SpendlerColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: SpendlerSpacing.sm),
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

class _TappableRow extends StatelessWidget {
  const _TappableRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? SpendlerColors.textSecondary;
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
            PhosphorIcon(icon, color: c, size: 20),
            const SizedBox(width: SpendlerSpacing.cardGap),
            Expanded(
              child: Text(
                label,
                style: TextStyle(color: color ?? SpendlerColors.textPrimary, fontSize: 15),
              ),
            ),
            if (value.isNotEmpty)
              Text(
                value,
                style: const TextStyle(
                  color: SpendlerColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            const SizedBox(width: SpendlerSpacing.sm),
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

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
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
          PhosphorIcon(icon, color: SpendlerColors.textSecondary, size: 20),
          const SizedBox(width: SpendlerSpacing.cardGap),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: SpendlerColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: SpendlerColors.textTertiary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeThumbColor: SpendlerColors.primary,
            activeTrackColor: SpendlerColors.primary.withValues(alpha: 0.3),
            inactiveTrackColor: SpendlerColors.border,
            inactiveThumbColor: SpendlerColors.textTertiary,
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
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
          PhosphorIcon(icon, color: SpendlerColors.textSecondary, size: 20),
          const SizedBox(width: SpendlerSpacing.cardGap),
          Text(label, style: const TextStyle(color: SpendlerColors.textPrimary, fontSize: 15)),
          const Spacer(),
          Text(value, style: const TextStyle(color: SpendlerColors.textTertiary, fontSize: 14)),
        ],
      ),
    );
  }
}
