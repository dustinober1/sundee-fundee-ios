# Phase 4: Core Workout Loop - Research

**Researched:** 2026-03-14
**Domain:** React Native workout logging, timers, charts, exercise library, offline-first set persistence
**Confidence:** MEDIUM-HIGH

## Summary

Phase 4 is the largest phase so far — it covers exercise library, set logging, rest timers, timed workout modes (ForTime/AMRAP/EMOM), PR detection, workout history, progress charts, and 1RM tracking. The existing codebase provides strong foundations: `WorkoutRepo` with dual Firestore/AsyncStorage implementations, `epleyFormula` for 1RM estimation, `isPR` for PR detection, `CelebrationEvent` types, and `HistoryItem` domain types. The core technical risks are background timer persistence (especially on Android) and the volume of new UI screens.

The timer strategy is the most critical architectural decision. True background execution is unreliable across platforms. The proven pattern is: record timestamps, use `AppState` to recalculate elapsed time on foreground, and schedule `expo-notifications` for user alerts when backgrounded. This avoids platform-specific foreground services while delivering the UX the user expects.

**Primary recommendation:** Use timestamp-based timer architecture (not interval-based), `expo-notifications` for background alerts, `react-native-gifted-charts` for progress visualization, bundled JSON for the exercise library, and `react-native-draggable-flatlist` for exercise reordering.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- Exercise library organized by muscle group categories: Chest, Back, Legs, Shoulders, Arms, Core, Full Body
- Search bar at top filters across all exercises
- Custom exercise creation inline from search — "Create [exercise name]" at bottom of results, quick form with name + muscle group
- Set logging: inline set rows beneath exercise card with previous workout ghost text, weight/reps inputs, check mark to complete
- "+set" button for additional sets, long-press drag-and-drop for exercise reorder
- Build-as-you-go for custom workouts (no template builder in Phase 4)
- Rest timer auto-starts on set completion, countdown at bottom with "Skip" button
- Global default rest duration in settings, per-exercise override available
- Background rest timer fires local push notification with sound + vibration
- Timed modes: full-screen timer, 3-2-1-Go countdown with beep, pause/stop buttons
- ForTime counts UP (stopwatch), AMRAP counts DOWN, EMOM fires per-minute notifications when backgrounded
- PR detection on: heaviest weight at tracked rep range (1RM, 3RM, 5RM, 8RM, 10RM) AND new estimated 1RM
- PR celebration: inline badge on set row + toast from top, non-intrusive
- History: date-grouped cards with source badge, source filtering (All/AI/Program/Custom), swipe-to-delete
- Maxes screen: all exercises with current best estimated 1RM, per-exercise detail with line chart + rep-range PR breakdown

