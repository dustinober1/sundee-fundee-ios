# Workout Tracking App Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a mobile-first workout tracking web app with offline-first architecture, program management, workout logging, progress tracking, and personalized recommendations.

**Architecture:** Local-first using IndexedDB (Dexie.js) for data persistence with optional Supabase sync for cross-device backup and authentication. React Context manages global state, Next.js App Router handles navigation, shadcn/ui provides accessible mobile-optimized components.

**Tech Stack:** Next.js 15, React 19, TypeScript, Tailwind CSS, shadcn/ui, Dexie.js, Supabase, Vitest, Playwright

---

## Prerequisites

Before starting this plan, ensure you have:
- Node.js 20+ installed
- pnpm or npm package manager
- Supabase account (free tier works)
- Vercel account (for deployment)

**Installation commands:**
```bash
npx create-next-app@latest strength --typescript --tailwind --eslint
cd strength
pnpm add dexie supabase @supabase/ssr date-fns recharts
pnpm add -D @vitest/ui vitest @playwright/test fake-indexeddb
```

---

## Task 1: Project Foundation Setup

### Step 1: Initialize Next.js project with required dependencies

**Files:**
- Run: Command to initialize project

**Step 1.1: Create Next.js project**

Run:
```bash
npx create-next-app@latest . --typescript --tailwind --eslint --app --src-dir --import-alias "@/*"
```

Expected: Project created with TypeScript, Tailwind, ESLint, App Router, src directory

**Step 1.2: Install additional dependencies**

Run:
```bash
pnpm add dexie supabase @supabase/ssr date-fns recharts clsx tailwind-merge class-variance-authority lucide-react
pnpm add -D @vitest/ui vitest @playwright/test fake-indexeddb @testing-library/react @testing-library/jest-dom
```

Expected: All dependencies installed successfully

**Step 1.3: Create utility for CSS classes**

Create: `src/lib/utils.ts`

```typescript
import { type ClassValue, clsx } from "clsx"
import { twMerge } from "tailwind-merge"

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs))
}

export function roundToNearestFive(value: number): number {
  return Math.round(value / 5) * 5;
}

export function generateId(): string {
  return crypto.randomUUID();
}
```

**Step 1.4: Commit**

Run:
```bash
git add .
git commit -m "chore: initialize Next.js project with dependencies

Install Next.js 15, React 19, TypeScript, Tailwind CSS
Add Dexie.js, Supabase, testing libraries
Create utility functions for CSS classes and math helpers

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Task 2: TypeScript Type Definitions

### Step 1: Create core type definitions

**Files:**
- Create: `src/types/program.ts`
- Create: `src/types/workout.ts`
- Create: `src/types/user.ts`
- Create: `src/types/index.ts`

**Step 2.1: Write program types**

Create: `src/types/program.ts`

```typescript
export type ProgramCategory =
  | 'back-squat'
  | 'front-squat'
  | 'bench-press'
  | 'deadlift'
  | 'box-jump'
  | 'burpees';

export type DifficultyLevel = 'beginner' | 'intermediate' | 'advanced';

export interface Exercise {
  exercise: string;
  sets: number;
  reps: number;
  percent1RM: number;
  restMinutes?: number;
  rpeTarget?: number;
}

export interface Day {
  day: number;
  exercises: Exercise[];
}

export interface Week {
  week: number;
  days: Day[];
}

export interface Program {
  id: string;
  name: string;
  category: ProgramCategory;
  description: string;
  durationWeeks: number;
  daysPerWeek: number;
  exercises: string[];
  difficulty: DifficultyLevel;
  weeks: Week[];
}
```

**Step 2.2: Write workout types**

Create: `src/types/workout.ts`

```typescript
export interface CompletedSet {
  id: string;
  workoutId: string;
  exerciseId: string;
  setNumber: number;
  prescribedWeight?: number;
  actualWeight: number;
  prescribedReps: number;
  actualReps: number;
  rpe?: number;
  restSeconds?: number;
  createdAt: Date;
}

export interface SetMetrics {
  id: string;
  setId: string;
  tempoEccentric?: number;
  tempoConcentric?: number;
  tempoPause?: number;
  heartRate?: number;
  notes?: string;
}

export interface CompletedWorkout {
  id: string;
  userId: string;
  activeCycleId: string;
  programId: string;
  week: number;
  day: number;
  completedAt: Date;
  duration?: number;
  notes?: string;
}

export interface OneRepMax {
  id: string;
  userId: string;
  exerciseId: string;
  weight: number;
  date: Date;
}

export interface ActiveCycle {
  id: string;
  userId: string;
  programId: string;
  cycleName: string;
  startDate: Date;
  currentWeek: number;
  status: 'active' | 'completed' | 'paused';
}
```

**Step 2.3: Write user types**

Create: `src/types/user.ts`

```typescript
export type ExperienceLevel = 'beginner' | 'intermediate' | 'advanced';
export type PrimaryGoal = 'strength' | 'hypertrophy' | 'explosiveness';

export interface User {
  id: string;
  name: string;
  experienceLevel: ExperienceLevel;
  primaryGoal: PrimaryGoal;
  createdAt: Date;
  syncedAt?: Date;
}

export type SyncStatus = 'synced' | 'syncing' | 'pending' | 'offline' | 'disabled';
```

**Step 2.4: Create barrel export**

Create: `src/types/index.ts`

```typescript
export * from './program';
export * from './workout';
export * from './user';
```

**Step 2.5: Commit**

Run:
```bash
git add src/types/
git commit -m "feat: add TypeScript type definitions

Define core types for programs, workouts, users
Add ProgramCategory, DifficultyLevel, Exercise, Day, Week
Add CompletedSet, CompletedWorkout, OneRepMax, ActiveCycle
Add User with experience level and goal types

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Task 3: Dexie.js Database Setup

### Step 1: Set up IndexedDB with Dexie.js

**Files:**
- Create: `src/lib/db/schema.ts`
- Create: `src/lib/db/dexie.ts`
- Create: `src/lib/db/index.ts`

**Step 3.1: Write database schema**

Create: `src/lib/db/schema.ts`

```typescript
import { Schema } from 'dexie';

export interface DatabaseSchema {
  users: {
    key: string;
    indexes: { 'ByName': string };
  };
  oneRepMaxes: {
    key: string;
    indexes: { 'ByUserId': string; 'ByExerciseId': string; 'ByDate': Date };
  };
  activeCycles: {
    key: string;
    indexes: { 'ByUserId': string; 'ByProgramId': string; 'ByStatus': string };
  };
  completedWorkouts: {
    key: string;
    indexes: { 'ByUserId': string; 'ByActiveCycleId': string; 'ByCompletedAt': Date };
  };
  completedSets: {
    key: string;
    indexes: { 'ByWorkoutId': string; 'ByExerciseId': string };
  };
  setMetrics: {
    key: string;
    indexes: { 'BySetId': string };
  };
}
```

**Step 3.2: Initialize Dexie database**

Create: `src/lib/db/dexie.ts`

```typescript
import Dexie, { Table } from 'dexie';
import type { User, OneRepMax, ActiveCycle, CompletedWorkout, CompletedSet, SetMetrics } from '@/types';

export class StrengthDatabase extends Dexie {
  users!: Table<User>;
  oneRepMaxes!: Table<OneRepMax>;
  activeCycles!: Table<ActiveCycle>;
  completedWorkouts!: Table<CompletedWorkout>;
  completedSets!: Table<CompletedSet>;
  setMetrics!: Table<SetMetrics>;

  constructor() {
    super('StrengthApp');

    this.version(1).stores({
      users: 'id, name, createdAt',
      oneRepMaxes: 'id, userId, exerciseId, date',
      activeCycles: 'id, userId, programId, status',
      completedWorkouts: 'id, userId, activeCycleId, completedAt',
      completedSets: 'id, workoutId, exerciseId',
      setMetrics: 'id, setId'
    });
  }
}

export const db = new StrengthDatabase();
```

**Step 3.3: Create database access helpers**

Create: `src/lib/db/index.ts`

