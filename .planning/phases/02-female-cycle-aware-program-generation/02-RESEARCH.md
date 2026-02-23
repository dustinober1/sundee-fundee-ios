# Phase 02: Female Cycle-Aware Program Generation - Research

**Researched:** 2026-02-23  
**Domain:** Flutter + Riverpod + Firebase program adaptation  
**Confidence:** MEDIUM-HIGH

## Summary

Phase 02 should be implemented as a read-time adaptation pipeline, not a write-time mutation of the base program catalog. The current codebase already has the key primitives: `cycleStatusProvider` for current phase, `CycleProgramGenerator` for phase-based heavy-day adaptation, and user profile fields for `gender` and `cycleTrackingEnabled`. The missing work is wiring these together in providers/repositories so active female users with cycle tracking enabled get an adapted program consistently across Program and Workout flows.

The standard approach in the current Flutter ecosystem is to keep business rules in pure domain functions and compose runtime state with provider-based dependency graphs. Riverpod 3 supports this directly and recommends provider declarations as top-level final variables; it also provides explicit override/test mechanisms that map well to this phase's required test matrix. Firestore should remain the source of truth for enrollment/progress while adaptation remains deterministic from user profile + cycle status + base template.

Firestore and Riverpod docs also point to two implementation constraints: avoid ad hoc synchronization logic (use stream/provider composition), and avoid custom persistence logic for pending writes/offline status when Firestore metadata already exposes this. For this phase, use a deterministic "adapted view" provider and preserve base program IDs so enrollment continuity and progress tracking remain stable.

**Primary recommendation:** Wire a new `adaptedActiveProgramProvider` (female + cycle-enabled gate, fallback-safe) and enforce deterministic adaptation via pure-domain policy + exhaustive generator tests before UI changes.

## Locked Context from 02-CONTEXT.md

### Decisions to honor
- Use current in-app phase adaptation behavior as baseline source of truth.
- Adaptation should be noticeable (primary levers: load and sets/reps volume).
- When readiness input conflicts with cycle phase, blend both signals.
- Recalculate immediately on cycle data changes.
- If workout is in progress when phase updates, ask user whether to apply update.
- If cycle phase is missing, default to last known phase.
- If cycle confidence is low/uncertain, apply reduced adjustments.
- Never block workouts due to low confidence/fallback states.
- Explanations should be short, neutral, and hideable by user.

### Claude discretion areas
- Exact blend policy between readiness and phase.
- Exact UI placement/copy variants for notices and badges.
- Exact styling for explanation components.

## Current Codebase Findings

1. `CycleProgramGenerator` exists and already maps all four cycle phases to workout prescriptions in `flutter_app/lib/domain/calculations/cycle_program_generator.dart`, but there is no production call site for `generateWomensProgram`.
2. `cycleStatusProvider` is already available and recomputes from `periodLogsProvider` + `cycleSettingsProvider` in `flutter_app/lib/features/cycle/providers.dart`.
3. User gating fields exist: `gender` + `cycleTrackingEnabled` in `flutter_app/lib/domain/models/user_model.dart`; profile stream is available via `userProfileStreamProvider` in `flutter_app/lib/features/auth/providers.dart`.
4. Program rendering currently consumes base program data directly via `programsProvider` / `activeProgramProvider` in `flutter_app/lib/features/programs/data/program_repository.dart`; no adaptation stage currently exists.
5. Tests cover cycle calculations and programs UI basics, but no unit tests exist for `CycleProgramGenerator` phase multipliers, which is explicitly required by roadmap success criteria.

## Standard Stack

The established libraries/tools for this phase:

### Core
| Library | Version (repo) | Purpose | Why Standard | Confidence |
|---|---:|---|---|---|
| Flutter SDK | (project SDK range `>=3.0.0 <4.0.0`) | UI + app runtime | Primary framework already in use | HIGH |
| `flutter_riverpod` | 3.2.1 | Dependency graph + derived state + mutation notifiers | Official Riverpod docs support provider composition, overrides, and notifier flows used by this app | HIGH |
| `cloud_firestore` | 6.1.2 | Program/enrollment/cycle persistence + realtime streams | Matches existing repository architecture and Firestore rule model | HIGH |
| `firebase_auth` | 6.1.4 | Session/user identity | Already drives profile/cycle visibility and feature gates | HIGH |

