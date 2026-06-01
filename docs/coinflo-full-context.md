# CoinFlo — Complete App Context for AI Conversations

> Paste this entire document when starting a new Claude/AI chat about CoinFlo.
> Replace the last section with your specific question.

---

## What is CoinFlo?

CoinFlo (codebase name: finance_buddy_app, legacy class prefix: Spendler) is a
mobile-first personal finance app built in Flutter. It tracks expenses, income,
budgets, savings goals, splits with friends, subscriptions, and family investments.
All core processing is on-device (Drift/SQLite, no cloud dependency). Firebase Auth
for login only. Currency locked to INR for v1.

---

## Tech Stack

- **Framework:** Flutter (Dart)
- **Database:** Drift ORM (SQLite), 19 tables, schema v13
- **State management:** Riverpod (providers + streams + FutureProvider.family)
- **Routing:** GoRouter — single `/home` route hosts a 4-tab `IndexedStack` (Home/Report/Plan/Settings via `selectedTabProvider`); other screens are nested push routes (no ShellRoute)
- **Design system:** Custom tokens — AppColors, AppTextStyles, AppSpacing, AppRadius, AppShadows, AppDurations + widget library (AppButton, AppCard, CategoryPill, AnimatedProgressBar, HealthBadge, NeoPOPButton, PressableCard, etc.)
- **Icons:** Phosphor Flutter
- **Animations:** flutter_animate (staggered fade+slide-Y patterns)
- **Auth:** Firebase Authentication (email/password, returning user detection)
- **Notifications:** flutter_local_notifications (local push, scheduled)
- **Charts:** Custom bar charts, donut charts, progress rings (CustomPaint)
- **File handling:** image_picker for receipt photos, excel parsing for import

---

## Directory Structure