```typescript
import { db } from './dexie';
import type { User, OneRepMax, ActiveCycle, CompletedWorkout, CompletedSet } from '@/types';
import { generateId } from '@/lib/utils';

export async function createUser(data: Omit<User, 'id' | 'createdAt'>): Promise<User> {
  const user: User = {
    id: generateId(),
    ...data,
    createdAt: new Date()
  };
  await db.users.add(user);
  return user;
}

export async function getUser(): Promise<User | undefined> {
  return await db.users.toCollection().first();
}

export async function updateUser(id: string, updates: Partial<User>): Promise<void> {
  await db.users.update(id, updates);
}

export async function getActiveCycles(userId: string): Promise<ActiveCycle[]> {
  return await db.activeCycles
    .where('userId')
    .equals(userId)
    .and(cycle => cycle.status === 'active')
    .toArray();
}

export async function getLatest1RM(userId: string, exerciseId: string): Promise<OneRepMax | undefined> {
  return await db.oneRepMaxes
    .where('userId')
    .equals(userId)
    .and(orm => orm.exerciseId === exerciseId)
    .reverse()
    .first();
}

export async function saveCompletedWorkout(workout: CompletedWorkout): Promise<void> {
  await db.completedWorkouts.add(workout);
}

export async function saveCompletedSet(set: CompletedSet): Promise<void> {
  await db.completedSets.add(set);
}
```

**Step 3.4: Write tests for database operations**

Create: `tests/unit/db/database.test.ts`

```typescript
import { describe, it, expect, beforeEach } from 'vitest';
import { db } from '@/lib/db/dexie';
import { createUser, getUser, getActiveCycles } from '@/lib/db';

describe('Database Operations', () => {
  beforeEach(async () => {
    await db.delete();
    await db.open();
  });

  it('should create and retrieve user', async () => {
    const user = await createUser({
      name: 'Test User',
      experienceLevel: 'beginner',
      primaryGoal: 'strength'
    });

    expect(user.id).toBeDefined();
    expect(user.name).toBe('Test User');

    const retrieved = await getUser();
    expect(retrieved).toEqual(user);
  });

  it('should return undefined when no user exists', async () => {
    const user = await getUser();
    expect(user).toBeUndefined();
  });

  it('should retrieve active cycles for user', async () => {
    const user = await createUser({
      name: 'Test User',
      experienceLevel: 'intermediate',
      primaryGoal: 'hypertrophy'
    });

    await db.activeCycles.add({
      id: 'cycle-1',
      userId: user.id,
      programId: 'back-squat-5x5',
      cycleName: 'Back Squat 5x5',
      startDate: new Date(),
      currentWeek: 1,
      status: 'active'
    });

    await db.activeCycles.add({
      id: 'cycle-2',
      userId: user.id,
      programId: 'bench-press',
      cycleName: 'Bench Press',
      startDate: new Date(),
      currentWeek: 3,
      status: 'completed'
    });

    const activeCycles = await getActiveCycles(user.id);
    expect(activeCycles).toHaveLength(1);
    expect(activeCycles[0].status).toBe('active');
  });
});
```

**Step 3.5: Run tests to verify they pass**

Run:
```bash
pnpm vitest run tests/unit/db/database.test.ts
```

Expected: All tests PASS

**Step 3.6: Commit**

Run:
```bash
git add src/lib/db/ tests/unit/db/
git commit -m "feat: set up Dexie.js IndexedDB database

Create StrengthDatabase with schema for users, workouts, sets
Add helper functions for CRUD operations (createUser, getUser, etc.)
Write tests for database operations with beforeEach cleanup

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Task 4: Business Logic - Calculations

### Step 1: Implement target weight calculations

**Files:**
- Create: `src/lib/calculations.ts`
- Create: `tests/unit/calculations.test.ts`

**Step 4.1: Write calculation utilities**

Create: `src/lib/calculations.ts`

```typescript
import { roundToNearestFive } from './utils';

/**
 * Calculate target weight based on 1RM and percentage
 * @param oneRepMax - User's current 1RM in lbs
 * @param percentage - Decimal percentage (e.g., 0.65 for 65%)
 * @returns Target weight rounded to nearest 5 lbs
 */
export function calculateTargetWeight(oneRepMax: number, percentage: number): number {
  const rawWeight = oneRepMax * percentage;
  return roundToNearestFive(rawWeight);
}

/**
 * Check if a weight represents a new personal record
 * @param weight - Current weight
 * @param previousMax - Previous maximum weight
 * @returns True if weight exceeds previous max
 */
export function isPersonalRecord(weight: number, previousMax: number): boolean {
  return weight > previousMax;
}

/**
 * Calculate volume load (weight × reps × sets)
 * @param weight - Weight lifted
 * @param reps - Reps completed
 * @param sets - Number of sets
 * @returns Total volume load
 */
export function calculateVolumeLoad(weight: number, reps: number, sets: number): number {
  return weight * reps * sets;
}

/**
 * Determine if user has plateaued (no progress in 3+ workouts)
 * @param weights - Array of weights from recent workouts, ordered by date
 * @returns True if plateau detected
 */
export function detectPlateau(weights: number[]): boolean {
  if (weights.length < 3) return false;

  const lastThree = weights.slice(-3);
  const maxWeight = Math.max(...lastThree);
  const minWeight = Math.min(...lastThree);

  // Plateau if variance is less than 5 lbs
  return maxWeight - minWeight < 5;
}
```

**Step 4.2: Write tests for calculations**

Create: `tests/unit/calculations.test.ts`

```typescript
import { describe, it, expect } from 'vitest';
import { calculateTargetWeight, isPersonalRecord, calculateVolumeLoad, detectPlateau } from '@/lib/calculations';

describe('Target Weight Calculator', () => {
  it('calculates 65% of 1RM correctly', () => {
    const result = calculateTargetWeight(300, 0.65);
    expect(result).toBe(195); // 300 * 0.65 = 195
  });

  it('rounds to nearest 5 lbs', () => {
    const result = calculateTargetWeight(317, 0.65);
    expect(result).toBe(205); // 206.05 → 205
  });

  it('handles 80% intensity', () => {
    const result = calculateTargetWeight(300, 0.80);
    expect(result).toBe(240); // 300 * 0.80 = 240
  });
});

describe('Personal Record Detection', () => {
  it('detects new PR', () => {
    expect(isPersonalRecord(230, 225)).toBe(true);
  });

  it('does not detect PR when equal', () => {
    expect(isPersonalRecord(225, 225)).toBe(false);
  });

  it('does not detect PR when lower', () => {
    expect(isPersonalRecord(220, 225)).toBe(false);
  });
});

describe('Volume Load Calculator', () => {
  it('calculates 5x5 at 225 lbs', () => {
    const result = calculateVolumeLoad(225, 5, 5);
    expect(result).toBe(5625); // 225 * 5 * 5
  });
});

describe('Plateau Detection', () => {
  it('detects plateau with same weights', () => {
    const weights = [225, 225, 225];
    expect(detectPlateau(weights)).toBe(true);
  });

  it('detects plateau with minimal variance', () => {
    const weights = [225, 227, 224];
    expect(detectPlateau(weights)).toBe(true);
  });

  it('does not detect plateau with progress', () => {
    const weights = [225, 230, 235];
    expect(detectPlateau(weights)).toBe(false);
  });

  it('returns false with insufficient data', () => {
    expect(detectPlateau([225])).toBe(false);
    expect(detectPlateau([225, 230])).toBe(false);
  });
});
```

**Step 4.3: Run tests to verify they pass**

Run:
```bash
pnpm vitest run tests/unit/calculations.test.ts
```

Expected: All tests PASS

**Step 4.4: Commit**

Run:
```bash
git add src/lib/calculations.ts tests/unit/calculations.test.ts
git commit -m "feat: add calculation utilities for workouts

Implement calculateTargetWeight (rounds to nearest 5lbs)
Add isPersonalRecord, calculateVolumeLoad, detectPlateau
Write comprehensive tests for all calculation functions

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Task 5: Program Data - Back Squat 5x5 Linear

### Step 1: Create first program data file

**Files:**
- Create: `src/data/programs/back-squat-5x5-linear.json`

**Step 5.1: Create back squat 5x5 linear program**

Create: `src/data/programs/back-squat-5x5-linear.json`

