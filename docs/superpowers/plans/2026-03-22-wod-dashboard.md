# WOD Dashboard Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a local-only Next.js admin dashboard for creating, editing, and publishing WODs and Programs for the Sundee Fundee iOS app, with AI generation via Cloudflare worker and CloudKit publishing.

**Architecture:** Next.js App Router with API routes that read/write bundled JSON files on disk, proxy AI generation to a Cloudflare worker, and publish to CloudKit Public DB via CloudKit JS SDK with Apple ID auth. Sidebar navigation with four sections: WODs, Programs, Exercise Catalog, Settings.

**Tech Stack:** Next.js 15 (App Router), TypeScript, Tailwind CSS 3, `@dnd-kit/core` + `@dnd-kit/sortable` (drag-and-drop), CloudKit JS SDK

**Spec:** `docs/superpowers/specs/2026-03-22-wod-dashboard-design.md`

---

## File Structure

```
wod-dashboard/
├── .env.local                          # CloudKit + worker config (exists)
├── next.config.ts                      # Next.js config
├── tailwind.config.ts                  # Tailwind with Art Deco theme
├── tsconfig.json
├── package.json
├── src/
│   ├── app/
│   │   ├── layout.tsx                  # Root layout with sidebar
│   │   ├── page.tsx                    # Redirect to /wods
│   │   ├── globals.css                 # Tailwind imports + Art Deco tokens
│   │   ├── wods/
│   │   │   └── page.tsx               # WOD list + editor + generator
│   │   ├── programs/
│   │   │   └── page.tsx               # Program list + editor + generator
│   │   ├── catalog/
│   │   │   └── page.tsx               # Exercise catalog reference
│   │   └── settings/
│   │       └── page.tsx               # Config settings
│   │   ├── api/
│   │   │   ├── wods/
│   │   │   │   └── route.ts           # GET, PUT, PATCH, DELETE for wods.json
│   │   │   ├── programs/
│   │   │   │   └── route.ts           # GET, PUT, PATCH, DELETE for programs.json
│   │   │   ├── generate/
│   │   │   │   ├── wod/route.ts       # POST proxy to Cloudflare worker
│   │   │   │   └── program/route.ts   # POST proxy to Cloudflare worker
│   │   │   └── cloudkit/
│   │   │       └── publish/route.ts   # POST publish, DELETE unpublish
│   ├── lib/
│   │   ├── types.ts                   # TypeScript types mirroring Swift models
│   │   ├── validation.ts              # WOD + Program validators
│   │   ├── exercise-catalog.ts        # Weightlifting + conditioning catalogs
│   │   ├── file-io.ts                 # JSON file read/write with backup + mutex
│   │   ├── paths.ts                   # Resolve paths to bundled JSON files
│   │   └── cloudkit.ts                # CloudKit JS SDK wrapper
│   └── components/
│       ├── sidebar.tsx                # Sidebar navigation
│       ├── toast.tsx                  # Toast notification system
│       ├── exercise-autocomplete.tsx  # Exercise name autocomplete input
│       ├── exercise-row.tsx           # Single exercise inline editor row
│       ├── wod-list.tsx               # WOD table with filters
│       ├── wod-editor.tsx             # WOD create/edit form
│       ├── wod-generator.tsx          # WOD AI generation form
│       ├── program-list.tsx           # Program table
│       ├── program-editor.tsx         # Program create/edit form (header + phases + weeks)
│       ├── program-generator.tsx      # Program AI generation form
│       ├── week-editor.tsx            # Single week accordion with sessions
│       ├── session-editor.tsx         # Single session with exercise list
│       └── cycle-adjustment-editor.tsx # Cycle adjustment profile form
└── __tests__/
    ├── validation.test.ts             # Validator unit tests
    ├── types.test.ts                  # ExerciseValue encoding/decoding tests
    ├── file-io.test.ts                # File I/O unit tests
    └── exercise-catalog.test.ts       # Catalog data tests
```

---

## Task 1: Project Scaffold

**Files:**
- Create: `wod-dashboard/package.json`
- Create: `wod-dashboard/next.config.ts`
- Create: `wod-dashboard/tsconfig.json`
- Create: `wod-dashboard/tailwind.config.ts`
- Create: `wod-dashboard/src/app/globals.css`
- Create: `wod-dashboard/src/app/layout.tsx`
- Create: `wod-dashboard/src/app/page.tsx`
- Modify: `wod-dashboard/.env.local` (add container ID)

- [ ] **Step 1: Initialize Next.js project**

```bash
cd wod-dashboard
npx create-next-app@latest . --typescript --tailwind --eslint --app --src-dir --no-import-alias --yes
```

This overwrites the existing stub files. Accept defaults. **Important:** If `create-next-app` installs Tailwind CSS 4, downgrade to v3: `npm install tailwindcss@3 postcss autoprefixer`. Tailwind 4 uses CSS-based config, not `tailwind.config.ts`.

- [ ] **Step 1b: Install test and drag-and-drop dependencies**

```bash
cd wod-dashboard && npm install -D jest ts-jest @types/jest
cd wod-dashboard && npm install @dnd-kit/core @dnd-kit/sortable @dnd-kit/utilities
npx ts-jest config:init
```

- [ ] **Step 2: Update `.env.local` with full config**

Add the missing container ID and worker URL:

```env
NEXT_PUBLIC_CLOUDKIT_CONTAINER=iCloud.com.sundeefundee.app
NEXT_PUBLIC_CLOUDKIT_API_TOKEN=7184ec917a629c0e2972460ee915e0540b5d840156b1341b1b2046adecabca10
NEXT_PUBLIC_CLOUDKIT_ENV=production
CLOUDFLARE_WORKER_URL=https://workout-proxy.sundeefundee.workers.dev/generate-workout
```

- [ ] **Step 3: Configure Tailwind with Art Deco theme**

Update `tailwind.config.ts`:

```typescript
import type { Config } from "tailwindcss";

const config: Config = {
  content: ["./src/**/*.{ts,tsx}"],
  theme: {
    extend: {
      colors: {
        cream: "#F4F0DF",
        navy: "#0D1A40",
        orange: "#F2731A",
      },
    },
  },
  plugins: [],
};
export default config;
```

- [ ] **Step 4: Set up globals.css**

```css
@tailwind base;
@tailwind components;
@tailwind utilities;

body {
  @apply bg-cream text-navy;
}
```

- [ ] **Step 5: Create root layout with placeholder sidebar**

`src/app/layout.tsx`:

```tsx
import "./globals.css";

export const metadata = { title: "Sundee Fundee Dashboard" };

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body className="flex h-screen">
        <nav className="w-60 bg-navy text-cream p-4 flex flex-col gap-2">
          <h1 className="text-xl font-bold mb-6">Sundee Fundee</h1>
          <a href="/wods" className="hover:text-orange">WODs</a>
          <a href="/programs" className="hover:text-orange">Programs</a>
          <a href="/catalog" className="hover:text-orange">Exercise Catalog</a>
          <a href="/settings" className="hover:text-orange">Settings</a>
        </nav>
        <main className="flex-1 overflow-auto p-6">{children}</main>
      </body>
    </html>
  );
}
```

- [ ] **Step 6: Create redirect page**

`src/app/page.tsx`:

