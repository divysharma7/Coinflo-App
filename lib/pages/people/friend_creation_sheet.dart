import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finance_buddy_app/design_system/design_system.dart';
import 'package:finance_buddy_app/data/db.dart';
import 'package:finance_buddy_app/providers/providers.dart';

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
    '#7B8FA1', '#6B8F71', '#A0785A', '#C9A84C', '#8E7AAF', '#7A7A7A',
  ];
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

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Add a Friend',
              style: AppTextStyles.headingS.copyWith(color: AppColors.black)),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            maxLength: 30,
            style: AppTextStyles.bodyM.copyWith(color: AppColors.black),
            decoration: InputDecoration(
              labelText: 'Name',
              labelStyle: AppTextStyles.bodyS.copyWith(color: AppColors.gray400),
              filled: true,
              fillColor: AppColors.gray100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _noteController,
            style: AppTextStyles.bodyM.copyWith(color: AppColors.black),
            decoration: InputDecoration(
              labelText: 'Note (optional)',
              hintText: 'roommate, college friend, etc',
              labelStyle: AppTextStyles.bodyS.copyWith(color: AppColors.gray400),
              hintStyle: AppTextStyles.bodyS.copyWith(color: AppColors.gray300),
              filled: true,
              fillColor: AppColors.gray100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: 'Add Friend',
            onTap: _nameController.text.trim().isEmpty ? () {} : _save,
            disabled: _nameController.text.trim().isEmpty,
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
