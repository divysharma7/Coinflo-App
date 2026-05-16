import 'package:flutter_test/flutter_test.dart';
import 'package:finance_buddy_app/core/enums.dart';
import 'package:finance_buddy_app/services/categorization/rule_engine.dart';

// TODO(v2): Audit all regex patterns for word-order assumptions.
// The salary pattern needed \bsalary\b added because real bank descriptions
// have "NEFT CR...SALARY JAN" where CR precedes SALARY. Other patterns
// (EMI, Bills, Health) may have similar gaps when CR/DR indicators appear
// before the keyword. Test each pattern against descriptions from all 5 bank
// fixtures with direction indicators in unexpected positions.

void main() {
  late RuleEngine engine;

  setUp(() {
    engine = RuleEngine();
  });

  group('Salary/Income patterns', () {
    test('matches "salary cr"', () {
      final result = engine.match('neft cr acme corp salary cr jan 2026');
      expect(result, isNotNull);
      expect(result!.category, 'income');
      expect(result.confidence, 0.95);
    });

    test('matches "payroll"', () {
      final result = engine.match('payroll credit from employer');
      expect(result, isNotNull);
      expect(result!.category, 'income');
    });

    test('matches "monthly sal"', () {
      final result = engine.match('monthly sal credit');
      expect(result, isNotNull);
    });
  });

  group('ATM patterns', () {
    test('matches "atm wdl"', () {
      final result = engine.match('atm wdl hdfc andheri');
      expect(result, isNotNull);
      expect(result!.category, 'cash');
      expect(result.confidence, 1.0);
    });

    test('matches "atm-withdrawal"', () {
      final result = engine.match('atm-withdrawal sbi branch');
      expect(result, isNotNull);
    });

    test('matches "atm cwd"', () {
      final result = engine.match('atm cwd 5000');
      expect(result, isNotNull);
    });
  });

  group('EMI patterns', () {
    test('matches "emi"', () {
      final result = engine.match('emi loan hdfc home loan');
      expect(result, isNotNull);
      expect(result!.category, 'billsAndUtilities');
      expect(result.confidence, 0.9);
    });

    test('matches "home loan"', () {
      final result = engine.match('home loan emi debit');
      expect(result, isNotNull);
    });

    test('matches "car loan"', () {
      final result = engine.match('car loan payment');
      expect(result, isNotNull);
    });
  });

  group('Bills/Utilities patterns', () {
    test('matches "electricity"', () {
      final result = engine.match('bescom electricity bill');
      expect(result, isNotNull);
      expect(result!.category, 'billsAndUtilities');
      expect(result.confidence, 0.95);
    });

    test('matches "tata power"', () {
      final result = engine.match('tata power bill payment');
      expect(result, isNotNull);
    });

    test('matches "bbps"', () {
      final result = engine.match('bbps bill payment');
      expect(result, isNotNull);
    });

    test('matches "water bill"', () {
      final result = engine.match('bwssb water bill');
      expect(result, isNotNull);
    });
  });

  group('Education patterns', () {
    test('matches "school fee"', () {
      final result = engine.match('school fee payment');
      expect(result, isNotNull);
      expect(result!.category, 'education');
      expect(result.confidence, 0.9);
    });

    test('matches "byjus"', () {
      final result = engine.match('byjus learning app');
      expect(result, isNotNull);
    });

    test('matches "unacademy"', () {
      final result = engine.match('unacademy subscription');
      expect(result, isNotNull);
    });
  });

  group('Health patterns', () {
    test('matches "apollo"', () {
      final result = engine.match('apollo pharmacy purchase');
      expect(result, isNotNull);
      expect(result!.category, 'healthAndWellness');
    });

    test('matches "1mg"', () {
      final result = engine.match('1mg medicine order');
      expect(result, isNotNull);
    });

    test('matches "hospital"', () {
      final result = engine.match('fortis hospital bill');
      expect(result, isNotNull);
    });
  });

  group('Insurance patterns', () {
    test('matches "lic"', () {
      final result = engine.match('lic premium payment');
      expect(result, isNotNull);
      expect(result!.category, 'insurance');
    });

    test('matches "policybazaar"', () {
      final result = engine.match('policybazaar renewal');
      expect(result, isNotNull);
    });
  });

  group('Investment patterns', () {
    test('matches "zerodha"', () {
      final result = engine.match('zerodha coin mf order');
      expect(result, isNotNull);
      expect(result!.category, 'investments');
      expect(result.confidence, 0.95);
    });

    test('matches "groww"', () {
      final result = engine.match('groww investment');
      expect(result, isNotNull);
    });

    test('matches "sip"', () {
      final result = engine.match('sip debit mutual fund');
      expect(result, isNotNull);
    });
  });

  group('No match', () {
    test('random text returns null', () {
      final result = engine.match('random purchase at store');
      expect(result, isNull);
    });

    test('empty string returns null', () {
      final result = engine.match('');
      expect(result, isNull);
    });
  });

  group('Source is always rule', () {
    test('all matches have source = rule', () {
      final descriptions = [
        'salary cr',
        'atm wdl',
        'emi loan',
        'electricity bill',
        'school fee',
        'apollo pharmacy',
        'lic premium',
        'zerodha',
      ];
      for (final desc in descriptions) {
        final result = engine.match(desc);
        expect(result?.source, CategorizationSource.rule, reason: 'Failed for: $desc');
      }
    });
  });
}
