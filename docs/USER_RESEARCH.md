# User Research: Spendler Onboarding Usability Testing

> **Date:** 2026-05-10
> **Method:** Moderated usability testing (simulated)
> **Participants:** 10 hypothetical users
> **Flow tested:** 11-screen onboarding (Currency → Completion)
> **Device:** iPhone 15 Pro, iOS 17

---

## Study Objectives

1. Can users complete the onboarding flow without confusion or friction?
2. Where do users hesitate, abandon, or express frustration?
3. Are labels, copy, and UI patterns self-explanatory?
4. Do users understand optional vs. required steps?
5. How long does the full onboarding take?

---

## Participant Profiles

| # | Name | Age | Occupation | Finance Tracking Experience | Device Comfort |
|---|------|-----|-----------|---------------------------|----------------|
| P1 | Ananya | 24 | UX Designer | Uses spreadsheets | High |
| P2 | Rohit | 31 | Sales Manager | Tried 3 apps, dropped all | High |
| P3 | Priya | 19 | College Student | Never tracked finances | Medium |
| P4 | Vikram | 45 | Business Owner | Uses Tally for business, nothing personal | Medium |
| P5 | Sneha | 28 | Freelance Writer | Used Walnut briefly | High |
| P6 | Arjun | 35 | Software Engineer | Built own spreadsheet | High |
| P7 | Kavita | 52 | Teacher | No finance tracking ever | Low |
| P8 | Dev | 22 | Marketing Intern | Uses Notes app to log expenses | Medium |
| P9 | Meera | 38 | Doctor | Used Money Manager for 6 months | Medium |
| P10 | Sameer | 26 | Delivery Executive | Low literacy, uses phone for UPI only | Low |

---

## Test Protocol

**Setup:** Think-aloud protocol. Participants narrate thoughts while completing onboarding.

**Task:** "You just downloaded Spendler. Set it up completely. Talk through what you're thinking as you go."

**Metrics tracked:**
- Task completion rate per screen
- Time per screen
- Errors / mis-taps
- Verbal confusion ("what does this mean?")
- Emotional markers (delight, frustration, boredom)

---

## Session Results

### Test 1 — Ananya (24, UX Designer)

**Completion:** Full flow completed
**Total time:** 4m 12s
**Issues:**

| Screen | Observation | Severity |
|--------|-------------|----------|
| 1 — Currency | "Oh nice, it detected INR automatically. Smart." | Positive |
| 4 — Category Budgets | "Wait, what's the difference between this and the monthly budget I just set? Is this a subset?" Paused 8 seconds. | 🟡 Moderate |
| 7 — Smart Rules | "I love this concept but I'd need to use the app first to know what keywords I'd want." Skipped. | 🟢 Minor |
| 11 — Completion | "Create Account — does this require email? I hope not, I just want to try it first." Hesitated. | 🟡 Moderate |

**Quote:** "The Category Budgets step confused me because I didn't know if it was carving up my ₹10k or separate from it."

---

### Test 2 — Rohit (31, Sales Manager)

**Completion:** Full flow completed
**Total time:** 5m 45s
**Issues:**

| Screen | Observation | Severity |
|--------|-------------|----------|
| 2 — Accounts | Added "HDFC" — logo appeared. "Oh that's cool!" Added "Paytm". Tried to add a second Cash account. Couldn't. Confused briefly. | 🟢 Minor |
| 3 — Budget | Tapped ₹50k pill. Then tapped the number to edit. "Can I type 35,000?" Typed 35000 successfully. | Positive |
| 5 — Categories | Scrolled quickly. "Yeah yeah, I'll look at these later." Tapped Continue in 3 seconds. | 🟢 Minor |
| 8 — Savings Goals | "I want to save for a car but there's no car icon." Selected Vehicle (bike icon). Seemed slightly dissatisfied. | 🟢 Minor |

**Quote:** "The preset chips for recurring payments saved me time — I just tapped Netflix, Gym, and Rent and filled in amounts."

