import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:finance_buddy_app/core/enums.dart';
import 'package:finance_buddy_app/design_system/design_system.dart';
import 'package:finance_buddy_app/providers/onboarding_provider.dart';

/// Deterministic avatar colors seeded from the user's name.
const _avatarPalette = [
  Color(0xFF6366F1), // indigo
  Color(0xFFEC4899), // pink
  Color(0xFF14B8A6), // teal
  Color(0xFFF97316), // orange
  Color(0xFF8B5CF6), // violet
  Color(0xFF22C55E), // green
  Color(0xFF3B82F6), // blue
  Color(0xFFE11D48), // rose
];

class ProfileSheet extends ConsumerStatefulWidget {
  const ProfileSheet({super.key});

  @override
  ConsumerState<ProfileSheet> createState() => _ProfileSheetState();
}

class _ProfileSheetState extends ConsumerState<ProfileSheet> {
  bool _editingName = false;
  late TextEditingController _nameCtrl;
  List<Map<String, dynamic>> _accounts = [];
  String _currencySymbol = '\u20B9';

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _loadAccounts();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final currencyCode = prefs.getString('currency_code') ?? 'inr';
    final currency = Currency.values.firstWhere(
      (c) => c.name == currencyCode,
      orElse: () => Currency.inr,
    );
    final json = prefs.getString('accounts');
    if (json != null) {
      try {
        final list = List<dynamic>.from(jsonDecode(json) as List);
        if (mounted) {
          setState(() {
            _accounts = list.cast<Map<String, dynamic>>();
            _currencySymbol = currency.symbol;
          });
        }
      } on FormatException catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final userName = ref.watch(userNameProvider);
    final userEmail = ref.watch(userEmailProvider);

    final name = userName.valueOrNull ?? 'User';
    final email = userEmail.valueOrNull;

    final initials = _initials(name);
    final avatarColor =
        _avatarPalette[name.hashCode.abs() % _avatarPalette.length];

    final totalBalance = _accounts.fold<double>(
      0,
      (sum, a) => sum + ((a['openingBalance'] as num?)?.toDouble() ?? 0),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Profile',
                  style:
                      AppTextStyles.headingM.copyWith(color: AppColors.black),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: AppColors.gray100,
                      borderRadius: AppRadius.sm,
                    ),
                    child: const Center(
                      child:
                          Icon(Icons.close, size: 18, color: AppColors.gray500),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Avatar with initials
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: avatarColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                initials,
                style:
                    AppTextStyles.headingL.copyWith(color: AppColors.white),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Editable name
          if (_editingName)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 180,
                  child: TextField(
                    controller: _nameCtrl,
                    autofocus: true,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.headingM
                        .copyWith(color: AppColors.black),
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                      filled: true,
                      fillColor: AppColors.gray100,
                      border: OutlineInputBorder(
                        borderRadius: AppRadius.base,
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _saveName(),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                GestureDetector(
                  onTap: _saveName,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: AppColors.black,
                      borderRadius: AppRadius.sm,
                    ),
                    child: const Center(
                      child:
                          Icon(Icons.check, size: 16, color: AppColors.white),
                    ),
                  ),
                ),
              ],
            )
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
                  Text(
                    name,
                    style: AppTextStyles.headingM
                        .copyWith(color: AppColors.black),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  PhosphorIcon(
                    PhosphorIcons.pencilSimple(),
                    color: AppColors.gray400,
                    size: 16,
                  ),
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.xxs),

          // Email
          Text(
            email ?? 'No email set',
            style: AppTextStyles.bodyM.copyWith(color: AppColors.gray500),
          ),

          const SizedBox(height: AppSpacing.xl),

          // Accounts summary card
          if (_accounts.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: const BoxDecoration(
                color: AppColors.white,
                borderRadius: AppRadius.xl,
                boxShadow: AppShadows.sm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Accounts',
                        style: AppTextStyles.labelM
                            .copyWith(color: AppColors.gray500),
                      ),
                      Text(
                        '${_accounts.length} linked',
                        style: AppTextStyles.labelS
                            .copyWith(color: AppColors.gray400),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ..._accounts.map((a) {
                    final acctName = a['name'] as String? ?? '';
                    final type = a['type'] as String? ?? '';
                    final balance =
                        (a['openingBalance'] as num?)?.toDouble() ?? 0;
                    return Padding(
                      padding:
                          const EdgeInsets.only(bottom: AppSpacing.xs),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: const BoxDecoration(
                              color: AppColors.gray100,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: PhosphorIcon(
                                type == 'upi'
                                    ? PhosphorIcons.deviceMobile()
                                    : PhosphorIcons.wallet(),
                                size: 14,
                                color: AppColors.gray600,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              acctName,
                              style: AppTextStyles.bodyS
                                  .copyWith(color: AppColors.black),
                            ),
                          ),
                          Text(
                            '$_currencySymbol${balance.toStringAsFixed(0)}',
                            style: AppTextStyles.bodyS.copyWith(
                              color: AppColors.black,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const Divider(color: AppColors.gray200, height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total balance',
                        style: AppTextStyles.bodyS
                            .copyWith(color: AppColors.gray500),
                      ),
                      Text(
                        '$_currencySymbol${totalBalance.toStringAsFixed(0)}',
                        style: AppTextStyles.headingS
                            .copyWith(color: AppColors.black),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ] else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: const BoxDecoration(
                color: AppColors.gray100,
                borderRadius: AppRadius.xl,
              ),
              child: Column(
                children: [
                  PhosphorIcon(
                    PhosphorIcons.wallet(),
                    color: AppColors.gray400,
                    size: 28,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'No accounts added yet',
                    style: AppTextStyles.bodyS
                        .copyWith(color: AppColors.gray500),
                  ),
                ],
              ),
            ),
          ],

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

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    if (name.length >= 2) return name.substring(0, 2).toUpperCase();
    return name.toUpperCase();
  }
}
