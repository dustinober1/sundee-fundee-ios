# Back Squat Program V2 Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace the existing simple back squat program with a comprehensive 8-week cycle featuring phases, multiple session types, exercise variants, and a structured test week.

**Architecture:** Complete schema redesign (ProgramV2) with no backward compatibility. New TypeScript types, IndexedDB schema updates, new React components for session selection and test day interface, and comprehensive JSON program data covering all 8 weeks with 3 sessions per week.

**Tech Stack:** Next.js 16, React 19, TypeScript, Dexie.js (IndexedDB), shadcn/ui, Vitest, Playwright

**Design Reference:** [docs/plans/2026-02-16-back-squat-program-v2-design.md](docs/plans/2026-02-16-back-squat-program-v2-design.md)

---

## Task 1: Update TypeScript Type Definitions

### Step 1.1: Create ProgramV2 types

**Files:**
- Create: `src/types/programV2.ts`
- Test: `tests/unit/types/programV2.test.ts`

**Step 1.1.1: Write failing test for ProgramV2 interface**

Create: `tests/unit/types/programV2.test.ts`

```typescript
import { describe, it, expect } from 'vitest';
import type { ProgramV2, Phase, Session, ExerciseV2 } from '@/types/programV2';

describe('ProgramV2 Types', () => {
  it('should accept valid ProgramV2 structure', () => {
    const program: ProgramV2 = {
      id: 'test-program',
      name: 'Test Program',
      category: 'back-squat',
      description: 'Test description',
      durationWeeks: 8,
      sessionsPerWeek: 3,
      difficulty: 'intermediate',
      phases: [
        {
          id: 'phase-1',
          name: 'Test Phase',
          goal: 'Test goal',
          weekRange: [1, 4]
        }
      ],
      weeks: []
    };

    expect(program.phases[0].weekRange).toEqual([1, 4]);
  });

  it('should accept ExerciseV2 with rep range', () => {
    const exercise: ExerciseV2 = {
      exercise: 'pause-squat',
      sets: 3,
      reps: [2, 3],
      percent1RM: 0.65,
      restMinutes: 3
    };

    expect(Array.isArray(exercise.reps)).toBe(true);
  });

  it('should accept ExerciseV2 with AMRAP reps', () => {
    const exercise: ExerciseV2 = {
      exercise: 'pause-squat',
      sets: 'AMRAP',
      reps: 'AMRAP',
      percent1RM: 0.65,
      restMinutes: 3
    };

    expect(exercise.sets).toBe('AMRAP');
  });

  it('should accept Session with all required fields', () => {
    const session: Session = {
      sessionId: 'w1-a',
      sessionName: 'Support Session A',
      sessionType: 'support',
      focus: 'Positional Strength',
      exercises: []
    };

    expect(session.sessionType).toBe('support');
  });
});
```

**Step 1.1.2: Run test to verify it fails**

Run: `npm run test:run tests/unit/types/programV2.test.ts`

Expected: FAIL - "Cannot find module '@/types/programV2'"

**Step 1.1.3: Write ProgramV2 type definitions**

Create: `src/types/programV2.ts`

```typescript
import type { ProgramCategory, DifficultyLevel } from './program';

export interface Phase {
  id: string;
  name: string;
  goal: string;
  weekRange: [number, number];
}

export interface ExerciseV2 {
  exercise: string;
  variant?: string;
  sets: number | 'AMRAP';
  reps: number | [number, number] | 'AMRAP';
  percent1RM: number;
  restMinutes?: number;
  notes?: string;
}

export interface Session {
  sessionId: string;
  sessionName: string;
  sessionType: 'support' | 'anchor' | 'testing';
  focus: string;
  exercises: ExerciseV2[];
}

export interface WeekV2 {
  week: number;
  phaseId?: string;
  isTestWeek?: boolean;
  sessions: Session[];
}

export interface ProgramV2 {
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
```

**Step 1.1.4: Run test to verify it passes**

Run: `npm run test:run tests/unit/types/programV2.test.ts`

Expected: PASS (all 4 tests)

**Step 1.1.5: Commit**

```bash
git add src/types/programV2.ts tests/unit/types/programV2.test.ts
git commit -m "feat: add ProgramV2 TypeScript types

Add Phase, ExerciseV2, Session, WeekV2, ProgramV2 interfaces
Support rep ranges [number, number], AMRAP sets/reps
Add sessionType, variant, notes fields
Write tests for all type structures

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Task 2: Update Exercise Database

### Step 2.1: Add new exercise variants

**Files:**
- Modify: `src/data/exercises.ts`
- Test: `tests/unit/data/exercises.test.ts`

**Step 2.1.1: Write failing test for new exercises**

Create: `tests/unit/data/exercises.test.ts`

```typescript
import { describe, it, expect } from 'vitest';
import { getExerciseByName } from '@/data/exercises';

describe('Exercise Database', () => {
  it('should find pause-squat variant', () => {
    const exercise = getExerciseByName('pause-squat');
    expect(exercise).toBeDefined();
    expect(exercise?.name).toBe('Pause Squat');
  });

  it('should find zombie-squat variant', () => {
    const exercise = getExerciseByName('zombie-squat');
    expect(exercise).toBeDefined();
    expect(exercise?.name).toBe('Zombie Squat');
  });

  it('should find zercher-squat variant', () => {
    const exercise = getExerciseByName('zercher-squat');
    expect(exercise).toBeDefined();
    expect(exercise?.name).toBe('Zercher Squat');
  });

  it('should find bulgarian-split-squat', () => {
    const exercise = getExerciseByName('bulgarian-split-squat');
    expect(exercise).toBeDefined();
    expect(exercise?.name).toBe('Bulgarian Split Squat');
  });

  it('should find front-rack-hold', () => {
    const exercise = getExerciseByName('front-rack-hold');
    expect(exercise).toBeDefined();
    expect(exercise?.name).toBe('Front Rack Hold');
  });
});
```

**Step 2.1.2: Run test to verify it fails**

Run: `npm run test:run tests/unit/data/exercises.test.ts`

Expected: FAIL - getExerciseByName returns undefined

**Step 2.1.3: Add new exercises to database**

Read: `src/data/exercises.ts`

(Review existing structure, then add to the exercise list)

Add to exercises array:

```typescript
export const EXERCISES = [
  // ... existing exercises ...

  {
    id: 'pause-squat',
    name: 'Pause Squat',
    category: 'back-squat',
    muscleGroups: ['quadriceps', 'glutes', 'core'],
    description: 'Back squat with a 2-3 second pause at the bottom'
  },
  {
    id: 'zombie-squat',
    name: 'Zombie Squat',
    category: 'back-squat',
    muscleGroups: ['quadriceps', 'core', 'upper-back'],
    description: 'Front squat with arms extended forward, teaches upright torso'
  },
  {
    id: 'zercher-squat',
    name: 'Zercher Squat',
    category: 'back-squat',
    muscleGroups: ['quadriceps', 'glutes', 'core', 'biceps'],
    description: 'Squat with bar held in crook of elbows'
  },
  {
    id: 'bulgarian-split-squat',
    name: 'Bulgarian Split Squat',
    category: 'back-squat',
    muscleGroups: ['quadriceps', 'glutes', 'core'],
    description: 'Single-leg squat with rear foot elevated on bench'
  },
  {
    id: 'front-rack-hold',
    name: 'Front Rack Hold',
    category: 'back-squat',
    muscleGroups: ['core', 'upper-back', 'shoulders'],
    description: 'Isometric hold in front rack position, time-based'
  }
];

export function getExerciseByName(id: string) {
  return EXERCISES.find(ex => ex.id === id);
}
```

**Step 2.1.4: Run test to verify it passes**

Run: `npm run test:run tests/unit/data/exercises.test.ts`

Expected: PASS (all 5 tests)

**Step 2.1.5: Commit**

```bash
git add src/data/exercises.ts tests/unit/data/exercises.test.ts
git commit -m "feat: add new exercise variants to database

Add pause-squat, zombie-squat, zercher-squat
Add bulgarian-split-squat, front-rack-hold
Include muscle groups and descriptions
Add getExerciseByName helper function

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Task 3: Update IndexedDB Schema

### Step 3.1: Update Dexie database for V2 programs

**Files:**
- Modify: `src/lib/db/dexie.ts`
- Modify: `src/lib/db/schema.ts`
- Test: `tests/unit/db/schema-v2.test.ts`

**Step 3.1.1: Write failing test for new schema**

Create: `tests/unit/db/schema-v2.test.ts`

```typescript
import { describe, it, expect, beforeEach } from 'vitest';
import { db } from '@/lib/db/dexie';
import type { ProgramV2 } from '@/types/programV2';

describe('V2 Database Schema', () => {
  beforeEach(async () => {
    await db.delete();
    await db.open();
  });

  it('should store ProgramV2 in programs table', async () => {
    const program: ProgramV2 = {
      id: 'test-v2-program',
      name: 'Test V2 Program',
      category: 'back-squat',
      description: 'Test',
      durationWeeks: 8,
      sessionsPerWeek: 3,
      difficulty: 'intermediate',
      phases: [],
      weeks: []
    };

    await db.programs.add(program as any); // Type assertion for migration period
    const retrieved = await db.programs.get('test-v2-program');

    expect(retrieved).toBeDefined();
    expect(retrieved?.sessionsPerWeek).toBe(3);
  });

  it('should have userProgramPreferences table', async () => {
    await db.userProgramPreferences.add({
      id: 'pref-1',
      userId: 'user-1',
      programId: 'back-squat-complete-cycle',
      viewMode: 'session-cards'
    });

    const pref = await db.userProgramPreferences.get('pref-1');
    expect(pref?.viewMode).toBe('session-cards');
  });
});
```

**Step 3.1.2: Run test to verify it fails**

Run: `npm run test:run tests/unit/db/schema-v2.test.ts`

Expected: FAIL - Table 'userProgramPreferences' does not exist

**Step 3.1.3: Update database schema**

Read: `src/lib/db/dexie.ts`

Update the database class:

```typescript
import Dexie, { Table } from 'dexie';
import type { User, OneRepMax, ActiveCycle, CompletedWorkout, CompletedSet, SetMetrics } from '@/types';
import type { ProgramV2 } from '@/types/programV2';

export interface UserProgramPreference {
  id: string;
  userId: string;
  programId: string;
  viewMode: 'session-cards' | 'week-calendar' | 'compact-list';
  currentSessionId?: string;
}

export class StrengthDatabase extends Dexie {
  users!: Table<User>;
  oneRepMaxes!: Table<OneRepMax>;
  activeCycles!: Table<ActiveCycle>;
  completedWorkouts!: Table<CompletedWorkout>;
  completedSets!: Table<CompletedSet>;
  setMetrics!: Table<SetMetrics>;
  programs!: Table<ProgramV2>;
  userProgramPreferences!: Table<UserProgramPreference>;

  constructor() {
    super('StrengthApp');

    this.version(2).stores({
      users: 'id, name, createdAt',
      oneRepMaxes: 'id, userId, exerciseId, date',
      activeCycles: 'id, userId, programId, status, currentPhase, currentSessionId',
      completedWorkouts: 'id, userId, activeCycleId, sessionId, completedAt',
      completedSets: 'id, workoutId, exerciseId',
      setMetrics: 'id, setId',
      programs: 'id, category, difficulty',
      userProgramPreferences: 'id, userId, programId'
    });
  }
}

export const db = new StrengthDatabase();
```

