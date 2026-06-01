import 'package:finance_buddy_app/data/repositories/split_repository.dart';
import 'package:finance_buddy_app/services/split/split_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

/// Unit tests for [SplitCalculator] — CoinFlo's pure split-math engine.
///
/// Sign / convention notes (verified against the source + call sites):
///  * A [SplitEntry] with `personId == null` represents the USER's own share.
///  * `equal(total, personIds)` divides among `personIds.length + 1` people
///    (the +1 is the user). The USER absorbs any paise remainder, and the
///    user entry is always emitted FIRST.
///  * Expenses are stored as negative amounts elsewhere in the app, but the
///    calculator itself always works with the POSITIVE magnitude of the bill;
///    sign handling happens at the transaction layer, not here.
///  * `exact`, `percentage`, and `byShares` accept a `Map<int?, …>` keyed by
///    person id where the `null` key is again the user.
///
/// The settlement-direction (`paid_to` / `received_from`) and the running
/// balance (`positive = they owe me`, `negative = I owe them`) live in SQL in
/// `LocalSplitRepository`, not in this pure class, so they are out of scope for
/// these tests. The invariant this suite guards is the one the calculator IS
/// responsible for: **no money is created or lost** — every method's shares sum
/// back to the exact original total.

/// Sums share amounts to 2-decimal (paise) precision so floating point dust
/// does not produce false negatives.
double _sumShares(List<SplitEntry> splits) {
  final total = splits.fold<double>(0, (acc, s) => acc + s.shareAmount);
  return double.parse(total.toStringAsFixed(2));
}

/// Convenience: the single user (`personId == null`) entry.
SplitEntry _userShare(List<SplitEntry> splits) =>
    splits.firstWhere((s) => s.personId == null);

