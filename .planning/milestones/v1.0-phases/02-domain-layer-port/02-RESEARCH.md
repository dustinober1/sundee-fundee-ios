# Phase 2: Domain Layer Port - Research

**Researched:** 2026-03-14
**Domain:** Pure TypeScript domain logic — math, date arithmetic, data classification; zero framework dependencies
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- Domain layer lives at `SundeeFundeeRN/src/domain/`
- Subdirectories regrouped by concern (not mirroring Swift layout) — e.g., `src/domain/cycle/` for CycleCalculations + CycleAdaptationPolicy + CycleProgramGenerator
- Files named in kebab-case: `cycle-calculations.ts`, `injury-adaptation-engine.ts`
- Each subdirectory gets a barrel `index.ts` that re-exports public API
- Consumers import from subdirectory barrels: `import { inferCyclePhase } from 'src/domain/cycle'`
- Local time throughout — matches how Swift Foundation.Date + Calendar work in the iOS app
- No timezone normalization to UTC in the domain layer; dates stay in user's local timezone
- Shared JSON fixture files with inputs and expected outputs for parity verification
- Floating-point parity enforced to 4 decimal places (matches success criteria for 1RM formulas)
- 50+ test cases for 1RM estimation formulas; comprehensive fixture coverage for cycle phase inference, injury adaptation, benchmark scoring
- `roundsAndReps` encoding ported as-is: `rounds * 10000 + reps` in a single number
- Higher is better; decode: `rounds = Math.floor(value / 10000)`, `reps = value % 10000`

### Claude's Discretion
- Date library choice (date-fns, dayjs, native Date, or other) — pick what works best for the cycle calculation patterns
- Whether domain functions accept/return plain Date objects or another format
- Enum representation in TypeScript (string unions, const objects, or TS enums)
- Struct/type modeling (interfaces + pure functions vs classes with getters)
- Nullability convention (null vs undefined for absent values) — consider Firestore semantics
- Shared fixture file location (co-located vs separate directory)
- Exact subdirectory groupings for the regrouped-by-concern layout

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| CYAD-01 | Workout load automatically adjusts based on current cycle phase | CycleAdaptationPolicy.applyPhaseAdjustment + CycleProgramGenerator.adaptProgram cover this |
| CYAD-02 | Set and rep targets scale with phase-specific multipliers | CycleAdaptationPolicy.scaleValue + blendMultiplier logic covers this |
| CYAD-03 | Adaptation integrates with readiness score for fine-tuning | CycleAdaptationPolicy.resolveReadinessTier + readinessScales lookup covers this |
| INJR-02 | Injury adaptation engine automatically substitutes or removes contraindicated exercises | InjuryAdaptationEngine.adaptProgram + contraindicationRules + regressionTable covers this |
| INJR-04 | App analyzes pain trends over time and surfaces insights | PainTrendAnalyzer.analyzeTrend + sparklineData covers this |
| INJR-05 | Phase transition advisor suggests when to progress recovery phase | PhaseTransitionAdvisor.evaluateTransition + meetsThreshold covers this |
| INJR-06 | App generates targeted rehab sessions based on injury profile | RehabSessionGenerator.generateSession + recoveryMap covers this |
| WORK-06 | App auto-detects personal records on set completion | WeightCalculations.isPersonalRecord + EpleyFormula.isPR covers this |
| MAX-03 | App estimates 1RM from logged sets using standard formulas | EpleyFormula.estimated1RM (weight × (1 + reps/30)) covers this |
</phase_requirements>

---

## Summary

The iOS app's `Domain/` folder is 23 Swift files of pure value-type logic with zero framework dependencies. Every file maps directly to TypeScript — the logic is arithmetic, table lookups, date arithmetic, and control flow. There are no side effects, no protocol witnesses, no generics that don't translate cleanly. The port is mechanical but detail-sensitive: numeric constants, edge-case handling (e.g., `max(1, ...)` floors on rep scaling), and date helpers must produce bit-for-bit identical output to Swift.

The date-heaviest module is `CycleCalculations`. It relies on `Calendar.current.startOfDay` (local midnight) and `dateComponents([.day], from:to:)` (integer day difference). These behaviors must be matched precisely. The native JavaScript `Date` object + integer arithmetic on midnight-aligned timestamps (using `new Date(y, m, d)`) can reproduce this without a library — but `date-fns` provides safer `startOfDay`, `differenceInCalendarDays`, and `addDays` utilities that parallel Swift Calendar exactly. This is the recommended choice.

