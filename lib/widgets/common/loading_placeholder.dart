import 'package:flutter/material.dart';
import 'package:finance_buddy_app/design_system/design_system.dart';

class LoadingPlaceholder extends StatelessWidget {
  const LoadingPlaceholder({super.key, this.height});

  final double? height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: const Center(
        child: CircularProgressIndicator(
          color: AppColors.black,
          strokeWidth: 2,
        ),
      ),
    );
  }
}
