---
phase: 01-smart-guidance
plan: 03
subsystem: ui-integration
tags: [recommendations, pr-detection, confetti, plateau, framer-motion, radix-ui, tooltip, select, typescript]

dependency-graph:
  requires:
    - "01-01: DB schema v4, WeightOverrideReason type, savePersonalRecord, Tooltip component, TooltipProvider"
    - "01-02: getNextRecommendedWeight, detectPlateauForExercise, getDeloadWeight, usePRDetection hook"
  provides:
    - "PRCelebration: full-screen confetti overlay with haptic + sound + auto-dismiss on weight/volume PR"
    - "PlateauModal: pre-workout must-acknowledge Dialog listing all plateaued exercises with deload weights"
    - "SetInputV2: recommendedWeight pre-fill, Info icon Tooltip, inline override reason Select on blur"
    - "WorkoutSessionView: orchestrates PR detection on each set, plateau modal on mount, PR saved to DB"
    - "workout/[id]/page.tsx: per-exercise recommendation loading + plateau detection on session load"
    - "useConfetti: firePRConfetti dense variant (150-particle dual-side burst + 200ms sustained)"
  affects:
    - "Phase 2+: PRs now saved to personalRecords table; ready for charts and history display"
    - "Phase 2 charts: per-exercise weight progression data now flowing fully through the system"

tech-stack:
  added: []
  patterns:
    - "AnimatePresence overlay pattern for full-screen celebrations (Framer Motion)"
    - "CustomEvent for cross-component sound dispatch ('pr-achieved')"
    - "onBlur-triggered inline contextual UI (override reason select appears only after blur, not keystroke)"
    - "Per-exercise 1RM lookup replacing hardcoded single-exercise lookup"
    - "Plateau + recommendation cascade: plateau detection overrides recommendation with deload weight"

key-files:
  created:
    - src/components/program/pr-celebration.tsx
    - src/components/program/plateau-modal.tsx
  modified:
    - src/hooks/use-confetti.ts
    - src/components/program/set-input-v2.tsx
    - src/components/program/exercise-card-v2.tsx
    - src/components/program/workout-session-view.tsx
    - src/app/workout/[id]/page.tsx
    - tests/unit/program/workout-session-view.test.tsx

decisions:
  - "Weight PR takes priority over volume PR when both are detected in the same set — single celebration, not stacked"
  - "Override reason selector triggers on onBlur (not onChange) — prevents dialog flickering while typing; only appears once per set"
  - "Plateau detection overrides the recommendation weight: plateaued weight becomes the pre-filled input value, not an alert alongside the original"
  - "Per-exercise 1RM lookup via find() on oneRepMaxes array replaces prior hardcoded backSquat1RM — allows all exercises to receive recommendations"
  - "WorkoutSessionView now wraps renders in UserProvider (test fix) — useUser hook required for PR detection"

metrics:
  duration: "~8 minutes (including human-verify checkpoint)"
  completed: "2026-02-18"
  tests-added: 0
  tests-passing: 176
---

# Phase 01 Plan 03: Smart Guidance UI Integration Summary

**One-liner:** Wired weight recommendations (pre-filled inputs + Tooltip + override reason Select), full-screen PR confetti celebration (haptic + sound + auto-dismiss), and pre-workout plateau modal into the live workout flow — completing all three RECOM requirements.

## What Was Built

### Task 1: PR Celebration and Plateau Modal Components

**`src/components/program/pr-celebration.tsx`** — Full-screen celebration overlay:
- `PRCelebrationProps`: `{ isVisible, prType: 'weight' | 'volume' | null, onDismiss }`
- On `isVisible` → true: calls `firePRConfetti()`, triggers `navigator.vibrate([100, 50, 100, 50, 300])`, dispatches `CustomEvent('pr-achieved')`
- Listens for `'pr-achieved'` to play `/sounds/pr.mp3` via `new Audio()` — wrapped in try/catch (sound is additive, not critical)
- Auto-dismiss via `setTimeout(onDismiss, 3500)`, cleanup on effect teardown
- Render: `z-[200]` fixed overlay, `bg-black/60`, trophy emoji, "New PR!" heading, type-specific subtitle ("New Weight Record!" / "New Volume Record!"), "Tap to continue" hint
- Framer Motion `AnimatePresence` with `scale` + `opacity` enter/exit

