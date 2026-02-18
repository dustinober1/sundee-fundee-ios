# ARCHITECTURE

## Purpose
Concise description of the app architecture and data flow so new contributors can get oriented quickly.

## High-level summary
- Mobile-first, **local-first** app with an optional **sync-later** pattern.
- Primary persistence: `IndexedDB` (Dexie) for all user/workout state.
- Optional cloud backup and cross-device sync via `Supabase`.

## Layers
1. UI Layer
   - `shadcn/ui` components + Tailwind + Framer Motion animations
   - Pages & routing: `src/app/` (App Router)
2. State Layer
   - React Contexts: `UserContext`, `ExerciseContext`, `RestTimerContext`
   - Providers in `src/contexts/` expose business operations and caches
3. Data Layer
   - Dexie wrappers in `src/lib/db/dexie.ts`
   - Local models in `src/types/` and `src/lib/cycle-seed.ts`
4. Sync Layer (optional)
   - `src/lib/supabase/` — handles remote backup and conflict resolution (last-write-by-timestamp)

## Data flow (text diagram)
UI → Contexts (validation + calculations) → Dexie (local storage) → [optional sync] → Supabase

## Key responsibilities (where to look)
- Business rules / calculations: `src/lib/calculations.ts`
- Program data: `src/data/programs/`
- Cycle tracking: `src/lib/cycle-calculations.ts`
- PR detection / recommendations: `src/lib/recommendations/`

## Non-functional considerations
- Offline-first UX and queuing for sync
- IndexedDB quota & transaction error handling (see `CLAUDE.md` priorities)
- Animations optimized for mobile-first performance

---
Status: architecture centers on local-first reliability with optional cloud sync.