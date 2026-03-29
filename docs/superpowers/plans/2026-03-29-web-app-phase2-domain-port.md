# Phase 2: Port Domain Logic — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Port all 27 Swift Domain files to TypeScript with 100% test coverage, preserving exact business logic, constants, and multipliers.

**Architecture:** Pure TypeScript functions in `web-app/src/lib/domain/` with zero framework dependencies. Tests in Vitest matching Swift test cases 1:1.

**Tech Stack:** TypeScript, Vitest

---

### Task 1: Set Up Vitest

**Files:**
- Modify: `web-app/package.json` (add vitest)
- Create: `web-app/vitest.config.ts`

- [ ] **Step 1: Install Vitest**

```bash
cd /Users/dustinober/Projects/sundee-fundee/web-app
npm install --save-dev vitest @vitest/coverage-v8
```

- [ ] **Step 2: Create `web-app/vitest.config.ts`**

```typescript
import { defineConfig } from "vitest/config";
import path from "path";

export default defineConfig({
  test: {
    globals: true,
    environment: "node",
    coverage: {
      provider: "v8",
      include: ["src/lib/domain/**"],
      thresholds: {
        lines: 100,
        functions: 100,
        branches: 100,
        statements: 100,
      },
    },
  },
  resolve: {
    alias: {
      "@": path.resolve(__dirname, "./src"),
    },
  },
});
```

- [ ] **Step 3: Add test scripts to `web-app/package.json`**

Add to `"scripts"`:
```json
{
  "test": "vitest run",
  "test:watch": "vitest",
  "test:coverage": "vitest run --coverage"
}
```

- [ ] **Step 4: Commit**

```bash
cd /Users/dustinober/Projects/sundee-fundee
git add web-app/vitest.config.ts web-app/package.json web-app/package-lock.json
git commit -m "feat: configure Vitest with 100% coverage thresholds for domain logic"
```

---

### Task 2: Shared Types — ExerciseValue, Program, WOD

**Files:**
- Create: `web-app/src/lib/domain/types.ts`

- [ ] **Step 1: Write the test at `web-app/src/lib/domain/__tests__/types.test.ts`**

```typescript
import { describe, it, expect } from "vitest";
import {
  ExerciseValue,
  exerciseValueToString,
  decodeExerciseValue,
  encodeExerciseValue,
} from "../types";

describe("ExerciseValue", () => {
  it("decodes a fixed integer", () => {
    expect(decodeExerciseValue(5)).toEqual({ type: "fixed", value: 5 });
  });

  it("decodes a float as fixed int", () => {
    expect(decodeExerciseValue(5.0)).toEqual({ type: "fixed", value: 5 });
  });

  it("decodes AMRAP string", () => {
    expect(decodeExerciseValue("AMRAP")).toEqual({ type: "amrap" });
    expect(decodeExerciseValue(" amrap ")).toEqual({ type: "amrap" });
  });

  it("decodes range string", () => {
    expect(decodeExerciseValue("8-10")).toEqual({ type: "range", low: 8, high: 10 });
  });

  it("decodes range array", () => {
    expect(decodeExerciseValue([8, 10])).toEqual({ type: "range", low: 8, high: 10 });
  });

  it("decodes numeric string as fixed", () => {
    expect(decodeExerciseValue("5")).toEqual({ type: "fixed", value: 5 });
  });

  it("decodes arbitrary text", () => {
    expect(decodeExerciseValue("max effort")).toEqual({ type: "text", value: "max effort" });
  });

  it("formats fixed", () => {
    expect(exerciseValueToString({ type: "fixed", value: 5 })).toBe("5");
  });

  it("formats AMRAP", () => {
    expect(exerciseValueToString({ type: "amrap" })).toBe("AMRAP");
  });

  it("formats range", () => {
    expect(exerciseValueToString({ type: "range", low: 8, high: 10 })).toBe("8\u201310");
  });

  it("formats text", () => {
    expect(exerciseValueToString({ type: "text", value: "max effort" })).toBe("max effort");
  });

  it("round-trips through encode/decode", () => {
    const values: ExerciseValue[] = [
      { type: "fixed", value: 5 },
      { type: "amrap" },
      { type: "range", low: 8, high: 10 },
      { type: "text", value: "tempo 3-1-3" },
    ];
    for (const v of values) {
      expect(decodeExerciseValue(encodeExerciseValue(v))).toEqual(v);
    }
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

```bash
cd /Users/dustinober/Projects/sundee-fundee/web-app && npx vitest run src/lib/domain/__tests__/types.test.ts
```

Expected: FAIL — module not found.

- [ ] **Step 3: Create `web-app/src/lib/domain/types.ts`**

```typescript
// ============================================================
// ExerciseValue — discriminated union matching Swift ExerciseValue
// ============================================================

export type ExerciseValue =
  | { type: "fixed"; value: number }
  | { type: "amrap" }
  | { type: "range"; low: number; high: number }
  | { type: "text"; value: string };

export function exerciseValueToString(ev: ExerciseValue): string {
  switch (ev.type) {
    case "fixed": return String(ev.value);
    case "amrap": return "AMRAP";
    case "range": return `${ev.low}\u2013${ev.high}`;
    case "text": return ev.value;
  }
}

/** Decode from JSON (number, string, or [number, number]) — matches Swift Codable init */
export function decodeExerciseValue(raw: unknown): ExerciseValue {
  if (typeof raw === "number") {
    return { type: "fixed", value: Math.floor(raw) };
  }
  if (Array.isArray(raw) && raw.length === 2 && typeof raw[0] === "number" && typeof raw[1] === "number") {
    return { type: "range", low: raw[0], high: raw[1] };
  }
  if (typeof raw === "string") {
    const trimmed = raw.trim();
    if (trimmed.toUpperCase() === "AMRAP") return { type: "amrap" };
    if (trimmed.includes("-")) {
      const parts = trimmed.split("-");
      if (parts.length === 2) {
        const lo = parseInt(parts[0].trim(), 10);
        const hi = parseInt(parts[1].trim(), 10);
        if (!isNaN(lo) && !isNaN(hi)) return { type: "range", low: lo, high: hi };
      }
    }
    const n = parseInt(trimmed, 10);
    if (!isNaN(n) && String(n) === trimmed) return { type: "fixed", value: n };
    return { type: "text", value: raw };
  }
  return { type: "fixed", value: 0 };
}

/** Encode to JSON — matches Swift Codable encode */
export function encodeExerciseValue(ev: ExerciseValue): unknown {
  switch (ev.type) {
    case "fixed": return ev.value;
    case "amrap": return "AMRAP";
    case "range": return [ev.low, ev.high];
    case "text": return ev.value;
  }
}

// ============================================================
// Program types — matches Swift Program.swift
// ============================================================

export interface ProgramExercise {
  exercise: string;
  variant?: string;
  sets: ExerciseValue;
  reps: ExerciseValue;
  percent1RM?: number;
  restMinutes?: number;
  notes?: string;
  bodyweightOnly?: boolean;
}

export interface ProgramSession {
  sessionId: string;
  sessionName: string;
  sessionType: string;
  focus: string;
  exercises: ProgramExercise[];
}

export interface ProgramWeek {
  week: number;
  phaseId?: string;
  isTestWeek?: boolean;
  sessions: ProgramSession[];
}

export interface ProgramPhase {
  id: string;
  name: string;
  goal: string;
  weekRange: number[];
}

export interface ProgramPhaseAdjustmentSettings {
  loadMultiplier: number;
  setsMultiplier: number;
  repsMultiplier: number;
}

export interface ProgramCycleAdjustmentProfile {
  fallbackPhase: string;
  lowConfidenceScale: number;
  phaseSettings: Record<string, ProgramPhaseAdjustmentSettings>;
}

export interface Program {
  id: string;
  name: string;
  category: string;
  description: string;
  durationWeeks: number;
  sessionsPerWeek: number;
  difficulty: string;
  phases: ProgramPhase[];
  weeks: ProgramWeek[];
  cycleAdjustmentProfile?: ProgramCycleAdjustmentProfile;
}

// ============================================================
// WOD
// ============================================================

export interface WOD {
  id: string;
  date: string;
  title: string;
  description: string;
  exercises: ProgramExercise[];
}

// ============================================================
// Enums (matching Swift raw-string enums)
// ============================================================

export const ExperienceLevel = {
  beginner: "beginner",
  intermediate: "intermediate",
  advanced: "advanced",
} as const;
export type ExperienceLevel = (typeof ExperienceLevel)[keyof typeof ExperienceLevel];

export const PrimaryGoal = {
  strength: "strength",
  hypertrophy: "hypertrophy",
  endurance: "endurance",
  weightLoss: "weight_loss",
} as const;
export type PrimaryGoal = (typeof PrimaryGoal)[keyof typeof PrimaryGoal];

export const Gender = {
  male: "male",
  female: "female",
  preferNotToSay: "prefer_not_to_say",
} as const;
export type Gender = (typeof Gender)[keyof typeof Gender];

export const WeightUnit = {
  kilograms: "kg",
  pounds: "lb",
} as const;
export type WeightUnit = (typeof WeightUnit)[keyof typeof WeightUnit];

export const RecoveryPhase = {
  acute: "acute",
  rehab: "rehab",
  lightLoad: "lightLoad",
  returnToPlay: "returnToPlay",
  resolved: "resolved",
} as const;
export type RecoveryPhase = (typeof RecoveryPhase)[keyof typeof RecoveryPhase];

export const CyclePhase = {
  menstrual: "menstrual",
  follicular: "follicular",
  ovulation: "ovulation",
  luteal: "luteal",
} as const;
export type CyclePhase = (typeof CyclePhase)[keyof typeof CyclePhase];

export const BenchmarkScoringType = {
  time: "time",
  reps: "reps",
  weight: "weight",
  distance: "distance",
  roundsAndReps: "roundsAndReps",
} as const;
export type BenchmarkScoringType = (typeof BenchmarkScoringType)[keyof typeof BenchmarkScoringType];

export const ConditioningScoringType = {
  time: "time",
  reps: "reps",
} as const;
export type ConditioningScoringType = (typeof ConditioningScoringType)[keyof typeof ConditioningScoringType];

export const SessionResult = {
  first: "first",
  success: "success",
  failure: "failure",
} as const;
export type SessionResult = (typeof SessionResult)[keyof typeof SessionResult];

// ============================================================
// Subscription
// ============================================================

export const SubscriptionTier = {
  free: "free",
  plus: "plus",
  premium: "premium",
} as const;
export type SubscriptionTier = (typeof SubscriptionTier)[keyof typeof SubscriptionTier];
```

- [ ] **Step 4: Run test to verify it passes**

```bash
cd /Users/dustinober/Projects/sundee-fundee/web-app && npx vitest run src/lib/domain/__tests__/types.test.ts
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
cd /Users/dustinober/Projects/sundee-fundee
git add web-app/src/lib/domain/types.ts web-app/src/lib/domain/__tests__/types.test.ts
git commit -m "feat: add shared domain types (ExerciseValue, Program, enums)"
```

---

### Task 3: Weight Calculations

**Files:**
- Create: `web-app/src/lib/domain/weight-calculations.ts`
- Create: `web-app/src/lib/domain/__tests__/weight-calculations.test.ts`

- [ ] **Step 1: Write the tests**

```typescript
import { describe, it, expect } from "vitest";
import {
  roundToNearestFive,
  calculateTargetWeight,
  getNextRecommendedWeight,
  wasSetSuccessful,
  isPersonalRecord,
  calculateVolumeLoad,
  detectPlateau,
  estimate1RM,
  isPR,
} from "../weight-calculations";

describe("roundToNearestFive", () => {
  it("rounds 67 to 65", () => expect(roundToNearestFive(67)).toBe(65));
  it("rounds 68 to 70", () => expect(roundToNearestFive(68)).toBe(70));
  it("keeps 100 as 100", () => expect(roundToNearestFive(100)).toBe(100));
  it("rounds 2.5 to 5", () => expect(roundToNearestFive(2.5)).toBe(5));
  it("rounds 0 to 0", () => expect(roundToNearestFive(0)).toBe(0));
});

describe("calculateTargetWeight", () => {
  it("calculates 70% of 100kg", () => expect(calculateTargetWeight(100, 0.7)).toBe(70));
  it("calculates 85% of 140kg rounded", () => expect(calculateTargetWeight(140, 0.85)).toBe(120));
  it("calculates 65% of 60kg", () => expect(calculateTargetWeight(60, 0.65)).toBe(40));
});

describe("getNextRecommendedWeight", () => {
  it("first attempt = 70% of 1RM", () => {
    expect(getNextRecommendedWeight(0, "first", 100)).toBe(70);
  });
  it("success = current + 5 rounded", () => {
    expect(getNextRecommendedWeight(70, "success", 100)).toBe(75);
  });
  it("failure = current - 5, floored at 50% of 1RM", () => {
    expect(getNextRecommendedWeight(55, "failure", 100)).toBe(50);
  });
  it("failure does not go below floor", () => {
    expect(getNextRecommendedWeight(50, "failure", 100)).toBe(50);
  });
});

describe("wasSetSuccessful", () => {
  it("success when reps and weight met", () => {
    expect(wasSetSuccessful(5, 5, 100, 100)).toBe(true);
  });
  it("success when exceeding prescribed", () => {
    expect(wasSetSuccessful(6, 5, 105, 100)).toBe(true);
  });
  it("failure when reps short", () => {
    expect(wasSetSuccessful(4, 5, 100, 100)).toBe(false);
  });
  it("failure when weight short", () => {
    expect(wasSetSuccessful(5, 5, 95, 100)).toBe(false);
  });
  it("success when no prescribed weight", () => {
    expect(wasSetSuccessful(5, 5, 0, undefined)).toBe(true);
  });
});

describe("isPersonalRecord", () => {
  it("returns true when weight exceeds previous max", () => {
    expect(isPersonalRecord(105, 100)).toBe(true);
  });
  it("returns false when equal", () => {
    expect(isPersonalRecord(100, 100)).toBe(false);
  });
});

describe("calculateVolumeLoad", () => {
  it("calculates correctly", () => {
    expect(calculateVolumeLoad(100, 5, 3)).toBe(1500);
  });
});

describe("detectPlateau", () => {
  it("detects plateau when last 3 weights within 5kg", () => {
    expect(detectPlateau([100, 102, 101])).toBe(true);
  });
  it("no plateau with fewer than 3 weights", () => {
    expect(detectPlateau([100, 102])).toBe(false);
  });
  it("no plateau when range exceeds 5kg", () => {
    expect(detectPlateau([100, 107, 103])).toBe(false);
  });
});

describe("estimate1RM (Epley)", () => {
  it("returns weight when reps <= 1", () => {
    expect(estimate1RM(100, 1)).toBe(100);
  });
  it("estimates correctly for 5 reps at 85kg", () => {
    // 85 * (1 + 5/30) = 85 * 1.1667 ≈ 99.17
    expect(estimate1RM(85, 5)).toBeCloseTo(99.17, 0);
  });
});