---

### Test 3 — Priya (19, College Student)

**Completion:** Abandoned at screen 7 (Smart Rules), then resumed after prompt
**Total time:** 7m 30s (with pause)
**Issues:**

| Screen | Observation | Severity |
|--------|-------------|----------|
| 3 — Budget | "I don't really have a budget... I just spend whatever my parents send." Set ₹5000 (default). | 🟢 Minor |
| 4 — Category Budgets | "I don't know how much I spend on food vs transport." Tapped Skip. | Expected |
| 7 — Smart Rules | "What's a keyword? Like a hashtag?" Read explainer card twice. "I don't get it." Closed app. | 🔴 Critical |
| 10 — Notifications | Enabled all three. "Yeah I need reminders or I'll forget." | Positive |

**Quote:** "The Smart Rules screen lost me. I don't know what transactions I'll have yet. Maybe show this later?"

---

### Test 4 — Vikram (45, Business Owner)

**Completion:** Full flow completed
**Total time:** 6m 20s
**Issues:**

| Screen | Observation | Severity |
|--------|-------------|----------|
| 1 — Currency | Detected INR. Tried to scroll list anyway. "Where's the search?" Found it. | 🟢 Minor |
| 2 — Accounts | "I want to add my business account separately. Is there a Business type?" Only sees Cash/UPI. | 🟡 Moderate |
| 6 — Track Income | "Obviously yes. My income is irregular, will it handle that?" No answer on screen. | 🟡 Moderate |
| 9 — Recurring | Added Electricity, Internet, Insurance. "I pay insurance quarterly, not monthly." Selected Yearly as closest. | 🟡 Moderate |

**Quote:** "I need a Quarterly frequency option. Not everything is monthly or yearly."

---

### Test 5 — Sneha (28, Freelance Writer)

**Completion:** Full flow completed
**Total time:** 4m 50s
**Issues:**

| Screen | Observation | Severity |
|--------|-------------|----------|
| 2 — Accounts | "I have 3 bank accounts. Can I add all?" Added HDFC, ICICI, Kotak. All got logos. Delighted. | Positive |
| 4 — Category Budgets | Added Food ₹8000, Shopping ₹5000. "This is adding up... am I overspending my budget?" Saw allocation bar go to 130%. "Oh it warns me. Good." | Positive |
| 7 — Smart Rules | Added "zomato → Food & Drink", "uber → Transport". "This is genius for my UPI transactions." | Positive |
| 8 — Savings Goals | "How do I add money to this goal later? I see a target but no 'deposit' button." | 🟡 Moderate |

**Quote:** "I wish it told me WHERE I'll add money to goals later. I'm setting this up but I don't know how to use it."

---

### Test 6 — Arjun (35, Software Engineer)

**Completion:** Full flow completed
**Total time:** 3m 40s (fastest)
**Issues:**

| Screen | Observation | Severity |
|--------|-------------|----------|
| 3 — Budget | Immediately tapped number, typed "75000". "Good, I can enter custom." | Positive |
| 5 — Categories | "40 categories, that's plenty. But I'd want to add 'SIP' and 'Mutual Funds'." Looked for Add button. Didn't find one on this screen. | 🟡 Moderate |
| 7 — Smart Rules | Added 5 rules in 40 seconds. Power user behavior. "Can I bulk import rules later?" | 🟢 Minor |
| 11 — Completion | "I don't want to create an account yet. Where's 'Use without account'?" | 🔴 Critical |

**Quote:** "Forced account creation is a dealbreaker for me. Let me try the app first."

---

### Test 7 — Kavita (52, Teacher)

**Completion:** Completed with difficulty
**Total time:** 9m 15s (slowest)
**Issues:**

