import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:finance_buddy_app/core/tokens.dart';
import 'package:finance_buddy_app/providers/providers.dart';
import 'package:finance_buddy_app/widgets/common/neo_pop_button.dart';

enum _SplitMode { equal, custom }

class SplitFlowSheet extends ConsumerStatefulWidget {
  final int transactionId;
  final double totalAmount;

  const SplitFlowSheet({
    super.key,
    required this.transactionId,
    required this.totalAmount,
  });

  @override
  ConsumerState<SplitFlowSheet> createState() => _SplitFlowSheetState();
}

class _SplitFlowSheetState extends ConsumerState<SplitFlowSheet> {
  _SplitMode? _mode;

  // ── Equal split state ──
  int _splitCount = 2;

  double get _equalMyShare => widget.totalAmount / _splitCount;
  double get _equalOthersOwe => widget.totalAmount - _equalMyShare;

  // ── Custom split state ──
  final List<_PersonRow> _customRows = [];
  final _myShareController = TextEditingController();

  double get _customMyShare =>
      double.tryParse(_myShareController.text.trim()) ?? 0;

  double get _customAllocated {
    double sum = _customMyShare;
    for (final row in _customRows) {
      sum += double.tryParse(row.amountController.text.trim()) ?? 0;
    }
    return sum;
  }

  double get _customRemaining => widget.totalAmount - _customAllocated;

  int get _customPersonCount => 1 + _customRows.length; // me + others

  @override
  void initState() {
    super.initState();
    _myShareController.addListener(_onCustomChanged);
    // Start with one other-person row
    _addCustomRow();
  }

  @override
  void dispose() {
    _myShareController.dispose();
    for (final row in _customRows) {
      row.dispose();
    }
    super.dispose();
  }

  void _onCustomChanged() => setState(() {});

  void _addCustomRow() {
    final row = _PersonRow();
    row.amountController.addListener(_onCustomChanged);
    setState(() => _customRows.add(row));
  }

  void _removeCustomRow(int index) {
    final row = _customRows.removeAt(index);
    row.amountController.removeListener(_onCustomChanged);
    row.dispose();
    setState(() {});
  }