**`src/components/program/plateau-modal.tsx`** — Pre-workout acknowledgement modal:
- `PlateauModalProps`: `{ isOpen, plateaus: Array<{ exerciseName, adjustedWeight }>, onAcknowledge }`
- Uses existing `Dialog` / `DialogContent` / `DialogHeader` / `DialogFooter` — no hand-rolled modal
- `onOpenChange={() => {}}` — noop prevents backdrop click / Escape dismissal
- `showCloseButton={false}` — user must press "Got it, let's go" button
- Lists all plateaued exercises with per-exercise deload weight in a single combined modal
- Encouraging copy: "Deloading allows your body to recover and break through plateaus."

**`src/hooks/use-confetti.ts`** — Added `firePRConfetti`:
- Initial burst: 2× `confetti({ particleCount: 150, spread: 100 })` from x=0.25 and x=0.75
- Sustained: `setInterval` every 200ms over 4 seconds, random origin, 6-color array, `zIndex: 9999`
- Returns `{ fireConfetti, firePRConfetti }` — existing `fireConfetti` unchanged

### Task 2: Recommendation Wiring, PR Detection, Plateau Integration

**`src/components/program/set-input-v2.tsx`** — Recommendation UI:
- New props: `recommendedWeight?: number`, `recommendationSource?: string`, `onOverrideReason?: (reason: WeightOverrideReason) => void`
- Initial weight value: `recommendedWeight ?? prescribedWeight`
- When `recommendedWeight` set: renders `Info` icon (lucide-react) next to "Weight (lbs)" label, wrapped in `Tooltip` / `TooltipTrigger` / `TooltipContent` showing `recommendationSource`
- `hasOverridden` state: tracks if user already provided a reason (prevents repeat prompt)
- `onBlur`: if value differs from `recommendedWeight` and `!hasOverridden` → shows inline `Select` with options: "Injured", "Fatigued", "Just because", "Other"
- On reason select: `hasOverridden = true`, calls `onOverrideReason(reason)`, hides select
- No `recommendedWeight` prop → component behaves identically to before (fully backward compatible)

**`src/components/program/exercise-card-v2.tsx`** — Prop passthrough:
- New props: `recommendedWeights?: Record<number, number>`, `recommendationSource?: string`, `onOverrideReason?: (setNumber, reason) => void`
- Passes `recommendedWeight={recommendedWeights?.[index + 1]}` to each `SetInputV2`

**`src/components/program/workout-session-view.tsx`** — Orchestration:
- New prop: `recommendations?: Record<string, { weight: number; source: string }>` (keyed by exerciseId)
- New prop: `plateaus?: Array<{ exerciseName: string; adjustedWeight: number }>`
- `prCelebration` state: `{ isVisible: boolean; prType: 'weight' | 'volume' | null }`
- `showPlateauModal` state: initialised `true` when `plateaus.length > 0`
- In `handleSetChange`: calls `checkWeightPR(exerciseId, actualWeight)` → weight PR sets type 'weight'; then `checkVolumePR(workoutId, exerciseId, sessionSets)` → volume PR sets type 'volume' only if no weight PR (weight takes priority)
- On PR: calls `savePersonalRecord({ id, userId, exerciseId, type, value, workoutId, date })` to persist to DB
- Override reason from `onOverrideReason` callback stored in `setDataMap` for that set
- Renders `<PRCelebration>` and `<PlateauModal>` as siblings at component root

**`src/app/workout/[id]/page.tsx`** — Page-level data loading:
- `useEffect` (on selectedSession + activeCycleId): for each exercise in session:
  - `getLastCompletedSetsForExercise(exerciseId, activeCycleId, 1)` → last session sets
  - Per-exercise 1RM lookup via `oneRepMaxes.find(r => r.exerciseName === name)?.value ?? 0`
  - `wasSessionSuccessful(lastSets)` → `SessionResult` ('success' | 'failure' | 'first')
  - `getNextRecommendedWeight(lastWeight, result, oneRepMax)` → recommended weight
  - `detectPlateauForExercise(exerciseId, activeCycleId)` → if plateau, `getDeloadWeight(recommended)` overrides weight + adds to plateaus array
  - Builds `recommendations` map and `plateaus` array; passes both as props to `WorkoutSessionView`