| Screen | Observation | Severity |
|--------|-------------|----------|
| 1 — Currency | "Choose your currency... what's this for?" Didn't understand why app needed this. Read subtitle. "Oh okay." | 🟢 Minor |
| 2 — Accounts | "What is UPI?" Didn't know the term. Added nothing beyond Cash. | 🟡 Moderate |
| 3 — Budget | "How much do I spend? I don't know. Maybe ₹10,000?" Selected default. | Expected |
| 4 — Category Budgets | Stared at screen for 12 seconds. Tapped Skip. | Expected |
| 7 — Smart Rules | "I don't understand this at all." Tapped Skip immediately. | Expected |
| 10 — Notifications | "What's a push notification?" Turned off master toggle to be safe. | 🟡 Moderate |

**Quote:** "Too many steps. I just want to write down what I spent today."

---

### Test 8 — Dev (22, Marketing Intern)

**Completion:** Full flow completed
**Total time:** 5m 10s
**Issues:**

| Screen | Observation | Severity |
|--------|-------------|----------|
| 2 — Accounts | Added GPay. Logo appeared. "Nice touch!" | Positive |
| 6 — Track Income | "No, just expenses — I get a fixed salary, I know what comes in." Selected No. | Expected |
| 8 — Savings Goals | Added "PS5" ₹55,000, ₹5000/mo. "11 months — that's accurate!" | Positive |
| 9 — Recurring | "YouTube Premium... Spotify... that's it for me." Added 2 via presets. | Positive |

**Quote:** "The whole flow took 5 minutes. That's reasonable. I've seen worse."

---

### Test 9 — Meera (38, Doctor)

**Completion:** Full flow completed
**Total time:** 5m 55s
**Issues:**

| Screen | Observation | Severity |
|--------|-------------|----------|
| 2 — Accounts | "I want Credit Card as an account type." Only sees Cash/UPI. "All my spending is on credit cards." | 🔴 Critical |
| 4 — Category Budgets | Added 4 budgets. Tried to reorder them. Couldn't. | 🟢 Minor |
| 9 — Recurring | "My maid's salary is recurring but it's not a bill or subscription. Where does that go?" Used manual add, category "Miscellaneous". | 🟡 Moderate |
| 11 — Completion | Read trust points. "Private and encrypted — good. But is it really?" | Neutral |

**Quote:** "No credit card option is a big miss. That's where 80% of my spending happens."

---

### Test 10 — Sameer (26, Delivery Executive)

**Completion:** Abandoned at screen 4 (Category Budgets)
**Total time:** 3m 20s (abandoned)
**Issues:**