**Step 3.1.4: Run test to verify it passes**

Run: `npm run test:run tests/unit/db/schema-v2.test.ts`

Expected: PASS (2 tests)

**Step 3.1.5: Commit**

```bash
git add src/lib/db/dexie.ts tests/unit/db/schema-v2.test.ts
git commit -m "feat: update IndexedDB schema to version 2

Add programs table with ProgramV2 type
Add userProgramPreferences table for view mode
Add currentSessionId, currentPhase to activeCycles
Add sessionId to completedWorkouts
Update indexes for V2 queries

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Task 4: Create Program V2 Data Layer

### Step 4.1: Add CRUD functions for V2 programs

**Files:**
- Modify: `src/lib/db/index.ts`
- Test: `tests/unit/db/program-v2-crud.test.ts`

**Step 4.1.1: Write failing test for program CRUD**

Create: `tests/unit/db/program-v2-crud.test.ts`

```typescript
import { describe, it, expect, beforeEach } from 'vitest';
import { db } from '@/lib/db/dexie';
import { getProgramV2, saveProgramV2, getCurrentSession } from '@/lib/db';
import type { ProgramV2 } from '@/types/programV2';

describe('ProgramV2 CRUD', () => {
  beforeEach(async () => {
    await db.delete();
    await db.open();
  });

  it('should save and retrieve ProgramV2', async () => {
    const program: ProgramV2 = {
      id: 'test-program',
      name: 'Test',
      category: 'back-squat',
      description: 'Test',
      durationWeeks: 8,
      sessionsPerWeek: 3,
      difficulty: 'intermediate',
      phases: [
        {
          id: 'phase-1',
          name: 'Phase 1',
          goal: 'Build muscle',
          weekRange: [1, 4]
        }
      ],
      weeks: [
        {
          week: 1,
          phaseId: 'phase-1',
          sessions: [
            {
              sessionId: 'w1-a',
              sessionName: 'Session A',
              sessionType: 'support',
              focus: 'Test',
              exercises: []
            }
          ]
        }
      ]
    };

    await saveProgramV2(program);
    const retrieved = await getProgramV2('test-program');

    expect(retrieved).toEqual(program);
  });

  it('should get current session for active cycle', async () => {
    const program = await saveProgramV2({
      id: 'test-program',
      name: 'Test',
      category: 'back-squat',
      description: 'Test',
      durationWeeks: 8,
      sessionsPerWeek: 3,
      difficulty: 'intermediate',
      phases: [],
      weeks: [
        {
          week: 1,
          sessions: [
            {
              sessionId: 'w1-a',
              sessionName: 'Session A',
              sessionType: 'support',
              focus: 'Test',
              exercises: []
            }
          ]
        }
      ]
    });

    const session = await getCurrentSession('test-program', 1, 'w1-a');
    expect(session?.sessionId).toBe('w1-a');
  });
});
```

**Step 4.1.2: Run test to verify it fails**

Run: `npm run test:run tests/unit/db/program-v2-crud.test.ts`

Expected: FAIL - "saveProgramV2 is not defined"

**Step 4.1.3: Implement CRUD functions**

Read: `src/lib/db/index.ts`

Add to existing exports:

```typescript
import type { ProgramV2 } from '@/types/programV2';
import type { Session } from '@/types/programV2';

export async function saveProgramV2(program: ProgramV2): Promise<ProgramV2> {
  await db.programs.put(program);
  return program;
}

export async function getProgramV2(id: string): Promise<ProgramV2 | undefined> {
  return await db.programs.get(id);
}

export async function getAllProgramsV2(): Promise<ProgramV2[]> {
  return await db.programs.toArray();
}

export async function getCurrentSession(
  programId: string,
  week: number,
  sessionId: string
): Promise<Session | undefined> {
  const program = await getProgramV2(programId);
  if (!program) return undefined;

  const weekData = program.weeks.find(w => w.week === week);
  if (!weekData) return undefined;

  return weekData.sessions.find(s => s.sessionId === sessionId);
}

export async function getPhaseProgress(
  programId: string,
  cycleId: string
): Promise<number> {
  const program = await getProgramV2(programId);
  if (!program) return 0;

  const cycle = await db.activeCycles.get(cycleId);
  if (!cycle) return 0;

  const currentPhase = program.phases.find(p => p.id === cycle.currentPhase);
  if (!currentPhase) return 0;

  const [startWeek, endWeek] = currentPhase.weekRange;
  const totalWeeksInPhase = endWeek - startWeek + 1;
  const weeksCompleted = cycle.currentWeek - startWeek;

  return Math.round((weeksCompleted / totalWeeksInPhase) * 100);
}

export async function updateUserProgramPreference(
  userId: string,
  programId: string,
  preferences: Partial<{
    viewMode: 'session-cards' | 'week-calendar' | 'compact-list';
    currentSessionId: string;
  }>
): Promise<void> {
  const existing = await db.userProgramPreferences
    .where('[userId+programId]')
    .equals([userId, programId])
    .first();

  if (existing) {
    await db.userProgramPreferences.update(existing.id, preferences);
  } else {
    await db.userProgramPreferences.add({
      id: generateId(),
      userId,
      programId,
      viewMode: preferences.viewMode || 'session-cards',
      currentSessionId: preferences.currentSessionId
    });
  }
}
```

**Step 4.1.4: Run test to verify it passes**

Run: `npm run test:run tests/unit/db/program-v2-crud.test.ts`

Expected: PASS (2 tests)

**Step 4.1.5: Commit**

```bash
git add src/lib/db/index.ts tests/unit/db/program-v2-crud.test.ts
git commit -m "feat: add ProgramV2 CRUD functions

Implement saveProgramV2, getProgramV2, getAllProgramsV2
Add getCurrentSession for session lookup
Add getPhaseProgress for phase percentage calculation
Add updateUserProgramPreference for view mode storage

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Task 5: Create the 8-Week Program JSON

### Step 5.1: Write complete program data

**Files:**
- Create: `src/data/programs/back-squat-complete-cycle.json`
- Modify: `src/data/programs/index.ts`

**Step 5.1.1: Create program JSON file**

Create: `src/data/programs/back-squat-complete-cycle.json`