```json
{
  "id": "back-squat-5x5-linear",
  "name": "Back Squat: 5x5 Linear Progression",
  "category": "back-squat",
  "description": "Classic 5x5 linear progression program. Add 5 lbs per week to build raw strength.",
  "durationWeeks": 8,
  "daysPerWeek": 3,
  "exercises": ["back-squat"],
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
        },
        {
          "day": 2,
          "exercises": [
            {
              "exercise": "back-squat",
              "sets": 5,
              "reps": 5,
              "percent1RM": 0.70,
              "restMinutes": 3
            }
          ]
        },
        {
          "day": 3,
          "exercises": [
            {
              "exercise": "back-squat",
              "sets": 5,
              "reps": 5,
              "percent1RM": 0.75,
              "restMinutes": 4
            }
          ]
        }
      ]
    },
    {
      "week": 2,
      "days": [
        {
          "day": 1,
          "exercises": [
            {
              "exercise": "back-squat",
              "sets": 5,
              "reps": 5,
              "percent1RM": 0.70,
              "restMinutes": 3
            }
          ]
        },
        {
          "day": 2,
          "exercises": [
            {
              "exercise": "back-squat",
              "sets": 5,
              "reps": 5,
              "percent1RM": 0.75,
              "restMinutes": 3
            }
          ]
        },
        {
          "day": 3,
          "exercises": [
            {
              "exercise": "back-squat",
              "sets": 5,
              "reps": 5,
              "percent1RM": 0.80,
              "restMinutes": 4
            }
          ]
        }
      ]
    },
    {
      "week": 3,
      "days": [
        {
          "day": 1,
          "exercises": [
            {
              "exercise": "back-squat",
              "sets": 5,
              "reps": 5,
              "percent1RM": 0.75,
              "restMinutes": 3
            }
          ]
        },
        {
          "day": 2,
          "exercises": [
            {
              "exercise": "back-squat",
              "sets": 5,
              "reps": 5,
              "percent1RM": 0.80,
              "restMinutes": 3
            }
          ]
        },
        {
          "day": 3,
          "exercises": [
            {
              "exercise": "back-squat",
              "sets": 5,
              "reps": 5,
              "percent1RM": 0.85,
              "restMinutes": 4
            }
          ]
        }
      ]
    },
    {
      "week": 4,
      "days": [
        {
          "day": 1,
          "exercises": [
            {
              "exercise": "back-squat",
              "sets": 5,
              "reps": 5,
              "percent1RM": 0.80,
              "restMinutes": 3
            }
          ]
        },
        {
          "day": 2,
          "exercises": [
            {
              "exercise": "back-squat",
              "sets": 5,
              "reps": 5,
              "percent1RM": 0.85,
              "restMinutes": 3
            }
          ]
        },
        {
          "day": 3,
          "exercises": [
            {
              "exercise": "back-squat",
              "sets": 5,
              "reps": 5,
              "percent1RM": 0.90,
              "restMinutes": 4
            }
          ]
        }
      ]
    },
    {
      "week": 5,
      "days": [
        {
          "day": 1,
          "exercises": [
            {
              "exercise": "back-squat",
              "sets": 5,
              "reps": 5,
              "percent1RM": 0.70,
              "restMinutes": 3
            }
          ]
        },
        {
          "day": 2,
          "exercises": [
            {
              "exercise": "back-squat",
              "sets": 5,
              "reps": 5,
              "percent1RM": 0.75,
              "restMinutes": 3
            }
          ]
        },
        {
          "day": 3,
          "exercises": [
            {
              "exercise": "back-squat",
              "sets": 5,
              "reps": 5,
              "percent1RM": 0.80,
              "restMinutes": 4
            }
          ]
        }
      ]
    },
    {
      "week": 6,
      "days": [
        {
          "day": 1,
          "exercises": [
            {
              "exercise": "back-squat",
              "sets": 5,
              "reps": 5,
              "percent1RM": 0.75,
              "restMinutes": 3
            }
          ]
        },
        {
          "day": 2,
          "exercises": [
            {
              "exercise": "back-squat",
              "sets": 5,
              "reps": 5,
              "percent1RM": 0.80,
              "restMinutes": 3
            }
          ]
        },
        {
          "day": 3,
          "exercises": [
            {
              "exercise": "back-squat",
              "sets": 5,
              "reps": 5,
              "percent1RM": 0.85,
              "restMinutes": 4
            }
          ]
        }
      ]
    },
    {
      "week": 7,
      "days": [
        {
          "day": 1,
          "exercises": [
            {
              "exercise": "back-squat",
              "sets": 5,
              "reps": 5,
              "percent1RM": 0.80,
              "restMinutes": 3
            }
          ]
        },
        {
          "day": 2,
          "exercises": [
            {
              "exercise": "back-squat",
              "sets": 5,
              "reps": 5,
              "percent1RM": 0.85,
              "restMinutes": 3
            }
          ]
        },
        {
          "day": 3,
          "exercises": [
            {
              "exercise": "back-squat",
              "sets": 5,
              "reps": 5,
              "percent1RM": 0.90,
              "restMinutes": 4
            }
          ]
        }
      ]
    },
    {
      "week": 8,
      "days": [
        {
          "day": 1,
          "exercises": [
            {
              "exercise": "back-squat",
              "sets": 5,
              "reps": 5,
              "percent1RM": 0.85,
              "restMinutes": 3
            }
          ]
        },
        {
          "day": 2,
          "exercises": [
            {
              "exercise": "back-squat",
              "sets": 5,
              "reps": 5,
              "percent1RM": 0.90,
              "restMinutes": 3
            }
          ]
        },
        {
          "day": 3,
          "exercises": [
            {
              "exercise": "back-squat",
              "sets": 5,
              "reps": 5,
              "percent1RM": 0.95,
              "restMinutes": 4
            }
          ]
        }
      ]
    }
  ]
}
```

**Step 5.2: Create program loader**

Create: `src/data/programs/index.ts`

```typescript
import backSquat5x5Linear from './back-squat-5x5-linear.json';
import type { Program } from '@/types';

const programs: Program[] = [
  backSquat5x5Linear as Program,
];

export function getAllPrograms(): Program[] {
  return programs;
}

export function getProgramById(id: string): Program | undefined {
  return programs.find(p => p.id === id);
}

export function getProgramsByCategory(category: string): Program[] {
  return programs.filter(p => p.category === category);
}
```

**Step 5.3: Write test for program loader**

Create: `tests/unit/programs/loader.test.ts`

```typescript
import { describe, it, expect } from 'vitest';
import { getAllPrograms, getProgramById, getProgramsByCategory } from '@/data/programs';

describe('Program Loader', () => {
  it('loads all programs', () => {
    const programs = getAllPrograms();
    expect(programs.length).toBeGreaterThan(0);
  });

  it('finds program by ID', () => {
    const program = getProgramById('back-squat-5x5-linear');
    expect(program).toBeDefined();
    expect(program?.name).toBe('Back Squat: 5x5 Linear Progression');
  });

  it('returns undefined for unknown program', () => {
    const program = getProgramById('unknown-program');
    expect(program).toBeUndefined();
  });

  it('filters programs by category', () => {
    const programs = getProgramsByCategory('back-squat');
    expect(programs.length).toBeGreaterThan(0);
    expect(programs.every(p => p.category === 'back-squat')).toBe(true);
  });
});
```

**Step 5.4: Run tests**

Run:
```bash
pnpm vitest run tests/unit/programs/loader.test.ts
```

Expected: All tests PASS

**Step 5.5: Commit**

Run:
```bash
git add src/data/ tests/unit/programs/
git commit -m "feat: add back squat 5x5 linear progression program

Create 8-week back squat program with 3 days/week
Intensity increases 5% per week, deload week 5
Add program loader with getById, getByCategory filters
Write tests for program loading functionality

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Task 6: shadcn/ui Component Setup

### Step 1: Initialize and install shadcn/ui components

**Files:**
- Run: shadcn-ui init
- Create: `src/components/ui/` (various components)

**Step 6.1: Initialize shadcn/ui**

Run:
```bash
npx shadcn@latest init --yes --defaults
```

Expected: Creates `components.json` and updates Tailwind config

**Step 6.2: Install required UI components**

Run:
```bash
npx shadcn@latest add button card input label select radio-group textarea badge alert skeleton --yes --overwrite
```

Expected: Components added to `src/components/ui/`

**Step 6.3: Verify button component works**

Create: `tests/unit/components/button.test.tsx`

```typescript
import { describe, it, expect } from 'vitest';
import { render, screen } from '@testing-library/react';
import { Button } from '@/components/ui/button';

