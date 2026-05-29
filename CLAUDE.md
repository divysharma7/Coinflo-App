# CoinFlo — CLAUDE.md

## Project Overview

CoinFlo (codebase: `finance_buddy_app`, legacy prefix: `Spendler`) is a Flutter personal finance app. All data on-device via Drift/SQLite. Firebase Auth for login only. Currency: INR (v1).

## Tech Stack

- Flutter + Dart
- Drift ORM (SQLite), schema v11, 19 tables
- Riverpod (providers, streams, FutureProvider.family)
- GoRouter with ShellRoute (4-tab + nested)
- Custom design system: AppColors, AppTextStyles, AppSpacing, AppRadius, AppShadows, AppDurations
- Phosphor Flutter icons, flutter_animate

## Architecture

```
lib/
├── core/          router.dart, enums.dart
├── data/
│   ├── db.dart    Drift database + all tables + migrations
│   └── repositories/
│       ├── *_repository.dart          (abstract interfaces)
│       └── local/local_*.dart         (Drift implementations)
├── providers/     Riverpod providers barrel-exported via providers.dart
├── pages/         Feature screens (home, people, groups, add, transactions, etc.)
├── services/      Business logic (split calculator, migration, AI classifier)
├── widgets/       Shared widgets (bottom sheets, cards, buttons)
└── design_system/ Tokens + component library
```

## Key Patterns

- **Repository pattern:** Abstract interface per domain → `BaseRepository` implements all → `LocalRepository` delegates to per-domain impls
- **Providers:** `StreamProvider` for reactive lists, `FutureProvider` for one-shots, barrel export via `providers.dart`
- **Bottom sheets:** All user input via `showSpendlerSheet()` helper
- **Transactions:** Negative amount = expense, positive = income. `isSplit` + `splitMyShare` for split transactions
- **People & Debts:** `Persons` table + `TransactionSplits` table. Balance computed via SQL joining splits + payer info

## Recent Work (2026-05-29)

### Phase 3: Split Integration into Main Transaction Flow
- Added "Split with..." toggle to `quick_add_sheet.dart` — opens `SplitPickerSheet`, saves transaction + splits atomically using `SplitCalculator.equal()`
- Fixed all category total providers to use `splitMyShare` (user's share) instead of full amount for split transactions
- Excluded settlement transactions from category totals

### Phase 6: Data Migration + Legacy Removal
- Completed `people_migration_service.dart`: FriendContacts→Persons, FriendSplits→TransactionSplits (with orphan detection), FamilyEntries→Transactions, auto-creates "Family" group
- Bumped schema v10→v11, migration runs automatically on upgrade
- Removed 9 legacy files (old providers, repositories, UI sheets)
- Updated `base_repository.dart`, `local_repository.dart`, `providers.dart`, `split_flow_sheet.dart`

### Build Status
`flutter analyze lib/` — 0 errors, 0 warnings (95 info-level lint suggestions)

## Remaining Plan Items

All 6 phases of the People & Debts plan are complete. The plan file lives at `.claude/plans/people-debts-unified.plan.md`.

### Known Gaps
| Gap | Fix |
|-----|-----|
| Transaction tile gesture inconsistency (3/4 screens) | Extract `_showTransactionActions()` to shared util |
| Home goal cards read-only | Wire existing `_AddGoalSheet` from plan_page |
| Single Firebase project (dev+prod) | Firebase project config split |

## Commands

```bash
flutter analyze lib/          # Lint check
flutter test                  # Run tests
dart run build_runner build --delete-conflicting-outputs  # Codegen (Drift)
```