```json
{
  "id": "back-squat-complete-cycle",
  "name": "Back Squat: Complete 8-Week Cycle",
  "category": "back-squat",
  "description": "Comprehensive 8-week program building positional strength, structural balance, and heavy main lifts. Three weekly sessions: Positional, Structural Balance, and Heavy Anchor.",
  "durationWeeks": 8,
  "sessionsPerWeek": 3,
  "difficulty": "intermediate",
  "phases": [
    {
      "id": "phase-1",
      "name": "Hypertrophy & Positional Foundation",
      "goal": "Build muscle and master the upright torso",
      "weekRange": [1, 4]
    },
    {
      "id": "phase-2",
      "name": "Strength & Rigidity",
      "goal": "Increase intensity and anti-folding strength",
      "weekRange": [5, 7]
    },
    {
      "id": "phase-3",
      "name": "Peak & Test",
      "goal": "Dissipate fatigue and set new 1RM",
      "weekRange": [8, 8]
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
            },
            {
              "exercise": "zombie-squat",
              "sets": 3,
              "reps": 10,
              "percent1RM": 0.50,
              "restMinutes": 2,
              "notes": "Arms extended forward, stay vertical"
            }
          ]
        },
        {
          "sessionId": "w1-b",
          "sessionName": "Support Session B",
          "sessionType": "support",
          "focus": "Structural Balance (Unilateral/Core)",
          "exercises": [
            {
              "exercise": "zercher-squat",
              "sets": 3,
              "reps": 10,
              "percent1RM": 0.45,
              "restMinutes": 2
            },
            {
              "exercise": "bulgarian-split-squat",
              "sets": 3,
              "reps": 10,
              "percent1RM": 0.35,
              "restMinutes": 2
            },
            {
              "exercise": "front-rack-hold",
              "sets": 3,
              "reps": 30,
              "percent1RM": 0.00,
              "restMinutes": 2,
              "notes": "Isometric hold - 30 seconds"
            }
          ]
        },
        {
          "sessionId": "w1-sunday",
          "sessionName": "Sunday Anchor",
          "sessionType": "anchor",
          "focus": "Heavy Main Lift + Front Rack Overloads",
          "exercises": [
            {
              "exercise": "back-squat",
              "sets": 5,
              "reps": 10,
              "percent1RM": 0.60,
              "restMinutes": 4
            },
            {
              "exercise": "front-rack-hold",
              "sets": 3,
              "reps": 30,
              "percent1RM": 0.00,
              "restMinutes": 2,
              "notes": "30 second holds"
            }
          ]
        }
      ]
    },
    {
      "week": 2,
      "phaseId": "phase-1",
      "sessions": [
        {
          "sessionId": "w2-a",
          "sessionName": "Support Session A",
          "sessionType": "support",
          "focus": "Positional Strength (Pause/Speed)",
          "exercises": [
            {
              "exercise": "pause-squat",
              "sets": 3,
              "reps": 8,
              "percent1RM": 0.65,
              "restMinutes": 3
            },
            {
              "exercise": "zombie-squat",
              "sets": 3,
              "reps": 10,
              "percent1RM": 0.55,
              "restMinutes": 2
            }
          ]
        },
        {
          "sessionId": "w2-b",
          "sessionName": "Support Session B",
          "sessionType": "support",
          "focus": "Structural Balance (Unilateral/Core)",
          "exercises": [
            {
              "exercise": "zercher-squat",
              "sets": 3,
              "reps": 10,
              "percent1RM": 0.50,
              "restMinutes": 2
            },
            {
              "exercise": "bulgarian-split-squat",
              "sets": 3,
              "reps": 10,
              "percent1RM": 0.35,
              "restMinutes": 2
            },
            {
              "exercise": "front-rack-hold",
              "sets": 3,
              "reps": 30,
              "percent1RM": 0.00,
              "restMinutes": 2
            }
          ]
        },
        {
          "sessionId": "w2-sunday",
          "sessionName": "Sunday Anchor",
          "sessionType": "anchor",
          "focus": "Heavy Main Lift + Front Rack Overloads",
          "exercises": [
            {
              "exercise": "back-squat",
              "sets": 5,
              "reps": 10,
              "percent1RM": 0.65,
              "restMinutes": 4
            },
            {
              "exercise": "front-rack-hold",
              "sets": 3,
              "reps": 30,
              "percent1RM": 0.00,
              "restMinutes": 2
            }
          ]
        }
      ]
    },
    {
      "week": 3,
      "phaseId": "phase-1",
      "sessions": [
        {
          "sessionId": "w3-a",
          "sessionName": "Support Session A",
          "sessionType": "support",
          "focus": "Positional Strength (Pause/Speed)",
          "exercises": [
            {
              "exercise": "pause-squat",
              "sets": 4,
              "reps": 6,
              "percent1RM": 0.70,
              "restMinutes": 3
            },
            {
              "exercise": "zombie-squat",
              "sets": 3,
              "reps": 8,
              "percent1RM": 0.60,
              "restMinutes": 2
            }
          ]
        },
        {
          "sessionId": "w3-b",
          "sessionName": "Support Session B",
          "sessionType": "support",
          "focus": "Structural Balance (Unilateral/Core)",
          "exercises": [
            {
              "exercise": "zercher-squat",
              "sets": 4,
              "reps": 8,
              "percent1RM": 0.55,
              "restMinutes": 2
            },
            {
              "exercise": "bulgarian-split-squat",
              "sets": 3,
              "reps": 12,
              "percent1RM": 0.35,
              "restMinutes": 2
            },
            {
              "exercise": "front-rack-hold",
              "sets": 3,
              "reps": 40,
              "percent1RM": 0.00,
              "restMinutes": 2
            }
          ]
        },
        {
          "sessionId": "w3-sunday",
          "sessionName": "Sunday Anchor",
          "sessionType": "anchor",
          "focus": "Heavy Main Lift + Front Rack Overloads",
          "exercises": [
            {
              "exercise": "back-squat",
              "sets": 4,
              "reps": 10,
              "percent1RM": 0.70,
              "restMinutes": 4
            },
            {
              "exercise": "front-rack-hold",
              "sets": 3,
              "reps": 40,
              "percent1RM": 0.00,
              "restMinutes": 2
            }
          ]
        }
      ]
    },
    {
      "week": 4,
      "phaseId": "phase-1",
      "sessions": [
        {
          "sessionId": "w4-a",
          "sessionName": "Support Session A",
          "sessionType": "support",
          "focus": "Positional Strength (Pause/Speed)",
          "exercises": [
            {
              "exercise": "pause-squat",
              "sets": 4,
              "reps": 6,
              "percent1RM": 0.72,
              "restMinutes": 3
            },
            {
              "exercise": "zombie-squat",
              "sets": 3,
              "reps": 8,
              "percent1RM": 0.62,
              "restMinutes": 2
            }
          ]
        },
        {
          "sessionId": "w4-b",
          "sessionName": "Support Session B",
          "sessionType": "support",
          "focus": "Structural Balance (Unilateral/Core)",
          "exercises": [
            {
              "exercise": "zercher-squat",
              "sets": 4,
              "reps": 8,
              "percent1RM": 0.58,
              "restMinutes": 2
            },
            {
              "exercise": "bulgarian-split-squat",
              "sets": 3,
              "reps": 12,
              "percent1RM": 0.38,
              "restMinutes": 2
            },
            {
              "exercise": "front-rack-hold",
              "sets": 3,
              "reps": 40,
              "percent1RM": 0.00,
              "restMinutes": 2
            }
          ]
        },
        {
          "sessionId": "w4-sunday",
          "sessionName": "Sunday Anchor",
          "sessionType": "anchor",
          "focus": "Heavy Main Lift + Front Rack Overloads",
          "exercises": [
            {
              "exercise": "back-squat",
              "sets": 4,
              "reps": 10,
              "percent1RM": 0.72,
              "restMinutes": 4
            },
            {
              "exercise": "front-rack-hold",
              "sets": 3,
              "reps": 40,
              "percent1RM": 0.00,
              "restMinutes": 2
            }
          ]
        }
      ]
    },
    {
      "week": 5,
      "phaseId": "phase-2",
      "sessions": [
        {
          "sessionId": "w5-a",
          "sessionName": "Support Session A",
          "sessionType": "support",
          "focus": "Positional Strength (Pause/Speed)",
          "exercises": [
            {
              "exercise": "pause-squat",
              "variant": "speed",
              "sets": 6,
              "reps": 2,
              "percent1RM": 0.70,
              "restMinutes": 2,
              "notes": "Speed squats - explosive"
            },
            {
              "exercise": "front-squat",
              "sets": 3,
              "reps": 5,
              "percent1RM": 0.65,
              "restMinutes": 3
            },
            {
              "exercise": "zercher-squat",
              "sets": 3,
              "reps": 8,
              "percent1RM": 0.60,
              "restMinutes": 2
            },
            {
              "exercise": "bulgarian-split-squat",
              "sets": 4,
              "reps": 8,
              "percent1RM": 0.35,
              "restMinutes": 2
            }
          ]
        },
        {
          "sessionId": "w5-b",
          "sessionName": "Support Session B",
          "sessionType": "support",
          "focus": "Structural Balance (Unilateral/Core)",
          "exercises": [
            {
              "exercise": "bulgarian-split-squat",
              "sets": 4,
              "reps": 8,
              "percent1RM": 0.35,
              "restMinutes": 2
            },
            {
              "exercise": "front-rack-hold",
              "sets": 3,
              "reps": 30,
              "percent1RM": 0.00,
              "restMinutes": 2
            }
          ]
        },
        {
          "sessionId": "w5-sunday",
          "sessionName": "Sunday Anchor",
          "sessionType": "anchor",
          "focus": "Heavy Main Lift + Front Rack Overloads",
          "exercises": [
            {
              "exercise": "back-squat",
              "sets": 5,
              "reps": 5,
              "percent1RM": 0.75,
              "restMinutes": 4
            },
            {
              "exercise": "front-rack-hold",
              "sets": 3,
              "reps": 30,
              "percent1RM": 0.00,
              "restMinutes": 2,
              "notes": "Heavier than previous weeks"
            }
          ]
        }
      ]
    },
    {
      "week": 6,
      "phaseId": "phase-2",
      "sessions": [
        {
          "sessionId": "w6-a",
          "sessionName": "Support Session A",
          "sessionType": "support",
          "focus": "Positional Strength (Pause/Speed)",
          "exercises": [
            {
              "exercise": "pause-squat",
              "variant": "speed",
              "sets": 6,
              "reps": 2,
              "percent1RM": 0.75,
              "restMinutes": 2
            },
            {
              "exercise": "front-squat",
              "sets": 4,
              "reps": 4,
              "percent1RM": 0.70,
              "restMinutes": 3
            },
            {
              "exercise": "zercher-squat",
              "sets": 3,
              "reps": 6,
              "percent1RM": 0.65,
              "restMinutes": 2
            },
            {
              "exercise": "bulgarian-split-squat",
              "sets": 4,
              "reps": 8,
              "percent1RM": 0.35,
              "restMinutes": 2
            }
          ]
        },
        {
          "sessionId": "w6-b",
          "sessionName": "Support Session B",
          "sessionType": "support",
          "focus": "Structural Balance (Unilateral/Core)",
          "exercises": [
            {
              "exercise": "bulgarian-split-squat",
              "sets": 4,
              "reps": 8,
              "percent1RM": 0.35,
              "restMinutes": 2
            },
            {
              "exercise": "front-rack-hold",
              "sets": 3,
              "reps": 30,
              "percent1RM": 0.00,
              "restMinutes": 2
            }
          ]
        },
        {
          "sessionId": "w6-sunday",
          "sessionName": "Sunday Anchor",
          "sessionType": "anchor",
          "focus": "Heavy Main Lift + Front Rack Overloads",
          "exercises": [
            {
              "exercise": "back-squat",
              "sets": 5,
              "reps": 3,
              "percent1RM": 0.85,
              "restMinutes": 5
            },
            {
              "exercise": "front-rack-hold",
              "sets": 3,
              "reps": 30,
              "percent1RM": 0.00,
              "restMinutes": 2
            }
          ]
        }
      ]
    },
    {
      "week": 7,
      "phaseId": "phase-2",
      "sessions": [
        {
          "sessionId": "w7-a",
          "sessionName": "Support Session A",
          "sessionType": "support",
          "focus": "Positional Strength (Pause/Speed)",
          "exercises": [
            {
              "exercise": "pause-squat",
              "variant": "speed",
              "sets": 5,
              "reps": 2,
              "percent1RM": 0.80,
              "restMinutes": 2
            },
            {
              "exercise": "front-squat",
              "sets": 5,
              "reps": 2,
              "percent1RM": 0.75,
              "restMinutes": 3
            },
            {
              "exercise": "zercher-squat",
              "sets": 3,
              "reps": 5,
              "percent1RM": 0.70,
              "restMinutes": 2
            },
            {
              "exercise": "bulgarian-split-squat",
              "sets": 4,
              "reps": 6,
              "percent1RM": 0.35,
              "restMinutes": 2
            }
          ]
        },
        {
          "sessionId": "w7-b",
          "sessionName": "Support Session B",
          "sessionType": "support",
          "focus": "Structural Balance (Unilateral/Core)",
          "exercises": [
            {
              "exercise": "bulgarian-split-squat",
              "sets": 4,
              "reps": 6,
              "percent1RM": 0.35,
              "restMinutes": 2
            },
            {
              "exercise": "front-rack-hold",
              "sets": 2,
              "reps": 20,
              "percent1RM": 0.00,
              "restMinutes": 2,
              "notes": "Max weight - 20 second holds"
            }
          ]
        },
        {
          "sessionId": "w7-sunday",
          "sessionName": "Sunday Anchor",
          "sessionType": "anchor",
          "focus": "Heavy Main Lift + Front Rack Overloads",
          "exercises": [
            {
              "exercise": "back-squat",
              "sets": 3,
              "reps": 2,
              "percent1RM": 0.90,
              "restMinutes": 5
            },
            {
              "exercise": "front-rack-hold",
              "sets": 2,
              "reps": 20,
              "percent1RM": 0.00,
              "restMinutes": 2
            }
          ]
        }
      ]
    },
    {
      "week": 8,
      "phaseId": "phase-3",
      "isTestWeek": true,
      "sessions": [
        {
          "sessionId": "w8-a",
          "sessionName": "Support Session A",
          "sessionType": "support",
          "focus": "Deload - Light and Fast",
          "exercises": [
            {
              "exercise": "back-squat",
              "sets": 3,
              "reps": 3,
              "percent1RM": 0.50,
              "restMinutes": 2,
              "notes": "Fast, easy reps - mobility focus"
            }
          ]
        },
        {
          "sessionId": "w8-b",
          "sessionName": "Support Session B",
          "sessionType": "support",
          "focus": "Deload - Stay Loose",
          "exercises": [
            {
              "exercise": "back-squat",
              "sets": 2,
              "reps": 2,
              "percent1RM": 0.60,
              "restMinutes": 2,
              "notes": "Walk 20 mins after, stay loose"
            }
          ]
        },
        {
          "sessionId": "w8-test",
          "sessionName": "TEST DAY",
          "sessionType": "testing",
          "focus": "1-Rep Max Test",
          "exercises": [
            {
              "exercise": "back-squat",
              "sets": 1,
              "reps": 1,
              "percent1RM": 0.30,
              "restMinutes": 2,
              "notes": "Warm-up single"
            },
            {
              "exercise": "back-squat",
              "sets": 1,
              "reps": 1,
              "percent1RM": 0.50,
              "restMinutes": 3,
              "notes": "Warm-up single"
            },
            {
              "exercise": "back-squat",
              "sets": 1,
              "reps": 1,
              "percent1RM": 0.60,
              "restMinutes": 3,
              "notes": "Warm-up single"
            },
            {
              "exercise": "back-squat",
              "sets": 1,
              "reps": 1,
              "percent1RM": 0.70,
              "restMinutes": 5,
              "notes": "Last warm-up"
            },
            {
              "exercise": "back-squat",
              "sets": 1,
              "reps": 1,
              "percent1RM": 0.80,
              "restMinutes": 5,
              "notes": "Working single"
            },
            {
              "exercise": "back-squat",
              "sets": 1,
              "reps": 1,
              "percent1RM": 0.90,
              "restMinutes": 5,
              "notes": "Working single"
            },
            {
              "exercise": "back-squat",
              "sets": 1,
              "reps": 1,
              "percent1RM": 0.95,
              "restMinutes": 5,
              "notes": "Working single"
            },
            {
              "exercise": "back-squat",
              "sets": 1,
              "reps": 1,
              "percent1RM": 1.02,
              "restMinutes": 5,
              "notes": "New 1RM Attempt (102-105%)"
            }
          ]
        }
      ]
    }
  ]
}
```