describe("isPR", () => {
  it("returns true when new estimate exceeds current", () => {
    expect(isPR(105, 100)).toBe(true);
  });
  it("returns false when equal", () => {
    expect(isPR(100, 100)).toBe(false);
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

```bash
cd /Users/dustinober/Projects/sundee-fundee/web-app && npx vitest run src/lib/domain/__tests__/weight-calculations.test.ts
```

Expected: FAIL.

- [ ] **Step 3: Create `web-app/src/lib/domain/weight-calculations.ts`**

```typescript
import type { SessionResult } from "./types";

/** Round to nearest 5 — matches Swift WeightCalculations.roundToNearestFive */
export function roundToNearestFive(value: number): number {
  return Math.round(value / 5) * 5;
}

/** Calculate target weight from 1RM and percentage, rounded to nearest 5 */
export function calculateTargetWeight(oneRepMax: number, percentage: number): number {
  return roundToNearestFive(oneRepMax * percentage);
}

/** Get next recommended weight based on session result */
export function getNextRecommendedWeight(
  currentWeight: number,
  result: SessionResult,
  oneRepMax: number
): number {
  switch (result) {
    case "first":
      return roundToNearestFive(oneRepMax * 0.7);
    case "success":
      return roundToNearestFive(currentWeight + 5);
    case "failure": {
      const floor = roundToNearestFive(oneRepMax * 0.5);
      return Math.max(roundToNearestFive(currentWeight - 5), floor);
    }
  }
}

/** Check if a set was successful (reps >= prescribed AND weight >= prescribed) */
export function wasSetSuccessful(
  actualReps: number,
  prescribedReps: number,
  actualWeight: number,
  prescribedWeight: number | undefined
): boolean {
  const repsOk = actualReps >= prescribedReps;
  const weightOk = prescribedWeight != null ? actualWeight >= prescribedWeight : true;
  return repsOk && weightOk;
}

/** Check if a weight is a personal record */
export function isPersonalRecord(weight: number, previousMax: number): boolean {
  return weight > previousMax;
}

/** Calculate volume load (weight x reps x sets) */
export function calculateVolumeLoad(weight: number, reps: number, sets: number): number {
  return weight * reps * sets;
}

/** Detect plateau — last 3 weights within 5kg range */
export function detectPlateau(weights: number[]): boolean {
  if (weights.length < 3) return false;
  const last3 = weights.slice(-3);
  const min = Math.min(...last3);
  const max = Math.max(...last3);
  return (max - min) <= 5;
}

/** Epley formula: estimate 1RM from submaximal weight and reps */
export function estimate1RM(weight: number, reps: number): number {
  if (reps <= 1) return weight;
  return weight * (1 + reps / 30);
}

/** Check if new estimated 1RM is a PR */
export function isPR(newEstimate: number, currentMax: number): boolean {
  return newEstimate > currentMax;
}
```

- [ ] **Step 4: Run test to verify it passes**

```bash
cd /Users/dustinober/Projects/sundee-fundee/web-app && npx vitest run src/lib/domain/__tests__/weight-calculations.test.ts
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
cd /Users/dustinober/Projects/sundee-fundee
git add web-app/src/lib/domain/weight-calculations.ts web-app/src/lib/domain/__tests__/weight-calculations.test.ts
git commit -m "feat: port weight calculations and Epley formula to TypeScript"
```

---

### Task 4: Weight Unit Conversion

**Files:**
- Create: `web-app/src/lib/domain/weight-unit-conversion.ts`
- Create: `web-app/src/lib/domain/__tests__/weight-unit-conversion.test.ts`

- [ ] **Step 1: Write the tests**

```typescript
import { describe, it, expect } from "vitest";
import {
  LB_PER_KG,
  fromKilograms,
  toKilograms,
  parseInputToKilograms,
  formatWeight,
  formatWeightWithUnit,
} from "../weight-unit-conversion";

describe("fromKilograms", () => {
  it("identity for kg", () => expect(fromKilograms(100, "kg")).toBe(100));
  it("converts to lb", () => expect(fromKilograms(100, "lb")).toBeCloseTo(220.46, 1));
});

describe("toKilograms", () => {
  it("identity for kg", () => expect(toKilograms(100, "kg")).toBe(100));
  it("converts from lb", () => expect(toKilograms(220.46, "lb")).toBeCloseTo(100, 0));
});

describe("parseInputToKilograms", () => {
  it("parses valid number in kg", () => expect(parseInputToKilograms("100", "kg")).toBe(100));
  it("parses valid number in lb", () => {
    expect(parseInputToKilograms("220", "lb")).toBeCloseTo(99.79, 0);
  });
  it("returns null for invalid input", () => expect(parseInputToKilograms("abc", "kg")).toBeNull());
  it("returns null for empty input", () => expect(parseInputToKilograms("", "kg")).toBeNull());
});

describe("formatWeight", () => {
  it("formats whole numbers without decimals", () => expect(formatWeight(100)).toBe("100"));
  it("formats with up to 1 decimal", () => expect(formatWeight(100.5)).toBe("100.5"));
  it("rounds to 1 decimal", () => expect(formatWeight(100.56)).toBe("100.6"));
});

describe("formatWeightWithUnit", () => {
  it("appends kg", () => expect(formatWeightWithUnit(100, "kg")).toBe("100 kg"));
  it("converts and appends lb", () => expect(formatWeightWithUnit(100, "lb")).toBe("220.5 lb"));
});
```

- [ ] **Step 2: Run test to verify it fails**

```bash
cd /Users/dustinober/Projects/sundee-fundee/web-app && npx vitest run src/lib/domain/__tests__/weight-unit-conversion.test.ts
```

Expected: FAIL.

- [ ] **Step 3: Create `web-app/src/lib/domain/weight-unit-conversion.ts`**

```typescript
import type { WeightUnit } from "./types";

export const LB_PER_KG = 2.2046226218;

/** Convert from kilograms to the target unit */
export function fromKilograms(kg: number, unit: WeightUnit): number {
  return unit === "kg" ? kg : kg * LB_PER_KG;
}

/** Convert from a given unit to kilograms */
export function toKilograms(value: number, unit: WeightUnit): number {
  return unit === "kg" ? value : value / LB_PER_KG;
}

/** Parse a string input to kilograms, returning null if invalid */
export function parseInputToKilograms(input: string, unit: WeightUnit): number | null {
  const trimmed = input.trim();
  if (trimmed === "") return null;
  const value = parseFloat(trimmed);
  if (isNaN(value)) return null;
  return toKilograms(value, unit);
}

/** Format weight with up to 1 decimal place */
export function formatWeight(value: number): string {
  const rounded = Math.round(value * 10) / 10;
  return rounded % 1 === 0 ? String(rounded) : rounded.toFixed(1);
}

/** Format weight converted to target unit with unit symbol */
export function formatWeightWithUnit(kg: number, unit: WeightUnit): string {
  const converted = fromKilograms(kg, unit);
  return `${formatWeight(converted)} ${unit}`;
}
```

- [ ] **Step 4: Run test to verify it passes**

```bash
cd /Users/dustinober/Projects/sundee-fundee/web-app && npx vitest run src/lib/domain/__tests__/weight-unit-conversion.test.ts
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
cd /Users/dustinober/Projects/sundee-fundee
git add web-app/src/lib/domain/weight-unit-conversion.ts web-app/src/lib/domain/__tests__/weight-unit-conversion.test.ts
git commit -m "feat: port weight unit conversion (kg/lb) to TypeScript"
```

---

### Task 5: Plate Calculation

**Files:**
- Create: `web-app/src/lib/domain/plate-calculation.ts`
- Create: `web-app/src/lib/domain/__tests__/plate-calculation.test.ts`

- [ ] **Step 1: Write the tests**

```typescript
import { describe, it, expect } from "vitest";
import { platesPerSide, plateDescription, STANDARD_BARBELL_KG, WOMENS_BARBELL_KG } from "../plate-calculation";

describe("platesPerSide", () => {
  it("returns empty for bar weight only", () => {
    expect(platesPerSide(20, 20)).toEqual([]);
  });

  it("calculates plates for 60kg on 20kg bar", () => {
    // 40kg total plates, 20kg per side = 1x20kg
    const plates = platesPerSide(60, 20);
    expect(plates).toEqual([{ weight: 20, count: 1 }]);
  });

  it("calculates plates for 100kg on 20kg bar", () => {
    // 80kg total, 40kg per side = 1x25 + 1x15
    const plates = platesPerSide(100, 20);
    expect(plates).toEqual([{ weight: 25, count: 1 }, { weight: 15, count: 1 }]);
  });

  it("handles women's bar", () => {
    const plates = platesPerSide(55, WOMENS_BARBELL_KG);
    // 40kg total, 20kg per side = 1x20
    expect(plates).toEqual([{ weight: 20, count: 1 }]);
  });

  it("returns empty for weight less than bar", () => {
    expect(platesPerSide(15, 20)).toEqual([]);
  });
});

describe("plateDescription", () => {
  it("describes plates for a given weight", () => {
    const desc = plateDescription(100);
    expect(desc).toContain("per side");
  });
});

describe("barbell constants", () => {
  it("standard barbell is 20kg", () => expect(STANDARD_BARBELL_KG).toBe(20));
  it("women's barbell is 15kg", () => expect(WOMENS_BARBELL_KG).toBe(15));
});
```

- [ ] **Step 2: Run test to verify it fails**

```bash
cd /Users/dustinober/Projects/sundee-fundee/web-app && npx vitest run src/lib/domain/__tests__/plate-calculation.test.ts
```

Expected: FAIL.

- [ ] **Step 3: Create `web-app/src/lib/domain/plate-calculation.ts`**

```typescript
export const STANDARD_BARBELL_KG = 20;
export const WOMENS_BARBELL_KG = 15;

const AVAILABLE_PLATES = [25, 20, 15, 10, 5, 2.5, 1.25];

export interface PlateCount {
  weight: number;
  count: number;
}

/** Calculate plates needed per side for a given total weight and barbell weight */
export function platesPerSide(totalWeightKg: number, barbellWeightKg: number = STANDARD_BARBELL_KG): PlateCount[] {
  let remaining = (totalWeightKg - barbellWeightKg) / 2;
  if (remaining <= 0) return [];

  const result: PlateCount[] = [];
  for (const plate of AVAILABLE_PLATES) {
    if (remaining >= plate) {
      const count = Math.floor(remaining / plate);
      result.push({ weight: plate, count });
      remaining -= plate * count;
    }
  }
  return result;
}

/** Human-readable plate description */
export function plateDescription(totalWeightKg: number, barbellWeightKg: number = STANDARD_BARBELL_KG): string {
  const plates = platesPerSide(totalWeightKg, barbellWeightKg);
  if (plates.length === 0) return "Bar only";
  const parts = plates.map((p) => `${p.count}\u00d7${p.weight}kg`);
  return `${parts.join(" + ")} per side`;
}
```

- [ ] **Step 4: Run test to verify it passes**

```bash
cd /Users/dustinober/Projects/sundee-fundee/web-app && npx vitest run src/lib/domain/__tests__/plate-calculation.test.ts
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
cd /Users/dustinober/Projects/sundee-fundee
git add web-app/src/lib/domain/plate-calculation.ts web-app/src/lib/domain/__tests__/plate-calculation.test.ts
git commit -m "feat: port plate calculation to TypeScript"
```

---

### Task 6: Exercise Catalogs

**Files:**
- Create: `web-app/src/lib/domain/exercise-catalog.ts`
- Create: `web-app/src/lib/domain/__tests__/exercise-catalog.test.ts`

- [ ] **Step 1: Write the tests**

```typescript
import { describe, it, expect } from "vitest";
import {
  WEIGHTLIFTING_EXERCISES,
  CONDITIONING_EXERCISES,
  isWeightliftingExercise,
  isConditioningExercise,
  conditioningScoringType,
  formatConditioningValue,
  isBetterConditioningScore,
} from "../exercise-catalog";

describe("WeightliftingExerciseCatalog", () => {
  it("contains Back Squat", () => {
    expect(isWeightliftingExercise("Back Squat")).toBe(true);
  });

  it("does not contain arbitrary exercise", () => {
    expect(isWeightliftingExercise("Jumping Jacks")).toBe(false);
  });

  it("has 39 exercises", () => {
    expect(WEIGHTLIFTING_EXERCISES.length).toBe(39);
  });
});

describe("ConditioningExerciseCatalog", () => {
  it("contains Wall Ball", () => {
    expect(isConditioningExercise("Wall Ball")).toBe(true);
  });

  it("returns scoring type for known exercise", () => {
    expect(conditioningScoringType("Wall Ball")).toBe("reps");
    expect(conditioningScoringType("400m Run")).toBe("time");
  });

  it("returns undefined for unknown exercise", () => {
    expect(conditioningScoringType("Yoga")).toBeUndefined();
  });
});

describe("formatConditioningValue", () => {
  it("formats time as M:SS", () => {
    expect(formatConditioningValue(125, "time")).toBe("2:05");
  });
  it("formats reps with plural", () => {
    expect(formatConditioningValue(10, "reps")).toBe("10 reps");
  });
  it("formats 1 rep singular", () => {
    expect(formatConditioningValue(1, "reps")).toBe("1 rep");
  });
});

describe("isBetterConditioningScore", () => {
  it("lower time is better", () => {
    expect(isBetterConditioningScore(100, 110, "time")).toBe(true);
    expect(isBetterConditioningScore(110, 100, "time")).toBe(false);
  });
  it("higher reps is better", () => {
    expect(isBetterConditioningScore(15, 10, "reps")).toBe(true);
    expect(isBetterConditioningScore(10, 15, "reps")).toBe(false);
  });
  it("always better than undefined", () => {
    expect(isBetterConditioningScore(100, undefined, "time")).toBe(true);
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

```bash
cd /Users/dustinober/Projects/sundee-fundee/web-app && npx vitest run src/lib/domain/__tests__/exercise-catalog.test.ts
```

Expected: FAIL.

- [ ] **Step 3: Create `web-app/src/lib/domain/exercise-catalog.ts`**

Port the complete exercise catalogs from Swift `ExerciseCatalog.swift`. The file contains all 39 weightlifting exercises and 21 conditioning exercises with their categories and scoring types. This is a large data file — copy all entries exactly from the Swift source.

```typescript
import type { ConditioningScoringType } from "./types";

// ============================================================
// Weightlifting Exercise Catalog
// ============================================================

export type WeightliftingCategory = "Squat" | "Hip Hinge" | "Press" | "Pull" | "Carry" | "Olympic Weightlifting";

export interface WeightliftingEntry {
  id: string;
  category: WeightliftingCategory;
}

export const WEIGHTLIFTING_EXERCISES: WeightliftingEntry[] = [
  // Squat
  { id: "Back Squat", category: "Squat" },
  { id: "Front Squat", category: "Squat" },
  { id: "Safety Bar Squat", category: "Squat" },
  { id: "Box Squat", category: "Squat" },
  { id: "Pause Squat", category: "Squat" },
  { id: "Goblet Squat", category: "Squat" },
  // Hip Hinge
  { id: "Conventional Deadlift (No Straps)", category: "Hip Hinge" },
  { id: "Conventional Deadlift (With Straps)", category: "Hip Hinge" },
  { id: "Romanian Deadlift (No Straps)", category: "Hip Hinge" },
  { id: "Romanian Deadlift (With Straps)", category: "Hip Hinge" },
  { id: "Sumo Deadlift (No Straps)", category: "Hip Hinge" },
  { id: "Sumo Deadlift (With Straps)", category: "Hip Hinge" },
  { id: "Trap Bar Deadlift (No Straps)", category: "Hip Hinge" },
  { id: "Trap Bar Deadlift (With Straps)", category: "Hip Hinge" },
  { id: "Good Morning", category: "Hip Hinge" },
  { id: "Hip Thrust", category: "Hip Hinge" },
  // Press
  { id: "Flat Barbell Bench Press", category: "Press" },
  { id: "Incline Barbell Bench Press", category: "Press" },
  { id: "Strict Press", category: "Press" },
  { id: "Push Press", category: "Press" },
  { id: "Dumbbell Bench Press", category: "Press" },
  { id: "Dumbbell Overhead Press", category: "Press" },
  // Pull
  { id: "Barbell Row", category: "Pull" },
  { id: "Pendlay Row", category: "Pull" },
  { id: "Pull-Up", category: "Pull" },
  { id: "Weighted Pull-Up", category: "Pull" },
  { id: "Lat Pulldown", category: "Pull" },
  { id: "Cable Row", category: "Pull" },
  // Carry
  { id: "Farmers Carry", category: "Carry" },
  { id: "Suitcase Carry", category: "Carry" },
  // Olympic Weightlifting
  { id: "Squat Snatch", category: "Olympic Weightlifting" },
  { id: "Squat Clean", category: "Olympic Weightlifting" },
  { id: "Power Clean", category: "Olympic Weightlifting" },
  { id: "Power Snatch", category: "Olympic Weightlifting" },
  { id: "Hang Clean", category: "Olympic Weightlifting" },
  { id: "Hang Snatch", category: "Olympic Weightlifting" },
  { id: "Split Jerk", category: "Olympic Weightlifting" },
  { id: "Push Jerk", category: "Olympic Weightlifting" },
  { id: "Clean and Jerk", category: "Olympic Weightlifting" },
];

const weightliftingIds = new Set(WEIGHTLIFTING_EXERCISES.map((e) => e.id));

export function isWeightliftingExercise(id: string): boolean {
  return weightliftingIds.has(id);
}

// ============================================================
// Conditioning Exercise Catalog
// ============================================================

export interface ConditioningEntry {
  id: string;
  defaultScoringType: ConditioningScoringType;
}

export const CONDITIONING_EXERCISES: ConditioningEntry[] = [
  // Reps-based
  { id: "Wall Ball", defaultScoringType: "reps" },
  { id: "Box Jump", defaultScoringType: "reps" },
  { id: "Burpee", defaultScoringType: "reps" },
  { id: "Kettlebell Swing", defaultScoringType: "reps" },
  { id: "Double Under", defaultScoringType: "reps" },
  { id: "Pull-Up (Kipping)", defaultScoringType: "reps" },
  { id: "Toes-to-Bar", defaultScoringType: "reps" },
  { id: "Muscle-Up", defaultScoringType: "reps" },
  { id: "Push-Up", defaultScoringType: "reps" },
  { id: "Sit-Up", defaultScoringType: "reps" },
  { id: "Air Squat", defaultScoringType: "reps" },
  { id: "Thruster", defaultScoringType: "reps" },
  { id: "Rowing (Calories)", defaultScoringType: "reps" },
  { id: "Assault Bike (Calories)", defaultScoringType: "reps" },
  // Time-based
  { id: "400m Run", defaultScoringType: "time" },
  { id: "800m Run", defaultScoringType: "time" },
  { id: "1-Mile Run", defaultScoringType: "time" },
  { id: "5K Run", defaultScoringType: "time" },
  { id: "500m Row", defaultScoringType: "time" },
  { id: "2K Row", defaultScoringType: "time" },
  { id: "1K Assault Bike", defaultScoringType: "time" },
];

const conditioningIds = new Set(CONDITIONING_EXERCISES.map((e) => e.id));

export function isConditioningExercise(id: string): boolean {
  return conditioningIds.has(id);
}

export function conditioningScoringType(exerciseId: string): ConditioningScoringType | undefined {
  return CONDITIONING_EXERCISES.find((e) => e.id === exerciseId)?.defaultScoringType;
}

export function formatConditioningValue(value: number, scoringType: ConditioningScoringType): string {
  switch (scoringType) {
    case "time": {
      const totalSeconds = Math.floor(value);
      const minutes = Math.floor(totalSeconds / 60);
      const seconds = totalSeconds % 60;
      return `${minutes}:${String(seconds).padStart(2, "0")}`;
    }
    case "reps": {
      const count = Math.floor(value);
      return count === 1 ? "1 rep" : `${count} reps`;
    }
  }
}

export function isBetterConditioningScore(
  newValue: number,
  existingValue: number | undefined,
  scoringType: ConditioningScoringType
): boolean {
  if (existingValue == null) return true;
  switch (scoringType) {
    case "time": return newValue < existingValue;
    case "reps": return newValue > existingValue;
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

```bash
cd /Users/dustinober/Projects/sundee-fundee/web-app && npx vitest run src/lib/domain/__tests__/exercise-catalog.test.ts
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
cd /Users/dustinober/Projects/sundee-fundee
git add web-app/src/lib/domain/exercise-catalog.ts web-app/src/lib/domain/__tests__/exercise-catalog.test.ts
git commit -m "feat: port exercise catalogs (weightlifting + conditioning) to TypeScript"
```

---

### Task 7: Body Location + Recovery Phase

**Files:**
- Create: `web-app/src/lib/domain/body-location.ts`
- Create: `web-app/src/lib/domain/__tests__/body-location.test.ts`

- [ ] **Step 1: Write the tests**

```typescript
import { describe, it, expect } from "vitest";
import { BODY_REGIONS, parseRegions, encodeRegions, recoveryPhaseDisplayName, RECOVERY_PHASE_ORDER } from "../body-location";

describe("BODY_REGIONS", () => {
  it("has 17 regions", () => expect(BODY_REGIONS.length).toBe(17));
  it("maps knee to engine key 'knee'", () => {
    const knee = BODY_REGIONS.find((r) => r.id === "knee");
    expect(knee?.engineKey).toBe("knee");
  });
});

describe("parseRegions/encodeRegions", () => {
  it("round-trips", () => {
    const encoded = encodeRegions(["knee", "shoulder_left"]);
    expect(parseRegions(encoded)).toEqual(["knee", "shoulder_left"]);
  });
  it("handles empty string", () => {
    expect(parseRegions("")).toEqual([]);
  });
});

describe("recoveryPhaseDisplayName", () => {
  it("formats acute", () => expect(recoveryPhaseDisplayName("acute")).toBe("Acute"));
  it("formats returnToPlay", () => expect(recoveryPhaseDisplayName("returnToPlay")).toBe("Return to Play"));
});

describe("RECOVERY_PHASE_ORDER", () => {
  it("acute is first", () => expect(RECOVERY_PHASE_ORDER[0]).toBe("acute"));
  it("resolved is last", () => expect(RECOVERY_PHASE_ORDER[4]).toBe("resolved"));
});
```

- [ ] **Step 2: Run test to verify it fails**

```bash
cd /Users/dustinober/Projects/sundee-fundee/web-app && npx vitest run src/lib/domain/__tests__/body-location.test.ts
```

Expected: FAIL.

- [ ] **Step 3: Create `web-app/src/lib/domain/body-location.ts`**

```typescript
import type { RecoveryPhase } from "./types";

export interface BodyRegion {
  id: string;
  displayName: string;
  engineKey: string;
}

export const BODY_REGIONS: BodyRegion[] = [
  { id: "head", displayName: "Head", engineKey: "head" },
  { id: "neck", displayName: "Neck", engineKey: "neck" },
  { id: "shoulder_left", displayName: "Left Shoulder", engineKey: "shoulder" },
  { id: "shoulder_right", displayName: "Right Shoulder", engineKey: "shoulder" },
  { id: "chest", displayName: "Chest", engineKey: "chest" },
  { id: "upper_back", displayName: "Upper Back", engineKey: "back" },
  { id: "lower_back", displayName: "Lower Back", engineKey: "back" },
  { id: "elbow_left", displayName: "Left Elbow", engineKey: "elbow" },
  { id: "elbow_right", displayName: "Right Elbow", engineKey: "elbow" },
  { id: "wrist_left", displayName: "Left Wrist", engineKey: "wrist" },
  { id: "wrist_right", displayName: "Right Wrist", engineKey: "wrist" },
  { id: "hip_left", displayName: "Left Hip", engineKey: "hip" },
  { id: "hip_right", displayName: "Right Hip", engineKey: "hip" },
  { id: "knee_left", displayName: "Left Knee", engineKey: "knee" },
  { id: "knee_right", displayName: "Right Knee", engineKey: "knee" },
  { id: "ankle_left", displayName: "Left Ankle", engineKey: "ankle" },
  { id: "ankle_right", displayName: "Right Ankle", engineKey: "ankle" },
];

export function parseRegions(raw: string): string[] {
  if (!raw.trim()) return [];
  return raw.split(",").map((s) => s.trim()).filter(Boolean);
}

export function encodeRegions(regions: string[]): string {
  return regions.join(",");
}

export const RECOVERY_PHASE_ORDER: RecoveryPhase[] = [
  "acute", "rehab", "lightLoad", "returnToPlay", "resolved",
];

const displayNames: Record<RecoveryPhase, string> = {
  acute: "Acute",
  rehab: "Rehab",
  lightLoad: "Light Load",
  returnToPlay: "Return to Play",
  resolved: "Resolved",
};

export function recoveryPhaseDisplayName(phase: RecoveryPhase): string {
  return displayNames[phase];
}
```

- [ ] **Step 4: Run test to verify it passes**

```bash
cd /Users/dustinober/Projects/sundee-fundee/web-app && npx vitest run src/lib/domain/__tests__/body-location.test.ts
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
cd /Users/dustinober/Projects/sundee-fundee
git add web-app/src/lib/domain/body-location.ts web-app/src/lib/domain/__tests__/body-location.test.ts
git commit -m "feat: port body location and recovery phase to TypeScript"
```

---

### Task 8: Subscription Tier + Feature Entitlement + AI Limits + Downgrade Policy

**Files:**
- Create: `web-app/src/lib/domain/subscription.ts`
- Create: `web-app/src/lib/domain/__tests__/subscription.test.ts`

- [ ] **Step 1: Write the tests**

```typescript
import { describe, it, expect } from "vitest";
import {
  tierDisplayName,
  tierRank,
  canAccess,
  GatedFeature,
  dailyCloudAILimit,
  canGenerateCloud,
  canViewExistingData,
  canCreateNew,
  canDeleteOwnData,
  shouldShowSoftNudge,
} from "../subscription";

describe("tierDisplayName", () => {
  it("free", () => expect(tierDisplayName("free")).toBe("Free"));
  it("plus", () => expect(tierDisplayName("plus")).toBe("Sundee Plus"));
  it("premium", () => expect(tierDisplayName("premium")).toBe("Sundee Premium"));
});

describe("tierRank", () => {
  it("free=0, plus=1, premium=2", () => {
    expect(tierRank("free")).toBe(0);
    expect(tierRank("plus")).toBe(1);
    expect(tierRank("premium")).toBe(2);
  });
});

describe("canAccess", () => {
  it("free cannot access customBenchmarks", () => {
    expect(canAccess("customBenchmarks", "free")).toBe(false);
  });
  it("plus can access customBenchmarks", () => {
    expect(canAccess("customBenchmarks", "plus")).toBe(true);
  });
  it("premium can access rehabSessions", () => {
    expect(canAccess("rehabSessions", "premium")).toBe(true);
  });
  it("plus cannot access rehabSessions", () => {
    expect(canAccess("rehabSessions", "plus")).toBe(false);
  });
});

describe("dailyCloudAILimit", () => {
  it("free = 0", () => expect(dailyCloudAILimit("free")).toBe(0));
  it("plus = 1", () => expect(dailyCloudAILimit("plus")).toBe(1));
  it("premium = 10", () => expect(dailyCloudAILimit("premium")).toBe(10));
});

describe("canGenerateCloud", () => {
  it("free cannot generate", () => expect(canGenerateCloud("free", 0)).toBe(false));
  it("plus can generate 1", () => expect(canGenerateCloud("plus", 0)).toBe(true));
  it("plus cannot generate after 1", () => expect(canGenerateCloud("plus", 1)).toBe(false));
  it("premium can generate up to 10", () => expect(canGenerateCloud("premium", 9)).toBe(true));
  it("premium cannot after 10", () => expect(canGenerateCloud("premium", 10)).toBe(false));
});

describe("shouldShowSoftNudge", () => {
  it("true for premium at 7+", () => expect(shouldShowSoftNudge("premium", 7)).toBe(true));
  it("false for premium under 7", () => expect(shouldShowSoftNudge("premium", 6)).toBe(false));
  it("false for non-premium", () => expect(shouldShowSoftNudge("plus", 1)).toBe(false));
});

describe("downgrade policy", () => {
  it("can always view existing data", () => {
    expect(canViewExistingData("rehabSessions", "free")).toBe(true);
  });
  it("canCreateNew gates on tier", () => {
    expect(canCreateNew("customBenchmarks", "free")).toBe(false);
    expect(canCreateNew("customBenchmarks", "plus")).toBe(true);
  });
  it("can always delete own data", () => {
    expect(canDeleteOwnData("free")).toBe(true);
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

```bash
cd /Users/dustinober/Projects/sundee-fundee/web-app && npx vitest run src/lib/domain/__tests__/subscription.test.ts
```

Expected: FAIL.

- [ ] **Step 3: Create `web-app/src/lib/domain/subscription.ts`**

```typescript
import type { SubscriptionTier } from "./types";

// ============================================================
// Tier metadata — from SubscriptionTier.swift
// ============================================================

export function tierDisplayName(tier: SubscriptionTier): string {
  switch (tier) {
    case "free": return "Free";
    case "plus": return "Sundee Plus";
    case "premium": return "Sundee Premium";
  }
}

export function tierValueProposition(tier: SubscriptionTier): string {
  switch (tier) {
    case "free": return "Unlimited on-device AI workouts";
    case "plus": return "Cloud-powered AI workouts and programming tools";
    case "premium": return "Personal AI coach that learns and adapts";
  }
}

export function tierRank(tier: SubscriptionTier): number {
  switch (tier) {
    case "free": return 0;
    case "plus": return 1;
    case "premium": return 2;
  }
}

// ============================================================
// Feature Entitlement — from FeatureEntitlement.swift
// ============================================================

export type GatedFeature =
  // Plus tier
  | "customBenchmarks" | "painTrends" | "effortTrends"
  | "unlimitedLifts" | "unlimitedInjuries" | "unlimitedHistory"
  | "programBuilder" | "periodizationTemplates" | "autoDeload"
  | "advancedAnalytics" | "streaksAchievements"
  // Premium tier
  | "rehabSessions" | "aiWorkoutHistory" | "exportData"
  | "aiCoachMemory" | "mesocyclePlans" | "progressiveOverload"
  | "plateauDetection" | "weeklyReports" | "smartSubstitutions";

function minimumTier(feature: GatedFeature): SubscriptionTier {
  switch (feature) {
    case "customBenchmarks":
    case "painTrends":
    case "effortTrends":
    case "unlimitedLifts":
    case "unlimitedInjuries":
    case "unlimitedHistory":
    case "programBuilder":
    case "periodizationTemplates":
    case "autoDeload":
    case "advancedAnalytics":
    case "streaksAchievements":
      return "plus";
    case "rehabSessions":
    case "aiWorkoutHistory":
    case "exportData":
    case "aiCoachMemory":
    case "mesocyclePlans":
    case "progressiveOverload":
    case "plateauDetection":
    case "weeklyReports":
    case "smartSubstitutions":
      return "premium";
  }
}

export function canAccess(feature: GatedFeature, tier: SubscriptionTier): boolean {
  return tierRank(tier) >= tierRank(minimumTier(feature));
}

/** Tracking limits per tier — from FeatureEntitlement.swift */
export function maxLifts(tier: SubscriptionTier): number | null {
  return tier === "free" ? 5 : null; // null = unlimited
}

export function maxInjuries(tier: SubscriptionTier): number | null {
  return tier === "free" ? 1 : null;
}

export function maxHistoryDays(tier: SubscriptionTier): number | null {
  return tier === "free" ? 30 : null;
}

// ============================================================
// AI Workout Limits — from AIWorkoutLimits.swift
// ============================================================

export function dailyCloudAILimit(tier: SubscriptionTier): number {
  switch (tier) {
    case "free": return 0;
    case "plus": return 1;
    case "premium": return 10;
  }
}

export function canGenerateCloud(tier: SubscriptionTier, generatedToday: number): boolean {
  const limit = dailyCloudAILimit(tier);
  return generatedToday < limit;
}

export function shouldShowSoftNudge(tier: SubscriptionTier, generatedToday: number): boolean {
  return tier === "premium" && generatedToday >= 7;
}

export function remainingCloudText(tier: SubscriptionTier, generatedToday: number): string {
  const limit = dailyCloudAILimit(tier);
  if (limit === 0) return "Cloud AI not available";
  const remaining = Math.max(0, limit - generatedToday);
  return `${remaining} of ${limit} remaining today`;
}

// ============================================================
// Downgrade Policy — from DowngradePolicy.swift
// ============================================================

export function canViewExistingData(_feature: GatedFeature, _currentTier: SubscriptionTier): boolean {
  return true; // Always allow viewing data created during paid subscription
}

export function canCreateNew(feature: GatedFeature, currentTier: SubscriptionTier): boolean {
  return canAccess(feature, currentTier);
}

export function canDeleteOwnData(_currentTier: SubscriptionTier): boolean {
  return true;
}
```

- [ ] **Step 4: Run test to verify it passes**

```bash
cd /Users/dustinober/Projects/sundee-fundee/web-app && npx vitest run src/lib/domain/__tests__/subscription.test.ts
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
cd /Users/dustinober/Projects/sundee-fundee
git add web-app/src/lib/domain/subscription.ts web-app/src/lib/domain/__tests__/subscription.test.ts
git commit -m "feat: port subscription tier, feature entitlement, AI limits, downgrade policy"
```

---

### Task 9: Cycle Calculations

**Files:**
- Create: `web-app/src/lib/domain/cycle-calculations.ts`
- Create: `web-app/src/lib/domain/__tests__/cycle-calculations.test.ts`

- [ ] **Step 1: Write the tests**

```typescript
import { describe, it, expect } from "vitest";
import {
  calculateCycleStatus,
  getPhaseBoundaries,
  getPhaseRecommendation,
  type CycleStatusResult,
} from "../cycle-calculations";

describe("getPhaseBoundaries", () => {
  it("returns boundaries for default 28-day cycle", () => {
    const bounds = getPhaseBoundaries({ averageCycleLengthDays: 28, averagePeriodLengthDays: 5, lutealPhaseLengthDays: 14 });
    expect(bounds.menstrual).toEqual({ start: 1, end: 5 });
    expect(bounds.follicular).toEqual({ start: 6, end: 13 });
    expect(bounds.ovulation).toEqual({ start: 14, end: 16 });
    expect(bounds.luteal).toEqual({ start: 17, end: 28 });
  });
});

describe("calculateCycleStatus", () => {
  it("returns menstrual phase on day 1", () => {
    const periodStart = new Date("2026-03-29");
    const result = calculateCycleStatus(
      [{ startDate: periodStart }],
      { averageCycleLengthDays: 28, averagePeriodLengthDays: 5, lutealPhaseLengthDays: 14 },
      periodStart
    );
    expect(result.currentPhase).toBe("menstrual");
    expect(result.cycleDay).toBe(1);
  });

  it("returns follicular phase on day 8", () => {
    const periodStart = new Date("2026-03-22");
    const refDate = new Date("2026-03-29");
    const result = calculateCycleStatus(
      [{ startDate: periodStart }],
      { averageCycleLengthDays: 28, averagePeriodLengthDays: 5, lutealPhaseLengthDays: 14 },
      refDate
    );
    expect(result.currentPhase).toBe("follicular");
    expect(result.cycleDay).toBe(8);
  });

  it("returns null with no period logs", () => {
    const result = calculateCycleStatus(
      [],
      { averageCycleLengthDays: 28, averagePeriodLengthDays: 5, lutealPhaseLengthDays: 14 },
      new Date()
    );
    expect(result).toBeNull();
  });
});

describe("getPhaseRecommendation", () => {
  it("returns recovery focus for menstrual", () => {
    const rec = getPhaseRecommendation("menstrual");
    expect(rec.title).toContain("Menstrual");
    expect(rec.trainingFocus).toBeTruthy();
  });

  it("returns peak performance for ovulation", () => {
    const rec = getPhaseRecommendation("ovulation");
    expect(rec.title).toContain("Ovulation");
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

```bash
cd /Users/dustinober/Projects/sundee-fundee/web-app && npx vitest run src/lib/domain/__tests__/cycle-calculations.test.ts
```

Expected: FAIL.

- [ ] **Step 3: Create `web-app/src/lib/domain/cycle-calculations.ts`**

```typescript
import type { CyclePhase } from "./types";

export interface CycleSettings {
  averageCycleLengthDays: number;
  averagePeriodLengthDays: number;
  lutealPhaseLengthDays: number;
}

export interface PeriodLogEntry {
  startDate: Date;
  endDate?: Date;
}

export interface PhaseBoundary {
  start: number;
  end: number;
}

export interface CycleStatusResult {
  currentPhase: CyclePhase;
  cycleDay: number;
  daysUntilNextPhase: number;
  predictedNextPeriod: Date;
  phaseStartDate: Date;
  phaseEndDate: Date;
}

export interface PhaseRecommendation {
  phase: CyclePhase;
  title: string;
  description: string;
  trainingFocus: string;
  intensityRecommendation: string;
  exercisesToEmphasize: string[];
  exercisesToAvoid: string[];
}

/** Get phase boundaries for a given cycle configuration */
export function getPhaseBoundaries(settings: CycleSettings): Record<CyclePhase, PhaseBoundary> {
  const { averageCycleLengthDays, averagePeriodLengthDays, lutealPhaseLengthDays } = settings;
  const ovulationDay = averageCycleLengthDays - lutealPhaseLengthDays;
  return {
    menstrual: { start: 1, end: averagePeriodLengthDays },
    follicular: { start: averagePeriodLengthDays + 1, end: ovulationDay - 1 },
    ovulation: { start: ovulationDay, end: ovulationDay + 2 },
    luteal: { start: ovulationDay + 3, end: averageCycleLengthDays },
  };
}

/** Determine current phase from period logs */
export function calculateCycleStatus(
  periodLogs: PeriodLogEntry[],
  settings: CycleSettings,
  referenceDate: Date
): CycleStatusResult | null {
  if (periodLogs.length === 0) return null;

  // Find most recent period start
  const sorted = [...periodLogs].sort(
    (a, b) => b.startDate.getTime() - a.startDate.getTime()
  );
  const lastPeriod = sorted[0];

  // Calculate cycle day
  const msPerDay = 86_400_000;
  const daysSinceStart = Math.floor(
    (referenceDate.getTime() - lastPeriod.startDate.getTime()) / msPerDay
  );
  const cycleDay = (daysSinceStart % settings.averageCycleLengthDays) + 1;

  // Determine phase
  const boundaries = getPhaseBoundaries(settings);
  let currentPhase: CyclePhase = "follicular";
  for (const [phase, boundary] of Object.entries(boundaries) as [CyclePhase, PhaseBoundary][]) {
    if (cycleDay >= boundary.start && cycleDay <= boundary.end) {
      currentPhase = phase;
      break;
    }
  }

  // Calculate days until next phase
  const currentBoundary = boundaries[currentPhase];
  const daysUntilNextPhase = currentBoundary.end - cycleDay + 1;

  // Predicted next period
  const daysUntilNextPeriod = settings.averageCycleLengthDays - cycleDay + 1;
  const predictedNextPeriod = new Date(
    referenceDate.getTime() + daysUntilNextPeriod * msPerDay
  );

  // Phase start/end dates
  const phaseStartOffset = cycleDay - currentBoundary.start;
  const phaseStartDate = new Date(
    referenceDate.getTime() - phaseStartOffset * msPerDay
  );
  const phaseEndOffset = currentBoundary.end - cycleDay;
  const phaseEndDate = new Date(
    referenceDate.getTime() + phaseEndOffset * msPerDay
  );

  return {
    currentPhase,
    cycleDay,
    daysUntilNextPhase,
    predictedNextPeriod,
    phaseStartDate,
    phaseEndDate,
  };
}

/** Get training recommendation for a cycle phase */
export function getPhaseRecommendation(phase: CyclePhase): PhaseRecommendation {
  switch (phase) {
    case "menstrual":
      return {
        phase,
        title: "Menstrual Phase",
        description: "Energy is typically lower. Focus on recovery and lighter movement.",
        trainingFocus: "Recovery, mobility, light cardio",
        intensityRecommendation: "Low to moderate",
        exercisesToEmphasize: ["Yoga", "Walking", "Light stretching", "Mobility work"],
        exercisesToAvoid: ["Heavy maximal lifts", "High-intensity intervals"],
      };
    case "follicular":
      return {
        phase,
        title: "Follicular Phase",
        description: "Rising energy and estrogen. Great time to build strength and endurance.",
        trainingFocus: "Strength building, skill work, endurance",
        intensityRecommendation: "Moderate to high",
        exercisesToEmphasize: ["Compound lifts", "Skill practice", "Endurance work"],
        exercisesToAvoid: [],
      };
    case "ovulation":
      return {
        phase,
        title: "Ovulation Phase",
        description: "Peak energy and strength. Ideal for PRs and maximal efforts.",
        trainingFocus: "Peak performance, PRs, competition prep",
        intensityRecommendation: "High",
        exercisesToEmphasize: ["Heavy singles/doubles", "Competition movements", "Power work"],
        exercisesToAvoid: [],
      };
    case "luteal":
      return {
        phase,
        title: "Luteal Phase",
        description: "Energy gradually decreases. Maintain volume, manage intensity.",
        trainingFocus: "Maintenance, moderate volume, technique",
        intensityRecommendation: "Moderate",
        exercisesToEmphasize: ["Volume work", "Technique drills", "Moderate conditioning"],
        exercisesToAvoid: ["Extreme volume increases"],
      };
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

```bash
cd /Users/dustinober/Projects/sundee-fundee/web-app && npx vitest run src/lib/domain/__tests__/cycle-calculations.test.ts
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
cd /Users/dustinober/Projects/sundee-fundee
git add web-app/src/lib/domain/cycle-calculations.ts web-app/src/lib/domain/__tests__/cycle-calculations.test.ts
git commit -m "feat: port cycle calculations (phase detection, boundaries, recommendations)"
```

---

### Task 10: Cycle Adaptation Policy

**Files:**
- Create: `web-app/src/lib/domain/cycle-adaptation-policy.ts`
- Create: `web-app/src/lib/domain/__tests__/cycle-adaptation-policy.test.ts`

- [ ] **Step 1: Write the tests**

```typescript
import { describe, it, expect } from "vitest";
import {
  PHASE_MULTIPLIERS,
  resolveReadinessTier,
  resolveConfidence,
  applyPhaseAdjustment,
} from "../cycle-adaptation-policy";
import type { ProgramExercise } from "../types";

describe("PHASE_MULTIPLIERS", () => {
  it("menstrual load is 0.90", () => expect(PHASE_MULTIPLIERS.menstrual.load).toBe(0.90));
  it("ovulation load is 1.12", () => expect(PHASE_MULTIPLIERS.ovulation.load).toBe(1.12));
  it("follicular load is 1.00", () => expect(PHASE_MULTIPLIERS.follicular.load).toBe(1.00));
  it("luteal load is 0.97", () => expect(PHASE_MULTIPLIERS.luteal.load).toBe(0.97));
});

describe("resolveReadinessTier", () => {
  it("low for score <= 3", () => expect(resolveReadinessTier(3)).toBe("low"));
  it("high for score >= 8", () => expect(resolveReadinessTier(8)).toBe("high"));
  it("neutral for 5", () => expect(resolveReadinessTier(5)).toBe("neutral"));
});

describe("resolveConfidence", () => {
  it("high with 3+ logs and recent phase", () => {
    expect(resolveConfidence("follicular", "follicular", 3, new Date())).toBe("high");
  });
  it("low with no logs", () => {
    expect(resolveConfidence("follicular", undefined, 0, undefined)).toBe("low");
  });
});

describe("applyPhaseAdjustment", () => {
  const baseExercise: ProgramExercise = {
    exercise: "Back Squat",
    sets: { type: "fixed", value: 4 },
    reps: { type: "fixed", value: 5 },
    percent1RM: 0.78,
  };

  it("adjusts for ovulation phase", () => {
    const result = applyPhaseAdjustment(baseExercise, "ovulation", "neutral", "high");
    // Load: 0.78 * (1 + (1.12 - 1) * 1.0 * 1.0) = 0.78 * 1.12 = 0.8736
    expect(result.percent1RM).toBeGreaterThan(0.78);
  });

  it("does not adjust AMRAP reps", () => {
    const amrapExercise: ProgramExercise = {
      exercise: "Pull-Up",
      sets: { type: "fixed", value: 3 },
      reps: { type: "amrap" },
    };
    const result = applyPhaseAdjustment(amrapExercise, "menstrual", "neutral", "high");
    expect(result.reps).toEqual({ type: "amrap" });
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

```bash
cd /Users/dustinober/Projects/sundee-fundee/web-app && npx vitest run src/lib/domain/__tests__/cycle-adaptation-policy.test.ts
```

Expected: FAIL.

- [ ] **Step 3: Create `web-app/src/lib/domain/cycle-adaptation-policy.ts`**

```typescript
import type { CyclePhase, ExerciseValue, ProgramExercise } from "./types";

export type ReadinessTier = "low" | "neutral" | "high";
export type AdaptationConfidence = "low" | "medium" | "high";

interface PhaseMultiplier {
  load: number;
  sets: number;
  reps: number;
}

export const PHASE_MULTIPLIERS: Record<CyclePhase, PhaseMultiplier> = {
  menstrual: { load: 0.90, sets: 0.90, reps: 0.90 },
  follicular: { load: 1.00, sets: 1.00, reps: 1.00 },
  ovulation: { load: 1.12, sets: 1.05, reps: 0.95 },
  luteal: { load: 0.97, sets: 0.95, reps: 0.92 },
};

const READINESS_SCALES: Record<ReadinessTier, number> = {
  low: 0.6,
  neutral: 1.0,
  high: 1.2,
};

const CONFIDENCE_SCALES: Record<AdaptationConfidence, number> = {
  low: 0.55,
  medium: 0.8,
  high: 1.0,
};

export function resolveReadinessTier(score: number): ReadinessTier {
  if (score <= 3) return "low";
  if (score >= 8) return "high";
  return "neutral";
}

export function resolveConfidence(
  currentPhase: CyclePhase,
  lastKnownPhase: CyclePhase | undefined,
  periodLogCount: number,
  lastPeriodStart: Date | undefined
): AdaptationConfidence {
  if (periodLogCount === 0 || !lastKnownPhase) return "low";
  if (periodLogCount < 3) return "medium";
  // High confidence: 3+ logs, phase matches or recent data
  if (lastPeriodStart) {
    const daysSince = (Date.now() - lastPeriodStart.getTime()) / 86_400_000;
    if (daysSince > 60) return "medium"; // stale data
  }
  return "high";
}

function clamp(value: number, min: number, max: number): number {
  return Math.max(min, Math.min(max, value));
}

function adjustExerciseValue(ev: ExerciseValue, multiplier: number): ExerciseValue {
  switch (ev.type) {
    case "fixed":
      return { type: "fixed", value: Math.max(1, Math.round(ev.value * multiplier)) };
    case "range":
      return {
        type: "range",
        low: Math.max(1, Math.round(ev.low * multiplier)),
        high: Math.max(1, Math.round(ev.high * multiplier)),
      };
    case "amrap":
    case "text":
      return ev; // No adjustment for AMRAP or text
  }
}

export function applyPhaseAdjustment(
  exercise: ProgramExercise,
  phase: CyclePhase,
  readinessTier: ReadinessTier,
  confidence: AdaptationConfidence
): ProgramExercise {
  const mult = PHASE_MULTIPLIERS[phase];
  const readinessScale = READINESS_SCALES[readinessTier];
  const confidenceScale = CONFIDENCE_SCALES[confidence];

  const blend = (target: number) =>
    clamp(1.0 + (target - 1.0) * readinessScale * confidenceScale, 0.75, 1.25);

  const loadMult = blend(mult.load);
  const setsMult = blend(mult.sets);
  const repsMult = blend(mult.reps);

  return {
    ...exercise,
    sets: adjustExerciseValue(exercise.sets, setsMult),
    reps: adjustExerciseValue(exercise.reps, repsMult),
    percent1RM: exercise.percent1RM != null
      ? exercise.percent1RM * loadMult
      : undefined,
  };
}
```

- [ ] **Step 4: Run test to verify it passes**

```bash
cd /Users/dustinober/Projects/sundee-fundee/web-app && npx vitest run src/lib/domain/__tests__/cycle-adaptation-policy.test.ts
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
cd /Users/dustinober/Projects/sundee-fundee
git add web-app/src/lib/domain/cycle-adaptation-policy.ts web-app/src/lib/domain/__tests__/cycle-adaptation-policy.test.ts
git commit -m "feat: port cycle adaptation policy (phase multipliers, readiness, confidence)"
```

---

### Task 11: Load Adjustment Policy + Pain Trend Analyzer + Phase Transition Advisor

**Files:**
- Create: `web-app/src/lib/domain/injury-support.ts`
- Create: `web-app/src/lib/domain/__tests__/injury-support.test.ts`

- [ ] **Step 1: Write the tests**

```typescript
import { describe, it, expect } from "vitest";
import {
  LOAD_MULTIPLIERS,
  adjustExerciseValueByMultiplier,
  adjustLoad,
  applyLoadMultipliers,
  analyzePainTrend,
  hasRecentLog,
  sparklineData,
  evaluateTransition,
} from "../injury-support";

describe("LOAD_MULTIPLIERS", () => {
  it("acute zeroes everything", () => {
    expect(LOAD_MULTIPLIERS.acute).toEqual({ load: 0, sets: 0, reps: 0 });
  });
  it("rehab has 30% load", () => {
    expect(LOAD_MULTIPLIERS.rehab.load).toBe(0.30);
  });
  it("resolved is full", () => {
    expect(LOAD_MULTIPLIERS.resolved).toEqual({ load: 1, sets: 1, reps: 1 });
  });
});

describe("analyzePainTrend", () => {
  it("detects improving trend", () => {
    const logs = [
      { painLevel: 3, recordedAt: new Date("2026-03-29") },
      { painLevel: 4, recordedAt: new Date("2026-03-28") },
      { painLevel: 5, recordedAt: new Date("2026-03-27") },
      { painLevel: 6, recordedAt: new Date("2026-03-26") },
    ];
    const result = analyzePainTrend(logs);
    expect(result.isImproving).toBe(true);
  });

  it("detects worsening trend", () => {
    const logs = [
      { painLevel: 7, recordedAt: new Date("2026-03-29") },
      { painLevel: 6, recordedAt: new Date("2026-03-28") },
      { painLevel: 5, recordedAt: new Date("2026-03-27") },
      { painLevel: 4, recordedAt: new Date("2026-03-26") },
    ];
    const result = analyzePainTrend(logs);
    expect(result.isImproving).toBe(false);
  });

  it("returns null for insufficient data", () => {
    expect(analyzePainTrend([])).toBeNull();
  });
});

describe("hasRecentLog", () => {
  it("true for log within 24 hours", () => {
    const now = new Date();
    const recent = new Date(now.getTime() - 12 * 3600_000);
    expect(hasRecentLog([{ recordedAt: recent }], now)).toBe(true);
  });

  it("false for old logs", () => {
    const now = new Date();
    const old = new Date(now.getTime() - 48 * 3600_000);
    expect(hasRecentLog([{ recordedAt: old }], now)).toBe(false);
  });
});

describe("sparklineData", () => {
  it("returns last N pain levels reversed", () => {
    const logs = [
      { painLevel: 5, recordedAt: new Date("2026-03-29") },
      { painLevel: 4, recordedAt: new Date("2026-03-28") },
      { painLevel: 3, recordedAt: new Date("2026-03-27") },
    ];
    expect(sparklineData(logs, 3)).toEqual([3, 4, 5]);
  });
});

describe("evaluateTransition", () => {
  it("suggests rehab after 3 days pain <= 5 from acute", () => {
    const logs = [
      { painLevel: 4, recordedAt: new Date("2026-03-29") },
      { painLevel: 5, recordedAt: new Date("2026-03-28") },
      { painLevel: 3, recordedAt: new Date("2026-03-27") },
    ];
    const result = evaluateTransition("injury1", "acute", logs);
    expect(result).toEqual({ injuryId: "injury1", currentPhase: "acute", suggestedPhase: "rehab" });
  });

  it("returns null if threshold not met", () => {
    const logs = [
      { painLevel: 7, recordedAt: new Date("2026-03-29") },
      { painLevel: 5, recordedAt: new Date("2026-03-28") },
      { painLevel: 3, recordedAt: new Date("2026-03-27") },
    ];
    expect(evaluateTransition("injury1", "acute", logs)).toBeNull();
  });

  it("returns null for resolved phase", () => {
    expect(evaluateTransition("injury1", "resolved", [])).toBeNull();
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

```bash
cd /Users/dustinober/Projects/sundee-fundee/web-app && npx vitest run src/lib/domain/__tests__/injury-support.test.ts
```

Expected: FAIL.

- [ ] **Step 3: Create `web-app/src/lib/domain/injury-support.ts`**

```typescript
import type { RecoveryPhase, ExerciseValue, ProgramExercise } from "./types";

// ============================================================
// Load Adjustment Policy — from LoadAdjustmentPolicy.swift
// ============================================================

interface PhaseMultipliers {
  load: number;
  sets: number;
  reps: number;
}

export const LOAD_MULTIPLIERS: Record<RecoveryPhase, PhaseMultipliers> = {
  acute: { load: 0, sets: 0, reps: 0 },
  rehab: { load: 0.30, sets: 0.50, reps: 0.70 },
  lightLoad: { load: 0.50, sets: 0.75, reps: 0.85 },
  returnToPlay: { load: 0.80, sets: 0.90, reps: 1.0 },
  resolved: { load: 1, sets: 1, reps: 1 },
};

export function adjustExerciseValueByMultiplier(ev: ExerciseValue, multiplier: number): ExerciseValue {
  switch (ev.type) {
    case "fixed":
      return { type: "fixed", value: Math.max(1, Math.round(ev.value * multiplier)) };
    case "range":
      return {
        type: "range",
        low: Math.max(1, Math.round(ev.low * multiplier)),
        high: Math.max(1, Math.round(ev.high * multiplier)),
      };
    case "amrap":
    case "text":
      return ev;
  }
}

export function adjustLoad(percent1RM: number, multiplier: number): number {
  return percent1RM * multiplier;
}

export function applyLoadMultipliers(exercise: ProgramExercise, phase: RecoveryPhase): ProgramExercise {
  const mult = LOAD_MULTIPLIERS[phase];
  return {
    ...exercise,
    sets: adjustExerciseValueByMultiplier(exercise.sets, mult.sets),
    reps: adjustExerciseValueByMultiplier(exercise.reps, mult.reps),
    percent1RM: exercise.percent1RM != null ? adjustLoad(exercise.percent1RM, mult.load) : undefined,
  };
}

// ============================================================
// Pain Trend Analyzer — from PainTrendAnalyzer.swift
// ============================================================

interface PainLogEntry {
  painLevel: number;
  recordedAt: Date;
}

export interface TrendResult {
  trailingAverage: number;
  isImproving: boolean;
  latestPainLevel: number;
  readingCount: number;
}

export function analyzePainTrend(logs: PainLogEntry[], windowSize: number = 7): TrendResult | null {
  if (logs.length === 0) return null;

  const sorted = [...logs].sort((a, b) => b.recordedAt.getTime() - a.recordedAt.getTime());
  const window = sorted.slice(0, windowSize);

  const sum = window.reduce((acc, l) => acc + l.painLevel, 0);
  const trailingAverage = sum / window.length;

  // Compare first half vs second half to determine trend
  const mid = Math.floor(window.length / 2);
  const recentHalf = window.slice(0, mid);
  const olderHalf = window.slice(mid);

  const recentAvg = recentHalf.reduce((a, l) => a + l.painLevel, 0) / (recentHalf.length || 1);
  const olderAvg = olderHalf.reduce((a, l) => a + l.painLevel, 0) / (olderHalf.length || 1);

  return {
    trailingAverage,
    isImproving: recentAvg < olderAvg,
    latestPainLevel: window[0].painLevel,
    readingCount: window.length,
  };
}

export function hasRecentLog(
  logs: { recordedAt: Date }[],
  referenceDate: Date = new Date(),
  withinHours: number = 24
): boolean {
  const cutoff = referenceDate.getTime() - withinHours * 3600_000;
  return logs.some((l) => l.recordedAt.getTime() >= cutoff);
}

export function sparklineData(logs: PainLogEntry[], count: number = 7): number[] {
  const sorted = [...logs].sort((a, b) => b.recordedAt.getTime() - a.recordedAt.getTime());
  return sorted.slice(0, count).map((l) => l.painLevel).reverse();
}

// ============================================================
// Phase Transition Advisor — from PhaseTransitionAdvisor.swift
// ============================================================

interface TransitionSuggestion {
  injuryId: string;
  currentPhase: RecoveryPhase;
  suggestedPhase: RecoveryPhase;
}

interface TransitionRule {
  requiredDays: number;
  maxPain: number;
  nextPhase: RecoveryPhase;
}

const TRANSITION_RULES: Partial<Record<RecoveryPhase, TransitionRule>> = {
  acute: { requiredDays: 3, maxPain: 5, nextPhase: "rehab" },
  rehab: { requiredDays: 3, maxPain: 3, nextPhase: "lightLoad" },
  lightLoad: { requiredDays: 3, maxPain: 2, nextPhase: "returnToPlay" },
  returnToPlay: { requiredDays: 5, maxPain: 1, nextPhase: "resolved" },
};

function meetsThreshold(logs: PainLogEntry[], count: number, maxPain: number): boolean {
  if (logs.length < count) return false;
  const sorted = [...logs].sort((a, b) => b.recordedAt.getTime() - a.recordedAt.getTime());
  return sorted.slice(0, count).every((l) => l.painLevel <= maxPain);
}

export function evaluateTransition(
  injuryId: string,
  currentPhase: RecoveryPhase,
  painLogs: PainLogEntry[]
): TransitionSuggestion | null {
  const rule = TRANSITION_RULES[currentPhase];
  if (!rule) return null;

  if (meetsThreshold(painLogs, rule.requiredDays, rule.maxPain)) {
    return {
      injuryId,
      currentPhase,
      suggestedPhase: rule.nextPhase,
    };
  }

  return null;
}
```

- [ ] **Step 4: Run test to verify it passes**

```bash
cd /Users/dustinober/Projects/sundee-fundee/web-app && npx vitest run src/lib/domain/__tests__/injury-support.test.ts
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
cd /Users/dustinober/Projects/sundee-fundee
git add web-app/src/lib/domain/injury-support.ts web-app/src/lib/domain/__tests__/injury-support.test.ts
git commit -m "feat: port load adjustment, pain trend analysis, phase transition advisor"
```

---

### Task 12: Injury Adaptation Engine

**Files:**
- Create: `web-app/src/lib/domain/injury-adaptation-engine.ts`
- Create: `web-app/src/lib/domain/__tests__/injury-adaptation-engine.test.ts`

- [ ] **Step 1: Write the tests**

```typescript
import { describe, it, expect } from "vitest";
import { adaptProgram, normalizeBodyRegions, buildRecoveryPrepBlock, mostRestrictivePhase } from "../injury-adaptation-engine";
import type { Program, ProgramExercise } from "../types";

describe("normalizeBodyRegions", () => {
  it("extracts engine keys from regions", () => {
    const regions = normalizeBodyRegions(["knee_left", "shoulder_right"]);
    expect(regions).toContain("knee");
    expect(regions).toContain("shoulder");
  });

  it("normalizes clinical synonyms", () => {
    const regions = normalizeBodyRegions([], "ACL tear, rotator cuff");
    expect(regions).toContain("knee");
    expect(regions).toContain("shoulder");
  });
});

describe("mostRestrictivePhase", () => {
  it("returns acute over rehab", () => {
    expect(mostRestrictivePhase(["rehab", "acute"])).toBe("acute");
  });
  it("returns resolved when only resolved", () => {
    expect(mostRestrictivePhase(["resolved"])).toBe("resolved");
  });
});

describe("buildRecoveryPrepBlock", () => {
  it("generates exercises for knee injury", () => {
    const block = buildRecoveryPrepBlock([{ engineKeys: ["knee"], phase: "rehab" }]);
    expect(block.length).toBeGreaterThan(0);
    expect(block[0].notes).toContain("tempo");
  });
});

describe("adaptProgram", () => {
  const testProgram: Program = {
    id: "test",
    name: "Test Program",
    category: "Strength",
    description: "Test",
    durationWeeks: 1,
    sessionsPerWeek: 1,
    difficulty: "Intermediate",
    phases: [],
    weeks: [
      {
        week: 1,
        sessions: [
          {
            sessionId: "s1",
            sessionName: "Day 1",
            sessionType: "strength",
            focus: "lower",
            exercises: [
              { exercise: "Back Squat", sets: { type: "fixed", value: 4 }, reps: { type: "fixed", value: 5 }, percent1RM: 0.78 },
              { exercise: "Barbell Row", sets: { type: "fixed", value: 3 }, reps: { type: "fixed", value: 8 } },
            ],
          },
        ],
      },
    ],
  };

  it("replaces contraindicated exercises in acute phase", () => {
    const result = adaptProgram(testProgram, [
      { engineKeys: ["knee"], phase: "acute", location: "Left Knee" },
    ]);
    const exercises = result.weeks[0].sessions[0].exercises;
    // Back Squat should be replaced (knee contraindication)
    expect(exercises.some((e) => e.exercise === "Back Squat")).toBe(false);
  });

  it("does not modify non-contraindicated exercises", () => {
    const result = adaptProgram(testProgram, [
      { engineKeys: ["wrist"], phase: "acute", location: "Left Wrist" },
    ]);
    const exercises = result.weeks[0].sessions[0].exercises;
    // Back Squat is not wrist-contraindicated
    expect(exercises.some((e) => e.exercise === "Back Squat")).toBe(true);
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

```bash
cd /Users/dustinober/Projects/sundee-fundee/web-app && npx vitest run src/lib/domain/__tests__/injury-adaptation-engine.test.ts
```

Expected: FAIL.

- [ ] **Step 3: Create `web-app/src/lib/domain/injury-adaptation-engine.ts`**

This is the largest domain file. Port the complete contraindication rules, regression table, clinical synonyms, and recovery prep map from `InjuryAdaptationEngine.swift`.

```typescript
import type { RecoveryPhase, Program, ProgramExercise, ProgramSession } from "./types";
import { BODY_REGIONS } from "./body-location";
import { LOAD_MULTIPLIERS, adjustExerciseValueByMultiplier, adjustLoad } from "./injury-support";

// ============================================================
// Types
// ============================================================

export interface InjuryInput {
  engineKeys: string[];
  phase: RecoveryPhase;
  location: string;
}

// ============================================================
// Contraindication Rules — from InjuryAdaptationEngine.swift
// ============================================================

const CONTRAINDICATIONS: Record<string, { categories: string[]; keywords: string[] }> = {
  knee: {
    categories: ["Squat"],
    keywords: ["squat", "lunge", "leg press", "leg extension", "box jump", "jump"],
  },
  shoulder: {
    categories: ["Press", "Olympic Weightlifting"],
    keywords: ["press", "overhead", "bench", "push-up", "dip", "fly", "raise"],
  },
  back: {
    categories: ["Hip Hinge"],
    keywords: ["deadlift", "good morning", "row", "back extension", "hyperextension"],
  },
  hip: {
    categories: [],
    keywords: ["hip thrust", "glute", "hamstring", "lunge", "step-up"],
  },
  wrist: {
    categories: ["Olympic Weightlifting"],
    keywords: ["clean", "snatch", "jerk", "front squat", "wrist"],
  },
  elbow: {
    categories: [],
    keywords: ["curl", "tricep", "extension", "press"],
  },
  ankle: {
    categories: [],
    keywords: ["calf", "jump", "run", "sprint", "box jump"],
  },
};

// ============================================================
// Regression Table — from InjuryAdaptationEngine.swift
// ============================================================

const REGRESSION_TABLE: Record<string, string[]> = {
  "Back Squat": ["Goblet Squat", "Box Squat", "Air Squats"],
  "Front Squat": ["Goblet Squat", "Box Squat", "Air Squats"],
  "Flat Barbell Bench Press": ["Dumbbell Bench Press", "Push-Ups", "Floor Press"],
  "Incline Barbell Bench Press": ["Dumbbell Bench Press", "Push-Ups"],
  "Strict Press": ["Dumbbell Overhead Press", "Lateral Raises"],
  "Conventional Deadlift (No Straps)": ["Romanian Deadlift (No Straps)", "Hip Thrust", "Glute Bridge"],
  "Conventional Deadlift (With Straps)": ["Romanian Deadlift (With Straps)", "Hip Thrust", "Glute Bridge"],
  "Sumo Deadlift (No Straps)": ["Romanian Deadlift (No Straps)", "Hip Thrust"],
  "Sumo Deadlift (With Straps)": ["Romanian Deadlift (With Straps)", "Hip Thrust"],
  "Barbell Row": ["Cable Row", "Lat Pulldown", "Band Pull-Aparts"],
  "Pull-Up": ["Lat Pulldown", "Band-Assisted Pull-Up"],
  "Squat Snatch": ["Power Snatch", "Hang Snatch", "Overhead Squat"],
  "Squat Clean": ["Power Clean", "Hang Clean"],
  "Clean and Jerk": ["Power Clean", "Push Press"],
};

// ============================================================
// Clinical Synonym Normalization — from InjuryAdaptationEngine.swift
// ============================================================

const CLINICAL_SYNONYMS: Record<string, string> = {
  acl: "knee",
  mcl: "knee",
  meniscus: "knee",
  patella: "knee",
  "rotator cuff": "shoulder",
  labrum: "shoulder",
  "frozen shoulder": "shoulder",
  lumbar: "back",
  "herniated disc": "back",
  sciatica: "back",
  "si joint": "hip",
  piriformis: "hip",
  "carpal tunnel": "wrist",
  "tennis elbow": "elbow",
  "golfers elbow": "elbow",
  achilles: "ankle",
  "plantar fascia": "ankle",
};

// ============================================================
// Recovery Prep Map — from InjuryAdaptationEngine.swift
// ============================================================

const RECOVERY_PREP: Record<string, string[]> = {
  knee: ["Bird-Dogs", "Reverse Lunges", "Terminal Knee Extension"],
  shoulder: ["Band Pull-Aparts", "Face Pulls", "Wall Slides"],
  back: ["Cat-Cow", "Bird-Dogs", "Dead Bugs"],
  hip: ["Glute Bridges", "Clamshells", "Side-Lying Hip Abduction"],
  wrist: ["Wrist Circles", "Finger Extensions", "Prayer Stretches"],
  elbow: ["Wrist Curls", "Reverse Wrist Curls", "Forearm Pronation"],
  ankle: ["Calf Raises", "Ankle Circles", "Banded Dorsiflexion"],
};

// ============================================================
// Public API
// ============================================================

export function normalizeBodyRegions(regions: string[], freeText?: string): string[] {
  const keys = new Set<string>();

  // From structured regions
  for (const regionId of regions) {
    const region = BODY_REGIONS.find((r) => r.id === regionId);
    if (region) keys.add(region.engineKey);
  }

  // From free text (clinical synonyms)
  if (freeText) {
    const lower = freeText.toLowerCase();
    for (const [synonym, key] of Object.entries(CLINICAL_SYNONYMS)) {
      if (lower.includes(synonym)) keys.add(key);
    }
  }

  return Array.from(keys);
}

export function mostRestrictivePhase(phases: RecoveryPhase[]): RecoveryPhase {
  const order: RecoveryPhase[] = ["acute", "rehab", "lightLoad", "returnToPlay", "resolved"];
  for (const phase of order) {
    if (phases.includes(phase)) return phase;
  }
  return "resolved";
}

function isContraindicated(exercise: ProgramExercise, engineKeys: string[]): boolean {
  const name = exercise.exercise.toLowerCase();
  for (const key of engineKeys) {
    const rules = CONTRAINDICATIONS[key];
    if (!rules) continue;
    if (rules.keywords.some((kw) => name.includes(kw))) return true;
  }
  return false;
}

function findRegression(exerciseName: string): string | undefined {
  const regressions = REGRESSION_TABLE[exerciseName];
  return regressions?.[0]; // First regression is the closest substitute
}

function safeBodyweightExercise(): ProgramExercise {
  return {
    exercise: "Air Squats",
    sets: { type: "fixed", value: 2 },
    reps: { type: "fixed", value: 10 },
    bodyweightOnly: true,
    notes: "Safe bodyweight alternative",
  };
}

export function buildRecoveryPrepBlock(injuries: { engineKeys: string[]; phase: RecoveryPhase }[]): ProgramExercise[] {
  const exercises: ProgramExercise[] = [];
  const seen = new Set<string>();

  for (const injury of injuries) {
    for (const key of injury.engineKeys) {
      const preps = RECOVERY_PREP[key] ?? [];
      for (const prep of preps) {
        if (seen.has(prep)) continue;
        seen.add(prep);

        let sets = 2;
        let reps = 10;
        let notes = "gentle tempo";

        if (injury.phase === "rehab") {
          sets = 3; reps = 12; notes = "controlled tempo";
        } else if (injury.phase === "lightLoad") {
          sets = 2; reps = 15; notes = "slow tempo, full ROM";
        }

        exercises.push({
          exercise: prep,
          sets: { type: "fixed", value: sets },
          reps: { type: "fixed", value: reps },
          bodyweightOnly: true,
          notes,
        });
      }
    }
  }

  return exercises;
}

export function adaptProgram(program: Program, injuries: InjuryInput[]): Program {
  if (injuries.length === 0) return program;

  const allEngineKeys = injuries.flatMap((i) => i.engineKeys);
  const overallPhase = mostRestrictivePhase(injuries.map((i) => i.phase));

  const adaptedWeeks = program.weeks.map((week) => ({
    ...week,
    sessions: week.sessions.map((session) => adaptSession(session, allEngineKeys, overallPhase, injuries)),
  }));

  return { ...program, weeks: adaptedWeeks };
}

function adaptSession(
  session: ProgramSession,
  engineKeys: string[],
  phase: RecoveryPhase,
  injuries: InjuryInput[]
): ProgramSession {
  let exercises: ProgramExercise[];

  switch (phase) {
    case "acute":
      exercises = session.exercises.map((ex) =>
        isContraindicated(ex, engineKeys)
          ? findRegressionExercise(ex) ?? safeBodyweightExercise()
          : ex
      );
      break;

    case "rehab": {
      const prep = buildRecoveryPrepBlock(injuries);
      exercises = [
        ...prep,
        ...session.exercises.map((ex) =>
          isContraindicated(ex, engineKeys)
            ? findRegressionExercise(ex) ?? safeBodyweightExercise()
            : ex
        ),
      ];
      break;
    }

    case "lightLoad": {
      const prep = buildRecoveryPrepBlock(injuries);
      const mult = LOAD_MULTIPLIERS.lightLoad;
      exercises = [
        ...prep,
        ...session.exercises.map((ex) => {
          if (isContraindicated(ex, engineKeys)) {
            const regression = findRegressionExercise(ex) ?? safeBodyweightExercise();
            return applyLoadMult(regression, mult);
          }
          return applyLoadMult(ex, mult);
        }),
      ];
      break;
    }

    case "returnToPlay": {
      const prep = buildRecoveryPrepBlock(injuries);
      exercises = [...prep, ...session.exercises];
      break;
    }

    case "resolved":
      exercises = session.exercises;
      break;
  }

  return { ...session, exercises };
}

function findRegressionExercise(exercise: ProgramExercise): ProgramExercise | undefined {
  const replacement = findRegression(exercise.exercise);
  if (!replacement) return undefined;
  return { ...exercise, exercise: replacement };
}

function applyLoadMult(ex: ProgramExercise, mult: { load: number; sets: number; reps: number }): ProgramExercise {
  return {
    ...ex,
    sets: adjustExerciseValueByMultiplier(ex.sets, mult.sets),
    reps: adjustExerciseValueByMultiplier(ex.reps, mult.reps),
    percent1RM: ex.percent1RM != null ? adjustLoad(ex.percent1RM, mult.load) : undefined,
  };
}
```

- [ ] **Step 4: Run test to verify it passes**

```bash
cd /Users/dustinober/Projects/sundee-fundee/web-app && npx vitest run src/lib/domain/__tests__/injury-adaptation-engine.test.ts
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
cd /Users/dustinober/Projects/sundee-fundee
git add web-app/src/lib/domain/injury-adaptation-engine.ts web-app/src/lib/domain/__tests__/injury-adaptation-engine.test.ts
git commit -m "feat: port injury adaptation engine (contraindications, regressions, recovery prep)"
```

---

### Task 13: Benchmark Catalog + Celebration Events

**Files:**
- Create: `web-app/src/lib/domain/benchmark-catalog.ts`
- Create: `web-app/src/lib/domain/celebration-event.ts`
- Create: `web-app/src/lib/domain/__tests__/benchmark-catalog.test.ts`
- Create: `web-app/src/lib/domain/__tests__/celebration-event.test.ts`

- [ ] **Step 1: Write the benchmark catalog tests**

```typescript
import { describe, it, expect } from "vitest";
import { PREDEFINED_BENCHMARKS, groupedByCategory } from "../benchmark-catalog";

describe("PREDEFINED_BENCHMARKS", () => {
  it("has 23+ benchmarks", () => {
    expect(PREDEFINED_BENCHMARKS.length).toBeGreaterThanOrEqual(23);
  });

  it("Fran is time-scored", () => {
    const fran = PREDEFINED_BENCHMARKS.find((b) => b.name === "Fran");
    expect(fran?.scoringType).toBe("time");
  });

  it("all are predefined", () => {
    expect(PREDEFINED_BENCHMARKS.every((b) => b.isPredefined)).toBe(true);
  });
});

describe("groupedByCategory", () => {
  it("has Classic WODs category", () => {
    const groups = groupedByCategory();
    expect(groups.has("Classic WODs")).toBe(true);
  });
});
```

- [ ] **Step 2: Write the celebration event tests**

```typescript
import { describe, it, expect } from "vitest";
import { celebrationSubtitle, type CelebrationEvent } from "../celebration-event";

describe("celebrationSubtitle", () => {
  it("formats workout completed", () => {
    const event: CelebrationEvent = { type: "workoutCompleted", durationSeconds: 3600 };
    expect(celebrationSubtitle(event, "kg")).toContain("60");
  });

  it("formats new PR", () => {
    const event: CelebrationEvent = { type: "newPersonalRecord", exerciseName: "Back Squat", weightKg: 140 };
    expect(celebrationSubtitle(event, "kg")).toContain("140");
    expect(celebrationSubtitle(event, "kg")).toContain("Back Squat");
  });

  it("formats program completed", () => {
    const event: CelebrationEvent = { type: "programCompleted", programName: "Starting Strength" };
    expect(celebrationSubtitle(event, "kg")).toContain("Starting Strength");
  });
});
```

- [ ] **Step 3: Run tests to verify they fail**

```bash
cd /Users/dustinober/Projects/sundee-fundee/web-app && npx vitest run src/lib/domain/__tests__/benchmark-catalog.test.ts src/lib/domain/__tests__/celebration-event.test.ts
```

Expected: FAIL.

- [ ] **Step 4: Create `web-app/src/lib/domain/benchmark-catalog.ts`**

Port all 23+ predefined benchmarks from `BenchmarkCatalog.swift`:

```typescript
import type { BenchmarkScoringType } from "./types";

export interface PredefinedBenchmark {
  id: string;
  name: string;
  category: string;
  workoutDescription: string;
  scoringType: BenchmarkScoringType;
  isPredefined: true;
  sortOrder: number;
}

export const PREDEFINED_BENCHMARKS: PredefinedBenchmark[] = [
  // Classic WODs
  { id: "fran", name: "Fran", category: "Classic WODs", workoutDescription: "21-15-9: Thrusters (95/65 lb) and Pull-ups", scoringType: "time", isPredefined: true, sortOrder: 0 },
  { id: "grace", name: "Grace", category: "Classic WODs", workoutDescription: "30 Clean and Jerks for time (135/95 lb)", scoringType: "time", isPredefined: true, sortOrder: 1 },
  { id: "helen", name: "Helen", category: "Classic WODs", workoutDescription: "3 rounds: 400m Run, 21 KB Swings (53/35 lb), 12 Pull-ups", scoringType: "time", isPredefined: true, sortOrder: 2 },
  { id: "diane", name: "Diane", category: "Classic WODs", workoutDescription: "21-15-9: Deadlifts (225/155 lb) and Handstand Push-ups", scoringType: "time", isPredefined: true, sortOrder: 3 },
  { id: "isabel", name: "Isabel", category: "Classic WODs", workoutDescription: "30 Snatches for time (135/95 lb)", scoringType: "time", isPredefined: true, sortOrder: 4 },
  { id: "cindy", name: "Cindy", category: "Classic WODs", workoutDescription: "AMRAP 20 min: 5 Pull-ups, 10 Push-ups, 15 Air Squats", scoringType: "roundsAndReps", isPredefined: true, sortOrder: 5 },
  { id: "mary", name: "Mary", category: "Classic WODs", workoutDescription: "AMRAP 20 min: 5 Handstand Push-ups, 10 Pistols, 15 Pull-ups", scoringType: "roundsAndReps", isPredefined: true, sortOrder: 6 },
  { id: "murph", name: "Murph", category: "Classic WODs", workoutDescription: "1-mile Run, 100 Pull-ups, 200 Push-ups, 300 Squats, 1-mile Run (20/14 lb vest)", scoringType: "time", isPredefined: true, sortOrder: 7 },
  { id: "filthy-fifty", name: "Filthy Fifty", category: "Classic WODs", workoutDescription: "50 each: Box Jumps, Jumping Pull-ups, KB Swings, Walking Lunges, K2E, Push Press, Back Extensions, Wall Balls, Burpees, Double Unders", scoringType: "time", isPredefined: true, sortOrder: 8 },
  // Strength
  { id: "1rm-back-squat", name: "1RM Back Squat", category: "Strength", workoutDescription: "Find your one-rep max Back Squat", scoringType: "weight", isPredefined: true, sortOrder: 10 },
  { id: "1rm-bench-press", name: "1RM Bench Press", category: "Strength", workoutDescription: "Find your one-rep max Bench Press", scoringType: "weight", isPredefined: true, sortOrder: 11 },
  { id: "1rm-deadlift", name: "1RM Deadlift", category: "Strength", workoutDescription: "Find your one-rep max Deadlift", scoringType: "weight", isPredefined: true, sortOrder: 12 },
  { id: "1rm-strict-press", name: "1RM Strict Press", category: "Strength", workoutDescription: "Find your one-rep max Strict Press", scoringType: "weight", isPredefined: true, sortOrder: 13 },
  { id: "1rm-clean-jerk", name: "1RM Clean & Jerk", category: "Strength", workoutDescription: "Find your one-rep max Clean and Jerk", scoringType: "weight", isPredefined: true, sortOrder: 14 },
  { id: "1rm-snatch", name: "1RM Snatch", category: "Strength", workoutDescription: "Find your one-rep max Snatch", scoringType: "weight", isPredefined: true, sortOrder: 15 },
  // Endurance
  { id: "1-mile-run", name: "1-Mile Run", category: "Endurance", workoutDescription: "Run 1 mile for time", scoringType: "time", isPredefined: true, sortOrder: 20 },
  { id: "5k-run", name: "5K Run", category: "Endurance", workoutDescription: "Run 5 kilometers for time", scoringType: "time", isPredefined: true, sortOrder: 21 },
  { id: "2k-row", name: "2K Row", category: "Endurance", workoutDescription: "Row 2,000 meters for time", scoringType: "time", isPredefined: true, sortOrder: 22 },
  { id: "500m-row", name: "500m Row", category: "Endurance", workoutDescription: "Row 500 meters for time", scoringType: "time", isPredefined: true, sortOrder: 23 },
  // Gymnastics
  { id: "max-pullups", name: "Max Pull-ups", category: "Gymnastics", workoutDescription: "Max unbroken strict Pull-ups", scoringType: "reps", isPredefined: true, sortOrder: 30 },
  { id: "max-pushups", name: "Max Push-ups", category: "Gymnastics", workoutDescription: "Max unbroken Push-ups", scoringType: "reps", isPredefined: true, sortOrder: 31 },
  { id: "max-muscle-ups", name: "Max Muscle-ups", category: "Gymnastics", workoutDescription: "Max unbroken Muscle-ups (bar or ring)", scoringType: "reps", isPredefined: true, sortOrder: 32 },
  // General Fitness
  { id: "max-calories-10min", name: "Max Calories (10 min)", category: "General Fitness", workoutDescription: "Max calories on Assault Bike or Rower in 10 minutes", scoringType: "reps", isPredefined: true, sortOrder: 40 },
];

/** Group benchmarks by category for UI display */
export function groupedByCategory(): Map<string, PredefinedBenchmark[]> {
  const map = new Map<string, PredefinedBenchmark[]>();
  for (const bm of PREDEFINED_BENCHMARKS) {
    const group = map.get(bm.category) ?? [];
    group.push(bm);
    map.set(bm.category, group);
  }
  return map;
}
```

- [ ] **Step 5: Create `web-app/src/lib/domain/celebration-event.ts`**

```typescript
import type { WeightUnit, ConditioningScoringType } from "./types";
import { formatWeightWithUnit } from "./weight-unit-conversion";
import { formatConditioningValue } from "./exercise-catalog";

export type CelebrationEvent =
  | { type: "workoutCompleted"; durationSeconds: number }
  | { type: "newPersonalRecord"; exerciseName: string; weightKg: number }
  | { type: "programCompleted"; programName: string }
  | { type: "weightMilestone"; exerciseName: string; thresholdKg: number }
  | { type: "newConditioningPR"; exerciseName: string; value: number; scoringType: ConditioningScoringType };

export function celebrationTitle(event: CelebrationEvent): string {
  switch (event.type) {
    case "workoutCompleted": return "Workout Complete!";
    case "newPersonalRecord": return "New PR!";
    case "programCompleted": return "Program Complete!";
    case "weightMilestone": return "Weight Milestone!";
    case "newConditioningPR": return "New Conditioning PR!";
  }
}

export function celebrationSubtitle(event: CelebrationEvent, unit: WeightUnit): string {
  switch (event.type) {
    case "workoutCompleted": {
      const minutes = Math.round(event.durationSeconds / 60);
      return `Completed in ${minutes} min`;
    }
    case "newPersonalRecord":
      return `${event.exerciseName} \u2014 ${formatWeightWithUnit(event.weightKg, unit)} estimated 1RM`;
    case "programCompleted":
      return `You finished ${event.programName}`;
    case "weightMilestone":
      return `${event.exerciseName} hit ${formatWeightWithUnit(event.thresholdKg, unit)}`;
    case "newConditioningPR":
      return `${event.exerciseName} \u2014 ${formatConditioningValue(event.value, event.scoringType)}`;
  }
}
```

- [ ] **Step 6: Run tests to verify they pass**

```bash
cd /Users/dustinober/Projects/sundee-fundee/web-app && npx vitest run src/lib/domain/__tests__/benchmark-catalog.test.ts src/lib/domain/__tests__/celebration-event.test.ts
```

Expected: PASS.

- [ ] **Step 7: Commit**

```bash
cd /Users/dustinober/Projects/sundee-fundee
git add web-app/src/lib/domain/benchmark-catalog.ts web-app/src/lib/domain/celebration-event.ts web-app/src/lib/domain/__tests__/benchmark-catalog.test.ts web-app/src/lib/domain/__tests__/celebration-event.test.ts
git commit -m "feat: port benchmark catalog and celebration events to TypeScript"
```

---

### Task 14: Program Template Generator

**Files:**
- Create: `web-app/src/lib/domain/program-template-generator.ts`
- Create: `web-app/src/lib/domain/__tests__/program-template-generator.test.ts`

- [ ] **Step 1: Write the tests**

```typescript
import { describe, it, expect } from "vitest";
import { generateProgram, ProgramTemplate } from "../program-template-generator";

describe("generateProgram", () => {
  it("generates a basic strength program", () => {
    const program = generateProgram("strength", "My Strength Program");
    expect(program.name).toBe("My Strength Program");
    expect(program.durationWeeks).toBe(4);
    expect(program.sessionsPerWeek).toBe(3);
    expect(program.weeks).toHaveLength(4);
    expect(program.weeks[0].sessions).toHaveLength(3);
  });

  it("generates a hypertrophy program", () => {
    const program = generateProgram("hypertrophy", "Hyp Program");
    expect(program.durationWeeks).toBe(6);
    expect(program.sessionsPerWeek).toBe(4);
  });

  it("generates a linear periodization program", () => {
    const program = generateProgram("linear", "Linear Program");
    expect(program.durationWeeks).toBe(6);
    // Linear: reps decrease, load increases across weeks
    const w1Ex = program.weeks[0].sessions[0].exercises[0];
    const w6Ex = program.weeks[5].sessions[0].exercises[0];
    expect(w1Ex.percent1RM!).toBeLessThan(w6Ex.percent1RM!);
  });

  it("generates a DUP program with 3 session types", () => {
    const program = generateProgram("dup", "DUP Program");
    expect(program.durationWeeks).toBe(4);
    const sessions = program.weeks[0].sessions;
    expect(sessions).toHaveLength(3);
    // DUP has Heavy/Moderate/Volume days
    expect(sessions[0].sessionName).toContain("Heavy");
    expect(sessions[1].sessionName).toContain("Moderate");
    expect(sessions[2].sessionName).toContain("Volume");
  });

  it("generates a block periodization program with 3 phases", () => {
    const program = generateProgram("block", "Block Program");
    expect(program.durationWeeks).toBe(9);
    expect(program.phases).toHaveLength(3);
    expect(program.phases[0].name).toBe("Accumulation");
    expect(program.phases[1].name).toBe("Intensification");
    expect(program.phases[2].name).toBe("Peaking");
  });

  it("respects custom duration and sessions", () => {
    const program = generateProgram("strength", "Custom", 8, 4);
    expect(program.durationWeeks).toBe(8);
    expect(program.sessionsPerWeek).toBe(4);
    expect(program.weeks).toHaveLength(8);
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

```bash
cd /Users/dustinober/Projects/sundee-fundee/web-app && npx vitest run src/lib/domain/__tests__/program-template-generator.test.ts
```

Expected: FAIL.

- [ ] **Step 3: Create `web-app/src/lib/domain/program-template-generator.ts`**

Port the complete generator from `ProgramTemplateGenerator.swift`. This is a large file with exercise templates for each program type.

```typescript
import type { Program, ProgramPhase, ProgramWeek, ProgramSession, ProgramExercise } from "./types";

export type ProgramTemplate = "strength" | "hypertrophy" | "fullBody" | "linear" | "dup" | "block";

interface TemplateDefaults {
  durationWeeks: number;
  sessionsPerWeek: number;
  difficulty: string;
  category: string;
}

const TEMPLATE_DEFAULTS: Record<ProgramTemplate, TemplateDefaults> = {
  strength: { durationWeeks: 4, sessionsPerWeek: 3, difficulty: "Intermediate", category: "Strength" },
  hypertrophy: { durationWeeks: 6, sessionsPerWeek: 4, difficulty: "Intermediate", category: "Hypertrophy" },
  fullBody: { durationWeeks: 4, sessionsPerWeek: 3, difficulty: "Beginner", category: "General" },
  linear: { durationWeeks: 6, sessionsPerWeek: 3, difficulty: "Intermediate", category: "Periodization" },
  dup: { durationWeeks: 4, sessionsPerWeek: 3, difficulty: "Intermediate", category: "Periodization" },
  block: { durationWeeks: 9, sessionsPerWeek: 3, difficulty: "Advanced", category: "Periodization" },
};

export function generateProgram(
  template: ProgramTemplate,
  name: string,
  durationWeeks?: number,
  sessionsPerWeek?: number
): Program {
  const defaults = TEMPLATE_DEFAULTS[template];
  const weeks = durationWeeks ?? defaults.durationWeeks;
  const sessions = sessionsPerWeek ?? defaults.sessionsPerWeek;

  switch (template) {
    case "strength":
      return buildBasicProgram(name, weeks, sessions, defaults, strengthExercises);
    case "hypertrophy":
      return buildBasicProgram(name, weeks, sessions, defaults, hypertrophyExercises);
    case "fullBody":
      return buildBasicProgram(name, weeks, sessions, defaults, fullBodyExercises);
    case "linear":
      return buildLinearProgram(name, weeks, sessions, defaults);
    case "dup":
      return buildDUPProgram(name, weeks, sessions, defaults);
    case "block":
      return buildBlockProgram(name, weeks, sessions, defaults);
  }
}

// ============================================================
// Exercise Templates
// ============================================================

function strengthExercises(dayIndex: number): ProgramExercise[] {
  const focuses = [
    // Day 0: Squat focus
    [
      { exercise: "Back Squat", sets: 4, reps: 5, percent1RM: 0.78 },
      { exercise: "Romanian Deadlift (No Straps)", sets: 3, reps: 8, percent1RM: 0.65 },
      { exercise: "Barbell Row", sets: 3, reps: 8, percent1RM: 0.65 },
    ],
    // Day 1: Bench focus
    [
      { exercise: "Flat Barbell Bench Press", sets: 4, reps: 5, percent1RM: 0.78 },
      { exercise: "Strict Press", sets: 3, reps: 8, percent1RM: 0.65 },
      { exercise: "Pull-Up", sets: 3, reps: 8 },
    ],
    // Day 2: Deadlift focus
    [
      { exercise: "Conventional Deadlift (No Straps)", sets: 4, reps: 5, percent1RM: 0.78 },
      { exercise: "Front Squat", sets: 3, reps: 6, percent1RM: 0.65 },
      { exercise: "Barbell Row", sets: 3, reps: 8, percent1RM: 0.65 },
    ],
    // Day 3: OHP focus
    [
      { exercise: "Strict Press", sets: 4, reps: 5, percent1RM: 0.78 },
      { exercise: "Incline Barbell Bench Press", sets: 3, reps: 8, percent1RM: 0.65 },
      { exercise: "Lat Pulldown", sets: 3, reps: 10 },
    ],
    // Day 4: Squat again
    [
      { exercise: "Back Squat", sets: 4, reps: 5, percent1RM: 0.78 },
      { exercise: "Hip Thrust", sets: 3, reps: 10, percent1RM: 0.60 },
      { exercise: "Cable Row", sets: 3, reps: 10 },
    ],
  ];
  return makeExercises(focuses[dayIndex % focuses.length]);
}

function hypertrophyExercises(dayIndex: number): ProgramExercise[] {
  const focuses = [
    // Upper
    [
      { exercise: "Flat Barbell Bench Press", sets: 4, reps: 10, percent1RM: 0.65 },
      { exercise: "Barbell Row", sets: 4, reps: 10, percent1RM: 0.65 },
      { exercise: "Dumbbell Overhead Press", sets: 3, reps: 12 },
      { exercise: "Lat Pulldown", sets: 3, reps: 12 },
    ],
    // Lower
    [
      { exercise: "Back Squat", sets: 4, reps: 10, percent1RM: 0.65 },
      { exercise: "Romanian Deadlift (No Straps)", sets: 4, reps: 10, percent1RM: 0.60 },
      { exercise: "Hip Thrust", sets: 3, reps: 12, percent1RM: 0.60 },
    ],
    // Push
    [
      { exercise: "Incline Barbell Bench Press", sets: 4, reps: 10, percent1RM: 0.65 },
      { exercise: "Strict Press", sets: 3, reps: 10, percent1RM: 0.65 },
      { exercise: "Dumbbell Bench Press", sets: 3, reps: 12 },
    ],
    // Pull
    [
      { exercise: "Conventional Deadlift (No Straps)", sets: 4, reps: 8, percent1RM: 0.65 },
      { exercise: "Pendlay Row", sets: 4, reps: 10, percent1RM: 0.65 },
      { exercise: "Pull-Up", sets: 3, reps: 10 },
    ],
    // Upper again
    [
      { exercise: "Dumbbell Bench Press", sets: 4, reps: 12 },
      { exercise: "Cable Row", sets: 4, reps: 12 },
      { exercise: "Push Press", sets: 3, reps: 10, percent1RM: 0.60 },
    ],
  ];
  return makeExercises(focuses[dayIndex % focuses.length]);
}

function fullBodyExercises(dayIndex: number): ProgramExercise[] {
  const focuses = [
    [
      { exercise: "Back Squat", sets: 3, reps: 8, percent1RM: 0.65 },
      { exercise: "Flat Barbell Bench Press", sets: 3, reps: 8, percent1RM: 0.65 },
      { exercise: "Barbell Row", sets: 3, reps: 8, percent1RM: 0.65 },
    ],
    [
      { exercise: "Conventional Deadlift (No Straps)", sets: 3, reps: 8, percent1RM: 0.65 },
      { exercise: "Strict Press", sets: 3, reps: 8, percent1RM: 0.65 },
      { exercise: "Pull-Up", sets: 3, reps: 8 },
    ],
    [
      { exercise: "Front Squat", sets: 3, reps: 8, percent1RM: 0.60 },
      { exercise: "Dumbbell Bench Press", sets: 3, reps: 10 },
      { exercise: "Cable Row", sets: 3, reps: 10 },
    ],
  ];
  return makeExercises(focuses[dayIndex % focuses.length]);
}

function makeExercises(templates: { exercise: string; sets: number; reps: number; percent1RM?: number }[]): ProgramExercise[] {
  return templates.map((t) => ({
    exercise: t.exercise,
    sets: { type: "fixed" as const, value: t.sets },
    reps: { type: "fixed" as const, value: t.reps },
    percent1RM: t.percent1RM,
    restMinutes: t.reps <= 5 ? 2.5 : t.reps <= 8 ? 2.0 : 1.5,
  }));
}

// ============================================================
// Basic program builder (repeated week structure)
// ============================================================

function buildBasicProgram(
  name: string,
  durationWeeks: number,
  sessionsPerWeek: number,
  defaults: TemplateDefaults,
  exerciseFn: (dayIndex: number) => ProgramExercise[]
): Program {
  const focusLabels = ["Day A", "Day B", "Day C", "Day D", "Day E"];
  const weeks: ProgramWeek[] = [];

  for (let w = 1; w <= durationWeeks; w++) {
    const sessions: ProgramSession[] = [];
    for (let d = 0; d < sessionsPerWeek; d++) {
      sessions.push({
        sessionId: `w${w}d${d + 1}`,
        sessionName: focusLabels[d % focusLabels.length],
        sessionType: defaults.category.toLowerCase(),
        focus: defaults.category.toLowerCase(),
        exercises: exerciseFn(d),
      });
    }
    weeks.push({ week: w, sessions });
  }

  return {
    id: crypto.randomUUID(),
    name,
    category: defaults.category,
    description: `${defaults.category} program — ${durationWeeks} weeks, ${sessionsPerWeek}x/week`,
    durationWeeks,
    sessionsPerWeek,
    difficulty: defaults.difficulty,
    phases: [],
    weeks,
  };
}

// ============================================================
// Linear Periodization — progressive overload
// ============================================================

function buildLinearProgram(
  name: string,
  durationWeeks: number,
  sessionsPerWeek: number,
  defaults: TemplateDefaults
): Program {
  const weeks: ProgramWeek[] = [];
  const coreExercises = ["Back Squat", "Flat Barbell Bench Press", "Conventional Deadlift (No Straps)"];

  for (let w = 1; w <= durationWeeks; w++) {
    const progression = (w - 1) / (durationWeeks - 1); // 0.0 to 1.0
    const reps = Math.round(10 - progression * 7); // 10 down to 3
    const load = 0.60 + progression * 0.28; // 60% up to 88%

    const sessions: ProgramSession[] = [];
    for (let d = 0; d < sessionsPerWeek; d++) {
      const mainExercise = coreExercises[d % coreExercises.length];
      sessions.push({
        sessionId: `w${w}d${d + 1}`,
        sessionName: `Week ${w} - ${mainExercise.split(" ")[0]}`,
        sessionType: "strength",
        focus: "compound",
        exercises: [
          {
            exercise: mainExercise,
            sets: { type: "fixed", value: 4 },
            reps: { type: "fixed", value: reps },
            percent1RM: Math.round(load * 100) / 100,
            restMinutes: reps <= 5 ? 2.5 : 2.0,
          },
          {
            exercise: "Barbell Row",
            sets: { type: "fixed", value: 3 },
            reps: { type: "fixed", value: Math.min(reps + 3, 12) },
            percent1RM: Math.round((load - 0.10) * 100) / 100,
            restMinutes: 1.5,
          },
        ],
      });
    }
    weeks.push({ week: w, sessions });
  }

  return {
    id: crypto.randomUUID(),
    name,
    category: defaults.category,
    description: `Linear periodization — ${durationWeeks} weeks, progressive overload`,
    durationWeeks,
    sessionsPerWeek,
    difficulty: defaults.difficulty,
    phases: [],
    weeks,
  };
}

// ============================================================
// Daily Undulating Periodization
// ============================================================

function buildDUPProgram(
  name: string,
  durationWeeks: number,
  sessionsPerWeek: number,
  defaults: TemplateDefaults
): Program {
  const dayConfigs = [
    { label: "Heavy", sets: 5, reps: 3, load: 0.85, rest: 3.0 },
    { label: "Moderate", sets: 4, reps: 6, load: 0.72, rest: 2.0 },
    { label: "Volume", sets: 3, reps: 12, load: 0.60, rest: 1.5 },
  ];
  const coreExercises = ["Back Squat", "Flat Barbell Bench Press", "Conventional Deadlift (No Straps)"];

  const weeks: ProgramWeek[] = [];
  for (let w = 1; w <= durationWeeks; w++) {
    const sessions: ProgramSession[] = [];
    for (let d = 0; d < Math.min(sessionsPerWeek, 3); d++) {
      const config = dayConfigs[d];
      sessions.push({
        sessionId: `w${w}d${d + 1}`,
        sessionName: `${config.label} Day`,
        sessionType: "strength",
        focus: "full body",
        exercises: coreExercises.map((ex) => ({
          exercise: ex,
          sets: { type: "fixed" as const, value: config.sets },
          reps: { type: "fixed" as const, value: config.reps },
          percent1RM: config.load,
          restMinutes: config.rest,
        })),
      });
    }
    weeks.push({ week: w, sessions });
  }

  return {
    id: crypto.randomUUID(),
    name,
    category: defaults.category,
    description: `DUP — ${durationWeeks} weeks, Heavy/Moderate/Volume rotation`,
    durationWeeks,
    sessionsPerWeek,
    difficulty: defaults.difficulty,
    phases: [],
    weeks,
  };
}

// ============================================================
// Block Periodization (3 phases x 3 weeks)
// ============================================================

function buildBlockProgram(
  name: string,
  durationWeeks: number,
  sessionsPerWeek: number,
  defaults: TemplateDefaults
): Program {
  const phaseConfigs = [
    { name: "Accumulation", goal: "Volume and muscle endurance", reps: 10, startLoad: 0.60, loadInc: 0.03, sets: 4, rest: 1.5 },
    { name: "Intensification", goal: "Strength development", reps: 5, startLoad: 0.75, loadInc: 0.03, sets: 4, rest: 2.5 },
    { name: "Peaking", goal: "Peak strength expression", reps: 2, startLoad: 0.85, loadInc: 0.03, sets: 5, rest: 3.0 },
  ];

  const coreExercises = ["Back Squat", "Flat Barbell Bench Press", "Conventional Deadlift (No Straps)"];
  const weeksPerPhase = Math.floor(durationWeeks / 3);
  const phases: ProgramPhase[] = [];
  const weeks: ProgramWeek[] = [];

  for (let p = 0; p < 3; p++) {
    const config = phaseConfigs[p];
    const startWeek = p * weeksPerPhase + 1;
    const endWeek = startWeek + weeksPerPhase - 1;

    phases.push({
      id: `phase-${p + 1}`,
      name: config.name,
      goal: config.goal,
      weekRange: [startWeek, endWeek],
    });

    for (let w = 0; w < weeksPerPhase; w++) {
      const weekNum = startWeek + w;
      const load = Math.round((config.startLoad + w * config.loadInc) * 100) / 100;

      const sessions: ProgramSession[] = [];
      for (let d = 0; d < sessionsPerWeek; d++) {
        sessions.push({
          sessionId: `w${weekNum}d${d + 1}`,
          sessionName: `${config.name} W${w + 1}`,
          sessionType: "strength",
          focus: config.goal.toLowerCase(),
          exercises: coreExercises.map((ex) => ({
            exercise: ex,
            sets: { type: "fixed" as const, value: config.sets },
            reps: { type: "fixed" as const, value: config.reps },
            percent1RM: load,
            restMinutes: config.rest,
          })),
        });
      }
      weeks.push({ week: weekNum, phaseId: `phase-${p + 1}`, sessions });
    }
  }

  return {
    id: crypto.randomUUID(),
    name,
    category: defaults.category,
    description: `Block periodization — ${durationWeeks} weeks: Accumulation → Intensification → Peaking`,
    durationWeeks,
    sessionsPerWeek,
    difficulty: defaults.difficulty,
    phases,
    weeks,
  };
}
```

- [ ] **Step 4: Run test to verify it passes**

```bash
cd /Users/dustinober/Projects/sundee-fundee/web-app && npx vitest run src/lib/domain/__tests__/program-template-generator.test.ts
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
cd /Users/dustinober/Projects/sundee-fundee
git add web-app/src/lib/domain/program-template-generator.ts web-app/src/lib/domain/__tests__/program-template-generator.test.ts
git commit -m "feat: port program template generator (6 templates with periodization)"
```

---

### Task 15: AI Workout Types + Offline Generator + Post-Processor

**Files:**
- Create: `web-app/src/lib/domain/ai-workout.ts`
- Create: `web-app/src/lib/domain/__tests__/ai-workout.test.ts`

- [ ] **Step 1: Write the tests**

```typescript
import { describe, it, expect } from "vitest";
import {
  extractMuscleGroups,
  totalEstimatedMinutes,
  defaultPercentage,
  assignRestMinutes,
  type GeneratedExercise,
  type GeneratedWorkout,
} from "../ai-workout";

describe("extractMuscleGroups", () => {
  it("extracts quads from squat", () => {
    const groups = extractMuscleGroups([{ name: "Back Squat" } as GeneratedExercise]);
    expect(groups).toContain("Quads");
  });
  it("extracts glutes from deadlift", () => {
    const groups = extractMuscleGroups([{ name: "Deadlift" } as GeneratedExercise]);
    expect(groups).toContain("Glutes");
  });
});

describe("totalEstimatedMinutes", () => {
  it("calculates from exercises", () => {
    const exercises: GeneratedExercise[] = [
      { id: "1", name: "Squat", sets: 4, reps: "5", restMinutes: 2.5, bodyweightOnly: false },
      { id: "2", name: "Bench", sets: 3, reps: "8", restMinutes: 2.0, bodyweightOnly: false },
    ];
    // 4 sets * 2.5 rest + 3 sets * 2.0 rest + setup time
    const minutes = totalEstimatedMinutes(exercises);
    expect(minutes).toBeGreaterThan(0);
  });
});

describe("defaultPercentage", () => {
  it("85% for 1-3 reps", () => expect(defaultPercentage(3)).toBe(0.85));
  it("80% for 4-5 reps", () => expect(defaultPercentage(5)).toBe(0.80));
  it("70% for 6-8 reps", () => expect(defaultPercentage(8)).toBe(0.70));
  it("65% for 9-12 reps", () => expect(defaultPercentage(12)).toBe(0.65));
  it("60% for 13+ reps", () => expect(defaultPercentage(15)).toBe(0.60));
});

describe("assignRestMinutes", () => {
  it("1.0 for bodyweight", () => expect(assignRestMinutes(true, 10)).toBe(1.0));
  it("2.5 for heavy (1-5 reps)", () => expect(assignRestMinutes(false, 5)).toBe(2.5));
  it("2.0 for 6-8 reps", () => expect(assignRestMinutes(false, 8)).toBe(2.0));
  it("1.5 for 9-12 reps", () => expect(assignRestMinutes(false, 10)).toBe(1.5));
  it("1.0 for 13+ reps", () => expect(assignRestMinutes(false, 15)).toBe(1.0));
});
```

- [ ] **Step 2: Run test to verify it fails**

```bash
cd /Users/dustinober/Projects/sundee-fundee/web-app && npx vitest run src/lib/domain/__tests__/ai-workout.test.ts
```

Expected: FAIL.

- [ ] **Step 3: Create `web-app/src/lib/domain/ai-workout.ts`**

```typescript
import { roundToNearestFive } from "./weight-calculations";

// ============================================================
// Types — from GeneratedWorkout.swift + WorkoutGenerationContext.swift
// ============================================================

export type WorkoutFocus = "upperBody" | "lowerBody" | "fullBody" | "push" | "pull" | "core" | "conditioning";
export type EnergyLevel = "low" | "medium" | "high";
export type EquipmentAccess = "fullGym" | "homeDumbbells" | "bodyweightOnly" | "outdoor";

export interface QuestionnaireAnswers {
  timeMinutes: number;
  focus: WorkoutFocus;
  energyLevel: EnergyLevel;
  equipment: EquipmentAccess;
}

export interface GeneratedExercise {
  id: string;
  name: string;
  sets: number;
  reps: string; // "5", "8-10", "AMRAP"
  weightKg?: number;
  restMinutes?: number;
  notes?: string;
  reasoning?: string;
  bodyweightOnly: boolean;
}

export interface GeneratedWorkout {
  id: string;
  createdAt: string;
  isFavorite: boolean;
  coachingSummary: string;
  exercises: GeneratedExercise[];
  questionnaire: QuestionnaireAnswers;
}

// ============================================================
// Muscle Group Extraction — from GeneratedWorkout.swift
// ============================================================

const MUSCLE_KEYWORDS: Record<string, string[]> = {
  Quads: ["squat", "lunge", "leg press", "leg extension"],
  Glutes: ["deadlift", "hip thrust", "glute", "lunge"],
  Hamstrings: ["deadlift", "curl", "good morning", "romanian"],
  Chest: ["bench", "push-up", "pushup", "chest", "fly"],
  Back: ["row", "pull-up", "pullup", "lat", "chin-up"],
  Shoulders: ["press", "raise", "shoulder", "delt"],
  Arms: ["curl", "tricep", "bicep", "extension"],
  Core: ["plank", "crunch", "sit-up", "ab", "core"],
};

export function extractMuscleGroups(exercises: Pick<GeneratedExercise, "name">[]): string[] {
  const groups = new Set<string>();
  for (const ex of exercises) {
    const name = ex.name.toLowerCase();
    for (const [group, keywords] of Object.entries(MUSCLE_KEYWORDS)) {
      if (keywords.some((kw) => name.includes(kw))) {
        groups.add(group);
      }
    }
  }
  return Array.from(groups);
}

// ============================================================
// Post-Processing — from WorkoutPostProcessor.swift
// ============================================================

export function defaultPercentage(reps: number): number {
  if (reps <= 3) return 0.85;
  if (reps <= 5) return 0.80;
  if (reps <= 8) return 0.70;
  if (reps <= 12) return 0.65;
  return 0.60;
}

export function assignRestMinutes(bodyweight: boolean, reps: number): number {
  if (bodyweight) return 1.0;
  if (reps <= 5) return 2.5;
  if (reps <= 8) return 2.0;
  if (reps <= 12) return 1.5;
  return 1.0;
}

export function totalEstimatedMinutes(exercises: GeneratedExercise[]): number {
  let total = 0;
  for (const ex of exercises) {
    const rest = ex.restMinutes ?? 1.5;
    const repTime = 0.5; // ~30 seconds per set of actual lifting
    total += ex.sets * (rest + repTime);
  }
  return Math.round(total);
}

/** Apply weight calculations from user's maxes to AI-generated exercises */
export function applyWeights(
  exercises: GeneratedExercise[],
  maxes: Map<string, number>, // exercise name → 1RM in kg
  energyMultiplier: number,
  cycleMultiplier: number
): GeneratedExercise[] {
  return exercises.map((ex) => {
    if (ex.bodyweightOnly || ex.weightKg != null) return ex;

    // Fuzzy match exercise name to maxes
    const matchedMax = findMaxForExercise(ex.name, maxes);
    if (matchedMax == null) return ex;

    const reps = parseReps(ex.reps);
    if (reps === 0) return ex; // AMRAP, no weight calc

    const pct = defaultPercentage(reps);
    const rawWeight = matchedMax * pct * energyMultiplier * cycleMultiplier;
    const weight = roundToNearestFive(rawWeight);

    return { ...ex, weightKg: weight };
  });
}

function findMaxForExercise(name: string, maxes: Map<string, number>): number | undefined {
  // Exact match first
  if (maxes.has(name)) return maxes.get(name);

  // Fuzzy: check if exercise name contains any max key
  const lower = name.toLowerCase();
  for (const [key, value] of maxes) {
    if (lower.includes(key.toLowerCase()) || key.toLowerCase().includes(lower)) {
      return value;
    }
  }
  return undefined;
}

function parseReps(reps: string): number {
  if (reps.toUpperCase() === "AMRAP") return 0;
  // Handle ranges like "8-10" — take the lower bound
  if (reps.includes("-")) {
    const parts = reps.split("-");
    return parseInt(parts[0], 10) || 0;
  }
  return parseInt(reps, 10) || 0;
}

/** Energy level multipliers */
export function energyMultiplier(level: EnergyLevel): number {
  switch (level) {
    case "low": return 0.85;
    case "medium": return 1.0;
    case "high": return 1.05;
  }
}

/** Cycle phase multipliers for AI workouts */
export function cyclePhaseMultiplier(phase: string | undefined): number {
  switch (phase) {
    case "menstrual": return 0.90;
    case "follicular": return 1.0;
    case "ovulation": return 1.12;
    case "luteal": return 0.97;
    default: return 1.0;
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

```bash
cd /Users/dustinober/Projects/sundee-fundee/web-app && npx vitest run src/lib/domain/__tests__/ai-workout.test.ts
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
cd /Users/dustinober/Projects/sundee-fundee
git add web-app/src/lib/domain/ai-workout.ts web-app/src/lib/domain/__tests__/ai-workout.test.ts
git commit -m "feat: port AI workout types, muscle extraction, and post-processor"
```

---

### Task 16: Barrel Export + Final Coverage Check

**Files:**
- Create: `web-app/src/lib/domain/index.ts`

- [ ] **Step 1: Create `web-app/src/lib/domain/index.ts`**

```typescript
// Shared types
export * from "./types";

// Weight
export * from "./weight-calculations";
export * from "./weight-unit-conversion";
export * from "./plate-calculation";

// Exercise catalogs
export * from "./exercise-catalog";

// Body & Recovery
export * from "./body-location";

// Subscription
export * from "./subscription";

// Cycle
export * from "./cycle-calculations";
export * from "./cycle-adaptation-policy";

// Injury
export * from "./injury-support";
export * from "./injury-adaptation-engine";

// Benchmarks
export * from "./benchmark-catalog";

// Celebration
export * from "./celebration-event";

// Programs
export * from "./program-template-generator";

// AI Workout
export * from "./ai-workout";
```

- [ ] **Step 2: Run all tests with coverage**

```bash
cd /Users/dustinober/Projects/sundee-fundee/web-app && npx vitest run --coverage
```

Expected: All tests pass. Coverage report generated for `src/lib/domain/`.

- [ ] **Step 3: Fix any coverage gaps**

Review the coverage report. If any lines are uncovered, add targeted tests. The goal is 100% line coverage for all domain files.

- [ ] **Step 4: Commit**

```bash
cd /Users/dustinober/Projects/sundee-fundee
git add web-app/src/lib/domain/index.ts
git commit -m "feat: add barrel export and complete Phase 2 domain logic port"
```
