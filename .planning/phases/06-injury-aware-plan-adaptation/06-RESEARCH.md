# Phase 6: Injury-Aware Plan Adaptation - Research

**Researched:** 2026-02-23
**Domain:** Flutter + Riverpod injury adaptation layer over existing program model
**Confidence:** HIGH — all findings verified directly against codebase

---

## Summary

Phase 6 adds an injury adaptation layer on top of the existing cycle-adaptation architecture. The codebase has a complete, battle-tested pattern for exactly this problem: `CycleProgramGenerator.adaptProgram()` transforms a `ProgramV2` immutably → the injury system must follow the same pattern. No new libraries are needed. All building blocks exist; this phase wires them together in a new domain class and new provider.

The primary difference from cycle adaptation: injury adaptation performs **exercise replacement** (swapping exercises for alternatives) rather than **prescription scaling** (adjusting loads/reps). This requires extending `ProgramExercise` with replacement metadata fields and adding a `recoveryExercises` block to `ProgramSession`. The disclaimer acknowledgment state is stored in Firestore on the user's profile (not SharedPreferences), scoped to the active injury period.

**Primary recommendation:** Model injury adaptation exactly after `CycleProgramGenerator` + `adapted_program_provider.dart`. Create `InjuryAdaptationEngine` in `domain/calculations/`, extend `ProgramExercise` and `ProgramSession` with injury metadata fields, and compose a new `injuryAdaptedActiveProgramProvider` on top of the existing `adaptedActiveProgramProvider`.

---

## Standard Stack

No new dependencies are needed. All required libraries are already present.

### Core (already in pubspec.yaml)
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| flutter_riverpod | ^3.2.1 | State management, providers | Used everywhere in app |
| shared_preferences | ^2.5.4 | Local disclaimer ack persistence | Already used in GuestModeStore |
| cloud_firestore | ^6.1.2 | Profile + injury data persistence | Core Firebase backend |
| flutter (Material) | SDK | AlertDialog, Card, Banner widgets | Already standard UI toolkit |

### No New Dependencies Required
All patterns needed for Phase 6 are already implemented in the codebase:
- Immutable model transformation → `CycleProgramGenerator._copyProgram()`
- Provider composition → `adaptedActiveProgramProvider`
- Mid-workout dialog prompt → `_promptForPhaseUpdate()` in `WorkoutExecutionScreen`
- Badge widget → `SyncStatusBadge`, `CycleAdjustmentExplainer`
- Local key/value store → `GuestModeStore` using SharedPreferences
- Disclaimer copy → `LegalScreen._disclaimer` (existing pattern)

---

## Architecture Patterns

### Recommended Project Structure (new files)

```
lib/
├── domain/
│   ├── calculations/
│   │   └── injury_adaptation_engine.dart     # NEW: pure function, mirrors CycleProgramGenerator
│   └── models/
│       └── program_models.dart               # EXTEND: add replacement fields to ProgramExercise/ProgramSession
│       └── injury_adaptation_models.dart     # NEW: InjuryAdaptationContext, InjuryReplacementEntry
├── features/
│   ├── programs/
│   │   ├── providers/
│   │   │   └── adapted_program_provider.dart # EXTEND: compose injury layer on top of existing
│   │   └── presentation/
│   │       └── widgets/
│   │           └── injury_adaptation_banner.dart  # NEW: mirrors CycleAdjustmentExplainer
│   └── workouts/
│       └── presentation/
│           └── workout_execution_screen.dart  # EXTEND: injury context change mid-workout prompt
test/
├── domain/
│   └── injury_adaptation_engine_test.dart    # NEW: unit tests for replacement logic
└── features/
    └── programs/
        └── providers/
            └── adapted_program_provider_test.dart  # EXTEND: injury scenarios
```

### Pattern 1: Immutable Program Transformation (copy `CycleProgramGenerator`)

The `InjuryAdaptationEngine` must be a pure static class with no side effects. Input: `ProgramV2` + list of `InjuryProfileModel` (active). Output: new `ProgramV2` instance.