```tsx
import { redirect } from "next/navigation";
export default function Home() { redirect("/wods"); }
```

- [ ] **Step 7: Create placeholder pages**

Create `src/app/wods/page.tsx`, `src/app/programs/page.tsx`, `src/app/catalog/page.tsx`, `src/app/settings/page.tsx` — each with a simple heading:

```tsx
export default function WodsPage() {
  return <h1 className="text-2xl font-bold">WODs</h1>;
}
```

- [ ] **Step 8: Verify dev server runs**

```bash
cd wod-dashboard && npm run dev
```

Open `http://localhost:3000`. Verify: cream background, navy sidebar, four nav links, redirects to /wods.

- [ ] **Step 9: Commit**

```bash
git add wod-dashboard/
git commit -m "feat(wod-dashboard): scaffold Next.js project with Art Deco theme"
```

---

## Task 2: TypeScript Types & ExerciseValue Encoding

**Files:**
- Create: `wod-dashboard/src/lib/types.ts`
- Create: `wod-dashboard/__tests__/types.test.ts`

- [ ] **Step 1: Write failing tests for ExerciseValue encoding/decoding**

`__tests__/types.test.ts`:

```typescript
import { encodeExerciseValue, decodeExerciseValue, ExerciseValue } from "../src/lib/types";

describe("ExerciseValue", () => {
  test("fixed int round-trips", () => {
    const val: ExerciseValue = { type: "fixed", value: 4 };
    expect(encodeExerciseValue(val)).toBe(4);
    expect(decodeExerciseValue(4)).toEqual(val);
  });

  test("AMRAP round-trips", () => {
    const val: ExerciseValue = { type: "amrap" };
    expect(encodeExerciseValue(val)).toBe("AMRAP");
    expect(decodeExerciseValue("AMRAP")).toEqual(val);
  });

  test("range round-trips", () => {
    const val: ExerciseValue = { type: "range", low: 8, high: 12 };
    expect(encodeExerciseValue(val)).toEqual([8, 12]);
    expect(decodeExerciseValue([8, 12])).toEqual(val);
  });

  test("text round-trips", () => {
    const val: ExerciseValue = { type: "text", text: "60s" };
    expect(encodeExerciseValue(val)).toBe("60s");
    expect(decodeExerciseValue("60s")).toEqual(val);
  });

  test("decodes double as fixed int", () => {
    expect(decodeExerciseValue(4.7)).toEqual({ type: "fixed", value: 4 });
  });

  test("decodes string integer as fixed", () => {
    expect(decodeExerciseValue("4")).toEqual({ type: "fixed", value: 4 });
  });

  test("decodes hyphenated range string", () => {
    expect(decodeExerciseValue("8-12")).toEqual({ type: "range", low: 8, high: 12 });
  });
});
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
cd wod-dashboard && npx jest __tests__/types.test.ts
```

Expected: FAIL — `types` module not found (Jest was installed in Task 1).

- [ ] **Step 3: Implement types.ts**

`src/lib/types.ts`:

```typescript
// --- ExerciseValue ---

export type ExerciseValue =
  | { type: "fixed"; value: number }
  | { type: "amrap" }
  | { type: "range"; low: number; high: number }
  | { type: "text"; text: string };

export function encodeExerciseValue(ev: ExerciseValue): number | string | number[] {
  switch (ev.type) {
    case "fixed": return ev.value;
    case "amrap": return "AMRAP";
    case "range": return [ev.low, ev.high];
    case "text": return ev.text;
  }
}

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
    const asInt = parseInt(trimmed, 10);
    if (!isNaN(asInt) && String(asInt) === trimmed) return { type: "fixed", value: asInt };
    return { type: "text", text: raw };
  }
  return { type: "fixed", value: 0 };
}

// --- Domain Types ---

export interface ProgramExercise {
  exercise: string;
  variant: string | null;
  sets: ExerciseValue;
  reps: ExerciseValue;
  percent1RM: number | null;
  restMinutes: number | null;
  notes: string | null;
  bodyweightOnly?: boolean | null;
}

export interface WOD {
  id: string;
  date: string;
  title: string;
  description: string;
  exercises: ProgramExercise[];
}

export interface ProgramPhase {
  id: string;
  name: string;
  goal: string;
  weekRange: number[];
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
  phaseId: string | null;
  isTestWeek: boolean | null;
  sessions: ProgramSession[];
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
  cycleAdjustmentProfile: ProgramCycleAdjustmentProfile | null;
}

// --- JSON serialization helpers ---
// ProgramExercise needs custom serialization because sets/reps are ExerciseValue

export interface ProgramExerciseJSON {
  exercise: string;
  variant: string | null;
  sets: number | string | number[];
  reps: number | string | number[];
  percent1RM: number | null;
  restMinutes: number | null;
  notes: string | null;
  bodyweightOnly?: boolean | null;
}

export function exerciseToJSON(ex: ProgramExercise): ProgramExerciseJSON {
  return {
    exercise: ex.exercise,
    variant: ex.variant,
    sets: encodeExerciseValue(ex.sets),
    reps: encodeExerciseValue(ex.reps),
    percent1RM: ex.percent1RM,
    restMinutes: ex.restMinutes,
    notes: ex.notes,
    bodyweightOnly: ex.bodyweightOnly,
  };
}

export function exerciseFromJSON(raw: ProgramExerciseJSON): ProgramExercise {
  return {
    exercise: raw.exercise,
    variant: raw.variant,
    sets: decodeExerciseValue(raw.sets),
    reps: decodeExerciseValue(raw.reps),
    percent1RM: raw.percent1RM,
    restMinutes: raw.restMinutes,
    notes: raw.notes,
    bodyweightOnly: raw.bodyweightOnly,
  };
}
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
cd wod-dashboard && npx jest __tests__/types.test.ts
```

Expected: All 7 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add wod-dashboard/src/lib/types.ts wod-dashboard/__tests__/types.test.ts
git commit -m "feat(wod-dashboard): add TypeScript types and ExerciseValue encoding"
```

---

## Task 3: Validation

**Files:**
- Create: `wod-dashboard/src/lib/validation.ts`
- Create: `wod-dashboard/__tests__/validation.test.ts`

- [ ] **Step 1: Write failing tests for WOD validation**

`__tests__/validation.test.ts`:

```typescript
import { validateWOD, validateProgram, ValidationError } from "../src/lib/validation";
import { WOD, Program } from "../src/lib/types";

const validWOD: WOD = {
  id: "wod-2026-03-22",
  date: "2026-03-22",
  title: "Test WOD",
  description: "A test workout",
  exercises: [{ exercise: "Back Squat", variant: null, sets: { type: "fixed", value: 3 }, reps: { type: "fixed", value: 8 }, percent1RM: 0.65, restMinutes: 3, notes: null, bodyweightOnly: false }],
};