The most complex files by porting difficulty are: `CycleCalculations` (date math, phase boundary math), `InjuryAdaptationEngine` (large lookup tables, multi-pass session adaptation), `CycleAdaptationPolicy` (multiplicative blending with clamping), and `OfflineWorkoutGenerator` (template selection + multi-step pipeline). The simplest are: `WODTemplateType`, `BenchmarkCatalog` (static data), `BodyLocation`, `RecoveryPhase`, `WeightUnitConversion`, `CelebrationEvent`.

**Primary recommendation:** Use `date-fns` for all date arithmetic. Model Swift `enum` cases with `const` objects + string union types. Use interfaces + pure functions (not classes). Fix `undefined` as the absent-value convention to match Firestore document field semantics.

---

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| TypeScript | ~5.9.2 (already installed) | Type-safe port of Swift value types | Already in project; strict mode enforced |
| Jest | ^30.3.0 (already installed) | 100% coverage enforcement, fixture-driven testing | Already configured in jest.config.js |
| date-fns | ^4.x | `startOfDay`, `addDays`, `differenceInCalendarDays` — mirrors Swift Calendar | Tree-shakeable, no side effects, pure functions; Context7 confirmed current |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| (none beyond date-fns) | — | All other domain logic is native arithmetic | No additional libraries needed |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| date-fns | Native Date + manual arithmetic | Native avoids a dependency but startOfDay and day-diff helpers would need hand-rolling, increasing porting risk |
| date-fns | dayjs | dayjs mutates by default (unless immutable plugin); date-fns is purely functional and matches Swift's value semantics better |
| string unions | TypeScript `enum` | TS enums compile to objects and cause Firestore serialization surprises; string unions are transparent and serialization-safe |

**Installation:**
```bash
cd SundeeFundeeRN && npm install date-fns
```

---

## Architecture Patterns

### Recommended Project Structure
```
SundeeFundeeRN/src/domain/
├── types/               # Shared interfaces used across subdomain modules
│   └── index.ts         # ExerciseValue, ProgramExercise, InjuryProfile, PainLog, etc.
├── cycle/               # CycleCalculations, CycleAdaptationPolicy, CycleProgramGenerator
│   ├── cycle-calculations.ts
│   ├── cycle-adaptation-policy.ts
│   ├── cycle-program-generator.ts
│   └── index.ts
├── injury/              # InjuryAdaptationEngine, LoadAdjustmentPolicy, PhaseTransitionAdvisor,
│   │                    # PainTrendAnalyzer, RehabSessionGenerator, RecoveryPhase, BodyLocation
│   ├── recovery-phase.ts
│   ├── body-location.ts
│   ├── load-adjustment-policy.ts
│   ├── injury-adaptation-engine.ts
│   ├── pain-trend-analyzer.ts
│   ├── phase-transition-advisor.ts
│   ├── rehab-session-generator.ts
│   └── index.ts
├── calculations/        # WeightCalculations, EpleyFormula, PlateCalculation, WeightUnitConversion, BarbellDefaults
│   ├── weight-calculations.ts
│   ├── epley-formula.ts
│   ├── plate-calculation.ts
│   ├── weight-unit-conversion.ts
│   ├── barbell-defaults.ts
│   └── index.ts
├── ai-workout/          # GeneratedWorkout, OfflineWorkoutGenerator, WorkoutGenerationContext
│   ├── generated-workout.ts
│   ├── offline-workout-generator.ts
│   ├── workout-generation-context.ts
│   └── index.ts
├── history/             # HistoryItem
│   ├── history-item.ts
│   └── index.ts
├── readiness/           # ReadinessSurvey (with AsyncStorage replacing UserDefaults)
│   ├── readiness-survey.ts
│   └── index.ts
├── benchmarks/          # BenchmarkCatalog
│   ├── benchmark-catalog.ts
│   └── index.ts
├── shared/              # CelebrationEvent, ProgramAvailability, WODTemplateType
│   ├── celebration-event.ts
│   ├── program-availability.ts
│   ├── wod-template-type.ts
│   └── index.ts
└── index.ts             # Top-level barrel re-exporting all subdomain barrels

SundeeFundeeRN/src/domain/__fixtures__/
├── cycle-calculations.json
├── epley-formula.json
├── injury-adaptation.json
└── benchmark-scoring.json
```

### Pattern 1: Namespace Object (Swift `enum` with static methods → TS namespace object)

**What:** Swift uses caseless enums as namespaces for static functions. TypeScript exports a plain const object with function values, or exports named functions directly.
**When to use:** For every Swift `enum SomeThing { static func ... }` that has no cases.
**Example:**
```typescript
// Mirrors: enum WeightCalculations { static func roundToNearestFive(...) }
export function roundToNearestFive(value: number): number {
  return Math.round(value / 5) * 5;
}

export function snapBarbellWeightLb(lb: number, barLb = 45): number {
  const plateLoad = Math.max(0, lb - barLb);
  const snapped = Math.round(plateLoad / 5) * 5;
  return barLb + snapped;
}
```

