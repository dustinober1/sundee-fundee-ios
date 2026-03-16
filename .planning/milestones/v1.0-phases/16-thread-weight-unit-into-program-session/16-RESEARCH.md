# Phase 16: Thread Weight Unit into Program Session - Research

**Researched:** 2026-03-16
**Domain:** React Native / Expo Router — weight unit preference propagation into program session screen
**Confidence:** HIGH

## Summary

Phase 16 closes the final remaining gap for PLAT-05 ("user can switch between lbs and kg"). The audit identified three hardcoded 'lbs' locations that were not addressed in Phase 13:

1. `programs/session.tsx` — the screen does not load `weightUnit` from `SettingsRepo` at all; all weight display is implicitly lbs.
2. `src/components/programs/target-weight.ts` — `formatTargetWeight()` returns `"${weight} lbs"` unconditionally.
3. `src/components/benchmarks/scoring-input.ts` — `formatScore('weight', score)` returns `"${score} lbs"` unconditionally.

The infrastructure is completely in place and battle-tested. `formatWeight`, `getSettingsRepo`, `WeightUnit`, and `DEFAULT_SETTINGS` are already used by six other screens. The pattern for loading settings in a screen is identical in `maxes.tsx`, `workout-detail.tsx`, `workout-session.tsx`, `exercise-detail.tsx`, and `history.tsx`. This phase is a mechanical application of those patterns to the one screen and two utility functions that were missed.

The rounding convention for `target-weight.ts` requires special attention: currently it rounds calculated weights to the nearest 5 lbs. When kg is the display unit, the output of `calculateTargetWeight` (which returns lbs) must be passed through `formatWeight(lbs, unit)` rather than appending a raw unit label. The rounding-to-nearest-5 can remain as a lbs-internal step before conversion.

**Primary recommendation:** Add `weightUnit` loading to `session.tsx` via `useFocusEffect` (matching the existing data-load pattern already in that file), add a `weightUnit` parameter to `formatTargetWeight` and `formatScore('weight')`, then pass the unit through from the screen. No new dependencies.

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| PLAT-05 | User can switch between lbs and kg | `weightUnit` is stored in `AppSettings` and loaded via `getSettingsRepo`; `formatWeight` converts lbs→kg correctly; only `programs/session.tsx`, `target-weight.ts`, and `scoring-input.ts` remain hardcoded |
</phase_requirements>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `formatWeight` | internal (`src/utils/formatWeight.ts`) | Convert stored-lbs to display string with correct unit suffix | Single source of truth; used by workout-detail, maxes, history, exercise-detail, workout-session, export |
| `getSettingsRepo` / `AppSettings` | internal (`src/repositories/SettingsRepo.ts`) | Load persisted `weightUnit` preference | Factory chooses Firestore vs AsyncStorage per auth state |
| `WeightUnit` | `src/domain/types/index.ts` | `'lb' | 'kg'` type alias | Used consistently across entire codebase |
| `DEFAULT_SETTINGS` | `src/repositories/SettingsRepo.ts` | `{ weightUnit: 'lb', ... }` fallback | Prevents undefined state when settings load fails |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `useFocusEffect` (expo-router) | already imported in session.tsx | Re-run settings load when screen regains focus | Session screen already uses `useFocusEffect` for enrollment/program load — add settings to same or parallel effect |
| `useCallback` (React) | already imported in session.tsx | Wrap async load for `useFocusEffect` | Required by `useFocusEffect` signature |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Per-screen settings load | React Context for weightUnit | Context avoids repeated async calls but adds indirection; per-screen load matches all existing patterns in this codebase — no deviation |
| Modifying `calculateTargetWeight` to return kg | Keep returning lbs, convert at display | Target weights are always stored in lbs (ExerciseMax uses lbs); convert only at display layer — consistent with app-wide storage convention |

**No additional installation required.**

## Architecture Patterns

