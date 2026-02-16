# Cycle Tracking Feature Design

**Date:** 2026-02-16
**Status:** Approved
**Approach:** Context-Based with On-Demand Calculation

## Overview

Add menstrual cycle tracking to help users optimize training around hormonal fluctuations. The feature provides phase-based training recommendations, personalized strength predictions, and workout history analysis by cycle phase.

## Goals

1. Help users understand how their cycle affects strength and energy
2. Provide actionable training recommendations for each cycle phase
3. Learn from user's actual performance to personalize predictions
4. Alert users when they're in their optimal strength window

## Non-Goals

- Medical advice or fertility tracking
- Integration with external cycle tracking apps (future consideration)
- Separate privacy controls (syncs with workout data)

## Data Model

### New Types (`src/types/cycle.ts`)

```typescript
// Core cycle tracking
export interface PeriodLog {
  id: string;
  userId: string;
  startDate: Date;
  endDate?: Date;          // null if ongoing
  flowLevel?: 'light' | 'medium' | 'heavy';
  notes?: string;
  createdAt: Date;
}

export interface SymptomLog {
  id: string;
  userId: string;
  date: Date;
  symptomId: string;       // references SymptomDefinition
  severity: 1 | 2 | 3 | 4 | 5;
  notes?: string;
}

export interface BBTLog {
  id: string;
  userId: string;
  date: Date;
  temperature: number;     // in Fahrenheit
  time: string;            // HH:mm format
  notes?: string;
}

// Configuration
export interface SymptomDefinition {
  id: string;
  name: string;
  category: 'physical' | 'emotional' | 'energy';
  isDefault: boolean;      // core set vs user-added
  userId?: string;         // null for defaults, set for custom
}

export interface CycleSettings {
  id: string;
  userId: string;
  averageCycleLength: number;    // days, default 28
  averagePeriodLength: number;   // days, default 5
  lutealPhaseLength: number;     // days, default 14
  enabledSymptomIds: string[];   // which symptoms to show
  notificationsEnabled: boolean;
}

// Computed (not stored, calculated on-demand)
export type CyclePhase =
  | 'menstrual'
  | 'follicular'
  | 'ovulation'
  | 'luteal';

export interface CycleStatus {
  currentPhase: CyclePhase;
  cycleDay: number;              // 1 = first day of period
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
  intensityRecommendation: 'low' | 'moderate' | 'high' | 'peak';
  exercisesToEmphasize: string[];
  exercisesToAvoid: string[];
}

export interface PhaseStrengthProfile {
  userId: string;
  phases: {
    phase: CyclePhase;
    avgPerformanceDelta: number;  // percentage vs baseline
    sampleSize: number;           // number of workouts analyzed
  }[];
  strongestPhase: CyclePhase;
  weakestPhase: CyclePhase;
  confidence: number;             // 0-1 based on data quality
}
```

### Dexie Tables

Add to `src/lib/db/dexie.ts`:

- `periodLogs` - indexed by userId, startDate
- `symptomLogs` - indexed by userId, date
- `bbtLogs` - indexed by userId, date
- `symptomDefinitions` - seeded with defaults, indexed by category
- `cycleSettings` - one record per user

## Cycle Calculations

### File: `src/lib/cycle-calculations.ts`

**Core Functions:**

1. `calculateCycleStatus(periodLogs, settings, referenceDate)` - Determines current phase, cycle day, predictions
2. `getPhaseBoundaries(settings, cycleStartDate)` - Returns day ranges for each phase
3. `getPhaseRecommendation(phase)` - Returns training guidance for each phase
4. `analyzeStrengthPatterns(workouts, sets, periodLogs)` - Compares performance across phases
5. `predictStrengthWindow(cycleStatus, strengthProfile)` - When to attempt PRs

**Phase Definitions:**
- Menstrual: Days 1 through period length (typically 1-5)
- Follicular: Day after period to ~5 days before ovulation (typically 6-12)
- Ovulation: ~5 day window around estimated ovulation (typically 13-17)
- Luteal: Post-ovulation to next period (typically 18-28)

**Error Handling:**
- Missing data → return reasonable defaults
- Irregular cycles → widen prediction windows, lower confidence
- Conflicting BBT vs. calendar → prefer BBT for ovulation detection

## State Management

### File: `src/contexts/cycle-context.tsx`