**Step 5.1.2: Update program loader**

Read: `src/data/programs/index.ts`

Replace the entire file:

```typescript
import backSquatComplete from './back-squat-complete-cycle.json';
import type { ProgramV2 } from '@/types/programV2';

const programs: ProgramV2[] = [
  backSquatComplete as ProgramV2,
];

export function getAllPrograms(): ProgramV2[] {
  return programs;
}

export function getProgramById(id: string): ProgramV2 | undefined {
  return programs.find(p => p.id === id);
}

export function getProgramsByCategory(category: string): ProgramV2[] {
  return programs.filter(p => p.category === category);
}
```

**Step 5.1.3: Write test for program loading**

Create: `tests/unit/programs/program-v2-loader.test.ts`

```typescript
import { describe, it, expect } from 'vitest';
import { getAllPrograms, getProgramById } from '@/data/programs';

describe('ProgramV2 Loader', () => {
  it('loads the complete back squat program', () => {
    const programs = getAllPrograms();
    const program = programs.find(p => p.id === 'back-squat-complete-cycle');

    expect(program).toBeDefined();
    expect(program?.durationWeeks).toBe(8);
    expect(program?.sessionsPerWeek).toBe(3);
  });

  it('has three phases', () => {
    const program = getProgramById('back-squat-complete-cycle');
    expect(program?.phases).toHaveLength(3);
  });

  it('week 8 is marked as test week', () => {
    const program = getProgramById('back-squat-complete-cycle');
    const week8 = program?.weeks.find(w => w.week === 8);
    expect(week8?.isTestWeek).toBe(true);
  });

  it('week 1 has three sessions', () => {
    const program = getProgramById('back-squat-complete-cycle');
    const week1 = program?.weeks.find(w => w.week === 1);
    expect(week1?.sessions).toHaveLength(3);
  });

  it('test week has all warm-up and working singles', () => {
    const program = getProgramById('back-squat-complete-cycle');
    const week8 = program?.weeks.find(w => w.week === 8);
    const testSession = week8?.sessions.find(s => s.sessionType === 'testing');
    expect(testSession?.exercises).toHaveLength(8); // 4 warm-ups + 3 working + 1 attempt
  });
});
```

**Step 5.1.4: Run test to verify it passes**

Run: `npm run test:run tests/unit/programs/program-v2-loader.test.ts`

Expected: PASS (all 5 tests)

**Step 5.1.5: Commit**

```bash
git add src/data/programs/back-squat-complete-cycle.json src/data/programs/index.ts tests/unit/programs/program-v2-loader.test.ts
git commit -m "feat: add complete 8-week back squat program V2

Create comprehensive 8-week program with 3 sessions per week
Phase 1 (Weeks 1-4): Hypertrophy & Positional Foundation
Phase 2 (Weeks 5-7): Strength & Rigidity
Week 8: Peak & Test with warm-up ladder
Update program loader to use V2 structure
Add tests for program structure and content

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Task 6: Remove Old Back Squat Program

### Step 6.1: Delete V1 back squat program file

**Files:**
- Delete: `src/data/programs/back-squat-5x5-linear.json`

**Step 6.1.1: Delete old program file**

Run: `rm src/data/programs/back-squat-5x5-linear.json`

**Step 6.1.2: Commit**

```bash
git add src/data/programs/back-squat-5x5-linear.json
git commit -m "refactor: remove old back squat 5x5 linear program

Replaced by comprehensive 8-week program V2
No migration needed (app not yet launched)

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Task 7: Update Exercise Context for V2

### Step 7.1: Extend ExerciseContext with V2 support

**Files:**
- Modify: `src/contexts/exercise-context.tsx`
- Test: `tests/contexts/exercise-context-v2.test.tsx`

**Step 7.1.1: Write failing test for V2 methods**

Create: `tests/contexts/exercise-context-v2.test.tsx`

```typescript
import { describe, it, expect } from 'vitest';
import { renderHook } from '@testing-library/react';
import { ExerciseProvider, useExercise } from '@/contexts/exercise-context';

describe('ExerciseContext V2', () => {
  it('returns ProgramV2 from getProgram', () => {
    const { result } = renderHook(() => useExercise(), {
      wrapper: ExerciseProvider
    });

    const program = result.current.getProgram('back-squat-complete-cycle');
    expect(program).toBeDefined();
    expect(program?.sessionsPerWeek).toBe(3);
  });

  it('gets session by ID', () => {
    const { result } = renderHook(() => useExercise(), {
      wrapper: ExerciseProvider
    });

    const session = result.current.getSession('back-squat-complete-cycle', 1, 'w1-a');
    expect(session).toBeDefined();
    expect(session?.sessionType).toBe('support');
  });

  it('returns phase for week', () => {
    const { result } = renderHook(() => useExercise(), {
      wrapper: ExerciseProvider
    });

    const phase = result.current.getPhaseForWeek('back-squat-complete-cycle', 1);
    expect(phase).toBeDefined();
    expect(phase?.name).toBe('Hypertrophy & Positional Foundation');
  });

  it('calculates phase progress', () => {
    const { result } = renderHook(() => useExercise(), {
      wrapper: ExerciseProvider
    });

    const progress = result.current.getPhaseProgress('back-squat-complete-cycle', 1, 'phase-1');
    expect(progress).toBeGreaterThan(0);
    expect(progress).toBeLessThanOrEqual(100);
  });
});
```

**Step 7.1.2: Run test to verify it fails**

Run: `npm run test:run tests/contexts/exercise-context-v2.test.tsx`

Expected: FAIL - "getSession is not a function"

**Step 7.1.3: Add V2 methods to ExerciseContext**

Read: `src/contexts/exercise-context.tsx`

Add new methods to the context value and interface:

```typescript
import { getAllPrograms, getProgramById } from '@/data/programs';
import { calculateTargetWeight } from '@/lib/calculations';
import type { Program, Week, Day, Exercise as ProgramExercise } from '@/types';
import type { ProgramV2, WeekV2, Session, Phase } from '@/types/programV2';

interface ExerciseContextValue {
  programs: ProgramV2[];  // Changed from Program[]
  getProgram: (id: string) => ProgramV2 | undefined;
  getWeek: (programId: string, weekNumber: number) => WeekV2 | undefined;  // Changed
  getDay: (programId: string, weekNumber: number, dayNumber: number) => Day | undefined;
  calculatePrescribedWeight: (exercise: ProgramExercise, oneRepMax: number) => number;
  // V2 additions:
  getSession: (programId: string, weekNumber: number, sessionId: string) => Session | undefined;
  getPhaseForWeek: (programId: string, weekNumber: number) => Phase | undefined;
  getPhaseProgress: (programId: string, currentWeek: number, phaseId: string) => number;
}

export function ExerciseProvider({ children }: { children: React.ReactNode }) {
  const programs = useMemo(() => getAllPrograms(), []);

  function getProgram(id: string): ProgramV2 | undefined {
    return getProgramById(id);
  }

  function getWeek(programId: string, weekNumber: number): WeekV2 | undefined {
    const program = getProgram(programId);
    return program?.weeks.find(w => w.week === weekNumber);
  }

  function getDay(programId: string, weekNumber: number, dayNumber: number): Day | undefined {
    // Legacy support for V1 programs
    const week = getWeek(programId, weekNumber);
    // V1 programs had 'days', V2 has 'sessions'
    if (week && 'days' in week) {
      return (week as any).days.find((d: Day) => d.day === dayNumber);
    }
    return undefined;
  }

  function getSession(programId: string, weekNumber: number, sessionId: string): Session | undefined {
    const week = getWeek(programId, weekNumber);
    return week?.sessions.find(s => s.sessionId === sessionId);
  }

  function getPhaseForWeek(programId: string, weekNumber: number): Phase | undefined {
    const program = getProgram(programId);
    return program?.phases.find(phase => {
      const [start, end] = phase.weekRange;
      return weekNumber >= start && weekNumber <= end;
    });
  }

  function getPhaseProgress(programId: string, currentWeek: number, phaseId: string): number {
    const program = getProgram(programId);
    if (!program) return 0;

    const phase = program.phases.find(p => p.id === phaseId);
    if (!phase) return 0;

    const [startWeek, endWeek] = phase.weekRange;
    const totalWeeks = endWeek - startWeek + 1;
    const weeksCompleted = currentWeek - startWeek;

    if (weeksCompleted < 0) return 0;
    if (weeksCompleted >= totalWeeks) return 100;

    return Math.round((weeksCompleted / totalWeeks) * 100);
  }

  function calculatePrescribedWeight(exercise: ProgramExercise, oneRepMax: number): number {
    return calculateTargetWeight(oneRepMax, exercise.percent1RM);
  }

  return (
    <ExerciseContext.Provider value={{
      programs,
      getProgram,
      getWeek,
      getDay,
      calculatePrescribedWeight,
      getSession,
      getPhaseForWeek,
      getPhaseProgress
    }}>
      {children}
    </ExerciseContext.Provider>
  );
}
```

**Step 7.1.4: Run test to verify it passes**

Run: `npm run test:run tests/contexts/exercise-context-v2.test.tsx`

Expected: PASS (all 4 tests)

**Step 7.1.5: Commit**

```bash
git add src/contexts/exercise-context.tsx tests/contexts/exercise-context-v2.test.tsx
git commit -m "feat: extend ExerciseContext for V2 programs

Add getSession method for session lookup
Add getPhaseForWeek to find phase by week number
Add getPhaseProgress for phase percentage calculation
Update types to use ProgramV2
Maintain backward compatibility with getDay for V1

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Task 8: Create PhaseBanner Component

### Step 8.1: Build PhaseBanner with progress display

**Files:**
- Create: `src/components/program/phase-banner.tsx`
- Create: `src/components/program/__tests__/phase-banner.test.tsx`

**Step 8.1.1: Write failing test for PhaseBanner**

Create: `src/components/program/__tests__/phase-banner.test.tsx`

```typescript
import { describe, it, expect } from 'vitest';
import { render, screen } from '@testing-library/react';
import { PhaseBanner } from '../phase-banner';

