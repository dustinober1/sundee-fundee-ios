# Phase 10: Verification Evidence and Regression Guardrails - Research

**Researched:** 2026-02-25  
**Domain:** Automated and manual verification evidence for authenticated Home/Programs/Workout paths plus onboarding regression protection  
**Confidence:** HIGH

## Summary

Phase 10 should be implemented as a verification-system phase, not a feature phase. The stack should combine:
1. Emulator-backed Flutter integration tests for the exact UAT path (`login -> dashboard -> programs -> workout start`).
2. Existing fast widget/unit suites for deterministic behavioral coverage.
3. A versioned verification evidence package in the phase folder that captures both automated output and manual UAT artifacts.

The repo already has strong widget/unit coverage for recovery states and onboarding decision logic, but it currently has no `integration_test` harness and no CI gate that runs authenticated emulator-backed end-to-end checks. Phase 10 should close that gap with minimal new dependencies and strict artifact discipline.

**Primary recommendation:** add a canonical emulator-backed integration lane and make evidence generation deterministic (seeded data, fixed account state, fixed artifact locations), then require those artifacts in `10-VERIFICATION.md`.

## Locked Context from 10-CONTEXT.md

The following decisions are fixed inputs for this phase:
- Full critical-flow automated coverage across Home, Programs, and Workout.
- Include unauthenticated guard-path checks in automated coverage.
- Assert positive outcomes and explicit absence of `permission-denied` and onboarding regressions.
- Cover write paths through workout start and session progress durability.
- Manual evidence must include checkpoint artifacts for `login -> dashboard -> programs -> workout start` plus final success evidence.
- Use one canonical verification account with explicit pre-run state checklist.
- If account state drifts, block evidence collection and restore state first.
- For milestone artifact resolution, each finding needs automated proof, UAT proof, and short cause/fix note.

## Current Codebase Findings

1. There is no `flutter_app/integration_test/` directory yet.
2. Existing tests are mostly widget/unit-level and already cover core regression branches (for example dashboard/program/workout recoverable states and onboarding bootstrap matrix), but they do not validate authenticated end-to-end reads/writes through real Firebase emulators.
3. Firebase is behind `ENABLE_FIREBASE` compile-time gating (`flutter_app/lib/firebase/firebase_bootstrap.dart`), which is good for test control but must be explicitly enabled for integration/UAT verification runs.
4. Current GitHub Actions quality job runs `flutter test` only and has no emulator-backed integration gate.
5. The project already has strong phase verification artifact conventions (`NN-VERIFICATION.md`) that Phase 10 can extend without inventing a new reporting format.
6. Project state already lists "Capture executed UAT evidence for the repaired access paths" as an open follow-up, so this phase directly closes a known tracked gap.

## Verification Baseline (Current)

Executed on 2026-02-25:
- `cd flutter_app && flutter test test/features/dashboard/presentation/dashboard_screen_test.dart test/features/programs/presentation/programs_screen_test.dart test/features/workouts/presentation/workout_landing_screen_test.dart test/features/workouts/presentation/workout_write_resilience_test.dart test/features/auth/data/auth_repository_onboarding_bootstrap_test.dart -r compact`
- Result: pass

Interpretation:
- Recovery state behavior and onboarding fallback logic are currently guarded by tests.
- QA-01 is still incomplete because authenticated emulator-backed read/write critical-flow integration tests are not present yet.
- QA-02 is still incomplete because manual UAT artifact capture is not yet recorded for this phase.

## Standard Stack

No new production app libraries are required. Use verification tooling already aligned with FlutterFire and Firebase Emulator Suite.

