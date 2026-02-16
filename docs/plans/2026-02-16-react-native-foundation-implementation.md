# React Native Foundation - Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Set up the React Native development environment with Expo, create basic project structure, configure navigation with Expo Router, set up styling with NativeWind and React Native Paper, and establish the data layer with AsyncStorage.

**Architecture:** Mobile-first React Native app using Expo SDK for simplified build/deployment, Expo Router for file-based navigation (matching Next.js patterns), React Native Paper for Material Design 3 components, NativeWind for Tailwind CSS compatibility, and AsyncStorage for local-first data persistence replacing IndexedDB.

**Tech Stack:** React Native, Expo SDK 51+, Expo Router, React Native Paper, NativeWind, Tailwind CSS, AsyncStorage, React Context, TypeScript, Jest, React Native Testing Library

---

## Prerequisites

Before starting this plan, ensure you have:
- Node.js 18+ installed
- macOS with Xcode 15+ (for iOS development)
- CocoaPods installed (`sudo gem install cocoapods`)
- iOS Simulator available (installed with Xcode)
- Android Studio optional (for Android development)
- Expo CLI: `npm install -g expo-cli`
- EAS CLI: `npm install -g eas-cli`

---

## Task 1: Initialize Expo Project with TypeScript

### Step 1: Create new Expo project

Run:
```bash
cd /path/to/Projects
npx create-expo-app@latest strength-app --template blank-typescript
```

Expected: Project created with TypeScript template

### Step 2: Navigate into project

Run:
```bash
cd strength-app
```

Expected: Now in project directory

### Step 3: Install core dependencies

Run:
```bash
npm install expo-router react-native-paper react-native-safe-area-context
npm install @react-navigation/native react-native-screens react-native-gesture-handler
npm install @react-native-async-storage/async-storage
npm install react-native-reanimated
```

Expected: All dependencies installed successfully

### Step 4: Install dev dependencies

Run:
```bash
npm install --save-dev jest @testing-library/react-native @testing-library/jest-native
npm install --save-dev @types/jest
```

Expected: Dev dependencies installed

### Step 5: Install NativeWind and Tailwind

Run:
```bash
npm install nativewind tailwindcss
npm install --save-dev babel-preset-expo
```

Expected: NativeWind and Tailwind installed

### Step 6: Install charting library

Run:
```bash
npm install victory-native
```

Expected: Victory Native installed

### Step 7: Install Supabase client

Run:
```bash
npm install @supabase/supabase-js
```

Expected: Supabase client installed

### Step 8: Initialize Git repository

Run:
```bash
git init
git add .
git commit -m "chore: initialize Expo project with TypeScript

Create blank Expo app with TypeScript template
Install core dependencies: Expo Router, React Native Paper, AsyncStorage
Install dev dependencies: Jest, React Native Testing Library
Install NativeWind and Tailwind CSS for styling
Install Victory Native for charts
Install Supabase client for future sync

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

Expected: Git repository initialized with initial commit

---

## Task 2: Configure Tailwind CSS and NativeWind

### Step 1: Create Tailwind config

Create: `tailwind.config.js`

```javascript
/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    './App.{js,jsx,ts,tsx}',
    './components/**/*.{js,jsx,ts,tsx}',
    './app/**/*.{js,jsx,ts,tsx}',
  ],
  theme: {
    extend: {
      colors: {
        primary: '#6366f1',
        secondary: '#8b5cf6',
        success: '#10b981',
        warning: '#f59e0b',
        error: '#ef4444',
        background: '#ffffff',
        surface: '#f3f4f6',
      },
    },
  },
  plugins: [],
};
```

### Step 2: Create Babel config for NativeWind

Create: `babel.config.js`

```javascript
module.exports = function (api) {
  api.cache(true);
  return {
    presets: ['babel-preset-expo', 'nativewind/babel'],
    plugins: ['react-native-reanimated/plugin'],
  };
};
```

### Step 3: Create CSS file for Tailwind directives

Create: `global.css`

```css
@tailwind base;
@tailwind components;
@tailwind utilities;
```

### Step 4: Update metro config to handle CSS

Modify: `metro.config.js`

```javascript
const { getDefaultConfig } = require('expo/metro-config');
const { withNativeWind } = require('nativewind/metro');

const config = getDefaultConfig(__dirname);

module.exports = withNativeWind(config, { input: './global.css' });
```

### Step 5: Commit Tailwind configuration

Run:
```bash
git add tailwind.config.js babel.config.js global.css metro.config.js
git commit -m "feat: configure Tailwind CSS and NativeWind

Create Tailwind config with custom color theme
Add Babel preset for NativeWind
Create global.css with Tailwind directives
Configure Metro bundler to process CSS files

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Task 3: Create Type Definitions

### Step 1: Create program types

Create: `types/program.ts`

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

### Step 2: Create workout types

Create: `types/workout.ts`

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

### Step 3: Create user types

Create: `types/user.ts`

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

### Step 4: Create barrel export

Create: `types/index.ts`