```dart
// Source: lib/domain/calculations/cycle_program_generator.dart (direct analog)
class InjuryAdaptationEngine {
  static ProgramV2 adaptProgram({
    required ProgramV2 baseProgram,
    required List<InjuryProfileModel> activeInjuries,
  }) {
    if (activeInjuries.isEmpty) return baseProgram;

    final List<ProgramWeek> adaptedWeeks = baseProgram.weeks
        .map((ProgramWeek week) => _adaptWeek(week: week, injuries: activeInjuries))
        .toList();

    return ProgramV2(
      id: baseProgram.id,
      name: baseProgram.name,
      category: baseProgram.category,
      description: baseProgram.description,
      durationWeeks: baseProgram.durationWeeks,
      sessionsPerWeek: baseProgram.sessionsPerWeek,
      difficulty: baseProgram.difficulty,
      phases: baseProgram.phases,
      weeks: adaptedWeeks,
      cycleAdjustmentProfile: baseProgram.cycleAdjustmentProfile,
    );
  }

  static ProgramWeek _adaptWeek({
    required ProgramWeek week,
    required List<InjuryProfileModel> injuries,
  }) {
    final List<ProgramSession> adaptedSessions = week.sessions
        .map((ProgramSession session) => _adaptSession(session: session, injuries: injuries))
        .toList();
    return ProgramWeek(
      week: week.week,
      phaseId: week.phaseId,
      isTestWeek: week.isTestWeek,
      sessions: adaptedSessions,
    );
  }
}
```

### Pattern 2: ProgramExercise Extension for Replacement Metadata

Extend `ProgramExercise` with nullable injury-replacement fields. This preserves backward compatibility (all existing tests pass unchanged). Fields are set by `InjuryAdaptationEngine` only — never in base program JSON.

```dart
// Source: lib/domain/models/program_models.dart (extension of existing class)
class ProgramExercise {
  ProgramExercise({
    required this.exercise,
    required this.variant,
    required this.sets,
    required this.reps,
    required this.percent1Rm,
    required this.restMinutes,
    required this.notes,
    // NEW fields — null unless this is an injury replacement
    this.injuryReplacedOriginal,
    this.injuryReplacementReason,
    this.isContraindicatedOriginal = false, // true when user reverted
  });

  final String? injuryReplacedOriginal;     // e.g. "Back Squat"
  final String? injuryReplacementReason;   // e.g. "Replaced — knee injury limits deep squat"
  final bool isContraindicatedOriginal;    // true after user-override revert
  // ... existing fields unchanged
}
```

### Pattern 3: ProgramSession Extension for Recovery Block

Prepend a recovery/mobility block into `ProgramSession.exercises` using a sentinel category. Alternatively, add a `recoveryPrepExercises` list to `ProgramSession`. Use the **separate list approach** — it keeps recovery exercises semantically distinct from training exercises and lets the UI render them in a separate section.

```dart
// Source: lib/domain/models/program_models.dart (extension of existing class)
class ProgramSession {
  ProgramSession({
    required this.sessionId,
    required this.sessionName,
    required this.sessionType,
    required this.focus,
    required this.exercises,
    this.recoveryPrepExercises = const [],  // NEW — empty when no injury
    this.recoveryPrepSkippedForSession = false,  // NEW — user skip state
  });

  final List<ProgramExercise> recoveryPrepExercises;
  final bool recoveryPrepSkippedForSession;
  // ... existing fields unchanged
}
```

### Pattern 4: Provider Composition (injury layer on top of cycle layer)

The `injuryAdaptedActiveProgramProvider` watches `adaptedActiveProgramProvider` (cycle-adapted output) and applies injury adaptation on top. This is the **stacking pattern** — each adaptation layer is composable.

