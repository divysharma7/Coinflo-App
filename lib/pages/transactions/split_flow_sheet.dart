import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:finance_buddy_app/design_system/design_system.dart';
import 'package:drift/drift.dart' show Value;
import 'package:finance_buddy_app/data/db.dart';
import 'package:finance_buddy_app/data/repositories/split_repository.dart';
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
  String get _sym {
    final code = ref.watch(selectedCurrencyProvider).valueOrNull ?? 'inr';
    switch (code.toLowerCase()) {
      case 'inr': return '\u20B9';
      case 'usd': return '\$';
      case 'eur': return '\u20AC';
      case 'gbp': return '\u00A3';
      case 'jpy': return '\u00A5';
      default: return '\$';
    }
  }

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
      labelStyle: AppTextStyles.bodyS.copyWith(color: AppColors.gray500),
      prefixText: prefix,
      prefixStyle: AppTextStyles.bodyM.copyWith(color: AppColors.gray500),
      filled: true,
      fillColor: AppColors.gray100,
      border: OutlineInputBorder(borderRadius: AppRadius.base, borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: AppRadius.base, borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: AppRadius.base, borderSide: const BorderSide(color: AppColors.black, width: 1.5)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('SPLIT THIS', style: AppTextStyles.labelM),
          const SizedBox(height: AppSpacing.md),

          // ── Mode selection tiles ──
          _buildModeTiles(),
          const SizedBox(height: AppSpacing.lg),

          // ── Mode content ──
          if (_mode == _SplitMode.equal) _buildEqualMode(),
          if (_mode == _SplitMode.custom) _buildCustomMode(),
        ],
      ),
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
                ? '$_sym${(_equalMyShare).toStringAsFixed(0)} each'
                : null,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
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
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _mode = mode);
      },
      child: AnimatedContainer(
        duration: AppDurations.fast,
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.md,
          horizontal: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.black.withValues(alpha: 0.1)
              : AppColors.white,
          borderRadius: AppRadius.lg,
          border: Border.all(
            color: selected ? AppColors.black : AppColors.gray200,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            PhosphorIcon(
              icon,
              size: 28,
              color: selected ? AppColors.black : AppColors.gray500,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              label,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyS.copyWith(
                color: AppColors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (sublabel != null) ...[
              const SizedBox(height: AppSpacing.xxs),
              Text(
                sublabel,
                textAlign: TextAlign.center,
                style: AppTextStyles.labelS.copyWith(
                  color: selected ? AppColors.gray600 : AppColors.gray500,
                ),
              ),
            ],
          ],
        ),
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
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: AppRadius.lg,
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
              const SizedBox(width: AppSpacing.lg),
              AnimatedSwitcher(
                duration: AppDurations.fast,
                transitionBuilder: (child, anim) => ScaleTransition(
                  scale: anim,
                  child: FadeTransition(opacity: anim, child: child),
                ),
                child: Text(
                  '$_splitCount',
                  key: ValueKey(_splitCount),
                  style: AppTextStyles.displayXL.copyWith(fontSize: 48),
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
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
        const SizedBox(height: AppSpacing.md),

        // Summary card
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.gray600, AppColors.white],
            ),
            borderRadius: AppRadius.lg,
            boxShadow: AppShadows.sm,
          ),
          child: Column(
            children: [
              _summaryRow(
                  'Your share', '$_sym${_equalMyShare.toStringAsFixed(0)}'),
              const SizedBox(height: AppSpacing.sm),
              _summaryRow(
                  'Others owe you', '$_sym${_equalOthersOwe.toStringAsFixed(0)}'),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

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
        const SizedBox(height: AppSpacing.sm),

        // Other person rows
        for (int i = 0; i < _customRows.length; i++) ...[
          _buildPersonRow(i),
          const SizedBox(height: AppSpacing.sm),
        ],

        // Add person button
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            _addCustomRow();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                PhosphorIcon(
                  PhosphorIcons.plusCircle(),
                  size: 18,
                  color: AppColors.black,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'Add person',
                  style: AppTextStyles.bodyS.copyWith(
                    color: AppColors.black,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Running total footer
        _buildTotalFooter(remaining, isBalanced, isOver),
        const SizedBox(height: AppSpacing.lg),

        // Confirm button
        if (!isBalanced)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Text(
              'Allocate the full $_sym${widget.totalAmount.toStringAsFixed(0)} to continue',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyS.copyWith(color: AppColors.amber),
            ),
          ),
        Opacity(
          opacity: isBalanced ? 1.0 : 0.4,
          child: NeoPOPButton(
            label: 'Confirm Split',
            onTap: isBalanced
                ? () => _confirmCustomSplit()
                : null,
          ),
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

  static const _avatarPalette = [
    '#7B8FA1', '#6B8F71', '#A0785A', '#C9A84C', '#8E7AAF', '#7A7A7A',
  ];
  static int _avatarIndex = 0;

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

    // Create Person + TransactionSplit for each named custom row
    for (final row in _customRows) {
      final name = row.nameController.text.trim();
      final amount = double.tryParse(row.amountController.text.trim()) ?? 0;
      if (name.isEmpty || amount <= 0) continue;

      final colour = _avatarPalette[_avatarIndex % _avatarPalette.length];
      _avatarIndex++;

      final personId = await repo.createPerson(
        PersonsCompanion(
          name: Value(name),
          tag: const Value('friend'),
          avatarColor: Value(colour),
        ),
      );

      await repo.createSplits(widget.transactionId, [
        SplitEntry(personId: personId, shareAmount: amount),
      ]);
    }

    if (mounted) {
      nav.pop();
      nav.pop();
    }
  }


  Widget _buildMyShareRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: AppSpacing.xxs, bottom: AppSpacing.xs),
          child: Text('My share', style: AppTextStyles.labelM),
        ),
        TextField(
          controller: _myShareController,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          style: AppTextStyles.headingS.copyWith(color: AppColors.black),
          decoration: _inputDecor('Amount', prefix: '$_sym '),
        ),
      ],
    );
  }

  Widget _buildPersonRow(int index) {
    final row = _customRows[index];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: AppSpacing.xxs, bottom: AppSpacing.xs),
          child: Row(
            children: [
              Text(
                "Friend's share",
                style: AppTextStyles.labelM.copyWith(color: AppColors.gray500),
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
                    color: AppColors.gray500,
                  ),
                ),
            ],
          ),
        ),
        TextField(
          controller: row.nameController,
          textCapitalization: TextCapitalization.words,
          style: AppTextStyles.bodyM.copyWith(color: AppColors.black),
          decoration: _inputDecor('Name (optional)'),
        ),
        const SizedBox(height: AppSpacing.xs),
        TextField(
          controller: row.amountController,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          style: AppTextStyles.headingS.copyWith(color: AppColors.black),
          decoration: _inputDecor('Amount', prefix: '$_sym '),
        ),
      ],
    );
  }

  Widget _buildTotalFooter(
      double remaining, bool isBalanced, bool isOver) {
    final Color statusColor;
    final IconData? statusIcon;
    if (isBalanced) {
      statusColor = AppColors.green;
      statusIcon = PhosphorIcons.checkCircle();
    } else if (isOver) {
      statusColor = AppColors.red;
      statusIcon = null;
    } else {
      statusColor = AppColors.amber;
      statusIcon = null;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppRadius.lg,
        border: Border.all(color: AppColors.gray200),
      ),
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.xs,
        children: [
          Text(
            '$_sym${widget.totalAmount.toStringAsFixed(0)} total',
            style: AppTextStyles.bodyS.copyWith(color: AppColors.gray500),
          ),
          Text(
            '·',
            style: AppTextStyles.bodyS.copyWith(color: AppColors.gray500),
          ),
          Text(
            'Allocated: $_sym${_customAllocated.toStringAsFixed(0)}',
            style: AppTextStyles.bodyS.copyWith(color: AppColors.gray500),
          ),
          Text(
            '·',
            style: AppTextStyles.bodyS.copyWith(color: AppColors.gray500),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Remaining: $_sym${remaining.toStringAsFixed(0)}',
                style: AppTextStyles.bodyS.copyWith(
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (statusIcon != null) ...[
                const SizedBox(width: AppSpacing.xxs),
                PhosphorIcon(statusIcon, size: 16, color: statusColor),
              ],
            ],
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
    return Semantics(
      button: true,
      enabled: enabled,
      label: filled ? 'Increase count' : 'Decrease count',
      child: GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: filled && enabled ? AppColors.black : Colors.transparent,
          border: Border.all(
            color: enabled ? AppColors.black : AppColors.gray200,
            width: 1.5,
          ),
        ),
        child: Icon(
          icon,
          color: filled && enabled
              ? AppColors.white
              : (enabled ? AppColors.black : AppColors.gray500),
          size: 20,
        ),
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
              AppTextStyles.bodyM.copyWith(color: AppColors.gray500),
        ),
        Text(
          value,
          style: AppTextStyles.headingM.copyWith(color: AppColors.black),
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
