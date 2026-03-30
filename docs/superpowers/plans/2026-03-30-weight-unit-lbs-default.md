# Weight Unit LBS Default Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix all weight displays to respect the user's `weightUnit` setting (defaulting to "lb"/pounds) instead of being hardcoded to "kg".

**Architecture:** UI components fetch the user's `weightUnit` preference and use existing domain conversion functions (`fromKilograms`, `toKilograms`, `formatWeightWithUnit`) to display weights in the user's preferred unit. All data remains stored as kg in Firestore.

**Tech Stack:** Next.js 16 App Router, TypeScript, Firebase Firestore, existing domain layer in `src/lib/domain/weight-unit-conversion.ts`

---

### Task 1: Create user profile API route

**Files:**
- Create: `web-app/src/app/api/user/profile/route.ts`

**Why:** Client components (AI workout page) need to fetch the user's `weightUnit` setting. This provides a server endpoint that returns the user profile.

- [ ] **Step 1: Create the API route file**

```typescript
// web-app/src/app/api/user/profile/route.ts
import { NextResponse } from "next/server";
import { getAuthUser } from "@/lib/firestore";
import { getUserProfile } from "@/app/(features)/settings/actions";

export async function GET() {
  const user = await getAuthUser();
  if (!user) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const profile = await getUserProfile();
  return NextResponse.json(profile ?? {});
}
```

- [ ] **Step 2: Test the API route manually**

Run dev server: `cd web-app && npm run dev`
Visit: `http://localhost:3000/api/user/profile` while signed in
Expected: JSON response with user profile including `weightUnit` field

- [ ] **Step 3: Commit**

```bash
git add web-app/src/app/api/user/profile/route.ts
git commit -m "feat: add user profile API route for client components"
```

---

### Task 2: Add weightUnit prop to AddMaxForm component

**Files:**
- Modify: `web-app/src/app/(features)/maxes/add-max-form.tsx:1-75`

**Why:** The form needs to display weights in the user's preferred unit and accept input in that unit, converting to kg before saving.

- [ ] **Step 1: Add weightUnit prop to component**

```typescript
// In web-app/src/app/(features)/maxes/add-max-form.tsx
// Add prop after line 11
export function AddMaxForm({ weightUnit = "lb" }: { weightUnit?: string }) {
  const router = useRouter();
  const [exercise, setExercise] = useState("");
  const [weight, setWeight] = useState("");
  const [reps, setReps] = useState("1");
  // ... rest of component
```

- [ ] **Step 2: Update weight input label to use weightUnit**

Replace line 56:
```typescript
// Old: <Input label="Weight (kg)" type="number" ... />
// New:
<Input label={`Weight (${weightUnit})`} type="number" value={weight} onChange={(e) => setWeight(e.target.value)} />
```

- [ ] **Step 3: Update estimated 1RM display to use weightUnit**

Replace lines 59-63:
```typescript
// Old:
// {isEstimated && weightNum > 0 && (
//   <p className="text-[13px] text-text-secondary">
//     Estimated 1RM: <span className="text-orange font-medium">{Math.round(estimated1RM)} kg</span> (Epley)
//   </p>
// )}

// New:
{isEstimated && weightNum > 0 && (
  <p className="text-[13px] text-text-secondary">
    Estimated 1RM: <span className="text-orange font-medium">{Math.round(estimated1RM * 10) / 10} {weightUnit}</span> (Epley)
  </p>
)}
```

- [ ] **Step 4: Convert input to kg before saving**

Replace line 32:
```typescript
// Old: await addMax({ exerciseId: exercise.trim(), weightKg: Math.round(estimated1RM * 10) / 10, isEstimated });
// New:
await addMax({ exerciseId: exercise.trim(), weightKg: toKilograms(estimated1RM, weightUnit), isEstimated });
```

- [ ] **Step 5: Add import for toKilograms**

Add after line 10:
```typescript
import { toKilograms } from "@/lib/domain";
```

- [ ] **Step 6: Run existing tests to verify no regression**

Run: `cd web-app && npm test`
Expected: All existing tests pass

- [ ] **Step 7: Commit**

```bash
git add web-app/src/app/(features)/maxes/add-max-form.tsx
git commit -m "feat: add weightUnit prop to AddMaxForm for unit-aware input"
```

---

