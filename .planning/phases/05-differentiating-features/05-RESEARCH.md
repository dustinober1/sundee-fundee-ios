# Phase 5: Differentiating Features - Research

**Researched:** 2026-03-15
**Domain:** React Native + Expo + Firebase — Feature wiring: Cycle tracking UI, injury management, AI workout generation, programs, benchmarks, WODs, readiness survey
**Confidence:** HIGH (domain layer fully ported, repo patterns established, code inspected directly)

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Cycle tracking UI & flow**
- Calendar tap interaction for period logging — monthly calendar view where users tap dates to mark period start/end
- Dashboard banner showing current phase (e.g., "Follicular — Day 8") with color coding, plus dedicated Cycle tab with full detail
- 2-cycle forecast on Cycle tab — predicted phases for ~2 months based on average cycle length
- No symptom logging — readiness survey (READ-01) already captures energy/mood/stress
- Cycle features only visible to opted-in users (CYCL-05)

**Workout adaptation indicators**
- Subtle inline indicators on affected sets showing adjusted values (e.g., "↓ 10%") with tooltip explaining why
- Non-intrusive — advanced users see it, beginners aren't confused
- Adaptation happens automatically; indicators are informational only

**Injury management UX**
- Body map tap for injury creation — visual body diagram, tap affected area, select recovery phase (acute/subacute/remodeling/return)
- Pain logging available post-workout ("How's your [area] feeling?" 1-10 slider) AND on injury profile screen for manual logging and trend viewing
- Substitutions shown as pre-workout summary card ("2 exercises modified for Right Knee") AND inline labels ("Replaces Barbell Squat — knee injury")
- Phase transition advice surfaces as in-app banner on injury profile screen only — no push notifications
- Rehab sessions accessible as standalone button on injury profile ("Generate Rehab Session") AND woven into AI workouts as warm-up/cool-down section

**AI workout generation**
- Quick config cards for input: horizontal scrollable cards for Time / Focus / Equipment / Energy
- Cycle phase, injuries, and readiness feed in automatically with visible summary chip: "Adapting for: Luteal phase · Right knee (subacute) · Readiness 7/10"
- Preview screen after generation: "Start Workout" or "Regenerate" buttons, no editing AI output
- Migrate from Cloudflare Worker to Firebase Cloud Function for Gemini proxy
- Transparent offline fallback: "You're offline — here's a workout based on your preferences" with badge

**Program catalog & enrollment**
- Card grid layout with filter chips (Strength / Hypertrophy / Power / All) for program browsing
- Tap card to see full program detail with weekly breakdown
- Target weights auto-calculated from user's logged 1RM (falls back to percentage if no 1RM logged)
- Enrollment flow prompts for missing key lift 1RMs with quick-entry fields; skippable

**Benchmark recording**
- Scoring-aware input adapts to benchmark type: ForTime (time picker MM:SS), AMRAP (rounds + reps inputs), MaxLoad (weight input)
- Purpose-built forms per scoring type
- Custom benchmark creation supported (BNCH-04)

**WOD display**
- Prominent dashboard card: "Today's WOD: [Name]" with brief description and "Start" button
- Also accessible from dedicated WODs section for browsing past WODs
- WODs fetched from Firestore, matched by date (WODS-02)

**Readiness survey**
- Morning prompt on dashboard: dismissable card "How are you feeling today?"
- Quick 4-slider survey (sleep, energy, stress, motivation) — takes <15 seconds
- Readiness score feeds into workout adaptation
- Available to all users, not just cycle-tracking users

