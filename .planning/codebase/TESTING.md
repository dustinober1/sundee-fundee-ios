---
name: Testing Patterns
type: codebase-map
focus: quality
created: 2026-04-08
---

# Testing Patterns

**Analysis Date:** 2026-04-08

## Test Framework

**Runner:**
- Vitest 4.1.2 (web app)
- XCTest + Swift Testing (iOS)
- Config: `web-app/vitest.config.ts`

**Assertion Library:**
- Vitest built-in `expect` (web app)
- `XCTAssertEqual`, `XCTAssertGreaterThan`, etc. (iOS XCTest)
- `#expect` (iOS Swift Testing)

**Run Commands (web app):**
```bash
cd web-app
npm test                 # Run all tests (vitest run)
npm run test:watch       # Watch mode (vitest)
npm run test:coverage    # Coverage report (domain layer only)
```

**Run Commands (iOS):**
```bash
# Via Xcode scheme SundeeFundeeKitTests
# Test action configured in SundeeFundeeApp.xcworkspace
```

## Vitest Configuration

**Config file:** `web-app/vitest.config.ts`

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
    },
  },
  resolve: {
    alias: {
      "@": path.resolve(__dirname, "./src"),
    },
  },
});
```

**Key settings:**
- `globals: true` -- `describe`, `it`, `expect` available without import (though most files import them explicitly)
- `environment: "node"` -- Node.js environment (no browser/DOM simulation)
- Coverage scoped to `src/lib/domain/**` only
- Path alias `@` resolves to `./src` to match `tsconfig.json`

## Test File Organization

**Location:**
- Domain tests: `web-app/src/lib/domain/__tests__/` (co-located in `__tests__` subdirectory within domain)
- Non-domain tests: `web-app/src/lib/__tests__/` (for `ai-generation`, `subscription-state`, `date-input`, `write-validation`)
- iOS tests: `SundeeFundee/Tests/SundeeFundeeKitTests/` (separate directory)

**Naming:**
- Web: `[module-name].test.ts` (matches source module name exactly)
- iOS: `[ModuleName]Tests.swift` (PascalCase with `Tests` suffix)

**Web test directory structure:**
```
web-app/src/lib/domain/__tests__/
  admin-types.test.ts
  ai-workout.test.ts
  benchmark-catalog.test.ts
  benchmark-readiness.test.ts
  body-location.test.ts
  celebration-event.test.ts
  cycle-adaptation-policy.test.ts
  cycle-calculations.test.ts
  cycle-calendar.test.ts
  exercise-catalog.test.ts
  injury-adaptation-engine.test.ts
  injury-support.test.ts
  plate-calculation.test.ts
  program-template-generator.test.ts
  subscription.test.ts
  types.test.ts
  weight-calculations.test.ts
  weight-unit-conversion.test.ts

web-app/src/lib/__tests__/
  ai-generation.test.ts
  date-input.test.ts
  subscription-state.test.ts
  write-validation.test.ts
```

**iOS test directory structure:**
```
SundeeFundee/Tests/SundeeFundeeKitTests/
  ActivityTests/
    LiveWorkoutActivityStateTests.swift
  AuthTests/
    AppleAuthClientTests.swift
  DataLayerTests/
    CloudKitClientTests.swift
    HealthKitClientTests.swift
    SyncQueueTests.swift
  DomainTests/
    AIWorkoutTests.swift
    BenchmarkCatalogTests.swift
    BenchmarkReadinessTests.swift
    BodyLocationTests.swift
    CelebrationEventTests.swift
    ChartDataAggregatorTests.swift
    CycleAdaptationPolicyTests.swift
    CycleCalculationsTests.swift
    CycleCalendarTests.swift
    CyclePhaseHelperTests.swift
    DataExportServiceTests.swift
    ExerciseCatalogTests.swift
    InjuryAdaptationEngineTests.swift
    InjurySupportTests.swift
    PlateCalculatorTests.swift
    PlateauDetectorTests.swift
    PreferenceLearnerTests.swift
    ProgramTemplateGeneratorTests.swift
    ScheduleReshufflerTests.swift
    SubstitutionRankerTests.swift
    UnitConverterTests.swift
    WeeklyLoadAnalyzerTests.swift
    WeightCalculatorTests.swift
  ModelTests/
    ExerciseTests.swift
    WorkoutTests.swift
  ViewModelTests/
    AnalyticsViewModelTests.swift
    WorkoutDetailViewModelTests.swift
```

## Test Structure

**Suite Organization (web app):**
```typescript
import { describe, it, expect } from "vitest";
import {
  roundToNearestFive,
  calculateTargetWeight,
  detectPlateau,
} from "../weight-calculations";
import { SessionResult } from "../types";

// Helper factories at top of file
describe("roundToNearestFive", () => {
  it("rounds to nearest 5 -- exact", () => {
    expect(roundToNearestFive(100)).toBe(100);
  });
  it("rounds up when >= 2.5", () => {
    expect(roundToNearestFive(102.5)).toBe(105);
  });
});

describe("detectPlateau", () => {
  it("returns false for fewer than 3 data points", () => {
    expect(detectPlateau([])).toBe(false);
    expect(detectPlateau([100])).toBe(false);
  });
});
```

**Suite Organization (iOS):**
```swift
import XCTest
@testable import SundeeFundeeKit

final class WeightCalculatorTests: XCTestCase {
    func testDefaultPercentage_MapsCorrectly() {
        XCTAssertEqual(defaultPercentage(reps: 1), 1.0, accuracy: 0.01)
        XCTAssertEqual(defaultPercentage(reps: 5), 0.80, accuracy: 0.01)
    }
}
```

**Patterns:**
- One `describe` block per function under test
- Multiple `it` blocks per `describe` covering different cases
- Helper factory functions defined at top of test file
- Test descriptions use plain English describing expected behavior
- Group related assertions within a single `it` block when testing the same case (e.g., multiple `expect` calls for boundary values)

## Helper Factories

**Web App Pattern:**
Factory functions at the top of each test file create test fixtures. Named `make[Type]` with default parameter values:

```typescript
// From web-app/src/lib/domain/__tests__/ai-workout.test.ts
function makeExercise(
  name: string,
  sets: number = 3,
  reps: string = "8",
  bodyweightOnly: boolean = false,
  weightKg?: number
): GeneratedExercise {
  return {
    id: `ex-${name}`,
    name,
    sets,
    reps,
    weightKg,
    restMinutes: undefined,
    bodyweightOnly,
  };
}
```

```typescript
// From web-app/src/lib/domain/__tests__/injury-adaptation-engine.test.ts
function makeProgram(exerciseNames: string[]): Program {
  const session: ProgramSession = {
    sessionId: "s1",
    sessionName: "Session 1",
    sessionType: "strength",
    focus: "squat",
    exercises: exerciseNames.map((name) => ({
      exercise: name,
      sets: { type: "fixed", value: 4 },
      reps: { type: "fixed", value: 5 },
      percent1RM: 0.80,
    })),
  };
  // ...
}

function makeInjury(
  id: string,
  location: string,
  phase: InjuryProfile["recoveryPhase"]
): InjuryProfile {
  return { id, location, recoveryPhase: phase };
}
```

```typescript
// From web-app/src/lib/domain/__tests__/cycle-calculations.test.ts
const defaultSettings: CycleSettings = {
  averageCycleLengthDays: 28,
  averagePeriodLengthDays: 5,
  lutealPhaseLengthDays: 14,
};

function localDate(year: number, month: number, day: number): Date {
  return new Date(year, month - 1, day);
}
```

**iOS Pattern:**
```swift
// From SundeeFundee/Tests/.../WorkoutDetailViewModelTests.swift
private func makeWorkout(
    id: String = UUID().uuidString,
    exercises: [Exercise],
    completedAt: Date? = nil
) -> Workout {
    Workout(
        id: id,
        date: makeDate(year: 2026, month: 3, day: 1),
        name: "Test Workout",
        exercises: exercises,
        completedAt: completedAt
    )
}

private func makeExercise(
    name: String,
    completedWeights: [Double?]
) -> Exercise { ... }
```

**Key conventions for factories:**
- Use default parameter values so callers only specify what they need
- Prefix with `make` (not `create` or `build`)
- Place at the top of the test file, before any `describe` blocks
- In Swift, mark as `private` since they are file-scoped

## Mocking

**Framework:** No mocking framework. Tests are pure function unit tests that require no mocking.

**What to Mock:**
- Nothing in domain tests -- domain functions are pure, taking data and returning data
- No framework dependencies in `src/lib/domain/` -- zero imports from Firebase, Next.js, React, etc.

**What NOT to Mock:**
- Domain logic itself -- test the actual implementation
- Pure calculation functions -- call with inputs, assert outputs

**Why no mocking is needed:**
The domain layer (`src/lib/domain/`) is designed as pure TypeScript with zero dependencies:
- No database calls
- No network requests
- No framework imports
- No global state
- Functions accept plain data, return plain data

This is a deliberate architectural choice. The `index.ts` barrel file re-exports everything, but individual domain modules have no imports from outside the domain directory (except type imports from other domain modules).

## Test Types

**Unit Tests:**
- Scope: Domain layer pure functions
- Approach: Call function with known inputs, assert exact outputs
- No setup/teardown needed
- Each test is independent

**Integration Tests:**
- Not present in automated test suite
- Server actions (`web-app/src/app/(features)/**/actions.ts`) are not tested
- API routes (`web-app/src/app/api/**`) are not tested
- Firestore queries are not tested

**E2E Tests:**
- Not present in web app
- iOS has some activity/view model tests that exercise more integrated paths

## Coverage

**Requirements:**
- Coverage scoped to `src/lib/domain/**` only
- Full coverage of the domain layer is the target
- No coverage threshold enforced in config (no `thresholds` property)

**Coverage Config:**
```typescript
coverage: {
  provider: "v8",
  include: ["src/lib/domain/**"],
}
```

**View Coverage:**
```bash
cd web-app
npm run test:coverage
```

**What is covered:**
- All modules in `web-app/src/lib/domain/` (18 modules with corresponding test files)
- Non-domain tests in `web-app/src/lib/__tests__/` (4 additional test files for `ai-generation`, `subscription-state`, `date-input`, `write-validation`)

**What is NOT covered:**
- React components (no component tests)
- Server actions (no integration tests)
- API routes (no API tests)
- Middleware (no middleware tests)
- Firebase interactions (no Firestore/Auth tests)

## Common Patterns

**Testing Pure Functions:**
```typescript
describe("functionName", () => {
  it("describes expected behavior", () => {
    expect(functionName(input)).toBe(expectedOutput);
  });
  it("handles edge case", () => {
    expect(functionName(edgeCaseInput)).toBe(fallbackOutput);
  });
});
```

**Testing with Multipliers:**
```typescript
it("applies energy multiplier", () => {
  const withEnergy = applyWeights(exercises, maxes, 0.85, 1.0);
  const withoutEnergy = applyWeights(exercises, maxes, 1.0, 1.0);
  expect(withEnergy[0].weightKg!).toBeLessThanOrEqual(withoutEnergy[0].weightKg!);
});
```

**Testing Enum Exhaustiveness:**
```typescript
it("all phases return a non-empty title", () => {
  const phases = ["menstrual", "follicular", "ovulation", "luteal"] as const;
  for (const phase of phases) {
    const rec = getPhaseRecommendation(phase);
    expect(rec.title.length).toBeGreaterThan(0);
  }
});
```

**Testing Feature Catalogs:**
```typescript
it("PLUS_FEATURES contains 11 features", () => {
  expect(PLUS_FEATURES).toHaveLength(11);
});

it("every plus feature is accessible at premium tier", () => {
  for (const feature of PLUS_FEATURES) {
    expect(canAccess(feature, "premium")).toBe(true);
  }
});
```

**Testing Null/Undefined Handling:**
```typescript
it("null -> 1.0", () => expect(cyclePhaseMultiplier(null)).toBe(1.0));
it("undefined -> 1.0", () => expect(cyclePhaseMultiplier(undefined)).toBe(1.0));
it("unknown -> 1.0", () => expect(cyclePhaseMultiplier("unknown_phase")).toBe(1.0));
```

**Testing Date-Dependent Logic:**
```typescript
// Use explicit reference dates to avoid time-dependent test failures
it("detects menstrual phase on day 2", () => {
  const start = localDate(2024, 1, 1);
  const ref   = localDate(2024, 1, 2);
  const logs: PeriodLog[] = [{ startDate: start }];
  const result = calculateCycleStatus(logs, defaultSettings, ref);
  expect(result!.currentPhase).toBe("menstrual");
});
```

**Async Testing:**
- Not applicable to domain tests (all synchronous)
- Non-domain tests in `web-app/src/lib/__tests__/` are also synchronous (testing pure logic functions)

**Error Testing:**
```typescript
it("rejects invalid focus values", () => {
  expect(() =>
    validateAIWorkoutRequest({
      time: 30,
      focus: "bad",
      energy: "medium",
      equipment: "full_gym",
    })
  ).toThrow("focus is invalid.");
});
```

## When Adding New Tests

**Domain module:**
1. Create `web-app/src/lib/domain/new-module.ts` with pure functions
2. Create `web-app/src/lib/domain/__tests__/new-module.test.ts`
3. Add helper factories at the top of the test file
4. Add one `describe` block per exported function
5. Cover happy path, edge cases, and boundary values
6. Export from `web-app/src/lib/domain/index.ts`

**Non-domain module:**
1. If the module contains pure logic (like `ai-generation.ts`), add tests to `web-app/src/lib/__tests__/`
2. If the module requires Firebase or external dependencies, no automated test pattern exists currently

**iOS domain module:**
1. Create test file in `SundeeFundee/Tests/SundeeFundeeKitTests/DomainTests/`
2. Use XCTest or Swift Testing framework
3. Add `@testable import SundeeFundeeKit`
4. Use `private` helper factory functions

## Test Count Summary

**Web app:**
- 18 domain test files in `web-app/src/lib/domain/__tests__/`
- 4 non-domain test files in `web-app/src/lib/__tests__/`
- Total: 22 test files

**iOS app:**
- 32 test files across 5 directories
- 18 domain test files
- 3 data layer test files
- 3 model/viewmodel test files
- 2 activity/auth test files
- 6 additional domain test files not present in web app (ChartDataAggregator, CyclePhaseHelper, DataExportService, PlateauDetector, PreferenceLearner, ScheduleReshuffler, SubstitutionRanker, WeeklyLoadAnalyzer)

---

*Testing analysis: 2026-04-08*