describe("validateWOD", () => {
  test("valid WOD returns no errors", () => {
    expect(validateWOD(validWOD)).toEqual([]);
  });

  test("empty title returns error", () => {
    const errors = validateWOD({ ...validWOD, title: "  " });
    expect(errors).toContainEqual(expect.objectContaining({ field: "title" }));
  });

  test("bad date format returns error", () => {
    const errors = validateWOD({ ...validWOD, date: "03-22-2026" });
    expect(errors).toContainEqual(expect.objectContaining({ field: "date" }));
  });

  test("empty exercises returns error", () => {
    const errors = validateWOD({ ...validWOD, exercises: [] });
    expect(errors).toContainEqual(expect.objectContaining({ field: "exercises" }));
  });

  test("empty exercise name returns error", () => {
    const wod = { ...validWOD, exercises: [{ ...validWOD.exercises[0], exercise: "" }] };
    expect(validateWOD(wod)).toContainEqual(expect.objectContaining({ field: "exercises[0]" }));
  });
});

const validProgram: Program = {
  id: "test-program",
  name: "Test Program",
  category: "Squat Focus",
  description: "A test program",
  durationWeeks: 1,
  sessionsPerWeek: 1,
  difficulty: "Beginner",
  phases: [{ id: "phase-1", name: "Phase 1", goal: "Build base", weekRange: [1, 1] }],
  weeks: [{
    week: 1, phaseId: "phase-1", isTestWeek: false,
    sessions: [{
      sessionId: "s1", sessionName: "Session A", sessionType: "Lift", focus: "Main",
      exercises: [{ exercise: "Back Squat", variant: null, sets: { type: "fixed", value: 3 }, reps: { type: "fixed", value: 5 }, percent1RM: 0.7, restMinutes: 3, notes: null }],
    }],
  }],
  cycleAdjustmentProfile: null,
};

describe("validateProgram", () => {
  test("valid program returns no errors", () => {
    expect(validateProgram(validProgram)).toEqual([]);
  });

  test("bad slug returns error", () => {
    const errors = validateProgram({ ...validProgram, id: "Bad Slug!" });
    expect(errors).toContainEqual(expect.objectContaining({ field: "id" }));
  });

  test("duration mismatch returns error", () => {
    const errors = validateProgram({ ...validProgram, durationWeeks: 5 });
    expect(errors).toContainEqual(expect.objectContaining({ field: "durationWeeks" }));
  });

  test("unknown phaseId returns error", () => {
    const prog = { ...validProgram, weeks: [{ ...validProgram.weeks[0], phaseId: "unknown" }] };
    expect(validateProgram(prog).length).toBeGreaterThan(0);
  });

  test("percent1RM out of range returns error", () => {
    const prog = {
      ...validProgram,
      weeks: [{
        ...validProgram.weeks[0],
        sessions: [{
          ...validProgram.weeks[0].sessions[0],
          exercises: [{ ...validProgram.weeks[0].sessions[0].exercises[0], percent1RM: 2.0 }],
        }],
      }],
    };
    expect(validateProgram(prog).length).toBeGreaterThan(0);
  });
});
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
cd wod-dashboard && npx jest __tests__/validation.test.ts
```

Expected: FAIL — module not found.

- [ ] **Step 3: Implement validation.ts**

`src/lib/validation.ts`:

```typescript
import { WOD, Program } from "./types";

export interface ValidationError {
  field: string;
  message: string;
}

export function validateWOD(wod: WOD): ValidationError[] {
  const errors: ValidationError[] = [];
  if (!wod.id.trim()) errors.push({ field: "id", message: "ID is required" });
  if (!wod.title.trim()) errors.push({ field: "title", message: "Title is required" });
  if (!wod.date.trim()) {
    errors.push({ field: "date", message: "Date is required" });
  } else if (!/^\d{4}-\d{2}-\d{2}$/.test(wod.date)) {
    errors.push({ field: "date", message: "Date must be yyyy-MM-dd format" });
  }
  if (wod.exercises.length === 0) {
    errors.push({ field: "exercises", message: "At least one exercise is required" });
  }
  wod.exercises.forEach((ex, i) => {
    if (!ex.exercise.trim()) {
      errors.push({ field: `exercises[${i}]`, message: "Exercise name is empty" });
    }
  });
  return errors;
}

export function validateProgram(program: Program): ValidationError[] {
  const errors: ValidationError[] = [];
  if (!program.name.trim()) errors.push({ field: "name", message: "Name is required" });
  if (!program.id.trim()) {
    errors.push({ field: "id", message: "ID is required" });
  } else if (!/^[a-z0-9]+(-[a-z0-9]+)*$/.test(program.id)) {
    errors.push({ field: "id", message: "ID must be a valid slug (lowercase, hyphens only)" });
  }
  if (program.durationWeeks !== program.weeks.length) {
    errors.push({ field: "durationWeeks", message: `Duration (${program.durationWeeks}) doesn't match week count (${program.weeks.length})` });
  }
  const phaseIDs = new Set(program.phases.map((p) => p.id));
  program.weeks.forEach((week, i) => {
    if (week.sessions.length === 0) {
      errors.push({ field: `weeks[${i}]`, message: `Week ${week.week} has no sessions` });
    }
    if (week.phaseId && !phaseIDs.has(week.phaseId)) {
      errors.push({ field: `weeks[${i}].phaseId`, message: `Week ${week.week} references unknown phase '${week.phaseId}'` });
    }
    week.sessions.forEach((session, j) => {
      if (session.exercises.length === 0) {
        errors.push({ field: `weeks[${i}].sessions[${j}]`, message: `Session '${session.sessionName}' has no exercises` });
      }
      session.exercises.forEach((ex, k) => {
        if (!ex.exercise.trim()) {
          errors.push({ field: `weeks[${i}].sessions[${j}].exercises[${k}]`, message: "Exercise name is empty" });
        }
        if (ex.percent1RM != null && (ex.percent1RM < 0.0 || ex.percent1RM > 1.5)) {
          errors.push({ field: `weeks[${i}].sessions[${j}].exercises[${k}].percent1RM`, message: `percent1RM ${ex.percent1RM} must be between 0.0 and 1.5` });
        }
      });
    });
  });
  return errors;
}
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
cd wod-dashboard && npx jest __tests__/validation.test.ts
```

Expected: All 10 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add wod-dashboard/src/lib/validation.ts wod-dashboard/__tests__/validation.test.ts
git commit -m "feat(wod-dashboard): add WOD and Program validators"
```

---

## Task 4: Exercise Catalog

**Files:**
- Create: `wod-dashboard/src/lib/exercise-catalog.ts`
- Create: `wod-dashboard/__tests__/exercise-catalog.test.ts`

- [ ] **Step 1: Write failing tests**

`__tests__/exercise-catalog.test.ts`:

```typescript
import { weightliftingExercises, conditioningExercises, allExerciseNames } from "../src/lib/exercise-catalog";

describe("ExerciseCatalog", () => {
  test("has 39 weightlifting exercises", () => {
    expect(weightliftingExercises.length).toBe(39);
  });

  test("has 21 conditioning exercises", () => {
    expect(conditioningExercises.length).toBe(21);
  });

  test("allExerciseNames contains Back Squat", () => {
    expect(allExerciseNames).toContain("Back Squat");
  });

  test("categories are correct", () => {
    const categories = [...new Set(weightliftingExercises.map((e) => e.category))];
    expect(categories).toEqual(expect.arrayContaining(["Squat", "Hip Hinge", "Press", "Pull", "Carry", "Olympic Weightlifting"]));
  });
});
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
cd wod-dashboard && npx jest __tests__/exercise-catalog.test.ts
```

