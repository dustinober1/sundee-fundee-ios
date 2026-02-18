# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Strength** is a mobile-first workout tracking web application with offline-first architecture. The app allows users to browse workout programs, start training cycles, log workouts with comprehensive data tracking, and receive personalized recommendations.

**Current Status:** Implementation in progress. Tasks 1-15 complete (all core features implemented). Remaining: recommendations, progress charts, Supabase, E2E tests, deployment. See [docs/plans/2025-02-15-workout-app-implementation.md](docs/plans/2025-02-15-workout-app-implementation.md) for the complete roadmap.

## Tech Stack

- **Framework:** Next.js 16 with App Router
- **UI:** React 19 + shadcn/ui + Tailwind CSS + Framer Motion for animations
- **Language:** TypeScript
- **Local Storage:** Dexie.js (IndexedDB wrapper)
- **Backend/Sync:** Supabase (optional, for backup and cross-device sync)
- **Testing:** Vitest (unit/integration), Playwright (E2E)
- **Charts:** Recharts
- **Animations:** Framer Motion, custom animation components
- **Fonts:** Geist

## Development Commands

```bash
# Install dependencies
npm install

# Development server
npm run dev

# Run tests
npm run test:run          # Unit tests
npm run test:e2e          # E2E tests

# Build
npm run build

# Production preview
npm run start

# Lint
npm run lint
```

## Environment Setup

Copy `.env.local.example` to `.env.local` for development:

```bash
cp .env.local.example .env.local
```

Required environment variables:
- `NEXT_PUBLIC_SUPABASE_URL`: Supabase project URL
- `NEXT_PUBLIC_SUPABASE_ANON_KEY`: Supabase anonymous key

## Key Architecture Principles

### Local-First, Sync-Later Pattern
The app follows a local-first architecture:
1. **Primary data store:** IndexedDB via Dexie.js (works offline)
2. **User data:** Users, active cycles, completed workouts, sets, 1RMs stored locally
3. **Static data:** Program definitions bundled as JSON in the app
4. **Optional sync:** Supabase for cloud backup and cross-device synchronization

### Data Layer Structure
```
UI Layer (shadcn/ui components + Framer Motion animations)
  ↓
State Layer (React Context - UserContext, ExerciseContext, RestTimerContext)
  ↓
Data Layer (Dexie.js - IndexedDB)
  ↓
Sync Layer (Supabase - optional)
```

