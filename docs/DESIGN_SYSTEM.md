# Paisa Bolta Design System

> Dark. Bold. Tactile. Confident. Quiet. Specific.
>
> Every interactive element behaves like a physical object that responds to touch.
> Buttons press. Cards lift. Numbers settle. Sheets slide. Nothing teleports.

---

## Font

**Primary:** Inter (Google Fonts, free)
**Fallback:** system sans-serif

| Role | Size | Weight | Usage |
|------|------|--------|-------|
| Hero number | 72 | Bold (700) | Weekly total, daily total |
| Currency symbol | 36 | Regular (400) | "Rs" beside hero number |
| Section title | 20 | SemiBold (600) | Tab headers, card titles |
| Body | 14 | Regular (400) | Transaction rows, descriptions |
| Caption / pill text | 10 | SemiBold (600) | Contextual pills, timestamps |
| Micro label | 10 | Medium (500) | Chart axis labels |

**Hero number rule:** The amount is always 2x the size of its label/symbol. `Rs` at 36, amount at 72. `Food` label at 14, amount at 28. This ratio is non-negotiable.

---

## Colour Palette

### Base (Dark-first, OLED-friendly)

| Token | Hex | Usage |
|-------|-----|-------|
| `scaffold` | `#000000` | Page background |
| `surface` | `#0A0A0A` | Card background |
| `surfaceElevated` | `#141414` | Bottom sheets, dialogs |
| `surfaceSecondary` | `#1A1A1A` | Nested cards, inputs |
| `textPrimary` | `#FFFFFF` | Headings, amounts |
| `textSecondary` | `#A0A0A0` | Labels, descriptions |
| `textTertiary` | `#606060` | Hints, disabled |

### Accent Colours (one per screen)

| Token | Hex | Where |
|-------|-----|-------|
| `accentYellow` | `#FFD60A` | Home screen dominant category highlight, NeoPOP buttons |
| `accentGold` | `#C9A84C` | Family tab accent |
| `accentBlue` | `#4DA8FF` | Analytics tab accent |
| `accentGreen` | `#34D399` | Positive delta pills ("ON TRACK", income) |
| `accentAmber` | `#F59E0B` | Warning delta pills ("+10% VS LAST WEEK") |
| `accentRed` | `#F87171` | Negative/over-budget pills |

**Rule:** Maximum ONE saturated colour per screen. Everything else is grey. The dominant data point gets the accent. Five muted, one loud.

### Category Colours

| Category | Active (accent) | Muted (default) |
|----------|-----------------|-----------------|
| Rent | `#FFD60A` | `#3A3A3A` |
| Transport | `#4DA8FF` | `#3A3A3A` |
| Food | `#34D399` | `#3A3A3A` |
| Family | `#C9A84C` | `#3A3A3A` |
| Social | `#A78BFA` | `#3A3A3A` |
| Other | `#9CA3AF` | `#3A3A3A` |

Only the top category for the period gets its active colour. All others stay muted grey.

---

## Spacing Scale (8pt grid)

| Token | Value |
|-------|-------|
| `xs` | 4 |
| `sm` | 8 |
| `md` | 16 |
| `lg` | 24 |
| `xl` | 32 |
| `xxl` | 48 |

**Card padding:** 16 all sides.
**Screen padding:** 16 horizontal, 24 top.
**Between cards:** 12.

---

## Corner Radii

| Element | Radius |
|---------|--------|
| Transaction card | 16 |
| Bottom sheet | 24 (top only) |
| Contextual pill | 100 (full round) |
| NeoPOP button | 12 |
| Chart bars | 6 (top only) |
| FAB | 28 |

---

## Components

### 1. NeoPOP Button

**Where:** "Confirm All" button, "Share Weekly Poster" button. Two buttons only.

```
Structure:
  - Front layer: solid fill (accentYellow), 12px radius
  - Back layer: same shape, darker shade (#B8960A), offset 4px right + 4px down
  - Text: black, 16pt SemiBold, uppercase

States:
  - Default: front layer at origin, shadow visible
  - Pressed: front layer translates (4, 4), covering back layer entirely
  - Animation: 150ms ease-out

Flutter note: Use Transform.translate + GestureDetector onTapDown/onTapUp
```

### 2. Hero Number

```
Layout:
  Row(
    crossAxisAlignment: baseline,
    children: [
      Text("Rs", style: 36pt / w400 / textSecondary),
      SizedBox(width: 4),
      Text("4,200", style: 72pt / w700 / textPrimary),
    ]
  )

Rule: Number is ALWAYS larger and bolder than its label/symbol.
```

### 3. Contextual Pill

```
Container(
  padding: EdgeInsets(h: 8, v: 4),
  decoration: BoxDecoration(
    color: accentAmber.withOpacity(0.15),
    borderRadius: 100,
  ),
  child: Text(
    "+10% VS LAST WEEK",
    style: 10pt / w600 / accentAmber / ALL_CAPS,
  ),
)

Placement: directly below the hero number, left-aligned.
Content examples:
  - "+10% VS LAST WEEK" (amber)
  - "TOP CATEGORY" (green)
  - "ON TRACK" (green)
  - "QUIETEST DAY" (blue)
```

### 4. Transaction Card (Skeuomorphic Surface)

