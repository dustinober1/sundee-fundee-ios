# Phase 02: Visual Progress - Research

**Researched:** 2026-02-18
**Domain:** Data visualization, chart components, React 19 / Next.js 16, IndexedDB/Dexie
**Confidence:** HIGH (full codebase inspection + installed library verification)

---

## Summary

Phase 02 adds three charts to the existing `/progress` page: an estimated-1RM line chart per exercise (CHART-01), a weekly volume bar chart (CHART-02), and a GitHub-style workout frequency heatmap (CHART-03). All must have graceful empty states.

The project already has **recharts 3.7.0** installed and a partially-built `WeightProgressChart` in `src/components/progress/`. The existing chart shows raw set weights from the first 20 records—it must be replaced/extended to show proper estimated 1RM over time. Phase 01 is complete: `completedWorkouts` and `completedSets` are actively persisted to IndexedDB on every workout completion.

The one library gap is the heatmap: recharts has no built-in grid heatmap. **react-activity-calendar 3.1.1** is the standard solution, is React 19-compatible, and needs to be added.

**Primary recommendation:** Use recharts 3.7.0 for line + bar charts, react-activity-calendar for the heatmap, date-fns 4.1.0 (already installed) for all date math, and keep all data access in custom hooks that query Dexie directly.

---

## User Constraints

_No CONTEXT.md found (discussion phase skipped). No locked user decisions. All implementation choices are Claude's discretion._

---

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| recharts | 3.7.0 ✅ installed | LineChart, BarChart | Already in project, React 19-compatible, full TypeScript support |
| react-activity-calendar | 3.1.1 | GitHub-style heatmap | Purpose-built, zero config, `peerDeps: react >=18 || >=19`, 3.1.1 is latest |
| date-fns | 4.1.0 ✅ installed | Week grouping, date formatting, 365-day range | Already in project |
| dexie | 4.3.0 ✅ installed | IndexedDB queries for chart data | Already in project, all chart data lives here |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| shadcn Card | ✅ installed | Chart containers | Every chart wrapped in a Card |
| shadcn Select | ✅ installed | Exercise dropdown for CHART-01 | Exercise picker |
| shadcn Skeleton | ✅ installed | Loading state | While async Dexie queries resolve |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| react-activity-calendar | Custom CSS grid | Activity calendar has edge-case logic (leap years, partial weeks, color scaling) — hand-rolling wastes ~2 days |
| react-activity-calendar | recharts ScatterChart styled as grid | Not designed for this, tooltip/accessibility not handled |
| Epley estimated 1RM | oneRepMaxes table | `oneRepMaxes` table is written only by onboarding/test days — sparse data. Epley from `completedSets` gives continuous signal |

### Installation

```bash
npm install react-activity-calendar
```

---

## Architecture Patterns

### Recommended Project Structure

```
src/
├── components/progress/
│   ├── weight-progress-chart.tsx     # REPLACE: new 1RM line chart (CHART-01)
│   ├── weekly-volume-chart.tsx       # NEW: bar chart (CHART-02)
│   ├── workout-heatmap.tsx           # NEW: frequency heatmap (CHART-03)
│   └── cycle-filter.tsx              # EXISTING: keep as-is
├── hooks/
│   ├── use-1rm-progress.ts           # NEW: Dexie query + Epley calc for CHART-01
│   ├── use-weekly-volume.ts          # NEW: Dexie join + week grouping for CHART-02
│   └── use-workout-frequency.ts      # NEW: Dexie date query for CHART-03
└── app/progress/
    └── page.tsx                      # UPDATE: add new chart cards
```

**Convention:** Each chart gets one component + one data hook. No data logic inside chart components.

### Pattern 1: Async Dexie hook with cleanup flag

All three charts query IndexedDB asynchronously. Use this pattern to avoid setState-on-unmounted-component:

```typescript
// Source: existing src/components/progress/weight-progress-chart.tsx pattern
export function use1RMProgress(exerciseId: string) {
  const [data, setData] = useState<ChartPoint[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let isActive = true;

    void (async () => {
      const result = await queryDexie(exerciseId);
      if (isActive) {
        setData(result);
        setLoading(false);
      }
    })();

    return () => { isActive = false; };
  }, [exerciseId]);

  return { data, loading };
}
```

### Pattern 2: Estimated 1RM (Epley formula)

CHART-01 needs continuous 1RM signal. Calculate from `completedSets` per workout per exercise:

```typescript
// Epley formula — standard in strength training research
// Accurate for reps < 10; above that, use Brzycki or clamp at 10 reps
function estimateOneRepMax(weight: number, reps: number): number {
  const clampedReps = Math.min(reps, 10); // don't trust Epley above 10 reps
  return weight * (1 + clampedReps / 30);
}
```