### Claude's Discretion
- Body map illustration style and level of detail
- Calendar component library choice for period logging
- Exact adaptation indicator positioning and animation
- Pain trend chart visualization (line chart vs bar chart)
- Cloud Function cold start mitigation strategy
- Program card visual design and information density
- WOD browsing/archive UX for past WODs
- Readiness slider component styling
- Benchmark history chart visualization

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| CYCL-01 | User can log period start and end dates | CycleRepo needed; calendar component; PeriodLog type already defined in domain types |
| CYCL-02 | User can log daily symptoms (energy, mood, cramps) | Decision: readiness survey covers this — CYCL-02 maps to readiness, not separate symptom tracking |
| CYCL-03 | App infers current cycle phase from period logs | `calculateCycleStatus()` already ported in `src/domain/cycle/cycle-calculations.ts` |
| CYCL-04 | User can view current phase and predicted upcoming phases | `getPhaseBoundaries()` + `calculateCycleStatus()` enable 2-cycle forecast; Cycle tab screen needed |
| CYCL-05 | Cycle features only visible to opted-in users | Gate on `onboardingProfile.cycleTrackingEnabled` field (ONBD-02 already stores this) |
| CYAD-01 | Workout load automatically adjusts based on current cycle phase | `CycleAdaptationPolicy` ported; wire into workout-session screen |
| CYAD-02 | Set and rep targets scale with phase-specific multipliers | Same `cycle-adaptation-policy.ts` module; inline adaptation indicators in workout-session |
| CYAD-03 | Adaptation integrates with readiness score | `blendMultiplier` in adaptation policy + `ReadinessRepo.getSurveyForDate()` already built |
| READ-01 | User can complete daily readiness survey (sleep, energy, stress, motivation) | `ReadinessRepository` + `FirestoreReadinessRepo` + `LocalReadinessRepo` already built |
| READ-02 | Readiness score feeds into workout adaptation intensity | `calculateReadinessScore()` in `readiness-survey.ts` → wire score into AI/cycle adaptation |
| INJR-01 | User can create injury profiles with body location and recovery phase | InjuryRepo needed; body map UI; `BodyLocation` union type already defined |
| INJR-02 | Injury adaptation engine auto-substitutes contraindicated exercises | `InjuryAdaptationEngine` ported; wire into workout-session and AI generation (already partial in `generateWorkout.ts`) |
| INJR-03 | User can log pain levels for active injuries | InjuryRepo pain log subresource; 1-10 slider UI |
| INJR-04 | App analyzes pain trends and surfaces insights | `PainTrendAnalyzer` ported; sparkline chart using `react-native-gifted-charts` |
| INJR-05 | Phase transition advisor suggests when to progress recovery phase | `PhaseTransitionAdvisor` ported; banner on injury profile screen |
| INJR-06 | App generates targeted rehab sessions based on injury profile | `RehabSessionGenerator` ported; wire to injury profile "Generate Rehab Session" button |
| AIWK-01 | User can generate a personalized workout via AI | Firebase Cloud Function `generateWorkout` exists; update to Gemini; build config card UI |
| AIWK-02 | AI incorporates cycle phase, injuries, and readiness | `WorkoutGenerationContext` already includes all three; function validates injuries |
| AIWK-03 | User can specify preferences (time, focus, equipment, energy level) | Horizontal card config UI; `QuestionnaireAnswers` type already defined |
| AIWK-04 | App falls back to templated workouts when offline | `generateOfflineWorkout()` in `offline-workout-generator.ts` fully ported |
| AIWK-05 | Generated workouts are saved to history | `WorkoutRepo.saveWorkout()` with source `'ai'` — already built |
| PROG-01 | User can browse program catalog from Firestore | ProgramRepo needed; Firestore `programs` collection; card grid + filter chips |
| PROG-02 | User can enroll in a program and track weekly progress | Enrollment state in Firestore; `ExerciseMaxRepo` for target weight calculation |
| PROG-03 | User can view current session with exercises, sets, and target weights | Program session detail screen; 1RM → target weight calculation using `ExerciseMaxRepo.getMaxes()` |
| PROG-04 | Programs include structured weeks, sessions, and progression schemes | Program data model; Firestore schema definition |
| BNCH-01 | User can browse benchmark catalog | `BENCHMARK_CATALOG` fully defined in `benchmark-catalog.ts`; catalog screen |
| BNCH-02 | User can record benchmark results with scoring types | BenchmarkRepo needed; scoring-aware forms (ForTime/AMRAP/MaxLoad); `encodeRoundsAndReps()` ready |
| BNCH-03 | User can view benchmark result history and track improvement | BenchmarkRepo `getResults()`; history list + chart using `react-native-gifted-charts` |
| BNCH-04 | User can create custom benchmarks | BenchmarkRepo `saveBenchmarkDefinition()`; create form |
| WODS-01 | User can view daily Workout of the Day from Firestore | WODRepo needed; Firestore `wods` collection keyed by date string |
| WODS-02 | WODs are matched by date and refreshed from Firestore | `getWODForDate(dateString)` using `yyyy-MM-dd` doc ID pattern (mirrors `ReadinessRepo`) |
</phase_requirements>

---

## Summary

Phase 5 wires the fully-ported domain layer to new repository implementations and new UI screens. The domain is already done — `CycleCalculations`, `CycleAdaptationPolicy`, `InjuryAdaptationEngine`, `PainTrendAnalyzer`, `PhaseTransitionAdvisor`, `RehabSessionGenerator`, `OfflineWorkoutGenerator`, `BenchmarkCatalog`, and `ReadinessSurvey` are all tested TypeScript in `src/domain/`. The Firebase Cloud Function `generateWorkout` already exists but uses Anthropic Claude (not Gemini) and needs to be updated per CONTEXT.md decision.

The work in this phase is: (1) five new repositories (CycleRepo, InjuryRepo, ProgramRepo, BenchmarkRepo, WODRepo) following the established `getXxxRepo(isGuest)` factory pattern, (2) two new Expo Router tabs (Cycle, Programs or Benchmarks), (3) a substantial number of new screens (AI workout generation flow, injury body map + profile, cycle calendar, program catalog + detail + enrollment, benchmark catalog + record + history, WOD display), and (4) wiring domain logic into existing screens (dashboard, workout-session).

The Firebase Cloud Function already handles auth validation, Firestore persistence, and retry logic — it needs its AI provider switched from Anthropic to Gemini. Cold start latency on Cloud Functions v2 is the main risk; minimum instances is the mitigation.

