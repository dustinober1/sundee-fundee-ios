# Architecture Research

**Domain:** Workout Tracking (Local-First, Offline-First)
**Researched:** 2026-02-17
**Confidence:** HIGH

## Standard Architecture

### System Overview

```
┌─────────────────────────────────────────────────────────────┐
│                        UI Layer (React)                     │
├─────────────────────────────────────────────────────────────┤
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐     │
│  │ Dashboard│  │ Logger   │  │ Charts   │  │ Programs │     │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘     │
│       │             │             │             │           │
├───────┴─────────────┴─────────────┴─────────────┴───────────┤
│                   State Layer (Context/Hooks)               │
│  (UserContext, ExerciseContext, TimerContext, SyncContext)  │
├─────────────────────────────────────────────────────────────┤
│  ┌───────────────────────────────────────────────────────┐  │
│  │              Recommendation Engine (Logic)            │  │
│  │        (Rule-based / Heuristic / Client-side ML)      │  │
│  └───────────────────────┬───────────────────────────────┘  │
├──────────────────────────┼──────────────────────────────────┤
│                          ▼                                  │
│                   Data Layer (Dexie.js)                     │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐     │
│  │ Workouts │  │Exercises │  │   Logs   │  │ Settings │     │
│  └────┬─────┘  └──────────┘  └──────────┘  └──────────┘     │
├───────┼─────────────────────────────────────────────────────┤
│       ▼                                                     │
│   Sync Layer (Service Worker / Sync Manager)                │
│       │                                                     │
└───────┼─────────────────────────────────────────────────────┘
        │ (Network)
        ▼
┌─────────────────────────────────────────────────────────────┐
│                 Remote Backend (Supabase)                   │
│         (Auth, Backup, Cross-Device Sync)                   │
└─────────────────────────────────────────────────────────────┘
```

### Component Responsibilities

| Component | Responsibility | Typical Implementation |
|-----------|----------------|------------------------|
| **Workout Logger** | Captures sets, reps, weight, RPE in real-time. Manages rest timers. | React form state + `RestTimerContext`. Debounced writes to DB. |
| **Data Layer** | Persists data locally (IndexedDB) for offline access. Queries data for UI. | **Dexie.js**. Strongly typed tables. Live queries (`useLiveQuery`). |
| **Sync Manager** | background sync of local data to cloud. Handles conflict resolution. | Custom hook or Service Worker. Queues failed requests. Uses `upsert`. |
| **Recommendation Engine** | Analyzes past performance to suggest next weights/exercises. | Pure TypeScript functions. Runs on load or after workout. Reads from Dexie. |
| **Visualization** | Renders progress charts (Volume, 1RM). | **Recharts** wrapped in `ResponsiveContainer`. Aggregates data from Dexie. |
| **Static Data** | Provides exercises, default programs, rules. | JSON bundles or embedded TS files (fast load, no DB req). |

## Recommended Project Structure

```
src/
├── components/
│   ├── features/           # Feature-specific UI
│   │   ├── workout/        # Logger, active workout view
│   │   ├── charts/         # Progress visualizations
│   │   └── onboarding/     # User setup wizard
│   └── ui/                 # Shared primitives (shadcn)
├── lib/
│   ├── db/                 # Database configuration
│   │   ├── dexie.ts        # Schema definition
│   │   ├── sync.ts         # Sync logic (Supabase <-> Dexie)
│   │   └── migrations.ts   # Schema versioning
│   ├── recommendations/    # Intelligent logic
│   │   ├── rules.ts        # Progression rules
│   │   └── engine.ts       # Main recommendation function
│   └── calculations/       # Pure math (1RM, Volume)
├── contexts/               # Global state
│   ├── SyncContext.tsx     # Online status & sync triggers
│   └── UserContext.tsx     # User profile & preferences
├── hooks/
│   └── use-live-query.ts   # Re-export from Dexie-React
└── data/                   # Static assets
    ├── programs/           # JSON program definitions
    └── exercises.ts        # Exercise metadata
```

### Structure Rationale