### Task 3: Update maxes page to fetch and pass weightUnit

**Files:**
- Modify: `web-app/src/app/(features)/maxes/page.tsx:1-65`

**Why:** Server component needs to fetch the user's profile to get weightUnit, pass it to AddMaxForm, and convert weight displays.

- [ ] **Step 1: Add getUserProfile import**

Add after line 4:
```typescript
import { getUserProfile } from "../settings/actions";
import { fromKilograms, formatWeightWithUnit } from "@/lib/domain";
```

- [ ] **Step 2: Fetch user profile in the component**

Replace line 7:
```typescript
// Old: const maxes = await getMaxes();
// New:
const [maxes, profile] = await Promise.all([
  getMaxes(),
  getUserProfile(),
]);
const weightUnit = (profile?.weightUnit as string) ?? "lb";
```

- [ ] **Step 3: Pass weightUnit to AddMaxForm**

Replace line 22:
```typescript
// Old: <AddMaxForm />
// New:
<AddMaxForm weightUnit={weightUnit} />
```

- [ ] **Step 4: Convert max display weight**

Replace line 44:
```typescript
// Old: <span className="text-orange font-bold font-mono text-lg">{records[0].weightKg} kg</span>
// New:
<span className="text-orange font-bold font-mono text-lg">{formatWeightWithUnit(records[0].weightKg, weightUnit)}</span>
```

- [ ] **Step 5: Convert history list weights**

Replace line 52:
```typescript
// Old: <span className="ml-2 font-mono">{r.weightKg} kg {r.isEstimated ? "(est)" : ""}</span>
// New:
<span className="ml-2 font-mono">{formatWeightWithUnit(r.weightKg, weightUnit)}{r.isEstimated ? " (est)" : ""}</span>
```

- [ ] **Step 6: Run existing tests to verify no regression**

Run: `cd web-app && npm test`
Expected: All existing tests pass

- [ ] **Step 7: Manual test in browser**

1. Start dev server: `cd web-app && npm run dev`
2. Navigate to /maxes
3. Verify weights show as "lb" by default
4. Add a max with weight in lbs, verify it saves correctly
5. Check settings, change to kg
6. Refresh /maxes, verify weights now show as "kg"

- [ ] **Step 8: Commit**

```bash
git add web-app/src/app/(features)/maxes/page.tsx
git commit -m "feat: fetch weightUnit in maxes page and convert displays"
```

---

### Task 4: Add weightUnit fetching to AI workout page

**Files:**
- Modify: `web-app/src/app/(features)/workouts/ai/page.tsx:1-238`

**Why:** Client component needs to fetch weightUnit on mount and use it to convert generated workout weights.

- [ ] **Step 1: Add weightUnit state and effect**

Add after line 50:
```typescript
const [userWeightUnit, setUserWeightUnit] = useState<string>("lb");

useEffect(() => {
  async function fetchWeightUnit() {
    try {
      const res = await fetch("/api/user/profile");
      if (res.ok) {
        const profile = await res.json();
        setUserWeightUnit(profile.weightUnit ?? "lb");
      }
    } catch {
      // Fallback to lb
      setUserWeightUnit("lb");
    }
  }
  fetchWeightUnit();
}, []);
```

- [ ] **Step 2: Add formatWeightWithUnit import**

Add after line 11:
```typescript
import { formatWeightWithUnit } from "@/lib/domain";
```

- [ ] **Step 3: Convert workout weight displays**

Replace lines 121-124:
```typescript
// Old:
// {ex.sets} sets × {ex.reps} reps
// {ex.weightKg ? ` @ ${ex.weightKg} kg` : ""}

// New:
{ex.sets} sets × {ex.reps} reps
{ex.weightKg ? ` @ ${formatWeightWithUnit(ex.weightKg, userWeightUnit)}` : ""}
```

- [ ] **Step 4: Run existing tests to verify no regression**

Run: `cd web-app && npm test`
Expected: All existing tests pass

- [ ] **Step 5: Manual test in browser**

1. Start dev server: `cd web-app && npm run dev`
2. Navigate to /workouts/ai
3. Generate a workout
4. Verify weights show as "lb" by default
5. Change settings to kg, refresh, regenerate workout
6. Verify weights now show as "kg"

- [ ] **Step 6: Commit**

