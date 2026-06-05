# CoinFlo — Audit Fixes

This document records the outcome of the 12-issue audit. **Every claim in the
audit prompt was first verified against the real codebase** before any code was
written — the prompt's file paths were largely written against an assumed
structure, and 5 of the 12 "issues" turned out to be false premises or already
implemented.

## Verdict summary

| # | Audit claim | Verdict | Action |
|---|---|---|---|
| 1 | Replace IndexedStack with StatefulShellRoute | **False premise** | None — IndexedStack + `selectedTabProvider` is the documented, working design; the claimed back-stack/scroll/stale symptoms don't occur (IndexedStack keeps tab subtrees alive; Riverpod data is independent of nav). |
| 2 | 4-tab vs 5-tab nav contradiction | **Non-issue** | None — code is consistently 4 tabs + a global centre-docked FAB (`shell_page.dart`) that opens Quick Add from every tab. The "5-tab" note is a future risk in a plan file, not in code. |
| 3 | Move Accounts from SharedPreferences to Drift | **Partly real, declined** | Skipped per decision — transactions have **no account FK**, so the JOIN/cascade/filter rationale is moot; a migration would risk live data for zero functional benefit. (An orphaned `UserAccounts` Drift table already exists.) |
| 4 | Firebase sync conflict resolution | **Real (re-scoped)** | **Fixed (targeted dedup):** sign-in now upserts budgets (by category) and dedupes goals (by name) instead of raw-inserting, so repeated sign-in no longer duplicates local data. |
| 5 | Add Edit/Delete to TxnDetail | **Already done** | None — full edit mode + delete-with-confirm already exist in `transaction_detail_page.dart`. |
| 6 | Connect DailyView to a provider | **Already done** | None — `DailyViewPage` already takes a `DateTime` and watches `dailyTransactionsProvider(date)`. |
| 7 | Notification scheduler triggers | **Partly real** | **Fixed:** subscription reminders now use `zonedSchedule` (configurable N days ahead) instead of one-time `.show()`; budget alerts now write to the in-app notification bell; disabling subscription alerts now cancels scheduled reminders. |
| 8 | Onboarding hydration loading/error | **Real** | **Fixed:** added `HydrationLoadingPage` + `hydrationControllerProvider` (loading/success/error) with branded UI, Retry, and "continue on this device" skip. |
| 9 | Excel import single-screen → wizard | **Partly real** | **Fixed (full wizard):** 4-step `PageView`-style wizard — file pick (ext + 10 MB size validation, .xlsx **or** .csv), column mapping (preview + dropdowns, mapping persisted to prefs), duplicate detection (date+amount+desc, default-skip with overrides), confirm + import inside a single `db.transaction()`. |
| 10 | Saraswati has no data layer/provider | **Mostly false** | **Fixed (the genuine gaps):** model, provider, service, and financial-context injection already existed. Added a `SaraswatiMessages` Drift table (schema v14, 7-day TTL) + `SaraswatiHistoryRepository` so chats persist across restarts, and a home-header "Ask Saraswati" shortcut so it's reachable outside Settings. |
| 11 | Report tab stale after TxnDetail writes | **Real** | **Fixed:** migrated the report/chart/category `FutureProvider`s to `StreamProvider`s backed by Drift `watch()` (added `watchCategoryTotalsForMonth`), so aggregates refresh live on any write regardless of originating screen. |
| 12 | Typed `showSpendlerSheet` | **Already done** | None — `showSpendlerSheet<T>` is already `Future<T?>`; call sites already use typed returns. |

## What changed (by issue)