```dart
// Source: lib/features/programs/providers/adapted_program_provider.dart (new provider, same file)
final Provider<AsyncValue<ProgramV2?>> injuryAdaptedActiveProgramProvider =
    Provider<AsyncValue<ProgramV2?>>((Ref ref) {
  final AsyncValue<ProgramV2?> cycleAdaptedAsync =
      ref.watch(adaptedActiveProgramProvider);        // cycle layer already applied
  final AsyncValue<UserModel?> profileAsync =
      ref.watch(userProfileStreamProvider);

  final List<InjuryProfileModel> activeInjuries =
      profileAsync.asData?.value?.activeInjuries ?? const [];

  return cycleAdaptedAsync.whenData((ProgramV2? program) {
    if (program == null || activeInjuries.isEmpty) return program;
    return InjuryAdaptationEngine.adaptProgram(
      baseProgram: program,
      activeInjuries: activeInjuries,
    );
  });
});
```

**All screens currently watching `adaptedActiveProgramProvider` must be updated to watch `injuryAdaptedActiveProgramProvider`.**

### Pattern 5: Disclaimer Acknowledgment State

Use Firestore (not SharedPreferences) for disclaimer acknowledgment — it must be per active injury period and device-synced. Store `injuryDisclaimerAcknowledgedAt` on the user document. The `InjuryProfileModel` gets a new optional field.

```dart
// Firestore write (via ProfileRepository or AuthRepository)
await _users.doc(userId).set({
  'injuryDisclaimerAcknowledgedAt': FieldValue.serverTimestamp(),
}, SetOptions(merge: true));

// Read via UserModel
bool get hasAcknowledgedInjuryDisclaimer =>
    injuryDisclaimerAcknowledgedAt != null;
```

**Acknowledgment must be re-required when a new injury becomes active after previous injuries were all resolved** (i.e., a new injury period starts). Reset `injuryDisclaimerAcknowledgedAt` to null in Firestore when user resolves all injuries, OR scope acknowledgment to injury IDs.

Simplest correct approach: store as a `Set<String>` of acknowledged injury IDs on the user document. One-time per injury period = one-time per injury ID.

### Pattern 6: Exercise Replacement Policy

The `InjuryExerciseReplacementPolicy` class (mirrors `CycleAdaptationPolicy`) encapsulates all replacement rules:

1. **Match priority**: same `category` AND overlapping `muscleGroups`
2. **Fallback**: same `category` only (different muscle emphasis)
3. **Final fallback**: safer regression of original movement (defined in static table)

```dart
// Source: exercise_definitions.dart has category + muscleGroups on every exercise
class InjuryExerciseReplacementPolicy {
  const InjuryExerciseReplacementPolicy();

  // Key: original exercise id → safe regressions (ordered by preference)
  static const Map<String, List<String>> _regressionTable = {
    'Back Squat': ['Goblet Squat', 'Air Squats', 'Leg Press'],
    'Conventional Deadlift (No Straps)': ['Romanian Deadlift / RDL (No Straps)', 'Trap Bar / Hex Bar Deadlift (No Straps)'],
    'Flat Barbell Bench Press': ['Dumbbell Bench Press', 'Floor Press'],
    'Strict Press / Military Press': ['Lateral Raises', 'Z-Press'],
    // ... cover all primary lifts
  };

  String? findReplacement({
    required String originalExerciseId,
    required String injuryLocation,        // e.g. "knee", "shoulder"
    required String movementLimitations,   // free text — used for log/reason only
  }) { ... }

  String buildReplacementReason({
    required String originalExerciseId,
    required String replacementId,
    required String injuryLocation,
  }) {
    return 'Replaced — $injuryLocation injury limits ${originalExerciseId.toLowerCase()}. '
        'Using ${replacementId} instead.';
  }
}
```

### Pattern 7: Mid-Workout Injury Context Change Prompt

Directly mirrors the existing `_promptForPhaseUpdate()` in `WorkoutExecutionScreen`. Uses the same `ref.listen<AsyncValue<ProgramV2?>>` hook, same `AlertDialog` with DEFER/APPLY actions.

```dart
// Source: lib/features/workouts/presentation/workout_execution_screen.dart
// Replace ref.listen target from adaptedActiveProgramProvider → injuryAdaptedActiveProgramProvider
// Same _handleAdaptedProgramUpdate logic, updated dialog copy:
AlertDialog(
  title: const Text('Injury Update Available'),
  content: const Text(
    'Your injury profile changed during this workout. Apply updated '
    'safe prescriptions to remaining sets now, or keep current session.',
  ),
  actions: [
    TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('KEEP CURRENT')),
    ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('APPLY SAFE')),
  ],
)
```

