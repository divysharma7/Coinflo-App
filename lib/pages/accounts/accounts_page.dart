import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:finance_buddy_app/design_system/design_system.dart';
import 'package:finance_buddy_app/models/account_model.dart';
import 'package:finance_buddy_app/utils/currency_utils.dart';
import 'package:finance_buddy_app/widgets/common/spendler_bottom_sheet.dart';

/// Full-screen Accounts manager — dark total-balance hero over the per-source
/// list, matching the "More Screens" Hi-Fi mock. Accounts persist as JSON in
/// SharedPreferences under the shared `accounts` key (same shape as onboarding).
class AccountsPage extends ConsumerStatefulWidget {
  const AccountsPage({super.key});

  @override
  ConsumerState<AccountsPage> createState() => _AccountsPageState();
}

class _AccountsPageState extends ConsumerState<AccountsPage> {
  List<AccountModel> _accounts = [];
  String _symbol = '₹';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString('currency_code') ?? 'inr';
    final json = prefs.getString('accounts');
    var accounts = <AccountModel>[];
    if (json != null) {
      try {
        accounts = (jsonDecode(json) as List)
            .map((e) => AccountModel.fromJson(e as Map<String, dynamic>))
            .toList();
      } on FormatException catch (_) {
        accounts = [];
      }
    }
    if (!mounted) return;
    setState(() {
      _accounts = accounts;
      _symbol = currencySymbol(code);
      _loading = false;
    });
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'accounts', jsonEncode(_accounts.map((a) => a.toJson()).toList()));
  }

  Future<void> _addAccount() async {
    final created = await showSpendlerSheet<AccountModel>(
      context: context,
      builder: (_) => const _AddAccountSheet(),
    );
    if (created == null) return;
    setState(() => _accounts = [..._accounts, created]);
    await _persist();
  }

  Future<void> _removeAccount(AccountModel account) async {
    setState(() =>
        _accounts = _accounts.where((a) => a.id != account.id).toList());
    await _persist();
  }

  double get _total =>
      _accounts.fold<double>(0, (sum, a) => sum + a.openingBalance);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xs, AppSpacing.xs, AppSpacing.lg, AppSpacing.xs),
              child: Row(
                children: [
                  const AppBackButton(),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text('Accounts',
                        style: AppTextStyles.headingM
                            .copyWith(color: AppColors.black)),
                  ),
                  _CircleIconButton(
                    icon: PhosphorIcons.plus(),
                    onTap: _addAccount,
                  ),
                ],
              ),
            ),

            if (_loading)
              const Expanded(
                child: Center(
                    child: CircularProgressIndicator(
                        color: AppColors.black, strokeWidth: 2)),
              )
            else
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg,
                      AppSpacing.sm, AppSpacing.lg, AppSpacing.xxxl),
                  children: [
                    // ── Dark total-balance hero ──
                    DarkHeroCard(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Total balance',
                              style: AppTextStyles.bodyS.copyWith(
                                  color:
                                      AppColors.white.withValues(alpha: 0.6),
                                  fontWeight: FontWeight.w500)),
                          const SizedBox(height: 6),
                          Text('$_symbol${_fmt(_total)}',
                              style: AppTextStyles.displayXL
                                  .copyWith(color: AppColors.white)),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                              'Across ${_accounts.length} '
                              '${_accounts.length == 1 ? 'account' : 'accounts'}',
                              style: AppTextStyles.bodyS.copyWith(
                                  color: AppColors.white
                                      .withValues(alpha: 0.5))),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xl),
                    Padding(
                      padding: const EdgeInsets.only(
                          left: 2, bottom: AppSpacing.xs),
                      child: Text('YOUR ACCOUNTS',
                          style: AppTextStyles.section
                              .copyWith(color: AppColors.gray400)),
                    ),

                    if (_accounts.isEmpty)
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                        child: Text('No accounts yet. Add one to get started.',
                            style: AppTextStyles.bodyM
                                .copyWith(color: AppColors.gray500)),
                      )
                    else
                      ..._accounts.map((a) => Padding(
                            padding:
                                const EdgeInsets.only(bottom: AppSpacing.sm),
                            child: _AccountRow(
                              account: a,
                              symbol: _symbol,
                              onRemove: a.isDeletable
                                  ? () => _confirmRemove(a)
                                  : null,
                            ),
                          )),

                    // ── Ghost add row ──
                    GestureDetector(
                      onTap: _addAccount,
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(vertical: AppSpacing.md),
                        decoration: BoxDecoration(
                          borderRadius: AppRadius.md,
                          border: Border.all(
                              color: AppColors.gray300,
                              width: 1.5,
                              style: BorderStyle.solid),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            PhosphorIcon(PhosphorIcons.plus(),
                                size: 16, color: AppColors.gray500),
                            const SizedBox(width: AppSpacing.xs),
                            Text('Add account',
                                style: AppTextStyles.bodyM.copyWith(
                                    color: AppColors.gray500,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _confirmRemove(AccountModel account) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lg),
        title: Text('Remove account',
            style: AppTextStyles.headingS.copyWith(color: AppColors.black)),
        content: Text('Remove "${account.name}"? This only affects accounts, '
            'not your recorded transactions.',
            style: AppTextStyles.bodyM.copyWith(color: AppColors.gray500)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style:
                    AppTextStyles.bodyM.copyWith(color: AppColors.gray500)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _removeAccount(account);
            },
            child: Text('Remove',
                style: AppTextStyles.bodyM.copyWith(
                    color: AppColors.red, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  /// ₹24,000-style grouped thousands.
  static String _fmt(double value) {
    final whole = value.round();
    final neg = whole < 0;
    final digits = whole.abs().toString();
    final buf = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buf.write(',');
      buf.write(digits[i]);
    }
    return '${neg ? '-' : ''}$buf';
  }
}

// ─── Account row (sel-row style) ─────────────────────────────

class _AccountRow extends StatelessWidget {
  const _AccountRow(
      {required this.account, required this.symbol, this.onRemove});
  final AccountModel account;
  final String symbol;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final isCash = account.type == AccountType.cash;
    final tint = _badgeTint(account.name);

    final row = Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: AppRadius.md,
        boxShadow: AppShadows.sm,
      ),
      child: Row(
        children: [
          // Badge
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: isCash ? AppColors.gray100 : tint.bg,
              borderRadius: AppRadius.sm,
            ),
            child: Center(
              child: isCash
                  ? PhosphorIcon(PhosphorIcons.wallet(),
                      size: 20, color: AppColors.gray600)
                  : Text(
                      account.name.isNotEmpty
                          ? account.name[0].toUpperCase()
                          : '?',
                      style: AppTextStyles.headingS
                          .copyWith(color: tint.fg, fontSize: 18)),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          // Name + type
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(account.name,
                    style: AppTextStyles.bodyM.copyWith(
                        color: AppColors.black, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 1),
                Text(isCash ? 'Cash' : 'UPI',
                    style: AppTextStyles.bodyS
                        .copyWith(color: AppColors.gray500)),
              ],
            ),
          ),
          Text('$symbol${account.openingBalance.toStringAsFixed(0)}',
              style: AppTextStyles.numericM.copyWith(
                  color: account.openingBalance == 0
                      ? AppColors.gray500
                      : AppColors.black,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );

    if (onRemove == null) return row;
    return GestureDetector(
      onLongPress: () {
        HapticFeedback.mediumImpact();
        onRemove!();
      },
      child: row,
    );
  }

  _BadgeTint _badgeTint(String name) {
    const tints = [
      _BadgeTint(AppColors.catBlueBg, AppColors.catBlueText),
      _BadgeTint(AppColors.catPurpleBg, AppColors.catPurpleText),
      _BadgeTint(AppColors.catGreenBg, AppColors.catGreenText),
      _BadgeTint(AppColors.catOrangeBg, AppColors.catOrangeText),
      _BadgeTint(AppColors.catPinkBg, AppColors.catPinkText),
    ];
    return tints[name.hashCode.abs() % tints.length];
  }
}

class _BadgeTint {
  const _BadgeTint(this.bg, this.fg);
  final Color bg;
  final Color fg;
}

// ─── Round header icon button ────────────────────────────────

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          color: AppColors.white,
          shape: BoxShape.circle,
          boxShadow: AppShadows.sm,
        ),
        child: Center(child: PhosphorIcon(icon, size: 19, color: AppColors.black)),
      ),
    );
  }
}

