---
phase: 14
plan: 03
subsystem: deployment
tags: [firebase, flutter-web, spa, deep-links, url-strategy, hosting]

dependency-graph:
  requires: []
  provides:
    - firebase-hosting-config
    - spa-rewrite-rules
    - path-url-strategy
  affects:
    - 14-06  # wave 2 depends on main.dart changes (confirmed in plan)

tech-stack:
  added: []
  patterns:
    - Firebase Hosting SPA rewrite (** → /index.html)
    - Path URL strategy for Flutter web (no hash fragments)
    - WASM MIME type override via Firebase headers

key-files:
  created:
    - firebase.json
  modified:
    - flutter_app/lib/main.dart

decisions:
  - id: firebase-public-dir
    choice: flutter_app/build/web
    rationale: Standard Flutter web build output directory

metrics:
  duration: ~1 minute
  completed: "2026-02-21"
---

# Phase 14 Plan 03: Firebase SPA Config Summary

**One-liner:** Firebase Hosting with SPA rewrite (** → /index.html) + WASM MIME headers, and Flutter web path URL strategy for clean deep links.

## What Was Built

Created `firebase.json` at repo root configuring Firebase Hosting for Flutter web deployment, and updated `flutter_app/lib/main.dart` to use path-based URLs instead of hash fragments.

### Task 1: firebase.json

Created `firebase.json` at repo root with:
- `hosting.public = "flutter_app/build/web"` — points to Flutter web build output
- SPA rewrite rule: all routes (`**`) → `/index.html` — prevents 404 on deep link refresh
- WASM MIME header: `**/*.wasm` → `Content-Type: application/wasm` — required for Drift's sqlite3.wasm
- Cache-Control `no-cache, no-store, must-revalidate` for all routes — ensures fresh deploys

### Task 2: usePathUrlStrategy in main.dart

Added `usePathUrlStrategy()` immediately after `WidgetsFlutterBinding.ensureInitialized()`:
- Import: `package:flutter_web_plugins/url_strategy.dart`
- Call: `usePathUrlStrategy()` — converts `/workout` from `/#/workout`
- Placed before all async operations (Supabase init, SharedPreferences)

## Decisions Made

| Decision | Choice | Rationale |
|---|---|---|
| Firebase public dir | `flutter_app/build/web` | Standard `flutter build web` output path |
| Rewrite catch-all | `**` (not `/path/**`) | SPA needs all routes served as index.html |
| Cache policy | no-cache/no-store | Ensures users see latest deploy immediately |
| URL strategy placement | After ensureInitialized, before async ops | Required: must run before any routing logic |
| pubspec.yaml | No change needed | `flutter_web_plugins` is an implicit Flutter SDK dep |

## Verification Results

| Check | Result |
|---|---|
| `cat firebase.json` valid JSON | ✓ Pass |
| `grep '"source": "\*\*"' firebase.json` | ✓ Pass (rewrite + cache headers) |
| `grep 'application/wasm' firebase.json` | ✓ Pass |
| `grep 'usePathUrlStrategy' flutter_app/lib/main.dart` | ✓ Pass |
| `grep 'flutter_web_plugins/url_strategy' flutter_app/lib/main.dart` | ✓ Pass |
| `flutter analyze --no-fatal-infos` | ✓ Exit 0 |
| firebase.json at repo root (not inside flutter_app/) | ✓ Pass |

## DPLY-01 Requirement Satisfied

> Users can open and refresh deep links on Firebase-hosted web routes without 404 errors.

- `/workout` refresh → Firebase serves `/index.html` → Flutter router handles route ✓
- `/progress` refresh → Same SPA rewrite applies ✓
- WASM files load correctly for Drift SQLite ✓
- Clean URLs (no `/#/` hash fragments) ✓

## Deviations from Plan

None — plan executed exactly as written.

## Next Phase Readiness

- Plan 14-06 (wave 2) can proceed: `main.dart` now has `usePathUrlStrategy()` in place
- Firebase deploy (`firebase deploy --only hosting`) will work once `flutter build web` is run
- No blockers identified