```
lib/
├── core/
│   ├── router.dart              GoRouter config, all routes, auth/onboarding guards
│   └── enums.dart               TransactionCategory with 14 groups + sub-categories
│
├── data/
│   ├── db.dart                  Drift database, 19 tables, migration v1-v13
│   └── repositories/
│       ├── transaction_repository.dart   (abstract)
│       ├── person_repository.dart        (abstract)
│       ├── goal_repository.dart          (abstract)
│       ├── split_repository.dart         (abstract + SplitEntry model)
│       └── local/
│           ├── local_repository.dart          facade delegates to sub-repos
│           ├── local_transaction_repository.dart
│           ├── local_person_repository.dart   balance SQL queries
│           ├── local_split_repository.dart
│           ├── local_goal_repository.dart
│           ├── local_friend_split_repository.dart (legacy)
│           └── local_budget_repository.dart
│
├── providers/
│   ├── providers.dart           barrel export for all providers
│   ├── transaction_providers.dart
│   ├── analytics_providers.dart spending, projections, streaks, alerts
│   ├── plan_providers.dart      budgets, goals, helper functions
│   ├── people_providers.dart    persons, balances
│   ├── group_providers.dart
│   ├── subscription_providers.dart
│   ├── family_providers.dart
│   ├── notification_providers.dart
│   ├── settings_providers.dart  currency, userName, userEmail, trackIncome
│   └── friend_providers.dart    legacy split system
│
├── services/
│   ├── auth_service.dart
│   ├── categorization_service.dart      6-stage on-device pipeline
│   ├── category_classifier.dart         wrapper for real-time classification
│   ├── merchant_dictionary.dart         shipped indian_merchants.json
│   ├── rule_engine.dart                 regex patterns for Indian banking
│   ├── upi_parser.dart                  UPI VPA format parsing
│   ├── transaction_normalizer.dart      cleanse raw descriptions
│   ├── learning_loop.dart               user correction feedback
│   ├── saraswati_service.dart           rule-based AI chat, 16+ handlers
│   ├── insight_generator.dart           weekly report generation
│   ├── notification_service.dart        local push notifications
│   ├── notification_scheduler.dart      evening check-in, Sunday digest
│   ├── spending_alert_service.dart      budget threshold alerts
│   ├── attachment_service.dart          receipt photo storage
│   ├── excel_import_service.dart        parse Excel, validate, dedup
│   ├── csv_exporter.dart                export transactions to CSV
│   ├── split_calculator.dart            compute balances and settlements
│   ├── people_migration_service.dart    FriendContacts to Persons migration
│   └── firestore_service.dart           optional cloud sync stub
│
├── pages/
│   ├── shell_page.dart          AppBottomTabBar + FAB
│   ├── splash/splash_page.dart
│   ├── auth/sign_in_screen.dart
│   ├── onboarding/             step2 through step9 + completion
│   ├── home/
│   │   ├── home_page.dart       7 sections (see App Structure below)
│   │   └── daily_view_page.dart all txns for a specific date
│   ├── transactions/
│   │   ├── transactions_page.dart       search, filter, tile list
│   │   ├── transaction_detail_page.dart read/edit modes, split, attach, delete
│   │   ├── split_flow_sheet.dart        equal/custom split from detail
│   │   └── attachment_viewer_page.dart
│   ├── add/
│   │   └── quick_add_sheet.dart         FAB new transaction with AI classify
│   ├── report/
│   │   ├── report_page.dart             charts, projections, streaks, categories
│   │   └── category_transactions_page.dart drill-down by category+month
│   ├── plan/
│   │   └── plan_page.dart               budgets + goals with full CRUD
│   ├── people/
│   │   ├── people_page.dart             list, search, tag filter
│   │   ├── person_detail_page.dart      balance card + Record expense btn
│   │   ├── person_creation_sheet.dart
│   │   ├── person_edit_sheet.dart
│   │   └── expense_sheet.dart           unified: who-paid chips, settle toggle
│   ├── groups/
│   │   ├── groups_page.dart
│   │   ├── group_detail_page.dart
│   │   └── group_creation_sheet.dart
│   ├── subscriptions/
│   │   └── subscriptions_page.dart
│   ├── family/
│   │   └── family_entry_sheet.dart      log MF/stocks/FD investments
│   ├── settings/
│   │   ├── settings_page.dart
│   │   ├── profile_sheet.dart
│   │   └── excel_import_page.dart
│   └── saraswati/
│       └── saraswati_page.dart          AI finance chat
│
├── widgets/
│   ├── common/
│   │   ├── spendler_bottom_sheet.dart   standard sheet with drag handle
│   │   ├── animated_amount.dart         number tween animation
│   │   ├── animated_progress_bar.dart
│   │   ├── error_card.dart
│   │   ├── notification_bell.dart       with unread badge
│   │   ├── notification_sheet.dart
│   │   ├── neo_pop_button.dart
│   │   ├── pressable_card.dart          onTap + onLongPress card wrapper
│   │   ├── hero_amount.dart
│   │   ├── contextual_pill.dart
│   │   ├── health_ring.dart
│   │   └── empty_state.dart
│   └── charts/
│       └── spend_bar_chart.dart
│
├── design_system/
│   ├── design_system.dart       barrel export
│   ├── app_colors.dart
│   ├── app_text_styles.dart     displayXL, headingL/M/S, bodyM/S, labelM/S
│   ├── app_spacing.dart         xxs=4, xs=8, sm=12, md=16, lg=24, xl=32, xxl=48, xxxl=64
│   ├── app_radius.dart          base, sm, md, mdLg, lg, xl, full, pill
│   ├── app_shadows.dart         sm, md, lg
│   ├── app_durations.dart       fast, debounce, base, medium, slow
│   └── widgets/
│       ├── app_button.dart      primary + ghost variants, scale animation
│       ├── app_card.dart
│       ├── category_pill.dart
│       ├── bottom_tab_bar.dart
│       ├── health_badge.dart
│       ├── account_icon.dart
│       ├── app_progress_indicator.dart
│       ├── app_back_button.dart
│       ├── app_text_field.dart
│       └── app_add_button.dart
│
└── utils/
    └── currency_utils.dart      currencySymbol helper (INR/USD/EUR/GBP/JPY)
```

---

## App Structure (4 Tabs + FAB)

