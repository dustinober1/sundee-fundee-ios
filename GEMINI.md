# Sundee-Fundee Project Context

**Sundee-Fundee** is a native iOS strength training application designed with hormonal cycle awareness. It integrates menstrual cycle data with structured training programs to provide optimized recommendations.

## Project Overview
- **Platform**: iOS 17.0+
- **Language**: Swift 5.9
- **Frameworks**: SwiftUI, SwiftData, Swift Charts, CloudKit
- **Architecture**: MVVM using the `@Observable` macro and SwiftData for persistence.
- **Key Feature**: Periodized strength training programs synchronized with the user's menstrual cycle phases.

## Tech Stack & Architecture
- **UI**: Pure SwiftUI with modern `@Observable` view models.
- **Data Persistence**: SwiftData with automatic CloudKit synchronization (`iCloud.com.sundeefundee.app`).
- **Project Generation**: [XcodeGen](https://github.com/yonaskolb/XcodeGen) manages the `.xcodeproj` via `project.yml`.
- **Authentication**: Sign in with Apple (required for CloudKit identity).
- **State Management**: SwiftData's `ModelContext` passed to `@Observable` view models; Views use `@Query` for data fetching.

## Building and Running

### Prerequisites
- Xcode 15.4+
- XcodeGen: `brew install xcodegen`

### Key Commands
```bash
# Generate the Xcode project (Run this after modifications to project.yml or adding files)
xcodegen generate

# Build the application
xcodebuild -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 15'

# Run Unit Tests
xcodebuild test -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 15'
```

## Project Structure
- `SundeeFundee/App/`: Entry point and root view configuration.
- `SundeeFundee/Models/`: SwiftData `@Model` classes and supporting `Codable` types.
- `SundeeFundee/Views/`: Feature-organized SwiftUI views (Auth, Dashboard, Programs, etc.).
- `SundeeFundee/ViewModels/`: Logic for views using the `@Observable` macro.
- `SundeeFundee/Services/`: Singleton services like `ProgramRepository` for loading JSON-based programs.
- `SundeeFundee/Utilities/`: Pure logic namespaces (`WeightCalculations`, `CycleCalculations`) and helpers like `KeychainHelper`.
- `SundeeFundee/Resources/Programs/`: JSON definitions for training programs.

## Development Conventions

### Data Modeling (SwiftData)
- **ID Pattern**: Use `@Attribute(.unique) var id: String = UUID().uuidString`.
- **Enum Persistence**: Store enums as raw strings (e.g., `experienceLevelRaw`) and provide computed properties for the actual enum types to ensure compatibility with SwiftData and CloudKit.
- **Relationships**: Define cascading deletes or nullification as appropriate for workout history.

### View Models & State
- Use the `@Observable` macro for all view models.
- Methods that modify or fetch data should accept `ModelContext` as a parameter.
- Avoid third-party state management; rely on SwiftUI and SwiftData primitives.

### Logic & Calculations
- Keep business logic (weight rounding, 1RM percentages, cycle phase mapping) in static utility methods within enum namespaces (e.g., `WeightCalculations`).
- Always add unit tests for new calculation logic in `SundeeFundeeTests/`.

### Training Programs
- Programs are defined in JSON files within `SundeeFundee/Resources/Programs/`.
- `ProgramRepository` handles loading and caching these definitions at runtime.

## Testing
- **Unit Tests**: Located in `SundeeFundeeTests/`, using `XCTest`.
- **UI Tests**: Located in `SundeeFundeeUITests/`.
- Ensure `xcodegen generate` is run before testing to include any newly added test files in the target.
