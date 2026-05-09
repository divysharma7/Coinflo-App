import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:finance_buddy_app/core/tokens.dart';
import 'package:finance_buddy_app/data/db.dart';
import 'package:finance_buddy_app/providers/providers.dart';
import 'package:finance_buddy_app/widgets/common/neo_pop_button.dart';

class FamilyEntrySheet extends ConsumerStatefulWidget {
  const FamilyEntrySheet({super.key});

  @override
  ConsumerState<FamilyEntrySheet> createState() => _FamilyEntrySheetState();
}

enum _EntryType { inflow, outflow, investment }

class _FamilyEntrySheetState extends ConsumerState<FamilyEntrySheet> {
  _EntryType _type = _EntryType.inflow;
  final _amountController = TextEditingController();
  final _fromController = TextEditingController();
  final _noteController = TextEditingController();
  String? _investmentType;

  @override
  void dispose() {
    _amountController.dispose();
    _fromController.dispose();
    _noteController.dispose();
    super.dispose();
  }

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
        borderSide: BorderSide(color: PaisaColors.gold.withValues(alpha: 0.8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('FAMILY ENTRY', style: PaisaTextStyles.sectionLabel),
          const SizedBox(height: PaisaSpacing.md),

          SegmentedButton<_EntryType>(
            segments: const [
              ButtonSegment(value: _EntryType.inflow, label: Text('Inflow')),
              ButtonSegment(value: _EntryType.outflow, label: Text('Outflow')),
            ],
            selected: {_type},
            onSelectionChanged: (v) => setState(() => _type = v.first),
          ),
          const SizedBox(height: PaisaSpacing.md),

          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: PaisaColors.textPrimary, fontSize: 18),
            decoration: _inputDecor('Amount', prefix: '₹ '),
          ),
          const SizedBox(height: PaisaSpacing.cardGap),

          TextField(
            controller: _fromController,
            style: const TextStyle(color: PaisaColors.textPrimary),
            decoration: _inputDecor(
              _type == _EntryType.inflow
                  ? 'From (Mom, Dad, etc.)'
                  : _type == _EntryType.outflow
                      ? 'To (person)'
                      : 'Managed by',
            ),
          ),
          const SizedBox(height: PaisaSpacing.cardGap),

          if (_type == _EntryType.investment) ...[
            // Investment type as tappable tiles
            const Text('TYPE', style: PaisaTextStyles.sectionLabel),
            const SizedBox(height: PaisaSpacing.sm),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _investTile('MF', 'Mutual Fund', PhosphorIcons.chartPieSlice()),
                _investTile('Stocks', 'Stocks', PhosphorIcons.trendUp()),
                _investTile('FD', 'Fixed Deposit', PhosphorIcons.vault()),
                _investTile('Other', 'Other', PhosphorIcons.dotsThreeCircle()),
              ],
            ),
            const SizedBox(height: PaisaSpacing.cardGap),
          ],

          TextField(
            controller: _noteController,
            style: const TextStyle(color: PaisaColors.textPrimary),
            decoration: _inputDecor('Note (optional)'),
          ),
          const SizedBox(height: PaisaSpacing.lg),

          NeoPOPButton(
            label: 'Add Entry',
            color: PaisaColors.gold,
            shadowColor: const Color(0xFF8A6B2A),
            onTap: _save,
          ),
        ],
      ),
    );
  }

  Widget _investTile(String value, String label, IconData icon) {
    final selected = _investmentType == value;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _investmentType = value);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? PaisaColors.gold.withValues(alpha: 0.15)
              : PaisaColors.surface,
          borderRadius: BorderRadius.circular(PaisaRadii.button),
          border: selected
              ? Border.all(color: PaisaColors.gold, width: 1.5)
              : Border.all(color: PaisaColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PhosphorIcon(icon, size: 16, color: selected ? PaisaColors.gold : PaisaColors.textSecondary),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? PaisaColors.gold : PaisaColors.textSecondary,
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amountController.text.trim());
    final from = _fromController.text.trim();
    if (amount == null || amount <= 0 || from.isEmpty) return;

    await HapticFeedback.mediumImpact();
    final repo = ref.read(repositoryProvider);
    await repo.insertEntry(FamilyEntriesCompanion.insert(
      type: _type.name,
      amount: amount,
      fromPerson: from,
      note: Value(_noteController.text.trim().isEmpty ? null : _noteController.text.trim()),
      investmentType: Value(_type == _EntryType.investment ? _investmentType : null),
    ));
    if (mounted) Navigator.pop(context);
  }
}
