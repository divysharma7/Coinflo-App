import 'package:finance_buddy_app/widgets/common/error_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:finance_buddy_app/design_system/design_system.dart';
import 'package:finance_buddy_app/data/db.dart';
import 'package:finance_buddy_app/providers/providers.dart';

class AddSplitSheet extends ConsumerStatefulWidget {
  const AddSplitSheet({super.key});

  @override
  ConsumerState<AddSplitSheet> createState() => _AddSplitSheetState();
}

class _AddSplitSheetState extends ConsumerState<AddSplitSheet> {
  static String _sym(WidgetRef ref) {
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

  String? _whoPaid;
  FriendContact? _selectedFriend;
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  String get _direction =>
      _whoPaid == 'i_paid' ? 'they_owe_me' : 'i_owe_them';

  @override
  Widget build(BuildContext context) {
    final contacts = ref.watch(friendContactsProvider);

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Add a Split',
              style: AppTextStyles.headingS.copyWith(color: AppColors.black)),
          const SizedBox(height: AppSpacing.lg),

          // Step 1: Who paid?
          Text('Who paid?',
              style: AppTextStyles.bodyS.copyWith(color: AppColors.gray500)),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _DirectionTile(
                  label: 'I paid',
                  sublabel: 'They owe me',
                  icon: PhosphorIcons.arrowUpRight(),
                  color: AppColors.green,
                  selected: _whoPaid == 'i_paid',
                  onTap: () => setState(() => _whoPaid = 'i_paid'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _DirectionTile(
                  label: 'They paid',
                  sublabel: 'I owe them',
                  icon: PhosphorIcons.arrowDownLeft(),
                  color: AppColors.orange,
                  selected: _whoPaid == 'they_paid',
                  onTap: () => setState(() => _whoPaid = 'they_paid'),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Step 2: Which friend?
          Text('With who?',
              style: AppTextStyles.bodyS.copyWith(color: AppColors.gray500)),
          const SizedBox(height: AppSpacing.sm),
          contacts.when(
            data: (list) {
              if (list.isEmpty) {
                return Text('Add a friend first.',
                    style: AppTextStyles.bodyS
                        .copyWith(color: AppColors.gray500));
              }
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: list.map((c) {
                  final selected = _selectedFriend?.id == c.id;
                  Color chipColor;
                  try {
                    chipColor = Color(int.parse(
                        'FF${c.avatarColour.replaceFirst('#', '')}',
                        radix: 16));
                  } on FormatException {
                    chipColor = AppColors.gray500;
                  }
                  return GestureDetector(
                    onTap: () => setState(() => _selectedFriend = c),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.black.withValues(alpha: 0.05)
                            : AppColors.white,
                        borderRadius: AppRadius.lg,
                        border: Border.all(
                            color: selected
                                ? AppColors.black
                                : AppColors.gray200),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            radius: 10,
                            backgroundColor: chipColor,
                            child: Text(c.name[0].toUpperCase(),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600)),
                          ),
                          const SizedBox(width: 6),
                          Text(c.name,
                              style: AppTextStyles.bodyS.copyWith(
                                  color: selected
                                      ? AppColors.black
                                      : AppColors.gray500,
                                  fontWeight: selected
                                      ? FontWeight.w600
                                      : FontWeight.w400)),
                          if (selected) ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.check,
                                color: AppColors.black, size: 14),
                          ],
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const ErrorCard(),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Step 3: Amount
          TextField(
            controller: _amountCtrl,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            style: AppTextStyles.headingM.copyWith(color: AppColors.black),
            decoration: InputDecoration(
              labelText: 'Amount',
              prefixText: '${_sym(ref)} ',
              prefixStyle:
                  AppTextStyles.headingM.copyWith(color: AppColors.gray500),
              labelStyle:
                  AppTextStyles.bodyS.copyWith(color: AppColors.gray500),
              filled: true,
              fillColor: AppColors.gray100,
              border: OutlineInputBorder(
                borderRadius: AppRadius.base,
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _noteCtrl,
            style: AppTextStyles.bodyM.copyWith(color: AppColors.black),
            decoration: InputDecoration(
              labelText: 'What for? (optional)',
              labelStyle:
                  AppTextStyles.bodyS.copyWith(color: AppColors.gray500),
              filled: true,
              fillColor: AppColors.gray100,
              border: OutlineInputBorder(
                borderRadius: AppRadius.base,
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          AppButton(
            label: 'Add Split',
            onTap: _canSave ? _save : () {},
            disabled: !_canSave,
          ),
        ],
      ),
    );
  }

  bool get _canSave {
    final amount = double.tryParse(_amountCtrl.text.trim());
    return _whoPaid != null &&
        _selectedFriend != null &&
        amount != null &&
        amount > 0;
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amountCtrl.text.trim());
    if (amount == null ||
        amount <= 0 ||
        _selectedFriend == null ||
        _whoPaid == null) {
      return;
    }

    await HapticFeedback.mediumImpact();
    await insertSplit(
      ref.read(repositoryProvider),
      friendContactId: _selectedFriend!.id,
      amount: amount,
      direction: _direction,
    );
    if (mounted) Navigator.pop(context);
  }
}

class _DirectionTile extends StatelessWidget {
  const _DirectionTile({
    required this.label,
    required this.sublabel,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String sublabel;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: AnimatedContainer(
        duration: AppDurations.fast,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.08)
              : AppColors.white,
          borderRadius: AppRadius.mdLg,
          border: Border.all(
            color: selected ? color : AppColors.gray200,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            PhosphorIcon(icon,
                size: 24,
                color: selected ? color : AppColors.gray500),
            const SizedBox(height: AppSpacing.sm),
            Text(label,
                style: AppTextStyles.bodyM.copyWith(
                    color: selected ? color : AppColors.black,
                    fontWeight: FontWeight.w600)),
            Text(sublabel,
                style: AppTextStyles.labelS.copyWith(
                    color: selected
                        ? color.withValues(alpha: 0.7)
                        : AppColors.gray500)),
          ],
        ),
      ),
    );
  }
}
