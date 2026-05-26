import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'package:finance_buddy_app/design_system/design_system.dart';
import 'package:finance_buddy_app/models/account_model.dart';
import 'package:finance_buddy_app/utils/account_logo_resolver.dart';

class AddAccountsScreen extends StatefulWidget {
  const AddAccountsScreen({super.key});

  @override
  State<AddAccountsScreen> createState() => _AddAccountsScreenState();
}

class _AddAccountsScreenState extends State<AddAccountsScreen>
    with TickerProviderStateMixin {
  final List<AccountModel> _accounts = [AccountModel.cashAccount];
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _balanceController = TextEditingController();
  bool _formHasName = false;
  String _currencySymbol = '₹';

  // Enter animations
  late final AnimationController _enterController;
  late final Animation<double> _titleFade;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _listFade;
  late final Animation<Offset> _listSlide;
  late final Animation<double> _formFade;
  late final Animation<Offset> _formSlide;

  @override
  void initState() {
    super.initState();
    _loadSavedData();
    _nameController.addListener(() {
      setState(() => _formHasName = _nameController.text.trim().isNotEmpty);
    });

    _enterController = AnimationController(
      vsync: this,
      duration: AppDurations.slow,
    );

    _titleFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _enterController,
        curve: const Interval(0, 0.6, curve: Curves.easeOutCubic),
      ),
    );
    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _enterController,
      curve: const Interval(0, 0.6, curve: Curves.easeOutCubic),
    ));

    _listFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _enterController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOut),
      ),
    );
    _listSlide = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _enterController,
      curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
    ));

    _formFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _enterController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
    );
    _formSlide = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _enterController,
      curve: const Interval(0.4, 1.0, curve: Curves.easeOutCubic),
    ));

    _enterController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    _enterController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    final symbol = prefs.getString('currency_symbol') ?? '₹';
    final savedJson = prefs.getString('accounts');
    if (savedJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(savedJson) as List<dynamic>;
        final saved = decoded
            .map((e) => AccountModel.fromJson(e as Map<String, dynamic>))
            .toList();
        if (saved.isNotEmpty) {
          setState(() {
            _accounts
              ..clear()
              ..addAll(saved);
            _currencySymbol = symbol;
          });
          return;
        }
      } on FormatException catch (_) {
        // Ignore malformed JSON — fall through to defaults.
      }
    }
    setState(() {
      _currencySymbol = symbol;
    });
  }

  void _addAccount() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final newAccount = AccountModel(
      id: const Uuid().v4(),
      name: name,
      type: AccountType.upi,
      openingBalance: double.tryParse(_balanceController.text) ?? 0.0,
    );

    setState(() {
      _accounts.add(newAccount);
    });
    _listKey.currentState?.insertItem(
      _accounts.length - 1,
      duration: AppDurations.base,
    );

    _nameController.clear();
    _balanceController.clear();
  }

  void _removeAccount(int index) {
    final removed = _accounts[index];
    setState(() {
      _accounts.removeAt(index);
    });
    _listKey.currentState?.removeItem(
      index,
      (context, animation) => _buildAccountRow(removed, animation),
      duration: AppDurations.base,
    );
  }

  Future<void> _onContinue() async {
    // Save pending form entry if name is filled
    if (_nameController.text.trim().isNotEmpty) {
      _addAccount();
    }

    final prefs = await SharedPreferences.getInstance();
    final encoded =
        jsonEncode(_accounts.map((a) => a.toJson()).toList());
    await prefs.setString('accounts', encoded);

    if (mounted) {
      await context.push('/onboarding/import');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress indicator
            Padding(
              padding: const EdgeInsets.only(
                top: AppSpacing.md,
                left: AppSpacing.lg,
                right: AppSpacing.lg,
              ),
              child: _buildProgressIndicator(),
            ),

            // Back button
            AppBackButton(onTap: () => context.pop()),

            // Title + subtitle
            SlideTransition(
              position: _titleSlide,
              child: FadeTransition(
                opacity: _titleFade,
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: AppSpacing.lg,
                    right: AppSpacing.lg,
                    top: AppSpacing.lg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add your accounts',
                        style: AppTextStyles.headingL
                            .copyWith(color: AppColors.black),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Where do you keep your money? Add at least one account.',
                        style: AppTextStyles.bodyM
                            .copyWith(color: AppColors.gray500),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Column(
                  children: [
                    // Accounts list
                    SlideTransition(
                      position: _listSlide,
                      child: FadeTransition(
                        opacity: _listFade,
                        child: _buildAccountsList(),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.sm),

                    // Add account form
                    SlideTransition(
                      position: _formSlide,
                      child: FadeTransition(
                        opacity: _formFade,
                        child: _buildFormCard(),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
            ),

            // Continue button
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: AppButton(label: 'Continue', onTap: _onContinue),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(8, (index) {
        return Container(
          width: 24,
          height: 3,
          margin: EdgeInsets.only(right: index < 7 ? AppSpacing.xs : 0),
          decoration: BoxDecoration(
            color: index < 2 ? AppColors.black : AppColors.gray200,
            borderRadius: AppRadius.full,
          ),
        );
      }),
    );
  }

  Widget _buildAccountsList() {
    return AnimatedList(
      key: _listKey,
      initialItemCount: _accounts.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index, animation) {
        final account = _accounts[index];
        return _buildAccountRow(account, animation, index: index);
      },
    );
  }

  Widget _buildAccountRow(
    AccountModel account,
    Animation<double> animation, {
    int? index,
  }) {
    final row = Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: AppRadius.xl,
        boxShadow: AppShadows.sm,
      ),
      child: Row(
        children: [
          AccountIcon(name: account.name, type: account.type),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  account.name,
                  style: AppTextStyles.headingS,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  account.type == AccountType.cash ? 'Cash' : 'UPI',
                  style:
                      AppTextStyles.labelS.copyWith(color: AppColors.gray400),
                ),
              ],
            ),
          ),
          if (account.openingBalance > 0)
            Text(
              '$_currencySymbol${account.openingBalance.toStringAsFixed(0)}',
              style:
                  AppTextStyles.numericM.copyWith(color: AppColors.gray500),
            ),
        ],
      ),
    );

    final animatedRow = SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.1),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      )),
      child: FadeTransition(opacity: animation, child: row),
    );

    // Cash account is never dismissible
    if (!account.isDeletable || index == null) return animatedRow;

    return Dismissible(
      key: Key(account.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.lg),
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        decoration: const BoxDecoration(
          color: AppColors.red,
          borderRadius: AppRadius.xl,
        ),
        child:
            const Icon(Icons.delete_outline, color: AppColors.white, size: 22),
      ),
      onDismissed: (_) => _removeAccount(index),
      child: animatedRow,
    );
  }

  Widget _buildFormCard() {
    final logoPath = AccountLogoResolver.resolve(_nameController.text);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: AppRadius.xl,
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Account name label + logo preview
          Row(
            children: [
              Text(
                'ACCOUNT NAME',
                style:
                    AppTextStyles.labelM.copyWith(color: AppColors.gray400),
              ),
              const Spacer(),
              // Live logo preview
              AnimatedSwitcher(
                duration: AppDurations.fast,
                child: logoPath != null
                    ? ClipRRect(
                        key: ValueKey(logoPath),
                        borderRadius: AppRadius.sm,
                        child: Image.asset(
                          logoPath,
                          width: 28,
                          height: 28,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              const SizedBox.shrink(),
                        ),
                      )
                    : const SizedBox.shrink(key: ValueKey('no_logo')),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          TextField(
            controller: _nameController,
            style: AppTextStyles.bodyM.copyWith(color: AppColors.black),
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              hintText: 'e.g. HDFC Bank, Paytm...',
              hintStyle:
                  AppTextStyles.bodyM.copyWith(color: AppColors.gray400),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Type selector
          Text(
            'TYPE',
            style: AppTextStyles.labelM.copyWith(color: AppColors.gray400),
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              // Cash pill — disabled
              Container(
                height: 36,
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                decoration: const BoxDecoration(
                  color: AppColors.gray100,
                  borderRadius: AppRadius.full,
                ),
                alignment: Alignment.center,
                child: Text(
                  'Cash',
                  style:
                      AppTextStyles.bodyM.copyWith(color: AppColors.gray400),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              // UPI pill — always selected
              Container(
                height: 36,
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                decoration: const BoxDecoration(
                  color: AppColors.black,
                  borderRadius: AppRadius.full,
                ),
                alignment: Alignment.center,
                child: Text(
                  'UPI',
                  style:
                      AppTextStyles.bodyM.copyWith(color: AppColors.white),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          // Opening balance
          Text(
            'OPENING BALANCE',
            style: AppTextStyles.labelM.copyWith(color: AppColors.gray400),
          ),
          const SizedBox(height: AppSpacing.xs),
          TextField(
            controller: _balanceController,
            style: AppTextStyles.bodyM.copyWith(color: AppColors.black),
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              hintText: 'e.g. $_currencySymbol 24,000',
              hintStyle:
                  AppTextStyles.bodyM.copyWith(color: AppColors.gray400),
              prefixText: '$_currencySymbol ',
              prefixStyle:
                  AppTextStyles.bodyM.copyWith(color: AppColors.gray400),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),

          // Add button — only visible when name has content
          if (_formHasName) ...[
            const SizedBox(height: AppSpacing.lg),
            GestureDetector(
              onTap: _addAccount,
              child: Container(
                width: double.infinity,
                height: 44,
                decoration: const BoxDecoration(
                  color: AppColors.gray100,
                  borderRadius: AppRadius.full,
                ),
                alignment: Alignment.center,
                child: Text(
                  'Add Account',
                  style: AppTextStyles.headingS
                      .copyWith(color: AppColors.gray600),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