### Pattern 2: String Union Types (Swift enums with raw values)

**What:** Swift enums with `String` raw values become TypeScript string union types + a const object for values.
**When to use:** For all Swift enums stored as strings (CyclePhase, RecoveryPhase, WorkoutFocus, EnergyLevel, EquipmentAccess, etc.)
**Example:**
```typescript
// Mirrors: enum CyclePhase: String { case menstrual, follicular, ovulation, luteal }
export type CyclePhase = 'menstrual' | 'follicular' | 'ovulation' | 'luteal';
export const CYCLE_PHASES: CyclePhase[] = ['menstrual', 'follicular', 'ovulation', 'luteal'];

// Mirrors: enum RecoveryPhase: String { case acute, rehab, lightLoad, returnToPlay, resolved }
export type RecoveryPhase = 'acute' | 'rehab' | 'lightLoad' | 'returnToPlay' | 'resolved';
export const RECOVERY_PHASE_ORDER: RecoveryPhase[] = ['acute', 'rehab', 'lightLoad', 'returnToPlay', 'resolved'];
```

### Pattern 3: ExerciseValue Discriminated Union

**What:** Swift `enum ExerciseValue` with associated values maps to a TypeScript discriminated union.
**When to use:** Whenever Swift code switches on `ExerciseValue` cases (.fixed, .range, .amrap, .text).
**Example:**
```typescript
// Mirrors Swift: enum ExerciseValue { case fixed(Int), range(Int, Int), amrap, text(String) }
export type ExerciseValue =
  | { kind: 'fixed'; value: number }
  | { kind: 'range'; lo: number; hi: number }
  | { kind: 'amrap' }
  | { kind: 'text'; value: string };

export function scaleExerciseValue(ev: ExerciseValue, multiplier: number): ExerciseValue {
  switch (ev.kind) {
    case 'fixed':
      return { kind: 'fixed', value: Math.max(1, Math.round(ev.value * multiplier)) };
    case 'range': {
      const lo = Math.max(1, Math.round(ev.lo * multiplier));
      return { kind: 'range', lo, hi: Math.max(lo, Math.round(ev.hi * multiplier)) };
    }
    case 'amrap':
    case 'text':
      return ev;
  }
}
```

### Pattern 4: Date Arithmetic with date-fns (mirrors Swift Calendar)

**What:** Swift `Calendar.current.startOfDay(for:)` and `calendar.dateComponents([.day], from:to:)` have direct date-fns equivalents.
**When to use:** All cycle-phase date calculations. This is the locked parity-critical area.
**Example:**
```typescript
import { startOfDay, addDays, differenceInCalendarDays, isWithinInterval } from 'date-fns';

// Mirrors: Calendar.current.startOfDay(for: date)
// Mirrors: Calendar.current.date(byAdding: .day, value: days, to: date)
// Mirrors: Calendar.current.dateComponents([.day], from:, to:).day

export function calculateCycleStatus(
  periodLogs: PeriodLog[],
  settings: CycleSettings,
  referenceDate: Date = new Date()
): CycleStatusResult | undefined {
  if (periodLogs.length === 0) return undefined;
  const ref = startOfDay(referenceDate);
  // ... rest of port
}
```

### Pattern 5: Clamping Helper

**What:** Swift's `Comparable.clamped(to:)` is used extensively. TypeScript needs an equivalent inline or utility.
**When to use:** Any multiplier arithmetic in CycleAdaptationPolicy, LoadAdjustmentPolicy.
**Example:**
```typescript
// Mirrors: extension Comparable { func clamped(to range: ClosedRange<Self>) }
export function clamp(value: number, min: number, max: number): number {
  return Math.min(Math.max(value, min), max);
}
```

### Pattern 6: Fixture-Driven Parity Tests

**What:** JSON fixtures capture Swift input/output pairs. TypeScript tests load fixtures and assert TypeScript output matches.
**When to use:** For every numerically sensitive function (EpleyFormula, cycle phase boundaries, adaptation multipliers).
**Example:**
```typescript
// __fixtures__/epley-formula.json
// { "cases": [{ "weight": 100, "reps": 5, "expected1RM": 116.6667 }, ...] }

import cases from '../__fixtures__/epley-formula.json';
test.each(cases.cases)('estimated1RM w=%d r=%d', ({ weight, reps, expected1RM }) => {
  expect(estimated1RM(weight, reps)).toBeCloseTo(expected1RM, 4);
});
```

