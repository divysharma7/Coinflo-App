# Saraswati Chat-Based Transaction Entry — Technical Documentation

## Overview

Saraswati is CoinFlo's AI chat assistant. It originally only answered **read** queries ("how much did I spend this month?"). This implementation adds a parallel **write** pipeline: users can enter transactions by typing naturally ("100 coffee", "split 600 with rahul").

The system extracts a structured `TransactionDraft`, evaluates confidence per field, and decides whether to silently commit, ask one clarifying question, or fall back to the manual form.

---

## Architecture

### High-Level Flow

```
User types in Saraswati chat
         |
         v
  SaraswatiRouter.classify()
         |
    +----+----+
    |         |
 QUESTION   ENTRY
    |         |
    v         v
 SaraswatiService.ask()    SaraswatiEntryService.processEntry()
 (existing read pipeline)   (new write pipeline)
    |                              |
    v                              v
 IntentExecutor.execute()    4-Stage Extraction Pipeline
 (markdown response)               |
                                   v
                          PersonalDefaults.apply()
                                   |
                                   v
                          DisambiguationEngine.evaluate()
                                   |
                         +---------+---------+
                         |         |         |
                    SilentCommit  AskOne   FormFallback
                         |         |         |
                         v         v         v
                    EntryExecutor  Chip UI   QuickAddSheet
                    .commit()     (reply)    (pre-filled)
                         |
                         v
                    DB insert via
                    BaseRepository
                    (audit-tagged)
```

### Router Decision Logic

```
Input: normalized user text
         |
         v
  Contains number + transaction verb? ──yes──> ENTRY
  (paid, spent, bought, gave, sent,
   received, split, owe, lent, diye,
   bheje, mila, liya)
         |no
         v
  Starts with question word? ──yes──> QUESTION
  (how, what, when, where, why,
   show, tell, kitna, kaise)
  OR ends with "?"
  OR contains question phrase?
  (show me, tell me, compare, vs,
   breakdown, average, total, top)
         |no
         v
     AMBIGUOUS
         |
    Try entry pipeline first
         |
    If QuickFormFallback(unrecognized)
         |
    Try query pipeline instead
```

### 4-Stage Extraction Pipeline

```
Normalized input
         |
         v
  Stage 0: QuickaddMatcher ──match──> Draft (conf 0.95)
  (15 regex patterns)
         |no match
         v
  Stage 1: PatternMatcher ──match──> Draft (conf 0.90)
  (5 fuzzy templates)
         |no match
         v
  Stage 2: EntryCacheRepository ──hit──> Draft (carried conf)
  (SQLite, date re-resolved)           + date re-resolved to today
         |cache miss
         v
  Stage 3: LlmEntryExtractor ──success──> Draft (per-field conf)
  (Gemini 2.0 Flash, 2s timeout)
         |null (timeout/error/offline)
         v
     null (→ disambiguation handles)
```

### Disambiguation Decision Matrix

```
Draft from extraction
         |
         v
  Rule 1: kind=unknown OR draft=null?
         |yes──> QuickFormFallback(reason: unrecognized)
         |no
         v
  Rule 2: Amount fails sanity check?
  (< 1, > 500K, > 1.5x historical max)
         |yes──> AskOneQuestion(field: amount, chips: [rounded values])
         |no
         v
  Rule 3: 2+ fields missing or uncertain (<0.85)?
         |yes──> QuickFormFallback(reason: too_uncertain)
         |no
         v
  Rule 4: kind=split AND all fields OK?
         |yes──> AskOneQuestion(field: split_with, chips: [confirm])
         |no     (splits ALWAYS require confirmation)
         v
  Rule 5: Exactly 1 required field missing?
         |yes──> AskOneQuestion(field: <missing>, chips: [suggestions])
         |no
         v
  Rule 6: Exactly 1 field confidence < 0.85?
         |yes──> AskOneQuestion(field: <uncertain>, chips: [guess + alts])
         |no
         v
  Rule 7: All good
         └──> SilentCommit(draft)
```

---

## Data Model

### TransactionDraft

The core artifact flowing through the pipeline.

