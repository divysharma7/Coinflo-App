# Plan: People & Debts (Unified Transaction Model)

**Source:** PRD v1 — People & Debts Unified Transaction Model
**Complexity:** Large (6 phases, ~30 files)
**Created:** 2026-05-27

---

## Context

CoinFlo is a Flutter personal finance app (Riverpod, Drift/SQLite, GoRouter). The current People module has separate Friends/Family tabs with incompatible models:
- `FriendContacts` + `FriendSplits` tables for friends
- `FamilyEntries` table for family (no per-person tracking)
- Splits are disconnected from the main transaction flow
- Splits don't integrate with categories or budgets

This plan unifies all interpersonal debt tracking into the main transaction model.

---

## Patterns to Mirror

| Category | Source | Pattern |
|---|---|---|
| Tables | `lib/data/db.dart:12` | Drift `Table` classes with `autoIncrement()`, `withDefault()`, nullable columns |
| Repositories | `lib/data/repositories/transaction_repository.dart` | Abstract class per domain, `Local*Repository` impl in `local/` |
| Providers | `lib/providers/database_providers.dart` | `repositoryProvider` -> `BaseRepository` implements all repo interfaces |
| State | `lib/providers/notification_providers.dart` | `StreamProvider` for reactive lists, `FutureProvider` for one-shots |
| UI Sheets | `lib/widgets/common/spendler_bottom_sheet.dart` | Bottom sheets via `showSpendlerSheet()` |
| Navigation | `lib/core/router.dart` | GoRouter with path pattern `/settings/people` |
| Schema migration | `lib/data/db.dart:200+` | `schemaVersion` bump + `migration` callback |

---

## Phase 1: Data Model (Drift tables, repos, providers)

**Goal:** New tables compile, old tables untouched, zero UI change.

### 1A — New Drift tables in `lib/data/db.dart`

Add these tables:

```dart
class Persons extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(max: 50)();
  TextColumn get tag => text().nullable()();        // friend / family / colleague / other
  TextColumn get avatarColor => text()();            // hex colour
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get archivedAt => dateTime().nullable()();
}

class Groups extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(max: 50)();
  TextColumn get description => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get archivedAt => dateTime().nullable()();
}

class GroupMembers extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get groupId => integer()();
  IntColumn get personId => integer()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class TransactionSplits extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get transactionId => integer()();
  IntColumn get personId => integer().nullable()();  // null = user's own share
  RealColumn get shareAmount => real()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
```

Add columns to `SpendlerTransactions`:
```dart
TextColumn get txnType => text().withDefault(const Constant('expense'))();  // expense/income/transfer/settlement
IntColumn get payerPersonId => integer().nullable()();           // null = user paid
IntColumn get counterpartyPersonId => integer().nullable()();    // settlements only
TextColumn get settlementDirection => text().nullable()();       // paid_to / received_from
IntColumn get groupId => integer().nullable()();
```

Register all new tables in `@DriftDatabase(tables: [...])`.
Bump `schemaVersion` and add migration callback that runs `ALTER TABLE ADD COLUMN` for SpendlerTransactions and `CREATE TABLE` for new tables.

### 1B — Abstract repositories

Create:
- `lib/data/repositories/person_repository.dart`
  - `watchAll()`, `watchByTag(String)`, `getById(int)`, `create()`, `update()`, `delete()`, `getBalance(int)`, `watchBalance(int)`
- `lib/data/repositories/group_repository.dart`
  - `watchAll()`, `getById(int)`, `create()`, `addMember()`, `removeMember()`, `watchMembers(int)`, `archive(int)`
- `lib/data/repositories/split_repository.dart`
  - `createSplits(int txnId, List<SplitEntry>)`, `watchSplitsForTransaction(int)`, `getBalanceForPerson(int)`, `watchBalanceForPerson(int)`

### 1C — Local repository implementations

Create in `lib/data/repositories/local/`:
- `local_person_repository.dart`
- `local_group_repository.dart`
- `local_split_repository.dart`

Update:
- `lib/data/repositories/base_repository.dart` — add new repo interfaces to `implements`
- `lib/data/repositories/local/local_repository.dart` — mix in new local implementations

Balance computation SQL (for `getBalanceForPerson`):
```sql
SELECT
  COALESCE(SUM(CASE WHEN ts.personId = :pid AND t.payerPersonId IS NULL THEN ts.shareAmount ELSE 0 END), 0)
  - COALESCE(SUM(CASE WHEN ts.personId IS NULL AND t.payerPersonId = :pid THEN ts.shareAmount ELSE 0 END), 0)
  - COALESCE(SUM(CASE WHEN t.txnType = 'settlement' AND t.counterpartyPersonId = :pid AND t.settlementDirection = 'paid_to' THEN t.amount ELSE 0 END), 0)
  + COALESCE(SUM(CASE WHEN t.txnType = 'settlement' AND t.counterpartyPersonId = :pid AND t.settlementDirection = 'received_from' THEN t.amount ELSE 0 END), 0)
AS balance
```
Positive = they owe user. Negative = user owes them.