**Query strategy for CHART-01:**
1. `db.completedSets.where('exerciseId').equals(exerciseId).toArray()`
2. Group by `workoutId`
3. For each workout, find max `estimateOneRepMax(actualWeight, actualReps)` across all sets
4. Map `workoutId → completedAt` via `completedWorkouts` lookup
5. Sort by date → return `[{ date: string, estimated1RM: number }]`

### Pattern 3: Weekly volume aggregation for CHART-02

`completedSets` has no date — requires joining through `completedWorkouts`:

```typescript
// Source: project data model (src/lib/db/dexie.ts)
async function queryWeeklyVolume(): Promise<WeeklyVolumePoint[]> {
  const workouts = await db.completedWorkouts.toArray();
  // Build workoutId → week-start-date map
  const workoutDateMap = new Map(
    workouts.map(w => [w.id, startOfWeek(w.completedAt, { weekStartsOn: 1 })])
  );

  const sets = await db.completedSets.toArray();

  // Aggregate volume per week
  const weeklyVolume = new Map<string, number>();
  for (const set of sets) {
    const weekStart = workoutDateMap.get(set.workoutId);
    if (!weekStart) continue;
    const key = format(weekStart, 'yyyy-MM-dd');
    const volume = set.actualWeight * set.actualReps;
    weeklyVolume.set(key, (weeklyVolume.get(key) ?? 0) + volume);
  }

  return Array.from(weeklyVolume.entries())
    .map(([week, volume]) => ({ week, volume }))
    .sort((a, b) => a.week.localeCompare(b.week));
}
```

### Pattern 4: Heatmap data format for react-activity-calendar

```typescript
// react-activity-calendar requires ALL days in range to be listed
// Source: react-activity-calendar npm docs (3.1.1)
interface Activity {
  date: string;   // 'YYYY-MM-DD'
  count: number;  // 0 = no activity
  level: 0 | 1 | 2 | 3 | 4;  // 0=none, 1-4 = intensity
}

// Build full year of dates, merge in actual workout counts
function buildHeatmapData(workoutDates: Date[]): Activity[] {
  const end = new Date();
  const start = subYears(end, 1);
  const countByDate = new Map<string, number>();

  for (const date of workoutDates) {
    const key = format(date, 'yyyy-MM-dd');
    countByDate.set(key, (countByDate.get(key) ?? 0) + 1);
  }

  const days = eachDayOfInterval({ start, end });
  return days.map(day => {
    const key = format(day, 'yyyy-MM-dd');
    const count = countByDate.get(key) ?? 0;
    return {
      date: key,
      count,
      level: count === 0 ? 0 : count === 1 ? 1 : count === 2 ? 2 : count <= 4 ? 3 : 4,
    };
  });
}
```

**react-activity-calendar usage:**
```tsx
// Source: react-activity-calendar npm package (3.1.1)
import ActivityCalendar from 'react-activity-calendar';

<ActivityCalendar
  data={heatmapData}
  colorScheme="light"   // or "dark"
  theme={{
    light: ['#ebedf0', '#9be9a8', '#40c463', '#30a14e', '#216e39'],
  }}
  labels={{ totalCount: '{{count}} workouts in the last year' }}
  showWeekdayLabels
/>
```

### Pattern 5: Recharts with CSS variable colors

The project uses shadcn theme variables. Use them in recharts:

```tsx
// Source: existing src/components/progress/weight-progress-chart.tsx
stroke="hsl(var(--primary))"      // primary brand color
stroke="hsl(var(--chart-1))"      // chart palette color 1 (orange)
fill="hsl(var(--chart-2))"        // chart palette color 2 (teal)
```

Available chart CSS vars: `--chart-1` through `--chart-5` (defined in globals.css).

### Pattern 6: Recharts BarChart (CHART-02)

```tsx
// Source: recharts 3.7.0 (verified by inspecting node_modules exports)
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts';

<ResponsiveContainer width="100%" height={250}>
  <BarChart data={weeklyData}>
    <CartesianGrid strokeDasharray="3 3" />
    <XAxis dataKey="week" tick={{ fontSize: 11 }} tickFormatter={formatWeekLabel} />
    <YAxis tick={{ fontSize: 11 }} tickFormatter={(v) => `${Math.round(v / 1000)}k`} />
    <Tooltip formatter={(value) => [`${value.toLocaleString()} lbs`, 'Volume']} />
    <Bar dataKey="volume" fill="hsl(var(--chart-2))" radius={[4, 4, 0, 0]} />
  </BarChart>
</ResponsiveContainer>
```