**Primary recommendation:** Implement in domain-integration waves — first the repository layer (all five repos in one wave), then the dashboard integrations (readiness, WOD, cycle banner), then dedicated tab screens (Cycle, Programs, Benchmarks), then the AI generation flow.

---

## Standard Stack

### Core (all already installed)

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `@react-native-firebase/firestore` | ^23.8.8 | All new repo backends | Already used for WorkoutRepo, ReadinessRepo |
| `@react-native-async-storage/async-storage` | 2.2.0 | Guest-mode repo backends | Already used for LocalWorkoutRepo, LocalReadinessRepo |
| `react-native-gifted-charts` | ^1.4.76 | Pain trend charts, benchmark history charts | Already installed; used in Phase 4 progress charts |
| `expo-network` | ~55.0.8 | Offline detection for AI fallback | Already installed |
| `date-fns` | ^4.1.0 | Calendar date arithmetic | Already used in `cycle-calculations.ts` |
| `expo-router` | ~55.0.5 | File-based routing for new screens/tabs | Established pattern |
| `react-native-reanimated` | 4.2.1 | Adaptation indicator animations | Already installed |
| `firebase-functions` | ^6.0.0 | Cloud Function for AI proxy | Already in `functions/` |

### Calendar Component (Claude's Discretion)

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `react-native-calendars` | ^1.1305.0 | Monthly calendar with multi-dot marking for period logs | Most mature RN calendar; supports marking, theming, and range selection |

**Recommendation: Use `react-native-calendars`.** It is the standard React Native calendar library with the widest adoption. It supports `markedDates` with `startingDay`/`endingDay` period range marking out of the box, which maps directly to period start/end log UX. It supports custom theme tokens so Art Deco cream/navy/orange palette applies cleanly.

No alternative needed — custom calendar would cost significant test surface for a solved problem.

**Installation (only new library needed):**
```bash
cd SundeeFundeeRN && npm install react-native-calendars
```

### Supporting Libraries (all already installed, relevant to this phase)

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `expo-haptics` | ~55.0.8 | Tactile feedback on body map taps | Body map region selection |
| `expo-linear-gradient` | ~55.0.8 | Cycle phase color banding | Phase timeline visualization |
| `react-native-gesture-handler` | ~2.30.0 | Swipe interactions | Body map, config cards |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `react-native-calendars` | Custom `FlatList`-based grid | Custom loses range-select, marking API, and theme support — not worth it |
| Gifted Charts (pain trend) | Victory Native | Gifted Charts already installed and used; adding Victory Native is unnecessary |
| Firebase Cloud Function | Cloudflare Worker | Decision locked: migrate to Cloud Function |

---

## Architecture Patterns

### Established Patterns (must follow)

All Phase 5 repositories follow the exact pattern of `ReadinessRepo.ts`:

```typescript
// Pattern: getXxxRepo(isGuest) factory
export function getCycleRepo(isGuest: boolean): CycleRepository {
  return isGuest ? new LocalCycleRepo() : new FirestoreCycleRepo();
}
```

Firestore doc ID pattern: use semantic IDs where possible (date string for WODs/readiness, uid-prefixed for owned data). This mirrors `ReadinessRepo` using `yyyy-MM-dd` as doc ID.

### Recommended Project Structure Additions

```
SundeeFundeeRN/
├── app/(app)/(tabs)/
│   ├── cycle.tsx              # new Cycle tab screen
│   └── programs.tsx           # new Programs tab screen (with nested screens)
├── app/(app)/
│   ├── ai-workout/
│   │   ├── config.tsx         # QuestionnaireAnswers config cards
│   │   └── preview.tsx        # Generated workout preview + Start/Regenerate
│   ├── injuries/
│   │   ├── body-map.tsx       # Body map tap to select location
│   │   ├── [id].tsx           # Injury profile: pain log, trend, rehab, transition advice
│   │   └── index.tsx          # Injury list
│   ├── programs/
│   │   ├── [id].tsx           # Program detail + enrollment
│   │   └── session.tsx        # Today's program session with target weights
│   ├── benchmarks/
│   │   ├── index.tsx          # Catalog (predefined + custom)
│   │   ├── [id].tsx           # Benchmark detail + record result + history
│   │   └── create.tsx         # Custom benchmark creation
│   └── wods/
│       └── index.tsx          # WOD archive browser
├── src/repositories/
│   ├── CycleRepo.ts           # interface + factory
│   ├── FirestoreCycleRepo.ts
│   ├── LocalCycleRepo.ts
│   ├── InjuryRepo.ts
│   ├── FirestoreInjuryRepo.ts
│   ├── LocalInjuryRepo.ts
│   ├── ProgramRepo.ts
│   ├── FirestoreProgramRepo.ts
│   ├── BenchmarkRepo.ts
│   ├── FirestoreBenchmarkRepo.ts
│   ├── LocalBenchmarkRepo.ts
│   └── WODRepo.ts             # read-only; guest gets empty (no local WODs)
└── src/components/
    ├── cycle/
    │   ├── CyclePhaseBanner.tsx   # dashboard banner + cycle tab header
    │   └── CycleCalendar.tsx      # period-log calendar wrapper
    ├── injury/
    │   ├── BodyMap.tsx            # SVG/image body diagram
    │   └── PainTrendChart.tsx     # gifted-charts sparkline
    └── ai-workout/
        └── AdaptationChip.tsx     # "Adapting for: ..." summary chip
```

