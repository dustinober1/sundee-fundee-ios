# Phase 01: Smart Guidance - Research

**Researched:** 2026-02-17
**Domain:** React/Next.js workout app — recommendation engine, plateau detection, PR celebrations
**Confidence:** HIGH (full codebase inspection + verified library APIs)

---

## Summary

This phase adds three guidance features to an existing workout tracker: weight recommendations pre-filled in inputs, plateau detection with pre-workout alerts, and immediate PR celebrations. The codebase is a Next.js 16 / React 19 app using Dexie (IndexedDB), Tailwind, Radix UI, Framer Motion, and canvas-confetti.

**Critical discovery:** The workout session completion flow does **not persist data** yet. `WorkoutSessionView` collects set data in local state but the `onComplete` handler in `workout/[id]/page.tsx` is a no-op (`() => {}`). Phase 1 must first wire up set persistence before recommendations, plateau detection, or PR tracking can function. All recommendation logic, plateau detection infrastructure, and confetti are already partially scaffolded but lack the data pipeline to drive them.

**Primary recommendation:** Wire workout data persistence first (it's the foundational dependency for everything else), then build the recommendation/plateau/PR features on top.

---

## User Constraints

_Copied verbatim from CONTEXT.md — planner MUST honor these._

### Locked Decisions

**Recommendation UI**
- Appearance: Pre-filled in the weight input field (editable).
- Acceptance: Auto-filled (passive acceptance), user just confirms or edits.
- Explanation: Small tooltip or 'i' icon explaining the calculation source.
- Override: If user changes the value, ask for a reason (e.g., "Injured", "Fatigued", "Just because").

**Plateau Alerts**
- Timing: Pre-workout modal or banner when opening the workout screen.
- Trigger: 3 consecutive failed sessions (unable to complete prescribed reps/weight).
- Content: Prescriptive advice (e.g., "Stalled for 3 sessions. Recommended deload: -10%").
- Action: Auto-adjust the recommended weight downwards based on the prescription.

**PR Celebrations**
- Intensity: Full-screen confetti takeover.
- Trigger: Immediately upon checking off the set that achieved the PR.
- Criteria: New Weight PR (max weight lifted) OR Volume PR (total volume for exercise).
- Feedback: Visual (confetti) + Sound effect + Haptic vibration.

**Logic Tuning**
- Rounding: Round all recommendations to the nearest 5 lbs.
- Base Calculation: Fixed percentage of current 1RM (e.g., 70% of 1RM).
- Success Progression: Linear increase (+5 lbs) after successful completion of all sets.
- Failure Handling: Decrease weight slightly for the next session if reps are missed.

### Claude's Discretion

- Exact specific wording of the plateau messages.
- Design of the tooltip for recommendation explanation.
- Animation timing for the confetti (duration, density).
- Specific decrease amount for failure (e.g., -10% vs -5lbs).

### Deferred (Out of Scope)

- History/Trends: Visualizing 1RM history or volume over time (Phase 2).
- Syncing: Backing up PRs to the cloud (Phase 3).
- Social: Sharing PRs with friends (Future/Backlog).

---

## Standard Stack

All libraries are **already installed**. No new dependencies needed.

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `canvas-confetti` | 1.9.4 | Full-screen PR confetti | Already installed, `useConfetti` hook exists |
| `dexie` | 4.3.0 | IndexedDB persistence for sets, workouts, PRs | Already the DB layer; has `completedSets`, `completedWorkouts`, `oneRepMaxes` tables |
| `framer-motion` | 12.34.0 | Plateau modal animation, confetti overlay enter/exit | Already used throughout; `AnimatePresence` in template |
| `radix-ui` (Tooltip) | 1.4.3 | 'i' icon tooltip explaining recommendation source | Available via `radix-ui` package's `Tooltip` export |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `@radix-ui/react-tooltip` | 1.2.8 | Tooltip primitive for recommendation explanation | Build shadcn-style `Tooltip` component in `components/ui/` |
| `lucide-react` | 0.564.0 | `Info` icon for tooltip trigger | Already imported in other components |
| `navigator.vibrate` | Web API | Haptic feedback on PR | Available in `useRestTimer` pattern — replicate for PR |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Radix Tooltip | CSS title attribute | Too simple, no styling control; Radix already present |
| canvas-confetti | CSS keyframe animations | Can't produce particle physics; confetti already installed |
| Framer Motion overlay | CSS transitions | AnimatePresence already handles mount/unmount; consistent with app |

**Installation:** None required — all libraries already in `package.json`.

---

## Architecture Patterns

### Existing Structure to Extend
```
src/
├── components/program/
│   ├── set-input-v2.tsx          # ADD: recommended weight prop + override reason dialog
│   ├── exercise-card-v2.tsx      # ADD: pass recommendation to SetInputV2
│   └── workout-session-view.tsx  # ADD: set persistence, PR detection, plateau pre-check
├── components/ui/
│   └── tooltip.tsx               # CREATE: shadcn-style Radix Tooltip wrapper
├── components/program/
│   ├── pr-celebration.tsx        # CREATE: full-screen confetti overlay
│   └── plateau-modal.tsx         # CREATE: pre-workout plateau warning modal
├── hooks/
│   ├── use-confetti.ts           # EXISTS: extend with full-screen variant
│   └── use-pr-detection.ts       # CREATE: checks weight/volume PR on set completion
├── lib/
│   ├── calculations.ts           # EXISTS: extend with nextSessionWeight() and sessionSuccess()
│   └── recommendations/
│       ├── plateau-detection.ts  # EXISTS: fix detection logic (per-exercise, failed reps)
│       └── weight-recommendation.ts  # CREATE: getNextWeight(exerciseId, cycleId, 1RM)
└── types/
    └── workout.ts                # EXTEND: add overrideReason to CompletedSet, add PR types
```

### Pattern 1: Pre-fill Weight Input with Recommended Value

**What:** `SetInputV2` receives a `recommendedWeight` prop. The input's initial `useState` uses this value. An 'i' icon shows a Radix Tooltip explaining the source. On weight change, a dialog asks for override reason.

**When to use:** Every set that has a corresponding exercise with previous session data.

**Example:**
```typescript
// src/components/program/set-input-v2.tsx
export function SetInputV2({
  setNumber,
  prescribedWeight,
  recommendedWeight,      // NEW: overrides prescribedWeight if present
  prescribedReps,
  isTimeBased,
  onWeightChange,
  onRepsChange,
  onTimeChange,
  onOverrideReason,       // NEW: callback when user changes recommended weight
}: SetInputV2Props) {
  const initialWeight = recommendedWeight ?? prescribedWeight;
  const [weight, setWeight] = useState(initialWeight);
  const [showOverrideDialog, setShowOverrideDialog] = useState(false);
  const [hasOverridden, setHasOverridden] = useState(false);

  const handleWeightChange = (newWeight: number) => {
    setWeight(newWeight);
    onWeightChange(newWeight);
    // Only prompt override reason if recommendation exists and value was changed
    if (recommendedWeight !== undefined && newWeight !== recommendedWeight && !hasOverridden) {
      setShowOverrideDialog(true);
    }
  };
  // ...
}
```

### Pattern 2: Recommendation Calculation (Progressive Overload)

**What:** Pure function in `lib/calculations.ts`. Takes previous session result for the exercise and returns next recommended weight.

**When to use:** When loading workout session — called per exercise.

**Example:**
```typescript
// src/lib/calculations.ts — ADD:

export type SessionResult = 'success' | 'failure' | 'first';

/**
 * Calculate next session recommended weight
 * - First session: 70% of 1RM (per spec)
 * - Success (all reps completed): +5 lbs
 * - Failure (any rep missed): -5 lbs (Claude's discretion: -5 lbs, ~2.5% for most)
 * - Always round to nearest 5 lbs
 */
export function getNextRecommendedWeight(
  currentWeight: number,
  result: SessionResult,
  oneRepMax: number,
): number {
  if (result === 'first') {
    return roundToNearestFive(oneRepMax * 0.7);
  }
  if (result === 'success') {
    return roundToNearestFive(currentWeight + 5);
  }
  // failure: -5 lbs (locked decision: "decrease weight slightly")
  return roundToNearestFive(Math.max(currentWeight - 5, roundToNearestFive(oneRepMax * 0.5)));
}

/**
 * Determine if a completed set was successful
 * Success = actualReps >= prescribedReps AND actualWeight >= prescribedWeight
 */
export function wasSetSuccessful(set: Pick<CompletedSet, 'actualReps' | 'prescribedReps' | 'actualWeight' | 'prescribedWeight'>): boolean {
  const weightMet = set.prescribedWeight === undefined || set.actualWeight >= set.prescribedWeight;
  return set.actualReps >= set.prescribedReps && weightMet;
}
```

### Pattern 3: Plateau Detection (Fix Required)

**What:** Current `detectPlateauForCycle` mixes sets across all exercises. Spec requires per-exercise, per-session failure tracking: 3 consecutive sessions where user **failed to complete prescribed reps** for a specific exercise.

**Fix:** Query `completedSets` by `exerciseId`, compare `actualReps < prescribedReps`, track consecutive failures.

```typescript
// src/lib/recommendations/plateau-detection.ts — REPLACE logic:

export async function detectPlateauForExercise(
  exerciseId: string,
  activeCycleId: string
): Promise<PlateauWarning> {
  // Get last 3 workouts for this cycle, ordered by completedAt
  const workouts = await db.completedWorkouts
    .where('activeCycleId').equals(activeCycleId)
    .reverse().limit(3).toArray();

  if (workouts.length < 3) {
    return { hasPlateau: false, message: '', recommendation: '' };
  }

  // For each workout, get sets for this exercise
  const sessionResults = await Promise.all(
    workouts.map(async (w) => {
      const sets = await db.completedSets
        .where('workoutId').equals(w.id)
        .and(s => s.exerciseId === exerciseId)
        .toArray();
      // Session failed if ANY set had actualReps < prescribedReps
      return sets.some(s => s.actualReps < s.prescribedReps);
    })
  );

  // Plateau = 3 consecutive failures
  const hasPlateau = sessionResults.every(failed => failed === true);

  if (hasPlateau) {
    const deloadWeight = /* current recommended weight */ 0;
    return {
      hasPlateau: true,
      message: `Stalled for 3 sessions on this exercise.`,
      recommendation: `Recommended deload: reduce weight by 10% for next session.`,
    };
  }

  return { hasPlateau: false, message: '', recommendation: '' };
}
```

### Pattern 4: PR Detection on Set Check-off

**What:** After each set is marked complete, check if `actualWeight` exceeds `oneRepMaxes` for this exercise (Weight PR) OR if current session's cumulative volume exceeds best recorded volume for this exercise (Volume PR).

**When to use:** Called in `WorkoutSessionView.handleSetChange` immediately upon set completion.

```typescript
// src/hooks/use-pr-detection.ts — CREATE:
export function usePRDetection(exerciseId: string) {
  const { oneRepMaxes } = useUser();

  function checkWeightPR(newWeight: number): boolean {
    const currentMax = oneRepMaxes
      .filter(orm => orm.exerciseId === exerciseId)
      .reduce((max, orm) => Math.max(max, orm.weight), 0);
    return newWeight > currentMax;
  }

  async function checkVolumePR(workoutId: string, exerciseId: string): Promise<boolean> {
    const currentSets = await db.completedSets
      .where('workoutId').equals(workoutId)
      .and(s => s.exerciseId === exerciseId)
      .toArray();
    const currentVolume = currentSets.reduce((sum, s) => sum + s.actualWeight * s.actualReps, 0);

    // Compare against best volume ever for this exercise
    // Requires querying all historical sets for this exercise
    const allSets = await db.completedSets
      .where('exerciseId').equals(exerciseId)
      .toArray();
    const bestVolume = /* group by workoutId and find max */
      Math.max(0, .../* ... */[]);

    return currentVolume > bestVolume;
  }

  return { checkWeightPR, checkVolumePR };
}
```

### Pattern 5: PR Celebration Overlay

**What:** Full-screen `position: fixed` overlay with canvas-confetti, sound via `CustomEvent`, vibration via `navigator.vibrate`. Uses `AnimatePresence` for enter/exit. Auto-dismisses after ~3.5 seconds.

**When to use:** Triggered immediately when `checkWeightPR` or `checkVolumePR` returns `true`.

```typescript
// src/components/program/pr-celebration.tsx — CREATE:
'use client';
import { useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { useConfetti } from '@/hooks/use-confetti';

interface PRCelebrationProps {
  isVisible: boolean;
  prType: 'weight' | 'volume' | null;
  onDismiss: () => void;
}

export function PRCelebration({ isVisible, prType, onDismiss }: PRCelebrationProps) {
  const { fireConfetti } = useConfetti();

  useEffect(() => {
    if (isVisible) {
      fireConfetti();
      // Haptic: pattern established in useRestTimer
      if (typeof navigator !== 'undefined' && navigator.vibrate) {
        navigator.vibrate([100, 50, 100, 50, 200]);
      }
      // Sound: dispatch custom event (same pattern as rest-timer)
      window.dispatchEvent(new CustomEvent('pr-achieved'));
      const timer = setTimeout(onDismiss, 3500);
      return () => clearTimeout(timer);
    }
  }, [isVisible]);

  return (
    <AnimatePresence>
      {isVisible && (
        <motion.div
          className="fixed inset-0 z-[200] flex flex-col items-center justify-center bg-black/60"
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
          onClick={onDismiss}
        >
          <motion.div
            initial={{ scale: 0.5, opacity: 0 }}
            animate={{ scale: 1, opacity: 1 }}
            exit={{ scale: 0.5, opacity: 0 }}
            className="text-center"
          >
            <div className="text-6xl mb-4">🏆</div>
            <h2 className="text-3xl font-bold text-white">New PR!</h2>
            <p className="text-white/80 mt-2">
              {prType === 'weight' ? 'New Weight Record!' : 'New Volume Record!'}
            </p>
            <p className="text-white/60 text-sm mt-4">Tap to continue</p>
          </motion.div>
        </motion.div>
      )}
    </AnimatePresence>
  );
}
```

### Pattern 6: Plateau Pre-Workout Modal

**What:** Dialog using existing `Dialog` component from `src/components/ui/dialog.tsx`. Shown at workout session load. Contains prescriptive message and auto-adjusted weight. User must acknowledge before entering workout.

```typescript
// src/components/program/plateau-modal.tsx — CREATE:
'use client';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter } from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';

interface PlateauModalProps {
  isOpen: boolean;
  exerciseName: string;
  adjustedWeight: number;
  onAcknowledge: () => void;
}

export function PlateauModal({ isOpen, exerciseName, adjustedWeight, onAcknowledge }: PlateauModalProps) {
  return (
    <Dialog open={isOpen} onOpenChange={() => {}}>
      <DialogContent showCloseButton={false}>
        <DialogHeader>
          <DialogTitle>⚠️ Plateau Detected</DialogTitle>
        </DialogHeader>
        <p className="text-sm text-muted-foreground">
          You've missed prescribed reps on <strong>{exerciseName}</strong> for 3 sessions in a row.
          We've automatically reduced your recommendation to <strong>{adjustedWeight} lbs</strong>.
        </p>
        <p className="text-sm">
          Deloading allows your body to recover and break through plateaus. 
          Your progress is still moving forward.
        </p>
        <DialogFooter>
          <Button onClick={onAcknowledge}>Got it, let's go</Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
```

### Pattern 7: Tooltip for Recommendation Source

**What:** Build a `Tooltip` component wrapping `@radix-ui/react-tooltip` (same approach as other shadcn UI components). Place an `Info` icon (lucide-react) next to the weight input label. Tooltip shows how the weight was calculated.

```typescript
// src/components/ui/tooltip.tsx — CREATE (shadcn pattern):
'use client';
import { Tooltip as TooltipPrimitive } from 'radix-ui';
import { cn } from '@/lib/utils';

// ... standard shadcn Tooltip wrapper
// Usage in SetInputV2:
// <Tooltip>
//   <TooltipTrigger><Info className="size-3" /></TooltipTrigger>
//   <TooltipContent>Based on last session: 225 lbs + 5 lb progression</TooltipContent>
// </Tooltip>
```

### Pattern 8: Workout Data Persistence (FOUNDATIONAL)

**What:** Wire up `saveCompletedWorkout` and `saveCompletedSet` when user clicks "Complete Workout". This is a prerequisite for ALL Phase 1 features.

**When to use:** In `workout/[id]/page.tsx` `onComplete` handler and in `WorkoutSessionView` per-set tracking.

```typescript
// In WorkoutSessionView — collect set data for persistence:
// When each set changes, capture {exerciseId, setNumber, actualWeight, actualReps, prescribedWeight, prescribedReps}

// In workout/[id]/page.tsx onComplete handler:
const handleComplete = async (setData: CollectedSetData[]) => {
  const workoutId = generateId();
  await saveCompletedWorkout({
    id: workoutId,
    userId: user.id,
    activeCycleId: cycle.id,
    programId: programId,
    week: currentWeek,
    sessionId: selectedSession.sessionId,
    completedAt: new Date(),
  });
  for (const set of setData) {
    await saveCompletedSet({ id: generateId(), workoutId, ...set });
  }
};
```

### Anti-Patterns to Avoid

- **Plateau detection on weight variance only:** Current `detectPlateau` in `calculations.ts` uses `maxWeight - minWeight < 5`. This is wrong for the spec — it should detect consecutive sessions where `actualReps < prescribedReps`. Do NOT use the existing `detectPlateau` function; extend `plateau-detection.ts` instead.
- **Volume PR across all sessions mixed together:** Volume PR compares current session volume vs best single-session volume for that exercise. Not cumulative total.
- **Not adding `TooltipProvider` at root:** Radix Tooltip requires `<TooltipProvider>` at a high level in the tree. Add to `Providers` component.
- **Firing confetti synchronously before data is saved:** Always save the set to IndexedDB before triggering the PR celebration, or the PR won't be recorded.
- **Database version not incremented:** Adding `overrideReason` to `CompletedSet` type and adding a PR history table requires a Dexie version bump (currently v3 → v4).

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Confetti animation | CSS particle system | `canvas-confetti` (already installed) | Physics, browser perf, already has `useConfetti` hook |
| Weight input tooltip | Custom CSS hover | `@radix-ui/react-tooltip` via `radix-ui` package | Accessibility, focus management, already available |
| Plateau modal | Custom CSS overlay | Existing `Dialog` from `components/ui/dialog.tsx` | Already styled, animated, accessible |
| Haptic on PR | Custom timer loop | `navigator.vibrate()` (already in `useRestTimer`) | Web API, same pattern already established |
| Rounding to 5 lbs | Custom logic | `roundToNearestFive()` in `lib/utils.ts` | Already exists, already tested |
| Target weight calc | Custom 1RM math | `calculateTargetWeight()` in `lib/calculations.ts` | Already exists, already tested |
| PR overlay animation | CSS transition | Framer Motion `AnimatePresence` | Already used in template, handles mount/unmount properly |

**Key insight:** Nearly everything is scaffolded. The missing piece is data plumbing (persistence + querying) and wiring components together. Don't rebuild what's there.

---

## Common Pitfalls

### Pitfall 1: The `onComplete` No-Op — Data Is Never Saved

**What goes wrong:** Building recommendation/plateau/PR features and finding they have no data to work with because sets are never persisted.
**Why it happens:** `WorkoutSessionView` correctly collects local state but `workout/[id]/page.tsx` has `onComplete={() => {}}`.
**How to avoid:** Fix data persistence FIRST. Wire up `saveCompletedWorkout` + `saveCompletedSet` before building anything else.
**Warning signs:** Plateau detection always returns false; recommendations always show the base 70% 1RM calculation.

### Pitfall 2: Plateau Logic Checks Wrong Thing

**What goes wrong:** Using `detectPlateau(weights)` from `calculations.ts` which checks weight variance (not rep completion). A user who consistently lifts the same weight successfully won't plateau under this logic.
**Why it happens:** The existing function was designed for a different use case.
**How to avoid:** Use the per-exercise, per-session failure approach in `plateau-detection.ts`. The check is: `actualReps < prescribedReps` (any set failed = session failed).
**Warning signs:** Plateau detection test `'detects plateau after 3 stagnant workouts'` passes but real user with same weight for 3 sessions but all reps completed doesn't trigger plateau.

### Pitfall 3: Volume PR Requires Per-Session Aggregation

**What goes wrong:** Querying all `completedSets` for an exercise and summing all volumes to compare. Gives wrong answer — should compare best single session's volume.
**Why it happens:** `calculateVolumeLoad` takes `sets` param but the DB query won't group by session.
**How to avoid:** Group `completedSets` by `workoutId`, sum volume per workout, find the max. Compare current session's running total against that max.
**Warning signs:** Volume PR triggered on first set of first session (0 > 0 is false, but 0 vs undefined edge case).

### Pitfall 4: Dexie Version Not Bumped for Schema Changes

**What goes wrong:** Adding `overrideReason` to `CompletedSet` or a `personalRecords` table without incrementing Dexie version causes the schema migration to be skipped silently.
**Why it happens:** Dexie uses version numbers for migrations; skipping a bump means old schema persists.
**How to avoid:** When adding new indexes or tables, always increment `this.version(N)` in `dexie.ts`. Current version is 3; next must be 4.
**Warning signs:** TypeScript compiles fine but queries for new fields return undefined.

### Pitfall 5: Override Reason Dialog Fires on Every Keystroke

**What goes wrong:** The dialog prompting override reason opens while the user is still typing the weight (e.g., typing "2" triggers it before "225" is complete).
**Why it happens:** `onChange` fires on every character.
**How to avoid:** Track `hasOverridden` flag. Show dialog only once, on `onBlur` (when user leaves the field), not `onChange`. Or show it inline (a small select below the input) rather than a dialog.
**Warning signs:** Dialog flashes open/closed as user types.

### Pitfall 6: TooltipProvider Missing

**What goes wrong:** Radix Tooltip throws runtime error "Tooltip must be used within TooltipProvider".
**Why it happens:** Radix Tooltip requires context from `TooltipProvider` high in the tree.
**How to avoid:** Add `<Tooltip.Provider>` to `src/contexts/providers.tsx`.
**Warning signs:** App crashes on any page that renders the weight input tooltip.

### Pitfall 7: Sound Event Listener Not Set Up

**What goes wrong:** `window.dispatchEvent(new CustomEvent('pr-achieved'))` fires but nothing plays audio.
**Why it happens:** The app uses the event-dispatch pattern for sound (from `useRestTimer`) but no listener exists yet.
**How to avoid:** Add an audio file to `/public/sounds/pr.mp3` and add a `useEffect` listener for `'pr-achieved'` in the `PRCelebration` component or layout.
**Warning signs:** Confetti fires but no sound.

---

## Code Examples

### DB Query: Get Last N Completed Workouts for Cycle
```typescript
// Source: existing pattern in src/lib/recommendations/plateau-detection.ts
const workouts = await db.completedWorkouts
  .where('activeCycleId')
  .equals(activeCycleId)
  .reverse()          // newest first
  .limit(3)
  .toArray();
```

### DB Query: Get Sets for Exercise in a Workout
```typescript
// Source: existing Dexie schema — completedSets indexed on 'workoutId, exerciseId'
const sets = await db.completedSets
  .where('workoutId')
  .equals(workoutId)
  .and(s => s.exerciseId === exerciseId)
  .toArray();
```

### Dexie Version Bump (Schema Migration)
```typescript
// Source: src/lib/db/dexie.ts — existing pattern
this.version(4).stores({
  // All existing tables must be listed even if unchanged
  users: 'id, name, createdAt',
  oneRepMaxes: 'id, userId, exerciseId, date',
  activeCycles: 'id, userId, programId, status, currentPhase, currentSessionId',
  completedWorkouts: 'id, userId, activeCycleId, sessionId, completedAt',
  completedSets: 'id, workoutId, exerciseId',  // overrideReason is just a field, no index needed
  setMetrics: 'id, setId',
  // ... all others
  personalRecords: 'id, userId, exerciseId, type, date',  // NEW table
});
```

### canvas-confetti Full-Screen Burst
```typescript
// Source: existing src/hooks/use-confetti.ts (extend with denser config for PR)
import confetti from 'canvas-confetti';

function firePRConfetti() {
  const duration = 4000;
  const end = Date.now() + duration;

  // Initial burst from both sides
  confetti({ particleCount: 150, spread: 100, origin: { x: 0.25, y: 0.6 }, zIndex: 9999 });
  confetti({ particleCount: 150, spread: 100, origin: { x: 0.75, y: 0.6 }, zIndex: 9999 });

  // Sustained bursts (Claude's discretion: every 200ms for 4s)
  const interval = setInterval(() => {
    if (Date.now() > end) { clearInterval(interval); return; }
    confetti({
      startVelocity: 20, spread: 360, ticks: 80, zIndex: 9999,
      origin: { x: Math.random(), y: Math.random() * 0.4 },
      colors: ['#26ccff', '#a25afd', '#ff5e7e', '#88ff5a', '#fcff42', '#ffa62d'],
    });
  }, 200);
}
```

### Haptic Vibration Pattern (PR)
```typescript
// Source: established pattern in src/hooks/useRestTimer.ts
// Claude's discretion: celebratory pattern (vs rest-timer's alert pattern)
if (typeof navigator !== 'undefined' && navigator.vibrate) {
  navigator.vibrate([100, 50, 100, 50, 300]); // short-short-long
}
```

### Radix Tooltip (shadcn pattern)
```typescript
// Source: @radix-ui/react-tooltip API + existing shadcn pattern in codebase
import { Tooltip as TooltipPrimitive } from 'radix-ui';

// In providers.tsx — ADD:
<TooltipPrimitive.Provider delayDuration={300}>
  {children}
</TooltipPrimitive.Provider>
```

### roundToNearestFive (already exists)
```typescript
// Source: src/lib/utils.ts
export function roundToNearestFive(value: number): number {
  return Math.round(value / 5) * 5;
}
// Used by: calculateTargetWeight() in lib/calculations.ts — already tested
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Per-exercise 1RM tracking | Single 1RM per exercise in `oneRepMaxes` table | Existing design | OK for this phase; Phase 2 may need history |
| Weight variance plateau detection | Per-session rep-completion failure detection | This phase | Aligns with spec's "failed sessions" trigger |
| No set persistence | `saveCompletedWorkout` + `saveCompletedSet` | This phase | Enables all future features |

**Gap to close:** The existing `detectPlateau` in `calculations.ts` uses the wrong algorithm. It's tested and works as designed, but the design doesn't match the spec. Don't delete it (tests pass), but don't use it for the new plateau feature — use the `plateau-detection.ts` approach with per-exercise session analysis.

---

## Data Model Changes Required

### TypeScript Type Changes (`src/types/workout.ts`)

```typescript
// ADD to CompletedSet:
export type WeightOverrideReason = 'injured' | 'fatigued' | 'just_because' | 'other';

export interface CompletedSet {
  // ... existing fields ...
  overrideReason?: WeightOverrideReason;  // NEW: only set when user changes recommendation
}

// ADD new interface:
export type PRType = 'weight' | 'volume';

export interface PersonalRecord {
  id: string;
  userId: string;
  exerciseId: string;
  type: PRType;
  value: number;          // weight in lbs OR volume load (weight × reps × sets)
  workoutId: string;
  date: Date;
}
```

### Dexie Schema (`src/lib/db/dexie.ts`)
- Bump to version 4
- Add `personalRecords` table: `'id, userId, exerciseId, type, date'`
- `overrideReason` on `CompletedSet` is just a field (no index needed)

### DB Index Functions (`src/lib/db/index.ts`)
- Add `savePersonalRecord(pr: PersonalRecord): Promise<void>`
- Add `getPersonalRecordsForExercise(userId: string, exerciseId: string): Promise<PersonalRecord[]>`
- Add `getLastCompletedSetsForExercise(exerciseId: string, activeCycleId: string, limit: number): Promise<CompletedSet[]>`

---

## Recommendation Logic Summary (Claude's Discretion Filled In)

| Scenario | Rule | Value |
|----------|------|-------|
| First session ever | 70% of 1RM | `roundToNearestFive(oneRepMax * 0.7)` |
| Previous session succeeded | +5 lbs linear | `roundToNearestFive(lastWeight + 5)` |
| Previous session failed | -5 lbs | `roundToNearestFive(lastWeight - 5)` |
| Plateau (3 consecutive failures) | -10% deload | `roundToNearestFive(lastWeight * 0.9)` |
| All recommendations | Rounded | `roundToNearestFive()` |

**Rationale for -5 lbs on failure** (Claude's discretion): -5 lbs is a fixed amount matching the +5 progression step, keeps math simple, and is less aggressive than -10% (which would be ~22 lbs on a 225 lb lift). Deload is a separate, larger intervention (−10%) only after 3 consecutive failures.

**Confetti timing** (Claude's discretion): 4 seconds total, bursts every 200ms, particle count 150 initial + ~20 sustained bursts. Dense enough to feel like a "full-screen takeover" without being overwhelming.

---

## Open Questions

1. **Volume PR baseline when DB is empty**
   - What we know: First session will always have volume > 0; no historical data to compare
   - What's unclear: Should first session auto-qualify as a Volume PR? Could be spammy.
   - Recommendation: Only trigger Volume PR if at least 1 prior session exists for the exercise. Handle the "no prior data" case gracefully (return `false`).

2. **Override reason timing: onChange vs onBlur**
   - What we know: Showing dialog on every keystroke is bad UX
   - What's unclear: Should it be a dialog or an inline select?
   - Recommendation: Use an inline select (show a small row below the input with `<Select>`) rather than a modal dialog. Less disruptive, better mobile UX. Show it only after the first time the user changes the value.

3. **Multi-exercise sessions and plateau**
   - What we know: Sessions have multiple exercises; plateau is per-exercise
   - What's unclear: Should the plateau modal show all plateaued exercises or just the first one?
   - Recommendation: Show one modal listing all plateaued exercises for the session (e.g., "Squat and Deadlift have both stalled"). Show a single combined modal, not one per exercise.

---

## Sources

### Primary (HIGH confidence)
- Codebase inspection: `src/lib/calculations.ts`, `src/lib/recommendations/plateau-detection.ts`, `src/hooks/use-confetti.ts`, `src/lib/db/dexie.ts`, `src/components/program/set-input-v2.tsx`, `src/components/program/workout-session-view.tsx`, `src/app/workout/[id]/page.tsx`
- `node_modules/canvas-confetti/README.md` — official confetti API docs
- `node_modules/radix-ui/src/index.ts` — confirmed Tooltip available via `radix-ui` package
- `node_modules/@radix-ui/react-tooltip/package.json` — version 1.2.8 confirmed installed

### Secondary (MEDIUM confidence)
- Existing test suite (`tests/unit/`) — confirms test patterns, vitest config, fake-indexeddb setup
- `src/hooks/useRestTimer.ts` — established patterns for vibrate + custom event sound dispatch

### Tertiary (LOW confidence)
- None — all claims verified from codebase inspection or installed package docs

---

## Metadata

**Confidence breakdown:**
- Standard Stack: HIGH — all libraries verified installed in package.json and node_modules
- Architecture: HIGH — based on full codebase inspection; all files read
- Pitfalls: HIGH — confirmed by direct code reading (the `onComplete: () => {}` is literally in the file)
- Data model changes: HIGH — verified current Dexie schema version and existing types

**Research date:** 2026-02-17
**Valid until:** 2026-03-19 (30 days — stable, no external dependencies)