### Claude's Discretion
- Exercise library data source (bundled JSON vs hardcoded vs Firestore)
- Chart library choice for progress charts
- Rest timer UI animation and styling details
- Background timer implementation approach (expo-task-manager vs expo-notifications scheduling)
- Workout auto-save frequency during logging (every set vs on finish)
- Delete confirmation UX (swipe + confirm vs immediate)

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| WORK-01 | User can log sets with reps and weight for any exercise | Set logging UX pattern, WorkoutRecord schema expansion, auto-save strategy |
| WORK-02 | User can start a rest timer between sets that works in background | Timestamp-based timer + expo-notifications scheduling |
| WORK-03 | Rest timer survives screen lock and app backgrounding | AppState listener + stored timestamps + scheduled notification |
| WORK-04 | User can search and filter exercise library (200+ exercises) | Bundled JSON exercise catalog with FlatList search filtering |
| WORK-05 | User can create custom exercises | Local/Firestore exercise repo with user-created exercises |
| WORK-07 | User can view workout history in chronological order | Existing WorkoutRepo.getHistory + date grouping helper |
| WORK-08 | User can filter history by source (AI/Program/Custom) | WorkoutRecord.source field already supports 'ai' / 'program' / 'custom' |
| WORK-09 | User can delete workouts from history | Existing WorkoutRepo.deleteWorkout + swipe gesture |
| WORK-10 | User can view progress charts per exercise | react-native-gifted-charts LineChart with 1RM time-series data |
| WORK-12 | User can build custom workout routines with drag-and-drop ordering | react-native-draggable-flatlist for exercise reordering |
| EXEC-01 | ForTime workouts with timer | Stopwatch (count-up) timer with optional time cap |
| EXEC-02 | AMRAP workouts with countdown timer | Countdown timer tracking completed rounds |
| EXEC-03 | EMOM workouts with interval timer | Interval timer with per-minute expo-notifications |
| EXEC-04 | Timer state preserves through screen lock | Timestamp persistence + AppState recalculation |
| MAX-01 | User can track one-rep max for any lift | Exercise PR repository with per-rep-range tracking |
| MAX-02 | User can view 1RM history over time | Line chart from react-native-gifted-charts |
| MAX-03 | App estimates 1RM from logged sets using standard formulas | Already complete — epley-formula.ts ported in Phase 2 |
</phase_requirements>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| expo-notifications | ~55.x | Local notification scheduling for rest timer, EMOM alerts | Official Expo module, handles iOS/Android permission differences, exact-time scheduling |
| react-native-gifted-charts | ^1.4.x | Line charts for 1RM history, progress visualization | Most complete RN chart library, pure JS (no Skia dependency), Expo-compatible, actively maintained |
| react-native-draggable-flatlist | ^4.x | Drag-and-drop exercise reordering in workout builder | Standard solution for sortable lists in RN, powered by Reanimated + Gesture Handler |
| expo-linear-gradient | ~55.x | Required peer dependency for react-native-gifted-charts | Expo-native gradient implementation |
| react-native-svg | (already installed via Expo) | Required peer dependency for charts | Standard SVG rendering for RN |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| react-native-reanimated | ~3.x (Expo-managed) | Required for draggable-flatlist, smooth timer animations | Already likely available via Expo SDK 55 |
| react-native-gesture-handler | ~2.x (Expo-managed) | Required for draggable-flatlist, swipe-to-delete | Already likely available via Expo SDK 55 |
| expo-haptics | ~55.x | Haptic feedback on PR detection, timer completion | Enhances physical feel of workout logging |
| expo-av | ~55.x | Beep sounds for 3-2-1-Go countdown, EMOM minute marks | Audio playback for timer sound cues |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| react-native-gifted-charts | victory-native | Victory requires Skia + Reanimated + Gesture Handler (heavier); does NOT support web builds natively. Gifted Charts is pure JS, lighter, web-compatible |
| react-native-gifted-charts | react-native-chart-kit | Chart-kit is older, less maintained, fewer chart types |
| expo-notifications (for timers) | expo-task-manager | Task manager is for periodic background tasks (min 15min intervals), NOT suitable for second-precision timers |
| expo-notifications (for timers) | react-native-background-timer | Requires native module, not Expo-managed, inconsistent behavior across platforms |
| Bundled JSON exercise library | Firestore exercise collection | Adds unnecessary network dependency for static data; 200+ exercises is < 50KB as JSON |

**Installation:**
```bash
cd SundeeFundeeRN && npx expo install expo-notifications expo-haptics expo-av react-native-gifted-charts expo-linear-gradient react-native-draggable-flatlist react-native-reanimated react-native-gesture-handler
```

## Architecture Patterns