### Affected Files
```
app/(app)/programs/session.tsx               ← add weightUnit state + settings load
src/components/programs/target-weight.ts     ← add WeightUnit param to formatTargetWeight
src/components/programs/__tests__/targetWeight.test.ts  ← update existing tests, add kg cases
src/components/benchmarks/scoring-input.ts   ← add WeightUnit param to formatScore('weight')
src/components/benchmarks/__tests__/scoringInput.test.ts ← update existing test, add kg case
app/(app)/programs/__tests__/session.test.tsx  ← NEW (Wave 0 gap)
```

### Pattern 1: Settings Load Inside useFocusEffect (established variant)
**What:** Load `weightUnit` from `SettingsRepository` inside the existing `useFocusEffect` data-load block in `session.tsx`.
**When to use:** When the screen already has a `useFocusEffect` data load — add settings read to the same async scope.

```typescript
// Source: pattern from app/(app)/(tabs)/maxes.tsx (lines 100–113) adapted for useFocusEffect
// Already imported: getSettingsRepo, DEFAULT_SETTINGS, useSession, useFocusEffect, useCallback
import { getSettingsRepo, DEFAULT_SETTINGS } from '@/src/repositories/SettingsRepo';
import type { WeightUnit } from '@/src/domain/types';
import { formatWeight } from '@/src/utils/formatWeight';

// In component state:
const [weightUnit, setWeightUnit] = useState<WeightUnit>(DEFAULT_SETTINGS.weightUnit);

// In useFocusEffect loadData(), after other loads succeed:
const settingsRepo = getSettingsRepo(isGuest);
const stored = await settingsRepo.getSettings(uid);
if (stored?.weightUnit) {
  setWeightUnit(stored.weightUnit);
}
```

Alternatively, use a separate `useEffect` for settings (mirrors `maxes.tsx` exactly). Either approach is acceptable; merging into `useFocusEffect` avoids a second async call on every focus.

### Pattern 2: formatTargetWeight with WeightUnit param
**What:** Add a `unit: WeightUnit = 'lb'` parameter to `formatTargetWeight`. When weight is non-null, pass it through `formatWeight(weight, unit)` instead of hardcoding `"${weight} lbs"`.

Current (broken):
```typescript
// Source: src/components/programs/target-weight.ts line 109
export function formatTargetWeight(weight: number | null, percentage: number): string {
  if (weight !== null) {
    return `${weight} lbs`;  // hardcoded
  }
  ...
}
```

Corrected:
```typescript
// Unit-aware version
import { formatWeight } from '@/src/utils/formatWeight';
import type { WeightUnit } from '@/src/domain/types';

export function formatTargetWeight(
  weight: number | null,
  percentage: number,
  unit: WeightUnit = 'lb'
): string {
  if (weight !== null) {
    return formatWeight(weight, unit);
  }
  const pct = Math.round(percentage * 100);
  return `${pct}%`;
}
```

### Pattern 3: formatScore('weight') with WeightUnit param
**What:** Add a `unit: WeightUnit = 'lb'` parameter to `formatScore`. Only the `'weight'` case needs the unit; all other cases (time, reps, roundsAndReps, distance) are unitless.

Current (broken):
```typescript
// Source: src/components/benchmarks/scoring-input.ts line 45
case 'weight':
  return `${score} lbs`;  // hardcoded
```

Corrected:
```typescript
import { formatWeight } from '@/src/utils/formatWeight';
import type { WeightUnit } from '@/src/domain/types';

export function formatScore(
  scoringType: BenchmarkScoringType,
  score: number,
  unit: WeightUnit = 'lb'
): string {
  switch (scoringType) {
    ...
    case 'weight':
      return formatWeight(score, unit);
  }
}
```

**Important:** Benchmark scores for `'weight'` type are stored as lbs in the DB (consistent with the rest of the app). `formatWeight` takes lbs and converts to display unit — this is the correct call.

