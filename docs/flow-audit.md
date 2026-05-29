# CoinFlo Flow Audit — Making the App Feel Connected

**Date:** 2026-05-29
**Branch:** main (post Phase 6 People & Debts)

---

## Executive Summary

CoinFlo has strong individual screens but **feels disconnected** because identical data (transactions, goals, budgets) behaves differently depending on which screen you're on. The core issue: **4 screens render transaction tiles, and all 4 behave differently.**

A user tapping a transaction on Home gets taken to a daily view. Tapping the same transaction on the Transactions tab opens its detail. Long-pressing works on the Transactions tab but does nothing on Home or Daily View. This breaks the mental model.

---

## 1. Transaction Tile Inconsistency (Critical)

A shared utility `showTransactionActions()` already exists at `lib/widgets/common/transaction_actions.dart` **but is not wired into any screen**.

| Screen | File | Tap | Long-press | Uses shared util? |
|--------|------|-----|------------|-------------------|
| **Home** (recent 5) | `home_page.dart:931` | `/daily-view` | None | No |
| **Daily View** | `daily_view_page.dart:70` | None (inert) | None | No |
| **Transactions** tab | `transactions_page.dart:390` | `/transaction/:id` | Edit/Delete sheet | No (inline copy) |
| **Category drill-down** | `category_transactions_page.dart:264` | `/transaction/:id` | None | No |

### What "connected" looks like

Every transaction tile everywhere should:
- **Tap** → push `/transaction/:id` (detail page)
- **Long-press** → `showTransactionActions()` from shared util (edit/delete sheet)

### Fix plan

1. **Home `_TransactionRow`**: Change tap from `/daily-view` to `/transaction/:id`. Add long-press → `showTransactionActions()`.
2. **Daily View `ListTile`**: Wrap in `GestureDetector` or `PressableCard`. Tap → `/transaction/:id`. Long-press → `showTransactionActions()`.
3. **Transactions Page `_buildTile`**: Already correct tap. Replace inline `_showTransactionActions()` with the shared util from `transaction_actions.dart`.
4. **Category Transactions `_TransactionTile`**: Already correct tap. Add long-press → `showTransactionActions()`.

**Complexity:** Low — 4 file edits, ~20 lines each.

---

## 2. Navigation Dead Ends

Things that look tappable but aren't, or navigate to the wrong place.

| Element | Location | Current behavior | Expected behavior |
|---------|----------|------------------|-------------------|
| Budget progress bar | Home hero card | Inert | Tap → Plan tab (budget section) |
| Top categories row | Home "Where it's going" | Inert | Tap → `/report/category` for that category |
| Goal cards | Home carousel | Tap: inert, Long-press: edit/delete | Tap → Plan tab (goal section) or "Add Money" sheet |
| "vs Last month" stat | Home quick stats | Inert | Tap → Report tab |
| Daily chart bars | Home chart | Tap → `/daily-view` | Correct |

### Fix plan

1. **Budget bar** (`home_page.dart`): Wrap in `GestureDetector`, `onTap: () => ref.read(selectedTabProvider.notifier).state = 2`
2. **Top categories** (`home_page.dart`): Wrap each row in `GestureDetector`, push to `/report/category` with the category + month
3. **Goal cards** (`home_page.dart`): Add `onTap` to open an "Add Money" sheet or navigate to Plan tab
4. **vs Last month** (`home_page.dart`): Wrap stat card, switch to Report tab

**Complexity:** Low — all in `home_page.dart`.

---

## 3. Duplicate Code (Transactions Page vs Shared Util)

`transactions_page.dart` has its own `_showTransactionActions()` (lines 473-524) and `_confirmDeleteFromList()` (lines 526-546) that are nearly identical copies of the shared `showTransactionActions()` and `confirmDeleteTransaction()` in `transaction_actions.dart`.

### Fix

Delete the inline copies from `transactions_page.dart`, import and call the shared versions. The shared util takes `(BuildContext, WidgetRef, SpendlerTransaction, String sym)` — same signature.

---

## 4. Daily View Is a Dead-End Screen

`daily_view_page.dart` (121 lines) is the most disconnected screen in the app:

- Transaction tiles are plain `ListTile` — no tap, no long-press, no `PressableCard`
- No way to add a transaction for that day
- No way to navigate to transaction detail
- No way to edit or delete
- Doesn't use the shared `transaction_actions.dart` util
- Doesn't use `AmountText` consistently (uses inline formatting)

### Fix