### Pattern 1: Repository Factory (Established — Must Follow)

```typescript
// Source: src/repositories/ReadinessRepo.ts (existing pattern)
export interface CycleRepository {
  savePeriodLog(uid: string, log: PeriodLog): Promise<void>;
  getPeriodLogs(uid: string): Promise<PeriodLog[]>;
  saveCycleSettings(uid: string, settings: CycleSettings): Promise<void>;
  getCycleSettings(uid: string): Promise<CycleSettings | null>;
}

export function getCycleRepo(isGuest: boolean): CycleRepository {
  return isGuest ? new LocalCycleRepo() : new FirestoreCycleRepo();
}
```

### Pattern 2: useFocusEffect for Data Refresh (Established)

```typescript
// Source: app/(app)/(tabs)/index.tsx (existing pattern)
useFocusEffect(
  useCallback(() => {
    void loadData();
  }, [loadData])
);
```

All new screens that display data-store-backed content must use `useFocusEffect` for refresh, not `useEffect`. This ensures data updates when navigating back from a form.

### Pattern 3: Firestore Date-Keyed Document (Established)

```typescript
// Source: src/repositories/FirestoreReadinessRepo.ts (existing pattern)
// WODRepo and CycleRepo should use same pattern
const dateKey = format(new Date(), 'yyyy-MM-dd'); // date-fns
await firestore().collection('wods').doc(dateKey).get();
```

### Pattern 4: Cycle-Gating Feature Visibility

```typescript
// Pattern for CYCL-05: gate on profile field set during onboarding (ONBD-02)
const { user, isGuest } = useSession();
const [profile, setProfile] = useState<OnboardingProfile | null>(null);
// load profile → profile.cycleTrackingEnabled gates Cycle tab + banner
```

The Cycle tab in `_layout.tsx` must check `profile.cycleTrackingEnabled` and either hide the tab or show an opt-in prompt. Use `href: null` on the `Tabs.Screen` to hide it conditionally.

### Pattern 5: Offline Detection + Fallback

```typescript
// Use expo-network (already installed) for offline detection
import * as Network from 'expo-network';
const state = await Network.getNetworkStateAsync();
if (!state.isConnected) {
  // use generateOfflineWorkout(context) from domain layer
}
```

`generateOfflineWorkout()` is fully ported in `src/domain/ai-workout/offline-workout-generator.ts`. The AI generation screen should check connectivity before calling the Cloud Function, not after failure.

### Pattern 6: Firestore Cloud Function Call (onCall)

```typescript
// The existing generateWorkout Cloud Function uses onCall — call from RN with:
import functions from '@react-native-firebase/functions';
const fn = functions().httpsCallable('generateWorkout');
const result = await fn(workoutContext);
```

Auth is enforced server-side (`request.auth` check). The client just passes the `WorkoutGenerationContext` payload.

### Anti-Patterns to Avoid

- **Symptom logging as separate feature:** CYCL-02 (daily symptoms) is covered by READ-01 (readiness survey) per locked decision. Do not build a separate symptom tracking module.
- **Inline Gemini calls from the client:** All AI calls go through the Cloud Function. Never call Gemini directly from the app.
- **Fetching all WODs then filtering on client:** WODRepo fetches a single document by date string doc ID — O(1) Firestore read, not a collection scan.
- **Blocking workout session start on cycle data:** Cycle data loads async; injury adaptation should not block the workout session if data is unavailable — degrade gracefully with no adaptation.
- **Enum types for Firestore-stored data:** All stored types use string unions (established in Phase 2 decisions). `RecoveryPhase`, `CyclePhase`, `BodyLocation` are already string unions.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Monthly calendar with period range marking | Custom grid | `react-native-calendars` | Range selection, theming, accessibility — built-in |
| Pain trend sparkline | Custom SVG path | `react-native-gifted-charts` LineChart | Already installed; handles scaling, axes, touch |
| Offline connectivity check | Fetch-then-catch | `expo-network` `getNetworkStateAsync()` | Installed; handles platform differences, airplane mode |
| Cycle phase color coding | Custom phase→color map | Use theme token approach + phase constants | `getPhaseRecommendation()` already returns display info |
| AI workout JSON parsing | Custom JSON parser | Use `JSON.parse()` + Cloud Function validation | `validateWorkout()` already handles malformed responses with retry |
| RoundsAndReps score display | Custom encoding | `decodeRoundsAndReps()` in `benchmark-catalog.ts` | Already ported and tested |