```typescript
export * from './program';
export * from './workout';
export * from './user';
```

### Step 5: Write test for type imports

Create: `types/__tests__/index.test.ts`

```typescript
import { Program, CompletedSet, User, ExperienceLevel } from '../index';

describe('Type Exports', () => {
  it('should export Program type', () => {
    const program: Program = {
      id: 'test',
      name: 'Test Program',
      category: 'back-squat',
      description: 'Test',
      durationWeeks: 8,
      daysPerWeek: 3,
      exercises: ['back-squat'],
      difficulty: 'intermediate',
      weeks: [],
    };
    expect(program).toBeDefined();
  });

  it('should export CompletedSet type', () => {
    const set: CompletedSet = {
      id: '1',
      workoutId: '1',
      exerciseId: 'back-squat',
      setNumber: 1,
      actualWeight: 225,
      actualReps: 5,
      prescribedReps: 5,
      createdAt: new Date(),
    };
    expect(set).toBeDefined();
  });

  it('should export User type', () => {
    const experience: ExperienceLevel = 'beginner';
    expect(experience).toBe('beginner');
  });
});
```

### Step 6: Run type check

Run:
```bash
npx tsc --noEmit
```

Expected: No type errors

### Step 7: Run tests

Run:
```bash
npm test -- types/__tests__/index.test.ts
```

Expected: Tests pass

### Step 8: Commit type definitions

Run:
```bash
git add types/
git commit -m "feat: add TypeScript type definitions

Define core types for programs, workouts, and users
Add ProgramCategory, DifficultyLevel, Exercise, Day, Week, Program
Add CompletedSet, CompletedWorkout, OneRepMax, ActiveCycle, SetMetrics
Add User with experience level and goal types
Create barrel export for easy importing
Write tests to verify type exports

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Task 4: Create Utility Functions

### Step 1: Create utility functions file

Create: `lib/utils.ts`

```typescript
import { clsx, type ClassValue } from 'clsx';
import { twMerge } from 'tailwind-merge';

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}

export function roundToNearestFive(value: number): number {
  return Math.round(value / 5) * 5;
}

export function generateId(): string {
  return crypto.randomUUID();
}
```

### Step 2: Install clsx and tailwind-merge

Run:
```bash
npm install clsx tailwind-merge
```

Expected: Packages installed

### Step 3: Write test for cn function

Create: `lib/__tests__/utils.test.ts`

```typescript
import { describe, it, expect } from '@jest/globals';
import { cn, roundToNearestFive, generateId } from '../utils';

describe('cn utility', () => {
  it('merges tailwind classes', () => {
    const result = cn('px-2', 'py-1');
    expect(result).toBe('px-2 py-1');
  });

  it('removes conflicting classes', () => {
    const result = cn('px-2', 'px-4');
    expect(result).toBe('px-4');
  });

  it('handles conditional classes', () => {
    const result = cn('base-class', false && 'remove-me', true && 'keep-me');
    expect(result).toBe('base-class keep-me');
  });
});

describe('roundToNearestFive', () => {
  it('rounds to nearest 5', () => {
    expect(roundToNearestFive(197)).toBe(195);
    expect(roundToNearestFive(198)).toBe(200);
    expect(roundToNearestFive(200)).toBe(200);
  });

  it('handles edge cases', () => {
    expect(roundToNearestFive(0)).toBe(0);
    expect(roundToNearestFive(2.5)).toBe(0);
    expect(roundToNearestFive(3)).toBe(5);
  });
});

describe('generateId', () => {
  it('generates unique IDs', () => {
    const id1 = generateId();
    const id2 = generateId();
    expect(id1).not.toBe(id2);
  });

  it('generates valid UUID format', () => {
    const id = generateId();
    expect(id).toMatch(/^[0-9a-f-]{36}$/);
  });
});
```

### Step 4: Run tests

Run:
```bash
npm test -- lib/__tests__/utils.test.ts
```

Expected: All tests pass

### Step 5: Commit utilities

Run:
```bash
git add lib/utils.ts lib/__tests__/utils.test.ts
git commit -m "feat: add utility functions

Add cn() for merging Tailwind classes with conflict resolution
Add roundToNearestFive() for weight calculations
Add generateId() for unique ID generation using UUID
Install clsx and tailwind-merge dependencies
Write comprehensive tests for all utilities

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Task 5: Set up AsyncStorage Layer

### Step 1: Create AsyncStorage keys and helpers

Create: `lib/storage/async-storage.ts`

