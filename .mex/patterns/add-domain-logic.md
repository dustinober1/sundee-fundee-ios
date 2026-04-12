---
name: add-domain-logic
description: Adding new business logic to the DomainLayer. Use when implementing calculations, analyzers, or pure logic services.
triggers:
  - "domain logic"
  - "business logic"
  - "calculation"
  - "analyzer"
  - "pure function"
  - "DomainLayer"
edges:
  - target: context/conventions.md
    condition: when checking the enum-with-static-methods pattern
  - target: context/architecture.md
    condition: when understanding where domain logic fits
  - target: patterns/add-view-feature.md
    condition: when the domain logic needs to be consumed by a ViewModel
last_updated: 2026-04-11
---

# Add Domain Logic

## Context

Load `context/conventions.md` — domain logic follows the "pure enum with static methods" pattern strictly.

Key directories:
- Domain layer: `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/`
- Subdirectories: `Intelligence/`, `Cycle/`, `Injury/`, `Benchmark/`, `AIWorkout/`, `Program/`, `Coach/`, `Celebration/`, `Analytics/`, `Export/`
- Tests: `SundeeFundee/Tests/SundeeFundeeKitTests/DomainTests/`

## Steps

1. **Create the domain type** in the appropriate `DomainLayer/` subdirectory:
   - Must be a `public enum` with `static` methods — no cases, no instance state
   - Zero framework imports — only `Foundation` is allowed
   - All input/output types must be `Sendable` and `Equatable`
   - Accept data as parameters, return computed results — no side effects

2. **Define result types** as nested structs inside the enum:
   ```swift
   public enum MyAnalyzer {
       public struct Result: Sendable, Equatable {
           public let value: Double
           public let category: Category
       }
       public enum Category: String, Sendable, Equatable {
           case low, medium, high
       }
       public static func analyze(from data: [Input]) -> [Result] { ... }
   }
   ```

3. **Write tests** in `Tests/SundeeFundeeKitTests/DomainTests/`:
   - Use private factory helpers (e.g., `makeWorkout(daysAgo:duration:exercises:)`)
   - Test edge cases: empty input, single item, boundary values
   - Test is pure: no setup/teardown needed, no mocks

4. **Consume from ViewModel** — the ViewModel calls the static method and publishes the result

## Gotchas

- **No `import UIKit`/`import SwiftUI`** — domain layer is UI-framework-free. Only `Foundation`.
- **No classes** — enums enforce statelessness. If you need instance state, it belongs in a ViewModel.
- **No `DataClientProtocol` access** — domain functions receive data as parameters. The ViewModel fetches data and passes it in.
- **Multiplier composition** — cycle phase, recovery, and energy multipliers compose multiplicatively (`base * m1 * m2 * m3`), not additively
- **Benchmark encoding** — `roundsAndReps = rounds * 10000 + reps`. Higher is better.

## Verify

- [ ] Type is a `public enum` with static methods only
- [ ] No framework imports beyond `Foundation`
- [ ] All types conform to `Sendable` and `Equatable`
- [ ] Functions are pure — no side effects, no stored state
- [ ] Tests exist with factory helpers for test data
- [ ] `swift test` passes

## Debug

If tests fail:
1. Check date calculations — `Calendar.current` can produce different results based on locale/timezone. Use factory helpers like `makeDate()` for deterministic dates.
2. Check floating-point comparisons — use `XCTAssertEqual(a, b, accuracy:)` for doubles.
3. Verify `Sendable` conformance on all nested types.

## Update Scaffold
- [ ] Update `.mex/ROUTER.md` "Current Project State" if what's working/not built has changed
- [ ] Update any `.mex/context/` files that are now out of date
- [ ] If this is a new task type without a pattern, create one in `.mex/patterns/` and add to `INDEX.md`