### Pattern 7: Exercise selector for CHART-01

```typescript
// Query exercises the user has actually performed
async function getTrackedExercises(): Promise<string[]> {
  const sets = await db.completedSets.toArray();
  return [...new Set(sets.map(s => s.exerciseId))];
}
```

Map exercise IDs to names using `EXERCISES` constant from `src/data/exercises.ts`.

### Anti-Patterns to Avoid

- **Data logic in chart components:** Put all Dexie queries in hooks, not inside the component render/effect
- **Not cleaning up Dexie subscriptions:** Always use the `isActive` flag (see Pattern 1)
- **Calling Dexie inside `useMemo`:** Dexie returns Promises; use `useEffect` + `useState`
- **Filling partial weeks with 0 for volume chart:** Only plot weeks with data — don't pad — avoids misleading "0 volume" bars for future weeks
- **Passing mutable Date objects to recharts:** Serialize to ISO strings before charting
- **Skipping ResponsiveContainer:** Charts without it break on mobile. Always wrap.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| GitHub-style heatmap grid | Custom CSS grid calendar | react-activity-calendar | Handles leap years, partial start/end weeks, color scaling, accessibility, tooltips |
| Date week grouping | Custom week calculator | `date-fns/startOfWeek` + `date-fns/format` | Already installed, handles DST, locale, week-start day |
| Chart tooltip formatting | Custom tooltip components (recharts) | recharts `Tooltip formatter` prop | Built-in, handles position and theme automatically |
| 1RM formula | Research formulas from scratch | Epley: `weight * (1 + reps/30)` | Industry standard, already directionally in codebase |

**Key insight:** The heatmap is the only genuinely hard piece. react-activity-calendar reduces it to a data-format problem.

---

## Common Pitfalls

### Pitfall 1: completedSets has no date — must join via completedWorkouts

**What goes wrong:** Developer queries `completedSets` directly and uses `createdAt` for weekly grouping. This works for the line chart (sets have `createdAt`) but `createdAt` on a set might be slightly different per set in the same workout session.

**How to avoid:** Join through `completedWorkouts.completedAt` for the authoritative workout date. For `completedSets.createdAt`, use it only for ordering within a workout.

**Warning signs:** Weekly volume chart shows multiple bars for the same workout session.

### Pitfall 2: New users — all three charts must handle zero data gracefully

**What goes wrong:** Recharts throws when `data=[]` or renders a blank SVG with no axis. react-activity-calendar requires a minimum of one entry.

**How to avoid:**
- For recharts charts: conditional render — if `data.length === 0`, show empty state JSX instead of chart
- For react-activity-calendar: if no workouts in the last year, generate the full year with all `count: 0, level: 0` entries (the component still renders, showing an empty calendar)

**Warning signs:** Console errors on the progress page before any workouts logged.

### Pitfall 3: Epley formula accuracy above 10 reps

**What goes wrong:** Epley formula significantly overestimates 1RM for high-rep sets (15+ reps). A 135lb x 20 reps yields a nonsensical "225 lbs 1RM."

**How to avoid:** Clamp reps at 10 before applying Epley: `Math.min(actualReps, 10)`. Or use only sets where `actualReps <= 5` for 1RM estimation.

**Warning signs:** 1RM chart shows wildly high values after accessory/endurance sets.

### Pitfall 4: react-activity-calendar date ordering requirement

**What goes wrong:** Data passed to ActivityCalendar is not sorted by date → component renders incorrectly or throws.

**How to avoid:** Always sort the data array ascending by date string before passing: `.sort((a, b) => a.date.localeCompare(b.date))`

### Pitfall 5: Recharts 3.x Tooltip type changes

**What goes wrong:** `Tooltip` formatter TypeScript types changed between recharts 2 and 3. The `formatter` prop has a different signature.

**How to avoid:** Use `formatter={(value: number) => [value.toLocaleString(), 'label']}` (tuple return). Don't pass just a string — recharts 3 expects `[formattedValue, name]` tuple.

### Pitfall 6: Progress page needs exercise picker but exercises come from DB, not a static list

**What goes wrong:** Defaulting to a hardcoded exercise ID in `useState('')` for the exercise selector causes the line chart to show empty state even when the user has data, if they trained a different exercise.

**How to avoid:** On mount, query `db.completedSets` for distinct `exerciseId` values, auto-select the first one. Only then render the line chart.

---

## Code Examples

### CHART-01: Full 1RM hook