### Pattern 4: ExerciseRow in session.tsx passes unit through
**What:** Thread `weightUnit` from screen state into `ExerciseRow` and then into `formatTargetWeight`.

```typescript
// ExerciseRowProps gains weightUnit
interface ExerciseRowProps {
  exercise: ProgramExercise;
  maxes: ExerciseMax[];
  weightUnit: WeightUnit;  // new
}

// Inside ExerciseRow, weight range display also hardcodes 'lbs':
// Line 107: targetWeightDisplay = `${lo}–${hi} lbs`;
// Fix: use formatWeight for lo and hi
if (lo !== null && hi !== null) {
  targetWeightDisplay = `${formatWeight(lo, weightUnit)}–${formatWeight(hi, weightUnit)}`;
}
```

### Anti-Patterns to Avoid
- **Passing `unit` to `calculateTargetWeight`**: That function returns lbs (internal storage). Unit conversion belongs at the display layer (`formatTargetWeight`), not the calculation layer.
- **Converting kg→lbs before `calculateTargetWeight`**: The `maxes` array stores `estimated1RM` in lbs. No conversion needed before calculation.
- **Calling `getSettingsRepo` outside `useFocusEffect`/`useEffect`**: Repo construction is cheap but the async call must be in an effect to avoid blocking render.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| lbs→kg conversion | Custom math in formatTargetWeight | `formatWeight(lbs, unit)` | Handles 0.5 kg rounding, suffix, all edge cases |
| Rounding to nearest plate | Re-implement in kg path | Leave rounding in lbs before conversion | `calculateTargetWeight` already rounds to nearest 5 lbs; `formatWeight` converts afterward — no kg plate rounding needed for display |
| Settings persistence | Manual AsyncStorage key | `getSettingsRepo(isGuest)` | Factory already selects Firestore vs local; same key used everywhere |

**Key insight:** `formatWeight` is the single source of truth. Any place that appends a unit suffix manually is a bug waiting to happen when the user switches units.

## Common Pitfalls

### Pitfall 1: Weight range in ExerciseRow also hardcodes 'lbs'
**What goes wrong:** `formatTargetWeight` is fixed but line 107 in `session.tsx` has a second hardcoded `"lbs"` string inside the weight-range branch of `ExerciseRow`.
**Why it happens:** The range branch builds its own string instead of calling `formatTargetWeight`.
**How to avoid:** Replace `"${lo}–${hi} lbs"` with `"${formatWeight(lo, weightUnit)}–${formatWeight(hi, weightUnit)}"`.
**Warning signs:** Percentage-range weights still show lbs even after fixing `formatTargetWeight`.

### Pitfall 2: Existing `formatTargetWeight` tests assert exact "225 lbs" string
**What goes wrong:** The test at line 122 of `targetWeight.test.ts` asserts `toBe('225 lbs')`. Adding the `unit` param with default `'lb'` keeps the assertion passing — but if the default is accidentally changed to `'kg'`, the test silently breaks in the other direction.
**Why it happens:** Test was written before the unit param existed.
**How to avoid:** Existing tests should pass unchanged (backward-compatible default). Add new explicit tests: `formatTargetWeight(225, 0.75, 'lb')` → `'225.0 lbs'` and `formatTargetWeight(225, 0.75, 'kg')` → `'102.1 kg'`.

**Note:** `formatWeight(225, 'lb')` returns `'225.0 lbs'` (one decimal place via `.toFixed(1)`), not `'225 lbs'` (integer). The existing test `toBe('225 lbs')` will break when `formatTargetWeight` delegates to `formatWeight`. Update the test to `toBe('225.0 lbs')`.

