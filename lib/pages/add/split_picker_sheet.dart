import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finance_buddy_app/design_system/design_system.dart';
import 'package:finance_buddy_app/data/db.dart';
import 'package:finance_buddy_app/providers/providers.dart';
import 'package:finance_buddy_app/widgets/common/error_card.dart';

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

  @override
  Widget build(BuildContext context) {
    final personsAsync = ref.watch(allPersonsProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Split with...',
            style: AppTextStyles.headingS.copyWith(color: AppColors.black)),
        const SizedBox(height: AppSpacing.md),
        personsAsync.when(
          data: (persons) {
            if (persons.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Center(
                  child: Text('Add people first from the People tab.',
                      style: AppTextStyles.bodyM
                          .copyWith(color: AppColors.gray500)),
                ),
              );
            }
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
          error: (_, __) => const ErrorCard(),
        ),
        const SizedBox(height: AppSpacing.md),
        AppButton(
          label: 'Split Equally (${_selected.length + 1} ways)',
          onTap: _selected.isEmpty
              ? () {}
              : () {
                  HapticFeedback.mediumImpact();
                  Navigator.pop(
                    context,
                    SplitPickerResult(personIds: _selected.toList()),
                  );
                },
          disabled: _selected.isEmpty,
        ),
      ],
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
    return GestureDetector(
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
    );
  }
}
