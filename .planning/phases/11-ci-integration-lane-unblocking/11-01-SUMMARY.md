---
phase: 11
plan: 01
subsystem: ci-integration
tags: [firebase, emulators, integration-tests, flutter, ci]
one-liner: "Firebase emulator ports locked in firebase.json; initializeHarness() silently skips on Linux CI (no Firebase plugins)"

dependency-graph:
  requires: []
  provides:
    - firebase.json emulator port configuration (auth:9099, firestore:8080, ui:4000)
    - No-op guard in FirebaseEmulatorTestHarness.initializeHarness()
  affects:
    - 11-02: CI workflow can now run integration_test/critical_access_flow_test.dart on Linux runner

tech-stack:
  added: []
  patterns:
    - "Environment-flag guard: early return on missing Firebase plugin support"
    - "firebase.json emulator port canonicalization"

file-tracking:
  key-files:
    created: []
    modified:
      - firebase.json
      - flutter_app/integration_test/support/firebase_emulator_test_harness.dart

decisions:
  - choice: "Collapse two guard throws into single combined early-return"
    rationale: "Firebase is never called after initializeHarness() when test uses Riverpod overrides; MissingPluginException on Linux is avoided by silent no-op"
    alternatives: ["Keep separate guards with warning prints instead of throws"]

metrics:
  duration: "~1 min"
  tasks-completed: 2
  completed: "2026-02-25"
---

# Phase 11 Plan 01: CI Integration Lane Unblocking — Emulator Config + Harness Guard Summary

## What Was Built

Two targeted changes to unblock the integration test CI lane on Linux runners where Firebase Flutter plugins are unavailable (`MissingPluginException`).

### Task 1 — firebase.json emulator port configuration (commit `693080f`)

Added a top-level `emulators` block to `firebase.json` with deterministic port assignments:

```json
"emulators": {
  "auth": { "port": 9099 },
  "firestore": { "port": 8080 },
  "ui": { "enabled": true, "port": 4000 }
}
```

Ports match the harness compile-time constants (`_authPort: 9099`, `_firestorePort: 8080`), ensuring local emulator startup and integration test targeting use the same ports without configuration drift.

### Task 2 — initializeHarness() no-op guard (commit `42b3403`)

Replaced the two `throw StateError(...)` guard branches in `FirebaseEmulatorTestHarness.initializeHarness()` with a single combined early-return:

```dart
if (!_firebaseEnabled || !_useEmulators) {
  // Firebase plugins are unavailable on Linux desktop and unnecessary
  // when the test uses Riverpod provider overrides exclusively.
  return;
}
```

The test (`critical_access_flow_test.dart`) uses 100% Riverpod provider overrides for data — Firebase is never called after init. On Linux CI the harness now silently skips initialization instead of throwing `StateError`. All emulator-backed behavior (Firebase.initializeApp, useAuthEmulator, useFirestoreEmulator, Settings) is preserved when both `ENABLE_FIREBASE=true` and `USE_FIREBASE_EMULATORS=true`.

## Verification Results

| Check | Result |
|---|---|
| `firebase.json` valid JSON with `emulators.auth.port==9099` | ✅ OK |
| `firebase.json` valid JSON with `emulators.firestore.port==8080` | ✅ OK |
| `throw StateError` count in `initializeHarness()` | ✅ 0 |
| Early `return;` present in `initializeHarness()` | ✅ 1 |
| `Firebase.initializeApp` still present | ✅ preserved |
| `flutter analyze` exit code | ✅ 0 (2 pre-existing info warnings, no new issues) |

## Decisions Made

| Decision | Choice | Rationale |
|---|---|---|
| Guard collapse strategy | Single `!_firebaseEnabled \|\| !_useEmulators` return | Simpler; both flags must be true for emulator init; either being false means skip |
| Existing `checkpoint()` throws | Unchanged | Plan explicitly required no change to other methods |

## Deviations from Plan

None — plan executed exactly as written.

## Next Phase Readiness

- ✅ `firebase.json` emulator config in place
- ✅ `initializeHarness()` safe on Linux/no-plugin environments
- ➡️ 11-02 can now wire the CI workflow to run `critical_access_flow_test.dart` on Linux runner with Riverpod-only overrides
