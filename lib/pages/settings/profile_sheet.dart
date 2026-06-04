import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:finance_buddy_app/design_system/design_system.dart';
import 'package:finance_buddy_app/providers/auth_provider.dart';
import 'package:finance_buddy_app/providers/onboarding_provider.dart';
import 'package:finance_buddy_app/pages/settings/widgets/settings_help_support_sheet.dart';
import 'package:finance_buddy_app/widgets/common/spendler_bottom_sheet.dart';

/// Profile sheet — identity plus jump-offs (Accounts, Help) and sign out.
/// Mirrors the "More Screens" Hi-Fi mock: gradient avatar, synced pill,
/// grouped nav rows, and a red ghost sign-out.
class ProfileSheet extends ConsumerStatefulWidget {
  const ProfileSheet({super.key});

  @override
  ConsumerState<ProfileSheet> createState() => _ProfileSheetState();
}

class _ProfileSheetState extends ConsumerState<ProfileSheet> {
  bool _editingName = false;
  late TextEditingController _nameCtrl;
  int _accountCount = 0;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _loadAccountCount();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAccountCount() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString('accounts');
    if (json == null) return;
    try {
      final list = jsonDecode(json) as List;
      if (mounted) setState(() => _accountCount = list.length);
    } on FormatException catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final name = ref.watch(userNameProvider).valueOrNull ?? 'User';
    final email = ref.watch(userEmailProvider).valueOrNull;
    final initials = _initials(name);
    final synced = email != null && email.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Profile',
                  style: AppTextStyles.headingM.copyWith(color: AppColors.black)),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: const BoxDecoration(
                    color: AppColors.gray100, shape: BoxShape.circle),
                  child: const Icon(Icons.close,
                      size: 18, color: AppColors.gray600),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Gradient avatar
          Container(
            width: 88,
            height: 88,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.heroGradientTop, AppColors.black],
              ),
              boxShadow: AppShadows.hero,
            ),
            child: Center(
              child: Text(initials,
                  style: AppTextStyles.displayL.copyWith(
                      color: AppColors.white,
                      fontSize: 30,
                      letterSpacing: 0.5)),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Editable name
          if (_editingName)
            _NameEditor(controller: _nameCtrl, onSave: _saveName)
          else
            GestureDetector(
              onTap: () {
                _nameCtrl.text = name;
                setState(() => _editingName = true);
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(name,
                      style: AppTextStyles.headingM
                          .copyWith(color: AppColors.black)),
                  const SizedBox(width: AppSpacing.xs),
                  PhosphorIcon(PhosphorIcons.pencilSimple(),
                      color: AppColors.gray400, size: 16),
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.xxs),

          // Email
          Text(email ?? 'Stored on this device',
              style: AppTextStyles.bodyM.copyWith(color: AppColors.gray500)),
          const SizedBox(height: AppSpacing.sm),

          // Sync status pill
          _SyncPill(synced: synced),
          const SizedBox(height: AppSpacing.xl),

          // Nav rows
          Container(
            decoration: const BoxDecoration(
              color: AppColors.white,
              borderRadius: AppRadius.xl,
              boxShadow: AppShadows.sm,
            ),
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.xxs),
            child: Column(
              children: [
                _NavRow(
                  icon: PhosphorIcons.creditCard(),
                  label: 'Accounts',
                  value: _accountCount > 0 ? '$_accountCount' : null,
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/accounts');
                  },
                ),
                const Divider(
                    height: 1, thickness: 1, color: AppColors.gray100),
                _NavRow(
                  icon: PhosphorIcons.question(),
                  label: 'Help & Support',
                  onTap: () {
                    Navigator.pop(context);
                    showSpendlerSheet<void>(
                      context: context,
                      builder: (_) => const SettingsHelpSupportSheet(),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Sign out (red ghost)
          GestureDetector(
            onTap: _confirmSignOut,
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: const BoxDecoration(
                color: AppColors.white,
                borderRadius: AppRadius.pill,
                boxShadow: AppShadows.sm,
              ),
              child: Center(
                child: Text('Sign out',
                    style: AppTextStyles.bodyM.copyWith(
                        color: AppColors.red, fontWeight: FontWeight.w700)),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }

  Future<void> _saveName() async {
    final newName = _nameCtrl.text.trim();
    if (newName.isNotEmpty) {
      await saveUserName(newName);
      ref.invalidate(userNameProvider);
    }
    if (mounted) setState(() => _editingName = false);
  }

  void _confirmSignOut() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lg),
        title: Text('Sign out',
            style: AppTextStyles.headingS.copyWith(color: AppColors.black)),
        content: Text('Are you sure you want to sign out?',
            style: AppTextStyles.bodyM.copyWith(color: AppColors.gray500)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style:
                    AppTextStyles.bodyM.copyWith(color: AppColors.gray500)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final authService = ref.read(authServiceProvider);
              await authService.signOut();
              if (mounted) {
                Navigator.pop(context);
                context.go('/onboarding/welcome');
              }
            },
            child: Text('Sign out',
                style: AppTextStyles.bodyM.copyWith(
                    color: AppColors.red, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  static String _initials(String name) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}

// ─── Sync status pill ────────────────────────────────────────

class _SyncPill extends StatelessWidget {
  const _SyncPill({required this.synced});
  final bool synced;

  @override
  Widget build(BuildContext context) {
    final bg = synced ? AppColors.catGreenBg : AppColors.gray100;
    final fg = synced ? AppColors.catGreenText : AppColors.gray500;
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs, vertical: AppSpacing.xxs),
      decoration: BoxDecoration(color: bg, borderRadius: AppRadius.pill),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PhosphorIcon(
              synced ? PhosphorIcons.check() : PhosphorIcons.deviceMobile(),
              size: 12,
              color: fg),
          const SizedBox(width: 5),
          Text(synced ? 'Synced just now' : 'On this device',
              style: AppTextStyles.labelS.copyWith(
                  color: fg, fontWeight: FontWeight.w600, letterSpacing: 0.2)),
        ],
      ),
    );
  }
}

// ─── Nav row (set-row style) ─────────────────────────────────

class _NavRow extends StatelessWidget {
  const _NavRow(
      {required this.icon, required this.label, this.value, required this.onTap});
  final IconData icon;
  final String label;
  final String? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                  color: AppColors.gray100, borderRadius: AppRadius.sm),
              child: Center(
                  child: PhosphorIcon(icon, size: 19, color: AppColors.gray600)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label,
                  style: AppTextStyles.bodyM.copyWith(
                      color: AppColors.black, fontWeight: FontWeight.w600)),
            ),
            if (value != null) ...[
              Text(value!,
                  style: AppTextStyles.bodyM.copyWith(color: AppColors.gray400)),
              const SizedBox(width: 8),
            ],
            PhosphorIcon(PhosphorIcons.caretRight(),
                size: 18, color: AppColors.gray300),
          ],
        ),
      ),
    );
  }
}

// ─── Inline name editor ──────────────────────────────────────

class _NameEditor extends StatelessWidget {
  const _NameEditor({required this.controller, required this.onSave});
  final TextEditingController controller;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 180,
          child: TextField(
            controller: controller,
            autofocus: true,
            textAlign: TextAlign.center,
            style: AppTextStyles.headingM.copyWith(color: AppColors.black),
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
              filled: true,
              fillColor: AppColors.gray100,
              border: OutlineInputBorder(
                  borderRadius: AppRadius.base, borderSide: BorderSide.none),
            ),
            onSubmitted: (_) => onSave(),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        GestureDetector(
          onTap: onSave,
          child: Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
                color: AppColors.black, borderRadius: AppRadius.sm),
            child: const Center(
                child: Icon(Icons.check, size: 16, color: AppColors.white)),
          ),
        ),
      ],
    );
  }
}