**`tests/unit/program/workout-session-view.test.tsx`** — Bug fix (Rule 1):
- Wrapped all renders with `UserProvider` — required because `WorkoutSessionView` now calls `usePRDetection` which calls `useUser` internally

## Verification Results

| Check | Status |
|-------|--------|
| `npx tsc --noEmit` (source files) | ✅ Pass (2 pre-existing RestTimer test errors unrelated to this plan) |
| `npm run build` | ✅ Pass |
| `npx vitest run` | ✅ 176/176 tests pass |
| PRCelebration: AnimatePresence + haptic + sound + auto-dismiss | ✅ |
| PlateauModal: must-acknowledge, lists all plateaued exercises | ✅ |
| SetInputV2: Tooltip + override Select on blur (not onChange) | ✅ |
| WorkoutSessionView: usePRDetection on each set, savePersonalRecord | ✅ |
| workout/[id]/page.tsx: per-exercise recommendations + plateau detection | ✅ |

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed `workout-session-view.test.tsx` missing UserProvider**

- **Found during:** Task 2 TypeScript/test verification
- **Issue:** `WorkoutSessionView` now calls `usePRDetection`, which internally calls `useUser`. Test renders were missing `UserProvider`, causing hook context errors.
- **Fix:** Wrapped all renders in `tests/unit/program/workout-session-view.test.tsx` with `UserProvider`
- **Files modified:** `tests/unit/program/workout-session-view.test.tsx`
- **Commit:** `8e07284`

### Pre-existing Issues (Not Introduced by This Plan)

- `RestTimerExpanded.test.tsx` and `RestTimerPill.test.tsx` have 2 TypeScript errors (status type mismatches from earlier commits `8f70539`, `833af9f`) — present before this plan, out of scope.

## Decisions Made

| Decision | Choice | Rationale |
|----------|--------|-----------|
| PR priority | Weight PR overrides volume PR when both detected | Single celebration is cleaner UX; weight PR is the more meaningful milestone |
| Override trigger | `onBlur` not `onChange` | Prevents dialog flickering while user is mid-type (Pitfall 5 from research) |
| Override reset | `hasOverridden` flag prevents repeat prompt | One reason per set is sufficient — not prompted on every subsequent edit |
| Plateau weight override | Deload weight replaces recommendation, not shown alongside | User sees one number to use; two conflicting numbers would be confusing |
| Per-exercise 1RM | Dynamic `find()` on `oneRepMaxes` array | Removes hardcoded `backSquat1RM` assumption; all exercises can receive recommendations |

## Success Criteria

| Criterion | Status |
|-----------|--------|
| RECOM-01: Weight suggestions pre-filled based on +5/−5/70%1RM rules | ✅ |
| RECOM-02: Plateau detected (3 failed sessions) → auto-adjust −10% + modal | ✅ |
| RECOM-03: Full-screen confetti + haptic + sound on weight or volume PR | ✅ |
| Info tooltip explains recommendation source | ✅ |
| Override reason inline select (blur-triggered, not keystroke) | ✅ |
| Plateau modal must-acknowledge (no backdrop/Escape dismiss) | ✅ |
| PR saved to `personalRecords` table in IndexedDB | ✅ |
| All locked decisions honored | ✅ |

## Phase 1 Complete

All three plans in Phase 01 (Smart Guidance) are now complete:
- **01-01**: DB schema v4, workout persistence, Tooltip component
- **01-02**: Recommendation engine, plateau detection, PR detection hook (26 tests)
- **01-03**: UI integration — recommendations in inputs, PR celebration, plateau modal

The Phase 01 Smart Guidance feature set is fully implemented and ready for Phase 02 (Visualization).