```
Container(
  decoration: BoxDecoration(
    gradient: LinearGradient(
      begin: topCenter,
      end: bottomCenter,
      colors: [surface.lighten(3%), surface],  // subtle top-light
    ),
    borderRadius: 16,
    boxShadow: [
      BoxShadow(
        color: #000000 @ 40%,
        offset: (0, 2),
        blurRadius: 8,
      ),
    ],
  ),
)

Content layout:
  Row: [CategoryIcon] [MerchantName + Time] [Amount right-aligned]
  Amount uses hero number ratio (amount 2x label size)
```

### 5. Bottom Sheet (not new screens)

**Use for:** mark as split, pick category, add family entry, confirm settlement, quick-add.

```
Specs:
  - Max height: 40% of screen
  - Background: surfaceElevated (#141414)
  - Top radius: 24
  - Drag handle: 40w x 4h, centered, textTertiary colour
  - Scrim: #000000 @ 50%
  - Entry animation: 300ms cubic-bezier(0.4, 0, 0.2, 1) slide up
  - Exit: 250ms slide down
```

### 6. Sunday Digest Card Stack

```
Structure: PageView with 4 cards
  - Card 1: Weekly total (hero number + delta pill)
  - Card 2: Top category (icon + amount + "TOP CATEGORY" pill)
  - Card 3: Quietest day (day name + amount + "QUIETEST DAY" pill)
  - Card 4: Shareable poster preview + "Share to Story" NeoPOP button

Specs:
  - viewportFraction: 0.85 (next card peeks from right)
  - Card height: 80% of screen
  - Dot indicators at bottom: active = accentYellow, inactive = textTertiary
  - Swipe physics: BouncingScrollPhysics
```

### 7. Bottom-Anchored CTA

Every detail/confirmation screen has its primary action pinned to the bottom.

```
Positioned(
  bottom: 0,
  left: 0,
  right: 0,
  child: Padding(
    padding: EdgeInsets(h: 16, bottom: safeArea + 16),
    child: NeoPOPButton(...)  // or standard filled button for non-hero CTAs
  ),
)

Non-hero CTA style: full-width, 56px height, accentYellow fill, black text,
  12px radius, no NeoPOP shadow. Reserve NeoPOP for the two hero buttons.
```

### 8. Seven-Day Bar Chart (Home Screen)

```
Specs:
  - 7 bars, equal width, 6px gap between
  - Default bar colour: textTertiary (#606060)
  - Today's bar: accentYellow
  - Highest bar: also accentYellow (if not today)
  - Bar radius: 6 top only
  - Below each bar: day initial (M T W T F S S) in 10pt caption
  - Above tallest bar: amount in 12pt, textSecondary
  - Animation: bars grow from 0 to value over 400ms with overshoot curve
```

---

## Animation Specs

| Animation | Duration | Curve | Trigger |
|-----------|----------|-------|---------|
| NeoPOP press | 150ms | easeOut | onTapDown / onTapUp |
| Number roll | 400ms | elasticOut (overshoot) | Value change |
| Bottom sheet enter | 300ms | cubic(0.4, 0, 0.2, 1) | Open |
| Bottom sheet exit | 250ms | cubic(0.4, 0, 0.2, 1) | Close / drag |
| Bar chart grow | 400ms | elasticOut | Screen load |
| Card stack swipe | physics-driven | BouncingScrollPhysics | User swipe |
| Tab transition | 200ms | easeInOut | Tab change |

**Number roll implementation:** Use `Tween<double>` with `AnimationController`. Display `value.toStringAsFixed(0)` formatted with commas on each frame. The elasticOut curve gives the overshoot-then-settle effect.

---

## What NOT To Do

- No celebratory animations (no confetti, no bouncing coins, no "JACKPOT")
- No gradient backgrounds on data screens (flat dark only)
- No equal-weight number + symbol (always hero ratio)
- No rainbow category charts (one accent, rest muted)
- No full-screen navigations for short interactions (bottom sheets only)
- No Material default buttons on hero actions (NeoPOP only on the two)
- No passive number changes (always animate)

---

## Implementation Priority

1. **Token file first** — create `lib/styles/paisa_tokens.dart` with all colours, spacing, radii
2. **Hero number widget** — reusable `HeroAmount(symbol, value, deltaText, deltaType)`
3. **NeoPOP button widget** — reusable `NeoPOPButton(label, onTap, color)`
4. **Transaction card** — skeuomorphic surface with gradient + shadow
5. **Bottom sheet wrapper** — consistent sheet with drag handle and animation
6. **Animated number** — `AnimatedAmount` widget with roll + overshoot
7. **Bar chart** — 7-day chart with accent highlighting
8. **Card stack** — Sunday digest PageView

---

## 5-Tab Navigation Bar

```
Background: scaffold (#000000)
Height: 64 + safeArea
Icon size: 24
Label size: 10pt

Inactive: textTertiary (#606060)
Active: accentYellow (#FFD60A)

Tabs: Home | Transactions | [FAB] | Family | Analytics

Centre FAB:
  - 56px circle
  - accentYellow fill
  - "+" icon in black
  - Elevated 4px shadow
  - Tap opens quick-add bottom sheet (not a new screen)
```