```
TransactionDraft
├── kind: TransactionKind (expense | income | transfer | split)
├── amount: double?
├── counterparty: String?         (merchant or person name)
├── counterpartyId: String?       (resolved ID if matched)
├── category: String?             (canonical: food, rent, transport, etc.)
├── date: DateTime?               (resolved absolute date)
├── payer: PayerKind?             (user | counterparty | splitEqual | splitCustom)
├── splitWith: List<String>?      (names if split)
├── note: String?
├── source: String                (quickadd | pattern | cache | llm)
├── fieldConfidence: Map<String, double>   (0.0-1.0 per field)
├── rawInput: String              (original chat text for audit)
│
├── uncertainFields({threshold})  → List<String> (fields below threshold)
├── missingRequiredFields()       → List<String> (per kind)
├── toJson() / fromJson()
├── copyWith()
└── toExtractionMetaJson()        → String (for DB audit column)
```

**Required fields per TransactionKind:**

```
expense:  amount, category, date
income:   amount, category, date
transfer: amount, counterparty (or counterpartyId), date
split:    amount, counterparty (or splitWith non-empty), date, payer
```

### EntryAction (sealed)

```
EntryAction
├── SilentCommitAction
│   └── draft: TransactionDraft
├── AskOneQuestionAction
│   ├── partialDraft: TransactionDraft
│   ├── fieldToConfirm: String
│   ├── questionText: String
│   └── chipOptions: List<String>
└── QuickFormFallbackAction
    ├── partialDraft: TransactionDraft?
    └── reason: String
```

### Database Schema (v13)

**New columns on `spendler_transactions`:**
```sql
raw_input       TEXT   -- original chat text, nullable
extraction_meta TEXT   -- JSON: {source, field_confidence}, nullable
```

**`source` column** (already existed, default 'manual'):
- `'manual'` — added via QuickAddSheet
- `'saraswati_chat'` — added via entry pipeline
- `'sms'` — added via SMS import

**New table: `saraswati_entry_cache`:**
```sql
normalized_input  TEXT     PRIMARY KEY
draft_json        TEXT     NOT NULL
hit_count         INTEGER  NOT NULL DEFAULT 1
created_at        INTEGER  NOT NULL
last_used_at      INTEGER  NOT NULL
confirmed_by_user INTEGER  NOT NULL DEFAULT 0
```

**New table: `saraswati_user_defaults`:**
```sql
key         TEXT     PRIMARY KEY   -- e.g. "counterparty:rahul", "category_for:zomato"
value       TEXT     NOT NULL      -- e.g. "splitEqual", "food"
hit_count   INTEGER  NOT NULL DEFAULT 1
updated_at  INTEGER  NOT NULL
```

---

## Stage 0: Quickadd Matcher — 15 Patterns

All patterns are case-insensitive regex on normalized input. Confidence = 0.95.

```
 #  Pattern                              Example          Kind      Category
 1  <amount> coffee|chai|tea             "100 coffee"     expense   food
 2  <amount> lunch|dinner|breakfast|snack "200 lunch"     expense   food
 3  <amount> uber|ola|rapido|auto|cab|taxi "150 uber"    expense   transport
 4  <amount> rent                        "15000 rent"     expense   rent
 5  <amount> petrol|fuel|gas             "1000 petrol"    expense   transport
 6  <amount> grocery|groceries|sabzi|vegetables "500 grocery" expense food
 7  <amount> electricity|water|wifi|internet|gas bill "2000 electricity" expense utilities
 8  <amount> from <name>                 "500 from raj"   income    other
 9  <amount> to <name>                   "1000 to mom"    transfer  —
10  salary <amount>                      "salary 50000"   income    salary
11  <amount> medicine|medical|doctor|hospital "300 medicine" expense healthcare
12  <amount> movie|netflix|spotify       "200 movie"      expense   entertainment
13  <amount> amazon|flipkart|myntra      "1500 amazon"    expense   shopping
14  split <amount> with <names>          "split 600 with rahul,priya" split —
15  <amount> zomato|swiggy               "400 zomato"     expense   food
```

## Stage 1: Pattern Matcher — 5 Templates

Fuzzier patterns for shapes Stage 0 missed. Confidence = 0.90.

```
 #  Template                    Example              Kind      Notes
 1  paid <amount> to <name>    "paid 500 to rahul"  transfer  —
 2  <name> paid me <amount>    "rahul paid me 300"  income    category conf 0.80
 3  <name> owes me <amount>    "priya owes me 250"  split     payer=user, conf 0.80
 4  i owe <name> <amount>      "i owe rahul 500"    transfer  —
 5  <amount> <free_text>       "500 birthday gift"  expense   category=null, conf 0.60 (catch-all)
```

