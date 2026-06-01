---
name: tdd-workflow
description: Use this skill when writing new features, fixing bugs, or refactoring code. Enforces test-driven development with 80%+ coverage including unit, integration, and E2E tests.
origin: ECC
---

# Test-Driven Development Workflow

This skill ensures all code development follows TDD principles with comprehensive test coverage.

## When to Activate

- Writing new features or functionality
- Fixing bugs or issues
- Refactoring existing code
- Adding API endpoints
- Creating new components

## Core Principles

### 1. Tests BEFORE Code
ALWAYS write tests first, then implement code to make tests pass.

### 2. Coverage Requirements
- Minimum 80% coverage (unit + integration + E2E)
- All edge cases covered
- Error scenarios tested
- Boundary conditions verified

### 3. Test Types

#### Unit Tests
- Individual functions and utilities
- Component logic
- Pure functions
- Helpers and utilities

#### Integration Tests
- API endpoints
- Database operations
- Service interactions
- External API calls

#### Integration/E2E (integration_test / patrol)
- Critical user flows
- Complete workflows
- On-device automation
- UI interactions
<!-- Flutter-ized today: replaced "E2E Tests (Playwright)" subsection heading and bullets -->

### 4. Git Checkpoints
- If the repository is under Git, create a checkpoint commit after each TDD stage
- Do not squash or rewrite these checkpoint commits until the workflow is complete
- Each checkpoint commit message must describe the stage and the exact evidence captured
- Count only commits created on the current active branch for the current task
- Do not treat commits from other branches, earlier unrelated work, or distant branch history as valid checkpoint evidence
- Before treating a checkpoint as satisfied, verify that the commit is reachable from the current `HEAD` on the active branch and belongs to the current task sequence
- The preferred compact workflow is:
  - one commit for failing test added and RED validated
  - one commit for minimal fix applied and GREEN validated
  - one optional commit for refactor complete
- Separate evidence-only commits are not required if the test commit clearly corresponds to RED and the fix commit clearly corresponds to GREEN

## TDD Workflow Steps

### Step 1: Write User Journeys
```
As a [role], I want to [action], so that [benefit]

Example:
As a user, I want to search for markets semantically,
so that I can find relevant markets even without exact keywords.
```

### Step 2: Generate Test Cases
For each user journey, create comprehensive test cases:

```dart
group('Semantic Search', () {
  test('returns relevant markets for query', () async {
    // Test implementation
  });

  test('handles empty query gracefully', () async {
    // Test edge case
  });

  test('falls back to substring search when DB unavailable', () async {
    // Test fallback behavior
  });

  test('sorts results by similarity score', () async {
    // Test sorting logic
  });
});
```
<!-- Flutter-ized today: replaced TypeScript describe/it with Dart group()/test() from package:test -->

### Step 3: Run Tests (They Should Fail)
```bash
flutter test
# Tests should fail - we haven't implemented yet
```
<!-- Flutter-ized today: replaced npm test with flutter test -->

This step is mandatory and is the RED gate for all production changes.

Before modifying business logic or other production code, you must verify a valid RED state via one of these paths:
- Runtime RED:
  - The relevant test target compiles successfully
  - The new or changed test is actually executed
  - The result is RED
- Compile-time RED:
  - The new test newly instantiates, references, or exercises the buggy code path
  - The compile failure is itself the intended RED signal
- In either case, the failure is caused by the intended business-logic bug, undefined behavior, or missing implementation
- The failure is not caused only by unrelated syntax errors, broken test setup, missing dependencies, or unrelated regressions

A test that was only written but not compiled and executed does not count as RED.

Do not edit production code until this RED state is confirmed.

If the repository is under Git, create a checkpoint commit immediately after this stage is validated.
Recommended commit message format:
- `test: add reproducer for <feature or bug>`
- This commit may also serve as the RED validation checkpoint if the reproducer was compiled and executed and failed for the intended reason
- Verify that this checkpoint commit is on the current active branch before continuing

### Step 4: Implement Code
Write minimal code to make tests pass:

```dart
// Implementation guided by tests
Future<List<Market>> searchMarkets(String query) async {
  // Implementation here
}
```
<!-- Flutter-ized today: replaced TypeScript async function stub with Dart equivalent -->

If the repository is under Git, stage the minimal fix now but defer the checkpoint commit until GREEN is validated in Step 5.

### Step 5: Run Tests Again
```bash
flutter test
# Tests should now pass
```
<!-- Flutter-ized today: replaced npm test with flutter test -->

Rerun the same relevant test target after the fix and confirm the previously failing test is now GREEN.

Only after a valid GREEN result may you proceed to refactor.

If the repository is under Git, create a checkpoint commit immediately after GREEN is validated.
Recommended commit message format:
- `fix: <feature or bug>`
- The fix commit may also serve as the GREEN validation checkpoint if the same relevant test target was rerun and passed
- Verify that this checkpoint commit is on the current active branch before continuing

### Step 6: Refactor
Improve code quality while keeping tests green:
- Remove duplication
- Improve naming
- Optimize performance
- Enhance readability

