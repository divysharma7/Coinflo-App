import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finance_buddy_app/design_system/design_system.dart';
import 'package:finance_buddy_app/providers/providers.dart';

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
      labelStyle: AppTextStyles.bodyS.copyWith(color: AppColors.gray500),
      prefixText: prefix,
      prefixStyle: AppTextStyles.bodyM.copyWith(color: AppColors.gray500),
      filled: true,
      fillColor: AppColors.gray100,
      border: OutlineInputBorder(
        borderRadius: AppRadius.base,
        borderSide: BorderSide.none,
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
          Text('Family Entry',
              style: AppTextStyles.headingS.copyWith(color: AppColors.black)),
          const SizedBox(height: AppSpacing.lg),

          // Type toggle
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.gray100,
              borderRadius: AppRadius.xxl,
            ),
            child: Row(
              children: [_EntryType.inflow, _EntryType.outflow].map((t) {
                final selected = _type == t;
                final label =
                    t == _EntryType.inflow ? 'Inflow' : 'Outflow';
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _type = t),
                    child: AnimatedContainer(
                      duration: AppDurations.fast,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.black
                            : Colors.transparent,
                        borderRadius: AppRadius.xlSm,
                      ),
                      child: Center(
                        child: Text(label,
                            style: AppTextStyles.bodyS.copyWith(
                                fontWeight: FontWeight.w600,
                                color: selected
                                    ? AppColors.white
                                    : AppColors.gray500)),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          TextField(
            controller: _amountController,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            style: AppTextStyles.headingM.copyWith(color: AppColors.black),
            decoration: _inputDecor('Amount', prefix: '\$ '),
          ),
          const SizedBox(height: AppSpacing.sm),

          TextField(
            controller: _fromController,
            style: AppTextStyles.bodyM.copyWith(color: AppColors.black),
            decoration: _inputDecor(
              _type == _EntryType.inflow
                  ? 'From (Mom, Dad, etc.)'
                  : 'To (person)',
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          TextField(
            controller: _noteController,
            style: AppTextStyles.bodyM.copyWith(color: AppColors.black),
            decoration: _inputDecor('Note (optional)'),
          ),
          const SizedBox(height: AppSpacing.xl),

          AppButton(
            label: 'Add Entry',
            onTap: _save,
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amountController.text.trim());
    final from = _fromController.text.trim();
    if (amount == null || amount <= 0 || from.isEmpty) return;

    await HapticFeedback.mediumImpact();
    final note = _noteController.text.trim();
    await insertFamilyEntry(
      ref.read(repositoryProvider),
      type: _type.name,
      amount: amount,
      fromPerson: from,
      note: note.isEmpty ? null : note,
      investmentType:
          _type == _EntryType.investment ? _investmentType : null,
    );
    if (mounted) Navigator.pop(context);
  }
}