### Pitfall 3: `formatScore('weight')` callers in benchmarks screens don't pass unit
**What goes wrong:** `formatScore` signature gains a `unit` param, but the call sites in benchmark screens don't pass it — they get the `'lb'` default, which is correct behavior, but if future call sites forget, the type system won't warn (it's optional).
**Why it happens:** Optional param with default silently uses the wrong unit in future code.
**How to avoid:** Search for all `formatScore` call sites and verify they either pass `weightUnit` explicitly or are confirmed non-weight types where the param is irrelevant.
**Call sites to verify:** `app/(app)/benchmarks/[id].tsx` (or wherever benchmark results render).

### Pitfall 4: `scoring-input.ts` test for 'weight' asserts "315 lbs"
**What goes wrong:** Line 32 of `scoringInput.test.ts` asserts `toBe('315 lbs')`. After adding the unit param with default `'lb'`, `formatWeight(315, 'lb')` returns `'315.0 lbs'` — breaking the assertion.
**Why it happens:** `formatWeight` always returns one decimal place via `.toFixed(1)`.
**How to avoid:** Update the existing test to `toBe('315.0 lbs')`. Add a new test: `formatScore('weight', 315, 'kg')` → `'142.9 kg'` (315 * 0.453592 = 142.88... → nearest 0.5 = 143.0... let's verify: 315 lbs = 142.882 kg → round to 0.5 = 143.0 → `'143.0 kg'`).

### Pitfall 5: Coverage — `src/**/*.{ts,tsx}` is collected; `app/**/*.tsx` is not
**What goes wrong:** `target-weight.ts` and `scoring-input.ts` are under `src/` and require 100% coverage per CI config. `session.tsx` is under `app/` and is not collected — but a test for its exported helpers (`getCurrentSession`, `getNextEnrollmentPosition`) is still good practice.
**Why it happens:** `jest.config.js` `collectCoverageFrom` only covers `src/**`.
**How to avoid:** Ensure all new branches in `target-weight.ts` and `scoring-input.ts` are covered by tests. For `session.tsx`, write a test for the exported pure functions and the UI rendering with the mock pattern.

## Code Examples

Verified patterns from existing codebase:

### formatWeight output format (exact strings)
```typescript
// Source: src/utils/formatWeight.ts
formatWeight(225, 'lb')   // → "225.0 lbs"
formatWeight(225, 'kg')   // → "102.1 kg"  (225 * 0.453592 = 102.08 → round to 0.5 = 102.0... recheck: 102.08 → Math.round(102.08 * 2)/2 = Math.round(204.16)/2 = 204/2 = 102.0 → "102.0 kg")
formatWeight(315, 'lb')   // → "315.0 lbs"
formatWeight(315, 'kg')   // → "143.0 kg"  (315 * 0.453592 = 142.88 → 143.0)
```

### Settings load in useFocusEffect (the session.tsx approach)
```typescript
// Source: pattern from app/(app)/(tabs)/maxes.tsx adapted for useFocusEffect
useFocusEffect(
  useCallback(() => {
    let cancelled = false;
    setLoading(true);

    const loadData = async (): Promise<void> => {
      try {
        const enroll = await getProgramRepo(isGuest).getEnrollment(uid);
        if (!enroll || cancelled) {
          if (!cancelled) setLoading(false);
          return;
        }

        const [prog, userMaxes, settings] = await Promise.all([
          getProgramRepo(isGuest).getProgram(enroll.programId),
          getExerciseMaxRepo(isGuest).getAllMaxes(uid),
          getSettingsRepo(isGuest).getSettings(uid),  // add this
        ]);

        if (cancelled) return;
        setEnrollment(enroll);
        setProgram(prog);
        setMaxes(userMaxes);
        if (settings?.weightUnit) setWeightUnit(settings.weightUnit);  // add this
      } catch {
        // Graceful degradation
      } finally {
        if (!cancelled) setLoading(false);
      }
    };

    void loadData();
    return () => { cancelled = true; };
  }, [uid, isGuest])
);
```

Adding `getSettingsRepo(isGuest).getSettings(uid)` to the existing `Promise.all` is the cleanest approach — zero additional network round trips, single loading state.

### Updated formatTargetWeight
```typescript
// Source: src/components/programs/target-weight.ts — updated
import { formatWeight } from '@/src/utils/formatWeight';
import type { WeightUnit } from '@/src/domain/types';

export function formatTargetWeight(
  weight: number | null,
  percentage: number,
  unit: WeightUnit = 'lb'
): string {
  if (weight !== null) {
    return formatWeight(weight, unit);
  }
  const pct = Math.round(percentage * 100);
  return `${pct}%`;
}
```

### Updated formatScore
```typescript
// Source: src/components/benchmarks/scoring-input.ts — updated
import { formatWeight } from '@/src/utils/formatWeight';
import type { WeightUnit } from '@/src/domain/types';

export function formatScore(
  scoringType: BenchmarkScoringType,
  score: number,
  unit: WeightUnit = 'lb'
): string {
  switch (scoringType) {
    case 'time':
    case 'distance':
      return formatSeconds(score);
    case 'roundsAndReps':
      return formatRoundsAndReps(score);
    case 'reps':
      if (score >= 10000) {
        return formatRoundsAndReps(score);
      }
      return `${score} reps`;
    case 'weight':
      return formatWeight(score, unit);  // was: `${score} lbs`
  }
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `formatTargetWeight` hardcodes `"${weight} lbs"` | `formatWeight(weight, unit)` with default `'lb'` | Phase 16 | Program session target weights respect user preference |
| `formatScore('weight')` hardcodes `"${score} lbs"` | `formatWeight(score, unit)` with default `'lb'` | Phase 16 | Benchmark weight scores respect user preference |
| `session.tsx` has no settings load | `getSettingsRepo` called in `useFocusEffect` via `Promise.all` | Phase 16 | Screen loads weight unit on every focus |
| Weight range display: `"${lo}–${hi} lbs"` | `"${formatWeight(lo, unit)}–${formatWeight(hi, unit)}"` | Phase 16 | Range weights also respect unit |

**Deprecated/outdated:**
- Bare string interpolation with " lbs" suffix anywhere in the render layer: all weight display must go through `formatWeight`.

## Open Questions

1. **Do benchmark call sites need to be updated?**
   - What we know: `formatScore` gains a `unit` param with default `'lb'`. All existing call sites without the param will continue to return lbs — backward compatible.
   - What's unclear: Whether benchmark result rendering screens (`app/(app)/benchmarks/[id].tsx`) already have a weightUnit loaded.
   - Recommendation: Inspect the benchmark detail screen in the plan phase. If it loads settings and already passes `weightUnit` to display functions, thread it into `formatScore`. If not, the default `'lb'` keeps behavior unchanged — the benchmark screen's weight-unit threading is out of scope for Phase 16 unless a call site is actively passing the unit.

2. **Should `calculateTargetWeight` rounding stay in lbs (nearest 5 lbs) or adapt for kg (nearest 2.5 kg)?**
   - What we know: Currently rounds to nearest 5 lbs before returning. When converted to kg, 5 lbs ≈ 2.27 kg, so the granularity is reasonable but not matched to kg plate increments.
   - What's unclear: Whether kg users expect nearest 2.5 kg rounding.
   - Recommendation: Keep lbs rounding in `calculateTargetWeight` (it returns lbs). `formatWeight` rounds kg to nearest 0.5 kg independently. Do not add kg plate rounding to this phase — it's a behavior change beyond the scope of PLAT-05 gap closure.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Jest (jest-expo preset) |
| Config file | `SundeeFundeeRN/jest.config.js` |
| Quick run command | `cd SundeeFundeeRN && npx jest --testPathPattern="targetWeight|scoringInput|session" --no-coverage` |
| Full suite command | `cd SundeeFundeeRN && npx jest --coverage` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| PLAT-05 | `formatTargetWeight` returns kg string when unit='kg' | unit | `npx jest --testPathPattern="targetWeight" --no-coverage` | exists (needs new cases) |
| PLAT-05 | `formatTargetWeight` backward-compat: default unit='lb' still works | unit | `npx jest --testPathPattern="targetWeight" --no-coverage` | exists (update assertion to "225.0 lbs") |
| PLAT-05 | `formatScore('weight')` returns kg when unit='kg' | unit | `npx jest --testPathPattern="scoringInput" --no-coverage` | exists (needs update + new case) |
| PLAT-05 | `session.tsx` exported helpers work correctly | unit | `npx jest --testPathPattern="session" --no-coverage` | Wave 0 gap |
| PLAT-05 | `ExerciseRow` renders weight badge in kg | component | `npx jest --testPathPattern="session" --no-coverage` | Wave 0 gap |

### Sampling Rate
- **Per task commit:** `cd SundeeFundeeRN && npx jest --testPathPattern="targetWeight|scoringInput|session" --no-coverage`
- **Per wave merge:** `cd SundeeFundeeRN && npx jest --coverage`
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] `SundeeFundeeRN/app/(app)/programs/__tests__/session.test.tsx` — covers `getCurrentSession`, `getNextEnrollmentPosition`, and renders ExerciseRow with weightUnit prop (PLAT-05)
- [ ] Update `SundeeFundeeRN/src/components/programs/__tests__/targetWeight.test.ts` — fix "225 lbs" → "225.0 lbs" assertion; add kg test cases
- [ ] Update `SundeeFundeeRN/src/components/benchmarks/__tests__/scoringInput.test.ts` — fix "315 lbs" → "315.0 lbs" assertion; add kg test case for 'weight' scoring type

*(Existing test files for targetWeight and scoringInput need assertion updates, not creation from scratch)*

## Sources

### Primary (HIGH confidence)
- Direct code inspection: `SundeeFundeeRN/app/(app)/programs/session.tsx` — confirmed no settings load, confirmed hardcoded "lbs" in ExerciseRow weight range branch (line 107)
- Direct code inspection: `SundeeFundeeRN/src/components/programs/target-weight.ts` — confirmed `formatTargetWeight` hardcodes `"${weight} lbs"` (line 110)
- Direct code inspection: `SundeeFundeeRN/src/components/benchmarks/scoring-input.ts` — confirmed `formatScore('weight')` hardcodes `"${score} lbs"` (line 45)
- Direct code inspection: `SundeeFundeeRN/src/utils/formatWeight.ts` — confirmed `formatWeight` API and output format (`.toFixed(1)` for lbs, `0.5 kg` rounding for kg)
- Direct code inspection: `SundeeFundeeRN/app/(app)/(tabs)/maxes.tsx` — confirmed reference pattern for settings `useEffect`
- Direct code inspection: `SundeeFundeeRN/src/repositories/SettingsRepo.ts` — confirmed `getSettingsRepo(isGuest)` factory, `DEFAULT_SETTINGS.weightUnit = 'lb'`
- Direct code inspection: `.planning/v1.0-MILESTONE-AUDIT.md` — confirmed exact gap description for PLAT-05 in programs/session.tsx
- Direct code inspection: `SundeeFundeeRN/jest.config.js` — confirmed `collectCoverageFrom: ['src/**/*.{ts,tsx}']`, `app/` not collected

### Secondary (MEDIUM confidence)
- Phase 13 RESEARCH.md — established patterns for this exact type of weight-unit threading; confirmed `formatWeight` as single source of truth for all weight display

### Tertiary (LOW confidence)
- None

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all utilities in production, no new dependencies
- Architecture: HIGH — pattern is mechanical repetition of Phase 13 approach; all three files clearly identified
- Pitfalls: HIGH — identified from direct code inspection of output format mismatches between existing tests and `formatWeight` actual output

**Research date:** 2026-03-16
**Valid until:** Stable — no fast-moving dependencies