### Core
| Library/Tool | Version/Channel | Purpose | Why standard for this phase |
|---|---|---|---|
| `integration_test` (Flutter SDK package) | Flutter stable (project uses Flutter 3.41.2 in CI) | Device/web integration tests for full app flows | Official Flutter integration test path; required for end-to-end UAT-path automation |
| `flutter_test` | SDK | Fast widget/unit regression suites | Keeps broad deterministic coverage and fast feedback |
| Firebase Emulator Suite (`auth`, `firestore`) | Firebase CLI managed | Local authenticated read/write validation | Closest safe runtime to production auth/rules behavior without hitting live services |
| `firebase emulators:exec` | Firebase CLI | Deterministic test run lifecycle with startup/shutdown encapsulated | Standard non-hand-rolled way to run test command against emulators |
| Existing app stack (`firebase_auth`, `cloud_firestore`, `flutter_riverpod`, `go_router`) | already in `pubspec.yaml` | Runtime under test | Validation should exercise real app stack, not parallel test-only flow |

### Supporting
| Library/Tool | Purpose | When to use |
|---|---|---|
| `fake_cloud_firestore` (already present) | Fast repository-level tests | Keep for unit speed; do not replace emulator-backed integration lane |
| Emulator import/export (`--import`, `--export-on-exit`) | Stable seeded data and repeatable runs | Canonical verification account/dataset reset per run |
| Firestore Rules coverage endpoint (`:ruleCoverage(.html)`) | Confirm which rules paths were exercised | Attach as supplemental evidence when rules-related regressions are in scope |
| Firebase Test Lab (optional for later hardening) | Managed device validation for integration flows | Use after local emulator lane is stable if device-matrix confidence is needed |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|---|---|---|
| Emulator-backed integration flows | Widget-only mocks/fakes | Faster but does not validate authenticated Firestore access contracts end-to-end |
| Manual emulator orchestration scripts | `firebase emulators:exec` | Hand-rolled lifecycle is fragile and leaves orphan processes/state |
| Ad-hoc artifact notes in PR comments | Phase-local `10-VERIFICATION.md` with linked artifacts | PR comments are not durable milestone evidence |

## Architecture Patterns

### Pattern 1: Two-Lane Verification Pyramid
- Lane A: fast widget/unit suites for broad branch coverage.
- Lane B: narrow, high-value integration flow specs for QA-critical authenticated paths.
- Keep Lane B small and deterministic: only critical UAT paths and known regression vectors.

### Pattern 2: Canonical Emulator Data Contract
- Seed one canonical verification account and minimal enrollment/workout fixtures.
- Start runs with emulator import data; export or reset after each run.
- If canonical state drifts from expected preconditions, fail fast and restore before rerun.

### Pattern 3: Explicit Firebase Runtime Mode for Tests
- Keep existing `ENABLE_FIREBASE` gate.
- Add explicit emulator-mode wiring for integration runs (`useAuthEmulator`, `useFirestoreEmulator`) before auth/session actions.
- Keep host/port configurable for web, simulator, and Android emulator host differences.

### Pattern 4: Flow-Step Assertions + Negative Error Assertions
- At each checkpoint (`login`, `dashboard`, `programs`, `workout start`), assert expected UI state.
- Also assert prohibited failure signatures do not appear (`permission-denied`, onboarding false-prompt).
- Persist a machine-readable checkpoint status artifact and a human-readable evidence summary.

### Pattern 5: Evidence Bundle as First-Class Deliverable
- Store all phase evidence under one deterministic folder path in phase 10.
- Include:
  - test command output,
  - checkpoint screenshots/video references,
  - timestamp/account/environment metadata,
  - finding-resolution checklist entries (`permission-denied`, onboarding false-prompt).
- Make `10-VERIFICATION.md` the index that links every artifact.

### Pattern 6: CI Guardrail for Regression Drift
- Add a dedicated CI job for emulator-backed integration verification.
- Gate merges on that job once stable.
- Keep job separate from default `flutter test` so failures are attributable (unit/widget vs integration environment).

## Don't Hand-Roll

| Problem | Do not build | Use instead | Why |
|---|---|---|---|
| End-to-end auth/firestore simulation | Custom fake auth + fake firestore integration lane | Real Firebase emulators with seeded fixtures | Phase goal is authenticated contract proof, not mock coherence |
| Emulator lifecycle handling | Background shell scripts that guess startup readiness | `firebase emulators:exec` | Official lifecycle management is more reliable and deterministic |
| Rules exercise visibility | Manual log scanning for rule hits | Firestore emulator rule coverage endpoint | Provides concrete, reproducible evidence |
| UAT reporting format | Ad-hoc notes per run | One phase verification document plus artifact links | Durable milestone traceability |
| Recovery of drifted verification state | On-the-fly manual edits in live project | Seeded emulator import/export and pre-run checklist | Prevents non-reproducible evidence |

