import 'package:flutter/material.dart';

import 'package:finance_buddy_app/design_system/app_colors.dart';
import 'package:finance_buddy_app/design_system/app_radius.dart';
import 'package:finance_buddy_app/models/account_model.dart';
import 'package:finance_buddy_app/utils/account_logo_resolver.dart';

class AccountIcon extends StatelessWidget {
  const AccountIcon({
    super.key,
    required this.name,
    required this.type,
    this.size = 44,
  });

  final String name;
  final AccountType type;
  final double size;

  @override
  Widget build(BuildContext context) {
    final logoPath = AccountLogoResolver.resolve(name);

    if (logoPath != null) {
      return ClipRRect(
        borderRadius: AppRadius.sm,
        child: Image.asset(
          logoPath,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _genericIcon(),
        ),
      );
    }

    return _genericIcon();
  }

  Widget _genericIcon() {
    final icon = type == AccountType.cash
        ? Icons.account_balance_wallet_outlined
        : Icons.phone_android_outlined;

    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: AppColors.gray100,
        borderRadius: AppRadius.sm,
      ),
      child: Icon(icon, size: size * 0.5, color: AppColors.gray600),
    );
  }
}
