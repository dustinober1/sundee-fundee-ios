# Dashboard Enhancements Design Spec

**Date:** 2026-03-29
**Status:** Approved

## Overview

Enhance the main dashboard with three high-priority features: Cycle Phase Banner, Suggested Workout, and Micro-Progress Celebrations. The goal is to make the dashboard more personalized, actionable, and rewarding.

## Features

### 1. Cycle Phase Banner

**Placement:** Full-width banner below the welcome header, above stat cards.

**Visibility:** Only shown when `cycleTrackingEnabled: true` in user profile.

**Content:**
- Label: "Current Phase"
- Phase name (e.g., "Ovulation Phase")
- Training recommendation (e.g., "Peak performance — go for PRs!")

**Data sources:**
- `periodLogs` subcollection (ordered by startDate desc)
- `cycleSettings/default` document
- `calculateCycleStatus()` from `src/lib/domain/cycle-calculations.ts`
- `getPhaseRecommendation()` from same file

**Styling:**
- Navy gradient background (`linear-gradient(135deg, #0d1a40, #1a2a5e)`)
- Cream text (`#f4f0df`)
- Gold label (`#c9a227`)
- Orange recommendation text (`#f27319`)
- Rounded corners (12px)

### 2. Suggested Workout

**Placement:** New card replacing the "Start Workout" button in Quick Actions.

**Behavior:**

| User State | Display |
|------------|---------|
| Enrolled in program | Program progress card with week/session info |
| No active program | "Generate AI Workout" prompt |

**Program enrolled view:**
- Label: "Today's Focus"
- Title: "Week X — [Session Name]"
- Tags: Duration, focus area
- Progress bar showing program completion %
- "Start Session" button (orange)

**No program view:**
- Label: "Today's Focus"
- Title: "Generate AI Workout"
- Description: "Personalized workout based on your cycle, goals, and equipment"
- "Generate Workout" button (orange)

**Data sources:**
- `enrolledPrograms` subcollection (status: "active")
- `programs` data (from WOD dashboard or hardcoded)
- AI generation via `/api/ai/generate`

**Quick Actions simplification:**
- Remove "Start Workout" button
- Keep: "Log Max", "Programs", "Benchmarks" as 3-column grid

### 3. Micro-Progress Celebrations ("Recent Wins")

**Placement:** Two locations working together:

1. **Stat Cards** (existing) — updated with dynamic data:
   - Card 1: Workouts this week
   - Card 2: PRs this month
   - Card 3: Active program name (or "None")

2. **Recent Wins Card** — new card below Quick Actions showing last 3-5 achievements

**Celebrated events:**
- New 1RM PRs (`newPersonalRecord`)
- Benchmark improvements (`newConditioningPR`)
- First workout (`workoutCompleted` for new users)
- Program completion (`programCompleted`)

**NOT celebrated:** Streak milestones (excluded per user preference)

**Data sources:**
- `oneRepMaxes` subcollection — detect PRs by comparing to previous entries
- `benchmarkResults` subcollection — detect improvements
- `completedWorkouts` subcollection — first workout detection
- `enrolledPrograms` subcollection — program completion

**Win item format:**
- Icon (emoji): 🏆 for PRs, ⏱️ for benchmarks, ✨ for first workout
- Title (bold): "New PR — Back Squat" or "Fran — New Best"
- Subtitle: Value + time ago (e.g., "185 lb · 2 days ago")

**Limits:**
- Last 30 days only
- Max 5 items shown
- Empty state: "Your wins will appear here as you train"

## Technical Implementation

### New Server Actions (in `src/app/(features)/dashboard/actions.ts`)

```typescript
// Get cycle status for banner
export async function getCycleStatus(): Promise<CycleStatusResult | null>

// Get active program enrollment with program details
export async function getActiveProgram(): Promise<ActiveProgram | null>

// Get dashboard stats
export async function getDashboardStats(): Promise<{
  workoutsThisWeek: number;
  prsThisMonth: number;
  activeProgramName: string | null;
}>

// Get recent wins
export async function getRecentWins(): Promise<Win[]>
```

### New Components

- `CyclePhaseBanner` — client component for cycle display
- `SuggestedWorkoutCard` — client component for workout suggestion
- `RecentWinsCard` — client component for wins list
- `WinItem` — individual win display

### Data Flow

```
DashboardPage (Server Component)
    ├── getCycleStatus() → CyclePhaseBanner
    ├── getDashboardStats() → StatCards
    ├── getActiveProgram() → SuggestedWorkoutCard
    └── getRecentWins() → RecentWinsCard
```

## Edge Cases

| Scenario | Handling |
|----------|----------|
| Cycle tracking disabled | Hide banner entirely |
| No period logs | Hide banner (can't calculate phase) |
| No active program | Show AI workout prompt |
| Free tier user (no AI) | Show "Browse Programs" instead |
| No wins yet | Show empty state message |
| First workout | Show special "First Workout!" win |

## Files to Modify

- `src/app/(features)/dashboard/page.tsx` — main layout changes
- `src/app/(features)/dashboard/actions.ts` — new file, server actions
- `src/components/dashboard/CyclePhaseBanner.tsx` — new
- `src/components/dashboard/SuggestedWorkoutCard.tsx` — new
- `src/components/dashboard/RecentWinsCard.tsx` — new

## Out of Scope

- Streak tracking/milestones
- Push notifications for wins
- Confetti animations
- Social sharing of wins