// ─── Add-account sheet ───────────────────────────────────────

class _AddAccountSheet extends StatefulWidget {
  const _AddAccountSheet();

  @override
  State<_AddAccountSheet> createState() => _AddAccountSheetState();
}

class _AddAccountSheetState extends State<_AddAccountSheet> {
  final _nameCtrl = TextEditingController();
  final _balanceCtrl = TextEditingController();
  AccountType _type = AccountType.upi;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _balanceCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    final balance = double.tryParse(_balanceCtrl.text.trim()) ?? 0;
    Navigator.pop(
      context,
      AccountModel(
        id: 'acct_${DateTime.now().microsecondsSinceEpoch}',
        name: name,
        type: _type,
        openingBalance: balance,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg,
          MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Add account',
              style: AppTextStyles.headingS.copyWith(color: AppColors.black)),
          const SizedBox(height: AppSpacing.md),

          // Name
          _Field(controller: _nameCtrl, hint: 'Account name', autofocus: true),
          const SizedBox(height: AppSpacing.sm),

          // Type toggle
          Row(
            children: [
              _TypeChip(
                label: 'UPI / Bank',
                selected: _type == AccountType.upi,
                onTap: () => setState(() => _type = AccountType.upi),
              ),
              const SizedBox(width: AppSpacing.xs),
              _TypeChip(
                label: 'Cash',
                selected: _type == AccountType.cash,
                onTap: () => setState(() => _type = AccountType.cash),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Opening balance
          _Field(
            controller: _balanceCtrl,
            hint: 'Opening balance (optional)',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: AppSpacing.lg),

          SizedBox(
            width: double.infinity,
            child: AppButton(label: 'Add account', onTap: _save),
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.autofocus = false,
  });
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: AppRadius.md,
        boxShadow: AppShadows.sm,
      ),
      child: TextField(
        controller: controller,
        autofocus: autofocus,
        keyboardType: keyboardType,
        style: AppTextStyles.bodyM.copyWith(color: AppColors.black),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTextStyles.bodyM.copyWith(color: AppColors.gray400),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.md),
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip(
      {required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            color: selected ? AppColors.black : AppColors.white,
            borderRadius: AppRadius.md,
            boxShadow: selected ? null : AppShadows.sm,
          ),
          alignment: Alignment.center,
          child: Text(label,
              style: AppTextStyles.bodyM.copyWith(
                  color: selected ? AppColors.white : AppColors.gray600,
                  fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }
}