If the repository is under Git, create a checkpoint commit immediately after refactoring is complete and tests remain green.
Recommended commit message format:
- `refactor: clean up after <feature or bug> implementation`
- Verify that this checkpoint commit is on the current active branch before considering the TDD cycle complete

### Step 7: Verify Coverage
```bash
flutter test --coverage
# Verify 80%+ coverage achieved
```
<!-- Flutter-ized today: replaced npm run test:coverage with flutter test --coverage -->

## Testing Patterns

### Unit Test Pattern (flutter_test)
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:finance_buddy_app/widgets/app_button.dart';

void main() {
  group('AppButton Widget', () {
    testWidgets('renders with correct text', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: AppButton(label: 'Click me'))),
      );
      expect(find.text('Click me'), findsOneWidget);
    });

    testWidgets('calls onPressed when tapped', (WidgetTester tester) async {
      var callCount = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppButton(label: 'Click', onPressed: () => callCount++),
          ),
        ),
      );

      await tester.tap(find.byType(AppButton));
      await tester.pump();

      expect(callCount, 1);
    });

    testWidgets('is disabled when onPressed is null', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: AppButton(label: 'Click'))),
      );
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    });
  });
}
```
<!-- Flutter-ized today: replaced React Testing Library render/screen/fireEvent with testWidgets + WidgetTester + find -->

### Repository Integration Test Pattern (Drift in-memory DB)
```dart
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finance_buddy_app/data/db.dart';
import 'package:finance_buddy_app/data/repositories/local/local_transaction_repository.dart';

void main() {
  late AppDatabase db;
  late LocalTransactionRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = LocalTransactionRepository(db);
  });

  tearDown(() async => db.close());

  group('TransactionRepository', () {
    test('returns transactions successfully', () async {
      final transactions = await repo.getAll();

      expect(transactions, isA<List>());
    });

    test('validates required fields on insert', () async {
      expect(
        () => repo.insert(amount: 0, description: ''),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('handles empty database gracefully', () async {
      final result = await repo.getAll();
      expect(result, isEmpty);
    });
  });
}
```
<!-- Flutter-ized today: replaced Next.js API route test with Drift NativeDatabase.memory() repository test -->

### Integration/E2E Test Pattern (integration_test / patrol)
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:finance_buddy_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('user can add and view a transaction', (WidgetTester tester) async {
    app.main();
    await tester.pumpAndSettle();

    // Navigate to add transaction sheet
    await tester.tap(find.byKey(const Key('fab_add')));
    await tester.pumpAndSettle();

    // Fill in the form
    await tester.enterText(find.byKey(const Key('amount_field')), '250');
    await tester.enterText(find.byKey(const Key('desc_field')), 'Lunch');

    // Submit
    await tester.tap(find.byKey(const Key('save_button')));
    await tester.pumpAndSettle();

    // Verify transaction appears on home screen
    expect(find.text('Lunch'), findsOneWidget);
    expect(find.text('₹250'), findsOneWidget);
  });

  testWidgets('user can settle a debt', (WidgetTester tester) async {
    app.main();
    await tester.pumpAndSettle();

    // Navigate to People tab
    await tester.tap(find.byKey(const Key('tab_people')));
    await tester.pumpAndSettle();

    // Tap settle button for first person
    await tester.tap(find.byKey(const Key('settle_button')).first);
    await tester.pumpAndSettle();

    // Confirm settlement
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();

    // Verify balance updated
    expect(find.text('₹0'), findsWidgets);
  });
}
```
<!-- Flutter-ized today: replaced Playwright page-automation E2E tests with integration_test / patrol Flutter equivalents -->

## Test File Organization

```
lib/
├── widgets/
│   ├── app_button.dart
│   └── market_card.dart
├── data/
│   └── repositories/
│       └── local/
│           └── local_transaction_repository.dart
test/
├── widgets/
│   ├── app_button_test.dart          # Unit/widget tests
│   └── market_card_test.dart
├── repositories/
│   └── local_transaction_repository_test.dart  # Integration tests
└── services/
    └── split_calculator_test.dart
integration_test/
├── add_transaction_test.dart         # E2E / integration_test
├── settle_debt_test.dart
└── auth_test.dart
```
<!-- Flutter-ized today: replaced .tsx/.ts file tree with .dart equivalents under test/ and integration_test/ -->

## Mocking External Services

### Drift In-Memory DB Mock
```dart
// Use NativeDatabase.memory() in setUp — no network, no file I/O
late AppDatabase db;

setUp(() {
  db = AppDatabase(NativeDatabase.memory());
});

tearDown(() async => db.close());
```
<!-- Flutter-ized today: replaced Supabase jest.mock with Drift NativeDatabase.memory() pattern -->

### Riverpod Provider Override Mock
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// Override a provider in unit tests via ProviderContainer
test('uses mock repository', () async {
  final container = ProviderContainer(
    overrides: [
      transactionRepositoryProvider.overrideWithValue(FakeTransactionRepository()),
    ],
  );
  addTearDown(container.dispose);

  final repo = container.read(transactionRepositoryProvider);
  expect(await repo.getAll(), isEmpty);
});

// Override inside a widget test
testWidgets('renders with mock data', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        transactionRepositoryProvider.overrideWithValue(FakeTransactionRepository()),
      ],
      child: const MaterialApp(home: HomeScreen()),
    ),
  );
  await tester.pumpAndSettle();
  expect(find.text('No transactions'), findsOneWidget);
});
```
<!-- Flutter-ized today: replaced Redis jest.mock with Riverpod ProviderContainer overrides pattern -->

### Fake Repository / Service Mock
```dart
// Implement the abstract interface with controlled test data
class FakeTransactionRepository implements TransactionRepository {
  final List<Transaction> _data;
  FakeTransactionRepository([List<Transaction>? seed]) : _data = seed ?? [];

