# Cycle Tracking Enhancements Design

## Summary

Enhance the existing `/cycle` page with 4 features: cycle settings configuration, enhanced period logging with symptoms, a visual cycle calendar, and phase-aware workout integration. All features live on a single scrollable page (Approach A), consistent with the app's one-page-per-feature pattern.

## Features

### Feature 1: Cycle Settings Configuration

**What:** Collapsible settings card on the cycle page with range sliders for cycle length (21–45 days), period length (2–10 days), and luteal phase length (8–18 days). Also accessible from the settings page as a "Cycle Settings" link.

**Data model:** No changes — uses existing `users/{uid}/cycleSettings/default` document with `averageCycleLengthDays`, `averagePeriodLengthDays`, `lutealPhaseLengthDays`.

**Components:**
- `CycleSettingsPanel` — client component with collapsible card, three range sliders, save button
- Server action `saveCycleSettings(settings)` — upserts to `cycleSettings/default`

**Settings page integration:** Add a link to `/cycle` under the existing "Cycle Tracking" entry in the Features/More section, or add inline cycle settings fields on the settings page that mirror the cycle page controls.

**Decision:** Quick-access collapsible panel on the cycle page. The settings page already links to `/cycle`.

### Feature 2: Enhanced Period Logging

**What:** Upgrade the log form from a single date input to a full journal entry with start date, optional end date, flow level selector (light/medium/heavy), symptom chips, and free-text notes.

**Data model changes:**
- `users/{uid}/periodLogs/{id}` — add fields:
  - `endDate?: Timestamp` (optional)
  - `flowLevel: "light" | "medium" | "heavy"` (was always "medium")
  - `symptoms?: string[]` (preset list: cramps, headache, fatigue, bloating, mood changes, back pain)
  - `notes?: string`

**Preset symptoms:** `["cramps", "headache", "fatigue", "bloating", "mood_changes", "back_pain"]` — stored as string array, rendered as toggleable chips.

**Components:**
- Enhanced `LogPeriodForm` — replaces current minimal form
  - Date inputs for start and end
  - Flow level as 3-button selector (light/medium/heavy)
  - Symptom chips as multi-toggle
  - Textarea for notes
  - Updated server action `logPeriod(data)` accepting all fields

**Period history enhancement:** Each history row shows date range (start–end), flow level badge, and symptom tags.

### Feature 3: Visual Cycle Calendar

**What:** Two visual components at the top of the cycle page:
1. **Phase ribbon** — horizontal bar showing all 4 phases proportionally, with a "you are here" marker
2. **Monthly calendar grid** — traditional calendar with phase-colored day cells, month navigation, today highlighted

**Domain logic:** Uses existing `getPhaseBoundaries()` and `calculateCycleStatus()`. New pure function needed:
- `getPhaseForDay(cycleDay: number, settings: CycleSettings): CyclePhase` — returns which phase a given cycle day falls in
- `getCycleCalendarData(periodLogs, settings, month, year)` — returns array of `{ date, cycleDay, phase, isToday, isPeriodLogged }` for each day in the month

**Components:**
- `CyclePhaseRibbon` — server component, renders proportional phase bar with position marker
- `CycleCalendar` — client component (needs month navigation state)
  - 7-column grid with day headers
  - Phase-colored cells using existing `PHASE_COLORS` / `PHASE_BG` maps
  - Today highlighted with ring
  - Month prev/next navigation
  - Legend row showing phase colors

**Color mapping (existing):**
- Menstrual: warm-rose
- Follicular: gold
- Ovulation: orange
- Luteal: navy

### Feature 4: Phase-Aware Workout Integration

**What:** Wire the existing `applyPhaseAdjustment()` domain function into the workout and program pages. Show users what adjustments are being made and why, with the ability to override.

**Integration points:**

1. **Program detail page (`/programs/[id]`):**
   - Fetch user's cycle status via server action
   - If cycle tracking active, show phase banner at top
   - Apply `applyPhaseAdjustment()` to Week 1 preview exercises
   - Show adjusted values with "was X" annotation