### Anti-Patterns to Avoid
- **Using TypeScript `enum`:** TS enums are numbers by default; string enums compile to lookup objects that don't match Firestore's plain-string storage. Use string unions.
- **Using `null` for absent values:** Swift optionals become `undefined` in TypeScript; `null` causes Firestore field-exists checks to differ. Pick `undefined` consistently throughout the domain layer.
- **Importing from full path instead of barrel:** `import { x } from 'src/domain/cycle/cycle-calculations'` breaks the public API contract. Always import from barrels.
- **Timezone-aware date construction in tests:** Test dates constructed with `new Date('2024-01-15')` parse as UTC midnight, not local midnight. Use `new Date(2024, 0, 15)` (month is 0-indexed) for local midnight in tests to match Swift behavior.
- **Mutating input arrays/objects:** All Swift domain functions return new values; the TypeScript port must follow the same immutable pattern. No in-place mutation.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Local midnight of a date | `new Date(d.getFullYear(), d.getMonth(), d.getDate())` inline everywhere | `startOfDay(date)` from date-fns | DST edge cases, leap seconds; date-fns handles them |
| Day difference between dates | Millisecond subtraction / 86400000 | `differenceInCalendarDays(to, from)` from date-fns | Millisecond math breaks across DST transitions (23h or 25h days) |
| Adding N days | `d.getTime() + n * 86400000` | `addDays(date, n)` from date-fns | Same DST reason; addDays uses calendar arithmetic, not milliseconds |
| Fixture generation | Manually writing 50+ JSON test cases | Run the Swift fixture generator script against iOS Domain/ | Ensures parity by construction; avoids re-implementing the source of truth |

**Key insight:** Millisecond arithmetic for date differences is the #1 source of off-by-one errors when porting cycle-phase calculations. The Swift app uses `Calendar.dateComponents([.day])` which counts calendar days, not elapsed milliseconds. `differenceInCalendarDays` from date-fns is the exact equivalent.

---

## Common Pitfalls

### Pitfall 1: UTC vs Local Midnight in Tests
**What goes wrong:** `new Date('2024-01-15')` in Node.js is parsed as UTC midnight, which in UTC-5 is `2024-01-14T19:00:00.000-05:00` — a different calendar day. Test assertions pass in UTC but fail in other timezones.
**Why it happens:** ISO 8601 date-only strings default to UTC in JavaScript; date-time strings default to local.
**How to avoid:** Construct test dates with `new Date(year, monthIndex, day)` — this always creates local midnight. Or run tests with `TZ=UTC` in the test script and construct dates accordingly.
**Warning signs:** Tests that pass locally but fail in CI (where TZ may differ).

