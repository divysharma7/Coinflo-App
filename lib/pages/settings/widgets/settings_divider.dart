import 'package:flutter/material.dart';
import 'package:finance_buddy_app/design_system/design_system.dart';

// ---------------------------------------------------------------------------
// Divider
// ---------------------------------------------------------------------------

class SettingsDivider extends StatelessWidget {
  const SettingsDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(left: 64),
      child: Divider(height: 1, thickness: 0.5, color: AppColors.gray200),
    );
  }
}