**Key insight:** The domain layer is the most complex part of this phase — it's already done. The remaining work is 90% repository + UI plumbing. Do not re-implement business logic that already exists in `src/domain/`.

---

## Common Pitfalls

### Pitfall 1: Cloud Function Cold Start Latency (Flagged in STATE.md)
**What goes wrong:** Firebase Cloud Functions v2 cold starts can add 2-5 seconds to the first AI workout generation request, especially after periods of inactivity.
**Why it happens:** Container initialization time for Node.js 20 runtime with dependencies.
**How to avoid:** Set `minInstances: 1` on the `generateWorkout` function definition. This costs ~$5/month in idle compute but eliminates cold starts entirely for an active app. Alternatively, show a loading skeleton immediately on the preview screen so perceived latency is acceptable.
**Warning signs:** Users reporting "spinning forever" on first AI generation of the day.

```typescript
// functions/src/generateWorkout.ts
export const generateWorkout = onCall(
  {
    minInstances: 1, // add this
    memory: "256MiB",
    timeoutSeconds: 60,
  },
  async (request) => { ... }
);
```

### Pitfall 2: Cycle Tab Hidden for Non-Opted-In Users
**What goes wrong:** Expo Router renders all `Tabs.Screen` entries by default. If the Cycle tab always renders, non-cycle users see it.
**Why it happens:** Expo Router doesn't support conditional tabs without explicit configuration.
**How to avoid:** Use `href: null` to hide the tab for non-opted-in users. Still define the screen so deep links work — just hide the tab bar entry.

```tsx
<Tabs.Screen
  name="cycle"
  options={{
    href: profile?.cycleTrackingEnabled ? undefined : null,
    title: 'Cycle',
    tabBarIcon: ...,
  }}
/>
```

### Pitfall 3: 1RM Target Weight Showing Wrong Units
**What goes wrong:** `ExerciseMaxRepo` stores weights in the user's preferred unit, but program target weights may be defined in lbs in Firestore.
**Why it happens:** Unit conversion needs to happen at display time using the user's settings.
**How to avoid:** Normalize all weights to lbs in Firestore. Convert to display unit using settings at the UI layer only — same pattern as workout-session screen.

### Pitfall 4: WOD Date Timezone Mismatch
**What goes wrong:** A WOD keyed `2026-03-15` in UTC may show yesterday's WOD for users in UTC+N timezones after midnight local time.
**Why it happens:** `new Date().toISOString().slice(0, 10)` produces UTC date, not local date.
**How to avoid:** Use `date-fns` `format(new Date(), 'yyyy-MM-dd')` which uses local time. Consistent with the `ReadinessRepo` pattern already established.

### Pitfall 5: Injury Profile Missing `userID` Thread
**What goes wrong:** Injury records saved without `userID` cause data access failures for authenticated users syncing across devices.
**Why it happens:** Forgetting to thread `userID` through new repo write operations — flagged in CLAUDE.md.
**How to avoid:** Every `InjuryRepo.saveInjury(uid, injury)` call uses `appState.currentUserID ?? ""` at the call site. Never hardcode empty strings.

### Pitfall 6: `export *` Barrel Collision on New Domain Exports
**What goes wrong:** Adding new barrel re-exports for cycle/injury/AI causes `TypeError: Cannot redefine property` if two modules export the same name.
**Why it happens:** Phase 2 decision: use explicit named re-exports with aliases, not `export * from`.
**How to avoid:** Follow established pattern — explicit named re-exports in barrel `index.ts` files.

### Pitfall 7: AI Workout Saved Before User Starts It
**What goes wrong:** If the workout is saved to history at generation time (not at start/completion time), abandoned previews pollute history.
**Why it happens:** Temptation to save immediately on Cloud Function return to avoid losing data.
**How to avoid:** Save to history only when user taps "Start Workout" on the preview screen (i.e., when `WorkoutRepo.saveWorkout()` is called with `source: 'ai'`). The Cloud Function already saves to `generatedWorkouts` collection for its own audit trail — that's separate from workout history.

---

## Code Examples

### Firestore Cycle Repository (Inferred from ReadinessRepo Pattern)

```typescript
// Source: src/repositories/FirestoreReadinessRepo.ts pattern — apply to CycleRepo
import firestore from '@react-native-firebase/firestore';
import type { CycleRepository } from './CycleRepo';
import type { PeriodLog, CycleSettings } from '../domain/types';

export class FirestoreCycleRepo implements CycleRepository {
  async savePeriodLog(uid: string, log: PeriodLog): Promise<void> {
    await firestore()
      .collection('users')
      .doc(uid)
      .collection('periodLogs')
      .doc(log.id)
      .set(log);
  }

  async getPeriodLogs(uid: string): Promise<PeriodLog[]> {
    const snap = await firestore()
      .collection('users')
      .doc(uid)
      .collection('periodLogs')
      .orderBy('startDate', 'desc')
      .get();
    return snap.docs.map(d => d.data() as PeriodLog);
  }
}
```

