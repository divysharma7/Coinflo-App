import 'dart:math';

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:finance_buddy_app/design_system/design_system.dart';
import 'package:finance_buddy_app/data/db.dart';
import 'package:finance_buddy_app/widgets/common/spendler_bottom_sheet.dart';
import 'package:lottie/lottie.dart';

class GoalCard extends StatefulWidget {
  const GoalCard({
    super.key,
    required this.goal,
    required this.onAddMoney,
    required this.onDelete,
    required this.onEdit,
    required this.symbol,
  });

  final SavingsGoal goal;
  final VoidCallback onAddMoney;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final String symbol;

  @override
  State<GoalCard> createState() => _GoalCardState();
}

class _GoalCardState extends State<GoalCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _celebrationCtrl;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _glowAnim;

  static const _goldColor = AppColors.gold;
  static const _goldDark = AppColors.amber;

  bool get _isCompleted => widget.goal.currentAmount >= widget.goal.targetAmount;

  IconData _resolveIcon(String iconName) {
    switch (iconName) {
      case 'airplane':
        return PhosphorIconsFill.airplane;
      case 'car':
        return PhosphorIconsFill.car;
      case 'house':
        return PhosphorIconsFill.house;
      case 'graduationCap':
        return PhosphorIconsFill.graduationCap;
      case 'heartbeat':
        return PhosphorIconsFill.heartbeat;
      case 'laptop':
        return PhosphorIconsFill.laptop;
      case 'gift':
        return PhosphorIconsFill.gift;
      case 'piggyBank':
        return PhosphorIconsFill.piggyBank;
      default:
        return PhosphorIconsFill.star;
    }
  }

  @override
  void initState() {
    super.initState();
    _celebrationCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.03), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.03, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(
      parent: _celebrationCtrl,
      curve: Curves.easeInOut,
    ));
    _glowAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.25), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 0.25, end: 0.0), weight: 50),
    ]).animate(CurvedAnimation(
      parent: _celebrationCtrl,
      curve: Curves.easeInOut,
    ));

    if (_isCompleted) {
      _celebrationCtrl.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant GoalCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isCompleted && !_celebrationCtrl.isAnimating) {
      _celebrationCtrl.repeat();
    } else if (!_isCompleted && _celebrationCtrl.isAnimating) {
      _celebrationCtrl.stop();
      _celebrationCtrl.reset();
    }
  }

  @override
  void dispose() {
    _celebrationCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final goal = widget.goal;
    final progress = goal.targetAmount > 0
        ? (goal.currentAmount / goal.targetAmount).clamp(0.0, 1.0)
        : 0.0;
    final remaining = goal.targetAmount - goal.currentAmount;

    final ringFg = _isCompleted ? _goldDark : AppColors.black;
    final ringBg = _isCompleted ? _goldColor.withValues(alpha: 0.25) : AppColors.gray200;

    Widget card = GestureDetector(
      onLongPress: () => _showOptionsSheet(context),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: const BorderRadius.all(Radius.circular(16)),
          boxShadow: const [
            ...AppShadows.sm,
          ],
          border: _isCompleted
              ? Border.all(color: _goldColor.withValues(alpha: 0.6), width: 1.5)
              : null,
        ),
        child: Row(
          children: [
            // Progress ring
            SizedBox(
              width: 64,
              height: 64,
              child: CustomPaint(
                painter: GoalRingPainter(
                  progress: progress,
                  strokeWidth: 5,
                  foregroundColor: ringFg,
                  backgroundColor: ringBg,
                ),
                child: Center(
                  child: _isCompleted
                      ? const PhosphorIcon(
                          PhosphorIconsFill.trophy,
                          size: 24,
                          color: _goldDark,
                        )
                      : PhosphorIcon(
                          _resolveIcon(goal.iconName),
                          size: 22,
                          color: AppColors.black,
                        ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          goal.name,
                          style: AppTextStyles.bodyM.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.black,
                          ),
                        ),
                      ),
                      if (_isCompleted) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: _goldColor.withValues(alpha: 0.18),
                            borderRadius: AppRadius.lg,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const PhosphorIcon(
                                PhosphorIconsFill.star,
                                size: 12,
                                color: _goldDark,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                'Goal reached!',
                                style: AppTextStyles.labelS.copyWith(
                                  color: _goldDark,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${widget.symbol}${goal.currentAmount.toStringAsFixed(0)} of ${widget.symbol}${goal.targetAmount.toStringAsFixed(0)}',
                    style: AppTextStyles.bodyS.copyWith(
                      color: _isCompleted ? _goldDark : AppColors.gray500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    remaining > 0
                        ? '${widget.symbol}${remaining.toStringAsFixed(0)} to go'
                        : 'Congratulations!',
                    style: AppTextStyles.labelS.copyWith(
                      color: remaining > 0
                          ? AppColors.gray500
                          : _goldDark,
                      fontWeight: remaining > 0
                          ? FontWeight.w400
                          : FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            // Add money button
            if (!_isCompleted)
              GestureDetector(
                onTap: widget.onAddMoney,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.black.withValues(alpha: 0.1),
                    borderRadius: AppRadius.sm,
                  ),
                  child: Center(
                    child: Icon(
                      PhosphorIcons.plus(),
                      size: 20,
                      color: AppColors.black,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    // Wrap in animated scale + glow when completed
    if (_isCompleted) {
      card = AnimatedBuilder(
        animation: _celebrationCtrl,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnim.value,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.all(Radius.circular(16)),
                boxShadow: [
                  BoxShadow(
                    color: _goldColor.withValues(alpha: _glowAnim.value),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: child,
            ),
          );
        },
        child: card,
      );
      // Add confetti Lottie overlay
      card = Stack(
        clipBehavior: Clip.none,
        children: [
          card,
          Positioned.fill(
            child: IgnorePointer(
              child: Lottie.asset(
                'assets/lottie/confetti.json',
                repeat: false,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      );
    }

    return card;
  }

  void _showOptionsSheet(BuildContext context) {
    showSpendlerSheet<void>(
      context: context,
      isScrollControlled: false,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: PhosphorIcon(PhosphorIcons.pencilSimple(), color: AppColors.black),
              title: const Text('Edit Goal'),
              onTap: () {
                Navigator.pop(ctx);
                widget.onEdit();
              },
            ),
            ListTile(
              leading: PhosphorIcon(PhosphorIcons.trash(), color: AppColors.red),
              title: const Text('Delete Goal', style: TextStyle(color: AppColors.red)),
              onTap: () {
                Navigator.pop(ctx);
                widget.onDelete();
              },
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }
}

// ─── Goal Ring Painter ────────────────────────────────

class GoalRingPainter extends CustomPainter {
  GoalRingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.foregroundColor,
    required this.backgroundColor,
  });

  final double progress;
  final double strokeWidth;
  final Color foregroundColor;
  final Color backgroundColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, 2 * pi, false, bgPaint);

    if (progress > 0) {
      final fgPaint = Paint()
        ..color = foregroundColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, -pi / 2, progress * 2 * pi, false, fgPaint);
    }
  }

  @override
  bool shouldRepaint(covariant GoalRingPainter old) =>
      old.progress != progress ||
      old.foregroundColor != foregroundColor ||
      old.backgroundColor != backgroundColor;
}
