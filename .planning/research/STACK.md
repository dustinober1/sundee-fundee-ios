# Stack Research

**Domain:** Flutter full rewrite for offline-first workout tracking (web + Android + iOS)
**Researched:** 2026-02-20
**Confidence:** HIGH (core platform/docs), MEDIUM (some package-version snapshots from pub.dev search)

## Recommended Stack

### Core Technologies

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| Flutter SDK | 3.41.x (stable) | Unified UI/runtime for web, Android, iOS | Meets milestone goal of one codebase across all 3 targets; official release line is current in Feb 2026. |
| Dart | 3.11.x (via Flutter 3.41) | Language/runtime | Required baseline for modern Flutter ecosystem and package compatibility. |
| Firebase (project + CLI) | Firebase CLI latest (>=12.1.0 per Flutter web hosting docs) | Hosting/deploy pipeline + cloud services | Official framework-aware workflow supports Flutter web deployment and CI-friendly release path. |
| Firestore | `cloud_firestore: ^6.1.2` | Cloud backup/sync data store | Natural parity replacement for Supabase sync UX with FlutterFire-first integration and offline cache support. |
| Local DB (offline-first) | `drift: ^2.31.0` + `drift_flutter: ^0.2.8` | Primary local persistence | Best fit for Sundee-Fundee constraint: local-first across mobile + web with one data model strategy. |

### Supporting Libraries

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `firebase_core` | `^4.4.0` | Firebase bootstrap | Always; app init on all platforms. |
| `firebase_auth` | `^6.1.4` | Optional account/sign-in for sync | Use when user enables cross-device backup/sync. |
| `flutterfire_cli` | latest | Generates `firebase_options.dart` + platform wiring | Use during setup and whenever adding Firebase products/platforms. |
| `flutter_riverpod` | `^3.2.1` | App state management | Replace React Context with explicit, testable state graph. |
| `go_router` | `^17.1.0` | Navigation/routing | Equivalent of App Router-style declarative routes in Flutter. |
| `fl_chart` | `^1.1.1` | Progress charting | Replace Recharts in progress/dashboard views. |
| `connectivity_plus` | `^7.0.0` | Connectivity awareness | Keep subtle offline/pending-sync UX parity from v1.1. |
| `freezed` + `json_serializable` | `^3.2.5` + `^6.13.0` | Immutable models + JSON mapping | Recommended for stable domain models and deterministic serialization for local+cloud sync. |

### Development Tools

| Tool | Purpose | Notes |
|------|---------|-------|
| `flutter_test` | Unit/widget tests | Replaces Vitest unit/integration layers. |
| `integration_test` (SDK package) | Cross-platform end-to-end app flow tests | Replaces Playwright for core workout-flow parity on Android/iOS/web. |
| `very_good_analysis` | Lint baseline | Strong defaults for large Flutter codebases. |
| `build_runner` + `drift_dev` | Code generation (models + SQL schema) | Required if using drift + freezed/json_serializable. |

## Installation

```bash
# Create rewrite app (recommended in new folder/repo path)
flutter create sundee_fundee_flutter

# Core app dependencies
flutter pub add flutter_riverpod go_router drift drift_flutter fl_chart connectivity_plus

# Firebase + sync
flutter pub add firebase_core firebase_auth cloud_firestore firebase_analytics firebase_crashlytics firebase_app_check

# Model + codegen
flutter pub add freezed_annotation json_annotation
flutter pub add -d build_runner freezed json_serializable drift_dev very_good_analysis

# FlutterFire CLI (global)
dart pub global activate flutterfire_cli

# Firebase CLI for hosting/deploy
npm install -g firebase-tools
firebase login

# Configure Firebase apps + options file
flutterfire configure

# Firebase Hosting (framework-aware Flutter web deploy)
firebase experiments:enable webframeworks
firebase init hosting
firebase deploy
```

## Alternatives Considered

| Recommended | Alternative | When to Use Alternative |
|-------------|-------------|-------------------------|
| `flutter_riverpod` | `bloc` / `Cubit` | Choose bloc if team already has deep Bloc conventions and tooling. |
| `drift` local-first SQL | `Hive CE` / NoSQL stores | Choose Hive only if relational queries/reporting are intentionally minimal. |
| Firestore sync | Keep Supabase from v1.x | Choose Supabase only if backend continuity outweighs tighter FlutterFire/Firebase integration. |
| `fl_chart` | `syncfusion_flutter_charts` | Choose Syncfusion for advanced enterprise chart features/licensing fit. |

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| Mixing Supabase + Firebase in v2.0 baseline | Doubles auth/sync complexity during a rewrite; increases migration and ops risk | Pick one cloud path for v2.0 (recommend Firebase stack end-to-end). |
| Mobile-only persistence plugins without strong web strategy | Breaks unified web/Android/iOS parity objective | Use drift with its web-compatible runtime path. |
| Premature microservices/backend split in milestone v2.0 | Slows parity delivery; not needed for current product scale | Monorepo app + Firebase products first, then split only if scale demands. |
| Rebuilding PWA install/service-worker semantics manually first | Flutter web + Firebase Hosting already provide a production path; manual SW work adds risk | Ship parity first, optimize web/PWA behavior in later milestone if needed. |

