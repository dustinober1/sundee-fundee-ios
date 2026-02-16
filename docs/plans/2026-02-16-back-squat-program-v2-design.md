# Back Squat Program V2 Design Document

**Date:** 2026-02-16
**Status:** Approved
**Approach:** Program Format V2 - Complete Schema Redesign

---

## Overview

Replace the existing simple "Back Squat 5x5 Linear" program with a comprehensive 8-week back squat cycle featuring phases, multiple session types, exercise variants, and a structured test week. This is a complete schema redesign (ProgramV2) with no backward compatibility requirements since the app has not yet launched.

**Program Structure:**
- 8 weeks total, 3 sessions per week
- Phase 1 (Weeks 1-4): Hypertrophy & Positional Foundation
- Phase 2 (Weeks 5-7): Strength & Rigidity
- Week 8: Peak & Test
- Session types: Support Session A (Positional), Support Session B (Structural Balance), Sunday Anchor (Heavy)

---

## 1. Data Model & TypeScript Types

### Core Interfaces

```typescript
interface ProgramV2 {
  id: string;
  name: string;
  category: ProgramCategory;
  description: string;
  durationWeeks: number;
  sessionsPerWeek: number;
  difficulty: DifficultyLevel;
  phases: Phase[];
  weeks: WeekV2[];
}

interface Phase {
  id: string;
  name: string;
  goal: string;
  weekRange: [number, number];
}

interface WeekV2 {
  week: number;
  phaseId?: string;
  isTestWeek?: boolean;
  sessions: Session[];
}

interface Session {
  sessionId: string;
  sessionName: string;
  sessionType: 'support' | 'anchor' | 'testing';
  focus: string;
  exercises: ExerciseV2[];
}

interface ExerciseV2 {
  exercise: string;
  variant?: string;
  sets: number | 'AMRAP';
  reps: number | [number, number] | 'AMRAP';
  percent1RM: number;
  restMinutes?: number;
  notes?: string;
}
```

### Key Features
- **Session replaces Day**: Named sessions with types and focus areas
- **Rep ranges**: Support `[2, 3]` for "2-3 reps" or `number` for fixed reps
- **Variants**: Optional `variant` field for exercise variations (pause, zombie, zercher)
- **Phases**: Week grouping with goals
- **Test week flag**: Special handling for Week 8

---

## 2. Architecture & Components

### New Components

| Component | Purpose | Location |
|-----------|---------|----------|
| `PhaseBanner` | Displays current phase name, goal, progress % | Workout page top, dashboard |
| `SessionSelector` | Three view modes for session selection | Workout page entry |
| `ExerciseCardV2` | Renders exercises with variants, rep ranges | Workout page |
| `TestDayInterface` | Week 8 warm-up ladder, single attempts | Workout page (conditional) |
| `SetInputV2` | Handles rep ranges, AMRAP, time-based sets | ExerciseCardV2 children |

### Session Selector View Modes

1. **Session Cards** (default): Large cards showing session name, focus, exercise count
2. **Week Calendar**: Grid view of all 3 sessions for current week
3. **Compact List**: Simple dropdown with session names

User preference stored in `userProgramPreferences` table.

### Component Hierarchy

```
WorkoutPage (workout/[id]/page.tsx)
  ├─ PhaseBanner
  ├─ SessionSelector
  │   ├─ SessionCardsView OR WeekCalendarView OR CompactListView
  └─ ExerciseCardV2
      └─ SetInputV2
```

---

## 3. Data Layer & IndexedDB

### Schema Changes

**Updated tables:**
- `programs` - Replace V1 schema with V2
- `activeCycles` - Add `currentSessionId`, `currentPhase`
- `completedWorkouts` - Add `sessionId`
- `userProgramPreferences` - NEW: View mode, current phase tracking

**New indexes:**
- `programs` by `category` and `difficulty`
- `completedWorkouts` by `sessionId`

### CRUD Functions

```typescript
getProgram(id: string): Promise<ProgramV2 | undefined>
getCurrentSession(cycleId: string): Promise<Session | undefined>
getPhaseProgress(cycleId: string): Promise<number>  // 0-100
updateUserPreference(userId: string, viewMode: ViewMode): Promise<void>
```

### No Migration Required

Since the app has not launched, we do a direct replacement:
- Delete V1 program files
- Update `programs` table schema
- Seed new 8-week back squat program

---

## 4. Program Data Structure

### Exercise Database Additions