### Static Data Organization
- **Program definitions:** [src/data/programs/*.json](src/data/programs/) - 8-week programs with exercises, sets, reps, %1RM
- **Exercise metadata:** [src/data/exercises.ts](src/data/exercises.ts)
- **Recommendation rules:** [src/lib/recommendations/](src/lib/recommendations/)

## Database Schema

IndexedDB tables via Dexie.js (defined in [src/lib/db/dexie.ts](src/lib/db/dexie.ts)):
- `users` - User profiles (`id`, `name`, `createdAt`)
- `oneRepMaxes` - 1RM tracking per exercise (`id`, `userId`, `exerciseId`, `date`)
- `activeCycles` - Active training programs (`id`, `userId`, `programId`, `status`)
- `completedWorkouts` - Completed workout sessions (`id`, `userId`, `activeCycleId`, `completedAt`)
- `completedSets` - Individual set logs (`id`, `workoutId`, `exerciseId`)
- `setMetrics` - Optional enhanced metrics (tempo, heart rate) (`id`, `setId`)

## Testing Strategy

- **Unit tests (70%):** Business logic, calculations, data layer operations
  - Location: `tests/unit/`
  - Framework: Vitest with fake-indexeddb
  - Setup: `tests/setup.ts` must include `import 'fake-indexeddb/auto'` for Dexie tests
- **Integration tests (20%):** React contexts, component interactions
  - Location: `tests/integration/`
  - Framework: Vitest + React Testing Library
- **E2E tests (10%):** Critical user flows
  - Location: `tests/e2e/`
  - Framework: Playwright with mobile viewport (iPhone 13)

## Important Implementation Notes

### shadcn/ui Setup
When running `npx shadcn@latest init`, it overwrites `src/lib/utils.ts`. Re-add any custom utility functions (like `roundToNearestFive`, `generateId`) after initialization.

### Type Definitions
Core types are defined in [src/types/](src/types/):
- `program.ts` - Program, Exercise, Week, Day, ProgramCategory, DifficultyLevel
- `workout.ts` - CompletedSet, CompletedWorkout, OneRepMax, ActiveCycle
- `user.ts` - User, ExperienceLevel, PrimaryGoal, SyncStatus

### Program Data Format
Programs are stored as JSON with this structure:
```json
{
  "id": "back-squat-5x5-linear",
  "name": "Back Squat: 5x5 Linear Progression",
  "category": "back-squat",
  "durationWeeks": 8,
  "daysPerWeek": 3,
  "difficulty": "intermediate",
  "weeks": [
    {
      "week": 1,
      "days": [
        {
          "day": 1,
          "exercises": [
            {
              "exercise": "back-squat",
              "sets": 5,
              "reps": 5,
              "percent1RM": 0.65,
              "restMinutes": 3
            }
          ]
        }
      ]
    }
  ]
}
```

### Calculation Utilities
Key calculations in [src/lib/calculations.ts](src/lib/calculations.ts):
- `calculateTargetWeight(oneRepMax, percentage)` - Returns weight rounded to nearest 5 lbs
- `isPersonalRecord(weight, previousMax)` - PR detection
- `calculateVolumeLoad(weight, reps, sets)` - Volume calculation
- `detectPlateau(weights[])` - Plateau detection (3+ workouts with <5 lbs variance)

## Animation System

The app uses a sophisticated animation system:
- Custom animation components in [src/components/animations/](src/components/animations/)
- Page transitions, fade-ins, scale buttons, staggered lists
- Framer Motion for complex animations
- Global smooth scrolling enabled

## Mobile-First UX Considerations

- **Thumb zone:** Primary actions in bottom 1/3 of screen
- **Single-handed use:** No stretch required for critical flows
- **Bottom navigation:** Fixed bottom nav with Dashboard, Programs, Workout, Progress
- **Touch targets:** Minimum 44px for interactive elements
- **Offline indicator:** Subtle badge when offline
- **Confetti celebrations:** Triggered on workout completion and PR achievements

## State Management with React Context

Three main contexts (in [src/contexts/](src/contexts/)):

### Testing Contexts
Use wrapper pattern with ReactNode typing:
```tsx
const wrapper = ({ children }: { children: ReactNode }) => (
  <UserProvider>{children}</UserProvider>
);
renderHook(() => useUser(), { wrapper });
```

1. **UserContext** - User profile, 1RMs, sync status
   - `user`, `oneRepMaxes`, `syncStatus`
   - `updateUserProfile()`, `update1RM()`, `refresh()`

2. **ExerciseContext** - Static program data
   - `programs`, `getProgram()`, `getWeek()`, `getDay()`
   - `calculatePrescribedWeight()`

3. **RestTimerContext** - Workout rest timer functionality
   - Controls rest timers during workouts
   - Manages timer state and settings

## Key Routes

```
/                          → Onboarding or Dashboard
/onboarding                → Multi-step wizard
/dashboard                 → Main dashboard
/programs                  → Browse all programs
/programs/[id]             → Program detail
/workout/[id]              → Active workout logger
/progress                  → Charts and stats
```

## Design Documents

- **[docs/plans/2025-02-15-workout-app-design.md](docs/plans/2025-02-15-workout-app-design.md)** - Complete system design, data model, user flows
- **[docs/plans/2025-02-15-workout-app-implementation.md](docs/plans/2025-02-15-workout-app-implementation.md)** - Step-by-step implementation plan with 21 tasks

## When to Use GSD Workflow

If user asks for GSD or uses `/gsd-*` commands, use the `get-shit-done` skill. Treat these as command invocations and load the matching file from `.claude/skills/gsd-*`.

The implementation plan ([docs/plans/2025-02-15-workout-app-implementation.md](docs/plans/2025-02-15-workout-app-implementation.md)) explicitly states to use `superpowers:executing-plans` for task-by-task implementation.

## MVP Scope (Option C - Full Release)

- ✅ All 6 programs: back squat, front squat, bench press, deadlift, box jump, burpees
- ✅ Multiple cycles per program (8 weeks, 3 days/week)
- ✅ Comprehensive onboarding (name, experience, goals)
- ✅ Rich dashboard (active cycles, today's workout, activity, PRs, recommendations)
- ✅ Rule-based recommendations (plateau detection, PR celebrations, missed workout reminders)
- ✅ Local-first with optional Supabase sync
- ✅ % of 1RM-based intensity calculations
- ✅ Animations and polished UI/UX
- ✅ Rest timer functionality

## Error Handling Priorities

**Critical (IndexedDB):**
- Quota exceeded → Show error, offer sessionStorage fallback
- Transaction conflict → Retry with exponential backoff

**Non-blocking (Sync):**
- Network unavailable → Queue for later retry, subtle 'pending' indicator
- Auth expired → Auto-refresh token, retry failed syncs
- Conflicts → Last write wins by timestamp, merge complementary data

## Animation Components

The app includes several custom animation components:
- `FadeIn` - Smooth entrance animations
- `ScaleButton` - Animated button interactions
- `StaggerList` - Sequential animations for list items
- `PageTransition` - Smooth page transitions
- Global smooth scrolling enabled in CSS