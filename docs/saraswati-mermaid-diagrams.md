# Saraswati Entry Pipeline — Mermaid Diagrams

## 1. High-Level Architecture

```mermaid
flowchart TD
    A[User types in Saraswati chat] --> B{SaraswatiRouter.classify}
    B -->|QUESTION| C[SaraswatiService.ask]
    B -->|ENTRY| D[SaraswatiEntryService.processEntry]
    B -->|AMBIGUOUS| E{Try entry first}

    C --> F[IntentExecutor.execute]
    F --> G[Markdown response in chat]

    D --> H[4-Stage Extraction Pipeline]
    H --> I[PersonalDefaults.apply]
    I --> J{DisambiguationEngine.evaluate}

    J -->|All confident| K[SilentCommitAction]
    J -->|1 field uncertain| L[AskOneQuestionAction]
    J -->|2+ uncertain / LLM down| M[QuickFormFallbackAction]

    K --> N[EntryExecutor.commit]
    N --> O[(Database insert\naudit-tagged)]
    N --> P[Show undo banner 5s]

    L --> Q[Show chip-based question]
    Q -->|User taps chip| R[confirmEntryField]
    R --> N

    M --> S[Open QuickAddSheet\npre-filled]

    E -->|QuickFormFallback unrecognized| C
    E -->|Valid entry action| J
```

## 2. Router Decision Logic

```mermaid
flowchart TD
    A[Normalized user text] --> B{Contains number +\ntransaction verb?}
    B -->|Yes| C[ENTRY]
    B -->|No| D{Starts with question word?\nOR ends with '?'\nOR contains question phrase?}
    D -->|Yes| E[QUESTION]
    D -->|No| F[AMBIGUOUS]

    F --> G[Try entry pipeline]
    G --> H{Result?}
    H -->|QuickFormFallback\nreason: unrecognized| I[Try query pipeline instead]
    H -->|Valid action| J[Use entry result]

    style C fill:#dcfce7,stroke:#15803d
    style E fill:#dbeafe,stroke:#1d40ae
    style F fill:#fef3c7,stroke:#b45309
```

## 3. 4-Stage Extraction Pipeline

```mermaid
flowchart TD
    A[Normalized input] --> B{Stage 0:\nQuickaddMatcher\n15 regex patterns}
    B -->|Match| C[Draft\nconf 0.95\nsource: quickadd]
    B -->|No match| D{Stage 1:\nPatternMatcher\n5 fuzzy templates}
    D -->|Match| E[Draft\nconf 0.90\nsource: pattern]
    D -->|No match| F{Stage 2:\nEntryCacheRepository\nSQLite lookup}
    F -->|Cache hit| G[Draft\ncarried conf\ndate re-resolved]
    F -->|Cache miss| H{Stage 3:\nLlmEntryExtractor\nGemini 2.0 Flash}
    H -->|Success| I[Draft\nper-field conf\nsource: llm]
    H -->|Timeout / Error\n/ Offline| J[null]

    C --> K[Apply PersonalDefaults]
    E --> K
    G --> K
    I --> K
    J --> K

    K --> L[DisambiguationEngine]

    style C fill:#dcfce7
    style E fill:#dcfce7
    style G fill:#dcfce7
    style I fill:#dcfce7
    style J fill:#fef2f2
```

## 4. Disambiguation Decision Matrix

```mermaid
flowchart TD
    A[Draft from extraction] --> B{Rule 1:\nkind=unknown\nOR draft=null?}
    B -->|Yes| C[QuickFormFallback\nreason: unrecognized]
    B -->|No| D{Rule 2:\nAmount fails sanity?\n< 1 or > 500K\nor > 1.5x historical}
    D -->|Yes| E[AskOneQuestion\nfield: amount]
    D -->|No| F{Rule 3:\n2+ fields missing\nor uncertain < 0.85?}
    F -->|Yes| G[QuickFormFallback\nreason: too_uncertain]
    F -->|No| H{Rule 4:\nkind=split AND\nall fields OK?}
    H -->|Yes| I[AskOneQuestion\nfield: split_with\nSplits ALWAYS confirm]
    H -->|No| J{Rule 5:\nExactly 1 required\nfield missing?}
    J -->|Yes| K[AskOneQuestion\nfield: missing]
    J -->|No| L{Rule 6:\nExactly 1 field\nconf < 0.85?}
    L -->|Yes| M[AskOneQuestion\nfield: uncertain]
    L -->|No| N[SilentCommit\nAll good!]

    style C fill:#fef2f2
    style G fill:#fef2f2
    style E fill:#fef3c7
    style I fill:#fef3c7
    style K fill:#fef3c7
    style M fill:#fef3c7
    style N fill:#dcfce7
```

## 5. Data Model — TransactionDraft