### 1D — Riverpod providers + codegen

Create:
- `lib/providers/person_providers.dart` — `allPersonsProvider`, `personBalanceProvider(int)`, `personsByTagProvider(String)`
- `lib/providers/group_providers.dart` — `allGroupsProvider`, `groupDetailProvider(int)`

Update `lib/providers/providers.dart` to export new files.

Run: `dart run build_runner build --delete-conflicting-outputs`
Validate: `flutter analyze lib/` — zero errors

---

## Phase 2: People Screen UI Rebuild

**Goal:** Replace Friends/Family tabs with unified flat list. Old data still works alongside.

| File | Action |
|---|---|
| `lib/pages/people/people_page.dart` | REWRITE — single flat list, tag filter chips (All/Friends/Family/Colleagues), per-person balance row, search |
| `lib/pages/people/person_detail_page.dart` | CREATE — header (name, tag, balance, Settle Up CTA), transaction history |
| `lib/pages/people/person_creation_sheet.dart` | CREATE — name + tag picker + optional note |
| `lib/pages/people/person_edit_sheet.dart` | CREATE — edit name/tag/note, delete with balance guard |
| `lib/core/router.dart` | UPDATE — add `/people/:id` route |

---

## Phase 3: Unified Transaction Flow with Splits

**Goal:** FAB opens enhanced Add Transaction with type selector + "Split with..." toggle.

| File | Action |
|---|---|
| `lib/pages/add/quick_add_sheet.dart` | UPDATE — add type selector, "Split with..." toggle |
| `lib/pages/add/split_picker_sheet.dart` | CREATE — pick persons/group, split method, preview shares |
| `lib/pages/add/settlement_form.dart` | CREATE — simplified settlement form |
| `lib/services/split/split_calculator.dart` | CREATE — equal/exact/percentage/shares with paise remainder |
| `lib/data/repositories/local/local_transaction_repository.dart` | UPDATE — atomic split creation |
| `lib/providers/transaction_providers.dart` | UPDATE — category totals use user's share |

---

## Phase 4: Groups

**Goal:** Groups section with detail view (balances + transactions per group).

| File | Action |
|---|---|
| `lib/pages/groups/groups_page.dart` | CREATE — list of groups |
| `lib/pages/groups/group_detail_page.dart` | CREATE — balances tab + transactions tab |
| `lib/pages/groups/group_creation_sheet.dart` | CREATE — name + pick 2+ members |
| `lib/core/router.dart` | UPDATE — `/groups`, `/groups/:id` routes |
| `lib/pages/shell_page.dart` | UPDATE — consider Groups as sub-section inside People |

---

## Phase 5: Settlement Flow

**Goal:** Settlement as first-class transaction type.

| File | Action |
|---|---|
| `lib/pages/people/person_detail_page.dart` | UPDATE — Settle Up opens prefilled settlement form |
| `lib/data/repositories/local/local_split_repository.dart` | UPDATE — balance query includes settlements |
| `lib/providers/transaction_providers.dart` | UPDATE — settlements excluded from category totals |

Edge cases: partial settlement, over-settlement (balance flips, soft confirm), direction validation.

---

## Phase 6: Migration

**Goal:** Migrate existing Friends/Family data, remove old code.

| Action | Detail |
|---|---|
| CREATE `lib/services/migration/people_migration_service.dart` | FriendContacts->Persons, FriendSplits->TransactionSplits, FamilyEntries->Transactions |
| DELETE old files | `friend_creation_sheet.dart`, `add_split_sheet.dart`, `family_entry_sheet.dart`, `friend_split_repository.dart`, `family_repository.dart`, `friend_providers.dart` |
| UPDATE `db.dart` migration | Run migration service in schema version bump |

Migration rules:
- `FriendContact` -> `Person(tag: 'friend')`
- `FriendSplit` -> `TransactionSplit` (create synthetic transaction if orphaned)
- `FamilyEntry(inflow)` -> `Transaction(txnType: income)`
- `FamilyEntry(investment)` -> `Transaction(txnType: transfer)`
- Auto-create "Family" group if 2+ family-tagged persons

---

## Risks

| Risk | Likelihood | Mitigation |
|---|---|---|
| Drift migration breaks existing data | Medium | Transaction-wrapped migration, test on DB copy |
| Balance computation slow with many splits | Low | Composite index `(personId, transactionId)` on TransactionSplits |
| Orphaned FriendSplits with no matching transaction | High | Migration creates synthetic expense transactions |
| 5-tab bottom nav feels crowded | Medium | Groups as sub-tab inside People page |
| Split paise rounding errors | Low | Unit test all 4 split methods |

## Acceptance Criteria

- [ ] Each phase compiles independently
- [ ] `flutter analyze lib/` — zero errors after each phase
- [ ] Solo expenses identical to before
- [ ] Split expense: category total = user's share only
- [ ] Settlement: touches account, never touches category
- [ ] Person balance matches PRD section 6.7 formula
- [ ] Migration: zero data loss
