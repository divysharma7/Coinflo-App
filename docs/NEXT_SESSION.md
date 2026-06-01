# CoinFlo — Next Session Plan

> Created end of 2026-05-31 session. **Start a FRESH session** for this — the prior session
> carried huge context (cost hit ~$80), so per-turn cost was ~10×. Everything below is
> mechanical/low-risk and cheap in a clean session.

## State at handoff (verified)
- ✅ **Hardening shipped**: god-file decomposition (5 pages → 41 widget files, all <800 LOC),
  doc re-sync, debugPrint gating, 44 money-math tests. Committed + **pushed to `main`**
  (`eff64d6`, GitHub `divysharma7/Coinflo-App`). Was green on Flutter 3.41.9 (analyze 0/0, all tests pass).
- ✅ **APK on Desktop**: `~/Desktop/coinflo-v22.apk`. NOTE: this may be either (a) the
  2026-05-31 22:04 release build (behavior-identical to current code) **or** (b) a fresh
  `--build-number=22` build if the end-of-session rebuild (`bskf6zd8l`) succeeded. **Verify which** (see step 2).
- ⚠️ **Flutter SDK state is uncertain**: it was upgraded 3.41.9 → 3.44.0, then **reverted to
  3.41.9** because the upgrade is blocked (see below). The revert's dart-sdk re-download may
  or may not have completed. **First thing: confirm the toolchain works.**

## Why the 3.44 upgrade is parked (the blocker)
Flutter **3.44 made `IconData` a `final` class**. `phosphor_flutter 2.1.0` does
`class PhosphorIconData extends IconData` → illegal on 3.44 (`"IconData can't be extended …"`).
Phosphor icons are used app-wide, so 3.44 **cannot compile the app** (build + tests fail; note
`flutter analyze` does NOT catch it — only the kernel compiler does). `phosphor_flutter`'s latest
published version is **2.1.0** — no compatible release existed at handoff.

## Priorities (cheapest-value first)

### 1. Confirm/repair the toolchain (do FIRST)
```bash
flutter --version          # expect 3.41.9 with a working Dart SDK
```
- If it errors about a missing/failed Dart SDK download: the revert didn't finish. With the
  network up, just re-run `flutter --version` (or `flutter precache --android`) — it re-downloads
  the 3.41.9 dart-sdk. Then:
```bash
flutter pub get
flutter analyze lib/       # expect 0 errors / 0 warnings (~110 info lints)
flutter test               # expect all pass
```

### 2. Confirm or rebuild the v22 APK
```bash
ls -la ~/Desktop/coinflo-v22.apk
# Want a genuine fresh build? (only if toolchain healthy)
# NOTE: --no-tree-shake-icons is currently REQUIRED (see cleanup item below)
flutter build apk --release --build-number=22 --no-tree-shake-icons
cp build/app/outputs/flutter-apk/app-release.apk ~/Desktop/coinflo-v22.apk
```

### 3. Flutter 3.44 upgrade — retry ONLY if Phosphor is fixed
```bash
# check for a 3.44-compatible phosphor_flutter (one that no longer `extends IconData`)
curl -s https://pub.dev/api/packages/phosphor_flutter | python3 -c "import sys,json;print(json.load(sys.stdin)['latest']['version'])"
```
- If a newer compatible version exists: bump `phosphor_flutter` in pubspec, `flutter upgrade`,
  `pub get`, `analyze`, `test`, `build apk`. If green, commit.
- If not: stay on 3.41.9. Alternatives if 3.44 is required urgently: fork/patch phosphor to
  compose instead of extend `IconData`, or migrate to another icon set. Don't burn budget here
  unless 3.44 is actually needed.

### 4. Optional cleanup
- `dart fix --apply lib/pages` — clears the ~6 new info lints (prefer_const, always_use_package_imports).
- Decide on the **uncommitted working-tree clutter** (NOT part of hardening, deliberately left out):
  `.agents/`, `landing/`, `.claude/{plans,skills}`, `skills-lock.json`, `docs/{ROADMAP,copy,mermaid,SKILL_AUDIT_LOG}.md`,
  `.claude/settings.json`, `android/build/.../problems-report.html` (latter should be gitignored).
  Commit, gitignore, or discard each.
- Consider pinning Flutter via **FVM** (`.fvmrc`) so the SDK can't drift / break a build unattended again.

## Quick verification block
```bash
flutter --version && flutter analyze lib/ && flutter test
git log --oneline -3
ls -la ~/Desktop/coinflo-v22.apk
```
