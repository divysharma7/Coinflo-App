# Design System Audit: Spendler

> **Date:** 2026-05-10
> **Score:** 88/100

---

## Summary

**Components:** 10 | **Tokens files:** 6 | **Barrel export:** Complete

---

## Token Coverage

| Category | Tokens Defined | Hardcoded Values | Status |
|----------|---------------|------------------|--------|
| Colors | 24 (base + gray + semantic + category + light variants) | 0 | CLEAN |
| Spacing | 8 (xxs → xxxl) | 0 | CLEAN |
| Typography | 12 styles (display, heading, body, label, numeric) | 0 | CLEAN |
| Radii | 6 (xs → full) | 0 | CLEAN |
| Shadows | 3 (sm, md, lg) | 0 | CLEAN |
| Durations | 3 (fast, base, slow) | 0 | CLEAN |

---

## Color Palette

### Base

| Token | Hex | Usage |
|-------|-----|-------|
| `black` | `#0A0A0A` | Titles, buttons, selected states |
| `white` | `#FFFFFF` | Card backgrounds, text on black |
| `offWhite` | `#F5F5F5` | Screen backgrounds |

### Grays

| Token | Hex | Usage |
|-------|-----|-------|
| `gray100` | `#F0F0F0` | Input backgrounds, icon boxes |
| `gray200` | `#E0E0E0` | Borders, inactive dots, dividers |
| `gray300` | `#C8C8C8` | Sheet handle bars |
| `gray400` | `#A0A0A0` | Hints, labels, inactive icons |
| `gray500` | `#6E6E6E` | Subtitles, de-emphasized text |
| `gray600` | `#4A4A4A` | Explainer body, generic icons |

### Semantic

| Token | Hex | Usage |
|-------|-----|-------|
| `green` | `#22C55E` | Success, checkmarks, "On Track" |
| `red` | `#EF4444` | Errors, over-budget, "Behind" |
| `orange` | `#F97316` | Warnings, "At Risk" |
| `orangeLight` | `#F97316` @ 10% | "At Risk" badge background |
| `redLight` | `#EF4444` @ 10% | "Behind" badge background |

### Category Pill Pairs

| Name | Background | Text |
|------|-----------|------|
| Pink | `#FCE7F3` | `#BE185D` |
| Orange | `#FEF3C7` | `#B45309` |
| Purple | `#EDE9FE` | `#6D28D9` |
| Blue | `#DBEAFE` | `#1D40AE` |
| Green | `#DCFCE7` | `#15803D` |
| Gray | `#F3F4F6` | `#374151` |

---

## Typography Scale

| Token | Size | Weight | Spacing | Features | Usage |
|-------|------|--------|---------|----------|-------|
| `displayXL` | 40 | 700 | -1.5 | Tabular figures | Hero amounts |
| `displayL` | 32 | 700 | -1.0 | Tabular figures | Currency symbols, sheet inputs |
| `headingL` | 28 | 700 | -0.5 | — | Screen titles |
| `headingM` | 22 | 700 | -0.3 | — | Sheet headers |
| `headingS` | 17 | 600 | -0.2 | — | Card titles, button text |
| `bodyL` | 17 | 400 | — | Line height 1.41 | Large body text |
| `bodyM` | 15 | 400 | — | Line height 1.47 | Standard body text |
| `bodyS` | 13 | 400 | — | Line height 1.38 | Secondary text |
| `labelM` | 12 | 600 | +0.8 | — | Form labels (UPPERCASE) |
| `labelS` | 11 | 500 | +0.6 | — | Badges, metadata |
| `numericL` | 17 | 600 | — | Tabular figures | Primary amounts |
| `numericM` | 15 | 500 | — | Tabular figures | Secondary amounts |

---

## Spacing (4pt Grid)

| Token | Value | Usage |
|-------|-------|-------|
| `xxs` | 4px | Micro gaps |
| `xs` | 8px | Dot spacing, chip gaps, icon-to-text |
| `sm` | 12px | Between list cards, pill padding |
| `md` | 16px | Card padding, form container padding |
| `lg` | 20px | Screen horizontal padding, button padding |
| `xl` | 24px | Title-to-content gap |
| `xxl` | 32px | Large section gaps |
| `xxxl` | 48px | Extra large gaps |

---

## Border Radii