### Supporting
| Library | Version (repo) | Purpose | When to Use | Confidence |
|---|---:|---|---|---|
| `go_router` | 17.1.0 | Route state | Keep existing onboarding/auth gates; no new router pattern needed | HIGH |
| `rxdart` | 0.28.0 | Stream composition in auth flows | Keep only where external stream merge is necessary; prefer Riverpod graph elsewhere | MEDIUM |
| `flutter_test` + `fake_cloud_firestore` | flutter SDK + 4.0.1 | Unit/widget/repository verification | Required for deterministic generator matrix + repository behavior coverage | HIGH |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|---|---|---|
| Riverpod provider graph | BLoC/Cubit layer | Adds migration overhead without phase-specific benefit; current app is already Riverpod-native |
| Read-time adaptation | Persist fully materialized per-user programs | Increases data drift risk and migration complexity; only needed if adaptation becomes expensive/server-driven |
| Pure domain adaptation | UI-layer conditional exercise edits | Harder to test and easy to regress across screens |

**Installation:**
```bash
cd flutter_app
flutter pub get
```

No new dependency is required for this phase.

## Architecture Patterns

### Recommended Project Structure
```text
flutter_app/lib/
  domain/
    calculations/
      cycle_program_generator.dart        # keep pure transformation logic
      cycle_adaptation_policy.dart        # NEW: phase + readiness multipliers, deterministic
  features/
    programs/
      providers/
        adapted_program_provider.dart     # NEW: read-time adaptation provider graph
      presentation/
        programs_screen.dart              # consume adapted provider + explanations
    workouts/
      presentation/
        workout_execution_screen.dart     # prompt if cycle update occurs mid-session
```

### Pattern 1: Read-Time Adapted Program Provider
**What:** Compute adapted program from base program + profile + cycle status at read time.  
**When to use:** Everywhere program sessions are displayed or executed.  
**Why:** Prevents stale persisted variants and keeps enrollment ID/progress stable.

### Pattern 2: Deterministic Adaptation Policy Table
**What:** Store per-phase multipliers/rules in one domain policy map consumed by generator.  
**When to use:** For all load/volume adjustments and low-confidence fallback scaling.  
**Why:** Centralizes behavior, simplifies tests, and keeps UI logic thin.

### Pattern 3: Explicit In-Progress Recompute Gate
**What:** If cycle phase changes during active session, generate pending update and ask user to apply or defer.  
**When to use:** Workout execution flow only.  
**Why:** Honors context requirement and avoids silently changing prescribed sets mid-workout.

### Pattern 4: Confidence-Tier Fallback
**What:** Resolve phase as `current -> lastKnown -> neutralReducedAdjustment` and emit short explanation tag.  
**When to use:** Missing logs, uncertain cycle state, or stale sync windows.  
**Why:** Keeps workouts unblocked while still giving transparent context.

### Pattern 5: Explanation as Derived UI State
**What:** Build short reason strings from adaptation outcome (`phase`, `confidence`, `appliedBlend`) and render in reusable chips/cards.  
**When to use:** Program overview, week cards, workout header.  
**Why:** Keeps copy logic consistent and hideable from a single state flag.

### Anti-Patterns to Avoid
- **Mutating Firestore base programs per user:** creates catalog drift and rollback pain.
- **Embedding multiplier logic in widgets:** makes correctness untestable and inconsistent.
- **Phase recompute side effects in build methods:** risks repeated writes and race conditions.
- **Randomized "smart" adjustments:** breaks test determinism and user trust.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---|---|---|---|
| Cross-feature state propagation | Custom event bus/singletons | Riverpod provider dependencies and `ref.watch` composition | Better traceability/testability with built-in overrides |
| Offline/pending write detection | Custom sync flags on each write | Firestore snapshot metadata (`fromCache`, `hasPendingWrites`) | SDK already handles offline queueing and exposes status |
| Firestore rule validation by trial/error in app | Manual click-through verification | Firestore Local Emulator Suite and rules tests | Prevents shipping rule regressions |
| Phase date arithmetic from scratch in UI | Duplicate cycle-day math per screen | `CycleCalculations` + shared domain policy | Avoids timezone/day-boundary divergence |
| Per-screen adaptation implementations | Re-implement generator in each UI | Single `CycleProgramGenerator`/policy pipeline | One correctness surface and one test matrix |