- [ ] **Step 3: Implement exercise-catalog.ts**

`src/lib/exercise-catalog.ts` — mirror the Swift `WeightliftingExerciseCatalog` and `ConditioningExerciseCatalog` exactly. Copy all 39 weightlifting entries and 21 conditioning entries with their categories and scoring types.

```typescript
export interface WeightliftingEntry {
  id: string;
  category: "Squat" | "Hip Hinge" | "Press" | "Pull" | "Carry" | "Olympic Weightlifting";
}

export interface ConditioningEntry {
  id: string;
  defaultScoringType: "time" | "reps";
}

export const weightliftingExercises: WeightliftingEntry[] = [
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

export const conditioningExercises: ConditioningEntry[] = [
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
  { id: "400m Run", defaultScoringType: "time" },
  { id: "800m Run", defaultScoringType: "time" },
  { id: "1-Mile Run", defaultScoringType: "time" },
  { id: "5K Run", defaultScoringType: "time" },
  { id: "500m Row", defaultScoringType: "time" },
  { id: "2K Row", defaultScoringType: "time" },
  { id: "1K Assault Bike", defaultScoringType: "time" },
];

export const allExerciseNames: string[] = [
  ...weightliftingExercises.map((e) => e.id),
  ...conditioningExercises.map((e) => e.id),
];
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
cd wod-dashboard && npx jest __tests__/exercise-catalog.test.ts
```

Expected: All 4 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add wod-dashboard/src/lib/exercise-catalog.ts wod-dashboard/__tests__/exercise-catalog.test.ts
git commit -m "feat(wod-dashboard): add exercise catalog mirroring Swift models"
```

---

## Task 5: File I/O and Path Resolution

**Files:**
- Create: `wod-dashboard/src/lib/paths.ts`
- Create: `wod-dashboard/src/lib/file-io.ts`
- Create: `wod-dashboard/__tests__/file-io.test.ts`

- [ ] **Step 1: Write failing tests**

`__tests__/file-io.test.ts`:

```typescript
import { readJSONFile, writeJSONFile } from "../src/lib/file-io";
import fs from "fs";
import path from "path";
import os from "os";

describe("file-io", () => {
  let tmpFile: string;

  beforeEach(() => {
    tmpFile = path.join(os.tmpdir(), `test-${Date.now()}.json`);
  });

  afterEach(() => {
    if (fs.existsSync(tmpFile)) fs.unlinkSync(tmpFile);
    const bak = tmpFile + ".bak";
    if (fs.existsSync(bak)) fs.unlinkSync(bak);
  });

  test("reads a JSON array file", async () => {
    fs.writeFileSync(tmpFile, JSON.stringify([{ id: "a" }]));
    const data = await readJSONFile(tmpFile);
    expect(data).toEqual([{ id: "a" }]);
  });

  test("writes JSON with pretty-printing", async () => {
    await writeJSONFile(tmpFile, [{ id: "b" }]);
    const raw = fs.readFileSync(tmpFile, "utf-8");
    expect(raw).toContain("  "); // 2-space indent
    expect(JSON.parse(raw)).toEqual([{ id: "b" }]);
  });

  test("creates .bak before writing", async () => {
    fs.writeFileSync(tmpFile, JSON.stringify([{ id: "original" }]));
    await writeJSONFile(tmpFile, [{ id: "updated" }]);
    const bak = fs.readFileSync(tmpFile + ".bak", "utf-8");
    expect(JSON.parse(bak)).toEqual([{ id: "original" }]);
  });
});
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
cd wod-dashboard && npx jest __tests__/file-io.test.ts
```

- [ ] **Step 3: Implement paths.ts**

`src/lib/paths.ts`:

```typescript
import path from "path";

// process.cwd() returns wod-dashboard/ when running `npm run dev`
// Project root is one level up
const projectRoot = path.resolve(process.cwd(), "..");

export const WODS_JSON_PATH = path.join(projectRoot, "SundeeFundee/Resources/WODs/wods.json");
export const PROGRAMS_JSON_PATH = path.join(projectRoot, "SundeeFundee/Resources/Programs/programs.json");
export const PUBLISH_STATUS_PATH = path.join(process.cwd(), "publish-status.json");
```

- [ ] **Step 4: Implement file-io.ts**

`src/lib/file-io.ts`:

```typescript
import fs from "fs/promises";
import { existsSync } from "fs";

let writeLock: Promise<void> = Promise.resolve();

export async function readJSONFile<T = unknown[]>(filePath: string, fallback?: T): Promise<T> {
  try {
    const content = await fs.readFile(filePath, "utf-8");
    return JSON.parse(content);
  } catch {
    if (fallback !== undefined) return fallback;
    throw new Error(`Failed to read ${filePath}`);
  }
}

export async function writeJSONFile<T>(filePath: string, data: T): Promise<void> {
  // Queue writes to prevent concurrent corruption
  writeLock = writeLock.then(async () => {
    // Create .bak if file exists
    if (existsSync(filePath)) {
      const existing = await fs.readFile(filePath, "utf-8");
      await fs.writeFile(filePath + ".bak", existing, "utf-8");
    }
    const json = JSON.stringify(data, null, 2) + "\n";
    await fs.writeFile(filePath, json, "utf-8");
  });
  return writeLock;
}
```

- [ ] **Step 5: Run tests to verify they pass**

```bash
cd wod-dashboard && npx jest __tests__/file-io.test.ts
```

Expected: All 3 tests PASS.

- [ ] **Step 6: Commit**

```bash
git add wod-dashboard/src/lib/paths.ts wod-dashboard/src/lib/file-io.ts wod-dashboard/__tests__/file-io.test.ts
git commit -m "feat(wod-dashboard): add file I/O with backup and mutex"
```

---

## Task 6: WOD API Routes

**Files:**
- Create: `wod-dashboard/src/app/api/wods/route.ts`

- [ ] **Step 1: Implement WOD API route**

`src/app/api/wods/route.ts`:

```typescript
import { NextRequest, NextResponse } from "next/server";
import { readJSONFile, writeJSONFile } from "@/lib/file-io";
import { WODS_JSON_PATH } from "@/lib/paths";

export async function GET() {
  try {
    const wods = await readJSONFile(WODS_JSON_PATH, []);
    return NextResponse.json(wods);
  } catch (e) {
    return NextResponse.json({ error: String(e) }, { status: 500 });
  }
}

export async function PUT(req: NextRequest) {
  try {
    const wods = await req.json();
    await writeJSONFile(WODS_JSON_PATH, wods);
    return NextResponse.json({ ok: true });
  } catch (e) {
    return NextResponse.json({ error: String(e) }, { status: 500 });
  }
}

export async function PATCH(req: NextRequest) {
  try {
    const wod = await req.json();
    const wods = await readJSONFile<any[]>(WODS_JSON_PATH, []);
    const index = wods.findIndex((w) => w.id === wod.id);
    if (index >= 0) { wods[index] = wod; } else { wods.push(wod); }
    await writeJSONFile(WODS_JSON_PATH, wods);
    return NextResponse.json({ ok: true });
  } catch (e) {
    return NextResponse.json({ error: String(e) }, { status: 500 });
  }
}