```typescript
interface CycleContextValue {
  // Data
  periodLogs: PeriodLog[];
  symptomLogs: SymptomLog[];
  bbtLogs: BBTLog[];
  settings: CycleSettings | null;
  availableSymptoms: SymptomDefinition[];

  // Computed
  cycleStatus: CycleStatus | null;
  currentRecommendation: PhaseRecommendation | null;
  strengthProfile: PhaseStrengthProfile | null;

  // Actions - Period
  logPeriod(startDate, flowLevel?): Promise<void>;
  endPeriod(endDate): Promise<void>;
  updatePeriodLog(id, updates): Promise<void>;

  // Actions - Symptoms
  logSymptom(date, symptomId, severity, notes?): Promise<void>;
  updateSymptomLog(id, updates): Promise<void>;

  // Actions - BBT
  logBBT(date, temperature, time): Promise<void>;

  // Actions - Settings
  updateSettings(updates): Promise<void>;
  enableSymptom(symptomId): Promise<void>;
  disableSymptom(symptomId): Promise<void>;
  addCustomSymptom(name, category): Promise<void>;

  // Utilities
  getSymptomsForDate(date): SymptomLog[];
  getCycleDayForDate(date): number | null;
  refresh(): Promise<void>;
}
```

**Default Symptoms:**
- Physical: cramps, bloating, breast tenderness, headaches
- Emotional: mood swings, anxiety, irritability
- Energy: fatigue, insomnia, high energy

## UI Components

### Dedicated Cycle Page (`src/app/cycle/page.tsx`)

- Cycle calendar with period days and phase color coding
- Current phase display with progress bar
- Quick log buttons: Log Period, Add Symptom, BBT
- Recent symptoms list
- Configure symptoms link

### Phase Indicator (`src/components/cycle/phase-indicator.tsx`)

- Compact display for dashboard/workout pages
- Shows current phase icon, name, cycle day
- Expands on tap for mini recommendation
- Props: `compact?: boolean`

### Cycle Calendar (`src/components/cycle/cycle-calendar.tsx`)

- Month grid with period days highlighted
- Predicted phases shown with subtle color bands
- Tap date to log symptoms or view history
- Legend for phase colors

### Symptom Logger (`src/components/cycle/symptom-logger.tsx`)

- Modal/sheet for adding symptoms
- Shows only enabled symptoms
- Severity slider (1-5)
- Optional notes field

### BBT Input (`src/components/cycle/bbt-input.tsx`)

- Temperature input (F/C toggle)
- Time picker (defaults to current)
- Quick entry for daily logging

### Recommendation Card (`src/components/cycle/recommendation-card.tsx`)

- Phase-specific training advice
- Visual intensity indicator (low → peak)
- Strength window alerts ("Your strength window starts in 3 days")

## Integration Points

### Dashboard

- Phase indicator at top showing current phase and day
- Phase-aware workout tip in "Today's Workout" card
- Link to cycle page

### Workout Logger

- Phase indicator below header
- Personalized tip based on phase (if profile exists)
- Example: "Your energy is typically high in this phase. Go for it!"

### Progress Page

- Filter dropdown: "All Time" / "By Cycle Phase"
- New "Strength by Phase" comparison chart
- Cycle Impact Analysis section (shows after 2+ cycles of data)

### Navigation

Access cycle page via Dashboard link (keep 4-item bottom nav)

## Data Flow

```
User logs period
    ↓
PeriodLog saved to Dexie
    ↓
CycleContext recalculates cycleStatus
    ↓
currentRecommendation updated
    ↓
UI components re-render with new phase info
    ↓
(Sync layer) PeriodLog syncs to Supabase if enabled
```

## Personalization Algorithm

1. Requires minimum 2 complete cycles of workout data
2. Groups workouts by cycle phase
3. Calculates average performance metrics per phase
4. Compares to user's baseline (overall average)
5. Identifies strongest/weakest phases
6. Confidence score based on sample size and consistency

## Sync Behavior

- Cycle data syncs together with workout data
- No separate privacy controls
- All cycle tables included in sync layer
- Last-write-wins conflict resolution

## Testing Strategy

- Unit tests for phase calculations
- Unit tests for strength pattern analysis
- Integration tests for CycleContext
- E2E test for logging period flow
- E2E test for viewing recommendations

## Future Considerations

- Import from external apps (Clue, Flo, Apple Health)
- Fertility awareness features
- Medication tracking (birth control affects cycles)
- Coach/trainer sharing (with explicit consent)