### Recommended Project Structure
```
src/
├── domain/
│   ├── exercises/           # Exercise catalog types, muscle groups, search
│   ├── workout-session/     # Active workout state machine, set logging types
│   ├── timers/              # Timer state types, elapsed time calculations
│   ├── pr-detection/        # PR checking logic across rep ranges
│   ├── history/             # (existing) HistoryItem types
│   └── calculations/        # (existing) epley-formula, weight-calculations
├── repositories/
│   ├── ExerciseRepo.ts      # Exercise catalog + custom exercises
│   ├── ExerciseMaxRepo.ts   # Per-exercise PR/max tracking
│   ├── WorkoutRepo.ts       # (existing) workout records
│   └── ...
├── hooks/
│   ├── useWorkoutSession.ts # Active workout state management
│   ├── useRestTimer.ts      # Rest timer with background notification
│   ├── useWorkoutTimer.ts   # ForTime/AMRAP/EMOM timer logic
│   └── usePRDetection.ts    # Real-time PR checking on set completion
├── components/
│   ├── workout/             # SetRow, ExerciseCard, RestTimerBar, PRToast
│   ├── timer/               # TimerDisplay, CountdownOverlay, EMOMClock
│   ├── charts/              # ProgressChart, OneRMChart wrapper components
│   └── exercises/           # ExerciseLibrary, ExerciseSearch, MuscleGroupGrid
└── resources/
    └── exercises.json       # Bundled 200+ exercise catalog
app/
├── (app)/(tabs)/
│   ├── index.tsx            # Dashboard (existing)
│   ├── workout.tsx          # NEW: Active workout / workout builder
│   ├── history.tsx          # NEW: Workout history list
│   ├── maxes.tsx            # NEW: 1RM tracking / maxes list
│   └── settings.tsx         # Settings (existing, add rest timer default)
├── (app)/
│   ├── workout-session.tsx  # NEW: Modal — active workout logging screen
│   ├── timer-mode.tsx       # NEW: Modal — full-screen timed workout
│   ├── exercise-picker.tsx  # NEW: Modal — exercise library browser
│   ├── workout-detail.tsx   # NEW: Modal — completed workout detail
│   └── exercise-detail.tsx  # NEW: Modal — exercise 1RM history + charts
```

### Pattern 1: Timestamp-Based Timer (Critical Pattern)
**What:** Store start timestamp + accumulated pause duration rather than counting intervals. Recalculate display time from timestamps on every render and on AppState foreground.
**When to use:** All timers (rest, ForTime, AMRAP, EMOM)
**Why:** `setInterval` stops when app is backgrounded on both iOS and Android. Timestamp math is always accurate regardless of background/foreground transitions.
**Example:**
```typescript
// domain/timers/timer-state.ts
export interface TimerState {
  startedAt: number;       // Date.now() when timer started
  pausedAt: number | null; // Date.now() when paused (null if running)
  totalPausedMs: number;   // Accumulated pause duration
  durationMs: number;      // Target duration (0 for stopwatch/ForTime)
  mode: 'rest' | 'forTime' | 'amrap' | 'emom';
}

export function getElapsedMs(state: TimerState): number {
  const now = state.pausedAt ?? Date.now();
  return now - state.startedAt - state.totalPausedMs;
}

export function getRemainingMs(state: TimerState): number {
  return Math.max(0, state.durationMs - getElapsedMs(state));
}

// hooks/useRestTimer.ts
import { useRef, useState, useEffect, useCallback } from 'react';
import { AppState, AppStateStatus } from 'react-native';
import * as Notifications from 'expo-notifications';

export function useRestTimer(defaultSeconds: number) {
  const [timerState, setTimerState] = useState<TimerState | null>(null);
  const intervalRef = useRef<ReturnType<typeof setInterval>>();
  const notificationIdRef = useRef<string>();

  const start = useCallback(async (seconds?: number) => {
    const duration = (seconds ?? defaultSeconds) * 1000;
    const now = Date.now();
    const state: TimerState = {
      startedAt: now,
      pausedAt: null,
      totalPausedMs: 0,
      durationMs: duration,
      mode: 'rest',
    };
    setTimerState(state);

    // Schedule notification for when rest completes
    const id = await Notifications.scheduleNotificationAsync({
      content: {
        title: 'Rest Complete',
        body: 'Time for your next set!',
        sound: true,
      },
      trigger: {
        type: Notifications.SchedulableTriggerInputTypes.TIME_INTERVAL,
        seconds: seconds ?? defaultSeconds,
      },
    });
    notificationIdRef.current = id;

    // UI tick — only updates display, not timer state
    intervalRef.current = setInterval(() => {
      setTimerState(prev => prev ? { ...prev } : null); // force re-render
    }, 100);
  }, [defaultSeconds]);

  // Recalculate on foreground return
  useEffect(() => {
    const sub = AppState.addEventListener('change', (state: AppStateStatus) => {
      if (state === 'active' && timerState && !timerState.pausedAt) {
        setTimerState(prev => prev ? { ...prev } : null);
      }
    });
    return () => sub.remove();
  }, [timerState]);

  // ... skip, stop, cleanup
}
```