```typescript
import AsyncStorage from '@react-native-async-storage/async-storage';

export const STORAGE_KEYS = {
  USER: '@strength_user',
  ONE_REP_MAXES: '@strength_one_rep_maxes',
  ACTIVE_CYCLES: '@strength_active_cycles',
  COMPLETED_WORKOUTS: '@strength_completed_workouts',
  COMPLETED_SETS: '@strength_completed_sets',
} as const;

export async function getItem<T>(key: string): Promise<T | null> {
  try {
    const json = await AsyncStorage.getItem(key);
    return json ? JSON.parse(json) : null;
  } catch (error) {
    console.error(`Error getting item ${key}:`, error);
    return null;
  }
}

export async function setItem<T>(key: string, value: T): Promise<void> {
  try {
    await AsyncStorage.setItem(key, JSON.stringify(value));
  } catch (error) {
    console.error(`Error setting item ${key}:`, error);
    throw error;
  }
}

export async function removeItem(key: string): Promise<void> {
  try {
    await AsyncStorage.removeItem(key);
  } catch (error) {
    console.error(`Error removing item ${key}:`, error);
    throw error;
  }
}

export async function clear(): Promise<void> {
  try {
    await AsyncStorage.clear();
  } catch (error) {
    console.error('Error clearing storage:', error);
    throw error;
  }
}
```

### Step 2: Create database access layer

Create: `lib/storage/database.ts`

```typescript
import { getItem, setItem, STORAGE_KEYS } from './async-storage';
import { generateId } from '../utils';
import type { User, OneRepMax, ActiveCycle } from '@/types';

// User operations
export async function createUser(data: Omit<User, 'id' | 'createdAt'>): Promise<User> {
  const user: User = {
    id: generateId(),
    ...data,
    createdAt: new Date(),
  };
  await setItem(STORAGE_KEYS.USER, user);
  return user;
}

export async function getUser(): Promise<User | null> {
  return getItem<User>(STORAGE_KEYS.USER);
}

export async function updateUser(id: string, updates: Partial<User>): Promise<void> {
  const user = await getUser();
  if (user && user.id === id) {
    await setItem(STORAGE_KEYS.USER, { ...user, ...updates });
  }
}

// 1RM operations
export async function saveOneRepMax(oneRepMax: OneRepMax): Promise<void> {
  const all1RMs = await getItem<OneRepMax[]>(STORAGE_KEYS.ONE_REP_MAXES) || [];
  all1RMs.push(oneRepMax);
  await setItem(STORAGE_KEYS.ONE_REP_MAXES, all1RMs);
}

export async function getLatest1RM(userId: string, exerciseId: string): Promise<OneRepMax | undefined> {
  const all1RMs = await getItem<OneRepMax[]>(STORAGE_KEYS.ONE_REP_MAXES) || [];
  const user1RMs = all1RMs
    .filter(orm => orm.userId === userId && orm.exerciseId === exerciseId)
    .sort((a, b) => new Date(b.date).getTime() - new Date(a.date).getTime());
  return user1RMs[0];
}

// Active cycles operations
export async function saveActiveCycle(cycle: ActiveCycle): Promise<void> {
  const cycles = await getItem<ActiveCycle[]>(STORAGE_KEYS.ACTIVE_CYCLES) || [];
  const existingIndex = cycles.findIndex(c => c.id === cycle.id);

  if (existingIndex >= 0) {
    cycles[existingIndex] = cycle;
  } else {
    cycles.push(cycle);
  }

  await setItem(STORAGE_KEYS.ACTIVE_CYCLES, cycles);
}

export async function getActiveCycles(userId: string): Promise<ActiveCycle[]> {
  const cycles = await getItem<ActiveCycle[]>(STORAGE_KEYS.ACTIVE_CYCLES) || [];
  return cycles.filter(c => c.userId === userId && c.status === 'active');
}
```

### Step 3: Create path alias for imports

Modify: `tsconfig.json`

```json
{
  "extends": "expo/tsconfig.base",
  "compilerOptions": {
    "strict": true,
    "baseUrl": ".",
    "paths": {
      "@/*": ["./*"]
    }
  }
}
```

### Step 4: Write test for storage operations

Create: `lib/storage/__tests__/database.test.ts`