```
Shell (BottomTabBar with 4 tabs + center FAB)
│
├── Tab 0: Home
│   ├── Dark header (greeting + month picker + notification bell)
│   ├── Budget progress bar (spent vs limit, % used, days remaining)
│   ├── Quick stats row (today / this month / vs last month)
│   ├── Daily spend bar chart (7-day, tappable bars go to Daily View)
│   ├── Top categories section
│   ├── Savings goals (horizontal scroll cards, long-press edit/delete)
│   └── Recent transactions (last 5)
│
├── Tab 1: Transactions
│   ├── Search bar (merchant / note / category)
│   ├── Filter sheet (direction, amount range, date range, category)
│   ├── Unconfirmed section (with "Confirm All" batch button)
│   └── Confirmed section (PressableCard tiles, tap detail, long-press edit/delete)
│
├── Tab 2: Report
│   ├── Period selector (week / month / year)
│   ├── Period navigator (prev / next)
│   ├── Bar chart visualization
│   ├── Month-end projection card (linear or shape-based forecast)
│   ├── Budget vs actual breakdown per category
│   ├── Savings goals progress
│   ├── Streak badge (consecutive weeks under target)
│   ├── Donut chart (category breakdown)
│   ├── Category breakdown list (tappable to CategoryTransactionsPage)
│   └── CSV export button
│
├── Tab 3: Settings
│   ├── Profile card (name, email)
│   ├── Ask Saraswati (AI chat, rule-based, 16+ query handlers)
│   ├── People management (friends/family/colleagues for splits)
│   ├── Groups (shared expense groups)
│   ├── Subscriptions (recurring payments tracker)
│   ├── Excel Import (bulk bank statement import with validation)
│   ├── Notifications toggle
│   ├── Help / FAQs
│   └── About / Version
│
└── FAB (center-docked) opens QuickAddSheet
    ├── Amount input
    ├── Category picker with AI auto-suggestion
    ├── Note/merchant field (triggers 6-stage classification after 3+ chars)
    ├── Expense / Income toggle
    ├── Date picker
    └── Income source selector (salary/freelance/refund/gift/other)
```

---

## Complete Database Schema (19 Tables)

### SpendlerTransactions (main ledger)

```
id                       INTEGER AUTOINCREMENT
amount                   REAL
category                 TEXT (foodAndDrink/transport/shopping/billsAndUtilities/
                               healthAndWellness/entertainment/personalCare/education/
                               travel/income/cash/investments/insurance/other/
                               debt/settlement)
merchant                 TEXT NULLABLE
note                     TEXT NULLABLE
happenedAt               DATETIME (default: now)
source                   TEXT (default: 'manual') values: manual/import/sms
status                   TEXT (default: 'confirmed') values: unconfirmed/confirmed
isSplit                  BOOLEAN (default: false)
splitCount               INTEGER NULLABLE
splitMyShare             REAL NULLABLE
splitPendingAmount       REAL NULLABLE
splitSettled             BOOLEAN (default: false)
ledgerType               TEXT (default: 'personal') values: personal/family
syncId                   TEXT NULLABLE
createdAt                DATETIME (default: now)
rawHash                  TEXT NULLABLE (SHA256 for dedup)
merchantToken            TEXT NULLABLE (normalized merchant key)
categorizationSource     TEXT NULLABLE values: smartRule/dictionary/userMerchantMap/
                                              upiParser/ruleEngine/uncategorized
categorizationConfidence REAL NULLABLE (0.0-1.0)
importBatchId            TEXT NULLABLE
isAnomaly                BOOLEAN (default: false)
isRecurring              BOOLEAN (default: false)
incomeSource             TEXT NULLABLE values: salary/freelance/refund/gift/other
attachmentPath           TEXT NULLABLE (local file path for receipt photo)
txnType                  TEXT (default: 'expense') values: expense/income/transfer/settlement
payerPersonId            INTEGER NULLABLE (null = user paid)
counterpartyPersonId     INTEGER NULLABLE (settlements only)
settlementDirection      TEXT NULLABLE values: paid_to/received_from
groupId                  INTEGER NULLABLE
```

### People & Debts (v10)

```
Persons
  id, name, tag (friend/family/colleague/other), avatarColor (hex),
  note, createdAt, archivedAt

TransactionSplits
  id, transactionId, personId (null = user's own share), shareAmount, createdAt

Groups
  id, name, description, createdAt, archivedAt

GroupMembers
  id, groupId, personId, createdAt
```

### Planning & Goals

```
CategoryBudgets    id, category, monthlyLimit
SavingsGoals       id, name, targetAmount, currentAmount, iconName, createdAt
Subscriptions      id, name, amount, billingCycle (weekly/monthly/yearly),
                   nextBillingDate, category, isActive, createdAt
UserAccounts       id, name, type (cash/bank/creditCard/digitalWallet), createdAt
SmartRules         id, keyword, category, createdAt
```

### Family Ledger

```
FamilyEntries      id, type (inflow/investment), amount, fromPerson, note,
                   happenedAt, investmentType (MF/stocks/FD/other), syncId, createdAt
```

### Analytics & Insights

```
WeeklyReflections  id, weekStartDate, totalSpent, topCategory, openedAt,
                   llmReportGeneratedAt, createdAt
AppMetrics         id, metricKey (app_open/retrospection/llm_report/week_confirmed),
                   metricValue, recordedAt
AppNotifications   id, title, body, type (transaction/checkin/digest), isRead, createdAt
```

### Import System