### Firestore WOD Repository (Read-Only, Date-Keyed)

```typescript
// Source: Established pattern — ReadinessRepo uses date string as doc ID
import { format } from 'date-fns';
import firestore from '@react-native-firebase/firestore';

export class FirestoreWODRepo {
  async getWODForDate(date: Date): Promise<WODRecord | null> {
    const dateKey = format(date, 'yyyy-MM-dd'); // local time
    const doc = await firestore().collection('wods').doc(dateKey).get();
    return doc.exists ? (doc.data() as WODRecord) : null;
  }
}
```

### Cycle Phase Banner (Dashboard Integration)

```typescript
// Source: calculateCycleStatus from src/domain/cycle/cycle-calculations.ts
import { calculateCycleStatus } from '@/src/domain/cycle/cycle-calculations';

// In dashboard component, after loading period logs and settings:
const status = calculateCycleStatus(periodLogs, cycleSettings);
// status.currentPhase → 'follicular' | 'menstrual' | 'ovulation' | 'luteal'
// status.cycleDay → number (e.g., 8)
// Display: "Follicular — Day 8"
```

### AI Workout — Switch to Gemini in Cloud Function

```typescript
// Current: functions/src/generateWorkout.ts uses Anthropic SDK
// Required change: replace Anthropic with @google/generative-ai (Gemini)
// Per CONTEXT.md: use Gemini proxy via Cloud Function (replaces Cloudflare Worker)
// Per MEMORY.md: Worker used Gemini native format (contents/systemInstruction/generationConfig)

import { GoogleGenerativeAI } from "@google/generative-ai";
const GEMINI_API_KEY = defineSecret("GEMINI_API_KEY");

const genAI = new GoogleGenerativeAI(GEMINI_API_KEY.value());
const model = genAI.getGenerativeModel({ model: "gemini-1.5-flash" });
const result = await model.generateContent(prompt);
const text = result.response.text();
workoutData = JSON.parse(text);
```

Note: `@google/generative-ai` must be added to `functions/package.json`. The Anthropic SDK can be removed once migrated.

### Benchmark Recording — Scoring-Aware Input

```typescript
// Source: src/domain/benchmarks/benchmark-catalog.ts
// BenchmarkDefinition.scoringType: 'time' | 'reps' | 'weight' | 'distance'
// encodeRoundsAndReps(rounds, reps) → single number for AMRAP scores

switch (benchmark.scoringType) {
  case 'time':
    return <ForTimeInput onSave={(seconds) => handleSave(seconds)} />;
  case 'reps':
    // AMRAP: show rounds + partial reps inputs
    return <AMRAPInput onSave={(rounds, reps) =>
      handleSave(encodeRoundsAndReps(rounds, reps))
    } />;
  case 'weight':
    return <WeightInput onSave={(lbs) => handleSave(lbs)} />;
}
```

### Adaptation Indicator (Inline on Workout Set)

