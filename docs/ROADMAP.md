# Spendler — Phased Roadmap

**62 issues found across all screens. Organized into 6 phases.**

---

## Phase 1: Critical Fixes (Security & Data Integrity)

> Ship-blocking issues. App is broken or insecure without these.

| # | Issue | Screen | Severity |
|---|-------|--------|----------|
| 1 | Remove hardcoded test token in splash — gate behind `kDebugMode` | Splash | Critical |
| 2 | Completion screen: show auth error to user instead of silently skipping | Onboarding | Critical |
| 3 | Sign-in screen: add "Create account" navigation for new users | Auth | Critical |
| 4 | Transaction detail: validate amount > 0 before saving in edit mode | Transaction Detail | Critical |
| 5 | Split flow: store person names alongside amounts (not just count) | Split Flow | Critical |
| 6 | Consolidate dual design system — AppColors vs SpendlerColors into one | App-wide | High |

**Estimated scope**: 6 items

---

## Phase 2: Data Reliability & Refresh

> Every number on screen should be correct and instantly updated.

| # | Issue | Screen | Severity |
|---|-------|--------|----------|
| 1 | Plan page budgets don't refresh after adding transaction | Plan | High |
| 2 | Report page category totals stale until page reopen | Report | High |
| 3 | Transactions page "Confirm All" needs confirmation dialog | Transactions | Medium |
| 4 | Family page investment_type field may not be populated | Family | Medium |
| 5 | Home top categories hardcoded to 3 — handle 0, 1, 2 gracefully | Home | Low |
| 6 | Savings goals horizontal scroll — add page indicator dots | Home | Low |

**Estimated scope**: 6 items

---

## Phase 3: UX Polish & Missing States

> Make every interaction feel complete — loading, empty, error, success.

| # | Issue | Screen | Severity |
|---|-------|--------|----------|
| 1 | Add loading skeletons to home budget bar, report charts, plan budgets | App-wide | High |
| 2 | Budget cards: show warning state when >100%, error state when >150% | Plan | High |
| 3 | Subscriptions: highlight "billing in 7 days" with visual indicator | Subscriptions | High |
| 4 | Daily view page not linked from daily chart tapping a bar | Home | Medium |
| 5 | Transaction filters: show active filter count badge on filter button | Transactions | Medium |
| 6 | Penny chat: don't auto-scroll when user has manually scrolled up | Penny | Medium |
| 7 | People page: add long-press menu on friend card (edit/delete) | People | Medium |
| 8 | Settings budget editor: add helper text explaining budget scope | Settings | Medium |
| 9 | Unconfirmed transactions: add distinct visual badge in list | Transactions | Low |
| 10 | Subscription paused state: improve icon contrast | Subscriptions | Low |

**Estimated scope**: 10 items

---

## Phase 4: Feature Gaps (What Users Expect)

> Core features a finance app must have that are currently missing.

| # | Feature | Description | Priority |
|---|---------|-------------|----------|
| 1 | CSV Export | Export transactions to CSV for tax/accounting | High |
| 2 | Recurring auto-create | Subscriptions auto-generate transactions on billing date | High |
| 3 | Spending alerts | Push notification when category exceeds budget mid-month | High |
| 4 | Duplicate detection | Warn if same merchant + amount posted twice same day | Medium |
| 5 | Transaction search | Search by merchant, note, amount across all transactions | Medium |
| 6 | Receipt upload | Attach photo to a transaction as proof | Medium |
| 7 | Custom categories | Let users create their own categories beyond the 10 defaults | Low |
| 8 | Multi-currency conversion | Convert between currencies when viewing totals | Low |

**Estimated scope**: 8 items

---

## Phase 5: Design Consistency Pass

> Make the app feel like one product, not a patchwork.

| # | Issue | Scope |
|---|-------|-------|
| 1 | Unify border radius: pick 12/16/20 and standardize across all cards | App-wide |
| 2 | Unify padding: replace all hardcoded `16` with design tokens | App-wide |
| 3 | Unify shadows: apply `AppShadows.sm` consistently to all cards | App-wide |
| 4 | Remove duplicate Family tab — consolidate family ledger into People tab or separate it clearly | People + Family |
| 5 | Split direction labels: make "You owe" / "Owes you" consistent | People |
| 6 | Move hardcoded FAQs to a data file (JSON/Dart const list) | Settings |
| 7 | Add profile picture upload to settings | Settings |

**Estimated scope**: 7 items

---

## Phase 6: Intelligence & Delight

> Features that make users love the app, not just use it.

| # | Feature | Description |
|---|---------|-------------|
| 1 | Penny AI data hydration | Feed actual transaction data to Penny for personalized advice |
| 2 | Spending insights cards | "You spent 30% more on food this week" on home screen |
| 3 | Goal celebration | Confetti animation when savings goal reaches 100% |
| 4 | Smart notifications | "Your Netflix bill is tomorrow" based on subscription data |
| 5 | Offline mode | Cache all data locally, sync when online |
| 6 | Biometric lock | Face ID / fingerprint to open app (financial data protection) |
| 7 | Penny markdown upgrade | Support code blocks, tables, links in AI responses |

**Estimated scope**: 7 items

---

## Summary

| Phase | Focus | Items | Priority |
|-------|-------|-------|----------|
| **Phase 1** | Critical fixes — security, data integrity | 6 | Must do NOW |
| **Phase 2** | Data reliability — every number correct | 6 | Before any release |
| **Phase 3** | UX polish — loading, empty, error states | 10 | Pre-launch |
| **Phase 4** | Feature gaps — CSV export, alerts, search | 8 | Post-launch v1.1 |
| **Phase 5** | Design consistency — unify tokens & patterns | 7 | Post-launch v1.2 |
| **Phase 6** | Intelligence & delight — AI, celebrations | 7 | v2.0 |

**Total: 44 actionable items across 6 phases.**
