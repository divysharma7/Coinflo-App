import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:finance_buddy_app/design_system/design_system.dart';
import 'package:finance_buddy_app/data/db.dart';
import 'package:finance_buddy_app/providers/providers.dart';
import 'package:finance_buddy_app/pages/people/person_creation_sheet.dart';
import 'package:finance_buddy_app/widgets/common/error_card.dart';
import 'package:finance_buddy_app/widgets/common/spendler_bottom_sheet.dart';

class SplitPickerResult {
  final List<int> personIds;
  const SplitPickerResult({required this.personIds});
}

class SplitPickerSheet extends ConsumerStatefulWidget {
  const SplitPickerSheet({super.key});

  @override
  ConsumerState<SplitPickerSheet> createState() => _SplitPickerSheetState();
}

class _SplitPickerSheetState extends ConsumerState<SplitPickerSheet> {
  final Set<int> _selected = {};

  /// Opens the Add Person sheet inline so an empty People list is no longer a
  /// dead end. [allPersonsProvider] is a stream, so the list below rebuilds with
  /// the freshly-created person automatically once it is saved.
  Future<void> _addPerson() async {
    await showSpendlerSheet<void>(
      context: context,
      builder: (_) => const PersonCreationSheet(),
    );
  }

  void _confirm() {
    if (_selected.isEmpty) return;
    HapticFeedback.mediumImpact();
    Navigator.pop(
      context,
      SplitPickerResult(personIds: _selected.toList()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final personsAsync = ref.watch(allPersonsProvider);
    final hasPeople = personsAsync.valueOrNull?.isNotEmpty ?? false;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Split with...',
            style: AppTextStyles.headingS.copyWith(color: AppColors.black)),
        const SizedBox(height: AppSpacing.md),
        personsAsync.when(
          data: (persons) {
            if (persons.isEmpty) return _emptyState();
            return ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: persons.length,
                itemBuilder: (_, i) {
                  final p = persons[i];
                  final selected = _selected.contains(p.id);
                  return _PersonTile(
                    person: p,
                    selected: selected,
                    onTap: () => setState(() {
                      if (selected) {
                        _selected.remove(p.id);
                      } else {
                        _selected.add(p.id);
                      }
                    }),
                  );
                },
              ),
            );
          },
          loading: () => const SizedBox(height: 100),
          error: (_, _) => const ErrorCard(),
        ),
        const SizedBox(height: AppSpacing.md),
        // Only show the confirm button once there is someone to split with —
        // an empty list shows its own "Add a person" action instead.
        if (hasPeople)
          AppButton(
            label: 'Split Equally (${_selected.length + 1} ways)',
            onTap: _confirm,
            disabled: _selected.isEmpty,
          ),
      ],
    );
  }

  // ── Empty state — actionable, adds a person inline ───────────
  Widget _emptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: AppColors.gray100,
              shape: BoxShape.circle,
            ),
            child: Icon(PhosphorIcons.users(),
                size: 26, color: AppColors.gray500),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No people yet',
            style: AppTextStyles.bodyM.copyWith(
              color: AppColors.black,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Add someone to split this expense with.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyS.copyWith(color: AppColors.gray500),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: 'Add a person',
            variant: AppButtonVariant.ghost,
            onTap: _addPerson,
          ),
        ],
      ),
    );
  }
}

class _PersonTile extends StatelessWidget {
  const _PersonTile({
    required this.person,
    required this.selected,
    required this.onTap,
  });
  final Person person;
  final bool selected;
  final VoidCallback onTap;

  Color _avatarColor(String hex) {
    try {
      return Color(int.parse('FF${hex.replaceFirst('#', '')}', radix: 16));
    } on FormatException {
      return AppColors.gray500;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _avatarColor(person.avatarColor);
    return Semantics(
      button: true,
      selected: selected,
      label: person.name,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.xs),
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.black.withValues(alpha: 0.05)
                : AppColors.white,
            borderRadius: AppRadius.base,
            border: Border.all(
                color: selected ? AppColors.black : AppColors.gray200),
          ),
          child: Row(
            children: [
              Icon(
                selected ? Icons.check_circle : Icons.circle_outlined,
                color: selected ? AppColors.black : AppColors.gray300,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: c.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  person.name.isNotEmpty ? person.name[0].toUpperCase() : '?',
                  style: TextStyle(
                      color: c, fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(person.name,
                    style: AppTextStyles.bodyM.copyWith(
                        color: AppColors.black,
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.w400)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
