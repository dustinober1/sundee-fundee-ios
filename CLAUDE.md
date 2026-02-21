# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Commands

```bash
# Generate Xcode project from project.yml (run after cloning or modifying project.yml)
xcodegen generate

# Build
xcodebuild -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 15'

# Run all tests
xcodebuild test -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 15'

# Run specific test class
xcodebuild test -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:SundeeFundeeTests/WeightCalculationsTests
```

## Overview

Native iOS strength training app with hormonal cycle awareness. Built with SwiftUI and SwiftData for automatic CloudKit sync. Key features:
- Periodized training programs with 1RM-based weight prescriptions
- Menstrual cycle phase tracking with training recommendations
- Set-by-set workout logging with PR detection

**Requirements**: Xcode 15.4+, iOS 17.0+ (SwiftData), XcodeGen (`brew install xcodegen`)

## Tech Stack
- **UI**: SwiftUI (iOS 17+)
- **Data**: SwiftData with CloudKit (`iCloud.com.sundeefundee.app`)
- **Auth**: Sign in with Apple
- **State**: `@Observable` macro
- **Charts**: Swift Charts

## Project Structure

```
SundeeFundee/
├── App/                    # SundeeFundeeApp.swift, ContentView.swift
├── Models/                 # SwiftData @Model classes & Codable types
├── Views/                  # SwiftUI views by feature
├── ViewModels/             # @Observable view models
├── Services/               # ProgramRepository
├── Utilities/              # WeightCalculations, CycleCalculations, KeychainHelper
├── Resources/Programs/     # JSON training program definitions
└── Extensions/
```

## Auth Flow

`ContentView` switches on `authViewModel.authState`:
1. **loading** → ProgressView
2. **unauthenticated** → SignInView (Sign in with Apple)
3. **needsOnboarding** → OnboardingView (name, experience level, goals)
4. **authenticated** → MainTabView

Apple user ID stored in Keychain via `KeychainHelper`. On subsequent launches, `checkAuthState` looks up existing User by appleUserID.

## Key Patterns

### SwiftData Models
All models use `@Model` with `@Attribute(.unique) var id: String`. Enums stored as raw String values:
```swift
var experienceLevelRaw: String
var experienceLevel: ExperienceLevel {
    get { ExperienceLevel(rawValue: experienceLevelRaw) ?? .beginner }
    set { experienceLevelRaw = newValue.rawValue }
}
```

### View Models
`@Observable` classes receive `ModelContext` as method parameters:
```swift
@Observable
final class AuthenticationViewModel {
    var authState: AuthState = .loading
    func checkAuthState(context: ModelContext) { ... }
}
```

### Previews
Views use in-memory model containers:
```swift
#Preview {
    ContentView()
        .modelContainer(for: User.self, inMemory: true)
}
```

### Calculation Namespaces
Static methods in enum namespaces—no instances needed:
- `WeightCalculations` — roundToNearestFive, calculateTargetWeight, getNextRecommendedWeight, wasSetSuccessful
- `CycleCalculations` — calculateCycleStatus, getPhaseBoundaries, getPhaseRecommendation

## Program JSON Files

Training programs in `Resources/Programs/*.json`. Two formats exist (inconsistent—may need consolidation):

**Simple format** (`deadlift-5x5.json`): `daysPerWeek`, nested `days` array

**Full format** (`back-squat-complete-cycle.json`): `sessionsPerWeek`, `phases`, `sessions` per week → maps to `ProgramV2` model

`ExerciseValue` enum handles flexible reps/sets: `Int`, `"AMRAP"`, or `[min, max]`

## Cycle-Based Training Recommendations

`CycleCalculations.getPhaseRecommendation(phase:)` returns training guidance per menstrual phase:
- **menstrual**: Low intensity, recovery focus
- **follicular**: Moderate, building strength
- **ovulation**: Peak intensity, PR attempts
- **luteal**: Maintenance, technique work

## Where to Start

| Task | Entry Point |
|------|-------------|
| Add/modify training programs | `Resources/Programs/*.json`, `ProgramModels.swift` |
| Weight calculation logic | `Utilities/WeightCalculations.swift` |
| Cycle tracking features | `Utilities/CycleCalculations.swift`, `CycleModels.swift` |
| Auth changes | `ViewModels/AuthenticationViewModel.swift` |
| Add new SwiftData model | `Models/`, register in `SundeeFundeeApp.swift` ModelContainer |
| UI views | `Views/` organized by feature |