```bash
git add web-app/src/app/(features)/workouts/ai/page.tsx
git commit -m "feat: fetch weightUnit in AI workout page and convert displays"
```

---

### Task 5: Add weightUnit prop to LogResultForm component

**Files:**
- Modify: `web-app/src/app/(features)/benchmarks/[id]/log-result-form.tsx:1-98`
- Modify: `web-app/src/app/(features)/benchmarks/[id]/page.tsx:170`

**Why:** The benchmark logging form needs to display the weight label in the user's preferred unit and convert input to kg before saving.

- [ ] **Step 1: Add weightUnit prop to LogResultForm**

Replace line 12 in log-result-form.tsx:
```typescript
// Old: export function LogResultForm({ definitionId, scoringType }: { definitionId: string; scoringType: string }) {
// New:
export function LogResultForm({ definitionId, scoringType, weightUnit = "lb" }: {
  definitionId: string;
  scoringType: string;
  weightUnit?: string;
}) {
```

- [ ] **Step 2: Update label to use weightUnit**

Replace lines 24-26:
```typescript
// Old:
// const label = scoringType === "weight" ? "Weight (kg)"
//   : scoringType === "reps" ? "Reps"
//   : "Score";

// New:
const label = scoringType === "weight" ? `Weight (${weightUnit})`
  : scoringType === "reps" ? "Reps"
  : "Score";
```

- [ ] **Step 3: Add toKilograms import and convert weight input**

Add import after line 10:
```typescript
import { toKilograms } from "@/lib/domain";
```

Replace line 83:
```typescript
// Old: const scoreValue = isTime ? timeValue : parseFloat(score);
// New:
const scoreValue = isTime ? timeValue : (scoringType === "weight" ? toKilograms(parseFloat(score), weightUnit) : parseFloat(score));
```

- [ ] **Step 4: Update benchmark detail page to fetch and pass weightUnit**

In page.tsx, add import after line 7:
```typescript
import { getUserProfile } from "../../settings/actions";
import { fromKilograms, formatWeightWithUnit } from "@/lib/domain";
```

Replace lines 68-73 in page.tsx:
```typescript
// Old:
// const [allResults, cycleStatus, cycleSettings, periodLogs] = await Promise.all([
//   getBenchmarkResults(),
//   getCycleStatus(),
//   getCycleSettings(),
//   getPeriodLogs(),
// ]);

// New:
const [allResults, cycleStatus, cycleSettings, periodLogs, profile] = await Promise.all([
  getBenchmarkResults(),
  getCycleStatus(),
  getCycleSettings(),
  getPeriodLogs(),
  getUserProfile(),
]);
const weightUnit = (profile?.weightUnit as string) ?? "lb";
```

Replace line 170 in page.tsx:
```typescript
// Old: <LogResultForm definitionId={id} scoringType={benchmark.scoringType} />
// New:
<LogResultForm definitionId={id} scoringType={benchmark.scoringType} weightUnit={weightUnit} />
```

- [ ] **Step 5: Update formatScore function to use weightUnit**

Replace the formatScore function (lines 35-55):
```typescript
function formatScore(value: number, type: string, weightUnit: string = "kg"): string {
  switch (type) {
    case "time": {
      const hours = Math.floor(value / 3600);
      const min = Math.floor((value % 3600) / 60);
      const sec = Math.floor(value % 60);
      if (hours > 0) {
        return `${hours}:${String(min).padStart(2, "0")}:${String(sec).padStart(2, "0")}`;
      }
      return `${min}:${String(sec).padStart(2, "0")}`;
    }
    case "weight": return formatWeightWithUnit(value, weightUnit);
    case "reps": return `${Math.floor(value)} reps`;
    case "roundsAndReps": {
      const rounds = Math.floor(value / 10000);
      const reps = Math.floor(value % 10000);
      return `${rounds}+${reps}`;
    }
    default: return String(value);
  }
}
```

- [ ] **Step 6: Update all formatScore calls to pass weightUnit**

Replace lines 184 and 226:
```typescript
// Line 184 Old: value={formatScore(bestResult.scoreValue, benchmark.scoringType)}
// Line 184 New:
value={formatScore(bestResult.scoreValue, benchmark.scoringType, weightUnit)}

// Line 226 Old: <span className="font-mono font-semibold">{formatScore(r.scoreValue, benchmark.scoringType)}</span>
// Line 226 New:
<span className="font-mono font-semibold">{formatScore(r.scoreValue, benchmark.scoringType, weightUnit)}</span>
```