```typescript
import { describe, it, expect, beforeEach, afterEach } from '@jest/globals';
import { createUser, getUser, updateUser, saveOneRepMax, getLatest1RM, saveActiveCycle, getActiveCycles } from '../database';
import { clear } from '../async-storage';
import type { User, OneRepMax, ActiveCycle } from '@/types';

describe('Database Operations', () => {
  afterEach(async () => {
    await clear();
  });

  describe('User operations', () => {
    it('should create and retrieve user', async () => {
      const user = await createUser({
        name: 'Test User',
        experienceLevel: 'beginner',
        primaryGoal: 'strength',
      });

      expect(user.id).toBeDefined();
      expect(user.name).toBe('Test User');

      const retrieved = await getUser();
      expect(retrieved).toEqual(user);
    });

    it('should update user', async () => {
      const user = await createUser({
        name: 'Test User',
        experienceLevel: 'beginner',
        primaryGoal: 'strength',
      });

      await updateUser(user.id, { name: 'Updated Name' });

      const updated = await getUser();
      expect(updated?.name).toBe('Updated Name');
    });

    it('should return null when no user exists', async () => {
      const user = await getUser();
      expect(user).toBeNull();
    });
  });

  describe('1RM operations', () => {
    it('should save and retrieve latest 1RM', async () => {
      const user = await createUser({
        name: 'Test',
        experienceLevel: 'intermediate',
        primaryGoal: 'strength',
      });

      const old1RM: OneRepMax = {
        id: '1',
        userId: user.id,
        exerciseId: 'back-squat',
        weight: 225,
        date: new Date('2024-01-01'),
      };

      const new1RM: OneRepMax = {
        id: '2',
        userId: user.id,
        exerciseId: 'back-squat',
        weight: 235,
        date: new Date('2024-02-01'),
      };

      await saveOneRepMax(old1RM);
      await saveOneRepMax(new1RM);

      const latest = await getLatest1RM(user.id, 'back-squat');
      expect(latest?.weight).toBe(235);
    });
  });

  describe('Active cycle operations', () => {
    it('should retrieve only active cycles', async () => {
      const user = await createUser({
        name: 'Test',
        experienceLevel: 'intermediate',
        primaryGoal: 'strength',
      });

      const activeCycle: ActiveCycle = {
        id: '1',
        userId: user.id,
        programId: 'back-squat-5x5',
        cycleName: 'Active Cycle',
        startDate: new Date(),
        currentWeek: 1,
        status: 'active',
      };

      const completedCycle: ActiveCycle = {
        id: '2',
        userId: user.id,
        programId: 'bench-press',
        cycleName: 'Completed Cycle',
        startDate: new Date(),
        currentWeek: 8,
        status: 'completed',
      };

      await saveActiveCycle(activeCycle);
      await saveActiveCycle(completedCycle);

      const activeCycles = await getActiveCycles(user.id);
      expect(activeCycles).toHaveLength(1);
      expect(activeCycles[0].status).toBe('active');
    });
  });
});
```

### Step 5: Run tests

Run:
```bash
npm test -- lib/storage/__tests__/database.test.ts
```

Expected: All tests pass

### Step 6: Commit storage layer

Run:
```bash
git add lib/storage/ tsconfig.json
git commit -m "feat: implement AsyncStorage database layer

Create AsyncStorage helper functions (getItem, setItem, removeItem)
Define storage keys for all data types
Implement database access functions for users, 1RMs, and active cycles
Add path alias configuration (@/*) for clean imports
Write comprehensive tests for all storage operations
Handle errors gracefully with try-catch blocks

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Task 6: Create Business Logic (Calculations)

### Step 1: Create calculation utilities

Create: `lib/calculations.ts`

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

### Step 2: Write tests for calculations

Create: `lib/__tests__/calculations.test.ts`

```typescript
import { describe, it, expect } from '@jest/globals';
import { calculateTargetWeight, isPersonalRecord, calculateVolumeLoad, detectPlateau } from '../calculations';