- **lib/db:** Centralizes all data persistence logic. Separation of `sync.ts` keeps the database definition clean.
- **lib/recommendations:** Isolates business logic from UI. Allows testing the engine without mounting React components.
- **features/:** Groups components by domain (Workout, Charts) rather than type, making the codebase easier to navigate as it grows.

## Architectural Patterns

### Pattern 1: Local-First with Background Sync

**What:** The app reads/writes exclusively to IndexedDB (Dexie). A separate process syncs Dexie to Supabase in the background.
**When to use:** Offline-critical apps like workout trackers (gyms often have bad service).
**Trade-offs:** High UI responsiveness vs. complexity of conflict resolution.

**Example:**
```typescript
// 1. UI writes to Local DB immediately
const logSet = async (set) => {
  await db.sets.add(set); // Instant
  triggerSync(); // Fire and forget
};

// 2. Sync logic (simplified)
const triggerSync = async () => {
  if (!navigator.onLine) return;
  const unsynced = await db.sets.where('synced').equals(0).toArray();
  if (unsynced.length === 0) return;

  const { error } = await supabase.from('sets').upsert(unsynced);
  if (!error) {
    await db.sets.bulkPut(unsynced.map(s => ({ ...s, synced: 1 })));
  }
};
```

### Pattern 2: Client-Side Recommendation Engine

**What:** Logic that queries local history to generate "Next Workout" suggestions without API calls.
**When to use:** User-specific, privacy-focused, low-latency requirements.
**Trade-offs:** Limited by device power (rarely an issue for this domain) vs. zero server cost/latency.

**Example:**
```typescript
// src/lib/recommendations/engine.ts
export async function getNextWeights(exerciseId: string) {
  const history = await db.sets
    .where('exerciseId').equals(exerciseId)
    .reverse().limit(5).toArray();

  if (detectPlateau(history)) {
    return applyDeload(history[0].weight);
  }
  return applyProgressiveOverload(history[0].weight);
}
```

### Pattern 3: Live Query Data Binding

**What:** UI components subscribe to Database queries. Changes in DB (even from background sync) auto-update UI.
**When to use:** When background processes (sync) might update data the user is viewing.
**Trade-offs:** reactive UI vs. potential render noise (mitigate with memoization).

**Example:**
```typescript
// UI automatically re-renders when db.sets changes
const workoutHistory = useLiveQuery(() => db.sets.toArray());
```

## Data Flow

### Request Flow (Write)

```
[User Interaction] (Complete Set)
    ↓
[WorkoutLogger Component]
    ↓
[Dexie.js (IndexedDB)] ← (Persisted Immediately)
    ↓ (Async Trigger)
[Sync Service]
    ↓ (If Online)
[Supabase (Postgres)]
```

### Request Flow (Read/Recommendation)

```
[Dashboard Load]
    ↓
[Recommendation Hook]
    ↓ (Query)
[Dexie.js] (Fetch recent history)
    ↓
[Recommendation Engine] (Calculate next steps)
    ↓
[UI Display]
```

## Suggested Build Order

1.  **Core Data Layer (Current Phase):** Finalize Dexie schema for `completedWorkouts`, `sets`, and `oneRepMaxes`.
2.  **Basic Sync (Next Phase):** Implement one-way backup (Local -> Remote) to secure user data.
3.  **Recommendation Logic:** Build the pure functions for progression logic (independent of UI).
4.  **Visualization:** Add Charts consuming the now-reliable data.
5.  **Full Sync:** Implement Remote -> Local sync (conflict resolution) for multi-device support.

## Scaling Considerations

| Scale | Architecture Adjustments |
|-------|--------------------------|
| **0-1k users** | Client-side heavy. Direct Dexie usage. Simple "last-write-wins" sync. |
| **1k-100k users** | Optimize IndexedDB indices. Add server-side validation for sync. |
| **100k+ users** | Move recommendation heavy-lifting to server (optional). Partition IndexedDB data (archive old workouts). |

## Sources

- [Dexie.js Documentation](https://dexie.org/)
- [Local-First Web Development](https://localfirstweb.dev/)
- [Supabase Offline Patterns](https://supabase.com/docs/guides/realtime/presence)
- [Recharts Responsive Patterns](https://recharts.org/)

---
*Architecture research for: Workout Tracking*
*Researched: 2026-02-17*
