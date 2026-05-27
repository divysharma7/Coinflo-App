import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:finance_buddy_app/design_system/app_colors.dart';
import 'package:finance_buddy_app/design_system/app_radius.dart';
import 'package:finance_buddy_app/design_system/app_spacing.dart';
import 'package:finance_buddy_app/design_system/app_text_styles.dart';

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.label,
    this.hintText,
    this.prefixText,
    this.autofocus = false,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.onChanged,
    this.focusNode,
    this.textAlign = TextAlign.start,
    this.style,
    this.hasError = false,
  });

  final TextEditingController? controller;
  final String? label;
  final String? hintText;
  final String? prefixText;
  final bool autofocus;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final FocusNode? focusNode;
  final TextAlign textAlign;
  final TextStyle? style;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: AppTextStyles.labelM.copyWith(color: AppColors.gray500),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: AppColors.gray100,
            borderRadius: AppRadius.md,
            border: hasError
                ? Border.all(color: AppColors.red, width: 1.5)
                : null,
          ),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            autofocus: autofocus,
            keyboardType: keyboardType,
            textCapitalization: textCapitalization,
            inputFormatters: inputFormatters,
            textAlign: textAlign,
            style: style ?? AppTextStyles.bodyM.copyWith(color: AppColors.black),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: AppTextStyles.bodyM.copyWith(color: AppColors.gray500),
              prefixText: prefixText,
              prefixStyle: AppTextStyles.bodyM.copyWith(color: AppColors.gray500),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