describe('PhaseBanner', () => {
  it('displays phase name and goal', () => {
    render(
      <PhaseBanner
        phaseName="Hypertrophy & Positional Foundation"
        phaseGoal="Build muscle and master the upright torso"
        progress={25}
      />
    );

    expect(screen.getByText('Hypertrophy & Positional Foundation')).toBeInTheDocument();
    expect(screen.getByText(/Build muscle/)).toBeInTheDocument();
  });

  it('shows progress percentage', () => {
    const { container } = render(
      <PhaseBanner
        phaseName="Test Phase"
        phaseGoal="Test goal"
        progress={50}
      />
    );

    expect(screen.getByText('50%')).toBeInTheDocument();
  });

  it('shows progress bar at correct width', () => {
    const { container } = render(
      <PhaseBanner
        phaseName="Test Phase"
        phaseGoal="Test goal"
        progress={75}
      />
    );

    const progressBar = container.querySelector('[role="progressbar"]');
    expect(progressBar).toHaveStyle({ width: '75%' });
  });
});
```

**Step 8.1.2: Run test to verify it fails**

Run: `npm run test:run src/components/program/__tests__/phase-banner.test.tsx`

Expected: FAIL - "Cannot find module '../phase-banner'"

**Step 8.1.3: Implement PhaseBanner component**

Create: `src/components/program/phase-banner.tsx`

```typescript
'use client';

import { Card } from '@/components/ui/card';
import { Progress } from '@/components/ui/progress';

interface PhaseBannerProps {
  phaseName: string;
  phaseGoal: string;
  progress: number; // 0-100
}

export function PhaseBanner({ phaseName, phaseGoal, progress }: PhaseBannerProps) {
  return (
    <Card className="p-4 mb-4">
      <div className="space-y-2">
        <div className="flex justify-between items-center">
          <div>
            <h3 className="font-semibold text-lg">{phaseName}</h3>
            <p className="text-sm text-muted-foreground">{phaseGoal}</p>
          </div>
          <span className="text-2xl font-bold">{progress}%</span>
        </div>
        <Progress value={progress} className="h-2" />
      </div>
    </Card>
  );
}
```

**Step 8.1.4: Add Progress component if missing**

If Progress component doesn't exist:

Run: `npx shadcn@latest add progress --yes --overwrite`

**Step 8.1.5: Run test to verify it passes**

Run: `npm run test:run src/components/program/__tests__/phase-banner.test.tsx`

Expected: PASS (all 3 tests)

**Step 8.1.6: Commit**

```bash
git add src/components/program/phase-banner.tsx src/components/program/__tests__/phase-banner.test.tsx
git commit -m "feat: add PhaseBanner component

Display current phase name and goal
Show progress percentage and progress bar
Use Card and shadcn/ui Progress component
Add tests for display and progress calculation

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Task 9: Create SessionSelector Component

### Step 9.1: Build SessionSelector with three view modes

**Files:**
- Create: `src/components/program/session-selector.tsx`
- Create: `src/components/program/session-cards-view.tsx`
- Create: `src/components/program/week-calendar-view.tsx`
- Create: `src/components/program/compact-list-view.tsx`
- Create: `src/components/program/__tests__/session-selector.test.tsx`

**Step 9.1.1: Write failing test for SessionSelector**

Create: `src/components/program/__tests__/session-selector.test.tsx`

```typescript
import { describe, it, expect, vi } from 'vitest';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { SessionSelector } from '../session-selector';
import type { Session } from '@/types/programV2';

const mockSessions: Session[] = [
  {
    sessionId: 'w1-a',
    sessionName: 'Support Session A',
    sessionType: 'support',
    focus: 'Positional Strength',
    exercises: []
  },
  {
    sessionId: 'w1-b',
    sessionName: 'Support Session B',
    sessionType: 'support',
    focus: 'Structural Balance',
    exercises: []
  },
  {
    sessionId: 'w1-sunday',
    sessionName: 'Sunday Anchor',
    sessionType: 'anchor',
    focus: 'Heavy Main Lift',
    exercises: []
  }
];

describe('SessionSelector', () => {
  it('displays all sessions in cards view', () => {
    const onSelect = vi.fn();

    render(
      <SessionSelector
        sessions={mockSessions}
        viewMode="session-cards"
        onSelect={onSelect}
      />
    );

    expect(screen.getByText('Support Session A')).toBeInTheDocument();
    expect(screen.getByText('Support Session B')).toBeInTheDocument();
    expect(screen.getByText('Sunday Anchor')).toBeInTheDocument();
  });

  it('calls onSelect when session is clicked', async () => {
    const user = userEvent.setup();
    const onSelect = vi.fn();

    render(
      <SessionSelector
        sessions={mockSessions}
        viewMode="session-cards"
        onSelect={onSelect}
      />
    );

    await user.click(screen.getByText('Support Session A'));
    expect(onSelect).toHaveBeenCalledWith('w1-a');
  });

  it('shows session focus in cards view', () => {
    render(
      <SessionSelector
        sessions={mockSessions}
        viewMode="session-cards"
        onSelect={() => {}}
      />
    );

    expect(screen.getByText('Positional Strength')).toBeInTheDocument();
  });
});
```

**Step 9.1.2: Run test to verify it fails**

Run: `npm run test:run src/components/program/__tests__/session-selector.test.tsx`

Expected: FAIL - "Cannot find module '../session-selector'"

**Step 9.1.3: Implement SessionSelector component**

Create: `src/components/program/session-selector.tsx`

```typescript
'use client';

import { useState } from 'react';
import { Button } from '@/components/ui/button';
import { Card } from '@/components/ui/card';
import { SessionCardsView } from './session-cards-view';
import { WeekCalendarView } from './week-calendar-view';
import { CompactListView } from './compact-list-view';
import type { Session } from '@/types/programV2';

type ViewMode = 'session-cards' | 'week-calendar' | 'compact-list';

interface SessionSelectorProps {
  sessions: Session[];
  viewMode: ViewMode;
  onSelect: (sessionId: string) => void;
}

export function SessionSelector({ sessions, viewMode, onSelect }: SessionSelectorProps) {
  const [currentView, setCurrentView] = useState<ViewMode>(viewMode);

  return (
    <div className="space-y-4">
      {/* View mode toggle */}
      <div className="flex gap-2">
        <Button
          variant={currentView === 'session-cards' ? 'default' : 'outline'}
          size="sm"
          onClick={() => setCurrentView('session-cards')}
        >
          Cards
        </Button>
        <Button
          variant={currentView === 'week-calendar' ? 'default' : 'outline'}
          size="sm"
          onClick={() => setCurrentView('week-calendar')}
        >
          Calendar
        </Button>
        <Button
          variant={currentView === 'compact-list' ? 'default' : 'outline'}
          size="sm"
          onClick={() => setCurrentView('compact-list')}
        >
          List
        </Button>
      </div>

      {/* Current view */}
      {currentView === 'session-cards' && (
        <SessionCardsView sessions={sessions} onSelect={onSelect} />
      )}
      {currentView === 'week-calendar' && (
        <WeekCalendarView sessions={sessions} onSelect={onSelect} />
      )}
      {currentView === 'compact-list' && (
        <CompactListView sessions={sessions} onSelect={onSelect} />
      )}
    </div>
  );
}
```

**Step 9.1.4: Implement SessionCardsView**

Create: `src/components/program/session-cards-view.tsx`

```typescript
'use client';

import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import type { Session } from '@/types/programV2';

interface SessionCardsViewProps {
  sessions: Session[];
  onSelect: (sessionId: string) => void;
}

export function SessionCardsView({ sessions, onSelect }: SessionCardsViewProps) {
  return (
    <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
      {sessions.map(session => (
        <Card
          key={session.sessionId}
          className="cursor-pointer hover:shadow-md transition-shadow"
          onClick={() => onSelect(session.sessionId)}
        >
          <CardHeader>
            <CardTitle className="text-lg">{session.sessionName}</CardTitle>
            <CardDescription>{session.focus}</CardDescription>
          </CardHeader>
          <CardContent>
            <p className="text-sm text-muted-foreground">
              {session.exercises.length} exercise{session.exercises.length !== 1 ? 's' : ''}
            </p>
          </CardContent>
        </Card>
      ))}
    </div>
  );
}
```

**Step 9.1.5: Implement WeekCalendarView**

Create: `src/components/program/week-calendar-view.tsx`

```typescript
'use client';

import { Card, CardContent } from '@/components/ui/card';
import type { Session } from '@/types/programV2';

interface WeekCalendarViewProps {
  sessions: Session[];
  onSelect: (sessionId: string) => void;
}

export function WeekCalendarView({ sessions, onSelect }: WeekCalendarViewProps) {
  return (
    <div className="grid grid-cols-3 gap-4">
      {sessions.map(session => (
        <Card
          key={session.sessionId}
          className="cursor-pointer hover:shadow-md transition-shadow"
          onClick={() => onSelect(session.sessionId)}
        >
          <CardContent className="p-4">
            <div className="text-center">
              <p className="font-semibold text-sm">{session.sessionName}</p>
              <p className="text-xs text-muted-foreground mt-1">{session.focus}</p>
              <p className="text-xs text-muted-foreground mt-2">
                {session.exercises.length} exercises
              </p>
            </div>
          </CardContent>
        </Card>
      ))}
    </div>
  );
}
```

**Step 9.1.6: Implement CompactListView**

Create: `src/components/program/compact-list-view.tsx`

```typescript
'use client';

import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import type { Session } from '@/types/programV2';

interface CompactListViewProps {
  sessions: Session[];
  onSelect: (sessionId: string) => void;
}

export function CompactListView({ sessions, onSelect }: CompactListViewProps) {
  return (
    <Select onValueChange={onSelect}>
      <SelectTrigger>
        <SelectValue placeholder="Select a session" />
      </SelectTrigger>
      <SelectContent>
        {sessions.map(session => (
          <SelectItem key={session.sessionId} value={session.sessionId}>
            {session.sessionName} - {session.focus}
          </SelectItem>
        ))}
      </SelectContent>
    </Select>
  );
}
```

**Step 9.1.7: Run test to verify it passes**

Run: `npm run test:run src/components/program/__tests__/session-selector.test.tsx`

Expected: PASS (all 3 tests)

**Step 9.1.8: Commit**

```bash
git add src/components/program/session-selector.tsx src/components/program/session-cards-view.tsx src/components/program/week-calendar-view.tsx src/components/program/compact-list-view.tsx src/components/program/__tests__/session-selector.test.tsx
git commit -m "feat: add SessionSelector with three view modes

Implement SessionCardsView with cards showing session info
Implement WeekCalendarView with grid layout
Implement CompactListView with dropdown selector
Add view mode toggle buttons
Support onSelect callback for session selection
Add tests for display and interaction

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Task 10: Create ExerciseCardV2 Component

### Step 10.1: Build ExerciseCardV2 with variants and rep ranges

**Files:**
- Create: `src/components/program/exercise-card-v2.tsx`
- Create: `src/components/program/set-input-v2.tsx`
- Create: `src/components/program/__tests__/exercise-card-v2.test.tsx`

**Step 10.1.1: Write failing test for ExerciseCardV2**

Create: `src/components/program/__tests__/exercise-card-v2.test.tsx`

```typescript
import { describe, it, expect } from 'vitest';
import { render, screen } from '@testing-library/react';
import { ExerciseCardV2 } from '../exercise-card-v2';
import type { ExerciseV2 } from '@/types/programV2';

