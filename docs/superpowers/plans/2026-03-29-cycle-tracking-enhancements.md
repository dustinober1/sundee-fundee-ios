# Cycle Tracking Enhancements Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Enhance the cycle tracking page with settings configuration, rich period logging, visual calendar, and phase-aware workout integration.

**Architecture:** All new UI lives on the existing `/cycle` page as new sections. New pure domain functions handle calendar data generation and phase summaries. Shared UI components (`CyclePhaseBanner`, `CycleAdjustmentToggle`) are used on workout/program pages. TDD for all domain logic.

**Tech Stack:** Next.js 16 App Router, TypeScript, Tailwind CSS 4, Vitest, Firebase Firestore

---

## File Structure

### New Files
| File | Responsibility |
|------|---------------|
| `web-app/src/lib/domain/cycle-calendar.ts` | Pure functions: `getPhaseForDay`, `getCycleCalendarData`, `getPhaseAdjustmentSummary`, `getPhaseExplanation` |
| `web-app/src/lib/domain/__tests__/cycle-calendar.test.ts` | Tests for all new domain functions |
| `web-app/src/app/(features)/cycle/cycle-phase-ribbon.tsx` | Server component: proportional phase bar with position marker |
| `web-app/src/app/(features)/cycle/cycle-calendar.tsx` | Client component: monthly calendar grid with phase colors |
| `web-app/src/app/(features)/cycle/cycle-settings-panel.tsx` | Client component: collapsible settings with range sliders |
| `web-app/src/components/ui/cycle-phase-banner.tsx` | Shared client component: phase banner for workout/program pages |
| `web-app/src/components/ui/cycle-adjustment-toggle.tsx` | Shared client component: toggle with educational explanation |

### Modified Files
| File | Changes |
|------|---------|
| `web-app/src/lib/domain/index.ts` | Add export for `cycle-calendar` |
| `web-app/src/app/(features)/cycle/actions.ts` | Add `saveCycleSettings`, enhance `logPeriod`, add shared `getCycleStatus` |
| `web-app/src/app/(features)/cycle/log-period-form.tsx` | Full rewrite: flow level, symptoms, end date, notes |
| `web-app/src/app/(features)/cycle/page.tsx` | New layout integrating all sections |
| `web-app/src/app/(features)/programs/[id]/page.tsx` | Add phase banner + adjusted exercise preview |
| `web-app/src/app/(features)/workouts/ai/page.tsx` | Add phase banner + toggle + educational callout |

---

### Task 1: Domain — `getPhaseForDay` and `getPhaseAdjustmentSummary`

**Files:**
- Create: `web-app/src/lib/domain/cycle-calendar.ts`
- Create: `web-app/src/lib/domain/__tests__/cycle-calendar.test.ts`
- Modify: `web-app/src/lib/domain/index.ts`

- [ ] **Step 1: Write failing tests for `getPhaseForDay`**

```typescript
// web-app/src/lib/domain/__tests__/cycle-calendar.test.ts
import { describe, it, expect } from "vitest";
import {
  getPhaseForDay,
  getPhaseAdjustmentSummary,
  getPhaseExplanation,
} from "../cycle-calendar";
import type { CycleSettings } from "../cycle-calculations";

const defaultSettings: CycleSettings = {
  averageCycleLengthDays: 28,
  averagePeriodLengthDays: 5,
  lutealPhaseLengthDays: 14,
};

describe("getPhaseForDay", () => {
  it("returns menstrual for day 1", () => {
    expect(getPhaseForDay(1, defaultSettings)).toBe("menstrual");
  });

  it("returns menstrual for day 5", () => {
    expect(getPhaseForDay(5, defaultSettings)).toBe("menstrual");
  });

  it("returns follicular for day 6", () => {
    expect(getPhaseForDay(6, defaultSettings)).toBe("follicular");
  });

  it("returns ovulation for day 13", () => {
    expect(getPhaseForDay(13, defaultSettings)).toBe("ovulation");
  });

  it("returns luteal for day 20", () => {
    expect(getPhaseForDay(20, defaultSettings)).toBe("luteal");
  });

  it("returns luteal for day 28", () => {
    expect(getPhaseForDay(28, defaultSettings)).toBe("luteal");
  });

  it("wraps days beyond cycle length", () => {
    expect(getPhaseForDay(29, defaultSettings)).toBe("menstrual");
  });

  it("handles day 0 by wrapping to last day", () => {
    expect(getPhaseForDay(0, defaultSettings)).toBe("luteal");
  });
});

describe("getPhaseAdjustmentSummary", () => {
  it("returns load +12% for ovulation", () => {
    const summary = getPhaseAdjustmentSummary("ovulation");
    expect(summary).toContain("+12%");
  });

  it("returns load -10% for menstrual", () => {
    const summary = getPhaseAdjustmentSummary("menstrual");
    expect(summary).toContain("-10%");
  });

  it("returns no change for follicular", () => {
    const summary = getPhaseAdjustmentSummary("follicular");
    expect(summary).toContain("baseline");
  });

  it("returns load -3% for luteal", () => {
    const summary = getPhaseAdjustmentSummary("luteal");
    expect(summary).toContain("-3%");
  });
});

describe("getPhaseExplanation", () => {
  it("returns non-empty string for each phase", () => {
    const phases = ["menstrual", "follicular", "ovulation", "luteal"] as const;
    for (const phase of phases) {
      const explanation = getPhaseExplanation(phase);
      expect(explanation.length).toBeGreaterThan(20);
    }
  });

  it("mentions recovery for menstrual", () => {
    expect(getPhaseExplanation("menstrual").toLowerCase()).toContain("recover");
  });

  it("mentions peak for ovulation", () => {
    expect(getPhaseExplanation("ovulation").toLowerCase()).toContain("peak");
  });
});
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd web-app && npx vitest run src/lib/domain/__tests__/cycle-calendar.test.ts`
Expected: FAIL — module `../cycle-calendar` not found

- [ ] **Step 3: Implement `getPhaseForDay`, `getPhaseAdjustmentSummary`, `getPhaseExplanation`**

