# Import Module Architecture

## Overview

The bulk bank statement import module solves the "Day 1 empty app" problem. A new CoinFlo user uploads a 6-month bank statement (CSV), and within ~30 seconds the app parses ~1500 transactions, categorizes 80%+ using a fully on-device cascade (no internet required), detects subscriptions and anomalies, and backfills budgets with real spending baselines. After import, the user lands on a populated home screen with real data.

**Critical constraint:** 100% on-device. No Gemini, no Firebase ML, no API calls during import.

## Architecture at a Glance

```
                         ┌─────────────────────────────────┐
                         │         MAIN THREAD             │
                         └─────────────────────────────────┘
                                      │
                    ┌─────────────────┼─────────────────┐
                    ▼                 ▼                  ▼
           ┌──────────────┐  ┌──────────────┐  ┌──────────────┐
           │  Read file   │  │ Prefetch DB  │  │ Load dict    │
           │  (CSV bytes) │  │ (hashes,     │  │ (merchant    │
           │              │  │  mappings,   │  │  entries)    │
           │              │  │  rules,      │  │              │
           │              │  │  historical) │  │              │
           └──────┬───────┘  └──────┬───────┘  └──────┬───────┘
                  │                  │                  │
                  └──────────────────┼──────────────────┘
                                     │
                         ┌───────────▼───────────┐
                         │    Isolate.run()      │
                         │                       │
                         │  Parse (BankAdapter)  │
                         │  Normalize + Dedup    │
                         │  Categorize (Cascade) │
                         │  Detect Recurring     │
                         │  Detect Anomalies     │
                         │                       │
                         └───────────┼───────────┘
                                     │
                         Returns: ProcessedBatch
                                     │
                         ┌───────────▼───────────┐
                         │     MAIN THREAD       │
                         │                       │
                         │  db.transaction {     │
                         │    Insert ImportBatch  │
                         │    db.batch() txns    │
                         │  }                    │
                         │  SELECT for dbIds     │
                         │                       │
                         └───────────────────────┘
```

**Key design decision:** The isolate has ZERO Drift/DB coupling. All data needed for categorization is prefetched on the main thread and passed in as plain Dart objects. The isolate returns a `ProcessedBatch` which the main thread persists atomically.

## The 6-Stage Cascade

For each transaction, stages run in order. Stops at first match with confidence >= 0.65.

| Stage | Name | Source | Expected Hit Rate | Confidence |
|-------|------|--------|-------------------|------------|
| 0 | SmartRules | User-authored keyword rules (existing SmartRules table) | 5-10% | 1.0 |
| 1 | Personal Merchant Map | User corrections from MerchantMappings (source=userCorrected) | 10-20% (grows over time) | 1.0 |
| 2 | Shipped Dictionary | Pre-loaded from assets/data/indian_merchants.json | 40-50% | 0.8-0.95 |
| 3 | UPI VPA Parser | VPA pattern matching, P2P detection (UPI channel only) | 10-15% | 0.85-0.9 |
| 4 | Rule Engine | Pre-compiled regex patterns for Indian banking | 15-20% | 0.9-1.0 |
| 5 | ML Fallback (STUB) | Returns uncategorized. Placeholder for v2 Naive Bayes. | 0% | 0.0 |

**Confidence threshold:** If final confidence < 0.65, transaction is marked uncategorized and queued for user review.

## Bank Adapter Reference