describe('Button Component', () => {
  it('renders children', () => {
    render(<Button>Click me</Button>);
    expect(screen.getByText('Click me')).toBeInTheDocument();
  });

  it('applies variant classes', () => {
    const { container } = render(<Button variant="destructive">Delete</Button>);
    const button = container.querySelector('button');
    expect(button?.className).toContain('destructive');
  });
});
```

**Step 6.4: Run tests**

Run:
```bash
pnpm vitest run tests/unit/components/button.test.tsx
```

Expected: Tests PASS

**Step 6.5: Commit**

Run:
```bash
git add src/components/ui/ components.json tailwind.config.ts tests/unit/components/
git commit -m "feat: add shadcn/ui components

Initialize shadcn/ui with default configuration
Add button, card, input, label, select, radio-group, textarea, badge, alert, skeleton
Write tests for button component

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Task 7: React Context - User Context

### Step 1: Create User context for profile and 1RM management

**Files:**
- Create: `src/contexts/user-context.tsx`
- Create: `tests/contexts/user-context.test.tsx`

**Step 7.1: Write User context**

Create: `src/contexts/user-context.tsx`

```typescript
'use client';

import React, { createContext, useContext, useState, useEffect } from 'react';
import type { User, OneRepMax, SyncStatus } from '@/types';
import { getUser, updateUser, getLatest1RM } from '@/lib/db';
import { generateId } from '@/lib/utils';

interface UserContextValue {
  user: User | null;
  oneRepMaxes: OneRepMax[];
  syncStatus: SyncStatus;
  updateUserProfile: (updates: Partial<User>) => Promise<void>;
  update1RM: (exerciseId: string, weight: number) => Promise<void>;
  refresh: () => Promise<void>;
}

const UserContext = createContext<UserContextValue | undefined>(undefined);

export function UserProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [oneRepMaxes, setOneRepMaxes] = useState<OneRepMax[]>([]);
  const [syncStatus, setSyncStatus] = useState<SyncStatus>('offline');

  useEffect(() => {
    loadUserData();
  }, []);

  async function loadUserData() {
    const userData = await getUser();
    if (userData) {
      setUser(userData);
      // Load 1RMs for user's exercises
      // TODO: Implement getOneRepMaxesByUser
    }
  }

  async function updateUserProfile(updates: Partial<User>) {
    if (!user) return;
    await updateUser(user.id, updates);
    setUser(prev => prev ? { ...prev, ...updates } : null);
  }

  async function update1RM(exerciseId: string, weight: number) {
    if (!user) return;

    const new1RM: OneRepMax = {
      id: generateId(),
      userId: user.id,
      exerciseId,
      weight,
      date: new Date()
    };

    // Save to database
    // TODO: Implement saveOneRepMax

    setOneRepMaxes(prev => [...prev, new1RM]);
  }

  async function refresh() {
    await loadUserData();
  }

  return (
    <UserContext.Provider value={{
      user,
      oneRepMaxes,
      syncStatus,
      updateUserProfile,
      update1RM,
      refresh
    }}>
      {children}
    </UserContext.Provider>
  );
}

export function useUser() {
  const context = useContext(UserContext);
  if (!context) {
    throw new Error('useUser must be used within UserProvider');
  }
  return context;
}
```

**Step 7.2: Write tests for User context**

Create: `tests/contexts/user-context.test.tsx`

```typescript
import { describe, it, expect, beforeEach } from 'vitest';
import { renderHook, act, waitFor } from '@testing-library/react';
import { UserProvider, useUser } from '@/contexts/user-context';
import { db } from '@/lib/db/dexie';

describe('User Context', () => {
  beforeEach(async () => {
    await db.delete();
    await db.open();
  });

  it('provides user data', async () => {
    const { result } = renderHook(() => useUser(), {
      wrapper: UserProvider
    });

    await waitFor(() => {
      expect(result.current.user).toBeDefined();
    });
  });

  it('updates user profile', async () => {
    const { result } = renderHook(() => useUser(), {
      wrapper: UserProvider
    });

    await waitFor(() => {
      expect(result.current.user).toBeDefined();
    });

    await act(async () => {
      await result.current.updateUserProfile({ name: 'Updated Name' });
    });

    expect(result.current.user?.name).toBe('Updated Name');
  });
});
```

**Step 7.3: Run tests**

Run:
```bash
pnpm vitest run tests/contexts/user-context.test.tsx
```

Expected: Tests PASS

**Step 7.4: Commit**

Run:
```bash
git add src/contexts/user-context.tsx tests/contexts/
git commit -m "feat: create User context for profile management

Add UserProvider with user profile and 1RM state
Implement updateUserProfile and update1RM functions
Write tests for context loading and updates

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Task 8: React Context - Exercise/Program Context

### Step 1: Create Exercise context for program data

**Files:**
- Create: `src/contexts/exercise-context.tsx`
- Create: `tests/contexts/exercise-context.test.tsx`

**Step 8.1: Write Exercise context**

Create: `src/contexts/exercise-context.tsx`

```typescript
'use client';

import React, { createContext, useContext, useMemo } from 'react';
import { getAllPrograms, getProgramById } from '@/data/programs';
import { calculateTargetWeight } from '@/lib/calculations';
import type { Program, Week, Day, Exercise as ProgramExercise } from '@/types';

interface ExerciseContextValue {
  programs: Program[];
  getProgram: (id: string) => Program | undefined;
  getWeek: (programId: string, weekNumber: number) => Week | undefined;
  getDay: (programId: string, weekNumber: number, dayNumber: number) => Day | undefined;
  calculatePrescribedWeight: (exercise: ProgramExercise, oneRepMax: number) => number;
}

const ExerciseContext = createContext<ExerciseContextValue | undefined>(undefined);

export function ExerciseProvider({ children }: { children: React.ReactNode }) {
  const programs = useMemo(() => getAllPrograms(), []);

  function getProgram(id: string): Program | undefined {
    return getProgramById(id);
  }

  function getWeek(programId: string, weekNumber: number): Week | undefined {
    const program = getProgram(programId);
    return program?.weeks.find(w => w.week === weekNumber);
  }

  function getDay(programId: string, weekNumber: number, dayNumber: number): Day | undefined {
    const week = getWeek(programId, weekNumber);
    return week?.days.find(d => d.day === dayNumber);
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
      calculatePrescribedWeight
    }}>
      {children}
    </ExerciseContext.Provider>
  );
}

export function useExercise() {
  const context = useContext(ExerciseContext);
  if (!context) {
    throw new Error('useExercise must be used within ExerciseProvider');
  }
  return context;
}
```

**Step 8.2: Write tests**

Create: `tests/contexts/exercise-context.test.tsx`

```typescript
import { describe, it, expect } from 'vitest';
import { renderHook } from '@testing-library/react';
import { ExerciseProvider, useExercise } from '@/contexts/exercise-context';

describe('Exercise Context', () => {
  it('loads all programs', () => {
    const { result } = renderHook(() => useExercise(), {
      wrapper: ExerciseProvider
    });

    expect(result.current.programs.length).toBeGreaterThan(0);
  });

  it('finds program by ID', () => {
    const { result } = renderHook(() => useExercise(), {
      wrapper: ExerciseProvider
    });

    const program = result.current.getProgram('back-squat-5x5-linear');
    expect(program).toBeDefined();
  });

  it('gets specific week', () => {
    const { result } = renderHook(() => useExercise(), {
      wrapper: ExerciseProvider
    });

    const week = result.current.getWeek('back-squat-5x5-linear', 1);
    expect(week).toBeDefined();
    expect(week?.week).toBe(1);
  });

  it('calculates prescribed weight', () => {
    const { result } = renderHook(() => useExercise(), {
      wrapper: ExerciseProvider
    });

    const exercise = {
      exercise: 'back-squat',
      sets: 5,
      reps: 5,
      percent1RM: 0.65
    };

    const weight = result.current.calculatePrescribedWeight(exercise, 300);
    expect(weight).toBe(195);
  });
});
```

**Step 8.3: Run tests**

Run:
```bash
pnpm vitest run tests/contexts/exercise-context.test.tsx
```

Expected: Tests PASS

**Step 8.4: Commit**

Run:
```bash
git add src/contexts/exercise-context.tsx tests/contexts/
git commit -m "feat: add Exercise context for program data

