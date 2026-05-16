import 'package:flutter_test/flutter_test.dart';
import 'package:finance_buddy_app/core/enums.dart';
import 'package:finance_buddy_app/providers/import_provider.dart';

void main() {
  group('ImportFlowState', () {
    test('initial state has correct defaults', () {
      const state = ImportFlowState();
      expect(state.currentStep, ImportStep.selectBank);
      expect(state.selectedBank, isNull);
      expect(state.selectedFile, isNull);
      expect(state.progress, isNull);
      expect(state.completedBatch, isNull);
      expect(state.uncategorized, isEmpty);
      expect(state.error, isNull);
    });

    test('copyWith updates selected fields', () {
      const state = ImportFlowState();
      final updated = state.copyWith(
        selectedBank: BankType.hdfc,
        currentStep: ImportStep.uploadFile,
      );
      expect(updated.selectedBank, BankType.hdfc);
      expect(updated.currentStep, ImportStep.uploadFile);
      expect(updated.selectedFile, isNull); // Unchanged
    });

    test('copyWith with error clears previous error', () {
      final state = const ImportFlowState().copyWith(error: 'Some error');
      expect(state.error, 'Some error');

      final cleared = state.copyWith(error: null);
      expect(cleared.error, isNull);
    });

    test('copyWith preserves uncategorized list reference', () {
      const state = ImportFlowState();
      final updated = state.copyWith(selectedBank: BankType.sbi);
      expect(identical(updated.uncategorized, state.uncategorized), isTrue);
    });
  });

  group('ImportSource tracking', () {
    test('default source is settings', () {
      const state = ImportFlowState();
      expect(state.source, ImportSource.settings);
    });

    test('setSource updates state', () {
      const state = ImportFlowState();
      final updated = state.copyWith(source: ImportSource.onboarding);
      expect(updated.source, ImportSource.onboarding);

      final fromBanner = updated.copyWith(source: ImportSource.homeBanner);
      expect(fromBanner.source, ImportSource.homeBanner);
    });

    test('reset clears source back to default', () {
      final state = const ImportFlowState().copyWith(
        source: ImportSource.onboarding,
        selectedBank: BankType.hdfc,
      );
      expect(state.source, ImportSource.onboarding);

      // Simulate reset (fresh state)
      const reset = ImportFlowState();
      expect(reset.source, ImportSource.settings);
      expect(reset.selectedBank, isNull);
    });
  });

  group('ImportStep', () {
    test('stepNumber ordering', () {
      expect(ImportStep.selectBank.stepNumber, 0);
      expect(ImportStep.uploadFile.stepNumber, 1);
      expect(ImportStep.processing.stepNumber, 2);
      expect(ImportStep.review.stepNumber, 3);
      expect(ImportStep.summary.stepNumber, 4);
    });

    test('labels are readable', () {
      expect(ImportStep.selectBank.label, 'Select Bank');
      expect(ImportStep.processing.label, 'Processing');
    });
  });
}