### Pattern 8: Override (Revert-to-Contraindicated) Flow

```dart
// In exercise row widget, "Revert to original" button triggers:
final bool confirmed = await showDialog<bool>(
  context: context,
  builder: (ctx) => AlertDialog(
    title: const Text('⚠ Warning: Contraindicated Exercise'),
    content: const Text(
      'This exercise was replaced due to your active injury. '
      'Performing it may worsen your injury or cause harm.\n\n'
      'This app does not provide medical advice. '
      'Consult a healthcare professional before proceeding.',
    ),
    actions: [
      TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('STAY SAFE')),
      TextButton(
        onPressed: () => Navigator.of(ctx).pop(true),
        style: TextButton.styleFrom(foregroundColor: Colors.red),
        child: const Text('REVERT ANYWAY'),
      ),
    ],
  ),
) ?? false;
```

### Anti-Patterns to Avoid

- **Don't mutate base programs**: Always return new `ProgramV2` instances. Never modify in-place.
- **Don't store adapted programs in Firestore**: Adaptation is a view-layer computation. Only the base program + injury profile are persisted.
- **Don't disable adaptation globally while injury is active**: Validated by CONTEXT.md decision — enforcement is in the provider (no `enabled` flag for injury adaptation, unlike cycle adaptation which has `preferences.enabled`).
- **Don't rewrite completed history**: `InjuryAdaptationEngine` must only be applied to the program view. Completed workout logs (`completedWorkouts` collection) are never touched.
- **Don't use SharedPreferences for disclaimer ack**: Must be Firestore-backed so it syncs across devices and is tied to the user identity.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Exercise lookup by category/muscle | Custom search algo | `Exercises.all` list + `ExerciseDefinition.category`/`muscleGroups` | Already structured, ~100 exercises defined |
| Program model copying | Mutable copy constructor | Follow `_copyProgram()` static pattern | Existing tests validate immutability |
| Mid-workout change detection | Custom diffing logic | `_buildSessionSignature()` + `_hasMeaningfulPrescriptionChange()` | Proven approach, already handles edge cases |
| Collapsible info card with badge | Custom widget | Mirror `CycleAdjustmentExplainer` | Matches app design language exactly |
| Firestore user document writes | Direct `set()` calls | `ProfileRepository` / `AuthRepository` pending-write retry pattern | Handles offline + retry already |
| Legal disclaimer text | New screen | Extend `LegalScreen` or follow `_disclaimer` const string pattern | Consistent format with existing legal copy |
| Local flag persistence | New storage abstraction | `SharedPreferences` directly (like `GuestModeStore`) | Already demonstrated pattern |

**Key insight:** This codebase has a mature adaptation layer for cycle-aware programming. Injury adaptation is structurally identical but operates on exercise identity (replacement) rather than prescription magnitude (scaling). Follow every pattern exactly — the tests, the provider composition, the widget structure.

---

## Common Pitfalls

### Pitfall 1: Watching wrong provider in downstream screens
**What goes wrong:** Screens and tests that watch `adaptedActiveProgramProvider` continue showing unadapted exercises after injury adaptation is wired.
**Why it happens:** Both providers exist; wrong one silently returns data.
**How to avoid:** Global grep for `adaptedActiveProgramProvider` references and replace all with `injuryAdaptedActiveProgramProvider`. Update tests.
**Warning signs:** Exercises not replaced in UI even though injury profile is active.

### Pitfall 2: Extending ProgramExercise without updating fromJson/toJson
**What goes wrong:** Replacement metadata fields are lost in serialization round-trips. Tests fail with null field errors.
**Why it happens:** New fields added to constructor but not added to `fromJson`/`toJson`.
**How to avoid:** New fields are view-only (never persisted), so they should NOT be in `toJson` and should be null-default in `fromJson`. Document this explicitly.
**Warning signs:** `program_models_test.dart` failures on round-trip tests.