## Stage 2: Entry Cache

Structurally identical to IntentCacheRepository. Key = normalized input string.

- On hit: re-resolves date to today (cached "today" from Tuesday ≠ Wednesday's today)
- Bumps hit_count + last_used_at non-blocking
- `confirmed_by_user` flag for entries the user explicitly confirmed

## Stage 3: LLM Extractor

Gemini 2.0 Flash with function calling. Schema: `extract_transaction`.

- 2-second timeout → returns null
- Any error → returns null, never throws
- System prompt includes anti-hallucination rules, 8 Hindi/Hinglish examples, date resolution guidance
- `kind=unknown` returns a draft (disambiguation handles it), does NOT return null
- Confidence: 0.95+ for explicit values, 0.75-0.9 for clear inference, <0.7 for guesses

---

## Personal Defaults (Learning)

Applied AFTER extraction, BEFORE disambiguation. Raises confidence to 0.90.

**Learning rules:**
- After 1+ split with "rahul" → key `counterparty:rahul` → value `splitEqual`
- After 1+ expense at "zomato" categorized as food → key `category_for:zomato` → value `food`

**What triggers learning:**
- SilentCommit path (auto-committed entries)
- AskOneQuestion path (after user confirms via chip)

**What does NOT trigger learning:**
- QuickFormFallback (too varied to generalize)

---

## Entry Executor

Commits a confirmed TransactionDraft to the database.

```
TransactionDraft
         |
         v
  Build SpendlerTransactionsCompanion:
  ├── amount: negative for expense, positive for income/transfer/split
  ├── category: from draft, or 'other'/'income' fallback
  ├── merchant: counterparty or note
  ├── happenedAt: draft.date or now
  ├── source: 'saraswati_chat' (always)
  ├── status: 'confirmed'
  ├── txnType: mapped from TransactionKind
  ├── rawInput: original chat text
  └── extractionMeta: JSON {source, field_confidence}
         |
         v
  repo.insertTransaction(companion) → txnId
         |
         v
  _learnDefaults(draft)  (update personal defaults table)
         |
         v
  return txnId  (for undo)
```

**Undo:** `repo.deleteTransaction(txnId)` — available for 5 seconds after commit.

---

## Provider Wiring

```
databaseProvider
    |
    ├── _intentCacheProvider → IntentCacheRepository
    ├── _entryCacheProvider → EntryCacheRepository
    └── _personalDefaultsProvider → PersonalDefaultsRepository

repositoryProvider
    ├── _intentExecutorProvider → IntentExecutor
    └── _entryExecutorProvider → EntryExecutor(repo, defaults)

_classifierModelProvider → GenerativeModel (gemini-2.0-flash + classifier prompt)
    └── _llmClassifierProvider → LlmIntentClassifier

_entryExtractorModelProvider → GenerativeModel (gemini-2.0-flash + entry prompt)
    └── _llmEntryExtractorProvider → LlmEntryExtractor

saraswatiServiceProvider → SaraswatiService (executor, keywordMatcher, cache, llm)

saraswatiEntryServiceProvider → SaraswatiEntryService
    (quickadd, pattern, entryCache, llmExtractor, defaults, disambiguation)

saraswatiRouterProvider → SaraswatiRouter

saraswatiChatProvider → SaraswatiChatNotifier
    (service, entryService, router, entryExecutor, financialContext)

saraswatiProcessingProvider → bool (isProcessing flag)
saraswatiEntryExecutorProvider → EntryExecutor (for undo from UI)
```

---

## SaraswatiMessage Model

```
SaraswatiMessage
├── text: String
├── isUser: bool
├── timestamp: DateTime
└── entryAction: EntryAction?   (non-null for entry pipeline responses)
```

When `entryAction` is non-null, the UI renders `_EntryActionBubble` instead of `_AssistantBubble`.

---

## Chat Notifier Flow

```
User sends message
         |
         v
  SaraswatiChatNotifier.send(query)
         |
         v
  router.classify(query)
         |
    +----+----+--------+
    |         |        |
  ENTRY    QUESTION  AMBIGUOUS
    |         |        |
    v         v        v
  _handleEntry()  _handleQuery()  Try entry; if unrecognized → try query
    |              |
    v              v
  entryService    service.ask()
  .processEntry()     |
    |              v
    v         Add SaraswatiMessage(text: reply)
  EntryAction
    |
    +── SilentCommit → _autoCommit(draft)
    |     ├── entryExecutor.commit(draft) → txnId
    |     ├── entryService.cacheConfirmedEntry()
    |     └── Add message with entryAction + "Logged ₹X category"
    |
    +── AskOneQuestion → Add message with entryAction + questionText
    |     (UI renders chips; user taps chip → confirmEntryField())
    |
    +── QuickFormFallback → Add message; UI auto-opens QuickAddSheet
```

### Chip Confirmation Flow

```
User taps chip
         |
         v
  SaraswatiChatNotifier.confirmEntryField(action, field, value)
         |
         v
  Apply field to partialDraft (copyWith, confidence → 1.0)
         |
         v
  entryExecutor.commit(updatedDraft)
         |
         v
  entryService.cacheConfirmedEntry()
         |
         v
  Add SilentCommitAction message (shows undo)
```

### Undo Flow

```
User taps "Undo" within 5 seconds
         |
         v
  SaraswatiChatNotifier.undoLastEntry()
         |
         v
  entryExecutor.undo(lastCommittedTxnId)
  = repo.deleteTransaction(txnId)
         |
         v
  _lastCommittedTxnId = null
  return true → UI shows "Entry undone" snackbar
```

---

## UI Components

### Empty State

```
┌─────────────────────────────────────┐
│         ⚡ (black rounded square)    │
│                                     │
│       Hi, I'm Saraswati             │
│  Ask about finances or log expenses │
│                                     │
│  QUICK LOG                          │
│  ┌─────────────────────────────┐    │
│  │ ↗ 100 coffee               │    │  green bg, green text
│  ├─────────────────────────────┤    │
│  │ ↗ 500 grocery              │    │
│  ├─────────────────────────────┤    │
│  │ ↗ split 600 with rahul     │    │
│  └─────────────────────────────┘    │
│                                     │
│  ASK SARASWATI                      │
│  ┌─────────────────────────────┐    │
│  │ How much did I spend... →   │    │  white bg, gray border
│  ├─────────────────────────────┤    │
│  │ Show spending by category → │    │
│  ├─────────────────────────────┤    │
│  │ Compare this vs last month →│    │
│  └─────────────────────────────┘    │
└─────────────────────────────────────┘
```

- Entry cards: catGreenBg, green border (30% opacity), catGreenText
- Query cards: white, gray200 border, black text
- Staggered entrance animation: fadeIn + slideY, 80ms per card

### Input Bar

```
┌────────────────────────────────────────────────┐
│ [  Ask about your finances...  ] [●↑]          │  hint cycles every 4s:
│ [  Log an expense — try "100 coffee"  ] [●↑]   │  "Ask..." ↔ "Log..."
└────────────────────────────────────────────────┘  pauses when typing
```

### SilentCommit Bubble

```
┌─────────────────────────────────────────┐
│ █  ✓ Logged ₹100 food                  │  green bg, green left border
│ █                                       │  check icon scales in (easeOutBack)
│ █  [ Undo ━━━━━━━━━ ]                  │  pill: gray100 bg, progress bar shrinks 5s
└─────────────────────────────────────────┘  fades out when timer expires
```

### AskOneQuestion Bubble

```
┌─────────────────────────────────────────┐
│  What category is this?                 │  offWhite bg (no green — it's asking)
│                                         │
│  [food] [transport] [rent] [Other]      │  chips: 36px min height, 12px radius
└─────────────────────────────────────────┘  scale(0.96) press, staggered entrance
```

### Bubble Animations

- **Assistant + Entry bubbles**: `.animate().fadeIn(250ms).slideY(begin: 0.03, 250ms, easeOutCubic)`
- **User bubbles**: No animation (feel instant)
- **Chips**: Staggered `.animate().fadeIn(50ms * i, 150ms).slideY(begin: 0.1, 50ms * i, 150ms)`
- **Checkmark icon**: `.animate().scale(begin: 0.5, 150ms, easeOutBack)`
- **Empty state cards**: Staggered `.animate().fadeIn(80ms * i, 500ms).slideY(begin: 0.05, 80ms * i, 500ms)`

---

## File Inventory

### New Files (16 source + 7 test)

| File | Lines | Purpose |
|------|-------|---------|
| `lib/services/saraswati/entry/transaction_draft.dart` | ~180 | Core TransactionDraft type |
| `lib/services/saraswati/entry/entry_action.dart` | ~42 | Sealed EntryAction hierarchy |
| `lib/services/saraswati/entry/entry_normalizer.dart` | ~10 | Input normalization |
| `lib/services/saraswati/entry/quickadd_matcher.dart` | ~280 | 15 regex patterns (Stage 0) |
| `lib/services/saraswati/entry/pattern_matcher.dart` | ~150 | 5 fuzzy templates (Stage 1) |
| `lib/services/saraswati/entry/entry_cache_repository.dart` | ~100 | SQLite cache (Stage 2) |
| `lib/services/saraswati/entry/personal_defaults_repository.dart` | ~65 | Learned user patterns |
| `lib/services/saraswati/entry/amount_sanity_checker.dart` | ~45 | Amount validation |
| `lib/services/saraswati/entry/disambiguation_engine.dart` | ~180 | 7-rule decision matrix |
| `lib/services/saraswati/entry/entry_executor.dart` | ~95 | DB commit with audit |
| `lib/services/saraswati/entry/llm/entry_function_schema.dart` | ~100 | Gemini function schema |
| `lib/services/saraswati/entry/llm/entry_extractor_prompt.dart` | ~80 | System prompt |
| `lib/services/saraswati/entry/llm/llm_entry_extractor.dart` | ~140 | Gemini wrapper |
| `lib/services/saraswati/saraswati_router.dart` | ~60 | Question vs Entry router |
| `lib/services/saraswati/saraswati_entry_service.dart` | ~110 | Entry pipeline orchestrator |

### Modified Files (4)

| File | Changes |
|------|---------|
| `lib/data/db.dart` | v12→v13, 2 new columns, 2 new tables in migration |
| `lib/providers/saraswati_providers.dart` | Entry providers, SaraswatiMessage.entryAction, router wiring in ChatNotifier |
| `lib/services/saraswati/saraswati_service.dart` | Unchanged (router lives in providers) |
| `lib/pages/saraswati/saraswati_page.dart` | EntryActionBubble, dual empty state, rotating hint, undo pill, tactile chips, animations |

### Test Files (7)

| File | Test Count | Coverage |
|------|------------|----------|
| `transaction_draft_test.dart` | 34 | JSON round-trip, copyWith, uncertainFields, missingRequiredFields |
| `quickadd_matcher_test.dart` | 42 | All 15 patterns + metadata checks |
| `pattern_matcher_test.dart` | 13 | All 5 templates + priority + metadata |
| `llm_entry_extractor_test.dart` | 11 | Kind parsing, date resolution, error scenarios |
| `disambiguation_engine_test.dart` | 19 | Every row of decision matrix + AmountSanityChecker |
| `saraswati_router_test.dart` | 25 | Entry/question/ambiguous classification |
| `smoke_entries_test.dart` | 55 | 50+ mixed inputs, adversarial cases, routing |

**Total: 248 tests, all passing. Zero regressions on pre-existing 53 tests.**

---

## Confidence Thresholds

| Source | Confidence | Meaning |
|--------|------------|---------|
| Quickadd match | 0.95 | Explicit regex match on known keyword |
| Pattern match | 0.90 | Fuzzy template match |
| Personal default applied | 0.90 | Learned from 1+ prior commits |
| LLM explicit extraction | 0.95 | LLM said it's clearly stated |
| LLM inference | 0.75-0.90 | LLM inferred from context |
| LLM guess | < 0.70 | LLM is uncertain — triggers ask |
| User chip confirmation | 1.00 | User explicitly selected value |

**Silent commit threshold: all required fields >= 0.85, amount sane, kind != split.**

---

## Hard Constraints (from original brief)

1. Never silently commit a draft with any field below confidence 0.85
2. Never silently commit splits — always require explicit confirmation
3. Every chat-created transaction is reversible (5s undo, hard delete anytime)
4. Every chat-created transaction is audited (source, rawInput, extractionMeta)
5. Amount sanity: reject amounts < 1, > 500K, or > 1.5x user's historical max
6. No LLM-generated SQL — all writes through BaseRepository
7. Offline: Stages 0-1 work, Stage 3 degrades to QuickFormFallback