## Common Pitfalls

### Pitfall 1: Integration tests accidentally targeting live backend
- **What goes wrong:** Tests pass/fail unpredictably and can mutate production/staging data.
- **Why it happens:** Firebase enabled without emulator connection wiring.
- **How to avoid:** Require emulator mode in integration runs and fail startup if emulator host is not configured.

### Pitfall 2: Host mismatch across platforms
- **What goes wrong:** Integration tests cannot connect to emulator from Android emulator/device.
- **Why it happens:** Using `localhost` universally; Android emulator needs host remapping.
- **How to avoid:** Centralize host resolution and document per-target host values.

### Pitfall 3: False confidence from Firestore emulator limitations
- **What goes wrong:** Tests appear green while production can still fail (for example index-related query behavior).
- **Why it happens:** Firestore emulator does not enforce all production characteristics (such as compound-index requirements).
- **How to avoid:** Keep emulator-backed tests, but also preserve deploy/index parity checks and targeted production-like query validation.

### Pitfall 4: Dirty emulator state causing flaky evidence
- **What goes wrong:** Checkpoint results depend on leftover writes from prior runs.
- **Why it happens:** Reused emulator instance without controlled reset/import.
- **How to avoid:** Use import/export or explicit flush/reset at run boundaries.

### Pitfall 5: Missing integration binding initialization
- **What goes wrong:** Integration tests run with incorrect binding behavior and flaky timing.
- **Why it happens:** `IntegrationTestWidgetsFlutterBinding.ensureInitialized()` omitted.
- **How to avoid:** Initialize integration binding at the top of each integration suite.

### Pitfall 6: Treating widget coverage as sufficient for QA-01
- **What goes wrong:** Regression slips through authenticated access path because only mocked/fake layers were tested.
- **Why it happens:** Fast tests are mistaken for end-to-end contract validation.
- **How to avoid:** Keep QA-01 acceptance explicitly tied to emulator-backed authenticated read/write integration tests.

### Pitfall 7: Emulator runtime prerequisites drift
- **What goes wrong:** Local/CI emulator startup breaks after tooling updates.
- **Why it happens:** Emulator Java/runtime requirements change over time.
- **How to avoid:** Pin toolchain in docs/CI and periodically validate emulator startup in automation.

## Code Examples

### 1) Integration test bootstrap for critical UAT path
```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:sundee_fundee_flutter/firebase_options.dart';
import 'package:sundee_fundee_flutter/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    const bool useEmulators = bool.fromEnvironment(
      'USE_FIREBASE_EMULATORS',
      defaultValue: true,
    );
    if (useEmulators) {
      FirebaseAuth.instance.useAuthEmulator('127.0.0.1', 9099);
      FirebaseFirestore.instance.useFirestoreEmulator('127.0.0.1', 8080);
    }
  });

  testWidgets('login -> dashboard -> programs -> workout start', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    // Continue with deterministic login + checkpoint assertions.
    // Assert expected states and assert that permission-denied signatures
    // are absent from user-visible surfaces.
  });
}
```

### 2) Deterministic emulator-backed integration run
```bash
firebase emulators:exec \
  --only auth,firestore \
  --import=.planning/fixtures/firebase \
  --export-on-exit=.planning/fixtures/firebase \
  "cd flutter_app && flutter test integration_test -r compact --dart-define=ENABLE_FIREBASE=true --dart-define=USE_FIREBASE_EMULATORS=true"
```

