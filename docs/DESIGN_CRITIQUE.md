# Design Critique: Spendler Onboarding Flow

> **Date:** 2026-05-10
> **Stage:** Refinement — post-implementation audit
> **Focus:** 11-screen onboarding flow (Currency → Completion)

---

## Overall Impression

The flow is well-structured with consistent card-based layouts and good use of the design system. The biggest opportunities were: progress indicator math, hardcoded values leaking through, and inconsistent UX copy across modals/buttons. All critical issues have been resolved.

---

## Usability

| Finding | Severity | Status |
|---------|----------|--------|
| Progress bar had 8 segments for 11 screens — steps 8-11 all showed "full" | Critical | RESOLVED — grouped as 8 logical steps |
| No confirmation on delete actions (goals, payments, rules) | Moderate | Open — consider undo snackbar |
| No visual indication of required vs optional fields in sheets | Moderate | Open |
| "Skip for now" on some screens but not others | Moderate | RESOLVED — standardized |

---

## Visual Hierarchy

- **What draws the eye first**: Title on most screens — correct.
- **Reading flow**: Title → subtitle → content → CTA. Consistent and correct.
- **Emphasis**: All cards now use `AppShadows.sm` consistently. Monthly Budget card shadow fixed.

---

## Consistency

| Element | Issue | Status |
|---------|-------|--------|
| Animation duration | `Duration(milliseconds: 800)` instead of `AppDurations.slow` | FIXED |
| Colors | Hardcoded hex in SmartRules explainer | FIXED — uses `CategoryGroup.iconColor` |
| Fallback color | `Color(0xFF9CA3AF)` in AddPaymentSheet | FIXED — uses `AppColors.gray400` |
| Back button layout | Mix of `Padding` and `Align` | FIXED — standardized to `Padding` |
| Currency in presets | `_presetLabel()` hardcoded `₹` | FIXED — reads from SharedPreferences |
| Number format locale | `'en_IN'` hardcoded | FIXED — uses `NumberFormat.decimalPattern()` |
| Slide offsets | Varied: 0.05, 0.06, 0.08 | FIXED — standardized to 0.05 |
| Button copy | "Save" vs "Add [noun]" | FIXED — "Add Goal", "Add Payment", "Add Budget" |
| Optional screen labels | Some said "Continue" always | FIXED — "Skip for now" when empty |

---

## Accessibility

- **Color contrast**: Black on white passes. Gray500 on white = 4.8:1 (AA pass).
- **Touch targets**: All 44x44 — good.
- **Hint text**: Gray300 on Gray100 failed (1.4:1). FIXED — all hints now use gray400.
- **Text readability**: Body at 15px, labels at 12px — acceptable on mobile.

---

## What Works Well

- Design system is genuinely used everywhere — color/spacing/type consistency is strong
- AnimatedList usage for list mutations gives smooth UX
- Staggered enter animations create a polished feel
- Card-based layout creates clear visual grouping
- CupertinoSwitch on notifications screen — correct iOS-native choice
- Factory pattern on HealthBadge — clean API

---

## Priority Recommendations (Remaining)

1. **Add undo for destructive actions** — Deleting goals/payments/rules has no recovery path
2. **Mark required fields** — Sheets don't indicate which fields are mandatory
3. **Add empty state guidance on Add Accounts** — Only Cash exists on arrival, no prompt to explain why adding more accounts helps
