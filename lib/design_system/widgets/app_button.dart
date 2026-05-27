import 'package:flutter/material.dart';

import 'package:finance_buddy_app/design_system/app_colors.dart';
import 'package:finance_buddy_app/design_system/app_durations.dart';
import 'package:finance_buddy_app/design_system/app_radius.dart';
import 'package:finance_buddy_app/design_system/app_text_styles.dart';

enum AppButtonVariant { primary, ghost }

class AppButton extends StatefulWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onTap,
    this.variant = AppButtonVariant.primary,
    this.disabled = false,
  });

  final String label;
  final VoidCallback onTap;
  final AppButtonVariant variant;
  final bool disabled;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppDurations.fast,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    if (!widget.disabled) _controller.forward();
  }

  void _onTapUp(TapUpDetails _) {
    _controller.reverse();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final isPrimary = widget.variant == AppButtonVariant.primary;

    return Semantics(
      button: true,
      enabled: !widget.disabled,
      label: widget.label,
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        onTap: widget.disabled ? null : widget.onTap,
        child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: Opacity(
          opacity: widget.disabled ? 0.5 : 1.0,
          child: Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              color: isPrimary ? AppColors.black : Colors.transparent,
              borderRadius: AppRadius.full,
              border: isPrimary
                  ? null
                  : Border.all(color: AppColors.black, width: 1.5),
            ),
            alignment: Alignment.center,
            child: Text(
              widget.label,
              style: AppTextStyles.headingS.copyWith(
                color: isPrimary ? AppColors.white : AppColors.black,
              ),
            ),
          ),
          ),
        ),
      ),
    );
  }
}