**Key insight:** Most complexity in this phase is consistency, not algorithm novelty. Reuse SDK/provider primitives and keep adaptation logic pure and centralized.

## Common Pitfalls

### Pitfall 1: "Generator exists but never executes"
**What goes wrong:** UI still shows base program even though cycle logic exists.  
**Why it happens:** No provider/repository integration point for adaptation.  
**How to avoid:** Introduce one canonical adapted program provider and migrate consumers to it.  
**Warning signs:** `CycleProgramGenerator` has zero production call sites.

### Pitfall 2: Phase thrash around local midnight
**What goes wrong:** Prescriptions flip unexpectedly when dates cross timezone boundaries.  
**Why it happens:** Mixed `DateTime.now()` usage without day normalization.  
**How to avoid:** Normalize all adaptation inputs to start-of-day semantics (already modeled in `CycleCalculations`).  
**Warning signs:** Inconsistent phase between cycle screen and programs screen.

### Pitfall 3: Enrollment/progress mismatch after adaptation
**What goes wrong:** Week/day pointers refer to sessions that changed identity.  
**Why it happens:** Adaptation rebuilds sessions with unstable IDs or reordered arrays.  
**How to avoid:** Preserve `sessionId` and week structure; only transform exercise prescription fields.  
**Warning signs:** "Program not found/session mismatch" or jump/complete actions behaving oddly.

### Pitfall 4: Overwriting user intent during in-progress workouts
**What goes wrong:** Cycle updates silently replace prescribed sets while user is mid-session.  
**Why it happens:** Immediate recompute without consent gate.  
**How to avoid:** Stage updates and require explicit apply/defer decision in workout execution UI.  
**Warning signs:** User-reported "weights changed during workout" confusion.

### Pitfall 5: Low-confidence path is not test-covered
**What goes wrong:** Missing logs or uncertain state causes crashes or blocked flows.  
**Why it happens:** Tests only cover happy-path known phase.  
**How to avoid:** Add matrix tests for `null status`, last-known fallback, and reduced-adjustment mode.  
**Warning signs:** Production-only failures when cycle tab is toggled off/on or logs are deleted.

## Code Examples

Verified patterns adapted to current codebase conventions:

### 1) Canonical adapted program provider
```dart
final adaptedActiveProgramProvider = Provider<ProgramV2?>((ref) {
  final ProgramV2? base = ref.watch(activeProgramProvider).asData?.value;
  final CycleStatusResult? cycle = ref.watch(cycleStatusProvider);
  final UserModel? profile = ref.watch(userProfileStreamProvider).asData?.value;
  final List<PeriodLogModel> logs = ref.watch(periodLogsProvider).value ?? const [];
  final String userId = profile?.id ?? '';
  final CycleSettingsModel settings =
      ref.watch(cycleSettingsProvider).value ?? defaultCycleSettings(userId);

  if (base == null) return null;

  final bool shouldAdapt =
      profile?.gender == Gender.female && (profile?.cycleTrackingEnabled ?? false);
  if (!shouldAdapt) return base;

  // Deterministic fallback: use generator even when cycle is uncertain;
  // generator/policy resolves fallback behavior.
  return CycleProgramGenerator.generateWomensProgram(
    base,
    settings,
    logs,
    DateTime.now(),
  );
});
```

### 2) Unit-test matrix for phase multipliers
```dart
test('generateSundayWorkout returns expected load per phase', () {
  expect(
    CycleProgramGenerator.generateSundayWorkout(CyclePhase.menstrual)
        .single.percent1Rm,
    closeTo(0.70, 0.001),
  );
  expect(
    CycleProgramGenerator.generateSundayWorkout(CyclePhase.follicular)
        .single.percent1Rm,
    closeTo(0.80, 0.001),
  );
  expect(
    CycleProgramGenerator.generateSundayWorkout(CyclePhase.ovulation)
        .single.percent1Rm,
    closeTo(0.95, 0.001),
  );
  expect(
    CycleProgramGenerator.generateSundayWorkout(CyclePhase.luteal)
        .single.percent1Rm,
    closeTo(0.85, 0.001),
  );
});
```

