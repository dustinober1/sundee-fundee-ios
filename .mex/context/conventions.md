---
name: conventions
description: How code is written in this project — naming, structure, patterns, and style. Load when writing new code or reviewing existing code.
triggers:
  - "convention"
  - "pattern"
  - "naming"
  - "style"
  - "how should I"
  - "what's the right way"
edges:
  - target: context/architecture.md
    condition: when a convention depends on understanding the system structure
  - target: context/stack.md
    condition: when a convention relates to a specific technology choice
  - target: patterns/add-view-feature.md
    condition: when writing a new View or ViewModel
  - target: patterns/add-domain-logic.md
    condition: when applying conventions to new domain logic
last_updated: 2026-04-11
---

# Conventions

## Naming

- **Files:** PascalCase matching the primary type (`WeeklyLoadAnalyzer.swift`, `AuthViewModel.swift`)
- **Types:** PascalCase structs/enums/classes (`ExerciseSet`, `CyclePhase`, `DataError`)
- **Functions:** camelCase, verb-first (`fetchExercises()`, `detectTrends(from:)`, `classifyMuscleGroup(_:)`)
- **ViewModels:** `[Feature]ViewModel` — e.g., `AuthViewModel`, `BenchmarksListViewModel`, `ActiveWorkoutSessionViewModel`
- **Protocols:** `[Name]Protocol` suffix — e.g., `DataClientProtocol`, `ContentClientProtocol`, `HealthClientProtocol`
- **CloudKit record types:** PascalCase strings matching model names — `"Workout"`, `"UserData"`, `"Exercise"`
- **Git commits:** `type(scope): description` — e.g., `feat(ui): wire ProgramsListViewModel to ContentClientProtocol`

## Structure

- **Business logic in DomainLayer/, never in ViewModels** — ViewModels call domain services, domain services are pure
- **Domain types are enums with static methods** — not classes, not structs with instance methods. Accept data, return data.
- **All models conform to `Codable`, `Sendable`, `Identifiable`, `Equatable`** — required for CloudKit serialization, concurrency, SwiftUI lists, and testing
- **ViewModels live in `UI/ViewModels/`**, Views in `UI/Views/[Feature]/`** — organized by feature area
- **Tests in `Tests/SundeeFundeeKitTests/[Layer]Tests/`** — mirror the source structure (DomainTests, DataLayerTests, ModelTests, ViewModelTests, AuthTests)
- **One factory per client type** — `DataClientFactory`, `HealthClientFactory`, `ContentClientFactory` — all singletons with thread-safe access
- **Mocks live in `DataLayer/Mocks/`** — `MockCloudKitClient`, `MockHealthKitClient`, `MockContentClient`

## Patterns

**ViewModel dependency injection with factory defaults:**
```swift
// Correct — injectable for tests, default for production
@MainActor
public class ExportViewModel: ObservableObject {
    private let dataClient: DataClientProtocol
    public init(dataClient: DataClientProtocol = DataClientFactory.shared.client) {
        self.dataClient = dataClient
    }
}

// Wrong — hardcoded client
public init() {
    self.dataClient = CloudKitClient(containerIdentifier: "iCloud.com.sundeefundee.app")
}
```

**Domain logic as pure static methods on enums:**
```swift
// Correct — pure enum, no state, no framework imports
public enum WeeklyLoadAnalyzer {
    public static func weeklySummaries(from records: [CompletedWorkoutRecord]) -> [WeeklySummary] { ... }
    public static func detectTrends(from summaries: [WeeklySummary]) -> [LoadTrend] { ... }
}

// Wrong — class with instance state or framework dependency
public class WeeklyLoadAnalyzer {
    private var records: [CompletedWorkoutRecord]
    ...
}
```

**Benchmark `roundsAndReps` encoding:**
```swift
// Encode: rounds * 10000 + reps
let score = rounds * 10000 + reps  // 3 rounds, 15 reps → 30015

// Decode
let rounds = score / 10000   // 30015 → 3
let reps = score % 10000     // 30015 → 15
```

**Multiplier-based adaptation — cycle phase, recovery, and energy compose multiplicatively:**
```swift
let adjustedWeight = baseWeight * cycleMultiplier * recoveryMultiplier * energyMultiplier
```

## Verify Checklist

Before presenting any code:
- [ ] All new types conform to `Sendable` (Swift 6 strict concurrency)
- [ ] Business logic is in DomainLayer, not in ViewModels or Views
- [ ] Domain functions are pure — no side effects, no framework imports
- [ ] ViewModels are `@MainActor ObservableObject` with `@Published` properties
- [ ] Data client access goes through `DataClientProtocol`, not directly to CloudKit
- [ ] Guest mode is respected — CloudKit writes gated with `!authViewModel.isGuest`
- [ ] No subscription paywalls or purchase flows introduced
- [ ] New models conform to `Codable`, `Sendable`, `Identifiable`, `Equatable`