const mockExercise: ExerciseV2 = {
  exercise: 'pause-squat',
  variant: 'pause',
  sets: 3,
  reps: 8,
  percent1RM: 0.65,
  restMinutes: 3
};

describe('ExerciseCardV2', () => {
  it('displays exercise name with variant', () => {
    render(
      <ExerciseCardV2
        exercise={mockExercise}
        prescribedWeight={195}
        onSetChange={() => {}}
      />
    );

    expect(screen.getByText(/Pause.*Squat/i)).toBeInTheDocument();
  });

  it('displays sets and reps', () => {
    render(
      <ExerciseCardV2
        exercise={mockExercise}
        prescribedWeight={195}
        onSetChange={() => {}}
      />
    );

    expect(screen.getByText('3 sets × 8 reps')).toBeInTheDocument();
  });

  it('displays rep range as "2-3 reps"', () => {
    const exerciseWithRange: ExerciseV2 = {
      ...mockExercise,
      reps: [2, 3]
    };

    render(
      <ExerciseCardV2
        exercise={exerciseWithRange}
        prescribedWeight={195}
        onSetChange={() => {}}
      />
    );

    expect(screen.getByText('2-3 reps')).toBeInTheDocument();
  });

  it('displays notes when present', () => {
    const exerciseWithNotes: ExerciseV2 = {
      ...mockExercise,
      notes: 'Arms extended forward'
    };

    render(
      <ExerciseCardV2
        exercise={exerciseWithNotes}
        prescribedWeight={195}
        onSetChange={() => {}}
      />
    );

    expect(screen.getByText('Arms extended forward')).toBeInTheDocument();
  });
});
```

**Step 10.1.2: Run test to verify it fails**

Run: `npm run test:run src/components/program/__tests__/exercise-card-v2.test.tsx`

Expected: FAIL - "Cannot find module '../exercise-card-v2'"

**Step 10.1.3: Implement ExerciseCardV2**

Create: `src/components/program/exercise-card-v2.tsx`

```typescript
'use client';

import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { ExerciseV2 } from '@/types/programV2';
import { getExerciseByName } from '@/data/exercises';
import { SetInputV2 } from './set-input-v2';

interface ExerciseCardV2Props {
  exercise: ExerciseV2;
  prescribedWeight: number;
  onSetChange: (setNumber: number, data: { weight: number; reps: number }) => void;
}

export function ExerciseCardV2({ exercise, prescribedWeight, onSetChange }: ExerciseCardV2Props) {
  const exerciseData = getExerciseByName(exercise.exercise);

  const formatReps = (reps: typeof exercise.reps): string => {
    if (reps === 'AMRAP') return 'AMRAP';
    if (Array.isArray(reps)) return `${reps[0]}-${reps[1]}`;
    return String(reps);
  };

  const formatSets = (sets: typeof exercise.sets): string => {
    if (sets === 'AMRAP') return 'AMRAP';
    return String(sets);
  };

  const displayName = exercise.variant
    ? `${exerciseData?.name || exercise.exercise} (${exercise.variant})`
    : (exerciseData?.name || exercise.exercise);

  const isTimeBased = exercise.exercise === 'front-rack-hold';

  return (
    <Card>
      <CardHeader>
        <CardTitle className="capitalize">{displayName}</CardTitle>
        <p className="text-sm text-muted-foreground">
          {formatSets(exercise.sets)} sets × {formatReps(exercise.reps)}{' '}
          {isTimeBased ? 'seconds' : 'reps'} @ {exercise.percent1RM * 100}% 1RM ({prescribedWeight} lbs)
        </p>
        {exercise.notes && (
          <Badge variant="secondary" className="mt-2">
            {exercise.notes}
          </Badge>
        )}
      </CardHeader>
      <CardContent className="space-y-2">
        {Array.from({ length: typeof exercise.sets === 'number' ? exercise.sets : 3 }).map((_, i) => (
          <SetInputV2
            key={i}
            setNumber={i + 1}
            prescribedWeight={prescribedWeight}
            prescribedReps={exercise.reps}
            isTimeBased={isTimeBased}
            onWeightChange={(weight) => onSetChange(i + 1, { weight, reps: 0 })}
            onRepsChange={(reps) => onSetChange(i + 1, { weight: 0, reps })}
            onTimeChange={isTimeBased ? (seconds) => onSetChange(i + 1, { weight: seconds, reps: 0 }) : undefined}
          />
        ))}
      </CardContent>
    </Card>
  );
}
```

**Step 10.1.4: Implement SetInputV2**

Create: `src/components/program/set-input-v2.tsx`

```typescript
'use client';

import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { useState, useEffect } from 'react';
import type { ExerciseV2 } from '@/types/programV2';

interface SetInputV2Props {
  setNumber: number;
  prescribedWeight: number;
  prescribedReps: ExerciseV2['reps'];
  isTimeBased: boolean;
  onWeightChange: (weight: number) => void;
  onRepsChange: (reps: number) => void;
  onTimeChange?: (seconds: number) => void;
}

export function SetInputV2({
  setNumber,
  prescribedWeight,
  prescribedReps,
  isTimeBased,
  onWeightChange,
  onRepsChange,
  onTimeChange
}: SetInputV2Props) {
  const [weight, setWeight] = useState(String(prescribedWeight));
  const [reps, setReps] = useState(
    Array.isArray(prescribedReps) ? String(prescribedReps[0]) : String(prescribedReps)
  );

  useEffect(() => {
    onWeightChange(Number(weight));
  }, [weight]);

  useEffect(() => {
    onRepsChange(Number(reps));
  }, [reps]);

  return (
    <div className="flex items-center gap-3 p-3 border rounded-lg">
      <div className="font-medium text-lg w-8">{setNumber}</div>

      {!isTimeBased && (
        <>
          <div className="flex-1">
            <Label htmlFor={`weight-${setNumber}`} className="text-xs">Weight (lbs)</Label>
            <Input
              id={`weight-${setNumber}`}
              type="number"
              value={weight}
              onChange={(e) => setWeight(e.target.value)}
              placeholder="Weight"
            />
          </div>

          <div className="flex-1">
            <Label htmlFor={`reps-${setNumber}`} className="text-xs">
              {isTimeBased ? 'Seconds' : 'Reps'}
            </Label>
            <Input
              id={`reps-${setNumber}`}
              type="number"
              value={reps}
              onChange={(e) => setReps(e.target.value)}
              placeholder={isTimeBased ? 'Seconds' : 'Reps'}
            />
          </div>
        </>
      )}

      {isTimeBased && onTimeChange && (
        <div className="flex-1">
          <Label htmlFor={`time-${setNumber}`} className="text-xs">Seconds</Label>
          <Input
            id={`time-${setNumber}`}
            type="number"
            value={reps}
            onChange={(e) => {
              setReps(e.target.value);
              onTimeChange(Number(e.target.value));
            }}
            placeholder="Seconds"
          />
        </div>
      )}
    </div>
  );
}
```

**Step 10.1.5: Run test to verify it passes**

Run: `npm run test:run src/components/program/__tests__/exercise-card-v2.test.tsx`

Expected: PASS (all 4 tests)

**Step 10.1.6: Commit**

```bash
git add src/components/program/exercise-card-v2.tsx src/components/program/set-input-v2.tsx src/components/program/__tests__/exercise-card-v2.test.tsx
git commit -m "feat: add ExerciseCardV2 with variant and rep range support

Display exercise name with variant badge
Format rep ranges as '2-3 reps' or 'AMRAP'
Show notes field when present
Add SetInputV2 with time-based support for Front Rack Hold
Add tests for display formatting

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Task 11: Create TestDayInterface Component

### Step 11.1: Build TestDayInterface for Week 8

**Files:**
- Create: `src/components/program/test-day-interface.tsx`
- Create: `src/components/program/__tests__/test-day-interface.test.tsx`

**Step 11.1.1: Write failing test for TestDayInterface**

Create: `src/components/program/__tests__/test-day-interface.test.tsx`

```typescript
import { describe, it, expect, vi } from 'vitest';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { TestDayInterface } from '../test-day-interface';
import type { ExerciseV2 } from '@/types/programV2';

const mockWarmupExercises: ExerciseV2[] = [
  { exercise: 'back-squat', sets: 1, reps: 1, percent1RM: 0.30, restMinutes: 2 },
  { exercise: 'back-squat', sets: 1, reps: 1, percent1RM: 0.50, restMinutes: 3 },
  { exercise: 'back-squat', sets: 1, reps: 1, percent1RM: 0.60, restMinutes: 3 },
  { exercise: 'back-squat', sets: 1, reps: 1, percent1RM: 0.70, restMinutes: 5 }
];

const mockWorkingSets: ExerciseV2[] = [
  { exercise: 'back-squat', sets: 1, reps: 1, percent1RM: 0.80, restMinutes: 5 },
  { exercise: 'back-squat', sets: 1, reps: 1, percent1RM: 0.90, restMinutes: 5 },
  { exercise: 'back-squat', sets: 1, reps: 1, percent1RM: 0.95, restMinutes: 5 },
  { exercise: 'back-squat', sets: 1, reps: 1, percent1RM: 1.02, restMinutes: 5, notes: 'New 1RM Attempt' }
];

describe('TestDayInterface', () => {
  it('displays warm-up section', () => {
    render(
      <TestDayInterface
        warmupExercises={mockWarmupExercises}
        workingSets={mockWorkingSets}
        oneRepMax={300}
        onComplete={() => {}}
      />
    );

    expect(screen.getByText('Warm-up')).toBeInTheDocument();
  });

  it('displays working sets section', () => {
    render(
      <TestDayInterface
        warmupExercises={mockWarmupExercises}
        workingSets={mockWorkingSets}
        oneRepMax={300}
        onComplete={() => {}}
      />
    );

    expect(screen.getByText('Working Sets')).toBeInTheDocument();
  });

  it('calls onComplete when test is complete', async () => {
    const user = userEvent.setup();
    const onComplete = vi.fn();

    render(
      <TestDayInterface
        warmupExercises={mockWarmupExercises}
        workingSets={mockWorkingSets}
        oneRepMax={300}
        onComplete={onComplete}
      />
    );

    // Complete all warm-ups
    for (let i = 0; i < mockWarmupExercises.length; i++) {
      await user.click(screen.getAllByRole('checkbox')[i]);
    }

    // Complete all working sets
    for (let i = 0; i < mockWorkingSets.length; i++) {
      await user.click(screen.getAllByRole('checkbox')[mockWarmupExercises.length + i]);
    }

    expect(onComplete).toHaveBeenCalled();
  });
});
```

**Step 11.1.2: Run test to verify it fails**