1. Replace `ListTile` with `PressableCard` tile matching the Transactions page style
2. Wire tap → `/transaction/:id`, long-press → `showTransactionActions()`
3. Optionally add a FAB or "+" button to quick-add with the date pre-filled

---

## 5. Category Transactions Missing Long-Press

`category_transactions_page.dart` uses `PressableCard` with tap → detail (correct) but has no long-press handler. The shared `showTransactionActions()` just needs to be wired in.

---

## 6. Home Goals — No "Add Money" Flow

Goal cards on home only support long-press for edit/delete. The most common goal action — **adding money toward a goal** — requires navigating to Plan tab first.

### Fix

Add a tap handler on goal cards that opens a small "Add Money" sheet (amount input + save). The `addMoneyToGoal()` function already exists in `plan_providers.dart`.

---

## 7. Home "Where It's Going" — Not Clickable

The top 3 categories section shows category name, amount, and progress bar but tapping does nothing. Users expect to drill into a category's transactions.

### Fix

Wrap each category row in `GestureDetector`, push to `/report/category` with `extra: (category: cat.name, month: selectedMonth)`.

---

## 8. Inconsistent Currency Formatting

Three different currency formatting approaches exist:

| File | Helper | Pattern |
|------|--------|---------|
| `utils/currency_utils.dart` | `currencySymbol()` | Shared (correct) |
| `category_transactions_page.dart:338` | Local `_sym()` | Duplicate |
| `home_page.dart:1015` | Local `_formatNumber()` | Partial (no currency) |
| `category_transactions_page.dart:354` | Local `_fmt()` | Duplicate |

### Fix

Delete `_sym()` and `_fmt()` from `category_transactions_page.dart`, use `currencySymbol()` from `currency_utils.dart` and a shared number formatter.

---

## 9. Flow Map — Current vs Connected

### Current State (disconnected)

```
         Home Page
         ├── Budget bar ───────────────── (dead end)
         ├── Stats row ────────────────── (dead end)
         ├── Daily chart bars ─────────── Daily View ── (dead end, tiles inert)
         ├── Top categories ───────────── (dead end)
         ├── Goals carousel ───────────── (long-press only → Plan tab)
         └── Recent transactions ──────── Daily View ── (dead end)

         Transactions Tab
         └── Transaction tiles ────────── /transaction/:id (tap + long-press work)

         Report Tab
         └── Category breakdown ───────── Category drill-down ── (tap works, no long-press)
```

### Target State (connected)

```
         Home Page
         ├── Budget bar ───────────────── Plan tab (budget section)
         ├── Stats row ────────────────── Report tab
         ├── Daily chart bars ─────────── Daily View ── tiles → /transaction/:id + long-press actions
         ├── Top categories ───────────── /report/category (drill-down)
         ├── Goals carousel ───────────── tap: Add Money sheet / long-press: edit/delete
         └── Recent transactions ──────── /transaction/:id + long-press actions

         Transactions Tab
         └── Transaction tiles ────────── /transaction/:id (tap) + shared actions (long-press)

         Report Tab
         └── Category breakdown ───────── Category drill-down ── tap + long-press actions

         ALL tiles use:
           tap    → context.push('/transaction/${t.id}')
           hold   → showTransactionActions(context, ref, t, sym)
```

---

## 10. Priority Order

| # | Fix | Impact | Effort | Files |
|---|-----|--------|--------|-------|
| 1 | Wire shared `showTransactionActions` into all 4 screens | High | Low | 4 files |
| 2 | Home recent: tap → `/transaction/:id` instead of `/daily-view` | High | Trivial | 1 file |
| 3 | Daily View: add tap/long-press to tiles | High | Low | 1 file |
| 4 | Home categories: make tappable → category drill-down | Medium | Low | 1 file |
| 5 | Home budget bar: tap → Plan tab | Medium | Trivial | 1 file |
| 6 | Home goals: tap → Add Money sheet | Medium | Low | 1 file |
| 7 | Delete duplicate `_sym()`, `_fmt()` helpers | Low | Trivial | 1 file |
| 8 | Remove inline `_showTransactionActions` from transactions_page | Low | Trivial | 1 file |

**Total: 8 focused changes across 5 files.**

---

## Files to Modify

```
lib/pages/home/home_page.dart              — items 1-6 (home tiles, categories, budget, goals)
lib/pages/home/daily_view_page.dart        — item 3 (wire tap + long-press)
lib/pages/transactions/transactions_page.dart — item 8 (use shared util)
lib/pages/report/category_transactions_page.dart — item 1,7 (long-press + dedup)
lib/widgets/common/transaction_actions.dart — already done (shared util exists)
```