describe('Target Weight Calculator', () => {
  it('calculates 65% of 1RM correctly', () => {
    const result = calculateTargetWeight(300, 0.65);
    expect(result).toBe(195);
  });

  it('rounds to nearest 5 lbs', () => {
    const result = calculateTargetWeight(317, 0.65);
    expect(result).toBe(205);
  });

  it('handles 80% intensity', () => {
    const result = calculateTargetWeight(300, 0.80);
    expect(result).toBe(240);
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
    expect(result).toBe(5625);
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

### Step 3: Run tests

Run:
```bash
npm test -- lib/__tests__/calculations.test.ts
```

Expected: All tests pass

### Step 4: Commit calculations

Run:
```bash
git add lib/calculations.ts lib/__tests__/calculations.test.ts
git commit -m "feat: add calculation utilities for workouts

Implement calculateTargetWeight (rounds to nearest 5lbs)
Add isPersonalRecord, calculateVolumeLoad, detectPlateau
Write comprehensive tests for all calculation functions
Business logic is platform-independent (copied from web app)

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Task 7: Create React Context Providers

### Step 1: Create User Context

Create: `contexts/user-context.tsx`

```typescript
'use client';

import React, { createContext, useContext, useState, useEffect } from 'react';
import type { User, OneRepMax, SyncStatus } from '@/types';
import { getUser, updateUser, getLatest1RM } from '@/lib/storage/database';
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
      date: new Date(),
    };

    const { saveOneRepMax } = await import('@/lib/storage/database');
    await saveOneRepMax(new1RM);
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
      refresh,
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

### Step 2: Create Exercise Context

Create: `contexts/exercise-context.tsx`

```typescript
'use client';

import React, { createContext, useContext, useMemo } from 'react';
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

// TODO: Load programs from data files
const MOCK_PROGRAMS: Program[] = [];

export function ExerciseProvider({ children }: { children: React.ReactNode }) {
  const programs = useMemo(() => MOCK_PROGRAMS, []);

  function getProgram(id: string): Program | undefined {
    return programs.find(p => p.id === id);
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
      calculatePrescribedWeight,
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

### Step 3: Create combined Providers wrapper

Create: `contexts/providers.tsx`

```typescript
'use client';

import React from 'react';
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

### Step 4: Write test for User Context

Create: `contexts/__tests__/user-context.test.tsx`

```typescript
import { describe, it, expect, beforeEach } from '@jest/globals';
import { renderHook, act, waitFor } from '@testing-library/react';
import { UserProvider, useUser } from '../user-context';
import { createUser, getUser } from '@/lib/storage/database';
import { clear } from '@/lib/storage/async-storage';

describe('User Context', () => {
  beforeEach(async () => {
    await clear();
  });

  it('provides null when no user exists', async () => {
    const { result } = renderHook(() => useUser(), {
      wrapper: UserProvider,
    });

    expect(result.current.user).toBeNull();
  });

  it('loads user on mount', async () => {
    await createUser({
      name: 'Test User',
      experienceLevel: 'beginner',
      primaryGoal: 'strength',
    });

    const { result } = renderHook(() => useUser(), {
      wrapper: UserProvider,
    });

    await waitFor(() => {
      expect(result.current.user).toBeDefined();
      expect(result.current.user?.name).toBe('Test User');
    });
  });

  it('updates user profile', async () => {
    const user = await createUser({
      name: 'Test User',
      experienceLevel: 'beginner',
      primaryGoal: 'strength',
    });

    const { result } = renderHook(() => useUser(), {
      wrapper: UserProvider,
    });

    await waitFor(() => {
      expect(result.current.user).toBeDefined();
    });

    await act(async () => {
      await result.current.updateUserProfile({ name: 'Updated Name' });
    });

    expect(result.current.user?.name).toBe('Updated Name');

    // Verify persisted
    const fromDb = await getUser();
    expect(fromDb?.name).toBe('Updated Name');
  });
});
```

### Step 5: Run tests

Run:
```bash
npm test -- contexts/__tests__/user-context.test.tsx
```

Expected: All tests pass

### Step 6: Commit contexts

Run:
```bash
git add contexts/
git commit -m "feat: create React Context providers

Add UserProvider with user profile and 1RM state management
Implement updateUserProfile and update1RM functions
Add ExerciseProvider for program data access
Create Providers wrapper combining both contexts
Write tests for User Context loading and updates
Add useUser and useExercise custom hooks

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Task 8: Configure Expo Router

### Step 1: Update app.json for Expo Router

Modify: `app.json`

```json
{
  "expo": {
    "name": "Strength",
    "slug": "strength",
    "version": "1.0.0",
    "orientation": "portrait",
    "icon": "./assets/icon.png",
    "userInterfaceStyle": "automatic",
    "splash": {
      "image": "./assets/splash.png",
      "resizeMode": "contain",
      "backgroundColor": "#ffffff"
    },
    "assetBundlePatterns": [
      "**/*"
    ],
    "ios": {
      "supportsTablet": false,
      "bundleIdentifier": "com.strengthapp.mobile"
    },
    "android": {
      "adaptiveIcon": {
        "foregroundImage": "./assets/adaptive-icon.png",
        "backgroundColor": "#ffffff"
      },
      "package": "com.strengthapp.mobile"
    },
    "web": {
      "favicon": "./assets/favicon.png"
    },
    "scheme": "strengthapp",
    "experiments": {
      "typedRoutes": true
    }
  }
}
```

### Step 2: Create root layout with Providers

Create: `app/_layout.tsx`

```typescript
import { Stack } from 'expo-router';
import { Providers } from '@/contexts/providers';
import * as SplashScreen from 'expo-splash-screen';
import { useFonts } from 'expo-font';
import { useEffect } from 'react';

// Keep the splash screen visible while resources load
SplashScreen.preventAutoHideAsync();

export default function RootLayout() {
  const [fontsLoaded] = useFonts({
    // Add custom fonts here if needed
  });

  useEffect(() => {
    if (fontsLoaded) {
      SplashScreen.hideAsync();
    }
  }, [fontsLoaded]);

  if (!fontsLoaded) {
    return null;
  }

  return (
    <Providers>
      <Stack screenOptions={{ headerShown: false }}>
        <Stack.Screen name="index" />
        <Stack.Screen name="onboarding" />
        <Stack.Screen name="(tabs)" />
      </Stack>
    </Providers>
  );
}
```

### Step 3: Create home page (redirects)

Create: `app/index.tsx`

```typescript
import { Redirect } from 'expo-router';
import { useUser } from '@/contexts/user-context';
import { ActivityIndicator, View } from 'react-native';

export default function HomePage() {
  const { user } = useUser();

  if (!user) {
    return <Redirect href="/onboarding" />;
  }

  return <Redirect href="/(tabs)/dashboard" />;
}
```

### Step 4: Create tab layout

Create: `app/(tabs)/_layout.tsx`

```typescript
import { Tabs } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';

export default function TabLayout() {
  return (
    <Tabs
      screenOptions={{
        tabBarActiveTintColor: '#6366f1',
        headerShown: false,
      }}
    >
      <Tabs.Screen
        name="dashboard"
        options={{
          title: 'Dashboard',
          tabBarIcon: ({ color }) => <Ionicons name="grid-outline" size={28} color={color} />,
        }}
      />
      <Tabs.Screen
        name="programs"
        options={{
          title: 'Programs',
          tabBarIcon: ({ color }) => <Ionicons name="barbell-outline" size={28} color={color} />,
        }}
      />
      <Tabs.Screen
        name="workout"
        options={{
          title: 'Workout',
          tabBarIcon: ({ color }) => <Ionicons name="fitness-outline" size={28} color={color} />,
        }}
      />
      <Tabs.Screen
        name="progress"
        options={{
          title: 'Progress',
          tabBarIcon: ({ color }) => <Ionicons name="trending-up-outline" size={28} color={color} />,
        }}
      />
    </Tabs>
  );
}
```

### Step 5: Create placeholder screens

Create: `app/(tabs)/dashboard.tsx`

```typescript
import { View, Text } from 'react-native';

export default function DashboardScreen() {
  return (
    <View style={{ flex: 1, justifyContent: 'center', alignItems: 'center' }}>
      <Text>Dashboard</Text>
    </View>
  );
}
```

Create: `app/(tabs)/programs.tsx`

```typescript
import { View, Text } from 'react-native';

export default function ProgramsScreen() {
  return (
    <View style={{ flex: 1, justifyContent: 'center', alignItems: 'center' }}>
      <Text>Programs</Text>
    </View>
  );
}
```

Create: `app/(tabs)/workout.tsx`

```typescript
import { View, Text } from 'react-native';

export default function WorkoutScreen() {
  return (
    <View style={{ flex: 1, justifyContent: 'center', alignItems: 'center' }}>
      <Text>Workout</Text>
    </View>
  );
}
```

Create: `app/(tabs)/progress.tsx`

```typescript
import { View, Text } from 'react-native';

export default function ProgressScreen() {
  return (
    <View style={{ flex: 1, justifyContent: 'center', alignItems: 'center' }}>
      <Text>Progress</Text>
    </View>
  );
}
```

### Step 6: Create onboarding screen

Create: `app/onboarding.tsx`

```typescript
import { View, Text } from 'react-native';

export default function OnboardingScreen() {
  return (
    <View style={{ flex: 1, justifyContent: 'center', alignItems: 'center' }}>
      <Text>Onboarding</Text>
    </View>
  );
}
```

### Step 7: Install required dependencies

Run:
```bash
npm install expo-splash-screen expo-font @expo/vector-icons
```

Expected: Packages installed

### Step 8: Clear Metro cache and start dev server

Run:
```bash
npx expo start --clear
```

Expected: Metro bundler starts successfully

### Step 9: Test on iOS Simulator

In the Expo terminal, press: `i`

Expected: App launches in iOS Simulator with 4 tabs visible

### Step 10: Test navigation

Verify:
- [ ] All 4 tabs are visible
- [ ] Tapping tabs switches screens
- [ ] Active tab is highlighted in purple

### Step 11: Commit routing setup

Run:
```bash
git add app/ app.json
git commit -m "feat: configure Expo Router with tab navigation

Update app.json for Expo Router support
Create root layout with Providers wrapper
Implement bottom tab navigation with 4 tabs (Dashboard, Programs, Workout, Progress)
Add Ionicons for tab icons
Create placeholder screens for all routes
Implement home page redirect logic based on user auth
Install expo-splash-screen and expo-font
Test on iOS Simulator successfully

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Task 9: Set up Jest Configuration

### Step 1: Create Jest configuration

Create: `jest.config.js`

```javascript
const { defaults: tsjPreset } = require('ts-jest/presets');

module.exports = {
  preset: 'react-native',
  moduleFileExtensions: ['ts', 'tsx', 'js', 'jsx'],
  setupFilesAfterEnv: ['@testing-library/jest-native/extend-expect'],
  transform: {
    '^.+\\.(js|jsx|ts|tsx)$': ['ts-jest', tsjPreset],
  },
  transformIgnorePatterns: [
    'node_modules/(?!(@react-native|react-native|expo|@expo|react-native-paper|@react-native-async-storage|react-native-reanimated))',
  ],
  testMatch: ['**/__tests__/**/*.(test|spec).(ts|tsx|js)'],
  moduleNameMapper: {
    '^@/(.*)$': '<rootDir>/$1',
  },
  collectCoverageFrom: [
    'app/**/*.{ts,tsx}',
    'components/**/*.{ts,tsx}',
    'contexts/**/*.{ts,tsx}',
    'lib/**/*.{ts,tsx}',
    '!**/*.d.ts',
  ],
};
```

### Step 2: Update package.json with test script

Modify: `package.json`

Add to scripts section:
```json
{
  "scripts": {
    "start": "expo start",
    "android": "expo start --android",
    "ios": "expo start --ios",
    "web": "expo start --web",
    "test": "jest",
    "test:watch": "jest --watch",
    "test:coverage": "jest --coverage"
  }
}
```

### Step 3: Run all tests

Run:
```bash
npm test
```

Expected: All existing tests pass

### Step 4: Commit Jest config

Run:
```bash
git add jest.config.js package.json
git commit -m "test: configure Jest for React Native testing

Create Jest configuration with TypeScript support
Add React Native preset and setup files
Configure transform ignore patterns for node_modules
Set up module name mapper for @/* imports
Add test, test:watch, and test:coverage scripts to package.json
Verify all existing tests pass

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Task 10: Create Constants for Design Tokens

### Step 1: Create color constants

Create: `constants/colors.ts`

```typescript
export const Colors = {
  primary: '#6366f1',
  secondary: '#8b5cf6',
  success: '#10b981',
  warning: '#f59e0b',
  error: '#ef4444',
  background: '#ffffff',
  surface: '#f3f4f6',
  text: {
    primary: '#111827',
    secondary: '#6b7280',
    disabled: '#9ca3af',
  },
} as const;

export type Colors = typeof Colors;
```

### Step 2: Create typography constants

Create: `constants/typography.ts`

```typescript
export const Typography = {
  headingLarge: {
    fontSize: 32,
    fontWeight: '700' as const,
    lineHeight: 40,
  },
  headingMedium: {
    fontSize: 24,
    fontWeight: '600' as const,
    lineHeight: 32,
  },
  headingSmall: {
    fontSize: 20,
    fontWeight: '600' as const,
    lineHeight: 28,
  },
  body: {
    fontSize: 16,
    fontWeight: '400' as const,
    lineHeight: 24,
  },
  caption: {
    fontSize: 14,
    fontWeight: '400' as const,
    lineHeight: 20,
  },
  small: {
    fontSize: 12,
    fontWeight: '400' as const,
    lineHeight: 16,
  },
} as const;

export type Typography = typeof Typography;
```

### Step 3: Create spacing constants

Create: `constants/spacing.ts`

```typescript
export const Spacing = {
  xs: 4,
  sm: 8,
  md: 16,
  lg: 24,
  xl: 32,
  xxl: 48,
} as const;

export type Spacing = typeof Spacing;
```

### Step 4: Create barrel export

Create: `constants/index.ts`

```typescript
export * from './colors';
export * from './typography';
export * from './spacing';
```

### Step 5: Commit design tokens

Run:
```bash
git add constants/
git commit -m "feat: add design token constants

Create Colors constant with brand color palette
Add Typography constant with font size and weight scales
Define Spacing constant for consistent margins/padding
Export all constants from index file
Centralize design system for easy theming

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Task 11: Create Basic UI Component Wrappers

### Step 1: Create Button wrapper

Create: `components/ui/button.tsx`

```typescript
import { Button as PaperButton } from 'react-native-paper';

interface ButtonProps {
  children: React.ReactNode;
  onPress?: () => void;
  mode?: 'text' | 'outlined' | 'contained';
  loading?: boolean;
  disabled?: boolean;
  style?: any;
}

export function Button({
  children,
  mode = 'contained',
  ...props
}: ButtonProps) {
  return (
    <PaperButton mode={mode} {...props}>
      {children}
    </PaperButton>
  );
}
```

### Step 2: Create Card wrapper

Create: `components/ui/card.tsx`

```typescript
import React from 'react';
import { Card as PaperCard } from 'react-native-paper';
import { View } from 'react-native';

interface CardProps {
  children: React.ReactNode;
  style?: any;
}

export function Card({ children, style }: CardProps) {
  return (
    <PaperCard style={[{ padding: 16, borderRadius: 8 }, style]}>
      {children}
    </PaperCard>
  );
}
```

### Step 3: Create Text wrapper

Create: `components/ui/text.tsx`

```typescript
import React from 'react';
import { Text as PaperText } from 'react-native-paper';
import { Typography } from '@/constants';

interface TextProps {
  children: React.ReactNode;
  variant?: keyof typeof Typography;
  style?: any;
}

export function Text({ children, variant = 'body', style }: TextProps) {
  return (
    <PaperText style={[Typography[variant], style]}>
      {children}
    </PaperText>
  );
}
```

### Step 4: Write test for Button component

Create: `components/ui/__tests__/button.test.tsx`

```typescript
import { describe, it, expect } from '@jest/globals';
import { render, screen } from '@testing-library/react-native';
import { Button } from '../button';
import { Text } from 'react-native';

describe('Button Component', () => {
  it('renders children', () => {
    render(<Button>Click me</Button>);
    expect(screen.getByText('Click me')).toBeTruthy();
  });

  it('calls onPress when pressed', () => {
    const onPress = jest.fn();
    const { getByText } = render(<Button onPress={onPress}>Press me</Button>);

    getByText('Press me').props.onPress();
    expect(onPress).toHaveBeenCalledTimes(1);
  });

  it('shows loading state', () => {
    const { getByRole } = render(<Button loading>Loading</Button>);
    // Paper Button shows activity indicator when loading
    expect(getByRole('button')).toBeTruthy();
  });
});
```

### Step 5: Run tests

Run:
```bash
npm test -- components/ui/__tests__/button.test.tsx
```

Expected: All tests pass

### Step 6: Commit UI components

Run:
```bash
git add components/ui/
git commit -m "feat: create basic UI component wrappers

Add Button wrapper around React Native Paper Button
Create Card wrapper with default padding and radius
Implement Text wrapper with typography variants
Write tests for Button component
Provide consistent API for common UI elements

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Task 12: Final Verification and Cleanup

### Step 1: Run all tests

Run:
```bash
npm test
```

Expected: All tests pass

### Step 2: Type check the project

Run:
```bash
npx tsc --noEmit
```

Expected: No type errors

### Step 3: Test app on iOS Simulator

Run:
```bash
npx expo start --clear
```

Press `i` to launch iOS Simulator

Verify:
- [ ] App launches without errors
- [ ] All 4 tabs visible and working
- [ ] No console errors

### Step 4: Check git status

Run:
```bash
git status
```

Expected: Only uncommitted files are intentionally ignored (node_modules, .expo, etc.)

### Step 5: Create .gitignore

Modify: `.gitignore`

Ensure these entries exist:
```
# Expo
.expo/
dist/
web-build/

# Dependencies
node_modules/

# Native
*.orig.*
*.jks
*.p8
*.p12
*.key
*.mobileprovision
*.pem

# Metro
.metro-health-check*

# Debug
npm-debug.*
yarn-debug.*
yarn-error.*

# macOS
.DS_Store

# Temporary files
*.swp
*.swo
*~
```

### Step 6: Update README

Create: `README.md`

```markdown
# Strength - React Native Workout Tracker

Mobile-first workout tracking app for iOS and Android.

## Tech Stack

- React Native via Expo SDK 51+
- Expo Router for navigation
- React Native Paper for UI components
- NativeWind for Tailwind CSS styling
- AsyncStorage for local persistence
- TypeScript for type safety

## Development

### Prerequisites

- Node.js 18+
- macOS with Xcode 15+ (iOS development)
- CocoaPods installed

### Setup

```bash
# Install dependencies
npm install

# Start development server
npm start

# Run on iOS Simulator
npm run ios

# Run on Android Emulator
npm run android
```

### Testing

```bash
# Run all tests
npm test

# Run tests in watch mode
npm run test:watch

# Generate coverage report
npm run test:coverage
```

### Build

```bash
# Install EAS CLI
npm install -g eas-cli

# Build for iOS (development)
eas build --platform ios --profile development

# Build for TestFlight
eas build --platform ios --profile preview

# Build for App Store
eas build --platform ios --profile production
```

## Project Status

This is the Foundation phase (Phase 1) of the React Native migration.

### Completed
- ✅ Project setup with Expo and TypeScript
- ✅ Navigation configured with Expo Router
- ✅ Basic UI component wrappers
- ✅ AsyncStorage database layer
- ✅ React Context providers
- ✅ Business logic (calculations)
- ✅ Jest testing configuration
- ✅ Design token constants

### In Progress
- 🔄 Phase 2: Data Layer & Contexts completion
- 🔄 Phase 3: Onboarding & Core Flows

### Roadmap
See [docs/plans/2026-02-16-react-native-ios-app-design.md](docs/plans/2026-02-16-react-native-ios-app-design.md) for complete roadmap.

## License

MIT
```

### Step 7: Final commit

Run:
```bash
git add .gitignore README.md
git commit -m "docs: add README and finalize foundation phase

Update README with tech stack, development setup, and testing instructions
Add comprehensive .gitignore for React Native/Expo projects
Verify all tests pass and type checking succeeds
Confirm app runs successfully on iOS Simulator

Foundation phase complete:
- Project structure established
- Navigation working with 4 tabs
- Storage layer functional
- Context providers implemented
- Testing configured
- Ready for Phase 2: Data Layer & Contexts

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Completion Checklist

After completing this implementation plan:

- [ ] Expo project initialized with TypeScript
- [ ] Tailwind CSS and NativeWind configured
- [ ] Type definitions created and tested
- [ ] AsyncStorage database layer implemented
- [ ] Business logic (calculations) ported
- [ ] React Context providers created
- [ ] Expo Router configured with tab navigation
- [ ] Jest configured for testing
- [ ] Design token constants created
- [ ] Basic UI component wrappers implemented
- [ ] All tests passing
- [ ] Type checking passes
- [ ] App runs successfully on iOS Simulator
- [ ] README documentation complete

---

## Next Steps

After completing this Foundation phase, proceed to **Phase 2: Data Layer & Contexts** which will:
- Port program data JSON files from web app
- Implement complete storage operations for all data types
- Add comprehensive error handling
- Write additional context tests
- Set up Supabase client configuration

---

## Plan Complete

This implementation plan provides the complete Foundation phase setup for the React Native migration. Follow each task sequentially, run tests after each step, and commit frequently.

**Total estimated time:** 8-12 hours
**Total commits:** ~12 commits
**Files created/modified:** ~40 files

Ready to execute with `superpowers:executing-plans`.
