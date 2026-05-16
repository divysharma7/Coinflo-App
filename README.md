<p align="center">
  <img src="assets/icon/coinflo_icon.png" alt="CoinFlo — personal finance tracker for Android. A dark coin icon with a green accent ring and a white dollar symbol in the center." width="120" height="120" style="border-radius: 24px;" />
</p>

<h1 align="center">CoinFlo</h1>

<p align="center">
  <strong>Your money. Your rules. Zero clutter.</strong>
</p>

<p align="center">
  A premium personal finance app built with Flutter — track spending, set budgets,<br/>
  split bills, save toward goals, and get AI-powered insights.<br/>
  All your data stays local-first with optional Firebase cloud backup.
</p>

<p align="center">
  <b>Local-first</b> &nbsp;·&nbsp; <b>AI-categorized</b> &nbsp;·&nbsp; <b>Multi-currency</b> &nbsp;·&nbsp; <b>Beautiful UI</b>
</p>

<div align="center">

[![Flutter](https://img.shields.io/badge/Flutter-3.11-02569B?style=flat-square&logo=flutter&logoColor=white)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-3.11-0175C2?style=flat-square&logo=dart&logoColor=white)](https://dart.dev/)
[![Firebase](https://img.shields.io/badge/Firebase-Auth%20%2B%20Firestore-FFCA28?style=flat-square&logo=firebase&logoColor=black)](https://firebase.google.com/)
[![License](https://img.shields.io/badge/license-MIT-5B5BD6?style=flat-square)](LICENSE)
[![Release](https://img.shields.io/github/v/release/divysharma7/finance_buddy_app?style=flat-square&color=22C55E&label=latest)](https://github.com/divysharma7/finance_buddy_app/releases/latest)

</div>

<br/>

<p align="center">
  <a href="https://github.com/divysharma7/finance_buddy_app/releases/latest"><strong>Download APK</strong></a> &nbsp;·&nbsp;
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
        <li>Quick-add with custom numpad and cursor editing</li>
        <li>AI-powered category classification (Gemini)</li>
        <li>Duplicate transaction detection</li>
        <li>Split bills with friends (equal or custom)</li>
        <li>Confirm/edit/delete transactions</li>
      </ul>
    </td>
    <td width="50%" valign="top">
      <h3>Budgets &amp; Goals</h3>
      <ul>
        <li>Monthly budget with progress bar</li>
        <li>Per-category budget limits</li>
        <li>Savings goals with contribution tracking</li>
        <li>Budget alerts when nearing limits</li>
        <li>Plan page with unified budget + goals view</li>
      </ul>
    </td>
  </tr>
  <tr>
    <td width="50%" valign="top">
      <h3>Reports &amp; Analytics</h3>
      <ul>
        <li>Donut chart with category breakdown</li>
        <li>Daily spend bar chart with week navigation</li>
        <li>Spending projection &amp; streaks</li>
        <li>Budget vs actual comparison</li>
        <li>CSV export</li>
      </ul>
    </td>
    <td width="50%" valign="top">
      <h3>People &amp; Family</h3>
      <ul>
        <li>Friends with debt tracking (who owes whom)</li>
        <li>Settlement flow with multiple methods</li>
        <li>Family inflows &amp; outflows</li>
        <li>Investment tracking (MF, stocks, FD)</li>
      </ul>
    </td>
  </tr>
  <tr>
    <td width="50%" valign="top">
      <h3>Smart Features</h3>
      <ul>
        <li>Penny AI assistant (ask about your spending)</li>
        <li>15 currencies with auto-detection from locale</li>
        <li>Subscription tracking with billing reminders</li>
        <li>Local notifications &amp; spending alerts</li>
      </ul>
    </td>
    <td width="50%" valign="top">
      <h3>Premium UX</h3>
      <ul>
        <li>3-phase splash animation (coin spin, rocket, fade)</li>
        <li>Staggered list entrances across all screens</li>
        <li>Lottie micro-interactions (confetti, checkmarks)</li>
        <li>Dark header with adaptive status bar icons</li>
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
  Firebase is optional — used only for auth + cloud backup of settings.
</p>

```
lib/
 ├── core/              # Enums, constants, router
 ├── data/
 │   ├── db.dart        # Drift database (12 tables)
 │   └── repositories/  # Repository pattern (budget, goal, transaction, etc.)
 ├── design_system/     # AppColors, AppTextStyles, AppSpacing, AppRadius, widgets
 ├── models/            # Data models (AccountModel, SavingsGoalModel, etc.)
 ├── pages/             # Feature-first screens
 │   ├── add/           # Quick-add sheet
 │   ├── home/          # Home + daily view
 │   ├── onboarding_v2/ # 8-step onboarding flow
 │   ├── penny/         # AI assistant
 │   ├── people/        # Friends + family
 │   ├── plan/          # Budgets + savings goals
 │   ├── report/        # Analytics + charts
 │   ├── settings/      # Profile, currency, preferences
 │   ├── splash/        # Animated splash screen
 │   ├── subscriptions/ # Recurring subscriptions
 │   └── transactions/  # Transaction list + detail + split
 ├── providers/         # Riverpod providers
 ├── services/          # Firebase, AI, notifications, export
 └── widgets/           # Shared components (animations, charts, etc.)
```

<br/>

<h3 align="center">Tech Stack</h3>

<div align="center">

| Layer | Technology |
|-------|-----------|
| **Framework** | Flutter 3.11 + Dart 3.11 |
| **State** | Riverpod (FutureProvider, StreamProvider) |
| **Database** | Drift (SQLite) — 12 tables |
| **Auth** | Firebase Auth (email/password) |
| **Cloud Sync** | Cloud Firestore (settings + onboarding data) |
| **AI** | Firebase AI (Gemini) for category classification |
| **Charts** | fl_chart (pie, bar) |
| **Animations** | flutter_animate + Lottie + custom AnimationControllers |
| **Navigation** | go_router |
| **Icons** | Phosphor Icons |
| **Notifications** | flutter_local_notifications |

</div>

<br/>

---

<br/>

<h2 align="center" id="getting-started">Getting Started</h2>

<h3>Prerequisites</h3>

- Flutter SDK 3.11+
- Android Studio / VS Code
- A Firebase project (for auth + Firestore)

<h3>Setup</h3>

```bash
# Clone the repo
git clone https://github.com/divysharma7/finance_buddy_app.git
cd finance_buddy_app

# Install dependencies
flutter pub get

# Generate Drift database code
dart run build_runner build

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

<br/>

---

<br/>

<h2 align="center">Data Flow</h2>

```
┌─────────────────────────────────────────────────────────────┐
│  ONBOARDING                                                  │
│  Currency → Accounts → Budget → Categories → Goals →         │
│  Recurring → Completion (email + password)                   │
│       ↓                    ↓                                 │
│  SharedPreferences    Firebase Auth + Firestore              │
│       ↓                                                      │
│  Drift Database (local SQLite)                               │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│  APP RUNTIME                                                 │
│  Riverpod Providers ← Drift streams (reactive)              │
│       ↓                                                      │
│  Home · Report · Plan · Settings · Transactions              │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│  RETURNING USER (sign-in)                                    │
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
  <a href="https://github.com/divysharma7/finance_buddy_app/issues"><b>Report Bug</b></a> &nbsp;·&nbsp;
  <a href="https://github.com/divysharma7/finance_buddy_app/releases"><b>Releases</b></a>
</p>

<br/>

<p align="center"><sub>MIT License · Built with Flutter + Firebase · Made by <a href="https://github.com/divysharma7">@divysharma7</a></sub></p>
