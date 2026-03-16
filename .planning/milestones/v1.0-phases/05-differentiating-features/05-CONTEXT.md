# Phase 5: Differentiating Features - Context

**Gathered:** 2026-03-15
**Status:** Ready for planning

<domain>
## Phase Boundary

Cycle-aware training adaptation, injury modification, AI workout generation, programs, benchmarks, WODs, and readiness are all live and integrated. This phase wires the fully-ported domain layer (Phase 2) to new repository implementations and UI screens. Users who opted into cycle tracking see adaptation; users with injuries see substitutions; everyone can generate AI workouts, browse programs, record benchmarks, and view daily WODs.

</domain>

<decisions>
## Implementation Decisions

### Cycle tracking UI & flow
- Calendar tap interaction for period logging — monthly calendar view where users tap dates to mark period start/end
- Dashboard banner showing current phase (e.g., "Follicular — Day 8") with color coding, plus dedicated Cycle tab with full detail
- 2-cycle forecast on Cycle tab — predicted phases for ~2 months based on average cycle length
- No symptom logging — readiness survey (READ-01) already captures energy/mood/stress, avoids redundancy
- Cycle features only visible to opted-in users (CYCL-05)

### Workout adaptation indicators
- Subtle inline indicators on affected sets showing adjusted values (e.g., "↓ 10%") with tooltip explaining why
- Non-intrusive — advanced users see it, beginners aren't confused
- Adaptation happens automatically; indicators are informational only

### Injury management UX
- Body map tap for injury creation — visual body diagram, tap affected area, select recovery phase (acute/subacute/remodeling/return)
- Pain logging available both post-workout (prompt: "How's your [area] feeling?" with 1-10 slider) AND on injury profile screen for manual logging and trend viewing
- Exercise substitutions shown as both pre-workout summary card ("2 exercises modified for Right Knee") AND inline labels on individual exercises ("Replaces Barbell Squat — knee injury")
- Phase transition advice surfaces as in-app banner on injury profile screen only — no push notifications for medical-adjacent advice
- Rehab sessions accessible both as standalone button on injury profile ("Generate Rehab Session") AND woven into AI workouts as warm-up/cool-down section

### AI workout generation
- Quick config cards for input: horizontal scrollable cards for Time (15/30/45/60 min), Focus (Upper/Lower/Full/Push/Pull), Equipment (Full Gym/Dumbbells Only/Bodyweight), Energy (Low/Medium/High)
- Cycle phase, injuries, and readiness feed in automatically with visible summary chip: "Adapting for: Luteal phase · Right knee (subacute) · Readiness 7/10"
- Preview screen after generation showing exercises, sets, reps, estimated time — "Start Workout" or "Regenerate" buttons, no editing the AI output
- Migrate from Cloudflare Worker to Firebase Cloud Function for Gemini proxy
- Transparent offline fallback: "You're offline — here's a workout based on your preferences" with badge, same workout UI

### Program catalog & enrollment
- Card grid layout with filter chips (Strength / Hypertrophy / Power / All) for program browsing
- Tap card to see full program detail with weekly breakdown
- Target weights auto-calculated from user's logged 1RM (e.g., "Back Squat 5x5 @ 75%" shows "225 lbs" if 1RM is 300). Falls back to percentage if no 1RM logged
- Enrollment flow prompts for missing key lift 1RMs: "Log your Squat 1RM for accurate target weights" with quick-entry fields

### Benchmark recording
- Scoring-aware input adapts to benchmark type: ForTime shows time picker (MM:SS), AMRAP shows rounds + reps inputs, MaxLoad shows weight input
- Purpose-built forms per scoring type — matches existing domain scoring types (BenchmarkScoringType)
- Custom benchmark creation supported (BNCH-04)

### WOD display
- Prominent dashboard card: "Today's WOD: [Name]" with brief description and "Start" button
- Also accessible from dedicated WODs section for browsing past WODs
- WODs fetched from Firestore, matched by date (WODS-02)