## Stack Patterns by Variant

**If offline-first parity is the highest priority (recommended default):**
- Local source of truth: `drift`
- Cloud backup/sync: Firestore + Firebase Auth (optional account mode)
- Sync engine: explicit queue + last-write-wins timestamps (ported from v1 logic)

**If fastest rewrite speed is the highest priority (sacrifice some robustness):**
- Skip drift initially; use Firestore cache + in-memory state
- Accept lower confidence for advanced offline conflict handling
- Use only for internal pilot, not production parity target

## Version Compatibility

| Package A | Compatible With | Notes |
|-----------|-----------------|-------|
| Flutter 3.41.x | Dart 3.11.x | Same release generation (Feb 2026). |
| `firebase_core ^4.4.0` | `firebase_auth ^6.1.4`, `cloud_firestore ^6.1.2` | Keep FlutterFire family versions current together. |
| `drift ^2.31.0` | `drift_flutter ^0.2.8`, `drift_dev ^2.31.0` | Use matching major/minor lines to reduce generator/runtime mismatch. |
| `freezed ^3.2.5` | `freezed_annotation ^3.1.0`, `build_runner ^2.11.1` | Standard model-codegen toolchain pairing. |

## Integration / Migration Notes from v1.x

- **React Context → Riverpod providers**
  - `UserContext`, `ExerciseContext`, `RestTimerContext` map cleanly to scoped providers/notifiers.
- **Dexie IndexedDB schema → Drift tables**
  - Preserve table semantics (`users`, `oneRepMaxes`, `activeCycles`, `completedWorkouts`, `completedSets`, `setMetrics`) and migrate in phases.
- **Supabase optional sync → Firebase Auth + Firestore optional sync**
  - Keep UX contract: app fully usable offline without account; cloud sync is opt-in enhancement.
- **Recharts → fl_chart**
  - Re-implement 1RM trend, weekly volume, and activity visualizations with equivalent datasets.
- **Playwright E2E → integration_test matrix**
  - Keep same critical user journeys and acceptance criteria; only tooling changes.

## Sources

- Flutter release + SDK archive + release notes (HIGH)
  - https://docs.flutter.dev/release/whats-new
  - https://docs.flutter.dev/install/archive
  - https://docs.flutter.dev/release/release-notes
- Flutter web deployment + Firebase Hosting integration docs (HIGH)
  - https://docs.flutter.dev/deployment/web
  - https://firebase.google.com/docs/hosting/frameworks/flutter
- FlutterFire setup docs (HIGH)
  - https://firebase.google.com/docs/flutter/setup
- Drift web/platform guidance (HIGH)
  - https://drift.simonbinder.eu/platforms/web/
- Pub package version references (MEDIUM: snapshot accuracy depends on pub.dev current index)
  - https://pub.dev/packages/firebase_core/versions
  - https://pub.dev/packages/firebase_auth/versions
  - https://pub.dev/packages/cloud_firestore/versions
  - https://pub.dev/packages/flutter_riverpod/versions
  - https://pub.dev/packages/go_router/versions
  - https://pub.dev/packages/drift/versions
  - https://pub.dev/packages/drift_flutter/versions
  - https://pub.dev/packages/drift_dev/versions
  - https://pub.dev/packages/fl_chart/versions
  - https://pub.dev/packages/connectivity_plus/versions
  - https://pub.dev/packages/freezed/versions
  - https://pub.dev/packages/freezed_annotation/versions
  - https://pub.dev/packages/json_serializable/versions
  - https://pub.dev/packages/build_runner/versions
  - https://pub.dev/packages/very_good_analysis/versions
  - https://pub.dev/packages/firebase_analytics/versions
  - https://pub.dev/packages/firebase_crashlytics/versions
  - https://pub.dev/packages/firebase_app_check

---
*Stack research for: Sundee-Fundee v2.0 Flutter Full Rewrite*
*Researched: 2026-02-20*