### 3) In-progress update apply/defer gate
```dart
Future<void> maybeApplyCycleUpdate({
  required ProgramSession activeSession,
  required ProgramSession recalculatedSession,
  required bool isWorkoutInProgress,
  required Future<bool> Function() askUserToApply,
}) async {
  if (!isWorkoutInProgress) return;
  if (activeSession.exercises == recalculatedSession.exercises) return;

  final bool apply = await askUserToApply();
  if (!apply) return;

  // apply staged session update here (state notifier action)
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|---|---|---|---|
| Hand-wired global state/event buses | Provider graph with declarative dependencies and overrides | Ongoing in modern Flutter state management ecosystem | Better testability and lower coupling |
| Persisting many per-user computed program copies | Keep base template + deterministic runtime adaptation | Common in mobile apps with personalization + offline constraints | Lower schema churn and easier rollback |
| Blind sync indicators | Use Firestore snapshot metadata (`fromCache`, `hasPendingWrites`) | Supported in Firestore listeners; metadata include options documented | Accurate user-facing sync/confidence messaging |

**Deprecated/outdated for this phase:**
- UI-level prescription mutation spread across screens.
- "No cycle data -> block workouts" behavior.

## Open Questions

1. **Readiness signal source for blend logic**
   - What we know: context requires readiness/phase blend when signals conflict.
   - What's unclear: readiness metric source and normalization scale are not defined in codebase.
   - Recommendation: phase plan should define a minimal readiness contract (e.g., 1-5 daily readiness) before final blend implementation.

2. **Definition of low-confidence cycle state**
   - What we know: low-confidence behavior should reduce adjustment magnitude and remain non-blocking.
   - What's unclear: there is no explicit confidence score in `CycleStatusResult` today.
   - Recommendation: add a lightweight confidence enum derived from data freshness/completeness for phase-local use.

3. **Workout in-progress detection boundary**
   - What we know: phase updates during active workout require apply/defer prompt.
   - What's unclear: canonical "in progress" marker and lifecycle event source are not currently explicit.
   - Recommendation: model workout session state in notifier and trigger recompute prompts only while active.

## Deep Dive Addendum (Dig Deeper - 2026-02-23)

This addendum resolves implementation ambiguity for the three open areas using current code capabilities and external evidence.

### 1) Readiness + Cycle Blend Policy (Resolved Recommendation)

#### Evidence snapshot
- Menstrual-cycle and strength literature is mixed: some reviews show small/trivial aggregate effects, while newer reviews report phase-linked strength differences in some contexts.
- A large exercising-women dataset found symptom burden is associated with missed/modified training and competition availability.
- Autoregulation research supports using session-day readiness controls (RPE/APRE/VBT families) over rigid fixed-percentage programming for maximal-strength development.

#### Prescriptive decision
Use **phase-first baseline + readiness modifier**, not replacement:

1. Phase sets the baseline prescription (`CycleProgramGenerator` output).
2. Readiness applies a bounded adjustment layer to load/volume.
3. If signals conflict, keep both: phase determines direction, readiness determines magnitude.

#### Minimal readiness contract for this codebase
- `readinessTier = low | neutral | high`
- Resolve in this order:
  1. Explicit daily readiness input (if introduced in Phase 02 UI)
  2. Same-day symptom severity aggregate from `symptomLogsProvider`
  3. Previous workout average RPE from completed sets
  4. Fallback `neutral`

#### Recommended modifier table
| Readiness Tier | Load Delta | Volume Delta | Notes |
|---|---:|---:|---|
| low | -5% | -1 working set (min 2) | Preserve movement pattern, reduce fatigue risk |
| neutral | 0% | 0 | Keep phase baseline |
| high | +2.5% | +0 to +1 set (cap total weekly increase) | Keep conservative headroom |

#### Guardrails
- Clamp all adapted top-set loads to `[0.65, 0.95] * 1RM`.
- Never apply both high-load and high-volume increases in the same update.
- Keep session structure and `sessionId` stable.

### 2) Low-Confidence Cycle Scoring (Resolved Recommendation)

#### Evidence snapshot
- FIGO/ACOG cycle-regularity guidance supports using cycle interval range and variability as quality indicators.
- Firestore metadata flags (`hasPendingWrites`, `isFromCache`) provide authoritative sync-state confidence signals.

#### Prescriptive decision
Add `cycleConfidenceProvider` and compute confidence from **prediction confidence + sync confidence**.

#### Prediction confidence algorithm (from period logs/settings)
Use last up to 6 cycle intervals (`startDate[i] - startDate[i+1]`):

- `HIGH` when:
  - at least 3 complete intervals, and
  - >=80% intervals are 24-38 days, and
  - `(maxInterval - minInterval) <= 9`
- `MEDIUM` when:
  - at least 2 complete intervals, and
  - >=50% intervals are 24-38 days, and
  - `(maxInterval - minInterval) <= 14`
- `LOW` otherwise.

#### Sync confidence rule (Firestore metadata)
- Downgrade one tier when any relevant stream is from cache only.
- Downgrade to at most `MEDIUM` when pending writes exist.
- Never block training; low confidence only reduces adaptation magnitude.

#### Behavior mapping
| Confidence | Adjustment Magnitude | UI Copy |
|---|---|---|
| HIGH | Full phase + readiness blend | "Cycle-adjusted for current phase" |
| MEDIUM | 75% of planned phase delta | "Cycle estimate applied (moderate confidence)" |
| LOW | 50% of planned phase delta, no aggressive peaks | "Using conservative adjustment while data stabilizes" |

### 3) In-Progress Update Handling (Resolved Recommendation)

#### Evidence snapshot
- Riverpod `ref.listen` is intended for side effects like dialogs/navigation and is safe in widget build contexts.
- Existing app already exposes active-workout state via `workoutExecutionNotifierProvider != null`.

#### Prescriptive decision
Use a **listen-and-stage** pattern:

1. Capture `phaseAtWorkoutStart` on workout initialization.
2. `ref.listen(cycleStatusProvider, ...)` while workout is active.
3. If phase changes and adapted session differs materially, create staged update.
4. Show apply/defer dialog once per phase transition.
5. Apply:
   - update only remaining sets/reps/load.
   - keep completed sets unchanged.
6. Defer:
   - keep current workout unchanged.
   - apply new phase on next session launch.

#### Trigger condition
- Prompt only when all are true:
  - workout active
  - `previousPhase != nextPhase`
  - next session prescription diff exceeds threshold (>=2.5% load OR any set-count change)

#### Verification requirements for plan-phase
- Unit: readiness resolver order and modifier clamps.
- Unit: cycle confidence classifier with synthetic interval distributions.
- Widget: workout screen prompts once on phase change while active.
- Widget: defer keeps current session; apply updates remaining sets only.
- Regression: enrollment progression unaffected by adaptation updates.

## Sources

### Primary (HIGH confidence)
- Riverpod providers docs: [https://riverpod.dev/docs/concepts2/providers](https://riverpod.dev/docs/concepts2/providers)
  - Provider declarations are top-level, and dependencies are declared by reading other providers.
  - Built-in provider overrides/testing support.
- Riverpod testing providers docs: [https://riverpod.dev/docs/how_to/testing#mocking-providers](https://riverpod.dev/docs/how_to/testing#mocking-providers)
  - Override patterns for deterministic test setup.
- Firebase Firestore realtime listeners and metadata: [https://firebase.google.com/docs/firestore/query-data/listen](https://firebase.google.com/docs/firestore/query-data/listen)
  - Metadata changes and `hasPendingWrites` / `fromCache` semantics.
- Firebase Firestore offline persistence: [https://firebase.google.com/docs/firestore/manage-data/enable-offline](https://firebase.google.com/docs/firestore/manage-data/enable-offline)
  - Offline persistence behavior and platform caveats.
- `cloud_firestore` Query API (Dart): [https://pub.dev/documentation/cloud_firestore/latest/cloud_firestore/Query-class.html](https://pub.dev/documentation/cloud_firestore/latest/cloud_firestore/Query-class.html)
  - `snapshots(includeMetadataChanges: ...)` support in current package line.
- `cloud_firestore` SnapshotMetadata API (Dart): [https://pub.dev/documentation/cloud_firestore/latest/cloud_firestore/SnapshotMetadata-class.html](https://pub.dev/documentation/cloud_firestore/latest/cloud_firestore/SnapshotMetadata-class.html)
  - `hasPendingWrites` and `isFromCache` flags.
- Firebase Firestore best practices: [https://firebase.google.com/docs/firestore/best-practices](https://firebase.google.com/docs/firestore/best-practices)
  - ID/indexing/hotspot guidance relevant to program and enrollment data.
- Firestore rules testing with emulator: [https://firebase.google.com/docs/firestore/security/test-rules-emulator](https://firebase.google.com/docs/firestore/security/test-rules-emulator)
  - Recommended local rules verification workflow.
- Flutter app architecture docs: [https://docs.flutter.dev/app-architecture](https://docs.flutter.dev/app-architecture)
  - Layered architecture guidance (UI, state, repositories/services).
- The two FIGO systems...2018 revisions (PubMed): [https://pubmed.ncbi.nlm.nih.gov/30198563/](https://pubmed.ncbi.nlm.nih.gov/30198563/)
  - Normal cycle frequency/regularity framework for confidence thresholds.
- Menstruation in Girls and Adolescents: Using the Menstrual Cycle as a Vital Sign (ACOG): [https://www.acog.org/clinical/clinical-guidance/committee-opinion/articles/2015/12/menstruation-in-girls-and-adolescents-using-the-menstrual-cycle-as-a-vital-sign](https://www.acog.org/clinical/clinical-guidance/committee-opinion/articles/2015/12/menstruation-in-girls-and-adolescents-using-the-menstrual-cycle-as-a-vital-sign)
  - Clinical cycle-interval and abnormal-pattern guidance.
- The Influence of Menstrual Cycle Phases on Maximal Strength Performance... (PubMed): [https://pubmed.ncbi.nlm.nih.gov/38251305/](https://pubmed.ncbi.nlm.nih.gov/38251305/)
  - Newer synthesis reporting phase-dependent maximal strength effects.
- Variations in strength-related measures during the menstrual cycle... (PubMed): [https://pubmed.ncbi.nlm.nih.gov/32456980/](https://pubmed.ncbi.nlm.nih.gov/32456980/)
  - Prior synthesis showing generally small/trivial average effects.
- Prevalence and frequency of menstrual cycle symptoms are associated with availability to train and compete... (PubMed): [https://pubmed.ncbi.nlm.nih.gov/33199360/](https://pubmed.ncbi.nlm.nih.gov/33199360/)
  - Large sample evidence linking symptom burden to altered training/competition availability.
- Autoregulated resistance training for maximal strength enhancement... (PubMed): [https://pubmed.ncbi.nlm.nih.gov/40791980/](https://pubmed.ncbi.nlm.nih.gov/40791980/)
  - Updated network meta-analysis supporting autoregulation strategies.

### Secondary (MEDIUM confidence)
- Flutter testing overview page: [https://docs.flutter.dev/testing/overview](https://docs.flutter.dev/testing/overview)
  - Test pyramid framing for unit/widget/integration coverage in Flutter projects.
- Riverpod refs docs (`ref.listen`, `ref.watch`): [https://riverpod.dev/docs/concepts2/refs](https://riverpod.dev/docs/concepts2/refs)
  - Side-effect listening pattern for phase-change prompts.
- Riverpod provider overrides docs: [https://riverpod.dev/docs/concepts2/overrides](https://riverpod.dev/docs/concepts2/overrides)
  - Deterministic override strategy for adaptation tests.

### Tertiary (LOW confidence)
- None. No critical recommendation is based only on unverified secondary sources.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - direct match to current repo dependencies + official docs.
- Architecture patterns: MEDIUM-HIGH - codebase-specific adaptation design inferred from current structure plus official guidance.
- Pitfalls: MEDIUM - grounded in current code gaps and common Firestore/Riverpod integration failure modes.

**Research date:** 2026-02-23  
**Valid until:** 2026-03-25 (30-day refresh window for dependency/doc drift)