void main() {
  group('SplitMethod enum', () {
    test('exposes exactly the four supported strategies', () {
      // Arrange / Act
      const values = SplitMethod.values;

      // Assert
      expect(values, <SplitMethod>[
        SplitMethod.equal,
        SplitMethod.exact,
        SplitMethod.percentage,
        SplitMethod.shares,
      ]);
    });
  });

  group('SplitCalculator.equal — even division', () {
    test('splits a clean total between the user and one person', () {
      // Arrange
      const total = 100.0;
      final personIds = [1];

      // Act
      final splits = SplitCalculator.equal(total, personIds);

      // Assert
      expect(splits, hasLength(2));
      expect(_userShare(splits).shareAmount, 50.0);
      expect(splits[1].personId, 1);
      expect(splits[1].shareAmount, 50.0);
      expect(_sumShares(splits), total);
    });

    test('splits a clean total across the user and three people', () {
      // Arrange
      const total = 400.0;
      final personIds = [1, 2, 3];

      // Act
      final splits = SplitCalculator.equal(total, personIds);

      // Assert — 4 ways, 100 each
      expect(splits, hasLength(4));
      for (final s in splits) {
        expect(s.shareAmount, 100.0);
      }
      expect(_sumShares(splits), total);
    });

    test('emits the user share first, then people in input order', () {
      // Arrange
      const total = 300.0;
      final personIds = [7, 9];

      // Act
      final splits = SplitCalculator.equal(total, personIds);

      // Assert
      expect(splits[0].personId, isNull, reason: 'user entry must be first');
      expect(splits[1].personId, 7);
      expect(splits[2].personId, 9);
    });
  });

  group('SplitCalculator.equal — paise remainder distribution', () {
    test('user absorbs the remainder when total does not divide evenly', () {
      // Arrange — 100 / 3 = 33.33 each, 0.01 remainder to the user.
      const total = 100.0;
      final personIds = [1, 2]; // 3 people incl. user

      // Act
      final splits = SplitCalculator.equal(total, personIds);

      // Assert
      expect(_userShare(splits).shareAmount, closeTo(33.34, 1e-9));
      expect(splits[1].shareAmount, closeTo(33.33, 1e-9));
      expect(splits[2].shareAmount, closeTo(33.33, 1e-9));
      expect(_sumShares(splits), total,
          reason: 'paise must reconcile back to the exact bill');
    });

    test('reconciles a tricky 7-way split with rounding', () {
      // Arrange — 10.00 / 7 → 1.42 base, user takes the leftover.
      const total = 10.0;
      final personIds = [1, 2, 3, 4, 5, 6]; // 7 people incl. user

      // Act
      final splits = SplitCalculator.equal(total, personIds);

      // Assert
      expect(splits, hasLength(7));
      // 6 people at the base amount.
      final peopleShares =
          splits.where((s) => s.personId != null).map((s) => s.shareAmount);
      for (final share in peopleShares) {
        expect(share, closeTo(1.42, 1e-9));
      }
      // User absorbs the 0.06 remainder: 10 - (1.42 * 7) = 0.06 + 1.42 = 1.48.
      expect(_userShare(splits).shareAmount, closeTo(1.48, 1e-9));
      expect(_sumShares(splits), total);
    });

    test('handles a recurring-decimal total (33.33 ÷ 2) without losing paise',
        () {
      // Arrange
      const total = 33.33;
      final personIds = [1]; // user + 1

      // Act
      final splits = SplitCalculator.equal(total, personIds);

      // Assert
      expect(splits[1].shareAmount, closeTo(16.66, 1e-9));
      expect(_userShare(splits).shareAmount, closeTo(16.67, 1e-9));
      expect(_sumShares(splits), total);
    });
  });

  group('SplitCalculator.equal — edge cases', () {
    test('you-only split (no other people) assigns the whole total to user',
        () {
      // Arrange
      const total = 250.0;
      final personIds = <int>[];

      // Act
      final splits = SplitCalculator.equal(total, personIds);

      // Assert
      expect(splits, hasLength(1));
      expect(splits.single.personId, isNull);
      expect(splits.single.shareAmount, 250.0);
      expect(_sumShares(splits), total);
    });

    test('zero total produces zero shares for everyone', () {
      // Arrange
      const total = 0.0;
      final personIds = [1, 2];

      // Act
      final splits = SplitCalculator.equal(total, personIds);

      // Assert
      expect(splits, hasLength(3));
      for (final s in splits) {
        expect(s.shareAmount, 0.0);
      }
      expect(_sumShares(splits), 0.0);
    });

    test('small total of one paise lands entirely on the user', () {
      // Arrange — 0.01 / 2: base rounds to 0.00, user keeps the 0.01.
      const total = 0.01;
      final personIds = [1];

      // Act
      final splits = SplitCalculator.equal(total, personIds);

      // Assert
      expect(splits[1].shareAmount, closeTo(0.0, 1e-9));
      expect(_userShare(splits).shareAmount, closeTo(0.01, 1e-9));
      expect(_sumShares(splits), total);
    });
  });

  group('SplitCalculator.exact', () {
    test('passes through explicit amounts unchanged for user and people', () {
      // Arrange
      final amounts = <int?, double>{null: 40.0, 1: 35.0, 2: 25.0};

      // Act
      final splits = SplitCalculator.exact(amounts);

      // Assert
      expect(splits, hasLength(3));
      expect(_userShare(splits).shareAmount, 40.0);
      expect(splits.firstWhere((s) => s.personId == 1).shareAmount, 35.0);
      expect(splits.firstWhere((s) => s.personId == 2).shareAmount, 25.0);
      expect(_sumShares(splits), 100.0);
    });

    test('supports an unequal single-person split', () {
      // Arrange — user paid 80, friend owes 20 of a 100 bill.
      final amounts = <int?, double>{null: 80.0, 5: 20.0};

      // Act
      final splits = SplitCalculator.exact(amounts);

      // Assert
      expect(splits, hasLength(2));
      expect(_userShare(splits).shareAmount, 80.0);
      expect(splits.firstWhere((s) => s.personId == 5).shareAmount, 20.0);
      expect(_sumShares(splits), 100.0);
    });

    test('handles a you-only exact split', () {
      // Arrange
      final amounts = <int?, double>{null: 99.99};

      // Act
      final splits = SplitCalculator.exact(amounts);

      // Assert
      expect(splits.single.personId, isNull);
      expect(splits.single.shareAmount, 99.99);
    });

    test('returns an empty list for an empty input map', () {
      // Arrange
      final amounts = <int?, double>{};

      // Act
      final splits = SplitCalculator.exact(amounts);

      // Assert
      expect(splits, isEmpty);
    });
  });

  group('SplitCalculator.percentage', () {
    test('splits a total by clean percentages summing to the original', () {
      // Arrange
      const total = 200.0;
      final percentages = <int?, double>{null: 50.0, 1: 50.0};

      // Act
      final splits = SplitCalculator.percentage(total, percentages);

      // Assert
      expect(splits, hasLength(2));
      expect(_userShare(splits).shareAmount, closeTo(100.0, 1e-9));
      expect(splits.firstWhere((s) => s.personId == 1).shareAmount,
          closeTo(100.0, 1e-9));
      expect(_sumShares(splits), total);
    });

    test('applies unequal percentages across three participants', () {
      // Arrange
      const total = 1000.0;
      final percentages = <int?, double>{null: 50.0, 1: 30.0, 2: 20.0};

      // Act
      final splits = SplitCalculator.percentage(total, percentages);

      // Assert
      expect(_userShare(splits).shareAmount, closeTo(500.0, 1e-9));
      expect(splits.firstWhere((s) => s.personId == 1).shareAmount,
          closeTo(300.0, 1e-9));
      expect(splits.firstWhere((s) => s.personId == 2).shareAmount,
          closeTo(200.0, 1e-9));
      expect(_sumShares(splits), total);
    });

    test(
        'last participant absorbs the rounding so paise reconcile exactly '
        '(thirds of 100)', () {
      // Arrange — 33.33% each rounds to 33.33; the last entry takes the rest.
      const total = 100.0;
      final percentages = <int?, double>{
        null: 33.33,
        1: 33.33,
        2: 33.34,
      };

      // Act
      final splits = SplitCalculator.percentage(total, percentages);

      // Assert
      expect(_userShare(splits).shareAmount, closeTo(33.33, 1e-9));
      expect(splits.firstWhere((s) => s.personId == 1).shareAmount,
          closeTo(33.33, 1e-9));
      // Last entry = total - allocated, mopping up the residue.
      expect(splits.firstWhere((s) => s.personId == 2).shareAmount,
          closeTo(33.34, 1e-9));
      expect(_sumShares(splits), total,
          reason: 'no money created or lost across percentage rounding');
    });

    test('100% to the user yields a you-only split', () {
      // Arrange
      const total = 75.0;
      final percentages = <int?, double>{null: 100.0};

      // Act
      final splits = SplitCalculator.percentage(total, percentages);

      // Assert
      expect(splits.single.personId, isNull);
      expect(splits.single.shareAmount, closeTo(75.0, 1e-9));
      expect(_sumShares(splits), total);
    });

    test('zero total distributes zero to every percentage bucket', () {
      // Arrange
      const total = 0.0;
      final percentages = <int?, double>{null: 60.0, 1: 40.0};

      // Act
      final splits = SplitCalculator.percentage(total, percentages);

      // Assert
      for (final s in splits) {
        expect(s.shareAmount, closeTo(0.0, 1e-9));
      }
      expect(_sumShares(splits), 0.0);
    });
  });

  group('SplitCalculator.byShares', () {
    test('divides by equal share units like a plain equal split', () {
      // Arrange — 1:1 shares of 100 between user and one person.
      const total = 100.0;
      final shareUnits = <int?, int>{null: 1, 1: 1};

      // Act
      final splits = SplitCalculator.byShares(total, shareUnits);

      // Assert
      expect(_userShare(splits).shareAmount, closeTo(50.0, 1e-9));
      expect(splits.firstWhere((s) => s.personId == 1).shareAmount,
          closeTo(50.0, 1e-9));
      expect(_sumShares(splits), total);
    });

    test('weights shares unequally (2:1) and reconciles to the total', () {
      // Arrange — user pays double the friend's portion of a 90 bill.
      const total = 90.0;
      final shareUnits = <int?, int>{null: 2, 1: 1};

      // Act
      final splits = SplitCalculator.byShares(total, shareUnits);

      // Assert
      expect(_userShare(splits).shareAmount, closeTo(60.0, 1e-9));
      // Last entry absorbs the remainder: 90 - 60 = 30.
      expect(splits.firstWhere((s) => s.personId == 1).shareAmount,
          closeTo(30.0, 1e-9));
      expect(_sumShares(splits), total);
    });

    test('distributes 3:2:1 weighting across three participants', () {
      // Arrange — total 120, shares sum 6 → units of 20.
      const total = 120.0;
      final shareUnits = <int?, int>{null: 3, 1: 2, 2: 1};

      // Act
      final splits = SplitCalculator.byShares(total, shareUnits);

      // Assert
      expect(_userShare(splits).shareAmount, closeTo(60.0, 1e-9));
      expect(splits.firstWhere((s) => s.personId == 1).shareAmount,
          closeTo(40.0, 1e-9));
      // Last entry = total - allocated.
      expect(splits.firstWhere((s) => s.personId == 2).shareAmount,
          closeTo(20.0, 1e-9));
      expect(_sumShares(splits), total);
    });

    test('last entry absorbs rounding for an indivisible share split', () {
      // Arrange — 10 / 3 by 1:1:1 shares; first two round, last mops up.
      const total = 10.0;
      final shareUnits = <int?, int>{null: 1, 1: 1, 2: 1};

      // Act
      final splits = SplitCalculator.byShares(total, shareUnits);

      // Assert
      expect(_userShare(splits).shareAmount, closeTo(3.33, 1e-9));
      expect(splits.firstWhere((s) => s.personId == 1).shareAmount,
          closeTo(3.33, 1e-9));
      // 10 - 3.33 - 3.33 = 3.34 lands on the last entry.
      expect(splits.firstWhere((s) => s.personId == 2).shareAmount,
          closeTo(3.34, 1e-9));
      expect(_sumShares(splits), total,
          reason: 'share-based rounding must not create or lose money');
    });

    test('a single bucket holding all shares receives the entire total', () {
      // Arrange
      const total = 42.0;
      final shareUnits = <int?, int>{null: 5};

      // Act
      final splits = SplitCalculator.byShares(total, shareUnits);

      // Assert
      expect(splits.single.personId, isNull);
      expect(splits.single.shareAmount, closeTo(42.0, 1e-9));
      expect(_sumShares(splits), total);
    });

    test('zero total yields zero for every share bucket', () {
      // Arrange
      const total = 0.0;
      final shareUnits = <int?, int>{null: 1, 1: 3};

      // Act
      final splits = SplitCalculator.byShares(total, shareUnits);

      // Assert
      for (final s in splits) {
        expect(s.shareAmount, closeTo(0.0, 1e-9));
      }
      expect(_sumShares(splits), 0.0);
    });
  });

  group('Money-conservation invariant across all methods', () {
    test('equal split never creates or loses money for varied totals', () {
      // Arrange
      const totals = [0.01, 9.99, 33.33, 100.0, 1234.56, 99999.99];
      final personIds = [1, 2, 3];

      for (final total in totals) {
        // Act
        final splits = SplitCalculator.equal(total, personIds);

        // Assert
        expect(_sumShares(splits), double.parse(total.toStringAsFixed(2)),
            reason: 'equal failed to reconcile for total=$total');
      }
    });

    test('percentage split reconciles for varied totals and weightings', () {
      // Arrange
      const totals = [0.03, 50.0, 100.0, 777.77, 100000.0];
      final percentages = <int?, double>{null: 33.33, 1: 33.33, 2: 33.34};

      for (final total in totals) {
        // Act
        final splits = SplitCalculator.percentage(total, percentages);

        // Assert
        expect(_sumShares(splits), double.parse(total.toStringAsFixed(2)),
            reason: 'percentage failed to reconcile for total=$total');
      }
    });

    test('byShares split reconciles for varied totals and weightings', () {
      // Arrange
      const totals = [0.05, 7.0, 100.0, 999.99, 250000.0];
      final shareUnits = <int?, int>{null: 1, 1: 1, 2: 1};

      for (final total in totals) {
        // Act
        final splits = SplitCalculator.byShares(total, shareUnits);

        // Assert
        expect(_sumShares(splits), double.parse(total.toStringAsFixed(2)),
            reason: 'byShares failed to reconcile for total=$total');
      }
    });
  });
}