### Pitfall 3: Disclaimer ack not resetting when new injury starts
**What goes wrong:** User acknowledges disclaimer for injury A, resolves it, gets injury B — and sees no disclaimer.
**Why it happens:** Acknowledgment stored as single boolean rather than per-injury-ID set.
**How to avoid:** Store acknowledgment as a `Map<String, DateTime>` keyed by injury ID in Firestore. Check `injuryDisclaimerAcknowledgedAt[activeInjury.id] != null`.
**Warning signs:** QA finds that a second injury period skips the disclaimer gate.

### Pitfall 4: Recovery prep exercises polluting set-logging
**What goes wrong:** Recovery prep exercises appear in workout completion data or confuse the set-logging UI.
**Why it happens:** Recovery exercises added to `exercises` list are treated identically to training exercises.
**How to avoid:** Store recovery exercises in `recoveryPrepExercises` (separate list on `ProgramSession`). The workout execution screen renders them as a non-logging prep block before the main exercises.
**Warning signs:** Workout summary screen shows extra exercises that shouldn't be logged.

### Pitfall 5: Replacement lookup fails for Olympic lifts with no safe alternative
**What goes wrong:** Engine throws or returns null when no safe replacement exists for a complex lift (e.g., Squat Clean with a shoulder injury).
**Why it happens:** Regression table doesn't cover all exercises, or muscle overlap matching misses edge cases.
**How to avoid:** Fallback chain: (1) same category + overlapping muscle, (2) same category, (3) regression table entry, (4) bodyweight safe regression from a hardcoded minimal set, (5) note-only "consult coach" placeholder if no replacement exists. Never throw.
**Warning signs:** Null replacement exercises in production; null safety violations in tests.

### Pitfall 6: Widget test provider overrides miss injury provider
**What goes wrong:** Widget tests that override `adaptedActiveProgramProvider` don't override `injuryAdaptedActiveProgramProvider`, causing real provider computation to run in tests.
**Why it happens:** Tests copied from pre-Phase-6 patterns that only knew about cycle adaptation.
**How to avoid:** All new widget tests must override `injuryAdaptedActiveProgramProvider` using the same `overrides:` pattern as existing tests.
**Warning signs:** Tests that pass when injury profile is null but fail when InjuryProfileModel is in the provider.

---

## Code Examples

### Injury-Aware Provider Extension
```dart
// Source: lib/features/programs/providers/adapted_program_provider.dart
// Add AFTER existing adaptedActiveProgramProvider and programAdaptationContextProvider

class InjuryAdaptationContext {
  const InjuryAdaptationContext({
    required this.hasActiveInjuries,
    required this.activeInjuries,
    required this.disclaimerAcknowledged,
  });

  final bool hasActiveInjuries;
  final List<InjuryProfileModel> activeInjuries;
  final bool disclaimerAcknowledged;
}

final Provider<InjuryAdaptationContext> injuryAdaptationContextProvider =
    Provider<InjuryAdaptationContext>((Ref ref) {
  final AsyncValue<UserModel?> profileAsync =
      ref.watch(userProfileStreamProvider);
  final UserModel? profile = profileAsync.asData?.value;
  final List<InjuryProfileModel> activeInjuries =
      profile?.activeInjuries ?? const [];

  return InjuryAdaptationContext(
    hasActiveInjuries: activeInjuries.isNotEmpty,
    activeInjuries: activeInjuries,
    disclaimerAcknowledged: profile?.injuryDisclaimerAcknowledged ?? false,
  );
});
```