### Pattern 2: Exercise PR Repository with Multi-Rep-Range Tracking
**What:** Store best weight for each exercise at each tracked rep range (1, 3, 5, 8, 10) plus estimated 1RM history
**When to use:** PR detection and 1RM history screens
**Example:**
```typescript
// domain/pr-detection/pr-types.ts
export const TRACKED_REP_RANGES = [1, 3, 5, 8, 10] as const;
export type TrackedRepRange = typeof TRACKED_REP_RANGES[number];

export interface ExerciseMax {
  exerciseId: string;
  exerciseName: string;
  repRange: TrackedRepRange;
  weight: number;         // Best weight at this rep range
  estimated1RM: number;   // Epley estimate from this lift
  achievedAt: string;     // ISO timestamp
}

export interface PRCheckResult {
  isWeightPR: boolean;    // New best weight at this rep range
  is1RMPR: boolean;       // New best estimated 1RM
  repRange: TrackedRepRange | null;
  previousBest: number | null;
  newValue: number;
}
```

### Pattern 3: Active Workout Session State Machine
**What:** Manage in-progress workout as a state machine: idle -> active -> completing -> saved
**When to use:** Workout logging screen
**Example:**
```typescript
// domain/workout-session/session-types.ts
export interface LoggedSet {
  id: string;
  weight: number;
  reps: number;
  completed: boolean;
  completedAt?: string;   // ISO timestamp
  isPersonalRecord?: boolean;
}

export interface ActiveExercise {
  id: string;
  exerciseId: string;     // Reference to exercise catalog
  exerciseName: string;
  muscleGroup: string;
  sets: LoggedSet[];
  restSeconds?: number;   // Per-exercise override
  order: number;          // For drag-and-drop ordering
}

export interface WorkoutSession {
  id: string;
  startedAt: string;
  exercises: ActiveExercise[];
  timerMode?: 'forTime' | 'amrap' | 'emom';
  timerConfig?: {
    durationSeconds?: number;  // For AMRAP, ForTime cap
    intervalSeconds?: number;  // For EMOM (usually 60)
  };
}
```

### Pattern 4: Bundled Exercise Library with Search
**What:** JSON file bundled with app, loaded once into memory, filtered client-side
**When to use:** Exercise picker / library screens
**Example:**
```typescript
// domain/exercises/exercise-types.ts
export type MuscleGroup = 'Chest' | 'Back' | 'Legs' | 'Shoulders' | 'Arms' | 'Core' | 'Full Body';

export interface Exercise {
  id: string;
  name: string;
  muscleGroup: MuscleGroup;
  isCustom: boolean;
  equipmentType?: 'barbell' | 'dumbbell' | 'kettlebell' | 'machine' | 'bodyweight' | 'cable' | 'other';
}

// Bundled JSON shape: Exercise[] — loaded via require('../resources/exercises.json')
```

### Anti-Patterns to Avoid
- **Interval-based timers:** Never use `setInterval` as the source of truth for elapsed time. JS execution pauses when backgrounded. Always derive from timestamps.
- **Storing active workout only in React state:** If the app crashes mid-workout, all data is lost. Auto-save to AsyncStorage on each set completion.
- **Fetching exercise library from network:** 200+ exercises is tiny as JSON (~30-50KB). Bundling eliminates a network dependency and works offline by default.
- **Single 1RM value per exercise:** Users expect rep-range-specific PRs (3RM, 5RM, etc.), not just overall 1RM. Store per-rep-range maxes.
- **Blocking UI on PR check:** PR detection should be synchronous (compare against in-memory cache of maxes), not a Firestore round-trip.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Drag-and-drop list reordering | Custom PanResponder gesture handler | `react-native-draggable-flatlist` | Smooth native-driven animations, haptic feedback, edge cases with scroll vs drag |
| Chart rendering | Custom SVG path generation | `react-native-gifted-charts` LineChart | Axis scaling, labels, touch interaction, responsive sizing all handled |
| Background notification scheduling | Custom background task with setInterval | `expo-notifications` scheduleNotificationAsync | OS-level notification delivery, works when app is killed, handles Doze mode |
| Swipe-to-delete gesture | Custom Animated.View swipe handler | `react-native-gesture-handler` Swipeable or expo-router's built-in | Threshold detection, snap-back animation, simultaneous gesture recognition |
| Sound playback for timer beeps | Custom audio bridge | `expo-av` Audio.Sound | Cross-platform audio loading, interrupt mode, background audio mixing |