```typescript
// The adaptation indicator shows the adjustment delta on an exercise set
// CycleAdaptationPolicy returns a multiplier; the UI converts to a percentage change
const adaptedWeight = baseWeight * multiplier;
const delta = Math.round((multiplier - 1) * 100);
const label = delta > 0 ? `↑ ${delta}%` : `↓ ${Math.abs(delta)}%`;
// Only show if multiplier !== 1.0
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Cloudflare Worker (Gemini proxy) | Firebase Cloud Function (Gemini proxy) | Phase 5 (this phase) | Single auth surface; no separate Workers account; onCall handles Firebase Auth automatically |
| Anthropic Claude in Cloud Function | Gemini in Cloud Function | Phase 5 (this phase) | Matches memory decisions; function already exists, just needs provider swap |
| iOS Swift SwiftData for health data | Firestore subcollections per user | Rewrite decision | Uniform auth model; cross-platform sync |

**Deprecated/outdated:**
- Cloudflare Worker URL `workout-proxy.sundeefundee.workers.dev/generate-workout`: replaced by Firebase Cloud Function. Can be decommissioned after Phase 5.
- `@anthropic-ai/sdk` in `functions/package.json`: replace with `@google/generative-ai` when Gemini migration is complete.

---

## Open Questions

1. **Gemini model name for production**
   - What we know: MEMORY.md says `gemini-3.1-flash-lite-preview` was used in the Cloudflare Worker
   - What's unclear: Whether `gemini-3.1-flash-lite-preview` is available in the `@google/generative-ai` SDK, or if the model name has changed
   - Recommendation: Use `gemini-1.5-flash` as a safe stable model; check Google AI Studio for model availability during implementation. The preview model name may no longer be valid.

2. **Program data schema in Firestore**
   - What we know: `PROG-04` requires structured weeks, sessions, and progression schemes; no existing Firestore schema defined
   - What's unclear: Whether programs are admin-seeded (like WODs) or user-created. REQUIREMENTS.md says "browse from Firestore" suggesting admin-seeded.
   - Recommendation: Define schema in plan as admin-seeded `programs` collection with top-level program docs containing `weeks[]` → `sessions[]` → `exercises[]` subcollection or nested array. Mirror the approach that `programs.json` was used for in the Swift app.

3. **Local (guest) WOD behavior**
   - What we know: WODs come from Firestore; guest mode uses AsyncStorage for other repos
   - What's unclear: Should guest users see WODs (read-only public data) or see nothing?
   - Recommendation: Guest users can see WODs — they're public data, no auth required for Firestore reads if security rules permit. `WODRepo` for guests can still use Firestore directly (no write needed). Security rules must allow unauthenticated reads on the `wods` collection.

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | jest-expo (jest) |
| Config file | `SundeeFundeeRN/jest.config.js` |
| Quick run command | `cd SundeeFundeeRN && npx jest src/domain/__tests__ --testPathPattern=cycle\|injury\|ai-workout\|benchmarks --no-coverage` |
| Full suite command | `cd SundeeFundeeRN && npx jest --coverage` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| CYCL-01 | Period log save/retrieve round-trip | unit | `npx jest src/repositories/__tests__/CycleRepo.test.ts -x` | ❌ Wave 0 |
| CYCL-03 | `calculateCycleStatus()` infers correct phase | unit | `npx jest src/domain/__tests__/cycle.test.ts -x` | ✅ |
| CYCL-04 | `getPhaseBoundaries()` generates 2-cycle forecast | unit | `npx jest src/domain/__tests__/cycle.test.ts -x` | ✅ |
| CYCL-05 | Cycle tab hidden when `cycleTrackingEnabled: false` | unit | `npx jest src/components/__tests__/CyclePhaseBanner.test.tsx -x` | ❌ Wave 0 |
| CYAD-01 | Adaptation multiplier applied to exercise weights | unit | `npx jest src/domain/__tests__/cycle.test.ts -x` | ✅ |
| CYAD-03 | Readiness blends with cycle multiplier | unit | `npx jest src/domain/__tests__/cycle.test.ts -x` | ✅ |
| READ-01 | Readiness survey score calculation | unit | `npx jest src/domain/__tests__/cycle.test.ts -x` | ✅ (readiness tested in cycle suite) |
| INJR-01 | Injury profile save/retrieve | unit | `npx jest src/repositories/__tests__/InjuryRepo.test.ts -x` | ❌ Wave 0 |
| INJR-02 | Injury adaptation substitutes contraindicated exercises | unit | `npx jest src/domain/__tests__/injury.test.ts -x` | ✅ |
| INJR-04 | Pain trend analyzer identifies worsening trend | unit | `npx jest src/domain/__tests__/injury.test.ts -x` | ✅ |
| INJR-05 | Phase transition advisor suggests progression | unit | `npx jest src/domain/__tests__/injury.test.ts -x` | ✅ |
| INJR-06 | Rehab session generator produces valid session | unit | `npx jest src/domain/__tests__/injury.test.ts -x` | ✅ |
| AIWK-04 | `generateOfflineWorkout()` respects injuries + energy | unit | `npx jest src/domain/__tests__/ai-workout.test.ts -x` | ✅ |
| AIWK-05 | AI workout saved with source `'ai'` | unit | `npx jest src/repositories/__tests__/FirestoreWorkoutRepo.test.ts -x` | ✅ |
| BNCH-01 | Benchmark catalog contains expected entries | unit | `npx jest src/domain/__tests__/benchmarks.test.ts -x` | ❌ Wave 0 |
| BNCH-02 | `encodeRoundsAndReps` + `decodeRoundsAndReps` round-trip | unit | `npx jest src/domain/__tests__/benchmarks.test.ts -x` | ❌ Wave 0 |
| WODS-01 | WODRepo returns record for today's date | unit | `npx jest src/repositories/__tests__/WODRepo.test.ts -x` | ❌ Wave 0 |
| PROG-01 | ProgramRepo `getPrograms()` returns list | unit | `npx jest src/repositories/__tests__/ProgramRepo.test.ts -x` | ❌ Wave 0 |

### Sampling Rate

- **Per task commit:** `cd SundeeFundeeRN && npx jest src/domain/__tests__ src/repositories/__tests__ --no-coverage`
- **Per wave merge:** `cd SundeeFundeeRN && npx jest --coverage`
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps

- [ ] `SundeeFundeeRN/src/repositories/__tests__/CycleRepo.test.ts` — covers CYCL-01
- [ ] `SundeeFundeeRN/src/repositories/__tests__/InjuryRepo.test.ts` — covers INJR-01, INJR-03
- [ ] `SundeeFundeeRN/src/repositories/__tests__/BenchmarkRepo.test.ts` — covers BNCH-01 through BNCH-04
- [ ] `SundeeFundeeRN/src/repositories/__tests__/WODRepo.test.ts` — covers WODS-01, WODS-02
- [ ] `SundeeFundeeRN/src/repositories/__tests__/ProgramRepo.test.ts` — covers PROG-01 through PROG-04
- [ ] `SundeeFundeeRN/src/domain/__tests__/benchmarks.test.ts` — covers benchmark catalog + encode/decode
- [ ] `SundeeFundeeRN/src/components/__tests__/CyclePhaseBanner.test.tsx` — covers CYCL-05 gating

---

## Cross-Researcher Findings (Gemini + Qwen)

Additional insights gathered from parallel Gemini and Qwen research sessions:

### Body Map Component
- **`react-native-body-highlighter`** (Gemini): Built on `react-native-svg`, provides front/back interactive body diagram with region IDs that map to `BodyLocation` type. Viable alternative to raw SVG paths.
- **Custom SVG with `react-native-svg`** (Qwen): Use `Path` + `Pressable` regions with hit detection. More customizable but more implementation effort. Both approaches are valid — planner should choose based on design fidelity needs.

### Firestore Schema Patterns (Qwen)
- **Pain logs: hybrid embedded + subcollection** — Embed last 7 days in `InjuryProfile` for quick UI access, full history in `painLogs` subcollection for trend analysis. Avoids extra read for common case.
- **Programs: denormalized** — Nest `weeks[] → sessions[] → exercises[]` inside program doc for single-read catalog browsing. Programs are admin-seeded, read-heavy — denormalization is appropriate.
- **Benchmarks: user results in user subcollection** — `/users/{uid}/benchmarkResults/{resultId}` with denormalized `benchmarkName` and `scoringType` for display without join.
- **Security rules additions:** Programs and WODs `allow read: if request.auth != null; allow write: if false;` (admin-only writes via console/CLI).

### Cloud Function Enhancements (Qwen)
- **Rate limiting per user** — Track requests in `rateLimits` collection, cap at 10/hour per user. Prevents abuse of AI generation endpoint.
- **`responseMimeType: "application/json"`** — Gemini supports native JSON mode in `generationConfig`, eliminating need for response parsing/validation.
- **Concurrency setting** — `concurrency: 80` allows single instance to handle 80 concurrent requests, maximizing `minInstances: 1` efficiency.

### Offline Program Catalog (Qwen)
- **Bundle top 5 programs** as static JSON for offline/guest access, similar to existing `exercises.json` pattern. Firestore programs serve as live catalog with TTL-based cache refresh.

### Navigation (Both)
- **Expo Router `href: null`** confirmed by both researchers as the correct approach for conditional Cycle tab visibility.
- **Deep linking scheme** `sundeefundee://` should be configured in `app.json` for program/benchmark/WOD deep links.

