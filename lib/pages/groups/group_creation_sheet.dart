import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finance_buddy_app/design_system/design_system.dart';
import 'package:finance_buddy_app/data/db.dart';
import 'package:finance_buddy_app/providers/providers.dart';
import 'package:finance_buddy_app/widgets/common/error_card.dart';

class GroupCreationSheet extends ConsumerStatefulWidget {
  const GroupCreationSheet({super.key});

  @override
  ConsumerState<GroupCreationSheet> createState() => _GroupCreationSheetState();
}

class _GroupCreationSheetState extends ConsumerState<GroupCreationSheet> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final Set<int> _selectedMembers = {};

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  bool get _canSave =>
      _nameController.text.trim().isNotEmpty && _selectedMembers.length >= 2;

  @override
  Widget build(BuildContext context) {
    final personsAsync = ref.watch(allPersonsProvider);

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Create Group',
              style: AppTextStyles.headingS.copyWith(color: AppColors.black)),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _nameController,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            maxLength: 50,
            style: AppTextStyles.bodyM.copyWith(color: AppColors.black),
            decoration: InputDecoration(
              labelText: 'Group Name',
              labelStyle: AppTextStyles.bodyS.copyWith(color: AppColors.gray500),
              filled: true, fillColor: AppColors.gray100,
              border: OutlineInputBorder(
                  borderRadius: AppRadius.base, borderSide: BorderSide.none),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _descController,
            style: AppTextStyles.bodyM.copyWith(color: AppColors.black),
            decoration: InputDecoration(
              labelText: 'Description (optional)',
              labelStyle: AppTextStyles.bodyS.copyWith(color: AppColors.gray500),
              filled: true, fillColor: AppColors.gray100,
              border: OutlineInputBorder(
                  borderRadius: AppRadius.base, borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('PICK MEMBERS (2+)',
              style: AppTextStyles.labelM.copyWith(color: AppColors.gray500)),
          const SizedBox(height: AppSpacing.xs),
          personsAsync.when(
            data: (persons) {
              if (persons.isEmpty) {
                return Text('Add people first.',
                    style: AppTextStyles.bodyS.copyWith(color: AppColors.gray400));
              }
              return Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: persons.map((p) {
                  final sel = _selectedMembers.contains(p.id);
                  return GestureDetector(
                    onTap: () => setState(() {
                      if (sel) { _selectedMembers.remove(p.id); }
                      else { _selectedMembers.add(p.id); }
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                      decoration: BoxDecoration(
                        color: sel ? AppColors.black : AppColors.gray100,
                        borderRadius: AppRadius.pill),
                      child: Text(p.name,
                          style: AppTextStyles.bodyS.copyWith(
                            color: sel ? AppColors.white : AppColors.gray600,
                            fontWeight: sel ? FontWeight.w600 : FontWeight.w400)),
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const SizedBox(height: 40),
            error: (_, __) => const ErrorCard(),
          ),
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: 'Create Group',
            onTap: _canSave ? _save : () {},
            disabled: !_canSave,
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || _selectedMembers.length < 2) return;

    await HapticFeedback.mediumImpact();
    final repo = ref.read(repositoryProvider);
    final desc = _descController.text.trim();

    final groupId = await repo.createGroup(GroupsCompanion(
      name: drift.Value(name),
      description: drift.Value(desc.isEmpty ? null : desc),
    ));

    for (final pid in _selectedMembers) {
      await repo.addGroupMember(groupId, pid);
    }

    if (mounted) Navigator.pop(context);
  }
}