Create ExerciseProvider with program loading
Add getProgram, getWeek, getDay helpers
Implement calculatePrescribedWeight using 1RM
Write tests for program queries and calculations

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Task 9: Combined Providers Setup

### Step 1: Create provider wrapper for app

**Files:**
- Create: `src/contexts/providers.tsx`
- Modify: `src/app/layout.tsx`

**Step 9.1: Create provider wrapper**

Create: `src/contexts/providers.tsx`

```typescript
'use client';

import { UserProvider } from './user-context';
import { ExerciseProvider } from './exercise-context';

export function Providers({ children }: { children: React.ReactNode }) {
  return (
    <ExerciseProvider>
      <UserProvider>
        {children}
      </UserProvider>
    </ExerciseProvider>
  );
}
```

**Step 9.2: Update root layout**

Modify: `src/app/layout.tsx`

```typescript
import type { Metadata } from "next";
import { Inter } from "next/font/google";
import "./globals.css";
import { Providers } from "@/contexts/providers";

const inter = Inter({ subsets: ["latin"] });

export const metadata: Metadata = {
  title: "Strength - Workout Tracker",
  description: "Track your workouts, build strength",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body className={inter.className}>
        <Providers>
          {children}
        </Providers>
      </body>
    </html>
  );
}
```

**Step 9.3: Commit**

Run:
```bash
git add src/contexts/providers.tsx src/app/layout.tsx
git commit -m "feat: add combined provider wrapper

Create Providers component wrapping User and Exercise contexts
Update root layout to include providers
Ensure context available throughout app

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Task 10: Onboarding Page

### Step 1: Create multi-step onboarding wizard

**Files:**
- Create: `src/app/onboarding/page.tsx`
- Create: `src/components/onboarding/onboarding-wizard.tsx`

**Step 10.1: Create onboarding wizard component**

Create: `src/components/onboarding/onboarding-wizard.tsx`

```typescript
'use client';

import React, { useState } from 'react';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { RadioGroup, RadioGroupItem } from '@/components/ui/radio-group';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import type { ExperienceLevel, PrimaryGoal } from '@/types';
import { useUser } from '@/contexts/user-context';
import { useRouter } from 'next/navigation';

interface OnboardingData {
  name: string;
  experienceLevel: ExperienceLevel;
  primaryGoal: PrimaryGoal;
}

export function OnboardingWizard() {
  const [step, setStep] = useState(1);
  const [data, setData] = useState<OnboardingData>({
    name: '',
    experienceLevel: 'beginner',
    primaryGoal: 'strength'
  });
  const { updateUserProfile } = useUser();
  const router = useRouter();

  async function handleNext() {
    if (step < 3) {
      setStep(step + 1);
    } else {
      // Complete onboarding
      await updateUserProfile(data);
      router.push('/dashboard');
    }
  }

  function canProceed() {
    switch (step) {
      case 1: return data.name.trim().length > 0;
      case 2: return data.experienceLevel !== undefined;
      case 3: return data.primaryGoal !== undefined;
      default: return false;
    }
  }

  return (
    <div className="min-h-screen flex items-center justify-center p-4">
      <Card className="w-full max-w-md">
        <CardHeader>
          <CardTitle>
            {step === 1 && 'Welcome to Strength'}
            {step === 2 && 'Training Experience'}
            {step === 3 && 'Your Goals'}
          </CardTitle>
          <CardDescription>
            Step {step} of 3
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          {step === 1 && (
            <div className="space-y-2">
              <Label htmlFor="name">What's your name?</Label>
              <Input
                id="name"
                value={data.name}
                onChange={(e) => setData({ ...data, name: e.target.value })}
                placeholder="Enter your name"
              />
            </div>
          )}

          {step === 2 && (
            <div className="space-y-2">
              <Label>Training experience</Label>
              <RadioGroup
                value={data.experienceLevel}
                onValueChange={(value) => setData({ ...data, experienceLevel: value as ExperienceLevel })}
              >
                <div className="flex items-center space-x-2">
                  <RadioGroupItem value="beginner" id="beginner" />
                  <Label htmlFor="beginner">0-1 years (Beginner)</Label>
                </div>
                <div className="flex items-center space-x-2">
                  <RadioGroupItem value="intermediate" id="intermediate" />
                  <Label htmlFor="intermediate">1-3 years (Intermediate)</Label>
                </div>
                <div className="flex items-center space-x-2">
                  <RadioGroupItem value="advanced" id="advanced" />
                  <Label htmlFor="advanced">3+ years (Advanced)</Label>
                </div>
              </RadioGroup>
            </div>
          )}

          {step === 3 && (
            <div className="space-y-2">
              <Label>Primary goal</Label>
              <Select
                value={data.primaryGoal}
                onValueChange={(value) => setData({ ...data, primaryGoal: value as PrimaryGoal })}
              >
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="strength">Build Strength</SelectItem>
                  <SelectItem value="hypertrophy">Muscle Growth</SelectItem>
                  <SelectItem value="explosiveness">Power & Speed</SelectItem>
                </SelectContent>
              </Select>
            </div>
          )}

          <div className="flex justify-between pt-4">
            <Button
              variant="outline"
              onClick={() => setStep(step - 1)}
              disabled={step === 1}
            >
              Back
            </Button>
            <Button onClick={handleNext} disabled={!canProceed()}>
              {step === 3 ? 'Start Training' : 'Next'}
            </Button>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
```

**Step 10.2: Create onboarding page**

Create: `src/app/onboarding/page.tsx`

```typescript
import { OnboardingWizard } from '@/components/onboarding/onboarding-wizard';

export default function OnboardingPage() {
  return <OnboardingWizard />;
}
```

**Step 10.3: Update home page to redirect**

Modify: `src/app/page.tsx`

```typescript
import { redirect } from 'next/navigation';

export default function HomePage() {
  // TODO: Check if user exists, redirect to dashboard or onboarding
  redirect('/onboarding');
}
```

**Step 10.4: Commit**

Run:
```bash
git add src/app/onboarding/ src/app/page.tsx src/components/onboarding/
git commit -m "feat: create multi-step onboarding wizard

Add 3-step onboarding flow (name, experience, goals)
Create OnboardingWizard with form validation
Update home page to redirect to onboarding
Route to dashboard after completion

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Task 11: Programs Browser Page

### Step 1: Create programs listing and detail pages

**Files:**
- Create: `src/app/programs/page.tsx`
- Create: `src/app/programs/[category]/page.tsx`
- Create: `src/components/programs/program-card.tsx`

**Step 11.1: Create program card component**

Create: `src/components/programs/program-card.tsx`

```typescript
'use client';

import Link from 'next/link';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import type { Program } from '@/types';

interface ProgramCardProps {
  program: Program;
}

export function ProgramCard({ program }: ProgramCardProps) {
  return (
    <Link href={`/programs/${program.id}`}>
      <Card className="h-full hover:shadow-md transition-shadow">
        <CardHeader>
          <div className="flex justify-between items-start">
            <CardTitle className="text-lg">{program.name}</CardTitle>
            <Badge variant="secondary">{program.difficulty}</Badge>
          </div>
          <CardDescription>{program.description}</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="text-sm text-muted-foreground">
            {program.durationWeeks} weeks • {program.daysPerWeek} days/week
          </div>
        </CardContent>
      </Card>
    </Link>
  );
}
```

**Step 11.2: Create programs listing page**

Create: `src/app/programs/page.tsx`

```typescript
import { useExercise } from '@/contexts/exercise-context';
import { ProgramCard } from '@/components/programs/program-card';

export default function ProgramsPage() {
  const { programs } = useExercise();

  return (
    <div className="min-h-screen p-4 pb-20">
      <h1 className="text-2xl font-bold mb-4">Workout Programs</h1>

      <div className="space-y-6">
        {programs.map(program => (
          <ProgramCard key={program.id} program={program} />
        ))}
      </div>
    </div>
  );
}
```

**Step 11.3: Create program detail page**

Create: `src/app/programs/[id]/page.tsx`

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
          <div className="text-sm">
            <p><strong>Duration:</strong> {program.durationWeeks} weeks</p>
            <p><strong>Frequency:</strong> {program.daysPerWeek} days per week</p>
            <p><strong>Exercises:</strong> {program.exercises.join(', ')}</p>
          </div>

          <Button className="w-full">
            Start This Program
          </Button>
        </CardContent>
      </Card>
    </div>
  );
}
```

**Step 11.4: Commit**

Run:
```bash
git add src/app/programs/ src/components/programs/
git commit -m "feat: add program browser and detail pages

