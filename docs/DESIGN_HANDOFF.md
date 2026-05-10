# Handoff Spec: Spendler Onboarding Flow

> **Date:** 2026-05-10
> **Platform:** iOS (Flutter/Dart)
> **Screens:** 11 (Currency → Completion)

---

## Overview

11-screen onboarding flow for a personal finance tracker. Users configure currency, accounts, budget, categories, income tracking, smart rules, savings goals, recurring payments, and notifications before account creation.

---

## Design Tokens Used

| Token | Value | Usage |
|-------|-------|-------|
| `AppColors.black` | `#0A0A0A` | Titles, primary buttons, selected states, active dots |
| `AppColors.white` | `#FFFFFF` | Card backgrounds, button text on black |
| `AppColors.offWhite` | `#F5F5F5` | Screen backgrounds (steps 2–11) |
| `AppColors.gray100` | `#F0F0F0` | Input backgrounds, icon boxes |
| `AppColors.gray200` | `#E0E0E0` | Inactive dots, borders, chip outlines |
| `AppColors.gray300` | `#C8C8C8` | Handle bars |
| `AppColors.gray400` | `#A0A0A0` | Hints, labels, secondary icons |
| `AppColors.gray500` | `#6E6E6E` | Subtitles |
| `AppColors.gray600` | `#4A4A4A` | Explainer body, generic icons |
| `AppColors.green` | `#22C55E` | Checkmarks, success |
| `AppColors.red` | `#EF4444` | Errors, over-budget |
| `AppColors.orange` | `#F97316` | "At Risk" |
| `AppColors.orangeLight` | 10% orange | Badge backgrounds |
| `AppColors.redLight` | 10% red | Badge backgrounds |
| `AppTextStyles.headingL` | 28/700 | Screen titles |
| `AppTextStyles.headingM` | 22/700 | Sheet headers |
| `AppTextStyles.headingS` | 17/600 | Card titles, button text |
| `AppTextStyles.bodyM` | 15/400 | Body text, inputs |
| `AppTextStyles.bodyS` | 13/400 | Secondary info |
| `AppTextStyles.labelM` | 12/600 | Form labels (UPPERCASE) |
| `AppTextStyles.labelS` | 11/500 | Badges, metadata |
| `AppSpacing.xs` | 8px | Dot spacing, chip gaps |
| `AppSpacing.sm` | 12px | Between list cards |
| `AppSpacing.md` | 16px | Card padding |
| `AppSpacing.lg` | 20px | Screen padding, button margins |
| `AppSpacing.xl` | 24px | Title-to-content gap |
| `AppRadius.sm` | 10px | Icon boxes |
| `AppRadius.md` | 14px | Input containers |
| `AppRadius.xl` | 28px | Cards |
| `AppRadius.full` | 999px | Buttons, pills, badges |
| `AppShadows.sm` | 0 1px 4px 6% | Default cards |
| `AppDurations.fast` | 150ms | Press, selection |
| `AppDurations.base` | 250ms | List insert/remove |
| `AppDurations.slow` | 400ms | Screen enter |

---

## Components

| Component | Variant | Props | Notes |
|-----------|---------|-------|-------|
| `AppButton` | `primary` | label, onTap, disabled | Black fill, h56, scale 0.97 press |
| `AppButton` | `ghost` | label, onTap, disabled | 1.5px black border |
| `AppCard` | `light` | child, padding, shadow | White bg, xl radius |
| `AppCard` | `dark` | child, padding, shadow | Black bg, xl radius |
| `AppProgressIndicator` | — | currentStep, totalSteps | 8 capsules |
| `AppBackButton` | — | onTap | 44×44, pops by default |
| `AppTextField` | — | label, hint, prefix, hasError | Gray100 bg, md radius |
| `AppAddButton` | — | label, onTap | Outlined pill + icon |
| `HealthBadge` | goal/payment | health enum | RAG badges |
| `AccountIcon` | — | name, type, size | Logo or fallback |
| `CategoryPill` | — | category | Color-mapped pill |
| `AppBottomTabBar` | — | currentIndex, onTap | 4 tabs + FAB gap |

---

## Shared Screen Patterns

| Element | Spec |
|---------|------|
| **Progress bar** | `AppProgressIndicator(currentStep: N)`. Top padding `md`. |
| **Back button** | `AppBackButton()`. Below progress. |
| **Title block** | `headingL` black + `bodyM` gray500. Gap `xs`. Top `lg`. |
| **Continue button** | `AppButton.primary`, pinned. Padding `fromLTRB(lg, sm, lg, lg)`. |
| **Screen background** | Step 1: white. Steps 2–11: offWhite. |

---

## States and Interactions

| Element | State | Behavior |
|---------|-------|----------|
| AppButton | Default | Full opacity |
| AppButton | Pressed | Scale 0.97, 150ms |
| AppButton | Disabled | 50% opacity, non-interactive |
| Option card | Selected | 2px black border, md shadow, black icon box |
| Option card | Unselected | 1.5px gray200 border, sm shadow, gray100 icon box |
| Preset pill | Active | Black fill, white text, w600 |
| Preset pill | Inactive | White fill, gray200 border |
| Toggle row | Enabled | Full opacity |
| Toggle row | Disabled | 50% opacity, non-interactive |
| AnimatedList row | Insert | Slide Offset(0, 0.1) + Fade, `base` |
| AnimatedList row | Remove | Fade out, `fast` |

---

## Animation / Motion

| Element | Trigger | Animation | Duration | Easing |
|---------|---------|-----------|----------|--------|
| Screen title | Mount | Fade + Slide(0, 0.05) | `slow` | easeOutCubic |
| Content | Mount | Fade + Slide, staggered 80ms | `slow` | easeOutCubic |
| Card pulse | Selection tap | Scale 1→1.02→1 | 200ms | easeInOut |
| Budget number | Preset tap | AnimatedSwitcher Fade + Slide(0, 0.3) | `fast` | — |
| Checkmark | Mount | Scale 0.6→1.0 | `slow` | elasticOut |
| Category groups | Mount | Staggered fade, 60ms/group | `slow` | easeOut |
| List item | insert | Slide + Fade | `base` | easeOutCubic |
| List item | remove | Fade | `fast` | — |

---

## Edge Cases

| Scenario | Behavior |
|----------|----------|
| Empty search | Centered "No [items] found", bodyM gray400 |
| No items added | Button: "Skip for now" |
| Keyboard opens | Continue visible (`resizeToAvoidBottomInset: true`) |
| Duplicate keyword | Red border + error text |
| Over-allocated budget | Bar + label red. Continue enabled. |
| All groups budgeted | "+ Add" hidden |
| Logo asset missing | Generic Material icon fallback |
| Locale null | Default USD, no "Detected" label |
| Long text | `TextOverflow.ellipsis` |

---

## Accessibility

- **Touch targets**: ≥ 44×44px (back button, list rows, toggles)
- **Contrast**: Body 4.8:1 (AA). Hints 3.1:1 (placeholder-adequate).
- **Focus order**: progress → back → title → content → CTA
- **Switches**: CupertinoSwitch (native iOS semantics)
- **Icons**: Paired with text labels

---

## File Map

```
lib/design_system/           ← Tokens + reusable widgets
lib/constants/               ← currencies.dart, app_categories.dart, goal_icons.dart
lib/models/                  ← account, category_budget, savings_goal, recurring_payment, smart_rule
lib/utils/                   ← account_logo_resolver.dart, rule_matcher.dart
lib/widgets/                 ← Bottom sheets (add_goal, add_payment, add_rule, add_category_budget, category_picker)
lib/screens/onboarding/      ← 11 screen files
```