export async function DELETE(req: NextRequest) {
  try {
    const { searchParams } = new URL(req.url);
    const id = searchParams.get("id");
    if (!id) return NextResponse.json({ error: "id required" }, { status: 400 });
    const wods = await readJSONFile<any[]>(WODS_JSON_PATH, []);
    const filtered = wods.filter((w) => w.id !== id);
    await writeJSONFile(WODS_JSON_PATH, filtered);
    return NextResponse.json({ ok: true });
  } catch (e) {
    return NextResponse.json({ error: String(e) }, { status: 500 });
  }
}
```

- [ ] **Step 2: Manually test with curl**

```bash
curl http://localhost:3000/api/wods | head -c 200
```

Expected: JSON array of WODs.

- [ ] **Step 3: Commit**

```bash
git add wod-dashboard/src/app/api/wods/route.ts
git commit -m "feat(wod-dashboard): add WOD API routes (GET/PUT/PATCH/DELETE)"
```

---

## Task 7: Program API Routes

**Files:**
- Create: `wod-dashboard/src/app/api/programs/route.ts`

- [ ] **Step 1: Implement Program API route**

`src/app/api/programs/route.ts` — same pattern as WOD route but with `PROGRAMS_JSON_PATH`, try/catch on all handlers. Identical structure to Task 6.

- [ ] **Step 2: Manually test with curl**

```bash
curl http://localhost:3000/api/programs | head -c 200
```

- [ ] **Step 3: Commit**

```bash
git add wod-dashboard/src/app/api/programs/route.ts
git commit -m "feat(wod-dashboard): add Program API routes (GET/PUT/PATCH/DELETE)"
```

---

## Task 8: AI Generation API Routes

**Files:**
- Create: `wod-dashboard/src/app/api/generate/wod/route.ts`
- Create: `wod-dashboard/src/app/api/generate/program/route.ts`

- [ ] **Step 1: Implement WOD generation proxy**

`src/app/api/generate/wod/route.ts`:

```typescript
import { NextRequest, NextResponse } from "next/server";

const WORKER_URL = process.env.CLOUDFLARE_WORKER_URL!;

export async function POST(req: NextRequest) {
  const params = await req.json();
  // params: { date, focusArea, difficulty, exerciseCount, equipment, notes, batchDates? }

  const prompt = buildWODPrompt(params);

  const response = await fetch(WORKER_URL, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      contents: [{ role: "user", parts: [{ text: prompt }] }],
      systemInstruction: {
        parts: [{ text: "You are a strength training program designer. Return valid JSON only, no markdown." }],
      },
      generationConfig: { temperature: 0.7, maxOutputTokens: 4096 },
    }),
  });

  if (!response.ok) {
    return NextResponse.json({ error: "Worker request failed" }, { status: 502 });
  }

  const data = await response.json();

  // Gemini API returns nested structure — extract the text content and parse JSON
  const text = data?.candidates?.[0]?.content?.parts?.[0]?.text;
  if (!text) {
    return NextResponse.json({ error: "No content in AI response" }, { status: 502 });
  }

  // Strip markdown code fences if present
  const cleaned = text.replace(/```json\n?/g, "").replace(/```\n?/g, "").trim();
  try {
    const parsed = JSON.parse(cleaned);
    return NextResponse.json(parsed);
  } catch {
    return NextResponse.json({ error: "Failed to parse AI response as JSON", raw: text }, { status: 502 });
  }
}

function buildWODPrompt(params: any): string {
  const dates = params.batchDates ?? [params.date];
  const dateList = dates.join(", ");
  return `Generate ${dates.length > 1 ? "WODs" : "a WOD"} for the following date(s): ${dateList}.

Focus area: ${params.focusArea ?? "full body"}
Difficulty: ${params.difficulty ?? "intermediate"}
Exercise count: ${params.exerciseCount ?? 4}
Equipment: ${params.equipment ?? "full gym"}
${params.notes ? `Notes: ${params.notes}` : ""}

Return a JSON array of WOD objects. Each WOD:
{
  "id": "wod-YYYY-MM-DD",
  "date": "YYYY-MM-DD",
  "title": "string",
  "description": "string",
  "exercises": [
    {
      "exercise": "string (exercise name)",
      "variant": "string or null",
      "sets": number,
      "reps": number or "AMRAP" or [low, high] or "60s",
      "percent1RM": number 0.0-1.0 or null,
      "restMinutes": number,
      "notes": "string or null",
      "bodyweightOnly": boolean
    }
  ]
}`;
}
```

- [ ] **Step 2: Implement Program generation proxy**

`src/app/api/generate/program/route.ts`:

```typescript
import { NextRequest, NextResponse } from "next/server";

const WORKER_URL = process.env.CLOUDFLARE_WORKER_URL!;

export async function POST(req: NextRequest) {
  const params = await req.json();
  // params: { prompt, category?, duration?, sessionsPerWeek?, difficulty?, goal? }

  const prompt = buildProgramPrompt(params);

  const response = await fetch(WORKER_URL, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      contents: [{ role: "user", parts: [{ text: prompt }] }],
      systemInstruction: {
        parts: [{ text: "You are a strength training program designer. Return valid JSON only, no markdown." }],
      },
      generationConfig: { temperature: 0.7, maxOutputTokens: 16384 },
    }),
  });

  if (!response.ok) {
    return NextResponse.json({ error: "Worker request failed" }, { status: 502 });
  }

  const data = await response.json();

  // Gemini API returns nested structure — extract the text content and parse JSON
  const text = data?.candidates?.[0]?.content?.parts?.[0]?.text;
  if (!text) {
    return NextResponse.json({ error: "No content in AI response" }, { status: 502 });
  }

  const cleaned = text.replace(/```json\n?/g, "").replace(/```\n?/g, "").trim();
  try {
    const parsed = JSON.parse(cleaned);
    return NextResponse.json(parsed);
  } catch {
    return NextResponse.json({ error: "Failed to parse AI response as JSON", raw: text }, { status: 502 });
  }
}

function buildProgramPrompt(params: any): string {
  return `Generate a complete training program.

${params.prompt ? `User request: ${params.prompt}` : ""}
${params.category ? `Category: ${params.category}` : ""}
${params.duration ? `Duration: ${params.duration} weeks` : ""}
${params.sessionsPerWeek ? `Sessions per week: ${params.sessionsPerWeek}` : ""}
${params.difficulty ? `Difficulty: ${params.difficulty}` : ""}
${params.goal ? `Goal: ${params.goal}` : ""}

Return a single JSON object:
{
  "id": "slugified-name",
  "name": "string",
  "category": "string",
  "description": "string",
  "durationWeeks": number,
  "sessionsPerWeek": number,
  "difficulty": "Beginner" | "Intermediate" | "Advanced",
  "phases": [{ "id": "string", "name": "string", "goal": "string", "weekRange": [start, end] }],
  "weeks": [{
    "week": number,
    "phaseId": "string matching a phase id",
    "isTestWeek": boolean,
    "sessions": [{
      "sessionId": "string",
      "sessionName": "string",
      "sessionType": "Lift" | "Conditioning" | "Recovery",
      "focus": "string",
      "exercises": [{
        "exercise": "string",
        "variant": "string or null",
        "sets": number,
        "reps": number or "AMRAP" or [low, high],
        "percent1RM": number 0.0-1.0 or null,
        "restMinutes": number,
        "notes": "string or null"
      }]
    }]
  }],
  "cycleAdjustmentProfile": null
}`;
}
```

- [ ] **Step 3: Commit**

```bash
git add wod-dashboard/src/app/api/generate/
git commit -m "feat(wod-dashboard): add AI generation proxy routes for WODs and programs"
```

---

## Task 9: Toast & Sidebar Components

**Files:**
- Create: `wod-dashboard/src/components/toast.tsx`
- Create: `wod-dashboard/src/components/sidebar.tsx`
- Modify: `wod-dashboard/src/app/layout.tsx`

- [ ] **Step 1: Implement toast notification system**

`src/components/toast.tsx`:

```tsx
"use client";
import { createContext, useContext, useState, useCallback, ReactNode } from "react";