2. **AI workout page (`/workouts/ai`):**
   - Fetch cycle status on page load
   - Show phase banner + toggle to enable/disable adjustments
   - Pass cycle phase to `/api/ai/generate` request body
   - Show educational callout explaining the adjustment rationale

**New shared component:**
- `CyclePhaseBar` — reusable banner showing current phase, cycle day, and adjustment summary
  - Props: `phase: CyclePhase`, `cycleDay: number`, `adjustmentSummary: string`
  - Phase-specific icon and color
  - Optional "Hide" dismiss (client-side state only, not persisted)

**New shared component:**
- `CycleAdjustmentToggle` — toggle switch with educational explanation
  - Props: `phase: CyclePhase`, `enabled: boolean`, `onToggle: () => void`
  - Shows phase-specific explanation of why adjustments are made

**Server action:**
- `getCycleStatus()` — shared action that returns `CycleStatusResult | null` for the current user. Reusable across pages.

**Domain additions:**
- `getPhaseAdjustmentSummary(phase: CyclePhase): string` — returns human-readable summary like "load +12%, sets +5%"
- `getPhaseExplanation(phase: CyclePhase): string` — returns educational explanation of why adjustments are made

**Adjustment display:**
- Exercises with `percent1RM` show adjusted value with small "↑ was X%" or "↓ was X%" annotation
- Bodyweight exercises are not adjusted (no percent1RM)
- Confidence level affects blend strength — low confidence = smaller adjustments (existing logic in `applyPhaseAdjustment`)

## Page Layout (top to bottom)

1. Phase ribbon (new)
2. Calendar grid (new)
3. Current phase + training recommendation card (existing, unchanged)
4. Enhanced log period form (enhanced)
5. Cycle settings panel — collapsible (new)
6. Period history (enhanced with symptoms/flow)

## New Files

- `web-app/src/app/(features)/cycle/cycle-calendar.tsx` — client component
- `web-app/src/app/(features)/cycle/cycle-phase-ribbon.tsx` — server component
- `web-app/src/app/(features)/cycle/cycle-settings-panel.tsx` — client component
- `web-app/src/components/ui/cycle-phase-banner.tsx` — shared phase banner for workout pages
- `web-app/src/components/ui/cycle-adjustment-toggle.tsx` — shared toggle for AI workout page
- `web-app/src/lib/domain/cycle-calendar.ts` — pure calendar data generation
- `web-app/src/lib/domain/__tests__/cycle-calendar.test.ts` — tests

## Modified Files

- `web-app/src/app/(features)/cycle/page.tsx` — new layout with all sections
- `web-app/src/app/(features)/cycle/log-period-form.tsx` — enhanced with flow/symptoms/notes
- `web-app/src/app/(features)/cycle/actions.ts` — new actions: `saveCycleSettings`, enhanced `logPeriod`, shared `getCycleStatus`
- `web-app/src/app/(features)/programs/[id]/page.tsx` — add phase banner + adjusted exercise values
- `web-app/src/app/(features)/workouts/ai/page.tsx` — add phase banner + toggle + educational callout
- `web-app/src/lib/domain/cycle-calculations.ts` — add `getPhaseForDay`, `getPhaseAdjustmentSummary`, `getPhaseExplanation`
- `web-app/src/lib/domain/index.ts` — export new functions

## Testing

- New domain tests for `getPhaseForDay`, calendar data generation, adjustment summary, phase explanation
- Existing `cycle-calculations.test.ts` and `cycle-adaptation-policy.test.ts` already cover core logic — extend as needed
- No mocking needed — all new domain functions are pure

## Out of Scope

- Persisting the "hide phase banner" preference (client-side only for now)
- Auto-detecting cycle length from logged period data
- Notification/reminder to log period
- Syncing with Apple Health or other cycle tracking apps
