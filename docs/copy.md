# CoinFlo / Spendler — Copy Reference

## Voice & tone

**Persona:** Saraswati — warm, confident, never preachy.
- First-person when the app speaks ("I found 3 matches")
- Second-person when addressing the user ("Your spending this week")
- Short sentences. No corporate filler. No exclamation-mark abuse.
- Celebrate wins gently ("No spending this period — nice!")
- Errors should feel human, not robotic ("Couldn't delete account. Please try again.")

## Empty states

| Screen | Message | Subtitle |
|--------|---------|----------|
| Home (recent txns) | Nothing here yet | Tap + to log your first spend |
| Daily view (zero spend) | {symbol}0 spent this day. | A clean slate — nothing spent today. |
| Transactions (search) | Nothing matches that search. | Try different words. |
| Transactions (filter) | Nothing matches these filters. | Try loosening up the filters. |
| Subscriptions | No subscriptions tracked yet | Tap + to add your first one. |
| People / Splits | Add someone to start splitting expenses. | — |
| Report (bar chart) | No spending this period — nice! | — |
| Report (category chart) | No spending data yet. | — |
| Report (trend) | Not enough data yet | — |
| Report (category drill) | No {category} spending this month. | — |
| Notifications | All quiet — no notifications yet | — |
| Charts (generic) | No data yet | — |
| Saraswati chat | Hi, I'm Saraswati | Ask me anything about your finances — spending, trends, categories. |

## Snackbars & toasts

| Trigger | Message |
|---------|---------|
| Transaction added | {type} of {symbol}{amount} added |
| Export empty | Nothing to export this month. |
| Export failed | Export failed — please try again. |
| Account delete failed | Couldn't delete account. Please try again. |
| Bug report sent | Thanks for the report — we'll look into it. |
| Firebase signup failed | You're set! Sign in later to enable cloud backup. |
| Transaction confirmed | Transaction confirmed. |

## Onboarding

| Screen | Title | Subtitle |
|--------|-------|----------|
| Accounts | Add your accounts | Where do you keep your money? Add at least one. |
| Categories | We've got you covered | 40 categories already set up. Add more if you need. |
| Budgets | Category Budgets | Set limits per category. Optional — add more later. |
| Completion | You're all set! | Create your account so your data is safely backed up. |

## Button labels

- Primary actions: "Continue", "Save", "Confirm Import"
- Skip: "Skip for now" (never just "Skip")
- Destructive: "Remove", "Delete" (red, with confirmation)
- Settlement: "I Paid", "They Paid", "Mark Settled"
