# Phase 15: Wire AI Preview Adaptation Context - Research

**Researched:** 2026-03-15
**Domain:** React Native / Expo Router — module-level shared state, screen-to-screen context passing, UI display wiring
**Confidence:** HIGH

## Summary

The AI workout preview screen (`app/(app)/ai-workout/preview.tsx`) already renders an `AdaptationChip` component but passes it empty state. The config screen (`app/(app)/ai-workout/config.tsx`) assembles full adaptation context (cycle phase, active injuries, today's readiness) and stores it in module-level shared state via `setSharedWorkout(workout, isOffline, context)`. The `context` object is a `WorkoutGenerationContext` that contains `cyclePhase` (string | null), `activeInjuries` (InjurySummary[]), and `readinessTier` (string | null).

The preview screen calls `getSharedWorkout()` inside a `useEffect` on mount, reads `shared.workout` and `shared.isOffline`, but the comment in lines 104-106 explicitly acknowledges the gap: adaptation context is never unpacked from `shared.context`. As a result, `cyclePhase`, `injuries`, and `readiness` state in preview.tsx remain at their initial empty values and the `AdaptationChip` always returns null.

The fix is a two-part wiring job: (1) unpack `shared.context` fields into preview's local state, and (2) add a test file `app/(app)/ai-workout/__tests__/preview.test.tsx` to verify the chip receives the correct props.

**Primary recommendation:** In the existing `useEffect` in `preview.tsx`, after reading `shared.workout` and `shared.isOffline`, extract `cyclePhase`, `activeInjuries`, and `readinessTier` from `shared.context` and populate local state. Map `InjurySummary[]` back to a display-compatible form for `AdaptationChip`, which accepts `InjuryProfileRecord[]`. The simplest approach is to use a minimal synthetic `InjuryProfileRecord` shaped from the summary, or to extend `SharedWorkoutState` to carry the original `InjuryProfileRecord[]` alongside `context`.

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| CYAD-03 | Adaptation integrates with readiness score for fine-tuning | `shared.context.readinessTier` exists but is not unpacked in preview; readiness is assembled in config and lost in transit |
| AIWK-05 | Generated workouts are saved to history | Saving is already wired (handleStartWorkout calls workoutRepo.saveWorkout); the gap is display-only — AdaptationChip shows what context was factored in, providing the user-visible confirmation of AIWK-05 |
</phase_requirements>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| React Native | (expo-managed) | Component state, rendering | Already in use project-wide |
| Expo Router | (expo-managed) | Screen navigation | Already in use — config pushes to `/ai-workout/preview` |
| TypeScript | ~5.x | Type safety | Project standard — all files are .tsx/.ts |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `@testing-library/react-native` | (jest-expo preset) | Render + fire events in tests | All screen tests in this project use RNTL |
| jest-expo | (expo-managed) | Jest preset for RN | Already configured in `jest.config.js` |

No new dependencies needed. This phase only wires existing data and adds tests using existing tooling.

**Installation:**
No new packages required.

## Architecture Patterns

### Recommended Project Structure
```
app/(app)/ai-workout/
├── config.tsx          # Assembles context, calls setSharedWorkout(workout, isOffline, context)
├── preview.tsx         # NEEDS FIX: unpack shared.context into local state
└── __tests__/
    ├── config.test.tsx  # Existing
    └── preview.test.tsx # NEW: verify AdaptationChip receives non-empty props
```

### Pattern 1: Module-Level Shared State (already established)
**What:** `SharedWorkoutState` is a module-level singleton in `config.tsx`, exported via `getSharedWorkout()` / `setSharedWorkout()` / `clearSharedWorkout()`. The preview screen already imports `getSharedWorkout` and `clearSharedWorkout` from `./config`.
**When to use:** When Expo Router params cannot carry large serialized objects (enforced project decision from Phase 5).
**Current usage in config.tsx (lines 411-433):**
```typescript
interface SharedWorkoutState {
  workout: GeneratedWorkout;
  isOffline: boolean;
  context: WorkoutGenerationContext;
}
let _sharedWorkoutState: SharedWorkoutState | null = null;
export function setSharedWorkout(workout, isOffline, context): void { ... }
export function getSharedWorkout(): SharedWorkoutState | null { ... }
export function clearSharedWorkout(): void { ... }
```

### Pattern 2: InjurySummary vs InjuryProfileRecord Type Gap
**What:** `AdaptationChip` accepts `InjuryProfileRecord[]` (from `@/src/repositories/InjuryRepo`). `WorkoutGenerationContext.activeInjuries` carries `InjurySummary[]` (lighter type without `id`, `uid`, `bodyLocation`, `injuryDate`).

**Two valid options to resolve the mismatch:**

Option A — Store original records in SharedWorkoutState alongside context:
- Add `adaptationInjuries: InjuryProfileRecord[]` to `SharedWorkoutState`
- Pass the raw `injuries` array (already available in config state) into `setSharedWorkout`
- Preview reads `shared.adaptationInjuries` directly — no type mapping needed

Option B — Synthesize a minimal InjuryProfileRecord from InjurySummary:
- Map each `InjurySummary` to a record shape with synthetic `id`, `uid`, using `location` for both `location` and `bodyLocation`
- Works but creates synthetic records that are only used for display

**Recommendation: Option A.** It is more faithful to the existing data — the config screen holds real `InjuryProfileRecord[]` in React state and can pass them directly. This avoids a synthetic mapping that could silently diverge if `InjuryProfileRecord` grows new required fields.

### Pattern 3: Cycle Phase — String to CyclePhase Union
**What:** `WorkoutGenerationContext.cyclePhase` is typed as `string | null`. `AdaptationChip` accepts `CyclePhase | undefined` where `CyclePhase` is a string union (`'menstrual' | 'follicular' | 'ovulation' | 'luteal'`). The values are identical; the only issue is the TypeScript type — a safe cast (`cyclePhase as CyclePhase`) or a narrowing guard is appropriate.

### Pattern 4: Readiness — Tier String vs ReadinessSurveyRecord
**What:** `WorkoutGenerationContext.readinessTier` is `string | null` (e.g., `'high'`, `'neutral'`, `'low'`). `AdaptationChip` accepts `ReadinessSurveyRecord | null`.

`buildAdaptationText` uses `readiness.result.score` to compute `Math.round(score * 10)` for the display string (e.g., "Readiness 7/10"). The tier alone is not enough — the score value is required.

**Resolution:** Same as Option A — store the original `ReadinessSurveyRecord | null` from config's React state in `SharedWorkoutState` so preview can pass it directly to `AdaptationChip`. The readiness record was already in config's `readiness` state variable before being reduced to `readinessTier` for the context.

### Pattern 5: Static Test Helpers (project convention)
**What:** Per project decisions in STATE.md (`[Phase 05-differentiating-features]`) and CLAUDE.md, static helper methods on components enable unit testing without rendering. `buildAdaptationText` in `AdaptationChip.tsx` is already exported for this purpose. The `preview.test.tsx` should test the shared-state unpacking logic using component rendering + testID queries, following the pattern in `config.test.tsx`.

### Anti-Patterns to Avoid
- **Re-fetching adaptation data in preview:** Never load cycle/injury/readiness repos again in preview.tsx — this adds latency, duplicates network calls, and breaks the "context snapshot at generation time" invariant. The config screen assembled context at generation time; preview should display exactly that context.
- **Passing context via Expo Router params:** Already forbidden (Phase 5 decision). Objects are too large for URL params. The shared state module is the established pattern.
- **Mutating shared state in preview before clearing:** The comment in preview.tsx warns not to clear on load — only on Start Workout or Regenerate. This constraint must be preserved.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Cycle phase display text | Custom formatter | `cyclePhaseLabel()` inside `AdaptationChip.tsx` | Already handles all 4 phases; only needs the phase value |
| Adaptation text composition | Custom string builder | `buildAdaptationText()` exported from `AdaptationChip.tsx` | Already handles all edge cases (null, resolved injuries, score rounding) |
| Type narrowing guard for CyclePhase | Runtime check | Simple `as CyclePhase` cast after the string source is verified | The string values are identical; the cast is safe given config always assigns valid phases |

**Key insight:** The `AdaptationChip` component and its `buildAdaptationText` helper already implement all the display logic correctly. This phase is purely a data plumbing task — getting the right values into the already-correct display component.

## Common Pitfalls

### Pitfall 1: Reducing Context Too Early
**What goes wrong:** The `WorkoutGenerationContext` reduces full records to simpler types before storage (e.g., `InjuryProfileRecord[]` → `InjurySummary[]`, `ReadinessSurveyRecord` → tier string). Preview then can only access the reduced form and cannot reconstruct the full types that `AdaptationChip` needs.
**Why it happens:** The context was designed for the AI generation call, not for UI display. Reducing to summaries was appropriate for the generation context but lost display-relevant data.
**How to avoid:** Extend `SharedWorkoutState` to carry the original display-ready records (`InjuryProfileRecord[]` and `ReadinessSurveyRecord | null`) in addition to the already-present `context`. This keeps the `WorkoutGenerationContext` type unchanged.
**Warning signs:** If you see a mapping step that converts `InjurySummary` back to `InjuryProfileRecord`, you have taken the wrong path.

### Pitfall 2: Shared State Module Import Circular Dependency
**What goes wrong:** `preview.tsx` already imports `getSharedWorkout` and `clearSharedWorkout` from `./config`. Any addition to `SharedWorkoutState` must be made in `config.tsx` only — preview imports from config, not the reverse.
**Why it happens:** Module-level shared state lives in `config.tsx` as the source of truth.
**How to avoid:** Only modify `config.tsx` for state shape changes; preview only reads via the exported accessors.

### Pitfall 3: Test Isolation for Shared State
**What goes wrong:** `_sharedWorkoutState` is a module-level variable. If one test sets it and another test reads it without resetting, tests bleed into each other.
**Why it happens:** Module-level singletons persist across test runs within the same Jest worker.
**How to avoid:** In `preview.test.tsx`, call `setSharedWorkout(...)` in `beforeEach` and `clearSharedWorkout()` in `afterEach`. Import `setSharedWorkout`/`clearSharedWorkout` from the config module in tests.

### Pitfall 4: Type Assertion Scope
**What goes wrong:** `shared.context.cyclePhase` is `string | null`. Assigning it directly to `CyclePhase | undefined` fails TypeScript.
**Why it happens:** The `WorkoutGenerationContext` type uses `string | null` for flexibility with the AI function serialization.
**How to avoid:** Use `(shared.context.cyclePhase as CyclePhase) ?? undefined` to convert `null` to `undefined` (which matches the `CyclePhase | undefined` prop type). This is safe because config.tsx only ever assigns valid CyclePhase string values or `null`.

## Code Examples

### Minimal Change: Extend SharedWorkoutState and Unpack in Preview

**In `config.tsx` — extend the interface and setter:**
```typescript
// Source: existing config.tsx pattern, extended for display context
interface SharedWorkoutState {
  workout: GeneratedWorkout;
  isOffline: boolean;
  context: WorkoutGenerationContext;
  // Display-ready adaptation records (richer than WorkoutGenerationContext summary types)
  adaptationCyclePhase: CyclePhase | undefined;
  adaptationInjuries: InjuryProfileRecord[];
  adaptationReadiness: ReadinessSurveyRecord | null;
}

export function setSharedWorkout(
  workout: GeneratedWorkout,
  isOffline: boolean,
  context: WorkoutGenerationContext,
  adaptationCyclePhase: CyclePhase | undefined,
  adaptationInjuries: InjuryProfileRecord[],
  adaptationReadiness: ReadinessSurveyRecord | null,
): void {
  _sharedWorkoutState = {
    workout,
    isOffline,
    context,
    adaptationCyclePhase,
    adaptationInjuries,
    adaptationReadiness,
  };
}
```

**In `config.tsx` — update the call site (inside `handleGenerateWorkout`):**
```typescript
// After: setSharedWorkout(generatedWorkout, generatedOffline, context);
// Change to:
setSharedWorkout(
  generatedWorkout,
  generatedOffline,
  context,
  cyclePhase,           // React state from config screen
  injuries,             // React state from config screen (already filtered to active)
  readiness,            // React state from config screen
);
```

**In `preview.tsx` — unpack inside the existing useEffect:**
```typescript
useEffect(() => {
  const shared = getSharedWorkout();
  if (shared) {
    setWorkout(shared.workout);
    setIsOffline(shared.isOffline);
    // Unpack adaptation context for AdaptationChip display
    setCyclePhase(shared.adaptationCyclePhase);
    setInjuries(shared.adaptationInjuries);
    setReadiness(shared.adaptationReadiness);
  }
}, []);
```

### Test Pattern for Preview (follows config.test.tsx conventions)
```typescript
// Source: existing config.test.tsx pattern adapted for preview
import { setSharedWorkout, clearSharedWorkout } from '../config';

beforeEach(() => {
  setSharedWorkout(
    mockWorkout,
    false,
    mockContext,
    'luteal',           // adaptationCyclePhase
    [mockInjury],       // adaptationInjuries
    mockReadiness,      // adaptationReadiness
  );
});

afterEach(() => {
  clearSharedWorkout();
});

it('displays adaptation chip with cycle phase from shared context', async () => {
  const { getByTestId } = render(<AIWorkoutPreviewScreen />);
  await waitFor(() => {
    expect(getByTestId('adaptation-chip')).toBeTruthy();
  });
});
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Expo Router params for workout object | Module-level shared state | Phase 5 | Objects too large for URL serialization |
| Adaptation context not passed to preview | Adaptation context carried in SharedWorkoutState | Phase 15 (this work) | AdaptationChip shows correct context on preview |

## Open Questions

1. **Should `injuries` in config be pre-filtered before storing in SharedWorkoutState?**
   - What we know: config already filters to `activeInjuries` before building `context.activeInjuries`, but the raw `injuries` state contains all injuries (including resolved).
   - What's unclear: Which array to pass — pre-filtered `activeInjuries` or raw `injuries`?
   - Recommendation: Pass the filtered active injuries (`injuries.filter(i => i.recoveryPhase !== 'resolved')`) matching what was used for generation. `AdaptationChip.buildAdaptationText` internally re-filters for resolved anyway, so either works, but passing already-filtered is semantically cleaner.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Jest (jest-expo preset) |
| Config file | `SundeeFundeeRN/jest.config.js` |
| Quick run command | `cd SundeeFundeeRN && npx jest app/\(app\)/ai-workout/__tests__/preview.test.tsx --no-coverage` |
| Full suite command | `cd SundeeFundeeRN && npx jest --no-coverage` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| CYAD-03 | Readiness score feeds into adaptation display on preview chip | unit | `npx jest app/\(app\)/ai-workout/__tests__/preview.test.tsx -t "readiness"` | ❌ Wave 0 |
| AIWK-05 | Adaptation context visible on preview before saving (chip display) | unit | `npx jest app/\(app\)/ai-workout/__tests__/preview.test.tsx -t "adaptation-chip"` | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `cd SundeeFundeeRN && npx jest app/\(app\)/ai-workout/__tests__/preview.test.tsx --no-coverage`
- **Per wave merge:** `cd SundeeFundeeRN && npx jest --no-coverage`
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] `app/(app)/ai-workout/__tests__/preview.test.tsx` — covers CYAD-03 and AIWK-05 display, tests shared state unpacking, chip visibility

*(config.test.tsx exists and covers shared state write path; preview.test.tsx is the only missing file)*

## Sources

### Primary (HIGH confidence)
- Direct source code inspection: `app/(app)/ai-workout/preview.tsx` — lines 97-108 confirm the gap (comment explicitly states adaptation context is not unpacked)
- Direct source code inspection: `app/(app)/ai-workout/config.tsx` — lines 288, 411-433 confirm `context` is stored in `SharedWorkoutState` with cycle/injury/readiness data
- Direct source code inspection: `src/components/ai-workout/AdaptationChip.tsx` — confirms prop types (`CyclePhase | undefined`, `InjuryProfileRecord[]`, `ReadinessSurveyRecord | null`)
- Direct source code inspection: `src/domain/ai-workout/workout-generation-context.ts` — confirms `WorkoutGenerationContext` shape and type reductions
- `.planning/v1.0-MILESTONE-AUDIT.md` — lines 36-37 confirm the exact integration gap being fixed

### Secondary (MEDIUM confidence)
- `app/(app)/ai-workout/__tests__/config.test.tsx` — establishes testing patterns (mock structure, renderAndGenerate helper, act/waitFor usage) that preview tests should follow
- `src/components/ai-workout/__tests__/AdaptationChip.test.tsx` — confirms `buildAdaptationText` is the display logic; chip tests are purely about static helper, not screen-level rendering

## Metadata

**Confidence breakdown:**
- Gap identification: HIGH — audit file and source code are unambiguous
- Fix approach: HIGH — code inspection confirms Option A (extend SharedWorkoutState) is sound with no circular dependency risk
- Test patterns: HIGH — config.test.tsx provides a directly applicable template
- Type safety: HIGH — TypeScript types for all involved interfaces verified from source

**Research date:** 2026-03-15
**Valid until:** Stable until config.tsx SharedWorkoutState interface or AdaptationChip props change