### 3) Phase verification evidence skeleton
```markdown
## UAT Evidence Run - 2026-02-25T18:40:00Z
- Account: elizabethober@me.com
- Environment: firebase emulators (auth:9099, firestore:8080)
- Commit: <sha>

### Checkpoints
1. Login: pass (artifact: artifacts/login.png)
2. Dashboard Next Workout: pass (artifact: artifacts/dashboard.png)
3. Programs: pass (artifact: artifacts/programs.png)
4. Workout start write path: pass (artifact: artifacts/workout-start.png)

### Finding Resolution
- permission-denied
  - automated evidence: pass (integration_test/...)
  - UAT evidence: pass (artifacts/...)
  - cause/fix note: <short note>
- onboarding false-prompt
  - automated evidence: pass (existing onboarding bootstrap tests)
  - UAT evidence: pass (artifacts/...)
  - cause/fix note: <short note>
```

## QA Traceability (Phase 10)

| Requirement | Gap Today | Research-backed direction |
|---|---|---|
| QA-01 automated coverage for authenticated Home/Programs/Workout read/write paths | No `integration_test` harness; current coverage is primarily widget/unit/fake-store based | Add emulator-backed integration lane for critical UAT path + write assertions and negative regression assertions |
| QA-02 recorded UAT evidence for login -> dashboard -> programs -> workout start | No Phase 10 verification artifact package yet | Produce deterministic artifact bundle and index it from `10-VERIFICATION.md` using fixed checklist format |

## Open Questions

1. Should Phase 10 CI gate run integration tests on every PR, or first land as non-blocking nightly until flakiness is proven low?
2. Is the canonical verification account credential managed in secrets today, or should Phase 10 include secure secret wiring for local + CI evidence runs?
3. Should rule coverage HTML/JSON be required evidence for this phase, or optional supplemental artifact when rules paths are touched?

## Sources

### Primary codebase sources
- `.planning/ROADMAP.md`
- `.planning/REQUIREMENTS.md`
- `.planning/STATE.md`
- `.planning/phases/10-verification-evidence-and-regression-guardrails/10-CONTEXT.md`
- `.github/workflows/flutter-release.yml`
- `flutter_app/pubspec.yaml`
- `flutter_app/lib/firebase/firebase_bootstrap.dart`
- `flutter_app/lib/bootstrap.dart`
- `flutter_app/test/features/dashboard/presentation/dashboard_screen_test.dart`
- `flutter_app/test/features/programs/presentation/programs_screen_test.dart`
- `flutter_app/test/features/workouts/presentation/workout_landing_screen_test.dart`
- `flutter_app/test/features/workouts/presentation/workout_write_resilience_test.dart`
- `flutter_app/test/features/auth/data/auth_repository_onboarding_bootstrap_test.dart`

### Official Flutter/Firebase documentation (validated)
- [Flutter integration tests](https://docs.flutter.dev/testing/integration-tests)
  - Integration tests use `integration_test` and run with `flutter test integration_test`.
- [Firebase Emulator Suite install/configure](https://firebase.google.com/docs/emulator-suite/install_and_configure)
  - Use `emulators:exec` for scripted runs; import/export options support deterministic state.
- [Connect Firestore emulator](https://firebase.google.com/docs/emulator-suite/connect_firestore)
  - Firestore emulator connection patterns, host/port guidance, rule coverage endpoint, and emulator limitations.
- [Connect Auth emulator](https://firebase.google.com/docs/emulator-suite/connect_auth)
  - Auth emulator connection flow and emulator environment wiring.
- [Test security rules with Emulator Suite](https://firebase.google.com/docs/rules/unit-tests)
  - Rules test strategy and official test tooling guidance.
- [Add Firebase Auth to your Flutter app codelab](https://firebase.google.com/codelabs/firebase-auth-in-flutter-apps)
  - Flutter examples for `useAuthEmulator` and `useFirestoreEmulator` wiring.
- [Flutter integration testing in Firebase Test Lab](https://firebase.google.com/docs/test-lab/flutter/integration-testing-with-flutter)
  - Optional device-lab path for integration validation scaling.

## Metadata

**Confidence breakdown:**
- Local codebase gap analysis: HIGH
- Stack/tooling recommendation fit for this repo: HIGH
- CI rollout specifics (blocking vs non-blocking) pending team preference: MEDIUM

**Research date:** 2026-02-25  
**Valid until:** 2026-03-27 (refresh if Flutter/Firebase test tooling or emulator requirements change)
