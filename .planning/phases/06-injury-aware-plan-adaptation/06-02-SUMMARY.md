---
phase: 06
plan: 02
subsystem: program-adaptation
tags: [riverpod, providers, injury-adaptation, firestore, user-model, disclaimer]
one-liner: "Injury adaptation provider layer wiring: injuryAdaptedActiveProgramProvider stacking engine on cycle adapter, Firestore-backed disclaimer ack per-injury-ID on UserModel, all screens swapped to injury-aware provider"

dependency-graph:
  requires:
    - 06-01  # InjuryAdaptationEngine domain implementation
  provides:
    - injuryAdaptedActiveProgramProvider (cycle + injury stacked)
    - InjuryAdaptationContext + injuryAdaptationContextProvider
    - acknowledgedInjuryDisclaimerIds on UserModel (Firestore-backed)
    - acknowledgeInjuryDisclaimer / clearInjuryDisclaimerAcknowledgments on ProfileRepository
  affects:
    - 06-03  # UI layer consuming injuryAdaptationContextProvider for disclaimer gate
    - 06-04  # Revert-to-original flow watching injuryAdaptedActiveProgramProvider

tech-stack:
  added: []
  patterns:
    - "Provider stacking: injuryAdaptedActiveProgramProvider wraps adaptedActiveProgramProvider"
    - "Firestore dot-notation merge for per-field disclaimer acknowledgment writes"
    - "AsyncValue.whenData composition for layered async program transformation"

key-files:
  created:
    - path: flutter_app/test/features/programs/providers/adapted_program_provider_test.dart
      note: "Added InjuryAdaptation group (5 tests) to existing provider test file"
  modified:
    - flutter_app/lib/features/programs/providers/adapted_program_provider.dart
    - flutter_app/lib/domain/models/user_model.dart
    - flutter_app/lib/features/profile/data/profile_repository.dart
    - flutter_app/lib/features/programs/presentation/programs_screen.dart
    - flutter_app/lib/features/workouts/presentation/workout_landing_screen.dart
    - flutter_app/lib/features/workouts/presentation/workout_execution_screen.dart
    - flutter_app/lib/features/workouts/presentation/workout_execution_providers.dart
    - flutter_app/lib/features/dashboard/presentation/dashboard_screen.dart
    - flutter_app/lib/features/settings/presentation/injury_profile_screen.dart

decisions:
  - decision: "Disclaimer ack stored as Firestore top-level map field"
    choice: "Map<String, DateTime> acknowledgedInjuryDisclaimerIds with dot-notation merge writes"
    rationale: "Syncs across devices, scoped per injury ID, merge-safe without reading full document"
  - decision: "InjuryAdaptationContext.disclaimerAcknowledgedForAll returns true when no active injuries"
    choice: "hasAcknowledgedDisclaimerForAllActive returns true on empty list"
    rationale: "Empty active injuries = no disclaimer needed; avoids false negative on ack-gate"
  - decision: "_normalizeDocData passes through acknowledgedInjuryDisclaimerIds from Firestore"
    choice: "Conditional include in normalized map only when non-null"
    rationale: "Preserves Firestore Timestamp values through to UserModel.fromJson for correct DateTime parsing"
  - decision: "Test assertion for isContraindicatedOriginal = false"
    choice: "Honored 06-01 decision: engine always sets false, only user revert sets true"
    rationale: "Consistency with established contract; tests document the design intent"

metrics:
  duration: "5 minutes"
  completed: "2026-02-23"
  tests-run: 137
  tests-added: 5
  tasks-completed: 2
  tasks-total: 2
---

# Phase 6 Plan 02: Injury Provider Wiring Summary

## What Was Built

Wired the `InjuryAdaptationEngine` (Phase 06-01) into the Riverpod provider layer and connected all downstream screens to injury-adapted program data.

### Core additions

**`adapted_program_provider.dart`** — Two new providers:
- `injuryAdaptedActiveProgramProvider`: Watches `adaptedActiveProgramProvider` (cycle layer) and applies `InjuryAdaptationEngine.adaptProgram` when the user has active injuries. Returns the same cycle-adapted program unchanged when `activeInjuries` is empty (zero-cost fast-path).
- `InjuryAdaptationContext` + `injuryAdaptationContextProvider`: UI-facing struct exposing `hasActiveInjuries`, `activeInjuries` list, and `disclaimerAcknowledgedForAll` boolean for gate logic in screens.

**`user_model.dart`** — New `acknowledgedInjuryDisclaimerIds: Map<String, DateTime>` field:
- Default `const {}` — no breaking change to existing callers
- `fromJson`: parses as `Map<String, dynamic>`, converts string ISO8601 values to `DateTime`; null-safe
- `toJson`: serialized only when non-empty (ISO8601 strings)
- `copyWith`: included
- `hasAcknowledgedDisclaimerForAllActive(List<InjuryProfileModel>)`: returns `true` when every active injury ID is present as a key (or when injuries list is empty)