### Readiness survey
- Morning prompt on dashboard: if no survey completed today, show dismissable card "How are you feeling today?"
- Quick 4-slider survey (sleep, energy, stress, motivation) — takes <15 seconds
- Readiness score feeds into workout adaptation (cycle adaptation + AI generation)
- Available to all users, not just cycle-tracking users

### Claude's Discretion
- Body map illustration style and level of detail
- Calendar component library choice for period logging
- Exact adaptation indicator positioning and animation
- Pain trend chart visualization (line chart vs bar chart)
- Cloud Function cold start mitigation strategy (noted in STATE.md blockers)
- Program card visual design and information density
- WOD browsing/archive UX for past WODs
- Readiness slider component styling
- Benchmark history chart visualization

</decisions>

<specifics>
## Specific Ideas

- Cycle phase dashboard banner should feel like a gentle contextual hint, not a medical dashboard — color coding by phase (e.g., soft red for menstrual, green for follicular) but tasteful
- Body map for injuries inspired by physiotherapy apps — simple outline, tap regions highlight
- AI workout config cards should feel like Uber's ride selection — horizontal scroll, one tap per category, then go
- "Adapting for:" summary chip on AI generation screen provides transparency without requiring user action
- Pre-workout injury modification summary card prevents surprise substitutions mid-workout
- Program enrollment 1RM prompt is a gate that improves experience quality, not a blocker — user can skip and get percentage-only targets

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- `src/domain/cycle/`: CycleCalculations (phase inference), CycleAdaptationPolicy (load multipliers), CycleProgramGenerator — fully ported and tested
- `src/domain/injury/`: InjuryAdaptationEngine, PainTrendAnalyzer, PhaseTransitionAdvisor, RehabSessionGenerator, BodyLocation, RecoveryPhase — fully ported and tested
- `src/domain/ai-workout/`: GeneratedWorkout, WorkoutGenerationContext, OfflineWorkoutGenerator — fully ported
- `src/domain/benchmarks/`: BenchmarkCatalog with scoring types — ported
- `src/domain/readiness/`: ReadinessSurvey — ported
- `src/domain/pr-detection/`: PR detection with multi-rep-range support — ported
- `ReadinessRepo` interface + `FirestoreReadinessRepo` + `LocalReadinessRepo`: already built
- `ExerciseMaxRepo`: already built with saveMax/getMaxes — needed for program target weight calculation
- `WorkoutRepo`: saveWorkout/getHistory/deleteWorkout with source types 'ai' | 'program' | 'custom'
- Theme tokens: cream/navy/orange palette, semantic aliases
- `OfflineBanner` component: existing offline status display
- Chart components in `src/components/charts/`: built for Phase 4 progress charts

### Established Patterns
- Repository factory: `getXxxRepo(isGuest)` returns Firestore or AsyncStorage implementation
- Platform-specific file extensions (.native.ts / .web.ts) for platform branching
- Kebab-case file names, barrel index.ts exports per directory
- Expo Router file-based routing: `app/(app)/(tabs)/` for tab screens
- `useFocusEffect` for data refresh on screen focus (Phase 4 pattern)
- exercises.json bundled as static JSON for offline catalog

### Integration Points
- Tab navigation: currently has index (dashboard), history, maxes, settings — need to add Cycle tab, possibly Programs tab
- Dashboard: needs WOD card, readiness survey prompt, cycle phase banner
- Workout session screen: needs injury substitution indicators, cycle adaptation indicators
- New repos needed: CycleRepo, InjuryRepo, ProgramRepo, BenchmarkRepo, WODRepo (interfaces + dual implementations)
- Firebase Cloud Function: new `functions/` directory for Gemini proxy — replaces Cloudflare Worker
- Cloudflare Worker URL: `workout-proxy.sundeefundee.workers.dev/generate-workout` (current, to be replaced)

</code_context>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 05-differentiating-features*
*Context gathered: 2026-03-15*
