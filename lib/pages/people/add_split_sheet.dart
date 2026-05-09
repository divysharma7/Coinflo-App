import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:finance_buddy_app/core/tokens.dart';
import 'package:finance_buddy_app/data/db.dart';
import 'package:finance_buddy_app/providers/providers.dart';
import 'package:finance_buddy_app/widgets/common/neo_pop_button.dart';

/// MECE Split Cases:
/// 1. I paid for the group → friends owe me (direction: they_owe_me)
/// 2. Friend paid for the group → I owe them (direction: i_owe_them)
/// 3. I paid for one person → they owe me full amount
/// 4. Someone paid for me → I owe them full amount
///
/// All cases reduce to: pick a friend, pick direction, enter amount.
class AddSplitSheet extends ConsumerStatefulWidget {
  const AddSplitSheet({super.key});

  @override
  ConsumerState<AddSplitSheet> createState() => _AddSplitSheetState();
}

class _AddSplitSheetState extends ConsumerState<AddSplitSheet> {
  // Step 1: Who paid?
  // 'i_paid' = I paid, they owe me
  // 'they_paid' = They paid, I owe them
  String? _whoPaid;

  // Step 2: Which friend?
  FriendContact? _selectedFriend;

  // Step 3: Amount + note
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  String get _direction => _whoPaid == 'i_paid' ? 'they_owe_me' : 'i_owe_them';

  InputDecoration _inputDecor(String label, {String? prefix}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: SpendlerColors.textSecondary),
      prefixText: prefix,
      prefixStyle: const TextStyle(color: SpendlerColors.textSecondary),
      filled: true,
      fillColor: SpendlerColors.surface,
      border: const UnderlineInputBorder(borderSide: BorderSide(color: SpendlerColors.border)),
      enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: SpendlerColors.border)),
      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: SpendlerColors.primary.withValues(alpha: 0.8))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final contacts = ref.watch(friendContactsProvider);

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('ADD A SPLIT', style: SpendlerTextStyles.sectionLabel),
          const SizedBox(height: SpendlerSpacing.lg),

          // ── Step 1: Who paid? ──
          const Text('Who paid?', style: TextStyle(color: SpendlerColors.textSecondary, fontSize: 13)),
          const SizedBox(height: SpendlerSpacing.sm),
          Row(
            children: [
              Expanded(child: _DirectionTile(
                label: 'I paid',
                sublabel: 'They owe me',
                icon: PhosphorIcons.arrowUpRight(),
                color: SpendlerColors.income,
                selected: _whoPaid == 'i_paid',
                onTap: () => setState(() => _whoPaid = 'i_paid'),
              )),
              const SizedBox(width: SpendlerSpacing.sm),
              Expanded(child: _DirectionTile(
                label: 'They paid',
                sublabel: 'I owe them',
                icon: PhosphorIcons.arrowDownLeft(),
                color: SpendlerColors.warning,
                selected: _whoPaid == 'they_paid',
                onTap: () => setState(() => _whoPaid = 'they_paid'),
              )),
            ],
          ),
          const SizedBox(height: SpendlerSpacing.lg),

          // ── Step 2: Which friend? ──
          const Text('With who?', style: TextStyle(color: SpendlerColors.textSecondary, fontSize: 13)),
          const SizedBox(height: SpendlerSpacing.sm),
          contacts.when(
            data: (list) {
              if (list.isEmpty) {
                return const Text('Add a friend first.', style: TextStyle(color: SpendlerColors.textTertiary, fontSize: 13));
              }
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: list.map((c) {
                  final selected = _selectedFriend?.id == c.id;
                  Color chipColor;
                  try {
                    chipColor = Color(int.parse('FF${c.avatarColour.replaceFirst('#', '')}', radix: 16));
                  } on FormatException {
                    chipColor = SpendlerColors.textTertiary;
                  }
                  return GestureDetector(
                    onTap: () => setState(() => _selectedFriend = c),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected ? SpendlerColors.primary.withValues(alpha: 0.12) : SpendlerColors.surface,
                        borderRadius: BorderRadius.circular(SpendlerRadii.pill),
                        border: Border.all(color: selected ? SpendlerColors.primary : SpendlerColors.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            radius: 10,
                            backgroundColor: chipColor,
                            child: Text(c.name[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
                          ),
                          const SizedBox(width: 6),
                          Text(c.name, style: TextStyle(color: selected ? SpendlerColors.primary : SpendlerColors.textPrimary, fontSize: 13, fontWeight: selected ? FontWeight.w600 : FontWeight.w400)),
                          if (selected) ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.check, color: SpendlerColors.primary, size: 14),
                          ],
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
          const SizedBox(height: SpendlerSpacing.lg),

          // ── Step 3: Amount ──
          TextField(
            controller: _amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: SpendlerColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w600),
            cursorColor: SpendlerColors.primary,
            decoration: _inputDecor('Amount', prefix: '\$ '),
          ),
          const SizedBox(height: SpendlerSpacing.cardGap),
          TextField(
            controller: _noteCtrl,
            style: const TextStyle(color: SpendlerColors.textPrimary),
            cursorColor: SpendlerColors.primary,
            decoration: _inputDecor('What for? (optional)'),
          ),
          const SizedBox(height: SpendlerSpacing.xl),

          // ── Confirm ──
          NeoPOPButton(
            label: 'Add Split',
            onTap: _canSave ? _save : null,
          ),
        ],
      ),
    );
  }

  bool get _canSave {
    final amount = double.tryParse(_amountCtrl.text.trim());
    return _whoPaid != null && _selectedFriend != null && amount != null && amount > 0;
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amountCtrl.text.trim());
    if (amount == null || amount <= 0 || _selectedFriend == null || _whoPaid == null) return;

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
        duration: SpendlerMotion.micro,
        padding: const EdgeInsets.all(SpendlerSpacing.cardPadding),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.1) : SpendlerColors.surface,
          borderRadius: BorderRadius.circular(SpendlerRadii.card),
          border: Border.all(
            color: selected ? color : SpendlerColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            PhosphorIcon(icon, size: 24, color: selected ? color : SpendlerColors.textSecondary),
            const SizedBox(height: SpendlerSpacing.sm),
            Text(label, style: TextStyle(color: selected ? color : SpendlerColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
            Text(sublabel, style: TextStyle(color: selected ? color.withValues(alpha: 0.7) : SpendlerColors.textTertiary, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