### Recovery Prep Block Definition
```dart
// Source: lib/domain/calculations/injury_adaptation_engine.dart
// Hard-coded recovery prescriptions by injury location keyword
static const Map<String, List<ProgramExercise>> _recoveryPrepByLocation = {
  'knee': [
    ProgramExercise(
      exercise: 'Bird-Dogs',
      variant: null,
      sets: ExerciseValue.fixed(2),
      reps: ExerciseValue.fixed(10),
      percent1Rm: null,
      restMinutes: 0.5,
      notes: 'Injury recovery prep — move slowly, no pain.',
    ),
    ProgramExercise(
      exercise: 'Bodyweight Lunges',
      variant: null,
      sets: ExerciseValue.fixed(2),
      reps: ExerciseValue.fixed(8),
      percent1Rm: null,
      restMinutes: 0.5,
      notes: 'Injury recovery prep — stop if knee pain.',
    ),
  ],
  'shoulder': [
    ProgramExercise(
      exercise: 'Banded Pull-Aparts',
      variant: null,
      sets: ExerciseValue.fixed(3),
      reps: ExerciseValue.fixed(15),
      percent1Rm: null,
      restMinutes: 0.5,
      notes: 'Injury recovery prep — light band only.',
    ),
    ProgramExercise(
      exercise: 'Face Pulls',
      variant: null,
      sets: ExerciseValue.fixed(2),
      reps: ExerciseValue.fixed(15),
      percent1Rm: null,
      restMinutes: 0.5,
      notes: 'Injury recovery prep — light load, controlled.',
    ),
  ],
  // fallback for unrecognized locations
  'general': [
    ProgramExercise(
      exercise: 'Bird-Dogs',
      variant: null,
      sets: ExerciseValue.fixed(2),
      reps: ExerciseValue.fixed(10),
      percent1Rm: null,
      restMinutes: 0.5,
      notes: 'Injury recovery prep.',
    ),
  ],
};
```

### Unit Test Pattern (mirrors cycle_adaptation_policy_test.dart)
```dart
// Source: test/domain/injury_adaptation_engine_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sundee_fundee_flutter/domain/calculations/injury_adaptation_engine.dart';
import 'package:sundee_fundee_flutter/domain/models/injury_profile_model.dart';
import 'package:sundee_fundee_flutter/domain/models/program_models.dart';

void main() {
  group('InjuryAdaptationEngine', () {
    test('returns base program unchanged when no active injuries', () {
      final program = _program();
      final adapted = InjuryAdaptationEngine.adaptProgram(
        baseProgram: program,
        activeInjuries: const [],
      );
      expect(adapted, same(program)); // or equals(program)
    });

    test('replaces contraindicated exercise when injury location matches', () {
      final adapted = InjuryAdaptationEngine.adaptProgram(
        baseProgram: _programWithBackSquat(),
        activeInjuries: [_kneeInjury()],
      );
      final exercise = adapted.weeks.first.sessions.first.exercises.first;
      expect(exercise.exercise, isNot('Back Squat'));
      expect(exercise.injuryReplacedOriginal, 'Back Squat');
      expect(exercise.injuryReplacementReason, isNotEmpty);
    });

    test('adds recovery prep exercises to each session when injury active', () {
      final adapted = InjuryAdaptationEngine.adaptProgram(
        baseProgram: _program(),
        activeInjuries: [_kneeInjury()],
      );
      final session = adapted.weeks.first.sessions.first;
      expect(session.recoveryPrepExercises, isNotEmpty);
    });

    test('does not modify completed workout history', () {
      // Engine must never touch historical data — test this via provider test
    });
  });
}
```

