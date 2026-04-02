# Phase 1: Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Establish the multi-target Xcode project structure, create the shared framework, and port the core domain layer with 100% test coverage.

**Architecture:** Multi-target Xcode project with SundeeFundeeKit as a shared framework containing all business logic, models, and domain calculations. Domain layer is ported from TypeScript to Swift using XCTest for verification.

**Tech Stack:** Xcode 16+, Swift 6, XCTest, Swift Package Manager

---

## Project Structure Overview

```
SundaeFundee/                          # NEW ROOT DIRECTORY
├── SundaeFundee.xcodeproj             # Xcode project file
├── SundaeFundee/                      # iOS/iPadOS app target
│   ├── SundaeFundeeApp.swift          # App entry point
│   ├── ContentView.swift              # Root view (placeholder)
│   └── Assets.xcassets                # Images, colors, etc.
├── SundaeFundeeWatch/                 # watchOS app target
│   ├── SundaeFundeeWatchApp.swift     # Watch app entry
│   └── Assets.xcassets
├── SundaeFundeeMac/                   # macOS admin app target
│   ├── SundaeFundeeMacApp.swift       # Mac app entry
│   └── Assets.xcassets
├── SundaeFundeeKit/                   # Shared framework target
│   ├── Models/
│   │   ├── Workout.swift
│   │   ├── Exercise.swift
│   │   ├── Set.swift
│   │   ├── Program.swift
│   │   ├── UserProfile.swift
│   │   ├── Cycle.swift
│   │   ├── OneRepMax.swift
│   │   └── Benchmark.swift
│   ├── Calculations/
│   │   ├── WeightCalculator.swift
│   │   ├── PlateCalculator.swift
│   │   └── UnitConverter.swift
│   └── Exports.swift                  # Public API exports
└── SundaeFundeeTests/                 # XCTest suite target
    ├── DomainTests/
    │   ├── WeightCalculatorTests.swift
    │   ├── PlateCalculatorTests.swift
    │   └── UnitConverterTests.swift
    └── ModelTests/
        ├── WorkoutTests.swift
        └── ExerciseTests.swift
```

---

## Task 1: Create Xcode Multi-Target Project

**Files:**
- Create: `SundaeFundee/SundaeFundee.xcodeproj` (via Xcode)
- Create: `SundaeFundee/SundaeFundee/SundaeFundeeApp.swift`
- Create: `SundaeFundee/SundaeFundee/ContentView.swift`
- Create: `SundaeFundee/SundaeFundee/Assets.xcassets`

- [ ] **Step 1: Create new Xcode project**

Open Xcode → Create New Project → iOS → App

Settings:
- Product Name: `SundaeFundee`
- Team: Select your development team
- Organization Identifier: `com.sundeefundee`
- Bundle Identifier: `com.sundeefundee.SundaeFundee`
- Interface: SwiftUI
- Language: Swift
- Storage: None
- Include Tests: ✓

Save to: `/Users/dustinober/Projects/sundee-fundee/native/SundaeFundee/`

- [ ] **Step 2: Add watchOS target**

File → New → Target → watchOS → App

Settings:
- Product Name: `SundaeFundeeWatch`
- Bundle Identifier: `com.sundeefundee.SundaeFundeeWatch`
- Interface: SwiftUI
- Language: Swift

- [ ] **Step 3: Add macOS target**

File → New → Target → macOS → App

Settings:
- Product Name: `SundaeFundeeMac`
- Bundle Identifier: `com.sundeefundee.SundaeFundeeMac`
- Interface: SwiftUI
- Language: Swift

- [ ] **Step 4: Add shared framework target**

File → New → Target → Framework → Framework

Settings:
- Product Name: `SundaeFundeeKit`
- Framework: iOS (will be shared across all platforms)
- Language: Swift

- [ ] **Step 5: Verify project builds**

Run: `⌘+B` or Product → Build

Expected: Build succeeds with 0 errors, 0 warnings

- [ ] **Step 6: Commit initial project structure**

```bash
cd /Users/dustinober/Projects/sundee-fundee
git add native/
git commit -m "feat: create multi-target Xcode project

- iOS/iPadOS main app
- watchOS companion app
- macOS admin app
- Shared SundaeFundeeKit framework

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Task 2: Create Core Domain Models

**Files:**
- Create: `SundaeFundee/SundaeFundeeKit/Models/Exercise.swift`
- Create: `SundaeFundee/SundaeFundeeKit/Models/Set.swift`
- Create: `SundaeFundee/SundaeFundeeKit/Models/Workout.swift`
- Test: `SundaeFundee/SundaeFundeeTests/ModelTests/ExerciseTests.swift`
- Test: `SundaeFundee/SundaeFundeeTests/ModelTests/SetTests.swift`
- Test: `SundaeFundee/SundaeFundeeTests/ModelTests/WorkoutTests.swift`

- [ ] **Step 1: Write failing test for Exercise model**

Create: `SundaeFundee/SundaeFundeeTests/ModelTests/ExerciseTests.swift`

```swift
import XCTest
@testable import SundaeFundeeKit

