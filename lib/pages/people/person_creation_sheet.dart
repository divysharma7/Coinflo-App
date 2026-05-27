import 'dart:math';

import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finance_buddy_app/design_system/design_system.dart';
import 'package:finance_buddy_app/data/db.dart';
import 'package:finance_buddy_app/providers/database_providers.dart';

const _tagOptions = ['friend', 'family', 'colleague', 'other'];
const _avatarColors = [
  '#EF4444', '#F97316', '#F59E0B', '#22C55E',
  '#14B8A6', '#3B82F6', '#6366F1', '#8B5CF6',
  '#EC4899', '#64748B',
];

class PersonCreationSheet extends ConsumerStatefulWidget {
  const PersonCreationSheet({super.key});

  @override
  ConsumerState<PersonCreationSheet> createState() =>
      _PersonCreationSheetState();
}

class _PersonCreationSheetState extends ConsumerState<PersonCreationSheet> {
  final _nameController = TextEditingController();
  final _noteController = TextEditingController();
  String _selectedTag = 'friend';
  late String _avatarColor;

  @override
  void initState() {
    super.initState();
    _avatarColor = _avatarColors[Random().nextInt(_avatarColors.length)];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  bool get _canSave => _nameController.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Add Person',
              style:
                  AppTextStyles.headingS.copyWith(color: AppColors.black)),
          const SizedBox(height: AppSpacing.lg),

          // Name
          TextField(
            controller: _nameController,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            maxLength: 50,
            style: AppTextStyles.bodyM.copyWith(color: AppColors.black),
            decoration: InputDecoration(
              labelText: 'Name',
              labelStyle:
                  AppTextStyles.bodyS.copyWith(color: AppColors.gray500),
              filled: true,
              fillColor: AppColors.gray100,
              border: OutlineInputBorder(
                borderRadius: AppRadius.base,
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.md),

          // Tag chips
          Text('Tag',
              style:
                  AppTextStyles.labelM.copyWith(color: AppColors.gray500)),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            children: _tagOptions.map((tag) {
              final selected = tag == _selectedTag;
              return GestureDetector(
                onTap: () => setState(() => _selectedTag = tag),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.black : AppColors.gray100,
                    borderRadius: AppRadius.pill,
                  ),
                  child: Text(
                    tag[0].toUpperCase() + tag.substring(1),
                    style: AppTextStyles.bodyS.copyWith(
                      color: selected ? AppColors.white : AppColors.gray600,
                      fontWeight:
                          selected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.md),

          // Note
          TextField(
            controller: _noteController,
            style: AppTextStyles.bodyM.copyWith(color: AppColors.black),
            decoration: InputDecoration(
              labelText: 'Note (optional)',
              hintText: 'roommate, gym buddy, etc',
              labelStyle:
                  AppTextStyles.bodyS.copyWith(color: AppColors.gray500),
              hintStyle:
                  AppTextStyles.bodyS.copyWith(color: AppColors.gray300),
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
            label: 'Add Person',
            onTap: _canSave ? _save : () {},
            disabled: !_canSave,
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

    await repo.createPerson(PersonsCompanion(
      name: drift.Value(name),
      tag: drift.Value(_selectedTag),
      avatarColor: drift.Value(_avatarColor),
      note: drift.Value(note.isEmpty ? null : note),
    ));

    if (mounted) Navigator.pop(context);
  }
}