| Exercise ID | Display Name | Variant |
|-------------|--------------|---------|
| `pause-squat` | Pause Squat | pause |
| `zombie-squat` | Zombie Squat | zombie |
| `zercher-squat` | Zercher Squat | zercher |
| `bulgarian-split-squat` | Bulgarian Split Squat | - |
| `front-rack-hold` | Front Rack Hold | - |

### JSON Structure (excerpt)

```json
{
  "id": "back-squat-complete-cycle",
  "name": "Back Squat: Complete 8-Week Cycle",
  "category": "back-squat",
  "durationWeeks": 8,
  "sessionsPerWeek": 3,
  "difficulty": "intermediate",
  "phases": [
    {
      "id": "phase-1",
      "name": "Hypertrophy & Positional Foundation",
      "goal": "Build muscle and master the upright torso",
      "weekRange": [1, 4]
    }
  ],
  "weeks": [
    {
      "week": 1,
      "phaseId": "phase-1",
      "sessions": [
        {
          "sessionId": "w1-a",
          "sessionName": "Support Session A",
          "sessionType": "support",
          "focus": "Positional Strength (Pause/Speed)",
          "exercises": [
            {
              "exercise": "pause-squat",
              "sets": 3,
              "reps": 8,
              "percent1RM": 0.60,
              "restMinutes": 3
            }
          ]
        }
      ]
    }
  ]
}
```

---

## 5. Workout Logging Flow

### Standard Week (1-7) Flow

1. **Dashboard**: Shows "Week 3 of 8 - Phase 1: Hypertrophy - 40% complete"
2. **Session Selection**: User taps session card (e.g., "Support Session A")
3. **Exercise Logging**: Standard set-by-set input with weight/reps
4. **Completion**: Confetti, shows next session

### Test Week (Week 8) Flow

1. **Test Day Interface** loads (triggered by `isTestWeek: true`)
2. **Warm-up Ladder**: Auto-generated checkboxes (30%, 50%, 60%, 70%)
3. **Working Sets**: 80%, 90%, 95%, 1RM Attempt
4. **Attempt Handling**:
   - Success → Update 1RM, celebration
   - Failure → Option to re-attempt or decrease weight
5. **Completion**: Update all exercise 1RMs, show program completion

---

## 6. Error Handling & Edge Cases

| Scenario | Solution |
|----------|----------|
| Missing 1RM for new exercise | Prompt to enter estimated 1RM or default to main squat × 0.90 |
| Test day failure (miss 95%) | Options: re-attempt same weight or decrease by 5% |
| Skip session | Explicit "Skip" button with reason selection |
| Week 4→5 intensity jump | Transition modal with side-by-side comparison |
| Incomplete week (user returns after 4 weeks) | Dashboard: "Pick up at Week 3, Session A" or "Restart from Week 1" |
| Time-based sets (Front Rack Hold) | Timer UI instead of rep counter, log `actualSeconds` |

---

## 7: Testing Strategy

### Unit Tests (70%)
- Type system validation (phase ranges, session IDs)
- Calculation utilities with rep ranges
- Data layer CRUD operations

### Integration Tests (20%)
- SessionSelector view mode switching
- ExerciseCardV2 variant and rep range display
- V2 program seeding to IndexedDB

### E2E Tests (10%)
- Complete Week 1, all three sessions
- Phase transition Week 4 → Week 5
- Test day: fail, re-attempt, succeed

### Manual Testing Checklist
- [ ] All 8 weeks display correctly
- [ ] Session selector switches view modes
- [ ] Test day interface handles attempts and failures
- [ ] Phase progress bars accurate
- [ ] Confetti on program completion

---

## 8. Implementation Notes

### Special Cases

1. **Front Rack Hold**: Time-based sets, `percent1RM: 0.00`, timer UI
2. **Week 8**: `isTestWeek: true` triggers TestDayInterface
3. **Rep Ranges**: Display "2-3 reps", use midpoint for calculations
4. **AMRAP**: Special input field, no upper limit

### User Preferences

Store in `userProgramPreferences`:
```typescript
{
  userId: string;
  programId: string;
  viewMode: 'session-cards' | 'week-calendar' | 'compact-list';
  currentSessionId?: string;
}
```

---

## Design Complete

This design document outlines a complete schema redesign (ProgramV2) for the Back Squat 8-Week Program. All sections approved and ready for implementation planning.

**Next Step:** Invoke `writing-plans` skill to create detailed implementation plan.
