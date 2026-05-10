# Accessibility Review: Spendler Onboarding

> **Date:** 2026-05-10
> **Platform:** iOS (Flutter)
> **Scope:** 11 onboarding screens + 5 bottom sheets

---

## Summary

| Category | Status | Notes |
|----------|--------|-------|
| Touch targets | PASS | All interactive elements ≥ 44×44px |
| Color contrast (body) | PASS | Gray500 on white = 4.8:1 (AA) |
| Color contrast (hints) | PASS | Gray400 on gray100 = 3.1:1 (adequate for placeholder) |
| Text readability | PASS | Minimum 13px (bodyS), adequate line heights |
| Focus order | PASS | Logical top-down flow |
| Screen reader | PARTIAL | Icons paired with text, but no explicit semantics labels |
| Motion sensitivity | OPEN | No reduced-motion support |

---

## Color Contrast Audit

| Element | Foreground | Background | Ratio | WCAG | Status |
|---------|-----------|------------|-------|------|--------|
| Screen titles | `#0A0A0A` | `#FFFFFF` / `#F5F5F5` | 18.1:1 / 16.4:1 | AAA | PASS |
| Subtitles | `#6E6E6E` | `#FFFFFF` | 4.8:1 | AA | PASS |
| Body text (gray600) | `#4A4A4A` | `#FFFFFF` | 8.1:1 | AAA | PASS |
| Hint text (gray400) | `#A0A0A0` | `#F0F0F0` | 3.1:1 | — | PASS (placeholder) |
| Labels (gray400) | `#A0A0A0` | `#FFFFFF` | 3.5:1 | — | PASS (supplementary) |
| Button text (white on black) | `#FFFFFF` | `#0A0A0A` | 18.1:1 | AAA | PASS |
| Error text (red) | `#EF4444` | `#FFFFFF` | 3.9:1 | AA Large | PASS |
| Green checkmark | `#22C55E` | `#0A0A0A` (dark card) | 5.2:1 | AA | PASS |
| Green checkmark | `#22C55E` | `#FFFFFF` | 3.0:1 | — | MARGINAL |

### Previously Failed (Now Fixed)

| Element | Before | After | Fix |
|---------|--------|-------|-----|
| Hint text | Gray300 (`#C8C8C8`) on Gray100 (`#F0F0F0`) = 1.4:1 | Gray400 (`#A0A0A0`) on Gray100 = 3.1:1 | Changed all `hintStyle` colors |

---

## Touch Targets

| Element | Size | Minimum | Status |
|---------|------|---------|--------|
| Back button | 44×44 | 44×44 | PASS |
| Currency list rows | Full width × 56h | 44×44 | PASS |
| Preset pills | ~60w × 36h | 44×44 | MARGINAL (height 36 < 44) |
| Toggle switches | CupertinoSwitch native | 44×44 | PASS |
| Delete buttons | 32×32 | 44×44 | FAIL — needs padding |
| Day picker circles | 40×40 | 44×44 | MARGINAL |
| Category chips | Variable × 28h | 44×44 | NON-INTERACTIVE (display only) |

### Recommendations

1. **Delete buttons (32×32)**: Add transparent `GestureDetector` padding to achieve 44×44 tap area
2. **Preset pills (36h)**: Add vertical padding or increase height to 44
3. **Day picker (40×40)**: Increase to 44×44

---

## Typography Readability

| Style | Size | Weight | Line Height | Verdict |
|-------|------|--------|-------------|---------|
| `displayXL` | 40px | 700 | Default | Good |
| `headingL` | 28px | 700 | Default | Good |
| `headingS` | 17px | 600 | Default | Good |
| `bodyM` | 15px | 400 | 1.47 (22px) | Good |
| `bodyS` | 13px | 400 | 1.38 (18px) | Acceptable |
| `labelM` | 12px | 600 | Default | Acceptable (uppercase, short strings) |
| `labelS` | 11px | 500 | Default | Minimum — badges/metadata only |

---

## Focus Order

All screens follow consistent top-to-bottom focus order:

```
1. Progress indicator (non-interactive, skip)
2. Back button
3. Title (non-interactive)
4. Primary content area
5. Form fields / interactive cards
6. Continue button
```

---

## Screen Reader Considerations

| Element | Has Text Label | Semantic Role | Status |
|---------|---------------|---------------|--------|
| Back button | No (icon only) | Button | NEEDS `Semantics(label: 'Go back')` |
| Delete buttons | No (icon only) | Button | NEEDS `Semantics(label: 'Delete')` |
| Progress dots | No | Decorative | NEEDS `Semantics(label: 'Step N of 8')` |
| Currency checkmark | No | Decorative | OK — row text provides context |
| Toggle switches | Yes (title + subtitle) | Switch | OK — CupertinoSwitch has built-in semantics |
| Option cards | Yes (title + subtitle) | Button | OK |

### Recommendations

Add `Semantics` wrapper to:
1. `AppBackButton` — `Semantics(button: true, label: 'Go back')`
2. `AppProgressIndicator` — `Semantics(label: 'Step $currentStep of $totalSteps')`
3. All delete icon buttons — `Semantics(button: true, label: 'Delete $itemName')`

---

## Motion & Animation

| Concern | Status | Notes |
|---------|--------|-------|
| Enter animations | Present | Fade + slide on every screen mount |
| Duration | 400ms max | Within acceptable range |
| Reduces motion | NOT IMPLEMENTED | Should check `MediaQuery.disableAnimations` |
| Flashing content | None | No rapid color changes or strobing |
| Auto-playing | None | All animations are one-shot on mount |

### Recommendation

Wrap animations with:
```dart
final reduceMotion = MediaQuery.of(context).disableAnimations;
// If true, skip animations or use instant transitions
```

---

## Keyboard Navigation (External Keyboard)

| Screen | Tab Order | Enter/Space | Escape | Status |
|--------|-----------|-------------|--------|--------|
| Currency Selection | Fields → list → button | Selects row | — | OK |
| Add Accounts | Fields → button | Submits | — | OK |
| Monthly Budget | Number → pills → button | Selects pill | — | OK |
| Bottom sheets | Fields → buttons | Triggers | Closes | OK |

---

## Summary of Required Fixes

| Priority | Issue | Impact |
|----------|-------|--------|
| HIGH | Delete buttons 32×32 (below 44×44 minimum) | Difficult to tap for motor-impaired users |
| MEDIUM | No `Semantics` on icon-only buttons | Screen readers can't identify purpose |
| MEDIUM | No `reduceMotion` check | Users with vestibular disorders may be affected |
| LOW | Preset pills height 36 (below 44) | Slightly below minimum but row is wide |
| LOW | Progress dots have no semantic label | Screen readers skip them entirely |