```typescript
// web-app/src/lib/domain/cycle-calendar.ts
import type { CyclePhase } from "./types";
import { getPhaseBoundaries, type CycleSettings } from "./cycle-calculations";

// ---------------------------------------------------------------------------
// getPhaseForDay
// ---------------------------------------------------------------------------

export function getPhaseForDay(cycleDay: number, settings: CycleSettings): CyclePhase {
  const len = Math.max(1, settings.averageCycleLengthDays);
  let normalized = ((cycleDay - 1) % len + len) % len + 1;
  if (cycleDay <= 0) {
    normalized = len + cycleDay;
    if (normalized <= 0) normalized = ((normalized - 1) % len + len) % len + 1;
  }

  const boundaries = getPhaseBoundaries(settings);
  const phases: CyclePhase[] = ["menstrual", "follicular", "ovulation", "luteal"];

  for (const phase of phases) {
    const b = boundaries[phase];
    if (normalized >= b.start && normalized <= b.end) {
      return phase;
    }
  }

  return "luteal";
}

// ---------------------------------------------------------------------------
// getPhaseAdjustmentSummary
// ---------------------------------------------------------------------------

export function getPhaseAdjustmentSummary(phase: CyclePhase): string {
  switch (phase) {
    case "menstrual":
      return "Recovery focus — load -10%, volume -10%";
    case "follicular":
      return "Baseline — no adjustments, building phase";
    case "ovulation":
      return "Peak performance — load +12%, sets +5%";
    case "luteal":
      return "Maintenance — load -3%, volume -8%";
  }
}

// ---------------------------------------------------------------------------
// getPhaseExplanation
// ---------------------------------------------------------------------------

export function getPhaseExplanation(phase: CyclePhase): string {
  switch (phase) {
    case "menstrual":
      return "During menstruation, your body is actively recovering. Energy and iron levels may be lower, so we reduce load and volume to support recovery while keeping you active.";
    case "follicular":
      return "Rising estrogen supports muscle growth and endurance. This is your building phase — no adjustments needed, train at your normal capacity.";
    case "ovulation":
      return "Peak estrogen and testosterone create an optimal window for strength. Your body can handle higher loads and intensity — this is your time to push for PRs.";
    case "luteal":
      return "Progesterone rises, which may affect recovery and thermoregulation. We slightly reduce load and volume to match your body's shifting priorities. Toggle off if you're feeling strong.";
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `cd web-app && npx vitest run src/lib/domain/__tests__/cycle-calendar.test.ts`
Expected: All tests PASS

- [ ] **Step 5: Export from domain index**

Add to the end of `web-app/src/lib/domain/index.ts`:

```typescript
export * from "./cycle-calendar";
```

- [ ] **Step 6: Commit**

```bash
git add web-app/src/lib/domain/cycle-calendar.ts web-app/src/lib/domain/__tests__/cycle-calendar.test.ts web-app/src/lib/domain/index.ts
git commit -m "feat: add getPhaseForDay, getPhaseAdjustmentSummary, getPhaseExplanation domain functions"
```

---

### Task 2: Domain — `getCycleCalendarData`

**Files:**
- Modify: `web-app/src/lib/domain/cycle-calendar.ts`
- Modify: `web-app/src/lib/domain/__tests__/cycle-calendar.test.ts`

- [ ] **Step 1: Write failing tests for `getCycleCalendarData`**

Append to `web-app/src/lib/domain/__tests__/cycle-calendar.test.ts`:

```typescript
import { getCycleCalendarData } from "../cycle-calendar";
import type { PeriodLog } from "../cycle-calculations";

function localDate(year: number, month: number, day: number): Date {
  return new Date(year, month - 1, day);
}

describe("getCycleCalendarData", () => {
  it("returns entries for every day in the month", () => {
    const logs: PeriodLog[] = [{ startDate: localDate(2026, 3, 3) }];
    const data = getCycleCalendarData(logs, defaultSettings, 3, 2026);
    expect(data).toHaveLength(31); // March has 31 days
  });

  it("marks today correctly", () => {
    const today = new Date();
    const logs: PeriodLog[] = [{ startDate: localDate(today.getFullYear(), today.getMonth() + 1, 1) }];
    const data = getCycleCalendarData(logs, defaultSettings, today.getMonth() + 1, today.getFullYear());
    const todayEntry = data.find((d) => d.isToday);
    expect(todayEntry).toBeDefined();
    expect(todayEntry!.date.getDate()).toBe(today.getDate());
  });

  it("assigns a phase to each day", () => {
    const logs: PeriodLog[] = [{ startDate: localDate(2026, 3, 1) }];
    const data = getCycleCalendarData(logs, defaultSettings, 3, 2026);
    for (const entry of data) {
      expect(["menstrual", "follicular", "ovulation", "luteal"]).toContain(entry.phase);
    }
  });

  it("returns null phases when no period logs exist", () => {
    const data = getCycleCalendarData([], defaultSettings, 3, 2026);
    expect(data).toHaveLength(31);
    for (const entry of data) {
      expect(entry.phase).toBeNull();
    }
  });

  it("marks logged period days", () => {
    const logs: PeriodLog[] = [
      { startDate: localDate(2026, 3, 3), endDate: localDate(2026, 3, 7) },
    ];
    const data = getCycleCalendarData(logs, defaultSettings, 3, 2026);
    const loggedDays = data.filter((d) => d.isPeriodLogged);
    expect(loggedDays.length).toBe(5); // Mar 3-7
  });

  it("handles February correctly", () => {
    const logs: PeriodLog[] = [{ startDate: localDate(2026, 2, 1) }];
    const data = getCycleCalendarData(logs, defaultSettings, 2, 2026);
    expect(data).toHaveLength(28); // 2026 is not a leap year
  });
});
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd web-app && npx vitest run src/lib/domain/__tests__/cycle-calendar.test.ts`
Expected: FAIL — `getCycleCalendarData` not exported

- [ ] **Step 3: Implement `getCycleCalendarData`**

Add to `web-app/src/lib/domain/cycle-calendar.ts`:

```typescript
import { calculateCycleStatus, type PeriodLog } from "./cycle-calculations";

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

export interface CalendarDayData {
  date: Date;
  cycleDay: number | null;
  phase: CyclePhase | null;
  isToday: boolean;
  isPeriodLogged: boolean;
}

// ---------------------------------------------------------------------------
// getCycleCalendarData
// ---------------------------------------------------------------------------

