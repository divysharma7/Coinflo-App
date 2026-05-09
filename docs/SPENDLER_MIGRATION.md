# Spendler Design Migration Guide

Transform "Paisa Bolta / Pulse" (dark OLED, Inter font, Cred-inspired) into "Spendler" (light with dark heroes, system font, semantic color).

## 1. TOKENS (lib/core/tokens.dart) — COMPLETE REWRITE

Rename all classes: PaisaColors→SpendlerColors, PaisaTextStyles→SpendlerTextStyles, PaisaSpacing→SpendlerSpacing, PaisaRadii→SpendlerRadii, PaisaMotion→SpendlerMotion, PaisaShadows→SpendlerShadows, PaisaTypo→SpendlerTypo.

### SpendlerColors
Foundation:
- scaffold: #F5F5F7 (light gray app bg)
- surface: #FFFFFF (cards)
- surfaceHigh/surfaceElevated: #FFFFFF
- heroBackground: #000000 (dark hero cards)
- heroText: #FFFFFF
- border/divider: #E5E5EA
- textPrimary: #000000
- textSecondary: #6E6E73
- textTertiary: #6E6E73
- income/positive: #34C759
- expense/danger: #FF3B30
- info: #007AFF
- Remove yellow/gold/amber. No brand color.

Category palette with hue + tint pairs:
- foodAndDrink: #FF8A4C / #FFEDE0
- transport: #4A8FE7 / #E5F0FC
- shopping: #B19CD9 / #F0EBF8
- entertainment: #E91E63 / #FCE4EC
- streaming: #EC407A / #FCE4EC
- gymFitness: #4CAF50 / #E8F5E9
- productivityTools: #9575CD / #EDE7F6
- personalCare: #F8BBD0 / #FCE4EC
- education: #5C6BC0 / #E8EAF6

Add categoryColor() and categoryTint() helpers.

### SpendlerTextStyles
System font (remove Google Fonts). Tabular figures on all numerals.
- heroNumeral: 56pt Bold, black
- title1: 28pt Bold
- title2: 22pt Semibold
- bodyStrong: 17pt Semibold
- body: 16pt Regular
- caption: 13pt Regular
- label: 11pt Semibold Uppercase letterSpacing 0.6

### SpendlerSpacing
4pt base: xs=4, sm=8, md=12, lg=16, xl=24, xxl=40, cardPadding=16, screenH=20, screenTop=24, cardGap=12

### SpendlerRadii
card=20, sheet=20, pill=100, button=12, barTop=3, fab=28

### SpendlerMotion
Tab switch: Duration.zero. FAB to sheet: 320ms easeOut. Number: 240ms easeOut (no elasticOut). No bouncy springs.

## 2. THEME (lib/core/theme.dart)

Rename PaisaTheme→SpendlerTheme. Switch to ThemeData.light(). Remove Google Fonts.
- scaffold: #F5F5F7, surface: #FFFFFF, primary: #000000
- FAB: black circle, white icon, 56pt
- NavigationBar: white bg, black selected, #6E6E73 unselected
- Cards: white, 0 elevation, 20pt radius
- SystemOverlayStyle.dark (dark icons on light bg)

## 3. ENUMS (lib/core/enums.dart)

Replace 6 categories (rent/transport/food/family/social/other) with 9 Spendler categories:
foodAndDrink, transport, shopping, entertainment, streaming, gymFitness, productivityTools, personalCare, education.
Use Phosphor outlined icons. Update labels.

## 4. APP (lib/app.dart)

Rename PaisaBoltaApp→SpendlerApp, title "Spendler", themeMode: light, remove darkTheme.

## 5. NAVIGATION (lib/pages/shell_page.dart)

5 tabs: Home · Report · [FAB] · Plan · Settings
- FAB: black circle, white +, 56pt, centered, raised
- Active: black icon+label. Inactive: #6E6E73.
- Report = existing AnalyticsPage. Plan = new stub page (budgets/goals placeholder).

## 6. ALL WIDGETS (lib/widgets/)

Update ALL token references. Key changes:
- hero_amount: black text on light, white text on dark hero
- animated_amount: 240ms easeOut
- category_pill: dot in category hue + name
- neo_pop_button: convert to standard black button or delete
- health_ring: open ring, rounded caps, gaps
- empty_state: factual tone ("No subscriptions yet. Add one to start tracking")
- paisa_bottom_sheet: white bg, 20pt radius
- Charts: light background colors

## 7. ALL PAGES

Update all pages in lib/pages/ to use new token names and Spendler visual patterns:
- Light backgrounds with dark hero areas
- $ currency instead of ₹
- Voice: lead with number, no exclamation marks, no congratulations, sentence case

## 8. PROVIDERS, SERVICES, DATA

Update category references in providers, services, seed_data.dart.

## 9. PUBSPEC

Remove google_fonts dependency from pubspec.yaml.

## FILES TO MODIFY (in order)
1. lib/core/tokens.dart
2. lib/core/theme.dart
3. lib/core/enums.dart
4. lib/app.dart + lib/main.dart
5. lib/widgets/common/* (14 files)
6. lib/widgets/charts/* (3 files)
7. lib/pages/shell_page.dart
8. lib/pages/**/* (all page files)
9. lib/providers/*
10. lib/services/**/*
11. lib/data/seed_data.dart
12. pubspec.yaml