```
MerchantMappings   id, merchantToken, category, source (dictionary/rule/manual),
                   confidence, useCount, updatedAt
CorrectionEvents   id, merchantToken, previousCategory, newCategory, correctedAt,
                   backfillCount
ImportBatches      id (UUID), bankName, fileName, importedAt, transactionCount,
                   categorizedCount, uncategorizedCount, duplicateCount, status,
                   errorMessage
```

### Legacy (v3-v8, being migrated to Persons)

```
FriendContacts     id, name, avatarColour, createdAt
FriendSplits       id, transactionId, friendContactId, amount,
                   direction (they_owe_me/i_owe_them), isSettled, isWrittenOff,
                   settledAt, settlementMethod, createdAt,
                   status (uncleared/partiallyCleared/cleared), amountCleared
```

---

## Transaction Categories (14 + sub-categories)

```
foodAndDrink      Groceries, Restaurants, Coffee, Takeaway, Alcohol
transport         Fuel, Public Transit, Taxi, Parking, Car Maintenance
shopping          Clothing, Electronics, Home, Books, Gifts
billsAndUtilities Rent, Electricity, Internet, Water, Insurance
healthAndWellness Gym, Doctor, Pharmacy, Mental Health
entertainment     Movies, Streaming, Games, Hobbies
personalCare      Haircut, Skincare, Spa
education         Courses, Tuition, Childcare
travel            (flat)
income            (flat)
cash              (flat)
investments       (flat)
insurance         (flat)
other             (flat)
+ Legacy in enum: streaming, gymFitness, productivityTools
```

---

## All Routes

```
/splash                    SplashPage
/sign-in                   SignInScreen
/onboarding/step2..step9   Onboarding flow
/onboarding/complete       CompletionScreen

/home                      ShellPage → 4-tab IndexedStack: Home/Report/Plan/Settings (selectedTabProvider)
/transaction/:id           TransactionDetailPage (extra: {startInEditMode: bool})
/daily-view                DailyViewPage (extra: DateTime)
/attachment-viewer         AttachmentViewerPage (extra: String filePath)
/report/category           CategoryTransactionsPage (extra: {category, month})
/people/:id                PersonDetailPage
/groups/:id                GroupDetailPage
/saraswati                 SaraswatiPage (AI chat)
/subscriptions             SubscriptionsPage
/import                    ExcelImportPage
/plan                      PlanPage (also reachable via tab)
```

---

## All Providers

### Core
```
repositoryProvider                  BaseRepository (facade singleton)
databaseProvider                    SpendlerDatabase
```

### Navigation & UI State
```
selectedTabProvider                  int (0-3 tab index)
selectedMonthProvider                DateTime
selectedWeekProvider                 DateTime
selectedWeekStartProvider            DateTime (computed Monday)
```

### Transactions
```
weeklyTransactionsProvider           Stream<List<SpendlerTransaction>>
unconfirmedQueueProvider             Stream<List<SpendlerTransaction>>
allTransactionsProvider              Stream<List<SpendlerTransaction>>
singleTransactionProvider(id)        Future<SpendlerTransaction?>
filteredTransactionsProvider         computed from allTransactions + filters
transactionFiltersProvider           TransactionFilters state
dailyTransactionsProvider(date)      Stream<List<SpendlerTransaction>>
```

### Spending Analytics
```
todaySpendingProvider                Stream<double>
monthlyExpenseProvider               Stream<double>
lastMonthExpenseProvider             Stream<double>
dailySpendingForWeekProvider         Stream<Map<int, double>> weekday to amount
monthlyBudgetProvider                Stream<double?> total budget limit
thisMonthCumulativeProvider          Stream<List<double>> day-by-day running total
lastMonthCumulativeProvider          Stream<List<double>>
dayOfWeekAveragesProvider            Future<Map<int, double>> 4-week avg per weekday
topMerchantsProvider                 Future<List<MapEntry<String, int>>> top 7
monthlyComparisonProvider            Future category-level this vs last month
streakProvider                       Future<int> consecutive weeks under target
weeklyAlertsProvider                 Future<List<String>> max 2 anomaly alerts
monthEndProjectionProvider           Future<double> forecasted month-end total
```

### Plan & Budget
```
budgetsProvider                      Stream<List<CategoryBudget>>
monthlyCategorySpendingProvider      Stream<Map<String, double>>
budgetStatusProvider                 Future total limit/spent/remaining
goalsProvider                        Stream<List<SavingsGoal>>
budgetVsActualProvider               Future per-category comparison
```

### People & Relationships
```
allPersonsProvider                   Stream<List<Person>>
personsByTagProvider(tag)            Stream<List<Person>>
personBalanceProvider(id)            Stream<double>
```