export function getCycleCalendarData(
  periodLogs: PeriodLog[],
  settings: CycleSettings,
  month: number,
  year: number
): CalendarDayData[] {
  const today = new Date();
  const todayStr = `${today.getFullYear()}-${today.getMonth()}-${today.getDate()}`;
  const daysInMonth = new Date(year, month, 0).getDate();
  const result: CalendarDayData[] = [];

  for (let day = 1; day <= daysInMonth; day++) {
    const date = new Date(year, month - 1, day);
    const dateStr = `${date.getFullYear()}-${date.getMonth()}-${date.getDate()}`;
    const isToday = dateStr === todayStr;

    const status = calculateCycleStatus(periodLogs, settings, date);

    const isPeriodLogged = periodLogs.some((log) => {
      const start = new Date(log.startDate);
      start.setHours(0, 0, 0, 0);
      const end = log.endDate
        ? new Date(log.endDate)
        : new Date(start.getFullYear(), start.getMonth(), start.getDate() + settings.averagePeriodLengthDays - 1);
      end.setHours(23, 59, 59, 999);
      return date >= start && date <= end;
    });

    result.push({
      date,
      cycleDay: status?.cycleDay ?? null,
      phase: status?.currentPhase ?? null,
      isToday,
      isPeriodLogged,
    });
  }

  return result;
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `cd web-app && npx vitest run src/lib/domain/__tests__/cycle-calendar.test.ts`
Expected: All tests PASS

- [ ] **Step 5: Commit**

```bash
git add web-app/src/lib/domain/cycle-calendar.ts web-app/src/lib/domain/__tests__/cycle-calendar.test.ts
git commit -m "feat: add getCycleCalendarData for calendar view data generation"
```

---

### Task 3: Server Actions — `saveCycleSettings`, enhanced `logPeriod`, shared `getCycleStatus`

**Files:**
- Modify: `web-app/src/app/(features)/cycle/actions.ts`

- [ ] **Step 1: Rewrite `actions.ts` with all server actions**

Replace the contents of `web-app/src/app/(features)/cycle/actions.ts`:

```typescript
"use server";

import { getAuthUser, userCollection, userDoc } from "@/lib/firestore";
import { calculateCycleStatus } from "@/lib/domain";
import type { CycleSettings, CycleStatusResult } from "@/lib/domain";

// ---------------------------------------------------------------------------
// getPeriodLogs
// ---------------------------------------------------------------------------

export async function getPeriodLogs() {
  const user = await getAuthUser();
  if (!user) return [];

  const snapshot = await userCollection(user.uid, "periodLogs")
    .orderBy("startDate", "desc")
    .get();

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  return snapshot.docs.map((doc) => ({ id: doc.id, ...(doc.data() as any) }));
}

// ---------------------------------------------------------------------------
// getCycleSettings
// ---------------------------------------------------------------------------

export async function getCycleSettings() {
  const user = await getAuthUser();
  if (!user) return null;

  const doc = await userCollection(user.uid, "cycleSettings").doc("default").get();
  return doc.exists ? doc.data() : null;
}

// ---------------------------------------------------------------------------
// saveCycleSettings
// ---------------------------------------------------------------------------

export async function saveCycleSettings(settings: {
  averageCycleLengthDays: number;
  averagePeriodLengthDays: number;
  lutealPhaseLengthDays: number;
}) {
  const user = await getAuthUser();
  if (!user) throw new Error("Unauthorized");

  await userCollection(user.uid, "cycleSettings").doc("default").set(
    {
      averageCycleLengthDays: settings.averageCycleLengthDays,
      averagePeriodLengthDays: settings.averagePeriodLengthDays,
      lutealPhaseLengthDays: settings.lutealPhaseLengthDays,
      updatedAt: new Date(),
    },
    { merge: true }
  );
}

// ---------------------------------------------------------------------------
// logPeriod (enhanced)
// ---------------------------------------------------------------------------

export async function logPeriod(data: {
  startDate: string;
  endDate?: string;
  flowLevel: "light" | "medium" | "heavy";
  symptoms?: string[];
  notes?: string;
}) {
  const user = await getAuthUser();
  if (!user) throw new Error("Unauthorized");

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const doc: Record<string, any> = {
    startDate: new Date(data.startDate),
    flowLevel: data.flowLevel,
  };

  if (data.endDate) {
    doc.endDate = new Date(data.endDate);
  }
  if (data.symptoms && data.symptoms.length > 0) {
    doc.symptoms = data.symptoms;
  }
  if (data.notes && data.notes.trim().length > 0) {
    doc.notes = data.notes.trim();
  }

  await userCollection(user.uid, "periodLogs").add(doc);
}

// ---------------------------------------------------------------------------
// getCycleStatus (shared — usable from any page)
// ---------------------------------------------------------------------------

export async function getCycleStatus(): Promise<CycleStatusResult | null> {
  const user = await getAuthUser();
  if (!user) return null;

  const [logsSnap, settingsDoc] = await Promise.all([
    userCollection(user.uid, "periodLogs").orderBy("startDate", "desc").get(),
    userCollection(user.uid, "cycleSettings").doc("default").get(),
  ]);

  const settings: CycleSettings = {
    averageCycleLengthDays: (settingsDoc.data()?.averageCycleLengthDays as number) ?? 28,
    averagePeriodLengthDays: (settingsDoc.data()?.averagePeriodLengthDays as number) ?? 5,
    lutealPhaseLengthDays: (settingsDoc.data()?.lutealPhaseLengthDays as number) ?? 14,
  };

  const periodLogs = logsSnap.docs.map((doc) => {
    const d = doc.data();
    return {
      startDate: (d.startDate as { toDate(): Date }).toDate(),
      endDate: d.endDate ? (d.endDate as { toDate(): Date }).toDate() : undefined,
    };
  });

  return calculateCycleStatus(periodLogs, settings, new Date());
}
```

- [ ] **Step 2: Verify the build**

Run: `cd web-app && npx tsc --noEmit --pretty 2>&1 | head -20`
Expected: No errors related to `actions.ts`

- [ ] **Step 3: Commit**

```bash
git add web-app/src/app/(features)/cycle/actions.ts
git commit -m "feat: add saveCycleSettings, enhance logPeriod, add shared getCycleStatus action"
```

---

### Task 4: UI — Enhanced `LogPeriodForm`

**Files:**
- Modify: `web-app/src/app/(features)/cycle/log-period-form.tsx`

- [ ] **Step 1: Rewrite `log-period-form.tsx`**

```typescript
"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Card } from "@/components/ui/card";
import { SectionHeader } from "@/components/ui/art-deco";
import { logPeriod } from "./actions";

const FLOW_LEVELS = ["light", "medium", "heavy"] as const;
type FlowLevel = (typeof FLOW_LEVELS)[number];

const SYMPTOM_OPTIONS = [
  { value: "cramps", label: "Cramps" },
  { value: "headache", label: "Headache" },
  { value: "fatigue", label: "Fatigue" },
  { value: "bloating", label: "Bloating" },
  { value: "mood_changes", label: "Mood" },
  { value: "back_pain", label: "Back Pain" },
] as const;

export function LogPeriodForm() {
  const router = useRouter();
  const [startDate, setStartDate] = useState(() => new Date().toISOString().split("T")[0]);
  const [endDate, setEndDate] = useState("");
  const [flowLevel, setFlowLevel] = useState<FlowLevel>("medium");
  const [symptoms, setSymptoms] = useState<string[]>([]);
  const [notes, setNotes] = useState("");
  const [saving, setSaving] = useState(false);

  function toggleSymptom(value: string) {
    setSymptoms((prev) =>
      prev.includes(value) ? prev.filter((s) => s !== value) : [...prev, value]
    );
  }

  async function handleSubmit() {
    setSaving(true);
    try {
      await logPeriod({
        startDate,
        endDate: endDate || undefined,
        flowLevel,
        symptoms: symptoms.length > 0 ? symptoms : undefined,
        notes: notes || undefined,
      });
      // Reset form
      setEndDate("");
      setFlowLevel("medium");
      setSymptoms([]);
      setNotes("");
      router.refresh();
    } finally {
      setSaving(false);
    }
  }

  return (
    <Card>
      <SectionHeader label="Journal" title="Log Period" />

      <div className="mt-4 space-y-4">
        {/* Dates */}
        <div className="flex gap-3">
          <div className="flex-1">
            <label className="text-[11px] font-mono text-text-secondary uppercase tracking-wider mb-1 block">
              Start Date
            </label>
            <Input
              type="date"
              value={startDate}
              onChange={(e) => setStartDate(e.target.value)}
            />
          </div>
          <div className="flex-1">
            <label className="text-[11px] font-mono text-text-secondary uppercase tracking-wider mb-1 block">
              End Date
            </label>
            <Input
              type="date"
              value={endDate}
              onChange={(e) => setEndDate(e.target.value)}
              placeholder="Optional"
            />
          </div>
        </div>

        {/* Flow Level */}
        <div>
          <label className="text-[11px] font-mono text-text-secondary uppercase tracking-wider mb-2 block">
            Flow Level
          </label>
          <div className="grid grid-cols-3 gap-2">
            {FLOW_LEVELS.map((level) => (
              <button
                key={level}
                type="button"
                onClick={() => setFlowLevel(level)}
                className={`px-3 py-2.5 rounded-button text-[13px] font-medium border transition-all ${
                  flowLevel === level
                    ? "bg-orange text-cream border-orange shadow-sm shadow-orange/20"
                    : "bg-card-bg text-navy border-gold/15 hover:border-gold/40"
                }`}
              >
                {level.charAt(0).toUpperCase() + level.slice(1)}
              </button>
            ))}
          </div>
        </div>

        {/* Symptoms */}
        <div>
          <label className="text-[11px] font-mono text-text-secondary uppercase tracking-wider mb-2 block">
            Symptoms
          </label>
          <div className="flex flex-wrap gap-2">
            {SYMPTOM_OPTIONS.map((symptom) => (
              <button
                key={symptom.value}
                type="button"
                onClick={() => toggleSymptom(symptom.value)}
                className={`px-3 py-1.5 rounded-full text-[12px] font-medium border transition-all ${
                  symptoms.includes(symptom.value)
                    ? "bg-orange text-cream border-orange"
                    : "bg-card-bg text-text-secondary border-gold/15 hover:border-gold/40"
                }`}
              >
                {symptom.label}
              </button>
            ))}
          </div>
        </div>

        {/* Notes */}
        <div>
          <label className="text-[11px] font-mono text-text-secondary uppercase tracking-wider mb-1 block">
            Notes
          </label>
          <textarea
            value={notes}
            onChange={(e) => setNotes(e.target.value)}
            placeholder="Optional notes..."
            rows={2}
            className="w-full px-3.5 py-3 bg-card-bg border border-separator rounded-sm text-navy text-[15px] placeholder:text-text-secondary/50 focus:outline-none focus:ring-2 focus:ring-orange/40 focus:border-orange resize-none"
          />
        </div>

        <Button fullWidth disabled={saving || !startDate} onClick={handleSubmit}>
          {saving ? "Saving..." : "Log Period"}
        </Button>
      </div>
    </Card>
  );
}
```

- [ ] **Step 2: Verify the build**

Run: `cd web-app && npx tsc --noEmit --pretty 2>&1 | head -20`
Expected: No type errors

- [ ] **Step 3: Commit**

```bash
git add web-app/src/app/(features)/cycle/log-period-form.tsx
git commit -m "feat: enhance LogPeriodForm with flow level, symptoms, end date, and notes"
```

---

### Task 5: UI — `CycleSettingsPanel`

**Files:**
- Create: `web-app/src/app/(features)/cycle/cycle-settings-panel.tsx`

- [ ] **Step 1: Create the collapsible settings panel**

```typescript
// web-app/src/app/(features)/cycle/cycle-settings-panel.tsx
"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { SectionHeader } from "@/components/ui/art-deco";
import { saveCycleSettings } from "./actions";

interface CycleSettingsPanelProps {
  initialCycleLength: number;
  initialPeriodLength: number;
  initialLutealLength: number;
}

export function CycleSettingsPanel({
  initialCycleLength,
  initialPeriodLength,
  initialLutealLength,
}: CycleSettingsPanelProps) {
  const router = useRouter();
  const [open, setOpen] = useState(false);
  const [cycleLength, setCycleLength] = useState(initialCycleLength);
  const [periodLength, setPeriodLength] = useState(initialPeriodLength);
  const [lutealLength, setLutealLength] = useState(initialLutealLength);
  const [saving, setSaving] = useState(false);

  async function handleSave() {
    setSaving(true);
    try {
      await saveCycleSettings({
        averageCycleLengthDays: cycleLength,
        averagePeriodLengthDays: periodLength,
        lutealPhaseLengthDays: lutealLength,
      });
      router.refresh();
    } finally {
      setSaving(false);
    }
  }

  return (
    <Card>
      <button
        type="button"
        onClick={() => setOpen(!open)}
        className="w-full flex items-center justify-between"
      >
        <SectionHeader label="Configuration" title="Cycle Settings" />
        <svg
          className={`w-4 h-4 text-text-secondary transition-transform ${open ? "rotate-180" : ""}`}
          fill="none"
          viewBox="0 0 24 24"
          stroke="currentColor"
          strokeWidth={2}
        >
          <path strokeLinecap="round" strokeLinejoin="round" d="M19 9l-7 7-7-7" />
        </svg>
      </button>

      {open && (
        <div className="mt-4 space-y-5">
          <SliderField
            label="Cycle Length"
            value={cycleLength}
            min={21}
            max={45}
            unit="days"
            onChange={setCycleLength}
          />
          <SliderField
            label="Period Length"
            value={periodLength}
            min={2}
            max={10}
            unit="days"
            onChange={setPeriodLength}
          />
          <SliderField
            label="Luteal Phase"
            value={lutealLength}
            min={8}
            max={18}
            unit="days"
            onChange={setLutealLength}
          />
          <Button fullWidth disabled={saving} onClick={handleSave}>
            {saving ? "Saving..." : "Save Settings"}
          </Button>
        </div>
      )}
    </Card>
  );
}

function SliderField({
  label,
  value,
  min,
  max,
  unit,
  onChange,
}: {
  label: string;
  value: number;
  min: number;
  max: number;
  unit: string;
  onChange: (v: number) => void;
}) {
  return (
    <div>
      <div className="flex justify-between text-[13px] mb-2">
        <span className="text-navy">{label}</span>
        <span className="font-mono text-orange font-bold">
          {value} {unit}
        </span>
      </div>
      <input
        type="range"
        min={min}
        max={max}
        value={value}
        onChange={(e) => onChange(parseInt(e.target.value))}
        className="w-full accent-orange"
      />
    </div>
  );
}
```

- [ ] **Step 2: Verify the build**

Run: `cd web-app && npx tsc --noEmit --pretty 2>&1 | head -20`
Expected: No type errors

- [ ] **Step 3: Commit**

```bash
git add web-app/src/app/(features)/cycle/cycle-settings-panel.tsx
git commit -m "feat: add collapsible CycleSettingsPanel with range sliders"
```

---

### Task 6: UI — `CyclePhaseRibbon`

**Files:**
- Create: `web-app/src/app/(features)/cycle/cycle-phase-ribbon.tsx`

- [ ] **Step 1: Create the phase ribbon server component**

```typescript
// web-app/src/app/(features)/cycle/cycle-phase-ribbon.tsx
import { Card } from "@/components/ui/card";
import type { CyclePhase } from "@/lib/domain";
import type { CycleSettings } from "@/lib/domain";
import { getPhaseBoundaries } from "@/lib/domain";

const PHASE_RIBBON_COLORS: Record<CyclePhase, string> = {
  menstrual: "bg-warm-rose",
  follicular: "bg-gold",
  ovulation: "bg-orange",
  luteal: "bg-navy",
};

const PHASE_LABELS: Record<CyclePhase, string> = {
  menstrual: "Menstrual",
  follicular: "Follicular",
  ovulation: "Ov",
  luteal: "Luteal",
};

interface CyclePhaseRibbonProps {
  cycleDay: number;
  settings: CycleSettings;
}

export function CyclePhaseRibbon({ cycleDay, settings }: CyclePhaseRibbonProps) {
  const boundaries = getPhaseBoundaries(settings);
  const phases: CyclePhase[] = ["menstrual", "follicular", "ovulation", "luteal"];
  const totalDays = settings.averageCycleLengthDays;

  return (
    <Card>
      <div className="flex gap-0.5 h-7 rounded-md overflow-hidden">
        {phases.map((phase) => {
          const b = boundaries[phase];
          const width = ((b.end - b.start + 1) / totalDays) * 100;
          return (
            <div
              key={phase}
              className={`${PHASE_RIBBON_COLORS[phase]} flex items-center justify-center relative`}
              style={{ width: `${width}%` }}
            >
              <span className="text-[9px] font-semibold text-white/90 uppercase tracking-wide">
                {PHASE_LABELS[phase]}
              </span>
            </div>
          );
        })}
      </div>
      <div className="flex justify-between mt-1.5 text-[10px] text-text-secondary">
        <span>Day 1</span>
        <span className="text-orange font-semibold">
          ▲ Day {cycleDay}
        </span>
        <span>Day {totalDays}</span>
      </div>
    </Card>
  );
}
```

- [ ] **Step 2: Verify the build**

Run: `cd web-app && npx tsc --noEmit --pretty 2>&1 | head -20`
Expected: No type errors

- [ ] **Step 3: Commit**

```bash
git add web-app/src/app/(features)/cycle/cycle-phase-ribbon.tsx
git commit -m "feat: add CyclePhaseRibbon server component"
```

---

### Task 7: UI — `CycleCalendar`

**Files:**
- Create: `web-app/src/app/(features)/cycle/cycle-calendar.tsx`

- [ ] **Step 1: Create the calendar client component**

```typescript
// web-app/src/app/(features)/cycle/cycle-calendar.tsx
"use client";

import { useState } from "react";
import { Card } from "@/components/ui/card";
import { SectionHeader } from "@/components/ui/art-deco";
import type { CyclePhase } from "@/lib/domain";
import type { CalendarDayData } from "@/lib/domain";
import { getCycleCalendarData } from "@/lib/domain";
import type { CycleSettings, PeriodLog } from "@/lib/domain";

const PHASE_DAY_BG: Record<CyclePhase, string> = {
  menstrual: "bg-warm-rose text-white",
  follicular: "bg-gold/30 text-navy",
  ovulation: "bg-orange/30 text-navy",
  luteal: "bg-navy/10 text-navy",
};

const PHASE_LEGEND: { phase: CyclePhase; label: string; color: string }[] = [
  { phase: "menstrual", label: "Menstrual", color: "bg-warm-rose" },
  { phase: "follicular", label: "Follicular", color: "bg-gold/50" },
  { phase: "ovulation", label: "Ovulation", color: "bg-orange/50" },
  { phase: "luteal", label: "Luteal", color: "bg-navy/20" },
];

const DAY_HEADERS = ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"];

interface CycleCalendarProps {
  periodLogs: PeriodLog[];
  settings: CycleSettings;
}

export function CycleCalendar({ periodLogs, settings }: CycleCalendarProps) {
  const now = new Date();
  const [month, setMonth] = useState(now.getMonth() + 1);
  const [year, setYear] = useState(now.getFullYear());

  const data = getCycleCalendarData(periodLogs, settings, month, year);

  // First day of month's weekday (0=Sun)
  const firstDayOfWeek = new Date(year, month - 1, 1).getDay();

  function prevMonth() {
    if (month === 1) {
      setMonth(12);
      setYear(year - 1);
    } else {
      setMonth(month - 1);
    }
  }

  function nextMonth() {
    if (month === 12) {
      setMonth(1);
      setYear(year + 1);
    } else {
      setMonth(month + 1);
    }
  }

  const monthName = new Date(year, month - 1).toLocaleString("default", { month: "long" });

  return (
    <Card>
      {/* Header with navigation */}
      <div className="flex items-center justify-between mb-3">
        <button
          type="button"
          onClick={prevMonth}
          className="w-8 h-8 flex items-center justify-center rounded-full hover:bg-separator/30 transition-colors text-text-secondary"
        >
          <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
            <path strokeLinecap="round" strokeLinejoin="round" d="M15 19l-7-7 7-7" />
          </svg>
        </button>
        <h3 className="font-heading font-bold text-[15px]">
          {monthName} {year}
        </h3>
        <button
          type="button"
          onClick={nextMonth}
          className="w-8 h-8 flex items-center justify-center rounded-full hover:bg-separator/30 transition-colors text-text-secondary"
        >
          <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
            <path strokeLinecap="round" strokeLinejoin="round" d="M9 5l7 7-7 7" />
          </svg>
        </button>
      </div>

      {/* Day headers */}
      <div className="grid grid-cols-7 gap-1 text-center mb-1">
        {DAY_HEADERS.map((d) => (
          <div key={d} className="text-[9px] font-mono text-text-secondary uppercase tracking-wider py-1">
            {d}
          </div>
        ))}
      </div>

      {/* Calendar grid */}
      <div className="grid grid-cols-7 gap-1">
        {/* Empty cells for offset */}
        {Array.from({ length: firstDayOfWeek }).map((_, i) => (
          <div key={`empty-${i}`} />
        ))}

        {data.map((entry) => (
          <CalendarDay key={entry.date.getDate()} entry={entry} />
        ))}
      </div>

      {/* Legend */}
      <div className="flex gap-3 justify-center mt-3 pt-3 border-t border-separator/30">
        {PHASE_LEGEND.map((item) => (
          <div key={item.phase} className="flex items-center gap-1">
            <div className={`w-2 h-2 rounded-sm ${item.color}`} />
            <span className="text-[9px] text-text-secondary">{item.label}</span>
          </div>
        ))}
      </div>
    </Card>
  );
}

function CalendarDay({ entry }: { entry: CalendarDayData }) {
  const dayNum = entry.date.getDate();
  const phaseClass = entry.phase ? PHASE_DAY_BG[entry.phase] : "text-text-secondary/40";
  const todayRing = entry.isToday ? "ring-2 ring-orange ring-offset-1" : "";

  return (
    <div
      className={`aspect-square flex items-center justify-center rounded-md text-[11px] font-medium ${phaseClass} ${todayRing}`}
    >
      {dayNum}
    </div>
  );
}
```

- [ ] **Step 2: Verify the build**

Run: `cd web-app && npx tsc --noEmit --pretty 2>&1 | head -20`
Expected: No type errors

- [ ] **Step 3: Commit**

```bash
git add web-app/src/app/(features)/cycle/cycle-calendar.tsx
git commit -m "feat: add CycleCalendar client component with monthly grid and phase colors"
```

---

### Task 8: UI — Shared `CyclePhaseBanner` and `CycleAdjustmentToggle`

**Files:**
- Create: `web-app/src/components/ui/cycle-phase-banner.tsx`
- Create: `web-app/src/components/ui/cycle-adjustment-toggle.tsx`

- [ ] **Step 1: Create `CyclePhaseBanner`**

```typescript
// web-app/src/components/ui/cycle-phase-banner.tsx
"use client";

import { useState } from "react";
import type { CyclePhase } from "@/lib/domain";

const PHASE_STYLES: Record<CyclePhase, { bg: string; border: string; text: string; icon: string }> = {
  menstrual: {
    bg: "from-warm-rose/10 to-warm-rose/5",
    border: "border-warm-rose/25",
    text: "text-warm-rose",
    icon: "🩸",
  },
  follicular: {
    bg: "from-gold/10 to-gold/5",
    border: "border-gold/25",
    text: "text-gold",
    icon: "🌱",
  },
  ovulation: {
    bg: "from-orange/10 to-orange/5",
    border: "border-orange/25",
    text: "text-orange",
    icon: "⚡",
  },
  luteal: {
    bg: "from-navy/8 to-navy/3",
    border: "border-navy/15",
    text: "text-navy",
    icon: "🌙",
  },
};

interface CyclePhaseBannerProps {
  phase: CyclePhase;
  cycleDay: number;
  adjustmentSummary: string;
}

export function CyclePhaseBanner({ phase, cycleDay, adjustmentSummary }: CyclePhaseBannerProps) {
  const [hidden, setHidden] = useState(false);
  const style = PHASE_STYLES[phase];

  if (hidden) return null;

  const phaseName = phase.charAt(0).toUpperCase() + phase.slice(1);

  return (
    <div className={`bg-gradient-to-r ${style.bg} border ${style.border} rounded-xl p-3 flex items-center gap-3`}>
      <div className={`w-8 h-8 rounded-full bg-white/60 flex items-center justify-center flex-shrink-0`}>
        <span className="text-sm">{style.icon}</span>
      </div>
      <div className="flex-1 min-w-0">
        <p className={`text-[11px] font-semibold ${style.text}`}>
          {phaseName} Phase · Day {cycleDay}
        </p>
        <p className="text-[10px] text-text-secondary mt-0.5 truncate">
          {adjustmentSummary}
        </p>
      </div>
      <button
        type="button"
        onClick={() => setHidden(true)}
        className="text-[9px] text-text-secondary underline flex-shrink-0"
      >
        Hide
      </button>
    </div>
  );
}
```

- [ ] **Step 2: Create `CycleAdjustmentToggle`**

```typescript
// web-app/src/components/ui/cycle-adjustment-toggle.tsx
"use client";

import type { CyclePhase } from "@/lib/domain";
import { getPhaseExplanation } from "@/lib/domain";

interface CycleAdjustmentToggleProps {
  phase: CyclePhase;
  enabled: boolean;
  onToggle: () => void;
}

export function CycleAdjustmentToggle({ phase, enabled, onToggle }: CycleAdjustmentToggleProps) {
  const explanation = getPhaseExplanation(phase);

  return (
    <div className="space-y-3">
      <div className="bg-card-bg border border-separator rounded-xl p-3 flex items-center justify-between gap-3">
        <div className="min-w-0">
          <p className="text-[12px] font-medium text-navy">Cycle-aware adjustments</p>
          <p className="text-[10px] text-text-secondary mt-0.5">
            {enabled ? "Active — weights and volume adjusted" : "Disabled — using base values"}
          </p>
        </div>
        <button
          type="button"
          onClick={onToggle}
          className={`w-10 h-[22px] rounded-full transition-colors flex-shrink-0 relative ${
            enabled ? "bg-orange" : "bg-separator"
          }`}
        >
          <div
            className={`w-[18px] h-[18px] bg-white rounded-full absolute top-[2px] transition-all ${
              enabled ? "right-[2px]" : "left-[2px]"
            }`}
          />
        </button>
      </div>

      {enabled && (
        <div className="bg-navy/[0.03] border-l-[3px] border-l-navy rounded-r-lg p-3">
          <p className="text-[11px] text-navy font-semibold mb-1">Why the adjustment?</p>
          <p className="text-[11px] text-text-secondary leading-relaxed">{explanation}</p>
        </div>
      )}
    </div>
  );
}
```

- [ ] **Step 3: Verify the build**

Run: `cd web-app && npx tsc --noEmit --pretty 2>&1 | head -20`
Expected: No type errors

- [ ] **Step 4: Commit**

```bash
git add web-app/src/components/ui/cycle-phase-banner.tsx web-app/src/components/ui/cycle-adjustment-toggle.tsx
git commit -m "feat: add shared CyclePhaseBanner and CycleAdjustmentToggle components"
```

---

### Task 9: Assemble the Enhanced Cycle Page

**Files:**
- Modify: `web-app/src/app/(features)/cycle/page.tsx`

- [ ] **Step 1: Rewrite `page.tsx` with all sections**

```typescript
// web-app/src/app/(features)/cycle/page.tsx
import { Card } from "@/components/ui/card";
import { PageHeader, SectionHeader, ArtDecoRuleSmall } from "@/components/ui/art-deco";
import { getPeriodLogs, getCycleSettings } from "./actions";
import { calculateCycleStatus, getPhaseRecommendation } from "@/lib/domain";
import type { CycleSettings, PeriodLog } from "@/lib/domain";
import { LogPeriodForm } from "./log-period-form";
import { CyclePhaseRibbon } from "./cycle-phase-ribbon";
import { CycleCalendar } from "./cycle-calendar";
import { CycleSettingsPanel } from "./cycle-settings-panel";

const PHASE_COLORS: Record<string, string> = {
  menstrual: "text-warm-rose",
  follicular: "text-gold",
  ovulation: "text-orange",
  luteal: "text-text-secondary",
};

const PHASE_BG: Record<string, string> = {
  menstrual: "from-warm-rose/10",
  follicular: "from-gold/10",
  ovulation: "from-orange/10",
  luteal: "from-navy/5",
};

const SYMPTOM_LABELS: Record<string, string> = {
  cramps: "Cramps",
  headache: "Headache",
  fatigue: "Fatigue",
  bloating: "Bloating",
  mood_changes: "Mood",
  back_pain: "Back Pain",
};

export default async function CyclePage() {
  const [logs, settingsData] = await Promise.all([getPeriodLogs(), getCycleSettings()]);

  const cycleConfig: CycleSettings = {
    averageCycleLengthDays: (settingsData?.averageCycleLengthDays as number) ?? 28,
    averagePeriodLengthDays: (settingsData?.averagePeriodLengthDays as number) ?? 5,
    lutealPhaseLengthDays: (settingsData?.lutealPhaseLengthDays as number) ?? 14,
  };

  const periodEntries: PeriodLog[] = logs.map((l: Record<string, unknown>) => ({
    startDate: new Date(l.startDate as string),
    endDate: l.endDate ? new Date(l.endDate as string) : undefined,
  }));

  const status = calculateCycleStatus(periodEntries, cycleConfig, new Date());

  return (
    <div className="flex flex-col gap-8 pt-4">
      <PageHeader label="Wellness" title="Cycle Tracking" />

      {status ? (
        <>
          {/* Phase Ribbon */}
          <CyclePhaseRibbon cycleDay={status.cycleDay} settings={cycleConfig} />

          {/* Calendar */}
          <CycleCalendar periodLogs={periodEntries} settings={cycleConfig} />

          {/* Current Phase Card */}
          <Card className="text-center overflow-hidden relative">
            <div className={`absolute inset-0 bg-gradient-to-b ${PHASE_BG[status.currentPhase] ?? "from-navy/5"} to-transparent`} />
            <div className="relative">
              <h2 className={`text-xl font-heading font-bold ${PHASE_COLORS[status.currentPhase] ?? ""}`}>
                {status.currentPhase.charAt(0).toUpperCase() + status.currentPhase.slice(1)} Phase
              </h2>
              <p className="text-text-secondary text-[13px] mt-1">
                Day {status.cycleDay} · {status.daysUntilNextPhase} days until next phase
              </p>
            </div>
          </Card>

          {/* Training Recommendation */}
          {(() => {
            const rec = getPhaseRecommendation(status.currentPhase);
            return (
              <Card>
                <SectionHeader label="Guidance" title="Training Recommendation" />
                <div className="mt-3 space-y-2">
                  <p className="text-[13px] text-text-secondary">{rec.description}</p>
                  <div className="border-t border-separator/30 pt-3 space-y-1.5">
                    <p className="text-[13px]">
                      <strong className="font-mono text-[11px] text-gold uppercase tracking-wider">Focus:</strong>{" "}
                      {rec.trainingFocus}
                    </p>
                    <p className="text-[13px]">
                      <strong className="font-mono text-[11px] text-gold uppercase tracking-wider">Intensity:</strong>{" "}
                      {rec.intensityRecommendation}
                    </p>
                    {rec.exercisesToEmphasize.length > 0 && (
                      <p className="text-[13px]">
                        <strong className="font-mono text-[11px] text-gold uppercase tracking-wider">Emphasize:</strong>{" "}
                        {rec.exercisesToEmphasize.join(", ")}
                      </p>
                    )}
                  </div>
                </div>
              </Card>
            );
          })()}
        </>
      ) : (
        <Card>
          <div className="text-center py-8">
            <div className="text-gold/30 mb-4">
              <svg className="w-12 h-12 mx-auto" fill="none" viewBox="0 0 48 48" stroke="currentColor" strokeWidth={1}>
                <circle cx="24" cy="24" r="20" />
                <path d="M24 4 C30 16, 30 32, 24 44" />
                <path d="M24 4 C18 16, 18 32, 24 44" />
                <ellipse cx="24" cy="24" rx="20" ry="8" />
              </svg>
            </div>
            <p className="text-text-secondary text-[13px]">
              Log your first period to start tracking your cycle.
            </p>
          </div>
        </Card>
      )}

      <ArtDecoRuleSmall className="text-gold/30 mx-auto" />

      {/* Log Period Form */}
      <LogPeriodForm />

      {/* Cycle Settings */}
      <CycleSettingsPanel
        initialCycleLength={cycleConfig.averageCycleLengthDays}
        initialPeriodLength={cycleConfig.averagePeriodLengthDays}
        initialLutealLength={cycleConfig.lutealPhaseLengthDays}
      />

      {/* Period History */}
      {logs.length > 0 && (
        <Card>
          <SectionHeader label="Records" title="Period History" />
          <div className="flex flex-col gap-0 mt-3">
            {logs.slice(0, 10).map((l: Record<string, unknown>) => {
              const start = new Date(l.startDate as string);
              const end = l.endDate ? new Date(l.endDate as string) : null;
              const flow = (l.flowLevel as string) ?? "medium";
              const symptoms = (l.symptoms as string[]) ?? [];
              const startStr = start.toLocaleDateString("en-US", { month: "short", day: "numeric" });
              const endStr = end
                ? end.toLocaleDateString("en-US", { month: "short", day: "numeric" })
                : null;

              return (
                <div
                  key={l.id as string}
                  className="flex justify-between items-start text-[13px] py-3 border-b border-separator/30 last:border-0"
                >
                  <div>
                    <p className="font-medium">
                      {startStr}
                      {endStr ? ` – ${endStr}` : ""}
                    </p>
                    <div className="flex items-center gap-1.5 mt-1">
                      <span className="text-[10px] px-1.5 py-0.5 rounded-full bg-warm-rose/10 text-warm-rose font-mono">
                        {flow}
                      </span>
                      {symptoms.length > 0 && (
                        <span className="text-[10px] text-text-secondary">
                          {symptoms.map((s) => SYMPTOM_LABELS[s] ?? s).join(", ")}
                        </span>
                      )}
                    </div>
                  </div>
                  {end && (
                    <span className="text-text-secondary font-mono text-[11px]">
                      {Math.round((end.getTime() - start.getTime()) / (1000 * 60 * 60 * 24)) + 1} days
                    </span>
                  )}
                </div>
              );
            })}
          </div>
        </Card>
      )}
    </div>
  );
}
```

- [ ] **Step 2: Verify the build**

Run: `cd web-app && npx tsc --noEmit --pretty 2>&1 | head -20`
Expected: No type errors

- [ ] **Step 3: Run all domain tests to ensure nothing is broken**

Run: `cd web-app && npx vitest run`
Expected: All tests PASS

- [ ] **Step 4: Commit**

```bash
git add web-app/src/app/(features)/cycle/page.tsx
git commit -m "feat: assemble enhanced cycle page with ribbon, calendar, settings, and rich history"
```

---

### Task 10: Integrate Phase Banner into Program Detail Page

**Files:**
- Modify: `web-app/src/app/(features)/programs/[id]/page.tsx`

- [ ] **Step 1: Add phase banner and adjusted exercise values**

Modify `web-app/src/app/(features)/programs/[id]/page.tsx`. Add imports at the top:

```typescript
import { getCycleStatus } from "@/app/(features)/cycle/actions";
import { getPhaseAdjustmentSummary, applyPhaseAdjustment, resolveReadinessTier, resolveConfidence } from "@/lib/domain";
import { CyclePhaseBanner } from "@/components/ui/cycle-phase-banner";
```

In the component function, after `const program = generateProgram(...)`, add:

```typescript
  const cycleStatus = await getCycleStatus();
```

After the `<EnrollButton>` and before `<ArtDecoRuleSmall>`, add the phase banner:

```typescript
      {cycleStatus && (
        <CyclePhaseBanner
          phase={cycleStatus.currentPhase}
          cycleDay={cycleStatus.cycleDay}
          adjustmentSummary={getPhaseAdjustmentSummary(cycleStatus.currentPhase)}
        />
      )}
```

In the Week 1 preview section, replace the exercise rendering. Change:

```typescript
              {session.exercises.map((ex, i) => (
                <div key={i} className="flex justify-between text-[13px] py-2 border-b border-separator/30 last:border-0">
                  <span>{ex.exercise}</span>
                  <span className="text-text-secondary font-mono">
                    {exerciseValueToString(ex.sets)}×{exerciseValueToString(ex.reps)}
                    {ex.percent1RM ? ` @ ${Math.round(ex.percent1RM * 100)}%` : ""}
                  </span>
                </div>
              ))}
```

to:

```typescript
              {session.exercises.map((ex, i) => {
                const adjusted = cycleStatus
                  ? applyPhaseAdjustment(
                      ex,
                      cycleStatus.currentPhase,
                      resolveReadinessTier(null),
                      resolveConfidence(cycleStatus.currentPhase, null, 1, null)
                    )
                  : ex;
                const originalPct = ex.percent1RM ? Math.round(ex.percent1RM * 100) : null;
                const adjustedPct = adjusted.percent1RM ? Math.round(adjusted.percent1RM * 100) : null;
                const changed = originalPct !== null && adjustedPct !== null && originalPct !== adjustedPct;

                return (
                  <div key={i} className="flex justify-between text-[13px] py-2 border-b border-separator/30 last:border-0">
                    <span>{ex.exercise}</span>
                    <div className="text-right">
                      <span className="text-text-secondary font-mono">
                        {exerciseValueToString(adjusted.sets)}×{exerciseValueToString(adjusted.reps)}
                        {adjustedPct ? ` @ ${adjustedPct}%` : ""}
                      </span>
                      {changed && (
                        <div className="text-[9px] text-orange mt-0.5">
                          {adjustedPct! > originalPct! ? "↑" : "↓"} was {originalPct}%
                        </div>
                      )}
                    </div>
                  </div>
                );
              })}
```

- [ ] **Step 2: Verify the build**

Run: `cd web-app && npx tsc --noEmit --pretty 2>&1 | head -20`
Expected: No type errors

- [ ] **Step 3: Commit**

```bash
git add web-app/src/app/(features)/programs/[id]/page.tsx
git commit -m "feat: add cycle phase banner and adjusted exercise values to program detail page"
```

---

### Task 11: Integrate Phase Banner and Toggle into AI Workout Page

**Files:**
- Modify: `web-app/src/app/(features)/workouts/ai/page.tsx`

- [ ] **Step 1: Add phase banner, toggle, and cycle-aware generation**

In `web-app/src/app/(features)/workouts/ai/page.tsx`, add imports:

```typescript
import { CyclePhaseBanner } from "@/components/ui/cycle-phase-banner";
import { CycleAdjustmentToggle } from "@/components/ui/cycle-adjustment-toggle";
import { getPhaseAdjustmentSummary } from "@/lib/domain";
import type { CyclePhase } from "@/lib/domain";
```

Add state variables inside the component, after the existing state declarations:

```typescript
  const [cyclePhase, setCyclePhase] = useState<CyclePhase | null>(null);
  const [cycleDay, setCycleDay] = useState<number>(0);
  const [cycleAdjustments, setCycleAdjustments] = useState(true);
```

Add a `useEffect` to fetch cycle status on mount (add `useEffect` to the React import):

```typescript
  useEffect(() => {
    async function fetchCycleStatus() {
      try {
        const res = await fetch("/api/cycle/status");
        if (res.ok) {
          const data = await res.json() as { currentPhase: CyclePhase; cycleDay: number } | null;
          if (data) {
            setCyclePhase(data.currentPhase);
            setCycleDay(data.cycleDay);
          }
        }
      } catch {
        // Cycle tracking not available — continue without
      }
    }
    fetchCycleStatus();
  }, []);
```

In the `generate` function, add `cyclePhase` to the request body when adjustments are enabled:

```typescript
        body: JSON.stringify({
          time,
          focus,
          energy,
          equipment,
          cyclePhase: cycleAdjustments ? cyclePhase : undefined,
        }),
```

In the questionnaire return JSX, after the error card and before the first `<Card>`, add:

```typescript
      {cyclePhase && (
        <>
          <CyclePhaseBanner
            phase={cyclePhase}
            cycleDay={cycleDay}
            adjustmentSummary={getPhaseAdjustmentSummary(cyclePhase)}
          />
          <CycleAdjustmentToggle
            phase={cyclePhase}
            enabled={cycleAdjustments}
            onToggle={() => setCycleAdjustments(!cycleAdjustments)}
          />
        </>
      )}
```

- [ ] **Step 2: Create the cycle status API route**

Create `web-app/src/app/api/cycle/status/route.ts`:

```typescript
import { NextResponse } from "next/server";
import { getCycleStatus } from "@/app/(features)/cycle/actions";

export async function GET() {
  const status = await getCycleStatus();
  if (!status) {
    return NextResponse.json(null);
  }
  return NextResponse.json({
    currentPhase: status.currentPhase,
    cycleDay: status.cycleDay,
    daysUntilNextPhase: status.daysUntilNextPhase,
  });
}
```

- [ ] **Step 3: Verify the build**

Run: `cd web-app && npx tsc --noEmit --pretty 2>&1 | head -20`
Expected: No type errors

- [ ] **Step 4: Run all tests**

Run: `cd web-app && npx vitest run`
Expected: All tests PASS

- [ ] **Step 5: Commit**

```bash
git add web-app/src/app/(features)/workouts/ai/page.tsx web-app/src/app/api/cycle/status/route.ts
git commit -m "feat: add cycle phase banner, adjustment toggle, and educational callout to AI workout page"
```

---

### Task 12: Final Verification

- [ ] **Step 1: Run all domain tests**

Run: `cd web-app && npx vitest run`
Expected: All tests PASS

- [ ] **Step 2: Run the linter**

Run: `cd web-app && npm run lint`
Expected: No errors (warnings are OK)

- [ ] **Step 3: Run the build**

Run: `cd web-app && npm run build`
Expected: Build succeeds

- [ ] **Step 4: Final commit if any lint/build fixes were needed**

```bash
git add -A
git commit -m "fix: address lint and build issues from cycle tracking enhancements"
```