  // ── Input decoration (matches family_entry_sheet.dart) ──
  InputDecoration _inputDecor(String label, {String? prefix}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: PaisaColors.textSecondary),
      prefixText: prefix,
      prefixStyle: const TextStyle(color: PaisaColors.textSecondary),
      filled: true,
      fillColor: PaisaColors.surface,
      border: const UnderlineInputBorder(
        borderSide: BorderSide(color: PaisaColors.border),
      ),
      enabledBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: PaisaColors.border),
      ),
      focusedBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: PaisaColors.yellow.withValues(alpha: 0.8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('SPLIT THIS', style: PaisaTextStyles.sectionLabel),
        const SizedBox(height: PaisaSpacing.md),

        // ── Mode selection tiles ──
        _buildModeTiles(),
        const SizedBox(height: PaisaSpacing.lg),

        // ── Mode content ──
        if (_mode == _SplitMode.equal) _buildEqualMode(),
        if (_mode == _SplitMode.custom) _buildCustomMode(),
      ],
    );
  }

  // ────────────────────────────────────────────────────────
  // Mode selection tiles
  // ────────────────────────────────────────────────────────
  Widget _buildModeTiles() {
    return Row(
      children: [
        Expanded(
          child: _modeTile(
            mode: _SplitMode.equal,
            icon: PhosphorIcons.divide(),
            label: 'Equal Split',
            sublabel: _mode != null
                ? '₹${(_equalMyShare).toStringAsFixed(0)} each'
                : null,
          ),
        ),
        const SizedBox(width: PaisaSpacing.cardGap),
        Expanded(
          child: _modeTile(
            mode: _SplitMode.custom,
            icon: PhosphorIcons.slidersHorizontal(),
            label: 'Custom Amounts',
            sublabel: "Set each person's share",
          ),
        ),
      ],
    );
  }

  Widget _modeTile({
    required _SplitMode mode,
    required IconData icon,
    required String label,
    String? sublabel,
  }) {
    final selected = _mode == mode;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _mode = mode);
      },
      child: AnimatedContainer(
        duration: PaisaMotion.micro,
        padding: const EdgeInsets.symmetric(
          vertical: PaisaSpacing.md,
          horizontal: PaisaSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: selected
              ? PaisaColors.yellow.withValues(alpha: 0.1)
              : PaisaColors.surface,
          borderRadius: BorderRadius.circular(PaisaRadii.card),
          border: Border.all(
            color: selected ? PaisaColors.yellow : PaisaColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            PhosphorIcon(
              icon,
              size: 28,
              color: selected ? PaisaColors.yellow : PaisaColors.textSecondary,
            ),
            const SizedBox(height: PaisaSpacing.sm),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color:
                    selected ? PaisaColors.yellow : PaisaColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (sublabel != null) ...[
              const SizedBox(height: 2),
              Text(
                sublabel,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: selected
                      ? PaisaColors.yellow.withValues(alpha: 0.7)
                      : PaisaColors.textTertiary,
                  fontSize: 11,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────────
  // Equal split mode
  // ────────────────────────────────────────────────────────
  Widget _buildEqualMode() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Headcount selector on dark surface
        Container(
          padding: const EdgeInsets.symmetric(vertical: PaisaSpacing.md),
          decoration: BoxDecoration(
            color: PaisaColors.surface,
            borderRadius: BorderRadius.circular(PaisaRadii.card),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _circleButton(
                icon: Icons.remove,
                filled: false,
                onTap: _splitCount > 2
                    ? () {
                        HapticFeedback.lightImpact();
                        setState(() => _splitCount--);
                      }
                    : null,
              ),
              const SizedBox(width: PaisaSpacing.lg),
              AnimatedSwitcher(
                duration: PaisaMotion.micro,
                transitionBuilder: (child, anim) => ScaleTransition(
                  scale: anim,
                  child: FadeTransition(opacity: anim, child: child),
                ),
                child: Text(
                  '$_splitCount',
                  key: ValueKey(_splitCount),
                  style: PaisaTextStyles.heroAmount.copyWith(fontSize: 48),
                ),
              ),
              const SizedBox(width: PaisaSpacing.lg),
              _circleButton(
                icon: Icons.add,
                filled: true,
                onTap: _splitCount < 20
                    ? () {
                        HapticFeedback.lightImpact();
                        setState(() => _splitCount++);
                      }
                    : null,
              ),
            ],
          ),
        ),
        const SizedBox(height: PaisaSpacing.md),

        // Summary card
        Container(
          padding: const EdgeInsets.all(PaisaSpacing.cardPadding),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1E1E1E), PaisaColors.surface],
            ),
            borderRadius: BorderRadius.circular(PaisaRadii.card),
            boxShadow: PaisaShadows.card,
          ),
          child: Column(
            children: [
              _summaryRow(
                  'Your share', '₹${_equalMyShare.toStringAsFixed(0)}'),
              const SizedBox(height: PaisaSpacing.sm),
              _summaryRow(
                  'Others owe you', '₹${_equalOthersOwe.toStringAsFixed(0)}'),
            ],
          ),
        ),
        const SizedBox(height: PaisaSpacing.lg),

        NeoPOPButton(
          label: 'Confirm Split',
          onTap: () => _confirmEqualSplit(),
        ),
      ],
    );
  }

  // ────────────────────────────────────────────────────────
  // Custom amounts mode
  // ────────────────────────────────────────────────────────
  Widget _buildCustomMode() {
    final remaining = _customRemaining;
    final isBalanced = (remaining.abs() < 0.01);
    final isOver = remaining < -0.01;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // My share row
        _buildMyShareRow(),
        const SizedBox(height: PaisaSpacing.cardGap),

        // Other person rows
        for (int i = 0; i < _customRows.length; i++) ...[
          _buildPersonRow(i),
          const SizedBox(height: PaisaSpacing.cardGap),
        ],

        // Add person button
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            _addCustomRow();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: PaisaSpacing.sm),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                PhosphorIcon(
                  PhosphorIcons.plusCircle(),
                  size: 18,
                  color: PaisaColors.yellow,
                ),
                const SizedBox(width: PaisaSpacing.xs),
                const Text(
                  'Add person',
                  style: TextStyle(
                    color: PaisaColors.yellow,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: PaisaSpacing.md),

        // Running total footer
        _buildTotalFooter(remaining, isBalanced, isOver),
        const SizedBox(height: PaisaSpacing.lg),

        // Confirm button
        NeoPOPButton(
          label: 'Confirm Split',
          color: isBalanced ? PaisaColors.yellow : PaisaColors.textTertiary,
          shadowColor:
              isBalanced ? PaisaColors.yellowShadow : PaisaColors.border,
          onTap: isBalanced
              ? () => _confirmCustomSplit()
              : () => _showUnallocatedToast(remaining),
        ),
      ],
    );
  }

  Future<void> _confirmEqualSplit() async {
    final nav = Navigator.of(context);
    final repo = ref.read(repositoryProvider);
    await HapticFeedback.mediumImpact();
    await repo.markSplit(
      widget.transactionId,
      _splitCount,
      _equalMyShare,
      _equalOthersOwe,
    );
    if (mounted) {
      nav.pop();
      nav.pop();
    }
  }

  Future<void> _confirmCustomSplit() async {
    final nav = Navigator.of(context);
    final repo = ref.read(repositoryProvider);
    await HapticFeedback.mediumImpact();
    await repo.markSplit(
      widget.transactionId,
      _customPersonCount,
      _customMyShare,
      widget.totalAmount - _customMyShare,
    );
    if (mounted) {
      nav.pop();
      nav.pop();
    }
  }

  void _showUnallocatedToast(double remaining) {
    HapticFeedback.lightImpact();
    if (remaining > 0.01) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '₹${remaining.toStringAsFixed(0)} still unallocated',
          ),
          backgroundColor: PaisaColors.amber,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Widget _buildMyShareRow() {
    return Container(
      padding: const EdgeInsets.all(PaisaSpacing.cardPadding),
      decoration: BoxDecoration(
        color: PaisaColors.surface,
        borderRadius: BorderRadius.circular(PaisaRadii.card),
        border: Border.all(color: PaisaColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'My share',
            style: TextStyle(
              color: PaisaColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: PaisaSpacing.xs),
          TextField(
            controller: _myShareController,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(
              color: PaisaColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
            decoration: _inputDecor('Amount', prefix: '₹ '),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonRow(int index) {
    final row = _customRows[index];
    return AnimatedContainer(
      duration: PaisaMotion.micro,
      curve: PaisaMotion.surfaceCurve,
      padding: const EdgeInsets.all(PaisaSpacing.cardPadding),
      decoration: BoxDecoration(
        color: PaisaColors.surface,
        borderRadius: BorderRadius.circular(PaisaRadii.card),
        border: Border.all(color: PaisaColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Person ${index + 2}',
                style: const TextStyle(
                  color: PaisaColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              if (_customRows.length > 1)
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _removeCustomRow(index);
                  },
                  child: PhosphorIcon(
                    PhosphorIcons.xCircle(),
                    size: 20,
                    color: PaisaColors.textTertiary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: PaisaSpacing.xs),
          TextField(
            controller: row.nameController,
            textCapitalization: TextCapitalization.words,
            style: const TextStyle(
              color: PaisaColors.textPrimary,
              fontSize: 15,
            ),
            decoration: _inputDecor('Name (optional)'),
          ),
          const SizedBox(height: PaisaSpacing.sm),
          TextField(
            controller: row.amountController,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(
              color: PaisaColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
            decoration: _inputDecor('Amount', prefix: '₹ '),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalFooter(
      double remaining, bool isBalanced, bool isOver) {
    final Color statusColor;
    final IconData? statusIcon;
    if (isBalanced) {
      statusColor = PaisaColors.income;
      statusIcon = PhosphorIcons.checkCircle();
    } else if (isOver) {
      statusColor = PaisaColors.expense;
      statusIcon = null;
    } else {
      statusColor = PaisaColors.amber;
      statusIcon = null;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: PaisaSpacing.cardPadding,
        vertical: PaisaSpacing.sm + 2,
      ),
      decoration: BoxDecoration(
        color: PaisaColors.surface,
        borderRadius: BorderRadius.circular(PaisaRadii.card),
        border: Border.all(color: PaisaColors.border),
      ),
      child: Row(
        children: [
          // Total
          Text(
            '₹${widget.totalAmount.toStringAsFixed(0)} total',
            style: const TextStyle(
              color: PaisaColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: PaisaSpacing.sm),
          Container(
            width: 1,
            height: 16,
            color: PaisaColors.border,
          ),
          const SizedBox(width: PaisaSpacing.sm),
          // Allocated
          Text(
            'Allocated: ₹${_customAllocated.toStringAsFixed(0)}',
            style: const TextStyle(
              color: PaisaColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: PaisaSpacing.sm),
          Container(
            width: 1,
            height: 16,
            color: PaisaColors.border,
          ),
          const SizedBox(width: PaisaSpacing.sm),
          // Remaining
          Expanded(
            child: Row(
              children: [
                Text(
                  'Remaining: ₹${remaining.toStringAsFixed(0)}',
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (statusIcon != null) ...[
                  const SizedBox(width: 4),
                  PhosphorIcon(statusIcon, size: 16, color: statusColor),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────────────
  // Shared helpers
  // ────────────────────────────────────────────────────────
  Widget _circleButton({
    required IconData icon,
    required bool filled,
    VoidCallback? onTap,
  }) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: filled && enabled ? PaisaColors.yellow : Colors.transparent,
          border: Border.all(
            color: enabled ? PaisaColors.yellow : PaisaColors.border,
            width: 1.5,
          ),
        ),
        child: Icon(
          icon,
          color: filled && enabled
              ? Colors.black
              : (enabled ? PaisaColors.yellow : PaisaColors.textTertiary),
          size: 20,
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style:
              const TextStyle(color: PaisaColors.textSecondary, fontSize: 15),
        ),
        Text(
          value,
          style: const TextStyle(
            color: PaisaColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

// ── Helper class for custom person rows ──
class _PersonRow {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController amountController = TextEditingController();

  void dispose() {
    nameController.dispose();
    amountController.dispose();
  }
}