```typescript
// src/hooks/use-1rm-progress.ts
import { useEffect, useState } from 'react';
import { db } from '@/lib/db/dexie';
import { format } from 'date-fns';

interface OneRMPoint {
  date: string;
  estimated1RM: number;
}

function epley(weight: number, reps: number): number {
  return weight * (1 + Math.min(reps, 10) / 30);
}

export function use1RMProgress(exerciseId: string) {
  const [data, setData] = useState<OneRMPoint[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!exerciseId) return;
    let isActive = true;

    void (async () => {
      // Get all sets for this exercise
      const sets = await db.completedSets
        .where('exerciseId').equals(exerciseId).toArray();

      // Get workout dates
      const workoutIds = [...new Set(sets.map(s => s.workoutId))];
      const workouts = await db.completedWorkouts
        .where('id').anyOf(workoutIds).toArray();
      const workoutDateMap = new Map(workouts.map(w => [w.id, w.completedAt]));

      // Group by workout, take max estimated 1RM
      const byWorkout = new Map<string, { date: Date; max1RM: number }>();
      for (const set of sets) {
        const date = workoutDateMap.get(set.workoutId);
        if (!date) continue;
        const estimated = epley(set.actualWeight, set.actualReps);
        const existing = byWorkout.get(set.workoutId);
        if (!existing || estimated > existing.max1RM) {
          byWorkout.set(set.workoutId, { date, max1RM: estimated });
        }
      }

      const result: OneRMPoint[] = Array.from(byWorkout.values())
        .sort((a, b) => a.date.getTime() - b.date.getTime())
        .map(entry => ({
          date: format(entry.date, 'MMM d'),
          estimated1RM: Math.round(entry.max1RM),
        }));

      if (isActive) {
        setData(result);
        setLoading(false);
      }
    })();

    return () => { isActive = false; };
  }, [exerciseId]);

  return { data, loading };
}
```

### CHART-02: Weekly volume hook

```typescript
// src/hooks/use-weekly-volume.ts
import { useEffect, useState } from 'react';
import { db } from '@/lib/db/dexie';
import { startOfWeek, format } from 'date-fns';

interface WeeklyVolumePoint {
  week: string;       // 'Jan 6'
  weekKey: string;    // 'YYYY-MM-DD' for sorting
  volume: number;     // lbs total
}

export function useWeeklyVolume() {
  const [data, setData] = useState<WeeklyVolumePoint[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let isActive = true;

    void (async () => {
      const workouts = await db.completedWorkouts.toArray();
      const workoutDateMap = new Map(workouts.map(w => [w.id, w.completedAt]));
      const sets = await db.completedSets.toArray();

      const weeklyMap = new Map<string, number>();
      for (const set of sets) {
        const date = workoutDateMap.get(set.workoutId);
        if (!date) continue;
        const weekStart = startOfWeek(date, { weekStartsOn: 1 });
        const key = format(weekStart, 'yyyy-MM-dd');
        weeklyMap.set(key, (weeklyMap.get(key) ?? 0) + set.actualWeight * set.actualReps);
      }

      const result: WeeklyVolumePoint[] = Array.from(weeklyMap.entries())
        .sort(([a], [b]) => a.localeCompare(b))
        .slice(-12) // show last 12 weeks
        .map(([key, volume]) => ({
          weekKey: key,
          week: format(new Date(key), 'MMM d'),
          volume: Math.round(volume),
        }));

      if (isActive) {
        setData(result);
        setLoading(false);
      }
    })();

    return () => { isActive = false; };
  }, []);

  return { data, loading };
}
```

### CHART-03: Heatmap hook

```typescript
// src/hooks/use-workout-frequency.ts
import { useEffect, useState } from 'react';
import { db } from '@/lib/db/dexie';
import { format, subYears, eachDayOfInterval } from 'date-fns';

interface Activity {
  date: string;
  count: number;
  level: 0 | 1 | 2 | 3 | 4;
}

export function useWorkoutFrequency() {
  const [data, setData] = useState<Activity[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let isActive = true;

    void (async () => {
      const workouts = await db.completedWorkouts.toArray();
      const countByDate = new Map<string, number>();
      for (const w of workouts) {
        const key = format(w.completedAt, 'yyyy-MM-dd');
        countByDate.set(key, (countByDate.get(key) ?? 0) + 1);
      }

      const end = new Date();
      const start = subYears(end, 1);
      const allDays = eachDayOfInterval({ start, end });

      const result: Activity[] = allDays.map(day => {
        const key = format(day, 'yyyy-MM-dd');
        const count = countByDate.get(key) ?? 0;
        const level = (count === 0 ? 0 : count === 1 ? 1 : count === 2 ? 2 : count <= 4 ? 3 : 4) as 0|1|2|3|4;
        return { date: key, count, level };
      });

      if (isActive) {
        setData(result);
        setLoading(false);
      }
    })();

    return () => { isActive = false; };
  }, []);

  return { data, loading };
}
```

