import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finance_buddy_app/design_system/design_system.dart';
import 'package:finance_buddy_app/data/db.dart';
import 'package:finance_buddy_app/providers/database_providers.dart';

const _tagOptions = ['friend', 'family', 'colleague', 'other'];

class PersonEditSheet extends ConsumerStatefulWidget {
  const PersonEditSheet({super.key, required this.person});
  final Person person;

  @override
  ConsumerState<PersonEditSheet> createState() => _PersonEditSheetState();
}

class _PersonEditSheetState extends ConsumerState<PersonEditSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _noteController;
  late String _selectedTag;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.person.name);
    _noteController = TextEditingController(text: widget.person.note ?? '');
    _selectedTag = widget.person.tag ?? 'other';
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
          Text('Edit Person',
              style:
                  AppTextStyles.headingS.copyWith(color: AppColors.black)),
          const SizedBox(height: AppSpacing.lg),

          TextField(
            controller: _nameController,
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
            label: 'Save Changes',
            onTap: _canSave ? _save : () {},
            disabled: !_canSave,
          ),
          const SizedBox(height: AppSpacing.sm),

          GestureDetector(
            onTap: _confirmDelete,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              alignment: Alignment.center,
              child: Text('Delete Person',
                  style: AppTextStyles.bodyM.copyWith(
                      color: AppColors.red, fontWeight: FontWeight.w500)),
            ),
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

    await repo.updatePerson(
      widget.person.id,
      PersonsCompanion(
        name: drift.Value(name),
        tag: drift.Value(_selectedTag),
        note: drift.Value(note.isEmpty ? null : note),
      ),
    );

    if (mounted) Navigator.pop(context);
  }

  Future<void> _confirmDelete() async {
    final repo = ref.read(repositoryProvider);
    final balance = await repo.getPersonBalance(widget.person.id);

    if (!mounted) return;

    if (balance != 0) {
      showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Outstanding balance'),
          content: Text(
            '${widget.person.name} has an unsettled balance. '
            'Settle up before deleting.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete person?'),
        content: Text('Remove ${widget.person.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await repo.deletePerson(widget.person.id);
              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Delete',
                style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
  }
}