- **ISSUE 11** — `transaction_repository.dart` + `local_transaction_repository.dart` + `local_repository.dart`: added reactive `watchCategoryTotalsForMonth`. Converted `monthCategoryTotalsProvider`, `prevMonthCategoryTotalsProvider` (`report_scope.dart`), `_categoryMonthTransactionsProvider` (`category_transactions_page.dart`), and `dailySpendingForWeek/weeklyTotalsForMonth/monthlyTotalsForYear/yearlyTotals` (`chart_providers.dart`) from `FutureProvider` to `StreamProvider`. Consumers use `AsyncValue`, so the change is transparent.
- **ISSUE 7** — `notification_service.dart` (new `scheduleOneTime`), `notification_scheduler.dart` (`checkUpcomingSubscriptions` now schedules N-days-ahead via the OS + `cancelSubscriptionReminders`), `spending_alert_service.dart` (writes budget alerts to `AppNotifications`, deduped), `notification_providers.dart` (new `subscriptionWarningDays` pref + cancel-on-disable), `notification_sheet.dart` (warning-days stepper + `budget` styling), `constants.dart`.
- **ISSUE 8 + 4** — new `hydration_provider.dart` (controller running hydration with upsert/dedupe) + new `hydration_loading_page.dart`; `router.dart` (route + redirect bypass); `sign_in_screen.dart` (hands off to `/hydration`, inline sync removed).
- **ISSUE 10** — `db.dart` (new `SaraswatiMessages` table, schema **v13→v14** + migration), new `saraswati_history_repository.dart`, `saraswati_providers.dart` (load on init + snapshot persistence), `header_section.dart` (home shortcut).
- **ISSUE 9** — `excel_import_service.dart` (raw read for xlsx+csv, `ColumnMapping`, duplicate detection, atomic `bulkInsert`), `excel_import_page.dart` (4-step wizard), `pubspec.yaml` (+`csv`).

## Decisions where the spec was ambiguous

- **Firebase conflict (ISSUE 4):** chose the **targeted dedup** fix (upsert/dedupe at sign-in) over a full `ConflictResolutionSheet`. The real bug was *duplicate creation* (raw insert), not silent overwrite, and budgets/goals have no `updatedAt` for true timestamp resolution. Per-user decision, the heavier conflict-UI + schema work was deferred.
- **Accounts (ISSUE 3):** **not migrated to Drift** — transactions never reference accounts, so there is no functional benefit and a prefs→Drift migration would risk live data. (User-confirmed.)
- **Saraswati entry point (ISSUE 10):** added a Home-header shortcut (not a 5th nav tab or second FAB) to avoid crowding the existing centre-docked Quick Add FAB.

## Issues found that were NOT in the prompt

1. **The audit prompt was written against a different/assumed codebase.** Most of its paths were wrong (`lib/database/database.dart` → `lib/data/db.dart`, `txn_detail_page.dart` → `transaction_detail_page.dart`, etc.), and 5/12 issues did not exist. Verifying first avoided destructive "fixes" (e.g. ripping out a working, documented navigation system).
2. **Orphaned `UserAccounts` Drift table** — registered in the schema but unused; accounts actually live in SharedPreferences. Left as-is (see ISSUE 3 decision).
3. **Redundant `ref.invalidate(...)` calls** in `report_page.dart` and `quick_add_sheet.dart` for the now-streamed report providers — harmless (a no-op re-subscribe) and left in place to minimise churn.

## Verification

- `flutter analyze` on all authored files: **0 errors, 0 warnings** (info-level `prefer_const` suggestions only, consistent with the pre-existing baseline).
- `flutter pub get` and `dart run build_runner build` (Drift codegen for the v14 table) both succeed.
- No automated tests exist for the touched feature areas; no test failure is attributable to these changes.

> **Note:** at the time of writing, the working tree also contained unrelated,
> in-flight edits from a concurrent editing session (e.g. `transactions_page.dart`,
> `recent_transactions_section.dart`, `base_repository.dart`, a new
> `lib/pages/errors/route_error_page.dart`). Those introduce their own compile
> errors and are **not** part of this audit work; they were intentionally left
> untouched. A repo-wide `flutter analyze` will not be green until that
> concurrent work is completed. Do not commit until both streams are reconciled.