interface Toast {
  id: number;
  message: string;
  type: "success" | "error";
}

const ToastContext = createContext<{ toast: (msg: string, type: "success" | "error") => void }>({ toast: () => {} });

export function useToast() { return useContext(ToastContext); }

export function ToastProvider({ children }: { children: ReactNode }) {
  const [toasts, setToasts] = useState<Toast[]>([]);
  let nextId = 0;

  const toast = useCallback((message: string, type: "success" | "error") => {
    const id = ++nextId;
    setToasts((prev) => [...prev, { id, message, type }]);
    setTimeout(() => setToasts((prev) => prev.filter((t) => t.id !== id)), 3000);
  }, []);

  return (
    <ToastContext.Provider value={{ toast }}>
      {children}
      <div className="fixed bottom-4 right-4 flex flex-col gap-2 z-50">
        {toasts.map((t) => (
          <div key={t.id} className={`px-4 py-2 rounded shadow-lg text-white ${t.type === "success" ? "bg-green-600" : "bg-red-600"}`}>
            {t.message}
          </div>
        ))}
      </div>
    </ToastContext.Provider>
  );
}
```

- [ ] **Step 2: Implement sidebar with active state**

`src/components/sidebar.tsx`:

```tsx
"use client";
import Link from "next/link";
import { usePathname } from "next/navigation";

const links = [
  { href: "/wods", label: "WODs" },
  { href: "/programs", label: "Programs" },
  { href: "/catalog", label: "Exercise Catalog" },
  { href: "/settings", label: "Settings" },
];

export function Sidebar() {
  const pathname = usePathname();
  return (
    <nav className="w-60 bg-navy text-cream p-4 flex flex-col gap-1 shrink-0">
      <h1 className="text-xl font-bold mb-6 text-orange">Sundee Fundee</h1>
      {links.map((link) => (
        <Link
          key={link.href}
          href={link.href}
          className={`px-3 py-2 rounded transition-colors ${
            pathname.startsWith(link.href) ? "bg-orange text-white" : "hover:bg-navy/80 hover:text-orange"
          }`}
        >
          {link.label}
        </Link>
      ))}
    </nav>
  );
}
```

- [ ] **Step 3: Update root layout to use components**

Update `src/app/layout.tsx` to import `Sidebar` and `ToastProvider`, replacing the inline nav.

- [ ] **Step 4: Verify in browser**

Sidebar highlights active route, toast can be triggered.

- [ ] **Step 5: Commit**

```bash
git add wod-dashboard/src/components/toast.tsx wod-dashboard/src/components/sidebar.tsx wod-dashboard/src/app/layout.tsx
git commit -m "feat(wod-dashboard): add sidebar navigation and toast notifications"
```

---

## Task 10: Exercise Autocomplete Component

**Files:**
- Create: `wod-dashboard/src/components/exercise-autocomplete.tsx`

- [ ] **Step 1: Implement autocomplete**

`src/components/exercise-autocomplete.tsx`:

```tsx
"use client";
import { useState, useRef } from "react";
import { weightliftingExercises, conditioningExercises } from "@/lib/exercise-catalog";

interface Props {
  value: string;
  onChange: (value: string) => void;
}

const grouped = [
  ...["Squat", "Hip Hinge", "Press", "Pull", "Carry", "Olympic Weightlifting"].map((cat) => ({
    label: cat,
    items: weightliftingExercises.filter((e) => e.category === cat).map((e) => e.id),
  })),
  { label: "Conditioning (Reps)", items: conditioningExercises.filter((e) => e.defaultScoringType === "reps").map((e) => e.id) },
  { label: "Conditioning (Time)", items: conditioningExercises.filter((e) => e.defaultScoringType === "time").map((e) => e.id) },
];

