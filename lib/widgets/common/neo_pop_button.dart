import 'package:flutter/material.dart';
import 'package:finance_buddy_app/core/tokens.dart';

/// A Cred-style NeoPOP button with a physical press effect.
///
/// The button has a darker shadow layer offset behind it. On press the
/// front layer slides into the shadow, giving a tactile "key press" feel.
///
/// Use sparingly — only on "Confirm All" and "Share Weekly Poster".
class NeoPOPButton extends StatefulWidget {
  const NeoPOPButton({
    super.key,
    required this.label,
    required this.onTap,
    this.color = SpendlerColors.accentYellow,
    this.shadowColor = SpendlerColors.neoPopShadow,
    this.textColor = Colors.black,
    this.offset = 4.0,
  });

  final String label;
  final VoidCallback? onTap;
  final Color color;
  final Color shadowColor;
  final Color textColor;
  final double offset;

  @override
  State<NeoPOPButton> createState() => _NeoPOPButtonState();
}

class _NeoPOPButtonState extends State<NeoPOPButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: SpendlerMotion.neoPopPress,
    );
    _anim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: SpendlerMotion.neoPopCurve),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) => _ctrl.forward();
  void _onTapUp(TapUpDetails _) {
    _ctrl.reverse();
    widget.onTap?.call();
  }

  void _onTapCancel() => _ctrl.reverse();

  @override
  Widget build(BuildContext context) {
    final o = widget.offset;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _anim,
        builder: (context, child) {
          final press = _anim.value;
          return SizedBox(
            height: 56 + o,
            child: Stack(
              children: [
                // Shadow / back layer
                Positioned(
                  left: o,
                  right: 0,
                  top: o,
                  bottom: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: widget.shadowColor,
                      borderRadius: BorderRadius.circular(SpendlerRadii.button),
                    ),
                  ),
                ),
                // Front layer
                Positioned(
                  left: o * press,
                  right: o * (1 - press),
                  top: o * press,
                  bottom: o * (1 - press),
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: widget.color,
                      borderRadius: BorderRadius.circular(SpendlerRadii.button),
                    ),
                    child: Text(
                      widget.label.toUpperCase(),
                      style: TextStyle(
                        color: widget.textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
