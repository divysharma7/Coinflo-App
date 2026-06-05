import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:finance_buddy_app/design_system/design_system.dart';
import 'package:finance_buddy_app/data/db.dart';
import 'package:finance_buddy_app/widgets/common/spendler_bottom_sheet.dart';
import 'package:lottie/lottie.dart';

/// Indian-style digit grouping for amounts (₹78,000 / ₹1,20,000).
String _grouped(num value) {
  final s = value.abs().toStringAsFixed(0);
  if (s.length <= 3) return s;
  final last3 = s.substring(s.length - 3);
  var rest = s.substring(0, s.length - 3);
  final groups = <String>[];
  while (rest.length > 2) {
    groups.insert(0, rest.substring(rest.length - 2));
    rest = rest.substring(0, rest.length - 2);
  }
  groups.insert(0, rest);
  return '${groups.join(',')},$last3';
}

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
    final percent = (progress * 100).round();

    final ringFg = _isCompleted ? _goldDark : AppColors.black;
    final ringBg = _isCompleted ? _goldColor.withValues(alpha: 0.25) : AppColors.gray100;

    Widget card = GestureDetector(
      onTap: _isCompleted ? null : widget.onAddMoney,
      onLongPress: () => _showOptionsSheet(context),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: AppRadius.xl,
          boxShadow: const [...AppShadows.sm],
          border: _isCompleted
              ? Border.all(color: _goldColor.withValues(alpha: 0.6), width: 1.5)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Center(
              child: ProgressRing(
                progress: progress,
                size: 72,
                strokeWidth: 7,
                color: ringFg,
                trackColor: ringBg,
                center: _isCompleted
                    ? const PhosphorIcon(
                        PhosphorIconsFill.trophy,
                        size: 22,
                        color: _goldDark,
                      )
                    : Text(
                        '$percent%',
                        style: AppTextStyles.numericM.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                          color: AppColors.black,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              goal.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodyM.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
                color: _isCompleted ? _goldDark : AppColors.black,
              ),
            ),
            const SizedBox(height: 2),
            RichText(
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                style: AppTextStyles.bodyS.copyWith(
                  fontSize: 12,
                  color: AppColors.gray500,
                ),
                children: [
                  TextSpan(
                    text: '${widget.symbol}${_grouped(goal.currentAmount)} ',
                    style: AppTextStyles.numericM.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _isCompleted ? _goldDark : AppColors.black,
                    ),
                  ),
                  TextSpan(
                    text: '/ ${widget.symbol}${_grouped(goal.targetAmount)}',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    // Wrap in animated scale + glow when completed.
    if (_isCompleted) {
      card = AnimatedBuilder(
        animation: _celebrationCtrl,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnim.value,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: AppRadius.xl,
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
      // Add confetti Lottie overlay.
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

  void _confirmDelete(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Goal'),
        content: Text('Delete "${widget.goal.name}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              widget.onDelete();
            },
            child: const Text('Delete',
                style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
  }

  void _showOptionsSheet(BuildContext context) {
    showSpendlerSheet<void>(
      context: context,
      isScrollControlled: false,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!_isCompleted)
              ListTile(
                leading: PhosphorIcon(PhosphorIcons.plus(), color: AppColors.black),
                title: const Text('Add Money'),
                onTap: () {
                  Navigator.pop(ctx);
                  widget.onAddMoney();
                },
              ),
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
                _confirmDelete(context);
              },
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }
}
