# Phase 4: Core Workout Loop - Context

**Gathered:** 2026-03-14
**Status:** Ready for planning

<domain>
## Phase Boundary

Users can log any workout, execute timed workouts, and see their progress — entirely offline if needed. This includes: exercise library (200+), set logging, rest timers, ForTime/AMRAP/EMOM workout timers, PR detection, workout history, progress charts, and 1RM tracking. Programs, cycle adaptation, injury engine, AI workouts, and benchmarks are Phase 5.

</domain>

<decisions>
## Implementation Decisions

### Exercise library organization
- Primary grouping by muscle group categories: Chest, Back, Legs, Shoulders, Arms, Core, Full Body
- Users tap a category to see exercises within it
- Search bar at top filters across all exercises
- Custom exercise creation is inline from search: when no match found, show "Create [exercise name]" option at bottom of results
- Tapping "Create" opens a quick form: name (pre-filled from search text), muscle group picker
- Minimal friction — stays in the existing flow

### Set logging UX
- Inline set rows beneath each exercise card
- Each row shows: previous workout value (ghost text), weight input, reps input, check mark to complete
- "+set" button to add additional sets
- Previous workout's values shown as grayed-out placeholders in weight/reps fields for easy matching
- Build-as-you-go for custom workouts: start empty, add exercises from library one at a time
- Long-press to reorder exercises (drag-and-drop)
- No template builder in Phase 4 — just build-as-you-go

### Rest timer behavior
- Auto-starts on set completion (checking off a set)
- Countdown visible at bottom of screen with "Skip" button
- Global default rest duration configurable in settings (e.g., 90s)
- Per-exercise override available (set a custom rest time per exercise)
- When rest finishes while backgrounded/locked: fire a local push notification ("Rest complete — time for your next set") with sound + vibration
- Timer continues counting in background; when user returns, shows elapsed time past rest period

### Timed workout modes (ForTime, AMRAP, EMOM)
- Full-screen dedicated timer mode entered by tapping "Start"
- Big countdown/stopwatch display at top, exercise list below, log reps as you go
- ForTime: counts UP (stopwatch style) with optional time cap — user stops when finished
- AMRAP: counts DOWN from set time limit, tracks completed rounds
- EMOM: interval timer with per-minute boundaries
- 3-2-1-Go countdown with beep sounds before timed workout starts
- Timer state persists through screen lock on iOS and Android
- EMOM fires local notification at each minute mark when backgrounded ("Minute 4 — start next round") with sound + vibration
- Pause and Stop buttons available during all timed modes

### PR detection and celebration
- PR triggers on two conditions: heaviest weight at a tracked rep range OR new estimated 1RM (via Epley formula, already ported)
- Tracked rep ranges: 1RM, 3RM, 5RM, 8RM, 10RM (standard training zones)
- Both actual weight PRs and estimated 1RM PRs trigger notifications
- Celebration style: inline badge on the completed set row + toast notification from top
- Toast format: "New PR! Bench Press — 185 lbs" or "New est. 1RM PR! Squat — 285 lbs (from 225x8)"
- Non-intrusive — does not interrupt workout flow
- PR badge visible on the exercise detail (e.g., "PR: 185 lbs (Jan 5)")
- Full PR history in dedicated 1RM/Maxes screen

### History view
- Cards grouped by date (date headers: "Today", "Yesterday", "Mar 12", etc.)
- Each card shows: workout name, source badge (AI/Program/Custom), duration, exercise count, total volume
- Source filtering: All / AI / Program / Custom (segmented control or filter chips)
- Swipe left to delete individual workouts
- Tapping a card navigates to full workout detail screen
- Detail screen shows: date, duration, source, each exercise with all logged sets, PRs from that session highlighted

### 1RM and progress tracking
- Maxes screen: list of all exercises user has logged, showing current best estimated 1RM for each
- Search/filter at top of maxes list
- Tapping an exercise shows: estimated 1RM line chart over time + per-rep-range PR breakdown (1RM, 3RM, 5RM, 8RM, 10RM)
- PR info also visible from exercise detail in workout history (badge with PR value and date)

### Claude's Discretion
- Exercise library data source (bundled JSON vs hardcoded vs Firestore)
- Exact chart library choice for progress charts
- Rest timer UI animation and styling details
- Background timer implementation approach (expo-task-manager vs expo-notifications scheduling)
- Workout auto-save frequency during logging (every set vs on finish)
- Delete confirmation UX (swipe + confirm vs immediate)

</decisions>

<specifics>
## Specific Ideas

- Set logging screen matches the Strong/Hevy pattern: inline set rows with previous workout values as ghost text placeholders
- ForTime counts up like a stopwatch (not countdown) — matches how CrossFit-style ForTime workouts actually work
- EMOM needs per-minute notifications even when backgrounded — this is the killer feature for EMOM training
- PR tracking is granular: 5 standard rep ranges (1RM, 3RM, 5RM, 8RM, 10RM) rather than just overall heaviest
- Estimated 1RM PRs are celebrated too, not just actual weight PRs — catches gains during hypertrophy blocks
- STATE.md flags Android background timer as a known blocker needing implementation spike

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- `WorkoutRepo` interface + `FirestoreWorkoutRepo` + `LocalWorkoutRepo`: already built with saveWorkout, getHistory, deleteWorkout — source types: 'ai' | 'program' | 'custom'
- `WorkoutRecord` type: id, uid, completedAt, durationSeconds, source, workout (GeneratedWorkout)
- Domain calculations: `epleyOneRepMax()`, `weightCalculations`, `plateCalculation` — all ported and tested
- Domain types: `ProgramExercise`, `ExerciseValue`, `WorkoutFocus`, `EnergyLevel` — ready for UI consumption
- Theme tokens: cream/navy/orange palette, semantic aliases (background, text, accent, surface, error, border)
- `OfflineBanner` component: existing offline status display
- `AuthContext` / `SessionProvider`: auth state for repo factory selection

### Established Patterns
- Repository factory pattern: `getWorkoutRepo(isGuest)` returns Firestore or AsyncStorage implementation
- Platform-specific file extensions (.native.ts / .web.ts) for platform branching
- Kebab-case file names, barrel index.ts exports per directory
- Jest mock infrastructure in `__mocks__/`
- Expo Router file-based routing: `app/(app)/(tabs)/` for tab screens

### Integration Points
- Tab navigation: currently has `index.tsx` (dashboard) and `settings.tsx` — need to add History, Maxes tabs
- `WorkoutRecord.workout` field stores `GeneratedWorkout` — may need schema expansion for custom/program workout data
- `getWorkoutRepo(isGuest)` from `AuthContext.isGuest` drives implementation selection
- Notifications: need `expo-notifications` for rest timer and EMOM interval alerts
- Background execution: need investigation for timer persistence through screen lock (expo-task-manager or notification scheduling)

</code_context>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 04-core-workout-loop*
*Context gathered: 2026-03-14*