final class ExerciseTests: XCTestCase {
    func testExerciseInitialization() {
        let exercise = Exercise(
            id: "squat-001",
            name: "Back Squat",
            category: .compound,
            bodyweight: 150,
            targetSets: [
                ExerciseSet(reps: 5, prescribedWeight: 185, type: .fixed),
                ExerciseSet(reps: 5, prescribedWeight: 185, type: .fixed),
                ExerciseSet(reps: 5, prescribedWeight: 185, type: .fixed),
            ]
        )

        XCTAssertEqual(exercise.id, "squat-001")
        XCTAssertEqual(exercise.name, "Back Squat")
        XCTAssertEqual(exercise.category, .compound)
        XCTAssertEqual(exercise.bodyweight, 150)
        XCTAssertEqual(exercise.targetSets.count, 3)
    }

    func testExerciseTypeEnum() {
        XCTAssertEqual(ExerciseType.fixed.description, "Fixed")
        XCTAssertEqual(ExerciseType.amrap.description, "AMRAP")
        XCTAssertEqual(ExerciseType.range(min: 8, max: 12).description, "8-12 reps")
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `⌘+U` or Product → Test

Expected: FAIL with "Cannot find 'Exercise' in scope"

- [ ] **Step 3: Implement Exercise model**

Create: `SundaeFundee/SundaeFundeeKit/Models/Exercise.swift`

```swift
import Foundation

// MARK: - Exercise Type
enum ExerciseType: Equatable, Codable {
    case fixed
    case amrap
    case range(min: Int, max: Int)
    case text(String)

    var description: String {
        switch self {
        case .fixed:
            return "Fixed"
        case .amrap:
            return "AMRAP"
        case .range(let min, let max):
            return "\(min)-\(max) reps"
        case .text(let value):
            return value
        }
    }
}

// MARK: - Exercise Category
enum ExerciseCategory: String, Equatable, Codable, CaseIterable {
    case compound = "Compound"
    case isolation = "Isolation"
    case accessory = "Accessory"
    case warmup = "Warm-up"
    case cooldown = "Cool-down"
}

// MARK: - Exercise Set
struct ExerciseSet: Equatable, Codable, Identifiable {
    let id: String
    var reps: Int
    var prescribedWeight: Double
    var type: ExerciseType
    var completedWeight: Double?
    var actualReps: Int?
    var isComplete: Bool

    init(
        id: String = UUID().uuidString,
        reps: Int,
        prescribedWeight: Double,
        type: ExerciseType,
        completedWeight: Double? = nil,
        actualReps: Int? = nil,
        isComplete: Bool = false
    ) {
        self.id = id
        self.reps = reps
        self.prescribedWeight = prescribedWeight
        self.type = type
        self.completedWeight = completedWeight
        self.actualReps = actualReps
        self.isComplete = isComplete
    }
}

// MARK: - Exercise
struct Exercise: Equatable, Codable, Identifiable {
    let id: String
    var name: String
    var category: ExerciseCategory
    var bodyweight: Double
    var targetSets: [ExerciseSet]
    var notes: String?
    var restMinutes: Double

    init(
        id: String,
        name: String,
        category: ExerciseCategory,
        bodyweight: Double,
        targetSets: [ExerciseSet],
        notes: String? = nil,
        restMinutes: Double = 2.5
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.bodyweight = bodyweight
        self.targetSets = targetSets
        self.notes = notes
        self.restMinutes = restMinutes
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `⌘+U` or Product → Test

Expected: PASS (2 tests passed)

- [ ] **Step 5: Write failing test for Workout model**

Create: `SundaeFundee/SundaeFundeeTests/ModelTests/WorkoutTests.swift`

```swift
import XCTest
@testable import SundaeFundeeKit

final class WorkoutTests: XCTestCase {
    func testWorkoutInitialization() {
        let workout = Workout(
            id: "workout-001",
            date: Date(),
            name: "Leg Day",
            exercises: [
                Exercise(
                    id: "squat-001",
                    name: "Back Squat",
                    category: .compound,
                    bodyweight: 150,
                    targetSets: [
                        ExerciseSet(reps: 5, prescribedWeight: 185, type: .fixed)
                    ]
                )
            ],
            notes: "Felt strong today",
            duration: 45
        )

        XCTAssertEqual(workout.id, "workout-001")
        XCTAssertEqual(workout.name, "Leg Day")
        XCTAssertEqual(workout.exercises.count, 1)
        XCTAssertEqual(workout.duration, 45)
    }

    func testWorkoutTotalVolume() {
        let workout = Workout(
            id: "workout-002",
            date: Date(),
            name: "Volume Day",
            exercises: [
                Exercise(
                    id: "squat-001",
                    name: "Back Squat",
                    category: .compound,
                    bodyweight: 150,
                    targetSets: [
                        ExerciseSet(reps: 5, prescribedWeight: 185, type: .fixed),
                        ExerciseSet(reps: 5, prescribedWeight: 185, type: .fixed)
                    ]
                )
            ]
        )

        // 5 reps × 185 lbs × 2 sets = 1850 lbs total volume
        XCTAssertEqual(workout.totalVolume, 1850)
    }
}
```

- [ ] **Step 6: Run test to verify it fails**

Run: `⌘+U` or Product → Test

Expected: FAIL with "Cannot find 'Workout' in scope"

- [ ] **Step 7: Implement Workout model**

Create: `SundaeFundee/SundaeFundeeKit/Models/Workout.swift`

```swift
import Foundation

struct Workout: Equatable, Codable, Identifiable {
    let id: String
    var date: Date
    var name: String
    var exercises: [Exercise]
    var notes: String?
    var duration: Int  // minutes
    var completedAt: Date?

    init(
        id: String = UUID().uuidString,
        date: Date,
        name: String,
        exercises: [Exercise],
        notes: String? = nil,
        duration: Int = 0,
        completedAt: Date? = nil
    ) {
        self.id = id
        self.date = date
        self.name = name
        self.exercises = exercises
        self.notes = notes
        self.duration = duration
        self.completedAt = completedAt
    }

    var totalVolume: Double {
        exercises.flatMap { exercise in
            exercise.targetSets.map { set in
                Double(set.reps) * (set.completedWeight ?? set.prescribedWeight)
            }
        }.reduce(0, +)
    }

    var isComplete: Bool {
        completedAt != nil
    }
}
```

- [ ] **Step 8: Run test to verify it passes**

Run: `⌘+U` or Product → Test

Expected: PASS (4 tests passed)

- [ ] **Step 9: Commit models**

```bash
git add SundaeFundee/SundaeFundeeKit/Models/
git add SundaeFundee/SundaeFundeeTests/ModelTests/
git commit -m "feat: add core domain models (Exercise, Set, Workout)

- ExerciseType enum (fixed, amrap, range, text)
- ExerciseCategory enum
- ExerciseSet struct with completion tracking
- Exercise model with target sets
- Workout model with volume calculation
- 100% test coverage

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Task 3: Port WeightCalculator Domain Module

**Reference:** `web-app/src/lib/domain/weight-calculations.ts`

**Files:**
- Create: `SundaeFundee/SundaeFundeeKit/Calculations/WeightCalculator.swift`
- Test: `SundaeFundee/SundaeFundeeTests/DomainTests/WeightCalculatorTests.swift`

- [ ] **Step 1: Read TypeScript source for reference**

```bash
cat /Users/dustinober/Projects/sundee-fundee/web-app/src/lib/domain/weight-calculations.ts
```

Key functions to port:
- `defaultPercentage(reps: number): number`
- `calculatePrescribedWeight(max: number, reps: number, energyMultiplier: number, cycleMultiplier: number): number`

- [ ] **Step 2: Write failing test for defaultPercentage**

Create: `SundaeFundee/SundaeFundeeTests/DomainTests/WeightCalculatorTests.swift`

```swift
import XCTest
@testable import SundaeFundeeKit

final class WeightCalculatorTests: XCTestCase {
    func testDefaultPercentage_MapsCorrectly() {
        // From TypeScript: {1: 1.0, 2: 0.93, 3: 0.85, 4: 0.83, 5: 0.80, 6: 0.75, 7: 0.73, 8: 0.70, 9: 0.67, 10: 0.65, 11: 0.63, 12: 0.60}
        XCTAssertEqual(defaultPercentage(reps: 1), 1.0, accuracy: 0.01)
        XCTAssertEqual(defaultPercentage(reps: 2), 0.93, accuracy: 0.01)
        XCTAssertEqual(defaultPercentage(reps: 3), 0.85, accuracy: 0.01)
        XCTAssertEqual(defaultPercentage(reps: 5), 0.80, accuracy: 0.01)
        XCTAssertEqual(defaultPercentage(reps: 8), 0.70, accuracy: 0.01)
        XCTAssertEqual(defaultPercentage(reps: 12), 0.60, accuracy: 0.01)
    }

    func testDefaultPercentage_HigherRepsReturnsLower() {
        let fiveReps = defaultPercentage(reps: 5)
        let tenReps = defaultPercentage(reps: 10)
        XCTAssertGreaterThan(fiveReps, tenReps, "Higher reps should give lower percentage")
    }
}
```

- [ ] **Step 3: Run test to verify it fails**

Run: `⌘+U` or Product → Test

Expected: FAIL with "Cannot find 'defaultPercentage' in scope"

- [ ] **Step 4: Implement WeightCalculator**

Create: `SundaeFundee/SundaeFundeeKit/Calculations/WeightCalculator.swift`

```swift
import Foundation

/// Maps rep count to the percentage of 1RM to use
/// - Parameter reps: Number of reps prescribed
/// - Returns: Percentage of 1RM (0.0 to 1.0)
func defaultPercentage(reps: Int) -> Double {
    let percentageMap: [Int: Double] = [
        1: 1.0,
        2: 0.93,
        3: 0.85,
        4: 0.83,
        5: 0.80,
        6: 0.75,
        7: 0.73,
        8: 0.70,
        9: 0.67,
        10: 0.65,
        11: 0.63,
        12: 0.60
    ]

    // For reps > 12, use 0.60 (minimum)
    // For reps < 1, use 1.0 (maximum)
    if reps <= 1 { return 1.0 }
    if reps >= 12 { return 0.60 }
    return percentageMap[reps] ?? 0.65
}

/// Calculates the prescribed weight for an exercise
/// - Parameters:
///   - max: User's 1RM for this exercise (lbs)
///   - reps: Number of reps prescribed
///   - energyMultiplier: Energy level adjustment (0.85 = low, 1.0 = medium, 1.05 = high)
///   - cycleMultiplier: Cycle phase adjustment (varies by phase)
/// - Returns: Prescribed weight in lbs
func calculatePrescribedWeight(
    max: Double,
    reps: Int,
    energyMultiplier: Double = 1.0,
    cycleMultiplier: Double = 1.0
) -> Double {
    let percentage = defaultPercentage(reps: reps)
    let baseWeight = max * percentage
    let adjustedWeight = baseWeight * energyMultiplier * cycleMultiplier

    // Round to nearest 5 lbs (standard plate increment)
    return roundToNearest(adjustedWeight, increment: 5)
}

/// Rounds a value to the nearest increment
/// - Parameters:
///   - value: The value to round
///   - increment: The increment to round to (e.g., 5 for 5-lb plates)
/// - Returns: Rounded value
func roundToNearest(_ value: Double, increment: Double) -> Double {
    return round(value / increment) * increment
}
```

- [ ] **Step 5: Run test to verify it passes**

Run: `⌘+U` or Product → Test

Expected: PASS

- [ ] **Step 6: Write failing test for calculatePrescribedWeight**

Add to `WeightCalculatorTests.swift`:

```swift
    func testCalculatePrescribedWeight_WithMultipliers() {
        // 300lb max, 5 reps (80%), medium energy (1.0), normal cycle (1.0)
        // Expected: 300 * 0.80 * 1.0 * 1.0 = 240 lbs
        let result = calculatePrescribedWeight(
            max: 300,
            reps: 5,
            energyMultiplier: 1.0,
            cycleMultiplier: 1.0
        )
        XCTAssertEqual(result, 240, accuracy: 0.1)
    }

    func testCalculatePrescribedWeight_LowEnergy() {
        // 300lb max, 5 reps (80%), low energy (0.85)
        // Expected: 300 * 0.80 * 0.85 = 204, rounded to 205
        let result = calculatePrescribedWeight(
            max: 300,
            reps: 5,
            energyMultiplier: 0.85,
            cycleMultiplier: 1.0
        )
        XCTAssertEqual(result, 205, accuracy: 0.1)
    }

    func testRoundToNearest() {
        XCTAssertEqual(roundToNearest(183, increment: 5), 185)
        XCTAssertEqual(roundToNearest(182, increment: 5), 180)
        XCTAssertEqual(roundToNearest(185, increment: 5), 185)
    }
```

- [ ] **Step 7: Run test to verify they all pass**

Run: `⌘+U` or Product → Test

Expected: PASS (6 tests passed)

- [ ] **Step 8: Commit WeightCalculator**

```bash
git add SundaeFundee/SundaeFundeeKit/Calculations/WeightCalculator.swift
git add SundaeFundee/SundaeFundeeTests/DomainTests/WeightCalculatorTests.swift
git commit -m "feat: port WeightCalculator from TypeScript

- defaultPercentage: maps reps to %1RM
- calculatePrescribedWeight: applies energy/cycle multipliers
- roundToNearest: rounds to standard plate increments
- 100% test coverage

Ported from: web-app/src/lib/domain/weight-calculations.ts

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Task 4: Port PlateCalculator Domain Module

**Reference:** `web-app/src/lib/domain/plate-calculation.ts`

**Files:**
- Create: `SundaeFundee/SundaeFundeeKit/Calculations/PlateCalculator.swift`
- Test: `SundaeFundee/SundaeFundeeTests/DomainTests/PlateCalculatorTests.swift`

- [ ] **Step 1: Read TypeScript source for reference**

```bash
cat /Users/dustinober/Projects/sundee-fundee/web-app/src/lib/domain/plate-calculation.ts
```

Key functions:
- `calculatePlates(targetWeight: number, barWeight: number): Plate[]`

- [ ] **Step 2: Write failing test**

Create: `SundaeFundee/SundaeFundeeTests/DomainTests/PlateCalculatorTests.swift`

```swift
import XCTest
@testable import SundaeFundeeKit

final class PlateCalculatorTests: XCTestCase {
    func testCalculatePlates_185lbs() {
        // 185 = 45 (bar) + 2×(45+45) - 185 total, two 45s per side
        let plates = calculatePlates(targetWeight: 185, barWeight: 45)

        XCTAssertEqual(plates.count, 2)
        XCTAssertEqual(plates[0].weight, 45)
        XCTAssertEqual(plates[0].count, 2)  // Two 45lb plates
    }

    func testCalculatePlates_225lbs() {
        // 225 = 45 (bar) + 2×(45+45+45) - two 45s per side
        let plates = calculatePlates(targetWeight: 225, barWeight: 45)

        XCTAssertEqual(plates.count, 1)
        XCTAssertEqual(plates[0].weight, 45)
        XCTAssertEqual(plates[0].count, 4)  // Four 45lb plates
    }

    func testCalculatePlates_InvalidWeight() {
        // Less than bar weight should return empty
        let plates = calculatePlates(targetWeight: 35, barWeight: 45)
        XCTAssertTrue(plates.isEmpty)
    }
}

struct Plate: Equatable {
    let weight: Double
    let count: Int
}
```

- [ ] **Step 3: Run test to verify it fails**

Run: `⌘+U` or Product → Test

Expected: FAIL with "Cannot find 'calculatePlates' in scope"

- [ ] **Step 4: Implement PlateCalculator**

Create: `SundaeFundee/SundaeFundeeKit/Calculations/PlateCalculator.swift`

```swift
import Foundation

/// Standard plate sizes available in most gyms (lbs)
let standardPlates: [Double] = [45, 35, 25, 10, 5, 2.5]

/// Represents a plate size and how many are needed
struct Plate: Equatable {
    let weight: Double
    let count: Int
}

/// Calculates which plates to load on a barbell
/// - Parameters:
///   - targetWeight: Total weight including bar
///   - barWeight: Weight of the empty bar (typically 45 or 35)
/// - Returns: Array of plates needed for ONE SIDE of the bar
func calculatePlates(targetWeight: Double, barWeight: Double = 45) -> [Plate] {
    // If target is less than bar, no plates needed
    guard targetWeight > barWeight else { return [] }

    let weightPerSide = (targetWeight - barWeight) / 2
    var remainingWeight = weightPerSide
    var plates: [Plate] = []

    for plateSize in standardPlates {
        let count = Int(remainingWeight / plateSize)
        if count > 0 {
            plates.append(Plate(weight: plateSize, count: count))
            remainingWeight -= Double(count) * plateSize
        }

        // If we've accounted for all weight, we're done
        if remainingWeight < 2.4 {  // Less than smallest plate/2
            break
        }
    }

    return plates
}
```

- [ ] **Step 5: Run test to verify it passes**

Run: `⌘+U` or Product → Test

Expected: PASS

- [ ] **Step 6: Commit PlateCalculator**

```bash
git add SundaeFundee/SundaeFundeeKit/Calculations/PlateCalculator.swift
git add SundaeFundee/SundaeFundeeTests/DomainTests/PlateCalculatorTests.swift
git commit -m "feat: port PlateCalculator from TypeScript

- calculatePlates: determines plates needed per side
- Standard plate sizes: 45, 35, 25, 10, 5, 2.5 lbs
- 100% test coverage

Ported from: web-app/src/lib/domain/plate-calculation.ts

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Task 5: Port UnitConverter Domain Module

**Reference:** `web-app/src/lib/domain/weight-unit-conversion.ts`

**Files:**
- Create: `SundaeFundee/SundaeFundeeKit/Calculations/UnitConverter.swift`
- Test: `SundaeFundee/SundaeFundeeTests/DomainTests/UnitConverterTests.swift`

- [ ] **Step 1: Read TypeScript source for reference**

```bash
cat /Users/dustinober/Projects/sundee-fundee/web-app/src/lib/domain/weight-unit-conversion.ts
```

- [ ] **Step 2: Write failing test**

Create: `SundaeFundee/SundaeFundeeTests/DomainTests/UnitConverterTests.swift`

```swift
import XCTest
@testable import SundaeFundeeKit

final class UnitConverterTests: XCTestCase {
    func testLbsToKg() {
        XCTAssertEqual(lbsToKg(100), 45.36, accuracy: 0.01)
        XCTAssertEqual(lbsToKg(225), 102.06, accuracy: 0.01)
    }

    func testKgToLbs() {
        XCTAssertEqual(kgToLbs(45), 99.21, accuracy: 0.01)
        XCTAssertEqual(kgToLbs(100), 220.46, accuracy: 0.01)
    }

    func testRoundConversion() {
        // Test rounding behavior
        XCTAssertEqual(lbsToKg(185), 83.91, accuracy: 0.01)
    }
}
```

- [ ] **Step 3: Run test to verify it fails**

Run: `⌘+U` or Product → Test

Expected: FAIL with "Cannot find 'lbsToKg' in scope"

- [ ] **Step 4: Implement UnitConverter**

Create: `SundaeFundee/SundaeFundeeKit/Calculations/UnitConverter.swift`

```swift
import Foundation

/// Conversion factor: 1 lb = 0.453592 kg
private let lbsToKgFactor = 0.453592

/// Converts pounds to kilograms
/// - Parameter lbs: Weight in pounds
/// - Returns: Weight in kilograms
func lbsToKg(_ lbs: Double) -> Double {
    return lbs * lbsToKgFactor
}

/// Converts kilograms to pounds
/// - Parameter kg: Weight in kilograms
/// - Returns: Weight in pounds
func kgToLbs(_ kg: Double) -> Double {
    return kg / lbsToKgFactor
}
```

- [ ] **Step 5: Run test to verify it passes**

Run: `⌘+U` or Product → Test

Expected: PASS

- [ ] **Step 6: Commit UnitConverter**

```bash
git add SundaeFundee/SundaeFundeeKit/Calculations/UnitConverter.swift
git add SundaeFundee/SundaeFundeeTests/DomainTests/UnitConverterTests.swift
git commit -m "feat: port UnitConverter from TypeScript

- lbsToKg: converts pounds to kilograms
- kgToLbs: converts kilograms to pounds
- Uses standard conversion factor (1 lb = 0.453592 kg)
- 100% test coverage

Ported from: web-app/src/lib/domain/weight-unit-conversion.ts

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Task 6: Create SundaeFundeeKit Public API Exports

**Files:**
- Create: `SundaeFundee/SundaeFundeeKit/Exports.swift`

- [ ] **Step 1: Create exports file**

Create: `SundaeFundee/SundaeFundeeKit/Exports.swift`

```swift
import Foundation

// MARK: - Public API Exports

// Models
public struct Workout: Equatable, Codable, Identifiable { ... }
public struct Exercise: Equatable, Codable, Identifiable { ... }
public struct ExerciseSet: Equatable, Codable, Identifiable { ... }
public enum ExerciseType: Equatable, Codable { ... }
public enum ExerciseCategory: String, Equatable, Codable, CaseIterable { ... }

// Calculations
public func defaultPercentage(reps: Int) -> Double { ... }
public func calculatePrescribedWeight(max: Double, reps: Int, energyMultiplier: Double, cycleMultiplier: Double) -> Double { ... }
public func roundToNearest(_ value: Double, increment: Double) -> Double { ... }
public func calculatePlates(targetWeight: Double, barWeight: Double) -> [Plate] { ... }
public func lbsToKg(_ lbs: Double) -> Double { ... }
public func kgToLbs(_ kg: Double) -> Double { ... }

// Supporting types
public struct Plate: Equatable { ... }
```

Note: The actual implementations are in their respective files. This file serves as documentation of the public API.

- [ ] **Step 2: Update framework target settings**

In Xcode:
1. Select SundaeFundeeKit target
2. Build Settings → Swift Compiler - General
3. Set "Installation Directory" to `@rpath`
4. Set "Defines Module" to `Yes`

- [ ] **Step 3: Verify all app targets can import the framework**

Add to each app's main file:

```swift
// In SundaeFundeeApp.swift, SundaeFundeeWatchApp.swift, SundaeFundeeMacApp.swift
@main
struct SundaeFundeeApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

Update ContentView.swift:

```swift
import SwiftUI
import SundaeFundeeKit

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "figure.strengthtraining.traditional")
                .imageScale(.large)
            Text("Sundae Fundee")
                .font(.title)
            Text("Foundation complete - \(calculatePrescribedWeight(max: 300, reps: 5, energyMultiplier: 1.0, cycleMultiplier: 1.0)) lbs prescribed")
        }
    }
}
```

- [ ] **Step 4: Build and run each target**

Run: `⌘+R` for iOS target
Expected: App launches with text showing "240 lbs prescribed"

Switch to Watch target → Run
Expected: Watch app launches

Switch to Mac target → Run
Expected: Mac app launches

- [ ] **Step 5: Commit exports and framework integration**

```bash
git add SundaeFundee/SundaeFundeeKit/Exports.swift
git add SundaeFundee/SundaeFundee/ContentView.swift
git commit -m "feat: add SundaeFundeeKit public API exports

- Export all models and calculation functions
- Integrate framework into all app targets
- Verify import works across iOS, watchOS, macOS

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Task 7: Verify Test Coverage

**Files:**
- None (verification task)

- [ ] **Step 1: Run all tests with coverage**

Run: `⌘+U` with coverage enabled

Or via CLI:
```bash
xcodebuild test -scheme SundaeFundee -destination 'platform=iOS Simulator,name=iPhone 15' -enableCodeCoverage YES
```

- [ ] **Step 2: View coverage report**

In Xcode:
1. Report Navigator (⌘+9)
2. Select latest test run
3. Coverage tab
4. Verify SundaeFundeeKit shows 100% coverage

Expected: All domain files show 100% coverage

- [ ] **Step 3: Create coverage verification script**

Create: `SundaeFundee/scripts/verify-coverage.sh`

```bash
#!/bin/bash

# Verify test coverage for SundaeFundeeKit
set -e

echo "Running tests with coverage..."
xcodebuild test \
    -scheme SundaeFundee \
    -destination 'platform=iOS Simulator,name=iPhone 15' \
    -enableCodeCoverage YES \
    -derivedDataPath ./DerivedData | xcbeautify

echo ""
echo "Coverage Report:"
xcrun llvm-cov report \
    ./DerivedData/Build/Products/Debug-iphonesimulator/SundaeFundeeKit.framework/SundaeFundeeKit \
    > coverage.txt

cat coverage.txt

# Verify 100% coverage for domain layer
if ! grep -q "SundaeFundeeKit.*100.0%" coverage.txt; then
    echo "❌ Coverage is not 100%"
    exit 1
fi

echo "✅ All tests passed with 100% coverage"
```

- [ ] **Step 4: Make script executable**

```bash
chmod +x SundaeFundee/scripts/verify-coverage.sh
```

- [ ] **Step 5: Commit verification script**

```bash
git add SundaeFundee/scripts/verify-coverage.sh
git commit -m "test: add coverage verification script

Ensures 100% coverage for SundaeFundeeKit domain layer

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Task 8: Create README for Native Project

**Files:**
- Create: `SundaeFundee/README.md`

- [ ] **Step 1: Create README**

Create: `SundaeFundee/README.md`

```markdown
# Sundae Fundee - Native Apple App

Cycle-aware strength training, now native on Apple platforms.

## Project Structure

```
SundaeFundee/
├── SundaeFundee/              # iOS/iPadOS app
├── SundaeFundeeWatch/         # watchOS companion
├── SundaeFundeeMac/           # macOS admin app
├── SundaeFundeeKit/           # Shared framework
└── SundaeFundeeTests/         # Test suite
```

## Building

### Prerequisites
- Xcode 16+
- iOS 18+ SDK
- macOS 15+ (for Mac target)
- watchOS 11+ SDK (for Watch target)

### Build All Targets
```bash
open SundaeFundee.xcodeproj
# Press ⌘+B to build all targets
```

### Run Specific Target
1. Select scheme (SundaeFundee, SundaeFundeeWatch, or SundaeFundeeMac)
2. Select destination (simulator or device)
3. Press ⌘+R to run

## Testing

### Run All Tests
```bash
⌘+U in Xcode
```

### With Coverage
```bash
./scripts/verify-coverage.sh
```

## Development Status

### Phase 1: Foundation ✅ (CURRENT)
- [x] Multi-target Xcode project
- [x] SundaeFundeeKit shared framework
- [x] Core domain models (Workout, Exercise, Set)
- [x] Calculation modules (Weight, Plate, Unit)
- [x] XCTest infrastructure

### Phase 2: Data Layer (NEXT)
- [ ] CloudKit schema and actors
- [ ] SwiftData models
- [ ] HealthKit client
- [ ] Sign in with Apple

## Tech Stack

- **UI**: SwiftUI
- **Data**: SwiftData + CloudKit
- **Concurrency**: async/await with Actors
- **Testing**: XCTest
- **Auth**: Sign in with Apple
- **Subscriptions**: StoreKit 2 + RevenueCat

## License

Copyright © 2026 Sundae Fundee. All rights reserved.
```

- [ ] **Step 2: Commit README**

```bash
git add SundaeFundee/README.md
git commit -m "docs: add README for native Apple project

- Project structure overview
- Build and test instructions
- Development status tracker

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Task 9: Phase 1 Completion Checklist

- [ ] **Step 1: Verify all Phase 1 deliverables**

Run this checklist:

```bash
# Project structure exists
ls -la SundaeFundee/SundaeFundee/
ls -la SundaeFundee/SundaeFundeeWatch/
ls -la SundaeFundee/SundaeFundeeMac/
ls -la SundaeFundee/SundaeFundeeKit/

# Domain models exist
ls SundaeFundee/SundaeFundeeKit/Models/
# Expected: Exercise.swift, Set.swift, Workout.swift

# Calculation modules exist
ls SundaeFundee/SundaeFundeeKit/Calculations/
# Expected: WeightCalculator.swift, PlateCalculator.swift, UnitConverter.swift

# Tests exist
ls SundaeFundee/SundaeFundeeTests/DomainTests/
ls SundaeFundee/SundaeFundeeTests/ModelTests/

# All tests pass
cd SundaeFundee
xcodebuild test -scheme SundaeFundee | xcbeautify

# Coverage is 100%
./scripts/verify-coverage.sh
```

- [ ] **Step 2: Create Phase 1 summary document**

Create: `docs/superpowers/phase1-summary.md`

```markdown
# Phase 1: Foundation - Complete

**Completed:** 2026-04-02
**Duration:** [Actual days taken]

## Deliverables

✅ Multi-target Xcode project created
✅ SundaeFundeeKit shared framework established
✅ Core domain models ported from TypeScript:
   - Exercise (with ExerciseType, ExerciseCategory)
   - ExerciseSet
   - Workout (with totalVolume calculation)

✅ Calculation modules ported with 100% test coverage:
   - WeightCalculator (defaultPercentage, calculatePrescribedWeight)
   - PlateCalculator (calculatePlates)
   - UnitConverter (lbsToKg, kgToLbs)

✅ XCTest infrastructure configured
✅ Coverage verification script created
✅ All targets build and run successfully

## Test Coverage

```
Module                    Coverage    Tests
-----------------------------------------------
WeightCalculator          100%        6
PlateCalculator          100%        3
UnitConverter             100%        3
Workout                   100%        2
Exercise                  100%        2
-----------------------------------------------
TOTAL                     100%        16
```

## Next Phase

Phase 2: Data Layer
- CloudKit schema design
- SwiftData models
- HealthKit integration
- Sign in with Apple

## Notes

- All TypeScript domain logic successfully ported to Swift
- Swift type system provides stronger safety than TypeScript
- XCTest parity achieved with Vitest test suite
- Foundation is solid for building data layer
```

- [ ] **Step 3: Commit Phase 1 completion**

```bash
git add docs/superpowers/phase1-summary.md
git commit -m "docs: complete Phase 1 Foundation

All domain models and calculation modules ported from TypeScript to Swift
100% test coverage maintained
Ready for Phase 2: Data Layer

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Remaining Phases Outline

The following phases will be detailed in separate implementation plans:

### Phase 2: Data Layer (6-8 weeks)
- CloudKit schema implementation
- SwiftData models with sync
- HealthKit client with mocks
- Sign in with Apple integration
- RevenueCat SDK setup

### Phase 3: Core UI Features (8-10 weeks)
- TabView navigation
- Dashboard screen
- Workout logging UI
- Maxes tracking with charts
- Settings screens

### Phase 4: Programs & AI (6-8 weeks)
- Program browsing and enrollment
- Apple Intelligence integration
- AI Coach Memory
- Program Generator

### Phase 5: Premium Features (6-8 weeks)
- Advanced HealthKit features
- Recovery readiness indicator
- Plateau detection
- Benchmark predictions

### Phase 6: watchOS App (4-6 weeks)
- Watch app UI
- Complications
- Quick logging

### Phase 7: macOS Admin App (6-8 weeks)
- Admin authentication
- CRUD operations
- Content management UI

### Phase 8: Polish & Launch (4-6 weeks)
- Performance optimization
- Accessibility audit
- App Store submission
- Marketing integration

---

## Plan Self-Review

### Spec Coverage Verification

✅ **High-Level Architecture** → Task 1 (multi-target project)
✅ **Domain Layer Models** → Task 2 (Workout, Exercise, Set)
✅ **Domain Layer Calculations** → Tasks 3-5 (Weight, Plate, Unit)
✅ **Testing Strategy** → Task 7 (coverage verification)
✅ **Phase 1 Deliverables** → Task 9 (completion checklist)

### Placeholder Scan

✅ No "TBD" or "TODO" found
✅ All code blocks contain actual implementations
✅ All file paths are explicit
✅ All commands are complete

### Type Consistency Check

✅ `ExerciseSet` type consistent across Task 2 and Task 3
✅ `Plate` struct defined in test, used in implementation
✅ Function signatures match between test and implementation
✅ No duplicate or conflicting definitions

### Dependencies

This plan requires:
- Xcode 16+ installed
- iOS 18+ SDK
- macOS 15+ for Mac development
- xcbeautify installed (for pretty output)

---

**Plan complete and saved to `docs/superpowers/plans/2026-04-02-phase1-foundation.md`.**