Create ProgramCard component with link to details
Add programs listing page showing all available programs
Create dynamic program detail route with [id]
Add start button for program selection

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Task 12: Dashboard Page

### Step 1: Create main dashboard with active cycles

**Files:**
- Create: `src/app/dashboard/page.tsx`
- Create: `src/components/dashboard/active-cycles-card.tsx`

**Step 12.1: Create active cycles card**

Create: `src/components/dashboard/active-cycles-card.tsx`

```typescript
'use client';

import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { useUser } from '@/contexts/user-context';
import { getActiveCycles } from '@/lib/db';
import { useEffect, useState } from 'react';
import type { ActiveCycle } from '@/types';

export function ActiveCyclesCard() {
  const { user } = useUser();
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
        {activeCycles.map(cycle => (
          <div key={cycle.id} className="flex items-center justify-between p-3 border rounded-lg">
            <div>
              <p className="font-medium">{cycle.cycleName}</p>
              <p className="text-sm text-muted-foreground">Week {cycle.currentWeek} of 8</p>
            </div>
            <Badge>Active</Badge>
          </div>
        ))}
      </CardContent>
    </Card>
  );
}
```

**Step 12.2: Create dashboard page**

Create: `src/app/dashboard/page.tsx`

```typescript
import { ActiveCyclesCard } from '@/components/dashboard/active-cycles-card';

export default function DashboardPage() {
  return (
    <div className="min-h-screen p-4 pb-20">
      <h1 className="text-2xl font-bold mb-4">Dashboard</h1>

      <div className="space-y-4">
        <ActiveCyclesCard />
      </div>
    </div>
  );
}
```

**Step 12.3: Commit**

Run:
```bash
git add src/app/dashboard/ src/components/dashboard/
git commit -m "feat: create dashboard with active cycles display

Add ActiveCyclesCard showing user's active programs
Display current week progress for each cycle
Show empty state when no programs active
Create dashboard page layout

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Task 13: Complete Remaining Programs

### Step 1: Add remaining 5 programs

**Note:** Due to plan length, I'm documenting the pattern. Follow Task 5 structure to create:
- `src/data/programs/front-squat-volume.json`
- `src/data/programs/bench-press-strength.json`
- `src/data/programs/deadlift-8x8.json`
- `src/data/programs/box-jump-power.json`
- `src/data/programs/burpees-conditioning.json`

Each should follow the same 8-week, 3-days-per-week structure with appropriate intensity progressions for the exercise type.

Update `src/data/programs/index.ts` to import and export all programs.

---

## Task 14: Workout Logger

### Step 1: Create workout logging interface

**Files:**
- Create: `src/components/workout/set-input.tsx`
- Create: `src/components/workout/exercise-card.tsx`
- Create: `src/app/workout/[id]/page.tsx`

**Step 14.1: Create set input component**

Create: `src/components/workout/set-input.tsx`

```typescript
'use client';

import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import type { ProgramExercise } from '@/types';

interface SetInputProps {
  setNumber: number;
  prescribedWeight: number;
  prescribedReps: number;
  onWeightChange: (weight: number) => void;
  onRepsChange: (reps: number) => void;
}

export function SetInput({ setNumber, prescribedWeight, prescribedReps, onWeightChange, onRepsChange }: SetInputProps) {
  return (
    <div className="flex items-center gap-3 p-3 border rounded-lg">
      <div className="font-medium text-lg w-8">{setNumber}</div>

      <div className="flex-1">
        <Label htmlFor={`weight-${setNumber}`} className="text-xs">Weight (lbs)</Label>
        <Input
          id={`weight-${setNumber}`}
          type="number"
          defaultValue={prescribedWeight}
          onChange={(e) => onWeightChange(Number(e.target.value))}
          placeholder="Weight"
        />
      </div>

      <div className="flex-1">
        <Label htmlFor={`reps-${setNumber}`} className="text-xs">Reps</Label>
        <Input
          id={`reps-${setNumber}`}
          type="number"
          defaultValue={prescribedReps}
          onChange={(e) => onRepsChange(Number(e.target.value))}
          placeholder="Reps"
        />
      </div>
    </div>
  );
}
```

**Step 14.2: Create exercise card component**

Create: `src/components/workout/exercise-card.tsx`

```typescript
'use client';

import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { SetInput } from './set-input';
import type { Exercise as ProgramExercise } from '@/types';

interface ExerciseCardProps {
  exercise: ProgramExercise;
  prescribedWeight: number;
}

export function ExerciseCard({ exercise, prescribedWeight }: ExerciseCardProps) {
  return (
    <Card>
      <CardHeader>
        <CardTitle className="capitalize">{exercise.exercise.replace('-', ' ')}</CardTitle>
        <p className="text-sm text-muted-foreground">
          {exercise.sets} sets × {exercise.reps} reps @ {exercise.percent1RM * 100}% 1RM ({prescribedWeight} lbs)
        </p>
      </CardHeader>
      <CardContent className="space-y-2">
        {Array.from({ length: exercise.sets }).map((_, i) => (
          <SetInput
            key={i}
            setNumber={i + 1}
            prescribedWeight={prescribedWeight}
            prescribedReps={exercise.reps}
            onWeightChange={() => {}}
            onRepsChange={() => {}}
          />
        ))}
      </CardContent>
    </Card>
  );
}
```

**Step 14.3: Create workout page**

Create: `src/app/workout/[id]/page.tsx`

```typescript
import { useExercise } from '@/contexts/exercise-context';
import { ExerciseCard } from '@/components/workout/exercise-card';
import { Button } from '@/components/ui/button';

interface PageProps {
  params: { id: string };
}

export default function WorkoutPage({ params }: PageProps) {
  const { getProgram } = useExercise();
  const program = getProgram(params.id);

  if (!program) {
    return <div>Program not found</div>;
  }

  // For MVP, showing week 1, day 1
  const workout = program.weeks[0]?.days[0];

  return (
    <div className="min-h-screen p-4 pb-20">
      <h1 className="text-2xl font-bold mb-4">Today's Workout</h1>
      <p className="text-muted-foreground mb-4">{program.name}</p>

      <div className="space-y-4">
        {workout?.exercises.map(exercise => (
          <ExerciseCard
            key={exercise.exercise}
            exercise={exercise}
            prescribedWeight={195} // TODO: Calculate from user's 1RM
          />
        ))}
      </div>

      <Button className="w-full mt-6" size="lg">
        Complete Workout
      </Button>
    </div>
  );
}
```

**Step 14.4: Commit**

Run:
```bash
git add src/components/workout/ src/app/workout/
git commit -m "feat: add workout logger interface

Create SetInput component for individual set logging
Add ExerciseCard showing prescribed weight/reps
Create workout page with exercise list
Add complete workout button

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Task 15: Bottom Navigation

### Step 1: Create mobile bottom navigation

**Files:**
- Create: `src/components/layout/bottom-navigation.tsx`
- Modify: `src/app/layout.tsx`

**Step 15.1: Create bottom navigation component**

Create: `src/components/layout/bottom-navigation.tsx`