### Pitfall 2: Floating-Point Rounding Differences (Swift vs JS)
**What goes wrong:** Swift's `Double` and JavaScript's `number` are both IEEE 754 double-precision, but rounding functions differ. Swift `(value).rounded()` uses "round half to even" (banker's rounding). JavaScript `Math.round()` uses "round half away from zero."
**Why it happens:** `0.5.rounded()` in Swift is `0.0`; `Math.round(0.5)` in JavaScript is `1`. For negative numbers: Swift `-0.5.rounded()` is `0.0`; JS `Math.round(-0.5)` is `0`.
**How to avoid:** For the 4-decimal-place parity threshold, the difference only matters if a value lands exactly on 0.5 at the 4th decimal. Use `toBeCloseTo(expected, 4)` in Jest — this tolerates up to 0.00001 difference. For cases where exact rounding match is needed (weight snapping), use a `swiftRound` helper:
```typescript
// Matches Swift rounded() behavior for positive values (sufficient for weight/reps)
export const swiftRound = (value: number): number => {
  return value >= 0 ? Math.round(value) : -Math.round(-value);
};
```
*(Source: Gemini research — important for weight snapping functions)*
**Warning signs:** 1RM fixture cases with reps = 1 (weight returned as-is), or cases where `round(n * multiplier)` produces values ending in .5.

### Pitfall 3: Swift `prefix()` / `suffix()` on Arrays
**What goes wrong:** `PainTrendAnalyzer` uses `logs.prefix(windowSize)` then splits with `.prefix(halfSize)` and `.suffix(halfSize)`. Swift's `suffix` counts from the end of the original ArraySlice (not the half). JavaScript's `Array.slice()` must be used carefully.
**Why it happens:** Swift ArraySlice maintains base collection indices; `suffix` on a slice counts from the slice's end.
**How to avoid:** In `analyzeTrend`, the split is: `recent = logs.slice(0, windowSize)`, `newerHalf = recent.slice(0, halfSize)`, `olderHalf = recent.slice(recent.length - halfSize)`. This matches Swift behavior exactly.
**Warning signs:** Trend direction flipping in tests with odd-count log arrays.

### Pitfall 4: `InjuryAdaptationEngine.mostRestrictive` Phase Ordering
**What goes wrong:** The function relies on `phaseOrder.firstIndex(of:)` to rank phases. In TypeScript, `RECOVERY_PHASE_ORDER.indexOf(phase)` must use the same array ordering.
**Why it happens:** If the order constant is defined differently in TypeScript, the "most restrictive" phase comparison produces wrong results.
**How to avoid:** Define `RECOVERY_PHASE_ORDER = ['acute', 'rehab', 'lightLoad', 'returnToPlay', 'resolved']` as a const and use `indexOf` for comparisons, matching Swift exactly.
**Warning signs:** Injury adaptation tests where a session with mixed acute+rehab injuries doesn't get acute-phase load multipliers applied.

### Pitfall 5: `WeightUnitConversion.formatValue` Uses `NumberFormatter` Locale
**What goes wrong:** Swift's `NumberFormatter` with `numberStyle = .decimal` uses the device locale for thousand separators. The `formatValue` function in TypeScript should not use `toLocaleString()` unless locale is explicitly pinned — or it becomes untestable.
**Why it happens:** This function is used for display strings; tests that assert exact string output will fail in different locales.
**How to avoid:** In the TypeScript port, `formatValue` is display-only code. Either skip locale formatting in the domain layer (return a number, format at the UI layer) or pin to `en-US` explicitly in tests.
**Warning signs:** Tests asserting `"1,234.5"` that fail in systems with different decimal/thousand separators.

### Pitfall 6: `ReadinessSurvey` UserDefaults Dependency
**What goes wrong:** The Swift `ReadinessSurvey` has `saveTodayResult` and `loadTodayResult` that write to `UserDefaults`. This is a side effect — pure domain code should not own storage.
**Why it happens:** The iOS code bundled storage convenience into the domain type.
**How to avoid:** In TypeScript, the pure scoring functions (`score`, `blendWithHealthKit`, `tierFromScore`, display helpers) belong in the domain. The persistence functions (`saveTodayResult`, `loadTodayResult`) should be moved to the repository layer (Phase 3) or injected as a storage interface. The domain module exposes only the pure math.
**Warning signs:** Tests that require AsyncStorage mocking inside the domain layer — a sign the boundary is wrong.

### Pitfall 7: `BenchmarkCatalog` Predefined Array Initialization Order
**What goes wrong:** The Swift catalog uses a mutable local `order` counter in an IIFE to assign `sortOrder`. If TypeScript code constructs the array differently (e.g., using `map` with index), insertion order must be identical.
**Why it happens:** Sort order is baked into each `BenchmarkDefinition` object.
**How to avoid:** Port the catalog as a plain array literal in insertion order; let index-in-array serve as implicit sort order if the consumer always sorts by position. Alternatively, keep explicit `sortOrder` field and verify the sequence matches Swift.
**Warning signs:** Benchmark catalog appearing in different order than the iOS app when displayed to users.

---

## Code Examples

Verified patterns derived directly from the Swift source files:

### 1RM Estimation Formulas (MAX-03) — Full Reference

| Formula | Equation | Valid Rep Range |
|---------|----------|-----------------|
| **Epley** | `weight × (1 + reps / 30)` | reps > 1 |
| **Brzycki** | `weight × (36 / (37 - reps))` | 2 ≤ reps ≤ 36 |
| **Lombardi** | `weight × reps^0.10` | reps ≥ 1 |
| **Mayhew** | `weight × (100 / (52.2 + 41.9 × e^(-0.055 × reps)))` | reps ≥ 1 |
| **O'Conner** | `weight × (1 + reps / 40)` | reps ≥ 1 |
| **Wathen** | `weight × (100 / (48.8 + 53.8 × e^(-0.075 × reps)))` | reps ≥ 1 |
| **Lander** | `weight × (100 / (101.3 - 2.67123 × reps))` | 2 ≤ reps ≤ 10 |

*(Source: Qwen research — cross-referenced with WeightCalculations.swift)*

```typescript
// Mirrors: EpleyFormula.estimated1RM — weight × (1 + reps / 30)
// Swift: guard reps > 1 else { return weight }
export function estimated1RM(weight: number, reps: number): number {
  if (reps <= 1) return weight;
  return weight * (1 + reps / 30);
}

export function isPR(newEstimate: number, currentMax: number | undefined): boolean {
  if (currentMax === undefined) return true;
  return newEstimate > currentMax;
}
```

### CycleCalculations Phase Boundaries (CYAD-01, CYAD-02)
```typescript
// Mirrors: CycleCalculations.getPhaseBoundaries
export function getPhaseBoundaries(settings: CycleSettings): Record<CyclePhase, PhaseBoundary> {
  const { averageCycleLengthDays: cycleLen, averagePeriodLengthDays: periodLen, lutealPhaseLengthDays: lutealLen } = settings;
  const ovDay = cycleLen - lutealLen;
  const ovStart = Math.max(periodLen + 2, ovDay - 2);
  const ovEnd = Math.max(ovStart, Math.min(ovDay + 2, cycleLen - lutealLen + 2));
  const follicularEnd = Math.max(periodLen + 1, ovStart - 1);
  return {
    menstrual:  { start: 1,             end: periodLen },
    follicular: { start: periodLen + 1, end: follicularEnd },
    ovulation:  { start: ovStart,       end: ovEnd },
    luteal:     { start: ovEnd + 1,     end: cycleLen },
  };
}
```

### CycleAdaptationPolicy Multiplier Blending (CYAD-01, CYAD-02, CYAD-03)
```typescript
// Mirrors: CycleAdaptationPolicy.applyPhaseAdjustment — blendMultiplier + clamp
function blendMultiplier(target: number, readinessScale: number, confidenceScale: number): number {
  return clamp(1.0 + (target - 1.0) * readinessScale * confidenceScale, 0.75, 1.25);
}
```

### InjuryAdaptationEngine Most Restrictive Phase (INJR-02)
```typescript
// Mirrors: InjuryAdaptationEngine.mostRestrictive
const RECOVERY_PHASE_ORDER: RecoveryPhase[] = ['acute', 'rehab', 'lightLoad', 'returnToPlay', 'resolved'];

export function mostRestrictive(phases: RecoveryPhase[]): RecoveryPhase | undefined {
  return phases.reduce<RecoveryPhase | undefined>((best, phase) => {
    if (best === undefined) return phase;
    return RECOVERY_PHASE_ORDER.indexOf(phase) < RECOVERY_PHASE_ORDER.indexOf(best) ? phase : best;
  }, undefined);
}
```

### PainTrendAnalyzer (INJR-04)
```typescript
// Mirrors: PainTrendAnalyzer.analyzeTrend — prefix/suffix split
export function analyzeTrend(logs: PainLog[], windowSize = 7): TrendResult {
  if (logs.length === 0) return { trailingAverage: 0, isImproving: false, latestPainLevel: undefined, readingCount: 0 };
  const recent = logs.slice(0, windowSize);
  const average = recent.reduce((s, l) => s + l.painLevel, 0) / recent.length;
  const latest = logs[0]?.painLevel;
  let improving = false;
  if (recent.length >= 2) {
    const halfSize = Math.floor(recent.length / 2);
    const newerHalf = recent.slice(0, halfSize);
    const olderHalf = recent.slice(recent.length - halfSize);
    const newerAvg = newerHalf.reduce((s, l) => s + l.painLevel, 0) / newerHalf.length;
    const olderAvg = olderHalf.reduce((s, l) => s + l.painLevel, 0) / olderHalf.length;
    improving = newerAvg < olderAvg;
  }
  return { trailingAverage: average, isImproving: improving, latestPainLevel: latest, readingCount: logs.count };
}
```

### PhaseTransitionAdvisor (INJR-05)
```typescript
// Mirrors: PhaseTransitionAdvisor.meetsThreshold + evaluateTransition
export function meetsThreshold(logs: PainLog[], count: number, maxPain: number): boolean {
  if (logs.length < count) return false;
  return logs.slice(0, count).every(l => l.painLevel <= maxPain);
}
// Thresholds: acute→rehab: 3 logs ≤5, rehab→lightLoad: 3 logs ≤3, lightLoad→returnToPlay: 3 logs ≤2, returnToPlay→resolved: 5 logs ≤1
```

### roundsAndReps Encoding (Benchmarks)
```typescript
// Mirrors iOS CLAUDE.md encoding: rounds * 10000 + reps
export function encodeRoundsAndReps(rounds: number, reps: number): number {
  return rounds * 10000 + reps;
}
export function decodeRoundsAndReps(value: number): { rounds: number; reps: number } {
  return { rounds: Math.floor(value / 10000), reps: value % 10000 };
}
```

---

## Swift Source → TypeScript Module Map

Full inventory of all 23 files and their TypeScript destination:

| Swift File | TypeScript Module | Complexity |
|-----------|-------------------|------------|
| `CycleCalculations.swift` | `src/domain/cycle/cycle-calculations.ts` | HIGH — date arithmetic |
| `CycleAdaptationPolicy.swift` | `src/domain/cycle/cycle-adaptation-policy.ts` | HIGH — blended multipliers |
| `CycleProgramGenerator.swift` | `src/domain/cycle/cycle-program-generator.ts` | HIGH — orchestrates cycle + injury |
| `InjuryAdaptationEngine.swift` | `src/domain/injury/injury-adaptation-engine.ts` | HIGH — large lookup tables |
| `LoadAdjustmentPolicy.swift` | `src/domain/injury/load-adjustment-policy.ts` | MEDIUM |
| `PhaseTransitionAdvisor.swift` | `src/domain/injury/phase-transition-advisor.ts` | LOW |
| `PainTrendAnalyzer.swift` | `src/domain/injury/pain-trend-analyzer.ts` | MEDIUM — slice indexing |
| `RehabSessionGenerator.swift` | `src/domain/injury/rehab-session-generator.ts` | MEDIUM |
| `RecoveryPhase.swift` | `src/domain/injury/recovery-phase.ts` | LOW — types only |
| `BodyLocation.swift` | `src/domain/injury/body-location.ts` | LOW — types + parse/encode |
| `WeightCalculations.swift` | `src/domain/calculations/weight-calculations.ts` | MEDIUM |
| `PlateCalculation.swift` | `src/domain/calculations/plate-calculation.ts` | MEDIUM — unit branching |
| `WeightUnitConversion.swift` | `src/domain/calculations/weight-unit-conversion.ts` | LOW — arithmetic |
| `BarbellDefaults.swift` | `src/domain/calculations/barbell-defaults.ts` | LOW — table lookup |
| `GeneratedWorkout.swift` | `src/domain/ai-workout/generated-workout.ts` | MEDIUM — computed props |
| `OfflineWorkoutGenerator.swift` | `src/domain/ai-workout/offline-workout-generator.ts` | HIGH — template pipeline |
| `WorkoutGenerationContext.swift` | `src/domain/ai-workout/workout-generation-context.ts` | MEDIUM — types |
| `HistoryItem.swift` | `src/domain/history/history-item.ts` | LOW — types only |
| `ReadinessSurvey.swift` | `src/domain/readiness/readiness-survey.ts` | MEDIUM — split storage out |
| `BenchmarkCatalog.swift` | `src/domain/benchmarks/benchmark-catalog.ts` | MEDIUM — static data order |
| `CelebrationEvent.swift` | `src/domain/shared/celebration-event.ts` | LOW |
| `ProgramAvailability.swift` | `src/domain/shared/program-availability.ts` | MEDIUM — date parsing |
| `WODTemplateType.swift` | `src/domain/shared/wod-template-type.ts` | LOW |

**Note:** `CelebrationEvent` and `BenchmarkCatalog` reference types (`ConditioningScoringType`, `BenchmarkDefinition`, `BenchmarkScoringType`, `WeightUnit`, `Gender`, `PeriodLog`, `CycleSettings`, etc.) that live in the iOS `Models/` layer. The TypeScript port defines these as plain interfaces in `src/domain/types/` — they become domain interfaces, not Firestore-backed models (that wiring happens in Phase 3).

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `moment.js` for date math | `date-fns` (tree-shakeable, pure functions) | ~2020 | date-fns eliminates the 300KB moment bundle; pure functions match Swift's functional style |
| TypeScript `enum` for domain values | String unions + const arrays | TypeScript best practices 2022+ | Avoids enum numeric footguns, serialization surprises with Firestore |

**Deprecated/outdated:**
- `moment.js`: Do not use — deprecated project, adds 300KB. date-fns is the standard replacement.
- TypeScript `const enum`: Compile-time inlining breaks type safety across module boundaries. Use string unions.

---

## Open Questions

1. **`ExerciseValue` representation in existing RN code**
   - What we know: The type is defined in Swift Models with cases `.fixed(Int)`, `.range(Int, Int)`, `.amrap`, `.text(String)`. It is referenced throughout domain files.
   - What's unclear: There is no existing TypeScript definition. The discriminated union pattern is the recommendation, but the exact `kind` field name should be consistent with how Phase 3 Firestore documents will serialize this.
   - Recommendation: Define in `src/domain/types/exercise-value.ts` during Wave 0 of this phase; use `kind` as the discriminant field. Firestore will store as a map `{ kind: "fixed", value: 3 }`.

2. **Program, InjuryProfile, PeriodLog, CycleSettings, ProgramExercise interface definitions**
   - What we know: These are SwiftData `@Model` types in iOS. The domain functions accept them as pure value inputs.
   - What's unclear: Exact field names for TypeScript interfaces (Swift uses camelCase, Firestore uses camelCase — consistent). Need to define minimal interfaces that cover what domain functions need, then Phase 3 repositories expand them.
   - Recommendation: Define minimal domain interfaces (only fields actually accessed by domain functions) in `src/domain/types/`. Avoid over-specifying fields that only matter for persistence.

3. **Fixture generation workflow**
   - What we know: Context.md specifies "fixtures generated by running a Swift script that imports Domain types."
   - What's unclear: Does this Swift script already exist, or does it need to be written?
   - Recommendation: Include a Wave 0 task to write the Swift fixture generator script in `SundeeFundee/Scripts/generate-fixtures.swift` if it doesn't exist. Alternatively, hand-write fixtures for the critical numeric functions (EpleyFormula, phase boundaries, adaptation multipliers) since the formulas are now fully read and understood.

---

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Jest 30.3.0 + jest-expo preset |
| Config file | `SundeeFundeeRN/jest.config.js` (exists) |
| Quick run command | `cd SundeeFundeeRN && npx jest src/domain --testPathPattern="domain" --passWithNoTests` |
| Full suite command | `cd SundeeFundeeRN && npx jest --coverage` |
| Coverage threshold | 100% line coverage (enforced by CI; mirrors iOS standard) |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| CYAD-01 | Load multiplier applied based on cycle phase | unit | `npx jest src/domain/cycle --coverage` | Wave 0 |
| CYAD-02 | Set/rep targets scale with blended multiplier | unit | `npx jest src/domain/cycle --coverage` | Wave 0 |
| CYAD-03 | Readiness score feeds into adaptation blending | unit | `npx jest src/domain/cycle --coverage` | Wave 0 |
| INJR-02 | Contraindicated exercises replaced or removed | unit | `npx jest src/domain/injury --coverage` | Wave 0 |
| INJR-04 | Pain trend improving/worsening classification | unit | `npx jest src/domain/injury --coverage` | Wave 0 |
| INJR-05 | Phase transition suggestion at correct thresholds | unit | `npx jest src/domain/injury --coverage` | Wave 0 |
| INJR-06 | Rehab session generated for rehab/lightLoad injuries | unit | `npx jest src/domain/injury --coverage` | Wave 0 |
| WORK-06 | Personal record detected when weight exceeds previous max | unit | `npx jest src/domain/calculations --coverage` | Wave 0 |
| MAX-03 | Epley 1RM formula matches Swift output to 4 decimal places | unit (fixture) | `npx jest src/domain/calculations --coverage` | Wave 0 |

### Sampling Rate
- **Per task commit:** `cd SundeeFundeeRN && npx jest src/domain/<subdomain> --passWithNoTests`
- **Per wave merge:** `cd SundeeFundeeRN && npx jest --coverage`
- **Phase gate:** 100% coverage on `src/domain/**` before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] `src/domain/types/index.ts` — shared interfaces (ProgramExercise, ExerciseValue, InjuryProfile, PainLog, PeriodLog, CycleSettings, etc.)
- [ ] `src/domain/__fixtures__/` directory and initial fixture files
- [ ] All test files listed in the module map above (none exist yet — greenfield)
- [ ] `date-fns` installation: `cd SundeeFundeeRN && npm install date-fns`