  @override
  Future<List<Transaction>> getAll() async => List.unmodifiable(_data);

  @override
  Future<void> insert(Transaction tx) async => _data.add(tx);
}
```
<!-- Flutter-ized today: replaced OpenAI jest.mock with a Dart fake-repository implementing the abstract interface -->

## Test Coverage Verification

### Run Coverage Report
```bash
flutter test --coverage
# Generates coverage/lcov.info
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```
<!-- Flutter-ized today: replaced npm run test:coverage with flutter test --coverage + lcov reporting -->

### Coverage Thresholds
```yaml
# pubspec.yaml or CI check — enforce 80% minimum
# Use lcov --summary coverage/lcov.info to inspect totals
# Target: lines covered >= 80%
#
# Example lcov summary output:
#   Lines:    82.4%  (412 of 500)   ← must be >= 80%
#   Functions: 85.0%  (170 of 200)
#   Branches:  78.0%  (156 of 200)
```

## Common Testing Mistakes to Avoid

### FAIL: WRONG: Testing Implementation Details
```dart
// Don't reach into widget internals
final state = tester.state<MyWidgetState>(find.byType(MyWidget));
expect(state.count, 5);
```

### PASS: CORRECT: Test User-Visible Behavior
```dart
// Test what users see
expect(find.text('Count: 5'), findsOneWidget);
```
<!-- Flutter-ized today: replaced React state assertion with WidgetTester find.text -->

### FAIL: WRONG: Brittle Selectors
```dart
// Breaks easily — relies on internal widget type hierarchy
find.descendant(of: find.byType(Column), matching: find.byType(GestureDetector))
```

### PASS: CORRECT: Semantic Selectors
```dart
// Resilient to changes — use Keys or text
find.byKey(const Key('submit_button'))
find.text('Submit')
find.byTooltip('Submit')
```
<!-- Flutter-ized today: replaced Playwright CSS/text selectors with Flutter find.byKey / find.text -->

### FAIL: WRONG: No Test Isolation
```dart
// Tests depend on each other — shared mutable DB state
test('creates transaction', () async { /* writes to shared db */ });
test('updates same transaction', () async { /* depends on previous test */ });
```

### PASS: CORRECT: Independent Tests
```dart
// Each test gets its own in-memory DB via setUp
late AppDatabase db;
setUp(() { db = AppDatabase(NativeDatabase.memory()); });
tearDown(() async => db.close());

test('creates transaction', () async {
  final repo = LocalTransactionRepository(db);
  // Test logic
});

test('updates transaction', () async {
  final repo = LocalTransactionRepository(db);
  // Update logic
});
```
<!-- Flutter-ized today: replaced JS test/createTestUser isolation example with Dart setUp/NativeDatabase.memory() -->

## Continuous Testing

### Watch Mode During Development
```bash
flutter test --watch
# Tests run automatically on file changes (requires flutter_test_watch or IDE runner)
```
<!-- Flutter-ized today: replaced npm test --watch with flutter test --watch -->

### Pre-Commit Hook
```bash
# Runs before every commit
flutter test && flutter analyze lib/
```
<!-- Flutter-ized today: replaced npm test && npm run lint with flutter test && flutter analyze -->

### CI/CD Integration
```yaml
# GitHub Actions
- name: Run Tests
  run: flutter test --coverage
- name: Upload Coverage
  uses: codecov/codecov-action@v3
  with:
    files: coverage/lcov.info
```
<!-- Flutter-ized today: replaced npm test --coverage with flutter test --coverage in CI yaml -->

## Best Practices

1. **Write Tests First** - Always TDD
2. **One Assert Per Test** - Focus on single behavior
3. **Descriptive Test Names** - Explain what's tested
4. **Arrange-Act-Assert** - Clear test structure
5. **Mock External Dependencies** - Isolate unit tests
6. **Test Edge Cases** - Null, undefined, empty, large
7. **Test Error Paths** - Not just happy paths
8. **Keep Tests Fast** - Unit tests < 50ms each
9. **Clean Up After Tests** - No side effects
10. **Review Coverage Reports** - Identify gaps

## Success Metrics

- 80%+ code coverage achieved
- All tests passing (green)
- No skipped or disabled tests
- Fast test execution (< 30s for unit tests)
- E2E tests cover critical user flows
- Tests catch bugs before production

---

**Remember**: Tests are not optional. They are the safety net that enables confident refactoring, rapid development, and production reliability.