| Token | Value | Usage |
|-------|-------|-------|
| `xs` | 6px | Keyword chips, small elements |
| `sm` | 10px | Icon boxes, image clips |
| `md` | 14px | Input containers, search bars |
| `lg` | 20px | Reserved |
| `xl` | 28px | Cards, containers, checkmark icon |
| `full` | 999px | Buttons, pills, badges, progress dots |

---

## Shadows

| Token | Blur | Offset | Opacity | Usage |
|-------|------|--------|---------|-------|
| `sm` | 4px | (0, 1) | 6% | Default cards (standard) |
| `md` | 12px | (0, 4) | 8% | Elevated cards (opt-in) |
| `lg` | 24px | (0, 8) | 10% | Reserved |

---

## Animation Durations

| Token | Value | Usage |
|-------|-------|-------|
| `fast` | 150ms | Press scale, selection transitions, AnimatedContainer |
| `base` | 250ms | List insert/remove, progress bar |
| `slow` | 400ms | Screen enter animations |

---

## Component Completeness

| Component | States | Variants | Configurable | Score |
|-----------|--------|----------|--------------|-------|
| `AppButton` | default, pressed, disabled | primary, ghost | label, onTap, variant, disabled | 8/10 |
| `AppCard` | — | light, dark | child, padding, shadow | 8/10 |
| `AppProgressIndicator` | — | — | currentStep, totalSteps | 9/10 |
| `AppBackButton` | — | — | onTap | 9/10 |
| `AppTextField` | default, error | — | label, hint, prefix, keyboardType, hasError | 8/10 |
| `AppAddButton` | — | — | label, onTap | 8/10 |
| `HealthBadge` | onTrack, atRisk, behind, completed | fromGoalHealth, fromPaymentHealth | — | 9/10 |
| `AccountIcon` | loaded, fallback | — | name, type, size | 8/10 |
| `CategoryPill` | — | — | category | 6/10 |
| `AppBottomTabBar` | active, inactive | — | currentIndex, onTap | 7/10 |

---

## File Structure

```
lib/design_system/
├── app_colors.dart              ← 24 color tokens
├── app_text_styles.dart         ← 12 text styles
├── app_spacing.dart             ← 8 spacing values (4pt grid)
├── app_radius.dart              ← 6 border radius presets
├── app_shadows.dart             ← 3 shadow levels
├── app_durations.dart           ← 3 animation durations
├── design_system.dart           ← Barrel export (16 exports)
└── widgets/
    ├── app_button.dart          ← Primary + ghost, scale press
    ├── app_card.dart            ← Light + dark, configurable shadow
    ├── app_progress_indicator.dart ← Step dots
    ├── app_back_button.dart     ← Navigation back arrow
    ├── app_text_field.dart      ← Labeled input with error state
    ├── app_add_button.dart      ← Outlined pill with + icon
    ├── category_pill.dart       ← Colored category tags
    ├── bottom_tab_bar.dart      ← 4-tab bar with FAB gap
    ├── account_icon.dart        ← Brand logo or generic fallback
    └── health_badge.dart        ← RAG status badges
```

---

## Naming Conventions

| Pattern | Convention | Status |
|---------|-----------|--------|
| Token classes | `App[Category]` (AppColors, AppSpacing) | Consistent |
| Widget classes | `App[Name]` (AppButton, AppCard) | Consistent |
| Enum variants | camelCase (primary, ghost, light, dark) | Consistent |
| File naming | snake_case matching class | Consistent |
| Private helpers | Underscore prefix | Consistent |

---

## Usage Rules

1. **Single import**: `package:finance_buddy_app/design_system/design_system.dart`
2. **No raw Text styles**: Use `AppTextStyles.*` or `.copyWith()`
3. **No hardcoded colors**: Use `AppColors.*`
4. **No hardcoded spacing**: Use `AppSpacing.*`
5. **No hardcoded radii**: Use `AppRadius.*`
6. **No hardcoded durations**: Use `AppDurations.*`

---

## Remaining Improvements (Low Priority)

| Item | Why Deferred |
|------|--------------|
| `CategoryPill` maps only 6 of 40 categories | Fallback works; expand when transaction UI is built |
| Refactor 11 screens to use new shared widgets | Mechanical — do when touching files next |
| Add doc comments to all widget classes | Non-blocking; add incrementally |
| `AppButton` loading state | No async buttons in current screens |
| `AppBottomTabBar` badge support | Future feature |