---

## Sources

### Primary (HIGH confidence)
- Direct read of all 23 Swift source files in `SundeeFundee/Domain/` — complete logic inventory
- `SundeeFundeeRN/package.json` — confirmed Jest 30.3.0, TypeScript 5.9.2, no date library currently installed
- `SundeeFundeeRN/jest.config.js` — confirmed jest-expo preset, coverage from `src/**`, setup.js pattern
- `SundeeFundeeRN/tsconfig.json` — confirmed strict mode, baseUrl `.`
- `.planning/phases/02-domain-layer-port/02-CONTEXT.md` — locked decisions and discretion areas

### Secondary (MEDIUM confidence)
- date-fns API (`startOfDay`, `differenceInCalendarDays`, `addDays`) — verified against common usage; exact function names match date-fns v4 API surface

### Tertiary (LOW confidence)
- date-fns v4 `differenceInCalendarDays` behavior on DST transitions — assumed correct based on library documentation claim; validate with a targeted test in CI

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all libraries already installed except date-fns; date-fns choice verified against domain patterns
- Architecture: HIGH — derived directly from reading all 23 Swift files; structure mirrors domain concerns, not file system
- Pitfalls: HIGH — UTC/local midnight pitfall is a known TypeScript gotcha; others derived from reading Swift source line by line
- Numeric parity: HIGH — formulas fully read; fixture approach confirmed in CONTEXT.md

**Research date:** 2026-03-14
**Valid until:** 2026-04-14 (stable domain — no library churn expected)
**Research sources:** Claude (primary researcher — read all 23 Swift files), Gemini 2.5 Pro (supplemental — swiftRound helper, enum patterns), Qwen (supplemental — full 1RM formula table, wave structure, fixture schemas)
