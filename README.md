<p align="center">
  <img src="assets/icon/coinflo_icon.png" alt="CoinFlo — personal finance tracker for Android. A dark coin icon with a green accent ring and a white dollar symbol in the center." width="120" height="120" style="border-radius: 24px;" />
</p>

<h1 align="center">CoinFlo</h1>

<p align="center">
  <strong>Your money. Your rules. Zero clutter.</strong>
</p>

<p align="center">
  A premium personal finance app built with Flutter — track spending, set budgets,<br/>
  split bills with people, save toward goals, and ask an on-device AI assistant.<br/>
  Local-first: your data lives in an on-device SQLite database.
</p>

<p align="center">
  <b>Local-first</b> &nbsp;·&nbsp; <b>AI-categorized</b> &nbsp;·&nbsp; <b>Bill splitting</b> &nbsp;·&nbsp; <b>Beautiful UI</b>
</p>

<div align="center">

[![Flutter](https://img.shields.io/badge/Flutter-3.41-02569B?style=flat-square&logo=flutter&logoColor=white)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-3.11-0175C2?style=flat-square&logo=dart&logoColor=white)](https://dart.dev/)
[![Firebase](https://img.shields.io/badge/Firebase-Auth%20%2B%20Firestore-FFCA28?style=flat-square&logo=firebase&logoColor=black)](https://firebase.google.com/)
[![License](https://img.shields.io/badge/license-MIT-5B5BD6?style=flat-square)](LICENSE)
[![Release](https://img.shields.io/github/v/release/divysharma7/Coinflo-App?style=flat-square&color=22C55E&label=latest)](https://github.com/divysharma7/Coinflo-App/releases/latest)

</div>

<br/>

<p align="center">
  <a href="https://github.com/divysharma7/Coinflo-App/releases/latest"><strong>Download APK</strong></a> &nbsp;·&nbsp;
  <a href="#features"><strong>Features</strong></a> &nbsp;·&nbsp;
  <a href="#screenshots"><strong>Screenshots</strong></a> &nbsp;·&nbsp;
  <a href="#architecture"><strong>Architecture</strong></a> &nbsp;·&nbsp;
  <a href="#getting-started"><strong>Getting Started</strong></a>
</p>

<br/>

---

<br/>

<h2 align="center" id="features">Features</h2>

<table width="100%" border="0" cellspacing="0">
  <tr>
    <td width="50%" valign="top">
      <h3>Expense Tracking</h3>
      <ul>
        <li>Fast quick-add: custom numpad with live grouped amount (₹1,00,000)</li>
        <li>AI category auto-tagging (Gemini) from the note you type</li>
        <li>Grouped, searchable category picker</li>
        <li>Split with people — equal split, add people inline</li>
        <li>Duplicate detection, edit/delete, receipt photo attachments</li>
        <li>Accessible: screen-reader labels + 44px touch targets</li>
      </ul>
    </td>
    <td width="50%" valign="top">
      <h3>Budgets &amp; Goals</h3>
      <ul>
        <li>Monthly budget with progress bar</li>
        <li>Per-category budget limits</li>
        <li>Savings goals with contribution tracking</li>
        <li>Budget alerts when nearing limits</li>
        <li>Unified Plan tab (budget + goals in one view)</li>
      </ul>
    </td>
  </tr>
  <tr>
    <td width="50%" valign="top">
      <h3>Reports &amp; Analytics</h3>
      <ul>
        <li>Donut chart with category breakdown</li>
        <li>Daily-spend bar chart with week navigation</li>
        <li>Spending projection &amp; streaks</li>
        <li>Budget vs actual comparison</li>
        <li>CSV / Excel import &amp; export</li>
      </ul>
    </td>
    <td width="50%" valign="top">
      <h3>People &amp; Debts</h3>
      <ul>
        <li>People with debt tracking (who owes whom)</li>
        <li>Groups for shared/recurring splits</li>
        <li>Settlement flow with multiple methods</li>
        <li>Family inflows &amp; investment tracking (MF, stocks, FD)</li>
      </ul>
    </td>
  </tr>
  <tr>
    <td width="50%" valign="top">
      <h3>Saraswati AI Assistant</h3>
      <ul>
        <li>Ask about your spending in natural language</li>
        <li>4-tier intent pipeline routes each message</li>
        <li>Add transactions &amp; get insights from chat</li>
        <li>On-device data — only the prompt leaves the device</li>
      </ul>
    </td>
    <td width="50%" valign="top">
      <h3>Premium UX</h3>
      <ul>
        <li>Animated splash + staggered list entrances</li>
        <li>Lottie micro-interactions</li>
        <li>Custom monochrome design system + tokens</li>
        <li>Dark header with adaptive status-bar icons</li>
        <li>Local notifications &amp; spending alerts</li>
      </ul>
    </td>
  </tr>
</table>

<br/>

---

<br/>

<h2 align="center" id="architecture">Architecture</h2>

<p align="center">
  <b>Local-first</b> — all data lives in an on-device SQLite database via Drift.<br/>
  Firebase is optional — used only for auth + cloud hydration of settings/onboarding.
</p>

```
lib/
 ├── core/              # Enums, constants, router
 ├── data/
 │   ├── db.dart        # Drift database (20 tables · schema v14)
 │   └── repositories/  # Repository pattern (abstract + local Drift impls)
 ├── design_system/     # AppColors, AppTextStyles, AppSpacing, AppRadius, widgets
 ├── pages/             # Feature-first screens
 │   ├── accounts/      # Accounts (cash, bank, card, wallet)
 │   ├── add/           # Quick-add sheet · category picker · split picker
 │   ├── auth/          # Sign in / local-first auth gate
 │   ├── groups/        # Shared groups for splitting
 │   ├── home/          # Home + daily view
 │   ├── onboarding_v2/ # Multi-step onboarding flow
 │   ├── people/        # People + debts
 │   ├── plan/          # Budgets + savings goals
 │   ├── report/        # Analytics + charts
 │   ├── saraswati/     # Saraswati AI assistant
 │   ├── settings/      # Profile, currency, preferences
 │   ├── splash/        # Animated splash screen
 │   ├── subscriptions/ # Recurring subscriptions
 │   └── transactions/  # Transaction list + detail + split flow
 ├── providers/         # Riverpod providers (barrel: providers.dart)
 ├── services/          # ai · saraswati · categorization · split · export ·
 │                      #   migration · notifications · firestore · attachments
 └── widgets/           # Shared components (sheets, cards, charts, buttons)
```

<br/>

<h3 align="center">Tech Stack</h3>

<div align="center">

| Layer | Technology |
|-------|-----------|
| **Framework** | Flutter 3.41 + Dart 3.11 |
| **State** | Riverpod (StreamProvider, FutureProvider, `.family`) |
| **Database** | Drift (SQLite) — 20 tables, schema v14 |
| **Auth** | Firebase Auth (email/password) — optional |
| **Cloud Sync** | Cloud Firestore (settings + onboarding hydration) |
| **AI** | Firebase AI (Gemini) — category classification + Saraswati assistant |
| **Charts** | fl_chart (donut, bar) |
| **Animations** | flutter_animate + Lottie + custom AnimationControllers |
| **Navigation** | go_router (single `/home` shell, `IndexedStack` tabs) |
| **Icons** | Phosphor Icons |
| **Type** | Schibsted Grotesk + JetBrains Mono |
| **Notifications** | flutter_local_notifications + timezone |
| **Crash reporting** | Firebase Crashlytics |
| **Import / Export** | excel · csv · file_picker · share_plus |

</div>

<br/>

---

<br/>

<h2 align="center" id="getting-started">Getting Started</h2>

<h3>Prerequisites</h3>

- Flutter SDK 3.41+ (Dart 3.11+)
- Android Studio / VS Code
- A Firebase project (for optional auth + Firestore)

<h3>Setup</h3>

```bash
# Clone the repo
git clone https://github.com/divysharma7/Coinflo-App.git
cd Coinflo-App

# Install dependencies
flutter pub get

# Generate Drift database code
dart run build_runner build --delete-conflicting-outputs

# Run the app
flutter run
```

<h3>Firebase Setup</h3>

1. Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
2. Enable **Email/Password** auth
3. Create a **Firestore** database
4. Add your `google-services.json` (Android) to `android/app/`
5. Deploy security rules: `npx firebase-tools deploy --only firestore:rules`

<h3>Build Release APK</h3>

```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

> **Signing:** the release build currently uses the Flutter **debug** signing config
> (`android/app/build.gradle.kts`). The APK is sideload-installable but **not**
> Play Store–uploadable until a release keystore + `android/key.properties` are added.

<h3>Useful Commands</h3>

```bash
flutter analyze lib/                                       # Lint check
flutter test                                              # Run tests
dart run build_runner build --delete-conflicting-outputs  # Drift codegen
```

<br/>

---

<br/>

<h2 align="center">Data Flow</h2>

```
┌─────────────────────────────────────────────────────────────┐
│  ONBOARDING                                                  │
│  Welcome → Currency → Income → Accounts → Budget →           │
│  Categories → Goals → Recurring → Recap → Done               │
│       ↓                          ↓                           │
│  SharedPreferences        Firebase Auth + Firestore (opt.)   │
│       ↓                                                      │
│  Drift Database (on-device SQLite)                           │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│  APP RUNTIME                                                 │
│  Riverpod providers ← Drift streams (reactive)              │
│       ↓                                                      │
│  Home · Report · Plan · Settings  (4-tab IndexedStack)       │
│  + People · Transactions · Saraswati  (nested routes)        │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│  RETURNING USER (optional sign-in)                           │
│  Firebase Auth → Firestore hydration → SharedPreferences     │
│       → Drift Database → UI refreshes instantly              │
└─────────────────────────────────────────────────────────────┘
```

<br/>

---

<br/>

<h2 align="center">Contributing</h2>

<p align="center">
  Pull requests welcome! For major changes, please open an issue first.
</p>

<p align="center">
  <a href="mailto:divysharma029@gmail.com"><b>Contact</b></a> &nbsp;·&nbsp;
  <a href="https://github.com/divysharma7/Coinflo-App/issues"><b>Report Bug</b></a> &nbsp;·&nbsp;
  <a href="https://github.com/divysharma7/Coinflo-App/releases"><b>Releases</b></a>
</p>

<br/>

<p align="center"><sub>MIT License · Built with Flutter + Firebase · Made by <a href="https://github.com/divysharma7">@divysharma7</a></sub></p>
