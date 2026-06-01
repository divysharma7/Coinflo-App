# Project Skill Audit — Evidence Log

**Date:** 2026-05-31
**Scope:** `.claude/skills/` (25 skills → 10 kept, 15 deleted, 4 fixed in place)
**Method:** Agent harness — adversarial re-audit (devil's-advocate skeptic per skill) + empirical test-case (isolated executor → independent judge) + deterministic dual-confirm gate. 60 agents, ~1.69M tokens.

## Rubric
A skill **DELETE** requires BOTH: Phase-1 skeptic on the drop side (`CONFIRM_DROP`/`CHALLENGE_WEAK` or `recommendation=DROP`) **AND** Phase-2 judge `FAIL`. Judge scores: `platform_correct` (0–2), `skill_driven` (0–2, where 0 = base Claude would produce this without the skill), `additive_value` (0–2), `harmful` (0/−1/−2). PASS = total ≥ 5 ∧ platform ≥ 1 ∧ skill_driven ≥ 1. Disagreements → CONFLICT → human gate.

## Outcome: 15 DELETED

| Skill | Skeptic | Judge | Reason |
|---|---|---|---|
| accessibility | CHALLENGE_WEAK | FAIL 4/8 | Zero Flutter; HTML/Swift/Kotlin only; no `Semantics` API. Flutter mechanics came from base knowledge, not the skill. |
| design-system | CONFIRM_DROP | FAIL 3/8 | CSS/Tailwind web scanner; `--url localhost:3000`; output (JSON tokens, HTML preview) inapplicable to Dart tokens. |
| security-review | CHALLENGE_WEAK | FAIL 2/8 (harm −1) | 864 lines TS/Supabase/AWS/Solana; zero Dart. Would emit wrong-platform security code. |
| git-workflow | CONFIRM_DROP | FAIL 3/8 (harm −1) | 715 lines restating the 25-line always-loaded global git rule + npm/CI hooks. |
| coding-standards | CHALLENGE_WEAK | FAIL 3/8 (skill_driven 0) | KISS/DRY/YAGNI verbatim from global `coding-style.md` + React/TS noise. |
| codebase-onboarding | CHALLENGE_WEAK | FAIL 4/8 | Output already exists as CLAUDE.md + docs/coinflo-full-context.md. |
| repo-scan | CONFIRM_DROP | FAIL 4/8 (skill_driven 0) | C/C++/Android/Web scanner; community origin; manual install; no signal on pure Dart. |
| motion-patterns | CONFIRM_DROP | FAIL 4/8 | React `motion/react` + `usePathname`; CoinFlo uses `flutter_animate`. |
| motion-ui | CONFIRM_DROP | FAIL 3/8 (skill_driven 0) | React + DOM APIs (`document.body`, `querySelectorAll`, `npm install`). |
| e2e-testing | CONFIRM_DROP | FAIL 3/8 (skill_driven 0) | Playwright browser + Web3; Flutter uses integration_test/patrol. |
| deployment-patterns | CONFIRM_DROP | FAIL 3/8 (skill_driven 0) | Docker/K8s/Node/Go/Python; mobile ships to App/Play Store. |
| system-design | CONFIRM_DROP | FAIL 4/8 | Distributed-systems framing for a solo on-device app. (Was a symlink → link removed, target `.agents/skills/system-design` preserved.) |
| **verification-loop** † | CONFIRM_DROP | PASS 5/8 | CONFLICT override: judge passed only the 6-phase *structure*; every command (npm/tsc/pyright/ruff, `sk-` grep on `.ts/.js`) bypassed. skill_driven truly 0. |
| **motion-foundations** † | CONFIRM_DROP | PASS 5/8 | CONFLICT override: React/Next.js `motion/react`, SSR, browser globals. Skill explicitly *excludes* third-party libs like `flutter_animate`. Both siblings already dropped. |
| **android-clean-architecture** † | CONFIRM_DROP | PASS 5/8 | CONFLICT override: 100% Kotlin/Room/Koin/Hilt/Ktor/Gradle. "Actively misleading" — presents Kotlin patterns authoritatively for Dart/Drift/Riverpod. |

† **CONFLICT cases.** Phase-2 judge gave an identical charitable 5/8 (`skill_driven=1`), but each judge's own notes concede the output came from base Flutter knowledge, not the skill (rubric → `skill_driven=0` → FAIL). User confirmed deletion at the human gate.

## Outcome: 10 KEPT

**Kept as-is (1):** `flutter-dart-code-review` — 15 Flutter-native review sections; PASS, skill-driven.

**Kept + Flutter-ized (4):** edits applied in place, each changed block tagged `<!-- Flutter-ized 2026-05-31 -->`.
- `dart-flutter-patterns` — removed Dio/Crashlytics; added Drift DAO → Riverpod `StreamProvider` → `AsyncValue` example.
- `make-interfaces-feel-better` — kept principles; added Flutter equivalents after each CSS block (`FontFeature.tabularFigures()`, `AnimatedContainer`/`TweenAnimationBuilder`, 48×48 hit areas, `BoxDecoration` border).
- `production-audit` — removed Payments/Webhooks + Docker/CI lenses; added App Store / Play Store readiness lens; re-pointed score-cap at Firebase Security Rules.
- `tdd-workflow` — `npm test`→`flutter test`, Jest→`group()/test()`, RTL→`testWidgets`, Playwright→`integration_test`/patrol, added `ProviderContainer` + in-memory Drift; RED/GREEN/REFACTOR structure preserved.

**Kept generic — no always-loaded global-rule substitute (4):** `architecture-decision-records`, `search-first`, `product-capability`, `security-scan`.

**Rescued from Tier-4 (1):** `frontend-design-direction` — skeptic KEEP_PARTIAL + judge PASS; design-direction philosophy is platform-agnostic. (Its web-specific implementation/review sections remain mild noise — candidate for a future light Flutter-ization.)

## Notes
- These skill dirs were untracked in git; deletions are permanent (per user choice). Backups not taken.
- `skills-lock.json` `skills` object is now empty (only `system-design` was tracked; its symlink was removed).
- App code untouched — `lib/` not modified; no Flutter build impact.