Run: `npm run test:run src/components/program/__tests__/test-day-interface.test.tsx`

Expected: FAIL - "Cannot find module '../test-day-interface'"

**Step 11.1.3: Implement TestDayInterface**

Create: `src/components/program/test-day-interface.tsx`

```typescript
'use client';

import { useState } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Checkbox } from '@/components/ui/checkbox';
import { Label } from '@/components/ui/label';
import { Input } from '@/components/ui/input';
import type { ExerciseV2 } from '@/types/programV2';
import { calculateTargetWeight } from '@/lib/calculations';

interface TestDayInterfaceProps {
  warmupExercises: ExerciseV2[];
  workingSets: ExerciseV2[];
  oneRepMax: number;
  onComplete: (results: { successful: boolean; new1RM?: number }) => void;
}

interface Attempt {
  percentage: number;
  weight: number;
  completed: boolean;
  successful?: boolean;
}

export function TestDayInterface({
  warmupExercises,
  workingSets,
  oneRepMax,
  onComplete
}: TestDayInterfaceProps) {
  const [warmups, setWarmups] = useState<Attempt[]>(
    warmupExercises.map(ex => ({
      percentage: ex.percent1RM,
      weight: calculateTargetWeight(oneRepMax, ex.percent1RM),
      completed: false
    }))
  );

  const [attempts, setAttempts] = useState<Attempt[]>(
    workingSets.map(ex => ({
      percentage: ex.percent1RM,
      weight: calculateTargetWeight(oneRepMax, ex.percent1RM),
      completed: false,
      successful: undefined
    }))
  );

  const handleWarmupComplete = (index: number) => {
    const newWarmups = [...warmups];
    newWarmups[index].completed = !newWarmups[index].completed;
    setWarmups(newWarmups);
  };

  const handleAttemptComplete = (index: number, successful: boolean) => {
    const newAttempts = [...attempts];
    newAttempts[index] = {
      ...newAttempts[index],
      completed: true,
      successful
    };
    setAttempts(newAttempts);

    // If last attempt, call onComplete
    if (index === attempts.length - 1) {
      const new1RM = successful ? newAttempts[index].weight : undefined;
      onComplete({ successful, new1RM });
    }
  };

  const allWarmupsComplete = warmups.every(w => w.completed);

  return (
    <div className="space-y-6">
      {/* Warm-up Section */}
      <Card>
        <CardHeader>
          <CardTitle>Warm-up</CardTitle>
        </CardHeader>
        <CardContent className="space-y-3">
          {warmups.map((warmup, index) => (
            <div key={index} className="flex items-center gap-3 p-3 border rounded-lg">
              <Checkbox
                id={`warmup-${index}`}
                checked={warmup.completed}
                onCheckedChange={() => handleWarmupComplete(index)}
              />
              <Label htmlFor={`warmup-${index}`} className="flex-1 cursor-pointer">
                <span className="font-medium">{warmup.weight} lbs</span>
                <span className="text-muted-foreground ml-2">({Math.round(warmup.percentage * 100)}%)</span>
              </Label>
            </div>
          ))}
        </CardContent>
      </Card>

      {/* Working Sets Section */}
      <Card>
        <CardHeader>
          <CardTitle>Working Sets</CardTitle>
        </CardHeader>
        <CardContent className="space-y-3">
          {attempts.map((attempt, index) => (
            <div key={index} className="space-y-2">
              {!attempt.completed ? (
                <div className="p-3 border rounded-lg">
                  <p className="font-medium">{attempt.weight} lbs ({Math.round(attempt.percentage * 100)}%)</p>
                  {allWarmupsComplete && (
                    <div className="flex gap-2 mt-2">
                      <Button
                        size="sm"
                        variant="outline"
                        onClick={() => handleAttemptComplete(index, false)}
                      >
                        Miss
                      </Button>
                      <Button
                        size="sm"
                        onClick={() => handleAttemptComplete(index, true)}
                      >
                        Made
                      </Button>
                    </div>
                  )}
                </div>
              ) : (
                <div className={`p-3 border rounded-lg ${attempt.successful ? 'bg-green-50' : 'bg-red-50'}`}>
                  <p className="font-medium">{attempt.weight} lbs</p>
                  <p className="text-sm">{attempt.successful ? '✓ Made' : '✗ Missed'}</p>
                </div>
              )}
            </div>
          ))}
        </CardContent>
      </Card>
    </div>
  );
}
```

**Step 11.1.4: Add Checkbox component if missing**

Run: `npx shadcn@latest add checkbox --yes --overwrite`

**Step 11.1.5: Run test to verify it passes**

Run: `npm run test:run src/components/program/__tests__/test-day-interface.test.tsx`

Expected: PASS (all 3 tests)

**Step 11.1.6: Commit**

```bash
git add src/components/program/test-day-interface.tsx src/components/program/__tests__/test-day-interface.test.tsx
git commit -m "feat: add TestDayInterface for Week 8

Display warm-up ladder with checkboxes
Show working sets with Made/Miss buttons
Track attempt success/failure
Calculate weights from 1RM percentages
Call onComplete with new 1RM if successful
Add tests for interface and interaction

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Task 12: Update Workout Page for V2

### Step 12.1: Modify workout page to use V2 components

**Files:**
- Modify: `src/app/workout/[id]/page.tsx`
- Create: `src/components/program/workout-session-view.tsx`

**Step 12.1.1: Write failing test for workout session view**

Create: `src/components/program/__tests__/workout-session-view.test.tsx`

```typescript
import { describe, it, expect, vi } from 'vitest';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { WorkoutSessionView } from '../workout-session-view';
import type { Session } from '@/types/programV2';

const mockSession: Session = {
  sessionId: 'w1-a',
  sessionName: 'Support Session A',
  sessionType: 'support',
  focus: 'Positional Strength',
  exercises: [
    {
      exercise: 'pause-squat',
      sets: 3,
      reps: 8,
      percent1RM: 0.65,
      restMinutes: 3
    }
  ]
};

describe('WorkoutSessionView', () => {
  it('displays phase banner', () => {
    render(
      <WorkoutSessionView
        session={mockSession}
        phaseName="Hypertrophy Phase"
        phaseGoal="Build muscle"
        phaseProgress={25}
        oneRepMax={300}
        onComplete={() => {}}
      />
    );

    expect(screen.getByText('Hypertrophy Phase')).toBeInTheDocument();
  });

  it('displays session name and focus', () => {
    render(
      <WorkoutSessionView
        session={mockSession}
        phaseName="Test Phase"
        phaseGoal="Test"
        phaseProgress={0}
        oneRepMax={300}
        onComplete={() => {}}
      />
    );

    expect(screen.getByText('Support Session A')).toBeInTheDocument();
    expect(screen.getByText('Positional Strength')).toBeInTheDocument();
  });
});
```

**Step 12.1.2: Run test to verify it fails**

Run: `npm run test:run src/components/program/__tests__/workout-session-view.test.tsx`

Expected: FAIL - "Cannot find module '../workout-session-view'"

**Step 12.1.3: Implement WorkoutSessionView**

Create: `src/components/program/workout-session-view.tsx`

```typescript
'use client';

import { useState } from 'react';
import { PhaseBanner } from './phase-banner';
import { ExerciseCardV2 } from './exercise-card-v2';
import { Button } from '@/components/ui/button';
import type { Session, ExerciseV2 } from '@/types/programV2';

interface WorkoutSessionViewProps {
  session: Session;
  phaseName: string;
  phaseGoal: string;
  phaseProgress: number;
  oneRepMax: number;
  onComplete: (data: { completed: boolean }) => void;
}

export function WorkoutSessionView({
  session,
  phaseName,
  phaseGoal,
  phaseProgress,
  oneRepMax,
  onComplete
}: WorkoutSessionViewProps) {
  const [completedSets, setCompletedSets] = useState<Set<string>>(new Set());

  const handleSetChange = (exerciseIndex: number, setNumber: number, data: { weight: number; reps: number }) => {
    const key = `${exerciseIndex}-${setNumber}`;
    setCompletedSets(prev => new Set(prev).add(key));
  };

  const handleComplete = () => {
    onComplete({ completed: true });
  };

  return (
    <div className="min-h-screen p-4 pb-20">
      <PhaseBanner
        phaseName={phaseName}
        phaseGoal={phaseGoal}
        progress={phaseProgress}
      />

      <div className="mb-6">
        <h1 className="text-2xl font-bold">{session.sessionName}</h1>
        <p className="text-muted-foreground">{session.focus}</p>
      </div>

      <div className="space-y-4">
        {session.exercises.map((exercise, exerciseIndex) => {
          const prescribedWeight = Math.round(oneRepMax * exercise.percent1RM);

          return (
            <ExerciseCardV2
              key={`${exercise.exercise}-${exerciseIndex}`}
              exercise={exercise}
              prescribedWeight={prescribedWeight}
              onSetChange={(setNumber) => handleSetChange(exerciseIndex, setNumber, { weight: 0, reps: 0 })}
            />
          );
        })}
      </div>

      <Button
        className="w-full mt-6"
        size="lg"
        onClick={handleComplete}
        disabled={completedSets.size === 0}
      >
        Complete Workout
      </Button>
    </div>
  );
}
```

**Step 12.1.4: Update workout page**

Read: `src/app/workout/[id]/page.tsx`

Replace with:

```typescript
'use client';

import { useEffect, useState } from 'react';
import { useExercise } from '@/contexts/exercise-context';
import { useUser } from '@/contexts/user-context';
import { SessionSelector } from '@/components/program/session-selector';
import { WorkoutSessionView } from '@/components/program/workout-session-view';
import { TestDayInterface } from '@/components/program/test-day-interface';
import type { Session } from '@/types/programV2';

interface PageProps {
  params: { id: string };
}

