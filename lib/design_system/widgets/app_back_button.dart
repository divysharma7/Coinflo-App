import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:finance_buddy_app/design_system/app_colors.dart';
import 'package:finance_buddy_app/design_system/app_spacing.dart';

class AppBackButton extends StatelessWidget {
  const AppBackButton({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.md,
        top: AppSpacing.md,
      ),
      child: Semantics(
        button: true,
        label: 'Go back',
        child: GestureDetector(
          onTap: onTap ?? () => Navigator.pop(context),
          child: SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: Icon(
              PhosphorIcons.arrowLeft(),
              size: 20,
              color: AppColors.black,
            ),
          ),
          ),
        ),
      ),
    );
  }
}