export function ExerciseAutocomplete({ value, onChange }: Props) {
  const [open, setOpen] = useState(false);
  const [filter, setFilter] = useState("");
  const inputRef = useRef<HTMLInputElement>(null);

  const query = filter || value;
  const filtered = grouped
    .map((g) => ({ ...g, items: g.items.filter((item) => item.toLowerCase().includes(query.toLowerCase())) }))
    .filter((g) => g.items.length > 0);

  return (
    <div className="relative">
      <input
        ref={inputRef}
        type="text"
        value={value}
        onChange={(e) => { onChange(e.target.value); setFilter(e.target.value); }}
        onFocus={() => setOpen(true)}
        onBlur={() => setTimeout(() => setOpen(false), 200)}
        className="w-full border border-navy/20 rounded px-2 py-1 bg-white text-navy"
        placeholder="Exercise name..."
      />
      {open && filtered.length > 0 && (
        <div className="absolute z-10 top-full left-0 w-72 max-h-60 overflow-auto bg-white border border-navy/20 rounded shadow-lg mt-1">
          {filtered.map((group) => (
            <div key={group.label}>
              <div className="px-2 py-1 text-xs font-bold text-navy/50 uppercase">{group.label}</div>
              {group.items.map((item) => (
                <button
                  key={item}
                  className="w-full text-left px-2 py-1 hover:bg-orange/10 text-sm"
                  onMouseDown={(e) => { e.preventDefault(); onChange(item); setFilter(""); setOpen(false); }}
                >
                  {item}
                </button>
              ))}
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
```

- [ ] **Step 2: Commit**

```bash
git add wod-dashboard/src/components/exercise-autocomplete.tsx
git commit -m "feat(wod-dashboard): add exercise autocomplete with grouped categories"
```

---

## Task 11: Exercise Row Component

**Files:**
- Create: `wod-dashboard/src/components/exercise-row.tsx`

- [ ] **Step 1: Implement exercise row editor**

`src/components/exercise-row.tsx` — inline editor for a single `ProgramExercise`. Fields: exercise (autocomplete), variant, sets, reps, percent1RM, restMinutes, notes, bodyweightOnly. Includes drag handle, delete button. The sets/reps fields accept free-text input and parse on blur using `decodeExerciseValue`.

```tsx
"use client";
import { ProgramExercise, ExerciseValue, decodeExerciseValue, encodeExerciseValue } from "@/lib/types";
import { ExerciseAutocomplete } from "./exercise-autocomplete";

interface Props {
  exercise: ProgramExercise;
  onChange: (updated: ProgramExercise) => void;
  onDelete: () => void;
}

function evToString(ev: ExerciseValue): string {
  switch (ev.type) {
    case "fixed": return String(ev.value);
    case "amrap": return "AMRAP";
    case "range": return `${ev.low}-${ev.high}`;
    case "text": return ev.text;
  }
}

export function ExerciseRow({ exercise, onChange, onDelete }: Props) {
  const update = (partial: Partial<ProgramExercise>) => onChange({ ...exercise, ...partial });

  return (
    <div className="flex items-center gap-2 py-1 border-b border-navy/10">
      <div className="w-52">
        <ExerciseAutocomplete value={exercise.exercise} onChange={(v) => update({ exercise: v })} />
      </div>
      <input className="w-24 border border-navy/20 rounded px-2 py-1 text-sm" placeholder="Variant"
        value={exercise.variant ?? ""} onChange={(e) => update({ variant: e.target.value || null })} />
      <input className="w-16 border border-navy/20 rounded px-2 py-1 text-sm text-center" placeholder="Sets"
        value={evToString(exercise.sets)}
        onChange={(e) => update({ sets: decodeExerciseValue(e.target.value) })} />
      <input className="w-20 border border-navy/20 rounded px-2 py-1 text-sm text-center" placeholder="Reps"
        value={evToString(exercise.reps)}
        onChange={(e) => update({ reps: decodeExerciseValue(e.target.value) })} />
      <input className="w-16 border border-navy/20 rounded px-2 py-1 text-sm text-center" placeholder="%1RM"
        type="number" step="0.01" min="0" max="1.5"
        value={exercise.percent1RM ?? ""} onChange={(e) => update({ percent1RM: e.target.value ? parseFloat(e.target.value) : null })} />
      <input className="w-16 border border-navy/20 rounded px-2 py-1 text-sm text-center" placeholder="Rest"
        type="number" step="0.5" min="0"
        value={exercise.restMinutes ?? ""} onChange={(e) => update({ restMinutes: e.target.value ? parseFloat(e.target.value) : null })} />
      <input className="flex-1 border border-navy/20 rounded px-2 py-1 text-sm" placeholder="Notes"
        value={exercise.notes ?? ""} onChange={(e) => update({ notes: e.target.value || null })} />
      <label className="flex items-center gap-1 text-xs">
        <input type="checkbox" checked={exercise.bodyweightOnly ?? false}
          onChange={(e) => update({ bodyweightOnly: e.target.checked })} />
        BW
      </label>
      <button onClick={onDelete} className="text-red-500 hover:text-red-700 text-lg font-bold">&times;</button>
    </div>
  );
}
```

- [ ] **Step 2: Commit**

```bash
git add wod-dashboard/src/components/exercise-row.tsx
git commit -m "feat(wod-dashboard): add inline exercise row editor"
```

---

## Task 12: WOD List & Editor Components

**Files:**
- Create: `wod-dashboard/src/components/wod-list.tsx`
- Create: `wod-dashboard/src/components/wod-editor.tsx`
- Modify: `wod-dashboard/src/app/wods/page.tsx`

- [ ] **Step 1: Implement WOD list**

`src/components/wod-list.tsx` — fetches from `/api/wods`, displays table with date/title/exercise count/status, click to select, "New WOD" button. Include date range filter inputs. Add checkbox column for bulk select with a "Publish Selected" batch action button.

- [ ] **Step 2: Implement WOD editor**

`src/components/wod-editor.tsx` — form for editing a WOD. Date picker, title, description fields. Exercise list using `ExerciseRow` with add/delete and `@dnd-kit/sortable` for drag reorder. Validates on save using `validateWOD`. Shows inline errors. Save calls `PATCH /api/wods`. Auto-generates ID from date. Delete button calls `DELETE /api/wods?id=...`.

- [ ] **Step 3: Wire up WODs page**

`src/app/wods/page.tsx` — client component with two-panel layout: list on left, editor on right. Selecting a WOD loads it into the editor. "New WOD" creates a blank template.

- [ ] **Step 4: Test in browser**

Verify: list loads existing WODs from `wods.json`, clicking one populates editor, editing and saving persists to file, validation errors show inline.

- [ ] **Step 5: Commit**

```bash
git add wod-dashboard/src/components/wod-list.tsx wod-dashboard/src/components/wod-editor.tsx wod-dashboard/src/app/wods/page.tsx
git commit -m "feat(wod-dashboard): add WOD list and editor UI"
```

---

## Task 13: WOD Generator Component

**Files:**
- Create: `wod-dashboard/src/components/wod-generator.tsx`
- Modify: `wod-dashboard/src/app/wods/page.tsx`

- [ ] **Step 1: Implement WOD generator**

`src/components/wod-generator.tsx` — form with: date (or date range toggle for batch), focus area dropdown (Squat/Hip Hinge/Press/Pull/Full Body), difficulty dropdown (Beginner/Intermediate/Advanced), exercise count (number input), equipment (text), notes (textarea). "Generate" button calls `POST /api/generate/wod`, shows loading spinner with cancel button (uses `AbortController` to abort the fetch), parses response, loads result into the WOD editor for review.

- [ ] **Step 2: Add generator toggle to WODs page**

Add a "Generate WOD" button that toggles the generator form visibility.

- [ ] **Step 3: Test in browser**

Generate a WOD, verify it loads into the editor, review and save.

- [ ] **Step 4: Commit**

```bash
git add wod-dashboard/src/components/wod-generator.tsx wod-dashboard/src/app/wods/page.tsx
git commit -m "feat(wod-dashboard): add WOD AI generator"
```

---

## Task 14a: Program List & Header Editor

**Files:**
- Create: `wod-dashboard/src/components/program-list.tsx`
- Create: `wod-dashboard/src/components/program-editor.tsx`
- Modify: `wod-dashboard/src/app/programs/page.tsx`

- [ ] **Step 1: Implement program list**

`src/components/program-list.tsx` — table with name/category/difficulty/duration/sessions per week/status. Click to select.

- [ ] **Step 2: Implement program editor shell**

`src/components/program-editor.tsx` — header fields only for now: id (auto-slugified from name), name, category, description, difficulty dropdown (Beginner/Intermediate/Advanced), durationWeeks, sessionsPerWeek. Phases section with add/remove/reorder (use `@dnd-kit/sortable` for drag reorder), each phase has: name, goal, weekRange. Validates header fields on save. Placeholder sections for weeks and cycle adjustment (to be filled in Task 14b/14c).

- [ ] **Step 3: Wire up programs page**

`src/app/programs/page.tsx` — two-panel layout like WODs page. List on left, editor on right.

- [ ] **Step 4: Test in browser**

Load existing programs, verify header fields populate correctly, add/remove/reorder phases.

- [ ] **Step 5: Commit**

```bash
git add wod-dashboard/src/components/program-list.tsx wod-dashboard/src/components/program-editor.tsx \
  wod-dashboard/src/app/programs/page.tsx
git commit -m "feat(wod-dashboard): add Program list and header/phases editor"
```

---

## Task 14b: Week & Session Editors

**Files:**
- Create: `wod-dashboard/src/components/week-editor.tsx`
- Create: `wod-dashboard/src/components/session-editor.tsx`
- Modify: `wod-dashboard/src/components/program-editor.tsx`

- [ ] **Step 1: Implement session editor**

`src/components/session-editor.tsx` — sessionName, sessionType dropdown (Lift/Conditioning/Recovery), focus input, exercise list using `ExerciseRow` with add/delete. Use `@dnd-kit/sortable` for exercise reordering.

- [ ] **Step 2: Implement week editor**

`src/components/week-editor.tsx` — collapsible accordion showing week number, phaseId dropdown (populated from program phases), isTestWeek toggle, list of `SessionEditor` components with add/delete session.

- [ ] **Step 3: Wire weeks into program editor**

Replace the placeholder weeks section in `program-editor.tsx` with `WeekEditor` components. Auto-sync `durationWeeks` with weeks array length.

- [ ] **Step 4: Test in browser**

Edit a program's weeks and sessions, add/remove exercises, save and verify JSON.

- [ ] **Step 5: Commit**

```bash
git add wod-dashboard/src/components/week-editor.tsx wod-dashboard/src/components/session-editor.tsx \
  wod-dashboard/src/components/program-editor.tsx
git commit -m "feat(wod-dashboard): add week and session editors for programs"
```

---

## Task 14c: Cycle Adjustment Editor

**Files:**
- Create: `wod-dashboard/src/components/cycle-adjustment-editor.tsx`
- Modify: `wod-dashboard/src/components/program-editor.tsx`

- [ ] **Step 1: Implement cycle adjustment editor**

`src/components/cycle-adjustment-editor.tsx` — optional section with toggle to enable/disable. When enabled: fallbackPhase dropdown (menstrual/follicular/ovulation/luteal), lowConfidenceScale number input (0-1), and a 4-row table for phase settings (menstrual/follicular/ovulation/luteal) each with loadMultiplier/setsMultiplier/repsMultiplier number inputs.

- [ ] **Step 2: Wire into program editor**

Replace the placeholder cycle adjustment section in `program-editor.tsx`.

- [ ] **Step 3: Test in browser**

Toggle cycle adjustments on/off, edit values, save and verify JSON output matches `ProgramCycleAdjustmentProfile` structure.

- [ ] **Step 4: Commit**

```bash
git add wod-dashboard/src/components/cycle-adjustment-editor.tsx wod-dashboard/src/components/program-editor.tsx
git commit -m "feat(wod-dashboard): add cycle adjustment profile editor"
```

---

## Task 15: Program Generator Component

**Files:**
- Create: `wod-dashboard/src/components/program-generator.tsx`
- Modify: `wod-dashboard/src/app/programs/page.tsx`

- [ ] **Step 1: Implement program generator**

`src/components/program-generator.tsx` — large textarea for free-text prompt, optional structured fields (category, duration, sessions/week, difficulty, goal). "Generate" button calls `POST /api/generate/program`, validates response structure, loads into program editor.

- [ ] **Step 2: Add generator toggle to programs page**

- [ ] **Step 3: Test in browser**

Generate a program from prompt, verify it loads correctly into the nested editor.

- [ ] **Step 4: Commit**

```bash
git add wod-dashboard/src/components/program-generator.tsx wod-dashboard/src/app/programs/page.tsx
git commit -m "feat(wod-dashboard): add Program AI generator"
```

---

## Task 16: Exercise Catalog Page

**Files:**
- Modify: `wod-dashboard/src/app/catalog/page.tsx`

- [ ] **Step 1: Implement catalog page**

Read-only reference page. Two sections: Weightlifting (grouped by category) and Conditioning (grouped by scoring type). Simple table layout with exercise name and category/type.

- [ ] **Step 2: Commit**

```bash
git add wod-dashboard/src/app/catalog/page.tsx
git commit -m "feat(wod-dashboard): add exercise catalog reference page"
```

---

## Task 17: Settings Page

**Files:**
- Modify: `wod-dashboard/src/app/settings/page.tsx`

- [ ] **Step 1: Implement settings page**

Display current configuration (read-only since env vars can't be changed at runtime):
- Cloudflare Worker URL
- CloudKit Container ID
- CloudKit Environment
- CloudKit auth status (connected / not connected)

Include a "Test Worker Connection" button that sends a minimal request to verify the worker is reachable.

- [ ] **Step 2: Commit**

```bash
git add wod-dashboard/src/app/settings/page.tsx
git commit -m "feat(wod-dashboard): add settings page"
```

---

## Task 18: CloudKit Publishing

**Files:**
- Create: `wod-dashboard/src/lib/cloudkit.ts`
- Create: `wod-dashboard/src/app/api/cloudkit/publish/route.ts`

- [ ] **Step 1: Implement CloudKit client wrapper**

`src/lib/cloudkit.ts` — browser-side CloudKit JS SDK initialization. Loads CloudKit JS from Apple CDN, configures with container/environment/token from env vars. Provides `setUpAuth()` for Apple ID sign-in and `saveRecord()` / `deleteRecord()` methods that map WOD/Program objects to CloudKit record fields (using the exact field names from the spec: `exercisesJSON`, `weeksJSON`, `phasesJSON`, `cycleAdjustmentProfileJSON`).

- [ ] **Step 2: Implement publish API route**

`src/app/api/cloudkit/publish/route.ts` — POST accepts `{ type: "wod" | "program", data: object }`. Since CloudKit JS runs client-side, this route manages the `publish-status.json` file. The actual CloudKit save happens client-side.

- [ ] **Step 3: Add publish buttons to list views**

Add "Publish" button per row in WOD and Program list views. On click: authenticate if needed, save record to CloudKit, update publish status.

- [ ] **Step 4: Implement publish-status.json tracking**

The publish API route initializes `wod-dashboard/publish-status.json` with `{ "wods": {}, "programs": {} }` if the file doesn't exist (use `readJSONFile` with fallback). Updates the appropriate entry on publish/unpublish with a `publishedAt` ISO timestamp.

- [ ] **Step 5: Test publish flow**

Sign in with Apple ID, publish a WOD, verify status updates in list view.

- [ ] **Step 6: Commit**

```bash
git add wod-dashboard/src/lib/cloudkit.ts wod-dashboard/src/app/api/cloudkit/publish/route.ts \
  wod-dashboard/src/components/wod-list.tsx wod-dashboard/src/components/program-list.tsx
git commit -m "feat(wod-dashboard): add CloudKit publishing with Apple ID auth"
```

---

## Task 19: Polish & Final Integration

**Files:**
- Various existing files

- [ ] **Step 1: Add delete confirmation dialogs**

Before deleting a WOD or program, show a confirm dialog.

- [ ] **Step 2: Add loading states**

Skeleton loaders for list views while fetching, spinner on save/publish.

- [ ] **Step 3: Add duplicate-date warning for WODs**

When entering a date in the WOD editor that matches an existing WOD, show a warning.

- [ ] **Step 4: Test full end-to-end flows**

1. Create a WOD manually, save, verify in `wods.json`
2. Generate a WOD via AI, edit, save
3. Create a program manually, save, verify in `programs.json`
4. Generate a program via AI, edit, save
5. Delete a WOD, verify removed from JSON
6. Publish a WOD to CloudKit (if auth available)

- [ ] **Step 5: Commit**

```bash
git add wod-dashboard/
git commit -m "feat(wod-dashboard): polish UI with loading states, confirmations, and warnings"
```