### Calendar Theming (Gemini)
- `react-native-calendars` supports `markingType={'period'}` with `startingDay`/`endingDay` for range visualization — maps directly to period start/end dates without custom logic.

---

## Sources

### Primary (HIGH confidence)

- Direct code inspection: `src/domain/cycle/cycle-calculations.ts` — phase inference functions confirmed working
- Direct code inspection: `src/domain/injury/` — full injury domain confirmed ported
- Direct code inspection: `src/domain/ai-workout/` — `generateOfflineWorkout()` fully functional
- Direct code inspection: `src/domain/benchmarks/benchmark-catalog.ts` — catalog + encode/decode confirmed
- Direct code inspection: `src/domain/readiness/readiness-survey.ts` — scoring functions confirmed
- Direct code inspection: `src/repositories/ReadinessRepo.ts` — established factory pattern confirmed
- Direct code inspection: `functions/src/generateWorkout.ts` — onCall Cloud Function confirmed (uses Anthropic, needs Gemini swap)
- Direct code inspection: `SundeeFundeeRN/package.json` — all dependencies confirmed present except `react-native-calendars`
- Direct code inspection: `app/(app)/(tabs)/_layout.tsx` — current tab structure (4 tabs) confirmed

### Secondary (MEDIUM confidence)

- `react-native-calendars`: well-known community standard library; verified it supports `markedDates` with period range marking from npm package README patterns
- Expo Router `href: null` for conditional tab hiding: documented in Expo Router v3+ docs for hiding tabs

### Tertiary (LOW confidence)

- Gemini model name `gemini-1.5-flash` as stable replacement for `gemini-3.1-flash-lite-preview`: based on Google AI Studio knowledge as of August 2025. Model availability should be verified at implementation time.
- Firebase Cloud Functions v2 `minInstances: 1` pricing estimate ($5/month): approximation from Cloud Functions pricing knowledge; verify current pricing.

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all libraries confirmed in `package.json` except `react-native-calendars` (one new install)
- Architecture: HIGH — all patterns confirmed from existing code; five new repos follow identical pattern to three existing
- Pitfalls: HIGH for cold start, timezone, unit threading (confirmed from STATE.md/CLAUDE.md); MEDIUM for `href: null` tab hiding (needs Expo Router version confirmation)
- AI migration: MEDIUM — function exists, provider swap is clear, model name needs verification

**Research date:** 2026-03-15
**Valid until:** 2026-04-15 (stable ecosystem; Gemini model name may shift sooner)