| Screen | Observation | Severity |
|--------|-------------|----------|
| 1 — Currency | Tapped INR immediately. No issue. | Positive |
| 2 — Accounts | Typed "PhonePe". Logo appeared. "Sahi hai!" (That's right!) | Positive |
| 3 — Budget | Confused by "monthly budget" concept. Selected ₹10k because it was highlighted. | Expected |
| 4 — Category Budgets | "Ye kya hai?" (What is this?) — completely lost. The word "allocation" and "category group" felt like English exam. Closed app. | 🔴 Critical |

**Quote:** "Bahut zyada English hai. Mujhe bas likhna hai kitna kharch hua." (Too much English. I just want to write how much I spent.)

---

## Quantitative Summary

### Task Completion Rate

| Screen | Completed | Skipped | Abandoned | Completion Rate |
|--------|-----------|---------|-----------|-----------------|
| 1 — Currency | 10 | 0 | 0 | 100% |
| 2 — Accounts | 10 | 0 | 0 | 100% |
| 3 — Budget | 10 | 0 | 0 | 100% |
| 4 — Category Budgets | 7 | 2 | 1 | 70% proceed / 20% skip / 10% abandon |
| 5 — Categories | 10 | 0 | 0 | 100% |
| 6 — Track Income | 9 | 0 | 0 | 100% (of remaining) |
| 7 — Smart Rules | 6 | 3 | 0 | 67% engage / 33% skip |
| 8 — Savings Goals | 7 | 2 | 0 | 78% engage / 22% skip |
| 9 — Recurring | 8 | 1 | 0 | 89% engage / 11% skip |
| 10 — Notifications | 9 | 0 | 0 | 100% |
| 11 — Completion | 8 | 0 | 1* | 89% (*1 objected to forced account) |

### Average Time Per Screen

| Screen | Avg Time | Notes |
|--------|----------|-------|
| 1 — Currency | 18s | Fast — auto-detection helps |
| 2 — Accounts | 45s | Varies by # of accounts added |
| 3 — Budget | 22s | Quick — presets work |
| 4 — Category Budgets | 55s | Longest when engaged; skip if confused |
| 5 — Categories | 12s | Fastest — just scroll and continue |
| 6 — Track Income | 8s | Binary choice, instant |
| 7 — Smart Rules | 48s | High variance — power users engage deeply |
| 8 — Savings Goals | 40s | Moderate — form filling |
| 9 — Recurring | 35s | Preset chips accelerate |
| 10 — Notifications | 10s | Toggle and go |
| 11 — Completion | 15s | Read + tap |

**Average total time: 5m 28s** (range: 3m 40s to 9m 15s)

---

## Severity Classification

### 🔴 Critical (3 findings)

| Finding | Users Affected | Impact |
|---------|---------------|--------|
| **Smart Rules concept is incomprehensible to novice users** | P3, P7, P10 (30%) | Causes abandonment or deep confusion. The concept requires existing transaction history to be useful. |
| **No "Use without account" option on Completion screen** | P6 (10%) + latent risk for privacy-conscious users | Forced account creation is a trust barrier. Users want to try before committing. |
| **No Credit Card account type** | P9 (10%) + high latent demand | Credit card users (a huge segment) can't properly model their financial setup. UPI-only is too narrow. |

### 🟡 Moderate (7 findings)

| Finding | Users Affected | Recommendation |
|---------|---------------|----------------|
| Category Budgets relationship to Monthly Budget unclear | P1, P4 | Add subtitle: "Divide your ₹X budget across categories" |
| No Quarterly frequency for recurring payments | P4 | Add `quarterly` to PaymentFrequency enum |
| "What is UPI?" — term not universally understood | P7, P10 | Rename to "Digital/Bank" or add subtitle explanation |
| No explanation of what happens AFTER goals are set | P5 | Add helper text: "You'll log contributions from the home screen" |
| No custom category creation on Categories Overview | P6 | Add "+ Add category" with simple name input |
| Category Budgets screen jargon too complex for low-literacy users | P10 | Simplify copy; consider localization |
| Track Income doesn't explain how irregular income works | P4 | Add one line: "Works for salary, freelance, or irregular income" |

### 🟢 Minor (6 findings)

| Finding | Notes |
|---------|-------|
| Vehicle icon represents bike, no car icon | Add car icon to goal_icons |
| Can't add second Cash account | Expected — system design |
| Categories screen scrolled through too fast | Informational only, expected |
| "Bulk import rules" not available | Power user request, post-launch |
| Can't reorder category budgets | Nice-to-have, low impact |
| Progress bar shows 8 steps but 11 screens exist | Already resolved — logical grouping |

---

## Affinity Map: Key Themes

### Theme 1: "Let me try first" (Trust barrier)
- P6: "Forced account creation is a dealbreaker"
- P11 (implied): Privacy-conscious users want local-only mode
- **Insight:** Add "Continue without account" option on completion screen. Save locally. Prompt for account later.

### Theme 2: "I don't know yet" (Premature complexity)
- P3: Smart Rules require transaction history
- P7: Category Budgets need spending awareness
- P10: Allocation concept is too abstract
- **Insight:** Move Smart Rules and Category Budgets to post-onboarding (Settings). Keep onboarding to: Currency → Accounts → Budget → Income → Notifications → Done.

### Theme 3: "My money doesn't work like that" (Model gaps)
- P9: No credit card type
- P4: No quarterly frequency
- P4: Irregular income uncertainty
- **Insight:** Expand account types (Credit Card, Bank, Digital Wallet). Add quarterly to frequency. Show income flexibility.

### Theme 4: "This is too much English" (Accessibility/Literacy)
- P10: Jargon-heavy labels ("allocation", "category group")
- P7: "Push notification" not understood
- **Insight:** Use simpler language. Consider Hindi/regional language support. Replace "allocation" with "split".

### Theme 5: "That's a nice touch" (Delight moments)
- P1, P2, P5, P8, P10: Brand logo detection on account creation
- P2, P8: Preset chips for recurring payments
- P5: Over-allocation warning on budget bar
- P8: Months-remaining calculation on goals
- **Insight:** Logo detection and presets are viral-worthy features. Highlight in marketing.

---

## Jobs to Be Done

| Job | Evidence | Screen |
|-----|----------|--------|
| "Help me not think about how to categorize" | Smart Rules love from P5, P6 | 7 |
| "Show me I'm making progress" | Goal progress bar delight from P8 | 8 |
| "Don't make me remember recurring bills" | Preset chips save time for P2, P8 | 9 |
| "Just let me start simple" | P3, P7, P10 want fewer steps | All |
| "Recognize my banks/apps" | Logo detection delighted 5/10 users | 2 |

---

## Priority Recommendations

### P0 — Ship Blockers

1. **Add "Continue without account" on Completion screen**
   - Change "Create Account" to primary CTA
   - Add "Skip for now" as ghost button below → navigates to home with local-only storage
   - Re-prompt for account after 7 days of use

2. **Add Credit Card account type**
   - Add `creditCard` to `AccountType` enum
   - Icon: `Icons.credit_card_outlined`
   - No balance tracking needed — same model, different label

### P1 — Pre-Launch Improvements

3. **Simplify Category Budgets subtitle**
   - Current: "Set spending limits per category group. Optional — add more later."
   - Proposed: "Split your ₹[budget] across categories. Optional."

4. **Add Quarterly to PaymentFrequency**
   - Enum addition: `quarterly`
   - Display: "/qtr"

5. **Rename "UPI" to "Digital" in account type selector**
   - More inclusive — covers bank apps, wallets, UPI all

### P2 — Post-Launch

6. **Move Smart Rules to post-onboarding**
   - Remove from onboarding flow (reduce to 7 logical steps)
   - Surface in Settings → Smart Rules after user has 10+ transactions
   - Show contextual prompt: "You've logged 'Zomato' 5 times — want to auto-categorize it?"

7. **Add localization foundation**
   - Extract all user-facing strings to arb/l10n files
   - Hindi as first additional language (covers P10's need)

---

## Highlight Reel

> "The Category Budgets step confused me because I didn't know if it was carving up my ₹10k or separate from it." — **Ananya, P1**

> "Smart Rules is genius for my UPI transactions... zomato → Food, uber → Transport." — **Sneha, P5**

> "Forced account creation is a dealbreaker. Let me try the app first." — **Arjun, P6**

> "Too many steps. I just want to write down what I spent today." — **Kavita, P7**

> "No credit card option is a big miss. That's where 80% of my spending happens." — **Meera, P9**

> "Bahut zyada English hai." (Too much English.) — **Sameer, P10**

> "The preset chips for recurring payments saved me time." — **Rohit, P2**

> "Oh nice, it detected INR automatically. Smart." — **Ananya, P1**

---

## Next Steps

| Action | Owner | Timeline |
|--------|-------|----------|
| Add "Skip for now" on completion screen | Engineering | This sprint |
| Add Credit Card account type | Engineering | This sprint |
| Simplify Category Budgets copy | Design | This sprint |
| Add Quarterly frequency | Engineering | Next sprint |
| Rename UPI → Digital | Design + Engineering | Next sprint |
| Evaluate removing Smart Rules from onboarding | Product | Next sprint |
| Localization audit + Hindi strings | Design + Engineering | Next month |
| Real usability testing with 5 participants | Research | Next month |