```mermaid
classDiagram
    class TransactionDraft {
        +TransactionKind kind
        +double? amount
        +String? counterparty
        +String? counterpartyId
        +String? category
        +DateTime? date
        +PayerKind? payer
        +List~String~? splitWith
        +String? note
        +String source
        +Map~String, double~ fieldConfidence
        +String rawInput
        +uncertainFields(threshold) List~String~
        +missingRequiredFields() List~String~
        +toJson() Map
        +fromJson(Map) TransactionDraft
        +copyWith() TransactionDraft
        +toExtractionMetaJson() String
    }

    class TransactionKind {
        <<enumeration>>
        expense
        income
        transfer
        split
    }

    class PayerKind {
        <<enumeration>>
        user
        counterparty
        splitEqual
        splitCustom
    }

    class EntryAction {
        <<sealed>>
    }

    class SilentCommitAction {
        +TransactionDraft draft
    }

    class AskOneQuestionAction {
        +TransactionDraft partialDraft
        +String fieldToConfirm
        +String questionText
        +List~String~ chipOptions
    }

    class QuickFormFallbackAction {
        +TransactionDraft? partialDraft
        +String reason
    }

    TransactionDraft --> TransactionKind
    TransactionDraft --> PayerKind
    EntryAction <|-- SilentCommitAction
    EntryAction <|-- AskOneQuestionAction
    EntryAction <|-- QuickFormFallbackAction
    SilentCommitAction --> TransactionDraft
    AskOneQuestionAction --> TransactionDraft
```

## 6. Provider Dependency Graph

```mermaid
flowchart BT
    DB[databaseProvider] --> IC[_intentCacheProvider\nIntentCacheRepository]
    DB --> EC[_entryCacheProvider\nEntryCacheRepository]
    DB --> PD[_personalDefaultsProvider\nPersonalDefaultsRepository]

    REPO[repositoryProvider] --> IE[_intentExecutorProvider\nIntentExecutor]
    REPO --> EE[_entryExecutorProvider\nEntryExecutor]
    PD --> EE

    CM[_classifierModelProvider\nGemini + classifier prompt] --> LC[_llmClassifierProvider\nLlmIntentClassifier]

    EM[_entryExtractorModelProvider\nGemini + entry prompt] --> LE[_llmEntryExtractorProvider\nLlmEntryExtractor]

    IE --> SS[saraswatiServiceProvider\nSaraswatiService]
    IC --> SS
    LC --> SS

    EC --> SES[saraswatiEntryServiceProvider\nSaraswatiEntryService]
    LE --> SES
    PD --> SES

    SS --> CHAT[saraswatiChatProvider\nSaraswatiChatNotifier]
    SES --> CHAT
    EE --> CHAT
    ROUTER[saraswatiRouterProvider] --> CHAT
    FC[saraswatiFinancialContextProvider] --> CHAT

    CHAT --> PROC[saraswatiProcessingProvider\nbool]

    style CHAT fill:#e0e7ff,stroke:#4338ca
    style SS fill:#dbeafe,stroke:#1d40ae
    style SES fill:#dcfce7,stroke:#15803d
```

## 7. Chat Notifier State Flow

```mermaid
stateDiagram-v2
    [*] --> Idle: App starts

    Idle --> Processing: user sends message
    Processing --> Routing: router.classify()

    Routing --> HandleQuery: QUESTION
    Routing --> HandleEntry: ENTRY
    Routing --> TryBoth: AMBIGUOUS

    HandleQuery --> AddReply: service.ask() returns markdown
    HandleEntry --> EvaluateAction: entryService.processEntry()
    TryBoth --> EvaluateAction: entry action valid
    TryBoth --> HandleQuery: entry returned unrecognized

    EvaluateAction --> AutoCommit: SilentCommitAction
    EvaluateAction --> ShowChips: AskOneQuestionAction
    EvaluateAction --> OpenForm: QuickFormFallbackAction

    AutoCommit --> CommitToDB: executor.commit()
    CommitToDB --> ShowUndo: add message + undo banner
    ShowUndo --> Idle: 5s timer or user taps undo

    ShowChips --> WaitForChip: add message with chips
    WaitForChip --> CommitToDB: user taps chip → confirmEntryField

    OpenForm --> Idle: open QuickAddSheet

    AddReply --> Idle: add markdown message
```

## 8. Undo Timeline

```mermaid
sequenceDiagram
    participant U as User
    participant CN as ChatNotifier
    participant EX as EntryExecutor
    participant DB as Database

    U->>CN: send("100 coffee")
    CN->>CN: router → ENTRY
    CN->>CN: entryService.processEntry()
    Note over CN: Stage 0 match → SilentCommit
    CN->>EX: commit(draft)
    EX->>DB: insertTransaction(companion)
    DB-->>EX: txnId = 42
    EX-->>CN: txnId = 42
    CN->>CN: _lastCommittedTxnId = 42
    CN->>U: Show "✓ Logged ₹100 food" + Undo pill

    alt User taps Undo within 5s
        U->>CN: undoLastEntry()
        CN->>EX: undo(42)
        EX->>DB: deleteTransaction(42)
        DB-->>EX: success
        CN->>U: "Entry undone" snackbar
    else 5s timer expires
        CN->>CN: _undoAvailable = false
        CN->>U: Undo pill fades out
    end
```

## 9. Personal Defaults Learning

