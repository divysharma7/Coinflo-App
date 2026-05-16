# Changelog

## [Unreleased]

### Added
- Bulk bank statement import for HDFC, ICICI, SBI, Axis, and Kotak (CSV)
- 6-stage on-device categorization cascade (SmartRules, personal merchant map, shipped dictionary, UPI parser, rule engine, ML stub)
- Personal merchant learning loop with backfill across past transactions
- Recurring transaction detection (subscriptions, EMIs)
- Anomaly detection (per-category IQR-based outliers)
- Import flow UI with 6 screens (Select bank, Upload, Processing, Review, Summary, History)
- Entry points: onboarding (optional step), home empty banner, reports empty banner, settings
- Drift schema migration v6 → v7 with new tables (MerchantMappings, CorrectionEvents, ImportBatches)
- 4 new TransactionCategory values: income, cash, investments, insurance

### Changed
- CategoryClassifier now uses the cascade first, falls back to Gemini only for unknown merchants
- TransactionCategory enum extended with income, cash, investments, insurance values
- AppColors category accent map expanded with 4 new colors

### Performance
- All heavy import work runs in Isolate.run() — UI stays responsive at 60fps
- Batched Drift inserts (100 per batch) wrapped in single DB transaction for atomicity
- Merchant dictionary loaded once at app start, cached in memory
- Regex patterns pre-compiled at service construction, not per-transaction