**Key insight:** Workout apps have well-established UX patterns (Strong, Hevy, JEFIT). The libraries above implement these patterns with native-quality animations. Custom gesture handling for drag-and-drop and swipe-to-delete is a multi-week rabbit hole.

## Common Pitfalls

### Pitfall 1: Timer Drift on Background/Foreground
**What goes wrong:** Timer shows incorrect elapsed time after returning from background because `setInterval` was paused by OS
**Why it happens:** iOS and Android suspend JS execution when app is backgrounded
**How to avoid:** Store `startedAt` timestamp, derive elapsed time from `Date.now() - startedAt - totalPausedMs`
**Warning signs:** Timer "catches up" visually when returning to app, or shows wildly wrong values

### Pitfall 2: iOS Repeating Notification Minimum Interval
**What goes wrong:** EMOM minute-mark notifications silently fail on iOS
**Why it happens:** iOS requires repeating notification intervals to be >= 60 seconds. If you try to schedule repeating notifications at < 60s, they won't fire.
**How to avoid:** For EMOM, schedule individual (non-repeating) notifications for each minute mark. For a 20-minute EMOM, schedule 20 separate notifications.
**Warning signs:** Notifications work on Android but not iOS

### Pitfall 3: Android SCHEDULE_EXACT_ALARM Permission
**What goes wrong:** Scheduled notifications arrive late or not at all on Android 12+
**Why it happens:** Android 12+ requires `SCHEDULE_EXACT_ALARM` permission for precise notification timing
**How to avoid:** Add `<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>` to AndroidManifest.xml via `app.json` plugins config
**Warning signs:** Notifications work in dev but fail on production Android builds

### Pitfall 4: WorkoutRecord Schema Mismatch
**What goes wrong:** Existing `WorkoutRecord.workout` field stores `GeneratedWorkout` type, which is AI-workout-specific (has `questionnaire`, `coachingSummary`). Custom workouts don't have this data.
**Why it happens:** Schema was designed for AI workout flow in Phase 3
**How to avoid:** Expand WorkoutRecord schema to handle custom workout data OR create a unified workout data shape that both AI and custom workouts can populate. Recommend adding a `customWorkout` field alongside `workout` (discriminated by `source` field).
**Warning signs:** TypeScript errors when trying to save custom workout data to WorkoutRecord

### Pitfall 5: PR Cache Invalidation
**What goes wrong:** PR detection misses a PR or double-celebrates because the in-memory max cache is stale
**Why it happens:** Multiple places update maxes (set completion, workout deletion, data sync)
**How to avoid:** Load maxes into a React context at workout start, update context on each set completion, persist to repo. On workout delete, recompute affected maxes from history.
**Warning signs:** "New PR!" shows for a weight the user has already hit, or no PR shows when it should

### Pitfall 6: Notification Permission Not Requested Before First Use
**What goes wrong:** Rest timer notifications never appear; user doesn't know why
**Why it happens:** iOS and Android 13+ require explicit notification permission. If not requested before scheduling, notifications are silently dropped.
**How to avoid:** Request notification permission during onboarding or on first workout start. Check permission before scheduling and show UI guidance if denied.
**Warning signs:** Works in simulator but not on physical device

### Pitfall 7: Auto-Save Data Loss on App Crash
**What goes wrong:** User loses an entire workout if the app crashes mid-session
**Why it happens:** Workout data only exists in React state, not persisted
**How to avoid:** Auto-save to AsyncStorage on every set completion (not just on workout finish). Use a `@sundee/active-workout` key. Restore from it on app launch.
**Warning signs:** User reports losing workout data, crash reports during workouts