```mermaid
flowchart LR
    A[User commits\n"split 600 with rahul"] --> B[EntryExecutor._learnDefaults]
    B --> C{counterparty\n= rahul?}
    C -->|Yes| D[updateDefault\nkey: counterparty:rahul\nvalue: splitEqual]
    B --> E{splitWith\nnames?}
    E -->|rahul, priya| F[updateDefault\ncounterparty:rahul → splitEqual\ncounterparty:priya → splitEqual]
    B --> G{counterparty +\ncategory?}
    G -->|zomato + food| H[updateDefault\ncategory_for:zomato → food]

    I[Next time user types\n"500 rahul"] --> J[Extract draft\nkind=expense]
    J --> K[_applyDefaults]
    K --> L{getDefault\ncounterparty:rahul}
    L -->|splitEqual| M[Upgrade to\nkind=split\npayer=splitEqual\nconf 0.90]
```

## 10. Database Schema v13

```mermaid
erDiagram
    SPENDLER_TRANSACTIONS {
        int id PK
        real amount
        text category
        text merchant
        text note
        datetime happened_at
        text source "manual | saraswati_chat | sms"
        text status "confirmed | unconfirmed"
        text txn_type "expense | income | transfer | settlement"
        text raw_input "NEW v13 - original chat text"
        text extraction_meta "NEW v13 - JSON confidence"
        bool is_split
        int split_count
        real split_my_share
        int payer_person_id
        int counterparty_person_id
        int group_id
    }

    SARASWATI_ENTRY_CACHE {
        text normalized_input PK
        text draft_json
        int hit_count
        int created_at
        int last_used_at
        int confirmed_by_user
    }

    SARASWATI_USER_DEFAULTS {
        text key PK "counterparty:name | category_for:merchant"
        text value
        int hit_count
        int updated_at
    }

    SARASWATI_INTENT_CACHE {
        text normalized_query PK
        text intent_json
        int hit_count
        int created_at
        int last_used_at
        int confirmed_by_user
    }

    SPENDLER_TRANSACTIONS ||--o{ SARASWATI_ENTRY_CACHE : "cached drafts"
    SARASWATI_USER_DEFAULTS ||--o{ SPENDLER_TRANSACTIONS : "learned from"
```

## 11. UI Component Tree (Entry Flow)

```mermaid
flowchart TD
    SP[SaraswatiPage] --> LV[ListView.builder]
    SP --> IB[_InputBar\nrotating hint]

    LV --> UB[_UserBubble\nblack bg, right-aligned]
    LV --> AB[_AssistantBubble\noffWhite bg, fadeIn+slideY]
    LV --> EB[_EntryActionBubble\ngreen/offWhite bg, fadeIn+slideY]
    LV --> TI[_TypingIndicator\n3 pulsing dots]

    EB --> SC{SilentCommitAction?}
    SC -->|Yes| CK[✓ Checkmark icon\nscale-in easeOutBack]
    SC -->|Yes| MT[Logged ₹X category]
    SC -->|Yes| UP[_UndoPill\nprogress bar 5s\nfade-out]

    EB --> AQ{AskOneQuestionAction?}
    AQ -->|Yes| QT[Question text]
    AQ -->|Yes| WR[Wrap of _TactileChip]
    WR --> TC1[Chip 1\ndelay 0ms]
    WR --> TC2[Chip 2\ndelay 50ms]
    WR --> TC3[Chip 3\ndelay 100ms]

    EB --> FF{QuickFormFallback?}
    FF -->|Yes| QAS[Auto-open\nQuickAddSheet]

    SP --> ES[_EmptyState\nwhen no messages]
    ES --> QL[QUICK LOG section\ngreen cards, staggered]
    ES --> AS[ASK SARASWATI section\nwhite cards, staggered]

    style EB fill:#dcfce7
    style UP fill:#f0f0f0
    style TC1 fill:#fff,stroke:#e0e0e0
    style TC2 fill:#fff,stroke:#e0e0e0
    style TC3 fill:#fff,stroke:#e0e0e0
```

## 12. Confidence Flow

```mermaid
flowchart LR
    subgraph Extraction
        Q0[Stage 0\nQuickadd\n0.95] --> DRAFT
        Q1[Stage 1\nPattern\n0.90] --> DRAFT
        Q2[Stage 2\nCache\ncarried] --> DRAFT
        Q3[Stage 3\nLLM\n0.5-0.95] --> DRAFT
    end

    DRAFT[TransactionDraft\nfieldConfidence map] --> DEF[PersonalDefaults\napply → raise to 0.90]
    DEF --> DIS{Disambiguation\nthreshold: 0.85}

    DIS -->|All ≥ 0.85\namount sane\nnot split| COMMIT[SilentCommit]
    DIS -->|1 field < 0.85| ASK[AskOneQuestion]
    DIS -->|2+ fields < 0.85| FORM[FormFallback]

    ASK -->|User confirms\nchip tap| CONF[Confidence → 1.0]
    CONF --> COMMIT

    style COMMIT fill:#dcfce7
    style ASK fill:#fef3c7
    style FORM fill:#fef2f2
```
