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
      labelStyle: const TextStyle(color: PaisaColors.textSecondary),
      prefixText: prefix,
      prefixStyle: const TextStyle(color: PaisaColors.textSecondary),
      filled: true,
      fillColor: PaisaColors.surface,
      border: const UnderlineInputBorder(borderSide: BorderSide(color: PaisaColors.border)),
      enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: PaisaColors.border)),
      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: PaisaColors.yellow.withValues(alpha: 0.8))),
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
          const Text('ADD A SPLIT', style: PaisaTextStyles.sectionLabel),
          const SizedBox(height: PaisaSpacing.lg),

          // ── Step 1: Who paid? ──
          const Text('Who paid?', style: TextStyle(color: PaisaColors.textSecondary, fontSize: 13)),
          const SizedBox(height: PaisaSpacing.sm),
          Row(
            children: [
              Expanded(child: _DirectionTile(
                label: 'I paid',
                sublabel: 'They owe me',
                icon: PhosphorIcons.arrowUpRight(),
                color: PaisaColors.income,
                selected: _whoPaid == 'i_paid',
                onTap: () => setState(() => _whoPaid = 'i_paid'),
              )),
              const SizedBox(width: PaisaSpacing.sm),
              Expanded(child: _DirectionTile(
                label: 'They paid',
                sublabel: 'I owe them',
                icon: PhosphorIcons.arrowDownLeft(),
                color: PaisaColors.amber,
                selected: _whoPaid == 'they_paid',
                onTap: () => setState(() => _whoPaid = 'they_paid'),
              )),
            ],
          ),
          const SizedBox(height: PaisaSpacing.lg),

          // ── Step 2: Which friend? ──
          const Text('With who?', style: TextStyle(color: PaisaColors.textSecondary, fontSize: 13)),
          const SizedBox(height: PaisaSpacing.sm),
          contacts.when(
            data: (list) {
              if (list.isEmpty) {
                return const Text('Add a friend first.', style: TextStyle(color: PaisaColors.textTertiary, fontSize: 13));
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
                    chipColor = PaisaColors.textTertiary;
                  }
                  return GestureDetector(
                    onTap: () => setState(() => _selectedFriend = c),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected ? PaisaColors.yellow.withValues(alpha: 0.12) : PaisaColors.surface,
                        borderRadius: BorderRadius.circular(PaisaRadii.pill),
                        border: Border.all(color: selected ? PaisaColors.yellow : PaisaColors.border),
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
                          Text(c.name, style: TextStyle(color: selected ? PaisaColors.yellow : PaisaColors.textPrimary, fontSize: 13, fontWeight: selected ? FontWeight.w600 : FontWeight.w400)),
                          if (selected) ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.check, color: PaisaColors.yellow, size: 14),
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
          const SizedBox(height: PaisaSpacing.lg),

          // ── Step 3: Amount ──
          TextField(
            controller: _amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: PaisaColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w600),
            cursorColor: PaisaColors.yellow,
            decoration: _inputDecor('Amount', prefix: '₹ '),
          ),
          const SizedBox(height: PaisaSpacing.cardGap),
          TextField(
            controller: _noteCtrl,
            style: const TextStyle(color: PaisaColors.textPrimary),
            cursorColor: PaisaColors.yellow,
            decoration: _inputDecor('What for? (optional)'),
          ),
          const SizedBox(height: PaisaSpacing.xl),

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
    final repo = ref.read(repositoryProvider);
    await repo.createSplit(FriendSplitsCompanion.insert(
      transactionId: 0, // standalone split, not linked to a transaction
      friendContactId: _selectedFriend!.id,
      amount: amount,
      direction: _direction,
    ));
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
        duration: PaisaMotion.micro,
        padding: const EdgeInsets.all(PaisaSpacing.cardPadding),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.1) : PaisaColors.surface,
          borderRadius: BorderRadius.circular(PaisaRadii.card),
          border: Border.all(
            color: selected ? color : PaisaColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            PhosphorIcon(icon, size: 24, color: selected ? color : PaisaColors.textSecondary),
            const SizedBox(height: PaisaSpacing.sm),
            Text(label, style: TextStyle(color: selected ? color : PaisaColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
            Text(sublabel, style: TextStyle(color: selected ? color.withValues(alpha: 0.7) : PaisaColors.textTertiary, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