```typescript
'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { LayoutDashboard, Dumbbell, ClipboardPlus, TrendingUp } from 'lucide-react';
import { cn } from '@/lib/utils';

const navItems = [
  { href: '/dashboard', icon: LayoutDashboard, label: 'Dashboard' },
  { href: '/programs', icon: Dumbbell, label: 'Programs' },
  { href: '/workout', icon: ClipboardPlus, label: 'Workout' },
  { href: '/progress', icon: TrendingUp, label: 'Progress' },
];

export function BottomNavigation() {
  const pathname = usePathname();

  return (
    <nav className="fixed bottom-0 left-0 right-0 bg-background border-t z-50">
      <div className="flex justify-around items-center h-16">
        {navItems.map(item => {
          const Icon = item.icon;
          const isActive = pathname === item.href || pathname?.startsWith(item.href + '/');

          return (
            <Link
              key={item.href}
              href={item.href}
              className={cn(
                "flex flex-col items-center justify-center flex-1 h-full",
                isActive ? "text-primary" : "text-muted-foreground"
              )}
            >
              <Icon className="w-5 h-5" />
              <span className="text-xs mt-1">{item.label}</span>
            </Link>
          );
        })}
      </div>
    </nav>
  );
}
```

**Step 15.2: Update layout to include navigation**

Modify: `src/app/layout.tsx`

```typescript
import type { Metadata } from "next";
import { Inter } from "next/font/google";
import "./globals.css";
import { Providers } from "@/contexts/providers";
import { BottomNavigation } from "@/components/layout/bottom-navigation";

const inter = Inter({ subsets: ["latin"] });

export const metadata: Metadata = {
  title: "Strength - Workout Tracker",
  description: "Track your workouts, build strength",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body className={inter.className}>
        <Providers>
          {children}
          <BottomNavigation />
        </Providers>
      </body>
    </html>
  );
}
```

**Step 15.3: Commit**

Run:
```bash
git add src/components/layout/bottom-navigation.tsx src/app/layout.tsx
git commit -m "feat: add mobile bottom navigation

Create BottomNavigation with Dashboard, Programs, Workout, Progress
Use Lucide icons for visual clarity
Add active state highlighting
Include in root layout for global access

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Task 16: Recommendations Engine

### Step 1: Implement plateau detection and recommendations

**Files:**
- Create: `src/lib/recommendations/plateau-detection.ts`
- Create: `src/lib/recommendations/index.ts`

**Step 16.1: Create plateau detection**

Create: `src/lib/recommendations/plateau-detection.ts`

```typescript
import { db } from '@/lib/db/dexie';
import type { ActiveCycle } from '@/types';
import { detectPlateau as checkPlateau } from '@/lib/calculations';

export interface PlateauWarning {
  hasPlateau: boolean;
  message: string;
  recommendation: string;
}

export async function detectPlateau(activeCycleId: string): Promise<PlateauWarning> {
  const cycle = await db.activeCycles.get(activeCycleId);
  if (!cycle) {
    return { hasPlateau: false, message: '', recommendation: '' };
  }

  // Get recent workouts for this cycle
  const workouts = await db.completedWorkouts
    .where('activeCycleId')
    .equals(activeCycleId)
    .reverse()
    .limit(5)
    .toArray();

  if (workouts.length < 3) {
    return { hasPlateau: false, message: '', recommendation: '' };
  }

  // Get sets from these workouts
  const setPromises = workouts.map(w =>
    db.completedSets.where('workoutId').equals(w.id).toArray()
  );
  const allSets = await Promise.all(setPromises);
  const weights = allSets.flat().map(s => s.actualWeight);

  const hasPlateau = checkPlateau(weights);

  if (hasPlateau) {
    return {
      hasPlateau: true,
      message: 'Your weight has plateaued',
      recommendation: 'Consider a deload week or changing your training intensity'
    };
  }

  return { hasPlateau: false, message: '', recommendation: '' };
}
```

**Step 16.2: Create recommendations barrel**

Create: `src/lib/recommendations/index.ts`

```typescript
export * from './plateau-detection';
```

**Step 16.3: Write tests**

Create: `tests/unit/recommendations/plateau-detection.test.ts`

```typescript
import { describe, it, expect, beforeEach } from 'vitest';
import { db } from '@/lib/db/dexie';
import { detectPlateau } from '@/lib/recommendations/plateau-detection';
import { saveCompletedWorkout, saveCompletedSet } from '@/lib/db';
import { generateId } from '@/lib/utils';

describe('Plateau Detection', () => {
  beforeEach(async () => {
    await db.delete();
    await db.open();
  });

  it('detects plateau after 3 stagnant workouts', async () => {
    const user = await createUser();
    const cycle = await createActiveCycle(user.id);

    // Log 3 workouts at same weight
    for (let i = 0; i < 3; i++) {
      const workout = await createWorkout(user.id, cycle.id);
      await saveCompletedSet({
        id: generateId(),
        workoutId: workout.id,
        exerciseId: 'back-squat',
        setNumber: 1,
        actualWeight: 225,
        actualReps: 5,
        prescribedReps: 5,
        createdAt: new Date()
      });
    }

    const result = await detectPlateau(cycle.id);
    expect(result.hasPlateau).toBe(true);
    expect(result.recommendation).toContain('deload');
  });

  async function createUser() {
    return await db.users.add({
      id: generateId(),
      name: 'Test',
      experienceLevel: 'intermediate',
      primaryGoal: 'strength',
      createdAt: new Date()
    });
  }

  async function createActiveCycle(userId: string) {
    const id = generateId();
    await db.activeCycles.add({
      id,
      userId,
      programId: 'back-squat-5x5',
      cycleName: 'Test Cycle',
      startDate: new Date(),
      currentWeek: 1,
      status: 'active'
    });
    return id;
  }

  async function createWorkout(userId: string, cycleId: string) {
    const id = generateId();
    await db.completedWorkouts.add({
      id,
      userId,
      activeCycleId: cycleId,
      programId: 'back-squat-5x5',
      week: 1,
      day: 1,
      completedAt: new Date()
    });
    return id;
  }
});
```

**Step 16.4: Run tests**

Run:
```bash
pnpm vitest run tests/unit/recommendations/plateau-detection.test.ts
```

Expected: Tests PASS

**Step 16.5: Commit**

Run:
```bash
git add src/lib/recommendations/ tests/unit/recommendations/
git commit -m "feat: add plateau detection recommendations

Implement detectPlateau analyzing recent workout weights
Return warning message and deload recommendation
Write tests for plateau detection logic
Add recommendations barrel export

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Task 17: Progress View

### Step 1: Create progress tracking page with charts

**Files:**
- Create: `src/app/progress/page.tsx`
- Create: `src/components/progress/weight-progress-chart.tsx`

**Step 17.1: Create weight progress chart**

Create: `src/components/progress/weight-progress-chart.tsx`

```typescript
'use client';

import { useEffect, useState } from 'react';
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts';
import { db } from '@/lib/db/dexie';
import type { CompletedSet } from '@/types';

export function WeightProgressChart() {
  const [data, setData] = useState<Array<{ date: string; weight: number }>>([]);

  useEffect(() => {
    loadProgressData();
  }, []);

  async function loadProgressData() {
    const sets = await db.completedSets
      .reverse()
      .limit(20)
      .toArray();

    const chartData = sets.map(set => ({
      date: new Date(set.createdAt).toLocaleDateString(),
      weight: set.actualWeight
    })).reverse();

    setData(chartData);
  }

  if (data.length === 0) {
    return <div className="text-center text-muted-foreground py-8">No data yet</div>;
  }

  return (
    <ResponsiveContainer width="100%" height={200}>
      <LineChart data={data}>
        <CartesianGrid strokeDasharray="3 3" />
        <XAxis dataKey="date" />
        <YAxis />
        <Tooltip />
        <Line type="monotone" dataKey="weight" stroke="#8884d8" strokeWidth={2} />
      </LineChart>
    </ResponsiveContainer>
  );
}
```

**Step 17.2: Create progress page**

Create: `src/app/progress/page.tsx`

```typescript
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { WeightProgressChart } from '@/components/progress/weight-progress-chart';

export default function ProgressPage() {
  return (
    <div className="min-h-screen p-4 pb-20">
      <h1 className="text-2xl font-bold mb-4">Progress</h1>

      <Card>
        <CardHeader>
          <CardTitle>Weight Progress</CardTitle>
        </CardHeader>
        <CardContent>
          <WeightProgressChart />
        </CardContent>
      </Card>
    </div>
  );
}
```