### Groups
```
allGroupsProvider                    Stream<List<Group>>
groupDetailProvider(id)              Future group + members
groupTransactionsProvider(id)        Stream<List<SpendlerTransaction>>
```

### Subscriptions
```
allSubscriptionsProvider             Stream<List<Subscription>>
subscriptionMonthlyTotalProvider     Stream<double>
```

### Family
```
allFamilyEntriesProvider             Stream<List<FamilyEntry>>
familyTotalProvider                  Stream<double>
```

### Notifications
```
unreadNotificationCountProvider      Stream<int>
allNotificationsProvider             Stream<List<AppNotification>>
```

### AI & Classification
```
saraswatiChatProvider                StateProvider<List<ChatMessage>>
saraswatiProcessingProvider          StateProvider<bool>
categoryClassifierProvider           Provider<CategoryClassifier>
```

### User Settings
```
userNameProvider                     Future<String?>
userEmailProvider                    Future<String?>
trackIncomeProvider                  Future<bool>
selectedCurrencyProvider             Future<String> (locked to 'inr')
```

---

## People & Debts System

### How it works
- Create people with tags (friend/family/colleague/other) and avatar colors
- PersonDetailPage shows live balance via watchPersonBalance stream
- ExpenseSheet (unified): "You" / "{name}" chips for who-paid, amount, note, settle toggle
- Settle toggle pre-fills amount with abs(balance), allows partial settlement
- Both expense and settlement paths create transaction + split records

### Balance calculation (SQL)
```
+ SUM(person shares WHERE user paid)    they owe me
- SUM(user shares WHERE person paid)    I owe them
= net balance
  positive = they owe me
  negative = I owe them
```

---

## AI / Smart Features

### On-device category classification (6-stage cascade)
```
1. SmartRules        user-authored keyword to category rules
2. UserMerchantMap   learned from user corrections
3. ShippedDictionary indian_merchants.json curated list
4. UpiParser         extracts merchant from UPI VPA format
5. RegexRuleEngine   Indian banking description patterns
6. Uncategorized     fallback
```
Triggers after 3+ characters typed. 65% confidence threshold.

### Ask Saraswati (AI Chat)
Rule-based financial Q&A (no external LLM, deterministic):
- Spending queries (today, week, month, last month)
- Category breakdown and comparison
- Merchant analysis (top by frequency)
- Week-over-week and month-over-month comparison
- Biggest expenses, transaction counts, daily averages
- Income tracking, split summaries, budget status

### Weekly Insights
- Spending summary per week
- Top category identification
- Trend detection and anomaly flagging (max 2 alerts)
- Month-end projection (linear or pattern-based)
- Streak tracking (consecutive weeks under target)

---

## Notification System

### Scheduled
- Evening check-in (default 7 PM): confirm unconfirmed transactions
- Sunday digest (7 PM): weekly spending summary

### Types
- transaction: confirmations
- checkin: evening reminders
- digest: weekly summaries

### Alerts
- Budget threshold alerts when approaching category limit
- Unusual pattern detection in weekly alerts

---

## Import / Export

### Excel Import (6-stage pipeline)
1. File upload from device
2. Schema validation (required: date, amount, type, category)
3. Duplicate detection (SHA256 hash)
4. Row-level error tracking
5. Batch categorization via CategorizationService
6. Insert with import metadata

### CSV Export
- Export filtered transactions to CSV from Report page

---

## Current Known Issues

### Transaction flow inconsistency
Every screen handles transaction tile gestures differently:

| Screen                   | Tap                    | Long-press           |
|--------------------------|------------------------|----------------------|
| Home (recent txns)       | goes to Daily View     | nothing              |
| Daily View               | nothing (dead end)     | nothing              |
| Transactions page        | goes to Detail         | Edit/Delete sheet    |
| Category Transactions    | goes to Detail         | nothing              |

Ideal: every transaction tile should behave identically:
- Tap goes to /transaction/{id}
- Long-press opens actions sheet (Edit / Delete)

RESOLVED: extracted to shared `lib/widgets/common/transaction_actions.dart`
(`showTransactionActions`), wired across home, daily-view, transactions, category
& person screens.

### Legacy split system
RESOLVED (Phase 6): `people_migration_service` migrates FriendContacts/FriendSplits
→ Persons/TransactionSplits (with orphan detection); legacy providers, repositories
and UI sheets were removed.

---

## What I Need Help With

[PASTE YOUR SPECIFIC QUESTION HERE]