## Code Examples

### Scheduling EMOM Minute-Mark Notifications
```typescript
// Schedule individual notifications for each EMOM minute
async function scheduleEMOMNotifications(
  totalMinutes: number
): Promise<string[]> {
  const ids: string[] = [];
  for (let minute = 1; minute <= totalMinutes; minute++) {
    const id = await Notifications.scheduleNotificationAsync({
      content: {
        title: `Minute ${minute}`,
        body: 'Start next round!',
        sound: true,
      },
      trigger: {
        type: Notifications.SchedulableTriggerInputTypes.TIME_INTERVAL,
        seconds: minute * 60,
      },
    });
    ids.push(id);
  }
  return ids;
}

// Cancel all on workout stop/pause
async function cancelEMOMNotifications(ids: string[]): Promise<void> {
  await Promise.all(ids.map(id =>
    Notifications.cancelScheduledNotificationAsync(id)
  ));
}
```

### PR Detection on Set Completion
```typescript
// domain/pr-detection/check-pr.ts
import { estimated1RM, isPR } from '../calculations/epley-formula';
import type { ExerciseMax, PRCheckResult, TrackedRepRange } from './pr-types';

const TRACKED_REP_RANGES: TrackedRepRange[] = [1, 3, 5, 8, 10];

export function checkForPR(
  exerciseId: string,
  weight: number,
  reps: number,
  currentMaxes: ExerciseMax[]
): PRCheckResult {
  // Find closest tracked rep range
  const repRange = TRACKED_REP_RANGES.reduce((closest, range) =>
    Math.abs(range - reps) < Math.abs(closest - reps) ? range : closest
  );

  // Check weight PR at this rep range
  const maxAtRange = currentMaxes.find(
    m => m.exerciseId === exerciseId && m.repRange === repRange
  );
  const isWeightPR = !maxAtRange || weight > maxAtRange.weight;

  // Check estimated 1RM PR
  const newEstimate = estimated1RM(weight, reps);
  const best1RM = currentMaxes
    .filter(m => m.exerciseId === exerciseId)
    .reduce((best, m) => Math.max(best, m.estimated1RM), 0);
  const is1RMPR = isPR(newEstimate, best1RM || undefined);

  return {
    isWeightPR,
    is1RMPR,
    repRange,
    previousBest: maxAtRange?.weight ?? null,
    newValue: weight,
  };
}
```

### Exercise Library Search Filtering
```typescript
// Pure function — testable without React
export function filterExercises(
  exercises: Exercise[],
  query: string,
  muscleGroup?: MuscleGroup
): Exercise[] {
  let filtered = exercises;
  if (muscleGroup) {
    filtered = filtered.filter(e => e.muscleGroup === muscleGroup);
  }
  if (query.trim()) {
    const q = query.toLowerCase().trim();
    filtered = filtered.filter(e =>
      e.name.toLowerCase().includes(q)
    );
  }
  return filtered;
}
```