| Bank | Detection Signature | Date Format(s) | Format Variants | Key Quirks |
|------|--------------------|-----------------|--------------------|------------|
| HDFC | `Narration` + `Closing Balance` | dd/MM/yy (2-digit year) | Single format | "Value Dat" (truncated column name) |
| ICICI | `Transaction Date` + (`Description` OR `Transaction Remarks`) + (`Debit` OR `Withdrawal Amount`) | dd/MM/yyyy (4-digit year) | Format A (iMobile), Format B (Legacy with different column names) | Preamble up to 12 lines; quoted fields with internal commas |
| SBI | `Txn Date` + `Description` + (`Debit` OR `Withdrawal` OR `Amount`) | dd MMM yyyy, dd-MMM-yy, dd/MM/yyyy | Format A (YONO), Format B (Legacy tab-separated), Format C (Amount with Dr/Cr suffix) | Text-month parsing (locale-independent hardcoded map); tab delimiter detection; 0/0 row skipping |
| Axis | (`PARTICULARS` OR `Description` OR `Narration`) + (`SOL` OR `Sol ID` OR `Branch Code`) | dd-MM-yyyy | Standard + Variant (tolerant column alias matching) | SOL column unique to Axis; exact-match alias resolution to avoid substring collisions |
| Kotak | `Sl. No.` + (`Dr / Cr` OR `Dr/Cr`) | dd/MM/yyyy | Format A only (single Amount + separate Dr/Cr indicator column) | Throws FormatException on unexpected Dr/Cr values; serial number column skipped |

## How to Add a New Bank

1. **Obtain a real CSV export** from the target bank (multiple export paths if available)
2. **Identify detection signature** — column names unique to that bank that won't collide with existing adapters
3. **Create** `lib/services/import/bank_adapters/{bank}_adapter.dart` following `hdfc_adapter.dart` structure:
   - Extend `BankAdapter`
   - Implement `canParse(headerLine)` with the detection signature
   - Implement `parse(csvContent)` with preamble scanning, column resolution, date parsing, amount parsing
4. **Add to BankDetector** (`bank_detector.dart`) — order matters: most-specific signature first
5. **Create** `test/fixtures/{bank}_sample.csv` with 15+ realistic transactions covering debit/credit mix, UPI, NEFT, ATM, salary, EMI
6. **Create** `test/services/import/{bank}_adapter_test.dart` following existing test structure:
   - `canParse` group (positive, negative, case-insensitive)
   - Parsing group (count, dates, amounts, types, references)
   - Regression group (other bank fixtures NOT misdetected)
   - Edge cases (empty, header-only)
7. **Add to** `BankType` enum (`lib/core/enums.dart`) and `SelectBankPage` grid

## How to Extend the Rule Engine

File: `lib/services/categorization/rule_engine.dart`

1. Add a new `_Rule(RegExp(...), 'categoryEnumName', confidence)` to the `_rules` list
2. Use `caseSensitive: false` on all patterns
3. Map to an existing `TransactionCategory` enum value name (string)
4. **Test word-order carefully** — real bank descriptions have CR/DR/NEFT/UPI prefixes before the keyword. Test your pattern against descriptions from all 5 bank fixtures. See the audit TODO in `test/services/categorization/rule_engine_test.dart`.
5. Add test cases in `rule_engine_test.dart` for each new pattern

## How to Add Merchants to the Dictionary

File: `assets/data/indian_merchants.json`

Schema (top-level JSON array):
```json
[
  {
    "token": "swiggy",
    "category": "foodAndDrink",
    "confidence": 0.95,
    "aliases": ["swggy", "swigy"]
  }
]
```

Fields:
- `token` — normalized, lowercase, alphanumeric merchant identifier (matches the `merchantToken` extracted by `TransactionNormalizer`)
- `category` — `TransactionCategory` enum value name (e.g. "foodAndDrink", "transport")
- `confidence` — 0.0 to 1.0 (minimum 0.65 to pass the threshold)
- `aliases` — optional array of alternate spellings/abbreviations

**Process:** Updates to this file affect every user's categorization. Changes should go through code review with test coverage for new entries.

## Known Limitations and v2 Backlog

- **Stage 5 ML categorization is stubbed** — returns uncategorized. v2 will add on-device Naive Bayes trained on user-corrected data.
- **No PDF parsing** — CSV only. Many banks offer PDF-only exports on mobile.
- **No multi-account import** — one statement file at a time.
- **Generic CSV adapter deferred** — the `Date,Description,Debit,Credit,Balance` pattern is too generic to safely auto-detect. Needs manual bank selection path.
- **Real-world bank statement fixtures pending** — current test fixtures are synthetic. Real exports have edge cases around locale formatting, mid-file section breaks, and bank-specific disclaimers.
- **Rule engine word-order audit** — some regex patterns may miss matches when CR/DR indicators appear before keywords.