### Empty state pattern (used by all three charts)

```tsx
// Reusable for all three charts
function EmptyChartState({ message }: { message: string }) {
  return (
    <div className="flex flex-col items-center justify-center py-12 text-center text-muted-foreground">
      <p className="text-sm">{message}</p>
      <p className="text-xs mt-1">Complete some workouts to see data here</p>
    </div>
  );
}

// Usage:
if (!loading && data.length === 0) {
  return <EmptyChartState message="No 1RM data yet" />;
}
```

---

## Existing Code to Replace / Extend

### `src/components/progress/weight-progress-chart.tsx` — REPLACE

Current behavior: Queries `completedSets.orderBy('createdAt').limit(20)` and plots raw `actualWeight`. This is not a 1RM chart — it's a raw weight scatter.

Replace with: New `OneRMProgressChart` component using `use1RMProgress` hook with Epley calculation and exercise selector.

### `src/app/progress/page.tsx` — EXTEND

Current: Shows `WeightProgressChart` + `CycleFilter`. 

Extend with:
- Replace `WeightProgressChart` with `OneRMProgressChart`
- Add `WeeklyVolumeChart` card
- Add `WorkoutHeatmap` card

---

## State of the Art

| Old Approach | Current Approach | Impact |
|--------------|------------------|--------|
| Raw `actualWeight` plot | Epley estimated 1RM | Shows meaningful strength progress, not just heaviest set |
| Recharts 2.x Tooltip string return | Recharts 3.x `[value, label]` tuple | TypeScript type change - use tuple format |
| npm `react-github-contribution-calendar` (unmaintained) | `react-activity-calendar` | Actively maintained, React 19 compatible |

---

## Open Questions

1. **Exercise index needed on completedSets for performance**
   - What we know: `completedSets` is indexed by `workoutId` and `exerciseId` in Dexie schema
   - What's unclear: With many sets, `where('exerciseId').equals(exerciseId)` should be fast since the index exists
   - Recommendation: Use the existing index; no schema migration needed

2. **Recharts 3.x dark mode support**
   - What we know: Project uses `hsl(var(--primary))` and `hsl(var(--chart-N))` patterns in existing chart
   - What's unclear: No dark mode toggle exists in the app — `globals.css` has dark values but no toggle mechanism
   - Recommendation: Use CSS variable colors (they'll adapt automatically if dark mode is ever added)

3. **react-activity-calendar dark mode theming**
   - What we know: Component accepts `colorScheme="light"` and `theme={{ light: [...] }}`
   - Recommendation: Pass explicit theme using `--chart-N` CSS variable hex equivalents or Tailwind colors

---

## Sources

### Primary (HIGH confidence)
- Project codebase inspection: `package.json` (confirmed recharts 3.7.0, date-fns 4.1.0, dexie 4.3.0)
- `node_modules/recharts/package.json` — version 3.7.0 confirmed
- `node_modules/recharts/types/index.d.ts` — exported API verified (BarChart, LineChart, Bar, Line, etc.)
- `node_modules/date-fns/package.json` — version 4.1.0 confirmed
- `src/lib/db/dexie.ts` — database schema confirmed (completedSets indexed on exerciseId, completedWorkouts indexed on completedAt)
- `src/lib/db/index.ts` — available DB query functions confirmed
- `src/app/workout/[id]/page.tsx` — data persistence confirmed working (Phase 01 complete)

### Secondary (MEDIUM confidence)
- `npm info react-activity-calendar` — version 3.1.1, peerDeps React >=18 || >=19 (verified via npm CLI)
- `src/app/globals.css` — CSS chart variables `--chart-1` through `--chart-5` defined for both light/dark

### Tertiary (LOW confidence)
- Epley formula accuracy characteristics (training knowledge; well-established but verify if reps clamping strategy is appropriate for this app's use case)

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — packages inspected directly in node_modules
- Architecture: HIGH — based on existing codebase patterns + verified Dexie schema
- Pitfalls: HIGH for data join patterns (verified from schema), MEDIUM for Epley accuracy (training knowledge)
- Heatmap library: HIGH — npm CLI verified version + peer dep compatibility

**Research date:** 2026-02-18
**Valid until:** 2026-03-20 (recharts 3.x stable, react-activity-calendar 3.x stable)