### WorkoutRecord Schema Expansion
```typescript
// Expanded WorkoutRecord to support custom workouts
export interface WorkoutRecord {
  id: string;
  uid: string;
  completedAt: string;
  durationSeconds: number;
  source: 'ai' | 'program' | 'custom';
  // AI workout data (populated when source === 'ai')
  workout?: GeneratedWorkout;
  // Custom/program workout data (populated when source === 'custom' | 'program')
  exercises?: CompletedExercise[];
  workoutName?: string;
  timerMode?: 'forTime' | 'amrap' | 'emom' | 'none';
  totalVolume?: number;      // Pre-computed total weight x reps
  exerciseCount?: number;
}

export interface CompletedExercise {
  exerciseId: string;
  exerciseName: string;
  muscleGroup: string;
  sets: CompletedSet[];
}

export interface CompletedSet {
  weight: number;
  reps: number;
  isPersonalRecord: boolean;
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `setInterval` background timers | Timestamp + AppState recalculation | Always been the RN pattern | Eliminates timer drift entirely |
| react-native-background-timer | expo-notifications scheduling | 2024+ (Expo managed workflow) | No native module dependency, works with Expo |
| react-native-chart-kit | react-native-gifted-charts | 2023+ | Chart-kit unmaintained; gifted-charts actively maintained with 75+ chart configs |
| Single 1RM tracking | Per-rep-range PR tracking | Industry standard (Strong, Hevy) | Users expect granular PR data, not just overall 1RM |
| expo-background-fetch | expo-background-task | Late 2024 | New API replaces deprecated background-fetch, but neither is suitable for second-precision timers |

**Deprecated/outdated:**
- `react-native-background-timer`: Works but requires bare workflow; not Expo-managed-compatible
- `react-native-chart-kit`: Last meaningful update 2021; use gifted-charts instead
- `expo-background-fetch`: Replaced by `expo-background-task` but minimum 15min intervals — NOT for timers

## Open Questions

1. **HistoryItem type expansion**
   - What we know: Current `HistoryItem` has `source: HistoryItemSource` with only `aiWorkout` and `program` kinds. Need `custom` kind.
   - What's unclear: Whether to expand HistoryItem or create a new unified type
   - Recommendation: Add `{ kind: 'custom' }` to `HistoryItemSource` union — minimal change, backward compatible

2. **Reanimated/Gesture Handler version compatibility**
   - What we know: Expo SDK 55 ships with compatible versions of both
   - What's unclear: Whether react-native-draggable-flatlist's latest version works with Expo SDK 55's Reanimated version
   - Recommendation: Check peer dependency compatibility during installation; if issues, pin to known-good version

3. **Notification sound on iOS in silent mode**
   - What we know: iOS respects silent switch for notification sounds
   - What's unclear: Whether timer beep sounds should bypass silent mode (workout apps often do)
   - Recommendation: Use `expo-av` for 3-2-1-Go countdown sounds (plays through speaker), `expo-notifications` sound for background alerts (respects silent mode — this is correct UX)

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Jest 30 + jest-expo 55 + @testing-library/react-native 13 |
| Config file | `SundeeFundeeRN/jest.config.js` |
| Quick run command | `cd SundeeFundeeRN && npx jest --testPathPattern=src/ --passWithNoTests` |
| Full suite command | `cd SundeeFundeeRN && npx jest --coverage` |

### Phase Requirements -> Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| WORK-01 | Log sets with reps and weight | unit | `npx jest src/domain/__tests__/workout-session.test.ts` | No — Wave 0 |
| WORK-02 | Rest timer starts and counts in background | unit | `npx jest src/hooks/__tests__/useRestTimer.test.ts` | No — Wave 0 |
| WORK-03 | Rest timer survives screen lock | unit | `npx jest src/domain/__tests__/timers.test.ts` | No — Wave 0 |
| WORK-04 | Exercise library search and filter | unit | `npx jest src/domain/__tests__/exercises.test.ts` | No — Wave 0 |
| WORK-05 | Create custom exercises | unit | `npx jest src/repositories/__tests__/ExerciseRepo.test.ts` | No — Wave 0 |
| WORK-07 | View workout history | unit | `npx jest src/repositories/__tests__/LocalWorkoutRepo.test.ts` | Yes |
| WORK-08 | Filter history by source | unit | `npx jest src/domain/__tests__/history-filter.test.ts` | No — Wave 0 |
| WORK-09 | Delete workouts from history | unit | `npx jest src/repositories/__tests__/LocalWorkoutRepo.test.ts` | Yes |
| WORK-10 | Progress charts per exercise | unit | `npx jest src/domain/__tests__/progress-data.test.ts` | No — Wave 0 |
| WORK-12 | Build custom workout with drag ordering | unit | `npx jest src/domain/__tests__/workout-session.test.ts` | No — Wave 0 |
| EXEC-01 | ForTime timer counts up | unit | `npx jest src/domain/__tests__/timers.test.ts` | No — Wave 0 |
| EXEC-02 | AMRAP countdown timer | unit | `npx jest src/domain/__tests__/timers.test.ts` | No — Wave 0 |
| EXEC-03 | EMOM interval timer | unit | `npx jest src/domain/__tests__/timers.test.ts` | No — Wave 0 |
| EXEC-04 | Timer persists through screen lock | unit | `npx jest src/domain/__tests__/timers.test.ts` | No — Wave 0 |
| MAX-01 | Track 1RM for any lift | unit | `npx jest src/repositories/__tests__/ExerciseMaxRepo.test.ts` | No — Wave 0 |
| MAX-02 | View 1RM history over time | unit | `npx jest src/domain/__tests__/progress-data.test.ts` | No — Wave 0 |
| MAX-03 | Estimate 1RM from logged sets | unit | `npx jest src/domain/__tests__/calculations.test.ts` | Yes |

### Sampling Rate
- **Per task commit:** `cd SundeeFundeeRN && npx jest --testPathPattern=src/ --passWithNoTests`
- **Per wave merge:** `cd SundeeFundeeRN && npx jest --coverage`
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] `src/domain/__tests__/timers.test.ts` — covers WORK-02, WORK-03, EXEC-01, EXEC-02, EXEC-03, EXEC-04
- [ ] `src/domain/__tests__/exercises.test.ts` — covers WORK-04 (exercise search/filter)
- [ ] `src/domain/__tests__/workout-session.test.ts` — covers WORK-01, WORK-12 (set logging, workout building)
- [ ] `src/domain/__tests__/pr-detection.test.ts` — covers MAX-01 (PR checking at rep ranges)
- [ ] `src/domain/__tests__/history-filter.test.ts` — covers WORK-08 (source filtering)
- [ ] `src/domain/__tests__/progress-data.test.ts` — covers WORK-10, MAX-02 (chart data preparation)
- [ ] `src/repositories/__tests__/ExerciseRepo.test.ts` — covers WORK-05 (custom exercise CRUD)
- [ ] `src/repositories/__tests__/ExerciseMaxRepo.test.ts` — covers MAX-01 (max persistence)
- [ ] `src/hooks/__tests__/useRestTimer.test.ts` — covers WORK-02 (timer hook)
- [ ] `expo-notifications`, `expo-haptics`, `expo-av` — new dependencies to install
- [ ] `react-native-gifted-charts`, `react-native-draggable-flatlist` — new dependencies to install

## Sources

### Primary (HIGH confidence)
- [Expo Notifications docs](https://docs.expo.dev/versions/latest/sdk/notifications/) — scheduling API, trigger types, permissions
- [Expo TaskManager docs](https://docs.expo.dev/versions/latest/sdk/task-manager/) — confirmed NOT suitable for second-precision timers
- [react-native-gifted-charts npm](https://www.npmjs.com/package/react-native-gifted-charts) — v1.4.57, Expo install command
- [react-native-draggable-flatlist GitHub](https://github.com/computerjazz/react-native-draggable-flatlist) — Expo support confirmed

### Secondary (MEDIUM confidence)
- [Expo background timer pattern (Medium)](https://aloukissas.medium.com/how-to-build-a-background-timer-in-expo-react-native-without-ejecting-ea7d67478408) — timestamp-based approach, verified against Expo docs
- [RN chart library comparison (LogRocket)](https://blog.logrocket.com/top-react-native-chart-libraries/) — gifted-charts recommended for Expo
- [Timer state management (DEV.to)](https://dev.to/shivampawar/efficiently-managing-timers-in-a-react-native-app-overcoming-background-foreground-timer-state-issues-map) — AppState listener pattern

### Tertiary (LOW confidence)
- Victory Native web build limitation — mentioned in multiple sources but not verified in official docs with SDK 55 specifically

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Libraries verified via npm and official docs, Expo compatibility confirmed
- Architecture: HIGH - Patterns based on established RN workout app patterns (Strong/Hevy) and existing codebase conventions
- Timer implementation: MEDIUM-HIGH - Timestamp approach is well-documented; EMOM notification scheduling needs on-device testing for exact-alarm reliability
- Charts: MEDIUM - react-native-gifted-charts is actively maintained and Expo-compatible, but line chart time-series config needs validation during implementation
- Pitfalls: HIGH - All sourced from official docs or verified community reports

**Research date:** 2026-03-14
**Valid until:** 2026-04-14 (30 days — stable domain, libraries actively maintained)