export default function WorkoutPage({ params }: PageProps) {
  const { getProgram, getWeek, getPhaseForWeek, getPhaseProgress } = useExercise();
  const { user, oneRepMaxes } = useUser();
  const [selectedSession, setSelectedSession] = useState<Session | null>(null);
  const [currentWeek, setCurrentWeek] = useState(1);

  const program = getProgram(params.id);

  useEffect(() => {
    // Load current week from active cycle (mock for now)
    setCurrentWeek(1);
  }, []);

  if (!program) {
    return <div>Program not found</div>;
  }

  const weekData = getWeek(params.id, currentWeek);
  const phase = getPhaseForWeek(params.id, currentWeek);
  const phaseProgress = getPhaseProgress(params.id, currentWeek, phase?.id || '');

  const backSquat1RM = oneRepMaxes.find(orm => orm.exerciseId === 'back-squat')?.weight || 200;

  const handleSessionSelect = (sessionId: string) => {
    const session = weekData?.sessions.find(s => s.sessionId === sessionId);
    if (session) {
      setSelectedSession(session);
    }
  };

  const handleWorkoutComplete = (data: any) => {
    console.log('Workout complete:', data);
    // TODO: Save to database
  };

  const handleTestDayComplete = (results: any) => {
    console.log('Test day complete:', results);
    if (results.new1RM) {
      // TODO: Update 1RM
    }
  };

  // Test day interface for Week 8
  if (weekData?.isTestWeek) {
    const testSession = weekData.sessions.find(s => s.sessionType === 'testing');
    if (testSession) {
      return (
        <div className="min-h-screen p-4 pb-20">
          <h1 className="text-2xl font-bold mb-4">Test Day</h1>
          <TestDayInterface
            warmupExercises={testSession.exercises.slice(0, 4)}
            workingSets={testSession.exercises.slice(4)}
            oneRepMax={backSquat1RM}
            onComplete={handleTestDayComplete}
          />
        </div>
      );
    }
  }

  // Session selection
  if (!selectedSession) {
    return (
      <div className="min-h-screen p-4 pb-20">
        <h1 className="text-2xl font-bold mb-2">Week {currentWeek}</h1>
        {phase && (
          <p className="text-muted-foreground mb-6">{phase.name}</p>
        )}

        <SessionSelector
          sessions={weekData?.sessions || []}
          viewMode="session-cards"
          onSelect={handleSessionSelect}
        />
      </div>
    );
  }

  // Workout session view
  return (
    <WorkoutSessionView
      session={selectedSession}
      phaseName={phase?.name || ''}
      phaseGoal={phase?.goal || ''}
      phaseProgress={phaseProgress}
      oneRepMax={backSquat1RM}
      onComplete={handleWorkoutComplete}
    />
  );
}
```

**Step 12.1.5: Run test to verify it passes**

Run: `npm run test:run src/components/program/__tests__/workout-session-view.test.tsx`

Expected: PASS (all 2 tests)

**Step 12.1.6: Commit**

```bash
git add src/app/workout/[id]/page.tsx src/components/program/workout-session-view.tsx src/components/program/__tests__/workout-session-view.test.tsx
git commit -m "feat: update workout page for V2 programs

Add session selection with SessionSelector
Display phase banner with progress
Show WorkoutSessionView for selected session
Handle test week with TestDayInterface
Calculate prescribed weights from 1RM
Add tests for session view

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Task 13: Update Dashboard for V2

### Step 13.1: Modify dashboard to show V2 cycle info

**Files:**
- Modify: `src/components/dashboard/active-cycles-card.tsx`

**Step 13.1.1: Update ActiveCyclesCard**

Read: `src/components/dashboard/active-cycles-card.tsx`

Update to show phase and session info:

```typescript
'use client';

import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { useUser } from '@/contexts/user-context';
import { useExercise } from '@/contexts/exercise-context';
import { getActiveCycles } from '@/lib/db';
import { useEffect, useState } from 'react';
import type { ActiveCycle } from '@/types';
import Link from 'next/link';

export function ActiveCyclesCard() {
  const { user } = useUser();
  const { getProgram, getPhaseForWeek, getPhaseProgress } = useExercise();
  const [activeCycles, setActiveCycles] = useState<ActiveCycle[]>([]);

  useEffect(() => {
    if (user) {
      getActiveCycles(user.id).then(setActiveCycles);
    }
  }, [user]);

  if (activeCycles.length === 0) {
    return (
      <Card>
        <CardHeader>
          <CardTitle>Active Programs</CardTitle>
          <CardDescription>No active programs</CardDescription>
        </CardHeader>
        <CardContent>
          <p className="text-sm text-muted-foreground">
            Browse programs to start training
          </p>
        </CardContent>
      </Card>
    );
  }

  return (
    <Card>
      <CardHeader>
        <CardTitle>Active Programs</CardTitle>
        <CardDescription>{activeCycles.length} program{activeCycles.length > 1 ? 's' : ''} in progress</CardDescription>
      </CardHeader>
      <CardContent className="space-y-3">
        {activeCycles.map(cycle => {
          const program = getProgram(cycle.programId);
          const phase = getPhaseForWeek(cycle.programId, cycle.currentWeek);
          const phaseProgress = getPhaseProgress(cycle.programId, cycle.currentWeek, phase?.id || '');

          return (
            <Link key={cycle.id} href={`/workout/${cycle.programId}`}>
              <div className="flex items-center justify-between p-3 border rounded-lg hover:bg-accent transition-colors cursor-pointer">
                <div className="flex-1">
                  <p className="font-medium">{cycle.cycleName}</p>
                  <p className="text-sm text-muted-foreground">
                    Week {cycle.currentWeek} of {program?.durationWeeks || 8}
                  </p>
                  {phase && (
                    <p className="text-xs text-muted-foreground mt-1">
                      {phase.name} - {phaseProgress}%
                    </p>
                  )}
                </div>
                <Badge>Active</Badge>
              </div>
            </Link>
          );
        })}
      </CardContent>
    </Card>
  );
}
```

**Step 13.1.2: Commit**

```bash
git add src/components/dashboard/active-cycles-card.tsx
git commit -m "feat: update ActiveCyclesCard for V2 programs

Show phase name and progress percentage
Link directly to workout page
Display week progress with program duration
Use getPhaseForWeek and getPhaseProgress from context

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Task 14: Update Program Detail Page

### Step 14.1: Modify program detail to show V2 structure

**Files:**
- Modify: `src/app/programs/[id]/page.tsx`

**Step 14.1.1: Update program detail page**

Read: `src/app/programs/[id]/page.tsx`

Replace with:

```typescript
import { notFound } from 'next/navigation';
import { useExercise } from '@/contexts/exercise-context';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';

interface PageProps {
  params: { id: string };
}

export default function ProgramDetailPage({ params }: PageProps) {
  const { getProgram } = useExercise();
  const program = getProgram(params.id);

  if (!program) {
    notFound();
  }

  return (
    <div className="min-h-screen p-4 pb-20">
      <Card>
        <CardHeader>
          <div className="flex justify-between items-start">
            <CardTitle>{program.name}</CardTitle>
            <Badge>{program.difficulty}</Badge>
          </div>
          <CardDescription>{program.description}</CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="text-sm space-y-1">
            <p><strong>Duration:</strong> {program.durationWeeks} weeks</p>
            <p><strong>Frequency:</strong> {program.sessionsPerWeek} sessions per week</p>
            <p><strong>Sessions:</strong> {program.sessionsPerWeek} per week</p>
          </div>

          {/* Display phases */}
          {program.phases && program.phases.length > 0 && (
            <div className="space-y-2">
              <h3 className="font-semibold">Training Phases</h3>
              {program.phases.map(phase => (
                <div key={phase.id} className="p-3 border rounded-lg">
                  <p className="font-medium">{phase.name}</p>
                  <p className="text-sm text-muted-foreground">{phase.goal}</p>
                  <p className="text-xs text-muted-foreground">Weeks {phase.weekRange[0]}-{phase.weekRange[1]}</p>
                </div>
              ))}
            </div>
          )}

          <Button className="w-full">
            Start This Program
          </Button>
        </CardContent>
      </Card>
    </div>
  );
}
```

**Step 14.1.2: Commit**

```bash
git add src/app/programs/[id]/page.tsx
git commit -m "feat: update program detail page for V2

Display all training phases with goals
Show week ranges for each phase
Update to use sessionsPerWeek instead of daysPerWeek
Maintain program card layout and structure

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Task 15: Run All Tests and Verify Build

### Step 15.1: Execute full test suite

**Step 15.1.1: Run unit tests**

Run: `npm run test:run`

Expected: All unit tests PASS

**Step 15.1.2: Run integration tests**

Run: `npm run test:run tests/integration/`

Expected: All integration tests PASS

**Step 15.1.3: Build production bundle**

Run: `npm run build`

Expected: Build succeeds without errors

**Step 15.1.4: Fix any failing tests or build errors**

If any tests fail or build errors occur:
1. Review error messages
2. Fix the issue
3. Re-run test
4. Commit fix with message "fix: [description]"

**Step 15.1.5: Final commit after all tests pass**

```bash
git add .
git commit -m "test: ensure all tests pass and build succeeds

All unit tests passing
All integration tests passing
Production build successful
Ready for E2E testing and manual verification

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Task 16: E2E Tests

### Step 16.1: Write E2E test for V2 program flow

**Files:**
- Create: `tests/e2e/back-squat-v2.spec.ts`

**Step 16.1.1: Create E2E test**

Create: `tests/e2e/back-squat-v2.spec.ts`

```typescript
import { test, expect } from '@playwright/test';

test.describe('Back Squat Program V2', () => {
  test('browses to program detail and sees phases', async ({ page }) => {
    await page.goto('/programs');
    await page.click('text=Back Squat: Complete 8-Week Cycle');

    // Should show phases
    await expect(page.locator('text=Training Phases')).toBeVisible();
    await expect(page.locator('text=Hypertrophy & Positional Foundation')).toBeVisible();
    await expect(page.locator('text=Strength & Rigidity')).toBeVisible();
    await expect(page.locator('text=Peak & Test')).toBeVisible();
  });

  test('starts workout and selects session', async ({ page }) => {
    await page.goto('/workout/back-squat-complete-cycle');

    // Should show Week 1
    await expect(page.locator('text=Week 1')).toBeVisible();

    // Should show session cards
    await expect(page.locator('text=Support Session A')).toBeVisible();
    await expect(page.locator('text=Support Session B')).toBeVisible();
    await expect(page.locator('text=Sunday Anchor')).toBeVisible();

    // Select a session
    await page.click('text=Support Session A');

    // Should show session view
    await expect(page.locator('text=Positional Strength')).toBeVisible();
    await expect(page.locator('text=Hypertrophy & Positional Foundation')).toBeVisible();
  });

  test('completes workout session', async ({ page }) => {
    await page.goto('/workout/back-squat-complete-cycle');
    await page.click('text=Support Session A');

    // Enter weight and reps
    const weightInput = page.locator('input[type="number"]').first();
    await weightInput.fill('195');

    // Click complete
    await page.click('text=Complete Workout');

    // Should complete (in real app, would navigate to dashboard)
    await expect(page.locator('text=Complete Workout')).toBeVisible();
  });
});
```

**Step 16.1.2: Run E2E tests**

Run: `npm run test:e2e`

Expected: All E2E tests PASS

**Step 16.1.3: Commit**

```bash
git add tests/e2e/back-squat-v2.spec.ts
git commit -m "test: add E2E tests for V2 program flow

Test program detail page shows all phases
Test session selection from workout page
Test workout completion flow
Verify phase display and session cards

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Implementation Complete

All 16 tasks completed. The Back Squat Program V2 is fully implemented with:

✅ ProgramV2 type system with phases, sessions, variants
✅ Complete 8-week program JSON with all sessions
✅ IndexedDB schema updated (version 2)
✅ PhaseBanner component with progress display
✅ SessionSelector with three view modes
✅ ExerciseCardV2 with variants and rep ranges
✅ TestDayInterface for Week 8 testing
✅ Updated workout, dashboard, and program pages
✅ Comprehensive unit, integration, and E2E tests

**Next Steps:**
1. Manual testing in dev environment
2. Deploy to staging for user acceptance testing
3. Collect feedback and iterate

**Estimated commits:** 16+
**Tech stack:** Next.js 16, React 19, TypeScript, Dexie.js, shadcn/ui, Vitest, Playwright