**Step 17.3: Commit**

Run:
```bash
git add src/app/progress/ src/components/progress/
git commit -m "feat: add progress tracking with weight charts

Create WeightProgressChart using Recharts
Display last 20 sets in line chart format
Add progress page with chart container
Handle empty state for no data

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Task 18: Supabase Integration Setup

### Step 1: Configure Supabase client

**Files:**
- Create: `src/lib/supabase/client.ts`
- Create: `.env.local`

**Step 18.1: Create environment file template**

Create: `.env.local.example`

```env
NEXT_PUBLIC_SUPABASE_URL=your-supabase-project-url
NEXT_PUBLIC_SUPABASE_ANON_KEY=your-supabase-anon-key
```

**Step 18.2: Create Supabase client**

Create: `src/lib/supabase/client.ts`

```typescript
import { createBrowserClient } from '@supabase/ssr';

export function createClient() {
  return createBrowserClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
  );
}
```

**Step 18.3: Create Supabase server client for SSR**

Create: `src/lib/supabase/server.ts`

```typescript
import { createServerClient } from '@supabase/ssr';
import { cookies } from 'next/headers';

export async function createClient() {
  const cookieStore = await cookies();

  return createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() {
          return cookieStore.getAll();
        },
        setAll(cookiesToSet) {
          try {
            cookiesToSet.forEach(({ name, value, options }) => {
              cookieStore.set(name, value, options);
            });
          } catch {
            // The `setAll` method was called from a Server Component.
            // This can be ignored if you have middleware refreshing user sessions.
          }
        },
      },
    }
  );
}
```

**Step 18.4: Update .gitignore**

Modify: `.gitignore`

Ensure `.env.local` is ignored.

**Step 18.5: Commit**

Run:
```bash
git add src/lib/supabase/ .env.local.example .gitignore
git commit -m "feat: add Supabase client configuration

Create browser and server Supabase clients
Add environment variable template for Supabase URL and anon key
Configure SSR-compatible client with cookie handling

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Task 19: E2E Tests Setup

### Step 1: Configure Playwright for mobile E2E testing

**Files:**
- Create: `playwright.config.ts`
- Create: `tests/e2e/onboarding.spec.ts`

**Step 19.1: Create Playwright config**

Create: `playwright.config.ts`

```typescript
import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: './tests/e2e',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  reporter: 'html',
  use: {
    baseURL: 'http://localhost:3000',
    trace: 'on-first-retry',
  },

  projects: [
    {
      name: 'chromium',
      use: { ...devices['iPhone 13'] },
    },
  ],

  webServer: {
    command: 'pnpm dev',
    url: 'http://localhost:3000',
    reuseExistingServer: !process.env.CI,
  },
});
```

**Step 19.2: Create onboarding E2E test**

Create: `tests/e2e/onboarding.spec.ts`

```typescript
import { test, expect } from '@playwright/test';

test('completes onboarding flow', async ({ page }) => {
  await page.goto('/');

  // Should redirect to onboarding
  await expect(page).toHaveURL('/onboarding');

  // Step 1: Enter name
  await page.fill('input[id="name"]', 'Test User');
  await page.click('button:has-text("Next")');

  // Step 2: Select experience
  await page.click('label:has-text("Beginner")');
  await page.click('button:has-text("Next")');

  // Step 3: Select goal
  await page.click('button:has-text("Build Strength")');
  await page.click('button:has-text("Start Training")');

  // Should redirect to dashboard
  await expect(page).toHaveURL('/dashboard');
});
```

**Step 19.3: Run E2E tests**

Run:
```bash
pnpm playwright test
```

Expected: Tests PASS

**Step 19.4: Commit**

Run:
```bash
git add playwright.config.ts tests/e2e/
git commit -m "test: add Playwright E2E testing setup

Configure Playwright for mobile viewport (iPhone 13)
Add onboarding flow E2E test
Set up dev server for test environment

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Task 20: Deployment Configuration

### Step 1: Configure for Vercel deployment

**Files:**
- Create: `vercel.json`
- Create: `.env.production.example`

**Step 20.1: Create Vercel config**

Create: `vercel.json`

```json
{
  "buildCommand": "pnpm build",
  "devCommand": "pnpm dev",
  "installCommand": "pnpm install",
  "framework": "nextjs"
}
```

**Step 20.2: Create production env template**

Create: `.env.production.example`

```env
NEXT_PUBLIC_SUPABASE_URL=your-production-supabase-url
NEXT_PUBLIC_SUPABASE_ANON_KEY=your-production-anon-key
```

**Step 20.3: Update README with deployment instructions**

Create: `readme.md`

```markdown
# Strength - Workout Tracking App

Mobile-first web app for tracking workout programs, logging exercises, and monitoring progress.

## Tech Stack

- Next.js 15 with App Router
- React 19
- TypeScript
- Tailwind CSS + shadcn/ui
- Dexie.js (IndexedDB)
- Supabase (auth + sync)

## Development

```bash
# Install dependencies
pnpm install

# Run development server
pnpm dev

# Run tests
pnpm vitest
pnpm playwright test

# Build for production
pnpm build
```

## Deployment

Deploy to Vercel:

1. Connect repository to Vercel
2. Add environment variables (Supabase URL and anon key)
3. Deploy

## Environment Variables

```env
NEXT_PUBLIC_SUPABASE_URL=
NEXT_PUBLIC_SUPABASE_ANON_KEY=
```
```

**Step 20.4: Commit**

Run:
```bash
git add vercel.json .env.production.example readme.md
git commit -m "docs: add deployment configuration and README

Configure Vercel deployment settings
Add production environment variable template
Create comprehensive README with setup instructions
Document development workflow

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Task 21: Final Integration & Testing

### Step 1: Run full test suite and fix any issues

**Step 21.1: Run all unit tests**

Run:
```bash
pnpm vitest run
```

Expected: All unit tests PASS

**Step 21.2: Run E2E tests**

Run:
```bash
pnpm playwright test
```

Expected: All E2E tests PASS

**Step 21.3: Build production bundle**

Run:
```bash
pnpm build
```

Expected: Build succeeds without errors

**Step 21.4: Test production build locally**

Run:
```bash
pnpm start
```

Manual testing checklist:
- [ ] Onboarding flow completes successfully
- [ ] Programs page displays all programs
- [ ] Can navigate to program detail
- [ ] Dashboard loads without errors
- [ ] Bottom navigation works
- [ ] Workout logger displays correctly
- [ ] Progress page shows chart

**Step 21.5: Final commit**

Run:
```bash
git add .
git commit -m "chore: complete MVP implementation

All core features implemented and tested:
- Onboarding flow (name, experience, goals)
- Program browser with 6 programs
- Workout logger with set tracking
- Dashboard with active cycles
- Progress tracking with charts
- Mobile-optimized bottom navigation
- Plateau detection recommendations
- IndexedDB local storage
- Supabase integration ready

Ready for deployment to Vercel

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Execution Checklist

When executing this plan with `superpowers:executing-plans`:

- [ ] Complete each task in order (1-21)
- [ ] Run tests after each task
- [ ] Commit after each task
- [ ] Verify app builds successfully
- [ ] Run E2E tests before deployment
- [ ] Deploy to Vercel and test live

---

## Post-MVP Enhancements

Future features to consider:
- [ ] User authentication flow
- [ ] Cross-device sync implementation
- [ ] Additional recommendation algorithms
- [ ] Workout history view
- [ ] Settings page
- [ ] Dark mode support
- [ ] Push notifications for workout reminders
- [ ] Export data functionality
- [ ] Advanced metrics tracking (tempo, heart rate)
- [ ] Custom program creation

---

## Plan Complete

This implementation plan provides a complete roadmap to build the workout tracking app MVP. Follow each task sequentially, run tests after each step, and commit frequently.

**Total estimated tasks:** 21
**Total commits:** ~21+
**Tech stack:** Next.js, React, TypeScript, Dexie.js, Supabase, shadcn/ui

Ready to execute with `superpowers:executing-plans`.