- [ ] **Step 7: Run existing tests to verify no regression**

Run: `cd web-app && npm test`
Expected: All existing tests pass

- [ ] **Step 8: Manual test in browser**

1. Start dev server: `cd web-app && npm run dev`
2. Navigate to /benchmarks (select a weight-type benchmark)
3. Verify "Weight (lb)" label by default
4. Log a result with weight in lbs
5. Change settings to kg, refresh
6. Verify label now shows "Weight (kg)" and history shows converted values

- [ ] **Step 9: Commit**

```bash
git add web-app/src/app/(features)/benchmarks/[id]/log-result-form.tsx web-app/src/app/(features)/benchmarks/[id]/page.tsx
git commit -m "feat: add weightUnit prop to LogResultForm and benchmark page"
```

---

### Task 6: Manual testing checklist

**Files:**
- No file changes

**Why:** Comprehensive end-to-end verification that all weight displays respect the user's setting.

- [ ] **Step 1: Test new user (lbs default)**

1. Sign out or use incognito
2. Create new account
3. Navigate to /maxes
4. Verify: "Weight (lb)" label in add form
5. Add max: enter "135" lbs, save
6. Verify: Display shows "135 lb"
7. Navigate to /workouts/ai
8. Generate workout
9. Verify: Weights show as "lb"
10. Navigate to /benchmarks, select a weight benchmark
11. Verify: "Weight (lb)" label

- [ ] **Step 2: Test switching to kg**

1. Go to /settings
2. Change weight unit to "Kilograms (kg)"
3. Save
4. Navigate to /maxes
5. Verify: All existing maxes show as "kg"
6. Add max: enter "100" kg, save
7. Verify: Display shows "100 kg"
8. Navigate to /workouts/ai
9. Generate workout
10. Verify: Weights show as "kg"
11. Navigate to benchmarks
12. Verify: "Weight (kg)" label

- [ ] **Step 3: Test switching back to lb**

1. Go to /settings
2. Change weight unit to "Pounds (lb)"
3. Save
4. Navigate to /maxes
5. Verify: All maxes show as "lb" (including the 100kg one entered earlier, should show ~220lb)

- [ ] **Step 4: Verify data integrity**

1. Check Firebase Console or use Firestore inspection
2. Verify: All `weightKg` values are stored in kilograms
3. Verify: No data was corrupted during unit conversions

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "test: complete manual testing checklist for weight unit feature"
```

---

### Task 7: Run full test suite and verify domain tests

**Files:**
- No file changes (verification only)

**Why:** Ensure all existing domain tests still pass and conversion functions work correctly.

- [ ] **Step 1: Run full test suite**

Run: `cd web-app && npm test`

Expected: All tests pass, especially `weight-unit-conversion.test.ts`

- [ ] **Step 2: Run specific conversion tests**

Run: `cd web-app && npm test -- weight-unit-conversion`

Expected output should show:
- `fromKilograms` converts correctly
- `toKilograms` converts correctly
- `formatWeightWithUnit` formats correctly
- `parseInputToKilograms` parses correctly

- [ ] **Step 3: Verify test coverage**

Run: `cd web-app && npm run test:coverage`

Check that `src/lib/domain/weight-unit-conversion.ts` has 100% coverage

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "test: verify all tests pass for weight unit feature"
```

---

## Self-Review Checklist

After completing all tasks, verify:

- [ ] All weight displays on /maxes page respect user's weightUnit
- [ ] All weight displays on /workouts/ai page respect user's weightUnit
- [ ] All weight displays on /benchmarks pages respect user's weightUnit
- [ ] New users default to "lb" (pounds)
- [ ] Weights are stored as kg in Firestore (verify in console)
- [ ] Switching between units updates all displays correctly
- [ ] All existing tests still pass
- [ ] No console errors during manual testing
- [ ] API route /api/user/profile returns correct profile data

---

## Success Criteria

1. All weight displays respect the user's `weightUnit` setting
2. New users default to "lb" (pounds)
3. Existing users keep their chosen preference
4. All weight entries continue to be stored as kg in Firestore
5. No data migration required
