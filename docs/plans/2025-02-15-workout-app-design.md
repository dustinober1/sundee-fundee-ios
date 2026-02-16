# Workout Tracking App Design

**Date:** 2025-02-15
**Status:** Approved
**Tech Stack:** Next.js + React + shadcn/ui + TypeScript + Dexie.js + Supabase

---

## Goal

Build a mobile-first web application where users can browse workout programs, start training cycles, log workouts with comprehensive data tracking, and receive personalized recommendations. The app works offline (local-first) with optional cloud sync for backup and cross-device access.

---

## MVP Scope

**Full MVP (Option C) - Complete first release:**
- ✅ All 6 programs: back squat, front squat, bench press, deadlift, box jump, burpees
- ✅ Multiple cycles per program (8 weeks, 3 days/week)
- ✅ Comprehensive onboarding (name, experience, goals)
- ✅ Rich dashboard (active cycles, today's workout, activity, PRs, recommendations)
- ✅ Rule-based recommendations (plateau detection, PR celebrations, missed workout reminders)
- ✅ Local-first with optional Supabase sync
- ✅ % of 1RM-based intensity calculations

---

## Architecture

**Local-first, sync-later pattern:**

```
UI Layer (shadcn/ui + Tailwind CSS)
  ↓ Onboarding, Dashboard, Workout Log, Program Browser
State Layer (React Context + Hooks)
  ↓ ActiveContext, UserContext, WorkoutContext
Data Layer (Dexie.js - IndexedDB)
  ↓ Completed workouts, sets, reps, 1RMs, cycle progress
Sync Layer (Supabase)
  ↓ Auth, cloud backup, cross-device sync
```

**Static data bundled with app:**
- Program definitions (`src/data/programs/*.json`)
- Exercise database (`src/data/exercises.ts`)
- Recommendation rules (`src/lib/recommendations/`)

---

## Data Model

### IndexedDB Schema (Dexie.js)

```typescript
// Users
interface User {
  id: string;                    // UUID
  name: string;
  experienceLevel: 'beginner' | 'intermediate' | 'advanced';
  primaryGoal: 'strength' | 'hypertrophy' | 'explosiveness';
  createdAt: Date;
  syncedAt?: Date;
}

// One-rep max tracking
interface OneRepMax {
  id: string;
  userId: string;
  exerciseId: string;            // 'back-squat', 'bench-press', etc.
  weight: number;                // lbs
  date: Date;
}

// Active training cycles
interface ActiveCycle {
  id: string;
  userId: string;
  programId: string;             // 'back-squat-5x5-linear'
  cycleName: string;
  startDate: Date;
  currentWeek: number;           // 1-8
  status: 'active' | 'completed' | 'paused';
}

// Completed workouts
interface CompletedWorkout {
  id: string;
  userId: string;
  activeCycleId: string;
  programId: string;
  week: number;
  day: number;                   // 1-3
  completedAt: Date;
  duration?: number;             // minutes
  notes?: string;
}

// Individual sets logged
interface CompletedSet {
  id: string;
  workoutId: string;
  exerciseId: string;
  setNumber: number;
  prescribedWeight?: number;
  actualWeight: number;
  prescribedReps: number;
  actualReps: number;
  rpe?: number;                  // 1-10
  restSeconds?: number;
}

// Optional enhanced metrics
interface SetMetrics {
  id: string;
  setId: string;
  tempoEccentric?: number;
  tempoConcentric?: number;
  tempoPause?: number;
  heartRate?: number;
  notes?: string;
}
```

### Static Program Data (JSON)

```typescript
interface Program {
  id: string;
  name: string;
  category: ProgramCategory;
  description: string;
  durationWeeks: number;
  daysPerWeek: number;
  exercises: string[];
  difficulty: 'beginner' | 'intermediate' | 'advanced';
  weeks: Week[];
}

interface Week {
  week: number;
  days: Day[];
}

interface Day {
  day: number;
  exercises: Exercise[];
}

interface Exercise {
  exercise: string;
  sets: number;
  reps: number;
  percent1RM: number;
  restMinutes?: number;
  rpeTarget?: number;
}
```

---

## User Flows

### 1. First-Time User
1. Opens app → onboarding wizard
2. Enters name, experience level, primary goal
3. Browses programs by lift category
4. Selects program → views available cycles
5. Starts cycle → enters current 1RM and start date
6. Lands on dashboard with active cycle

### 2. Logging a Workout
1. Opens app → dashboard shows today's workout (if scheduled)
2. Taps workout → sees exercises with prescribed weights
3. Logs each set (weight, reps, optional RPE/rest)
4. Completes workout → data saved to IndexedDB
5. Triggers recommendations (plateau check, PR celebration)
6. Background sync to Supabase (if logged in)

### 3. Sync Flow (Optional)
1. User signs up/logs in with Supabase
2. App pushes local data to cloud
3. Pulls any changes from other devices
4. Merges with conflict resolution (last write wins)
5. Updates local IndexedDB and sync timestamp

---

## UI Components & Navigation

### Routes
```
/                          → Onboarding or Dashboard
/onboarding                → Multi-step wizard
/dashboard                 → Main dashboard
/programs                  → Browse all programs
/programs/[category]       → Programs by lift
/programs/[id]             → Program detail
/programs/[id]/cycles      → Available cycles
/cycles/[id]/start         → Start cycle (enter 1RM)
/workout/[id]              → Active workout logger
/history                   → Workout history
/history/[workoutId]       → Workout detail
/progress                  → Charts, stats
/settings                  → Settings, sync, account
```

### Key Screens
- **Onboarding**: Multi-step wizard (name, experience, goals)
- **Dashboard**: Stacked cards (active cycles, today's workout, recent activity, recommendations)
- **Program Browser**: Grid with category filters
- **Workout Logger**: Single-column, large touch targets, sticky "Complete" button
- **Progress View**: Charts (Recharts/Chart.js), filterable by date range

### Mobile UX Considerations
- Thumb zone: Primary actions in bottom 1/3
- Single-handed use: No stretch required for critical flows
- Offline indicator: Subtle badge
- Skeleton screens: Placeholder UI during loads

---

## State Management (React Context)

```typescript
// ActiveContext - current training
const ActiveContext = {
  activeCycles: ActiveCycle[],
  currentWorkout: Workout | null,
  refresh: () => Promise<void>
};

// UserContext - profile and settings
const UserContext = {
  user: User | null,
  oneRepMaxes: OneRepMax[],
  update1RM: (exerciseId, weight) => Promise<void>,
  syncStatus: 'synced' | 'syncing' | 'offline'
};

// ExerciseContext - static program data
const ExerciseContext = {
  programs: Program[],
  getProgram: (id) => Program,
  calculateTargetWeight: (exercise, week, oneRepMax) => number
};
```

---

## Error Handling

### Critical (IndexedDB)
- **Quota exceeded**: Show error, free space option, sessionStorage fallback
- **Transaction conflict**: Retry with exponential backoff

### Non-blocking (Sync)
- **Network unavailable**: Queue for later retry, subtle 'pending' indicator
- **Auth expired**: Auto-refresh token, retry failed syncs
- **Conflicts**: Last write wins by timestamp, merge complementary data

### Validation
- **1RM input**: Positive weight, sanity check by exercise
- **Workout completion**: All sets logged before allowing complete

### Edge Cases
- **1RM changed mid-cycle**: Ask to recalculate remaining workouts
- **Missed workout**: Skip/shift schedule/mark as rest day
- **Program update**: Notify active cycle users, offer continue/switch
- **Data loss**: Offer restore from Supabase backup if available

---

## Testing Strategy

### Test Stack
- **Unit**: Vitest (70% - business logic, calculations, data layer)
- **Integration**: Vitest + React Testing Library (20% - contexts, components)
- **E2E**: Playwright (10% - critical flows, mobile viewport)

### Coverage Priorities
- ✅ Critical flows: onboarding, starting cycles, logging workouts
- ✅ Business logic: recommendations, 1RM calculations, plateau detection
- ✅ Data persistence: all IndexedDB operations
- ✅ Edge cases: network failures, quota errors, sync conflicts

### Test Organization
```
tests/
  unit/
    recommendations/plateau-detection.test.ts
    calculations.test.ts
  integration/
    workout-logger.test.tsx
  e2e/
    onboarding.spec.ts
    workout-logging.spec.ts
```

---

## Project Structure

```
src/
  app/                          # Next.js App Router pages
  components/                   # Reusable UI
    ui/                         # shadcn/ui components
    dashboard/                  # Dashboard widgets
    workout/                    # Workout logger components
    layout/                     # Navigation, header
  lib/                          # Business logic
    db/                         # Dexie.js setup, schema
    supabase/                   # Supabase client, auth, sync
    recommendations/            # Plateau detection, PR logic
    calculations.ts             # 1RM, target weight
  contexts/                     # React Context providers
  hooks/                        # Custom hooks
  data/                         # Static data
    programs/*.json             # Program definitions
    exercises.ts                # Exercise metadata
  types/                        # TypeScript types
```

---

## Implementation Approach

**JSON-based programs with React Context:**
- Programs stored as JSON files in codebase
- Loaded at build time, bundled with app
- Simple architecture, easy to maintain
- Future migration path to database if needed

**Tech Stack:**
- Next.js 15+ with App Router
- React 19+
- TypeScript
- shadcn/ui + Tailwind CSS
- Dexie.js (IndexedDB)
- Supabase (auth + sync)
- Vitest (testing)
- Playwright (E2E)

---

## Next Steps

This design is approved and ready for implementation planning.

**Use `superpowers:writing-plans` to create the detailed implementation plan.**

The plan will break this into bite-sized tasks following TDD principles with:
- Exact file paths for each change
- Complete code snippets (not "add validation")
- Test-first approach for each feature
- Atomic commits with clear messages
- Deployment to Vercel when complete

---

## Decision Log

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Platform | Mobile-first web app | Broad accessibility, single codebase |
| Auth | Optional sync, local-first | Immediate access, backup for serious users |
| Tech stack | Next.js + shadcn/ui | Modern, great DX, strong ecosystem |
| Data storage | IndexedDB via Dexie.js | Offline-first, robust, cross-browser |
| Backend | Supabase | PostgreSQL + auth + sync, generous free tier |
| Programs | JSON-based | Simple, version-controlled, fast loads |
| State | React Context | Sufficient complexity, avoids over-engineering |
| Recommendations | Rule-based (start) | MVP-friendly, extensible to ML later |
| MVP scope | Full (Option C) | Complete first user experience |