### Injury Adaptation Banner Widget (mirrors CycleAdjustmentExplainer)
```dart
// Source: lib/features/programs/presentation/widgets/injury_adaptation_banner.dart
class InjuryAdaptationBanner extends StatelessWidget {
  const InjuryAdaptationBanner({
    super.key,
    required this.injuries,
    required this.disclaimerAcknowledged,
    required this.visible,
    required this.onToggleVisibility,
    required this.onAcknowledgeDisclaimer,
  });

  @override
  Widget build(BuildContext context) {
    if (!disclaimerAcknowledged) {
      return _DisclaimerCard(onAcknowledge: onAcknowledgeDisclaimer);
    }
    if (!visible) {
      return Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: onToggleVisibility,
          icon: const Icon(Icons.health_and_safety_outlined),
          label: const Text('Show injury adaptations'),
        ),
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.health_and_safety_outlined, color: Colors.orange),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Plan adapted for active injury. Some exercises replaced.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ]),
            const SizedBox(height: 6),
            const Text(
              'This is not medical advice. Consult a healthcare professional.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            // Badge/changelog summary
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.orange.withValues(alpha: 0.08),
              ),
              child: Text(
                '${injuries.length} active injur${injuries.length == 1 ? 'y' : 'ies'}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.orange,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## State of the Art

| Old Approach | Current Approach | Impact |
|--------------|------------------|--------|
| No injury adaptation (pre-v1.1) | Injury-aware exercise replacement | Exercises safe for injury state |
| No recovery prep block | Recovery prep injected per session | Mobility/warm-up before training |
| No disclaimer in workout context | Disclaimer in plan overview + workout detail | Legal clarity at decision point |
| No mid-workout injury update prompt | AlertDialog prompt (mirrors cycle pattern) | User agency preserved |

**Existing patterns already present in codebase (don't rebuild):**
- `_updatePromptVisible`/`_hasDeferredUpdate` mid-workout state pattern → reuse for injury
- `CycleAdjustmentExplainer` collapsible banner → mirror for injury banner
- `SyncStatusBadge` pill badge → reuse or directly copy for injury badge
- `LegalScreen._disclaimer` const string pattern → extend for injury-specific copy

---

## Open Questions

1. **Injury location → contraindicated exercise mapping**
   - What we know: `InjuryProfileModel.location` is free text ("knee", "shoulder", etc.)
   - What's unclear: Should matching be keyword-based on `movementLimitations` text, or on `location` field? Should there be a structured enum for location rather than free text?
   - Recommendation: Use keyword matching on `location` field for MVP (case-insensitive contains check). If "knee" in location → replace squat/deadlift patterns. This is deterministic and testable. Structured enum can be added post-MVP.

2. **Disclaimer acknowledgment reset condition**
   - What we know: Must be per active injury period (per CONTEXT.md decision)
   - What's unclear: Does "injury period" = a single `InjuryProfileModel.id`, or a window of time where any injury was active?
   - Recommendation: Scope to individual injury IDs (store `Set<String>` of acknowledged IDs in Firestore). This is simplest correct behavior — new injury always requires fresh acknowledgment.

3. **Recovery prep exercise selection granularity**
   - What we know: Recovery block is targeted (e.g., knee prep for knee injury)
   - What's unclear: How targeted? Multiple injuries = multiple recovery blocks?
   - Recommendation: One combined recovery block per session derived from all active injuries. Deduplicate exercises. Keep to ≤5 exercises total.

---

## Sources

### Primary (HIGH confidence)
- `/flutter_app/lib/domain/calculations/cycle_program_generator.dart` — immutable adaptation engine pattern
- `/flutter_app/lib/domain/calculations/cycle_adaptation_policy.dart` — policy class pattern
- `/flutter_app/lib/features/programs/providers/adapted_program_provider.dart` — provider composition pattern
- `/flutter_app/lib/features/workouts/presentation/workout_execution_screen.dart` — mid-workout dialog + deferred update pattern
- `/flutter_app/lib/features/programs/presentation/widgets/cycle_adjustment_explainer.dart` — collapsible banner widget pattern
- `/flutter_app/lib/domain/models/program_models.dart` — `ProgramV2`, `ProgramSession`, `ProgramExercise` models
- `/flutter_app/lib/domain/models/injury_profile_model.dart` — existing injury model
- `/flutter_app/lib/domain/models/exercise_definitions.dart` — exercise library with category + muscleGroups
- `/flutter_app/lib/features/auth/data/guest_mode_store.dart` — SharedPreferences store pattern
- `/flutter_app/lib/features/settings/presentation/legal_screen.dart` — disclaimer copy pattern
- `/flutter_app/pubspec.yaml` — confirmed no new dependencies needed

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — verified from pubspec.yaml, all patterns confirmed in codebase
- Architecture: HIGH — direct analogs exist in codebase for every required component
- Pitfalls: HIGH — identified from codebase inspection, not speculation
- Exercise replacement policy: MEDIUM — location keyword matching approach is reasonable but the specific mapping (which injury locations map to which exercise categories) needs definition during implementation

**Research date:** 2026-02-23
**Valid until:** 2026-03-23 (stable Flutter app codebase, 30-day horizon)