**`profile_repository.dart`** — Two new write methods:
- `acknowledgeInjuryDisclaimer({userId, injuryId})`: dot-notation merge write `acknowledgedInjuryDisclaimerIds.$injuryId = FieldValue.serverTimestamp()`
- `clearInjuryDisclaimerAcknowledgments({userId})`: merge-resets the map to `{}`
- `_normalizeDocData`: passes `acknowledgedInjuryDisclaimerIds` through to support Timestamp → DateTime parsing in `UserModel.fromJson`

### Screen reference swap

All 6 consumer screens/providers updated from `adaptedActiveProgramProvider` → `injuryAdaptedActiveProgramProvider`:
- `programs_screen.dart` (ref.watch)
- `workout_landing_screen.dart` (ref.watch)
- `workout_execution_screen.dart` (ref.read + ref.listen)
- `workout_execution_providers.dart` (ref.read)
- `dashboard_screen.dart` (ref.watch)
- `injury_profile_screen.dart` (ref.invalidate × 2)

`adaptedActiveProgramProvider` is intentionally preserved — it continues to exist as the internal cycle-adapted layer that `injuryAdaptedActiveProgramProvider` stacks on top of.

## Tests

5 new tests added to `adapted_program_provider_test.dart` under `group('InjuryAdaptation')`:

| Test | Covers |
|---|---|
| returns base program when no active injuries | Same-reference fast-path |
| replaces contraindicated exercise when knee injury active | Engine replacement, `injuryReplacedOriginal` field |
| adds recovery prep to sessions when injury active | `recoveryPrepExercises` populated for knee |
| adds shoulder-specific recovery prep when shoulder injury active | Shoulder-specific prep exercises (Banded Pull-Aparts, Face Pulls) |
| injury adaptation composes on top of cycle adaptation | Both layers applied: cycle-scaled load + injury replacement |

Full suite: **137 tests, all passing.**

## Decisions Made

| Decision | Choice |
|---|---|
| Disclaimer ack persistence | `Map<String, DateTime>` on UserModel, Firestore dot-notation merge |
| InjuryAdaptationContext with empty injuries | `disclaimerAcknowledgedForAll = true` (no injuries = no disclaimer needed) |
| `_normalizeDocData` passthrough | Conditional include to preserve Timestamp values for `fromJson` |
| `isContraindicatedOriginal` test assertion | `isFalse` — honoring 06-01 contract (engine sets false; user revert sets true) |

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] Added `acknowledgedInjuryDisclaimerIds` passthrough in `_normalizeDocData`**

- **Found during:** Task 1
- **Issue:** `_normalizeDocData` in `ProfileRepository` builds a clean normalized map from raw Firestore data. Without explicitly passing `acknowledgedInjuryDisclaimerIds` through, the field would be silently dropped on every `watchUserProfile` call — making the ack state appear empty in the app despite being persisted in Firestore.
- **Fix:** Added conditional passthrough `if (raw['acknowledgedInjuryDisclaimerIds'] != null)` in `_normalizeDocData`.
- **Files modified:** `flutter_app/lib/features/profile/data/profile_repository.dart`
- **Commit:** c0a390c

**2. [Rule 2 - Missing Critical] Added shoulder injury test for `_shoulderInjury()` helper usage**

- **Found during:** Task 2 — flutter analyze reported `_shoulderInjury` as unused element (warning)
- **Issue:** Plan specified creating both `_kneeInjury()` and `_shoulderInjury()` helpers but only described 4 specific test cases; `_shoulderInjury` would have been dead code.
- **Fix:** Added a 5th test `'adds shoulder-specific recovery prep when shoulder injury active'` that validates shoulder-specific exercises (Banded Pull-Aparts / Face Pulls) are injected. This improves coverage and eliminates the analyzer warning.
- **Files modified:** `flutter_app/test/features/programs/providers/adapted_program_provider_test.dart`
- **Commit:** 3cdb120

**3. [Rule 1 - Bug] Fixed `isContraindicatedOriginal` test expectations**

- **Found during:** Task 2 test execution (2 tests failed initially)
- **Issue:** Initial test assertions expected `isContraindicatedOriginal = true` on replaced exercises. Per STATE.md accumulated decisions from 06-01: "Engine always sets false; only user revert sets true."
- **Fix:** Updated assertions to `isFalse` with explanatory comment documenting the design decision.
- **Files modified:** `flutter_app/test/features/programs/providers/adapted_program_provider_test.dart`
- **Commit:** 3cdb120

## Next Phase Readiness

06-03 (Disclaimer gate UI) and 06-04 (Revert-to-original flow) can proceed. Both providers are live:
- `injuryAdaptationContextProvider` exposes `disclaimerAcknowledgedForAll` for the gate
- `injuryAdaptedActiveProgramProvider` is the canonical program source for all screens
- `ProfileRepository.acknowledgeInjuryDisclaimer` is ready for the confirmation button action
