import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finance_buddy_app/core/tokens.dart';
import 'package:finance_buddy_app/data/db.dart';
import 'package:finance_buddy_app/providers/providers.dart';
import 'package:finance_buddy_app/widgets/common/neo_pop_button.dart';

/// Bottom sheet for adding a new friend contact.
class FriendCreationSheet extends ConsumerStatefulWidget {
  const FriendCreationSheet({super.key});

  @override
  ConsumerState<FriendCreationSheet> createState() =>
      _FriendCreationSheetState();
}

class _FriendCreationSheetState extends ConsumerState<FriendCreationSheet> {
  final _nameController = TextEditingController();
  final _noteController = TextEditingController();

  static const _palette = [
    '#7B8FA1',
    '#6B8F71',
    '#A0785A',
    '#C9A84C',
    '#8E7AAF',
    '#7A7A7A',
  ];

  /// Keeps a running index so successive adds cycle through colours.
  static int _colourIndex = 0;

  String _nextColour() {
    final colour = _palette[_colourIndex % _palette.length];
    _colourIndex++;
    return colour;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecor(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(color: PaisaColors.textSecondary),
      hintStyle: const TextStyle(color: PaisaColors.textTertiary, fontSize: 13),
      filled: true,
      fillColor: PaisaColors.surface,
      border: const UnderlineInputBorder(
        borderSide: BorderSide(color: PaisaColors.border),
      ),
      enabledBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: PaisaColors.border),
      ),
      focusedBorder: UnderlineInputBorder(
        borderSide:
            BorderSide(color: PaisaColors.accentYellow.withValues(alpha: 0.8)),
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
          const Text('ADD A FRIEND', style: PaisaTextStyles.sectionLabel),
          const SizedBox(height: PaisaSpacing.md),

          // Name field
          TextField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            maxLength: 30,
            style: const TextStyle(
              color: PaisaColors.textPrimary,
              fontSize: 16,
            ),
            decoration: _inputDecor('Name'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: PaisaSpacing.cardGap),

          // Note field
          TextField(
            controller: _noteController,
            style: const TextStyle(
              color: PaisaColors.textPrimary,
              fontSize: 14,
            ),
            decoration: _inputDecor(
              'Note (optional)',
              hint: 'roommate, college friend, etc',
            ),
          ),
          const SizedBox(height: PaisaSpacing.lg),

          // Add Friend button
          NeoPOPButton(
            label: 'Add Friend',
            color: PaisaColors.accentYellow,
            shadowColor: PaisaColors.yellowShadow,
            onTap: _nameController.text.trim().isEmpty ? null : _save,
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    await HapticFeedback.mediumImpact();
    final repo = ref.read(repositoryProvider);
    final note = _noteController.text.trim();

    await repo.createContact(FriendContactsCompanion.insert(
      name: name,
      note: Value(note.isEmpty ? null : note),
      avatarColour: _nextColour(),
    ));

    if (mounted) Navigator.pop(context);
  }
}
