# Architecture Patterns

**Domain:** iOS App (Swift Package + Xcode Project)
**Researched:** 2026-04-08

## Recommended Architecture

```
sundee-fundee/
├── SundeeFundee/                    # Swift Package (domain logic, data layer, auth, subscriptions)
│   ├── Package.swift                # Package manifest
│   ├── Sources/SundeeFundeeKit/     # All source code
│   ├── Tests/SundeeFundeeKitTests/  # Test suite
│   ├── README.md                    # Package-specific docs
│   └── scripts/                     # Package-specific scripts
├── SundeeFundeeApp/                 # Xcode project (app target, widgets, assets, entitlements)
│   ├── project.yml                  # XcodeGen project definition
│   ├── SundeeFundee.xcodeproj/      # Generated Xcode project
│   ├── SundeeFundee/                # App target source
│   ├── SundeeFundeeWidgets/         # Widget extension
│   └── SundeeFundee.xcodeproj/      # Workspace with package reference
├── .github/
│   └── workflows/
│       └── ci.yml                   # iOS CI (test, build)
├── .gitignore                       # iOS-specific ignore patterns
├── CLAUDE.md                        # AI assistant context
├── README.md                        # Project documentation
└── Logo.jpeg                        # App icon source
```

### Component Boundaries

| Component | Responsibility | Communicates With |
|-----------|---------------|-------------------|
| **SundeeFundeeKit** (Swift Package) | Pure business logic, domain models, data layer, auth, subscriptions, HealthKit, CloudKit | Xcode targets via local package dependency |
| **SundeeFundee** (App Target) | SwiftUI views, view models, app lifecycle, Live Activities | SundeeFundeeKit (imported) |
| **SundeeFundeeWidgets** (Widget Extension) | Live Activity widget for workout tracking | SundeeFundeeKit (imported) |
| **project.yml** (XcodeGen) | Declares local package reference `../SundeeFundee`, generates Xcode project | Reads Package.swift from sibling directory |

### Data Flow

```
User Interaction (SwiftUI)
    ↓
View Model (SundeeFundeeApp/)
    ↓
Domain Layer (SundeeFundeeKit/DomainLayer/)
    ↓
Data Layer (SundeeFundeeKit/DataLayer/)
    ↓
CloudKit / HealthKit / Keychain (SundeeFundeeKit/DataLayer/)
```

**Direction:** Unidirectional from UI → Domain → Data. Domain layer is pure Swift with no framework dependencies.

## Patterns to Follow

### Pattern 1: Local Swift Package Sibling Directory

**What:** Swift Package in sibling directory to Xcode project, referenced via relative path in XcodeGen config.

**When:** 
- Separating reusable business logic from app-specific UI
- Enabling independent testing of domain layer
- Sharing code across multiple targets (app, widgets, tests)

**Example:**
```yaml
# SundeeFundeeApp/project.yml
packages:
  SundeeFundeeKit:
    path: ../SundeeFundee  # Sibling directory reference

targets:
  SundeeFundee:
    dependencies:
      - package: SundeeFundeeKit  # Import domain layer
```

**Why:** Clean separation between framework-agnostic business logic and iOS-specific UI code. Package can be tested independently with `swift test`.

### Pattern 2: XcodeGen with project.yml

**What:** Generate Xcode project from YAML config instead of manual `.pbxproj` editing.

**When:** 
- Working with teams (avoid merge conflicts in `.pbxproj`)
- Need reproducible project generation
- Managing multiple targets with complex dependencies

**Example:**
```bash
# Install XcodeGen
brew install xcodegen

# Generate project
cd SundeeFundeeApp
xcodegen generate
```

**Why:** Declarative project configuration, easier to maintain, git-friendly. Changes to `project.yml` are readable; changes to `.pbxproj` are opaque.

### Pattern 3: Protocol-Based Data Layer

**What:** Data layer defined as protocols (e.g., `CloudKitRepository`, `HealthKitClient`), implemented with actors for concurrency.

**When:**
- Need to swap implementations for testing
- Accessing external services (CloudKit, HealthKit, Keychain)
- Requires async/await concurrency

**Example:**
```swift
// Protocol
protocol WorkoutRepository {
    func fetchWorkouts() async throws -> [Workout]
    func saveWorkout(_ workout: Workout) async throws
}

// Implementation
actor CloudKitWorkoutRepository: WorkoutRepository {
    func fetchWorkouts() async throws -> [Workout] {
        // CloudKit fetch logic
    }
}
```

**Why:** Testability (mock protocols), Swift 6 concurrency safety (actors), clear contracts between layers.

### Pattern 4: SwiftUI + Combine View Models

**What:** Views observe `@ObservableObject` view models via `@StateObject`. View models use Combine publishers for state.

**When:** 
- Building reactive UI
- Need to separate view logic from business logic
- Managing complex app state

**Example:**
```swift
// ViewModel
@Observable
final class DashboardViewModel {
    var workouts: [Workout] = []
    private let repository: WorkoutRepository
    
    func loadWorkouts() async {
        workouts = try? await repository.fetchWorkouts()
    }
}

// View
struct DashboardView: View {
    @State private var viewModel = DashboardViewModel()
    
    var body: some View {
        List(viewModel.workouts) { workout in
            Text(workout.name)
        }
        .task {
            await viewModel.loadWorkouts()
        }
    }
}
```

**Why:** Unidirectional data flow, testable view models, automatic UI updates.

## Anti-Patterns to Avoid

### Anti-Pattern 1: Business Logic in Views

**What:** Embedding calculations, data transformations, or business rules directly in SwiftUI views.

**Why bad:** 
- Untestable (can't unit test views easily)
- Unreusable (logic locked to UI)
- Hard to debug (mix of view and logic concerns)

**Instead:** Move all business logic to `SundeeFundeeKit/DomainLayer/`. Views should only handle presentation and user interaction.

### Anti-Pattern 2: Direct CloudKit/HealthKit in Views

**What:** Importing `CloudKit` or `HealthKit` directly in SwiftUI views.

**Why bad:**
- Tight coupling to Apple frameworks
- Impossible to test (need real device + permissions)
- Violates dependency inversion

**Instead:** Use protocol-based repository pattern in `SundeeFundeeKit/DataLayer/`. Inject mock implementations for testing.

### Anti-Pattern 3: Ignoring Swift 6 Concurrency

**What:** Using `@MainActor` everywhere, ignoring data races, or marking everything as nonisolated.

**Why bad:** 
- Runtime crashes from data races
- Defeats purpose of Swift 6 concurrency safety
- Hard to debug intermittent issues

**Instead:** Use actors for data isolation, strict concurrency checking in Xcode build settings (`SWIFT_STRICT_CONCURRENCY = complete`).

### Anti-Pattern 4: Manual .pbxproj Editing

**What:** Directly editing `SundeeFundee.xcodeproj/project.pbxproj` to add files or targets.

**Why bad:**
- High risk of merge conflicts
- Fragile (easy to corrupt project)
- Hard to review changes

**Instead:** Edit `project.yml` and regenerate with `xcodegen generate`. Commit YAML changes, not `.pbxproj`.

## Scalability Considerations

| Concern | At 1K Users | At 100K Users | At 1M Users |
|---------|------------|---------------|-------------|
| **CloudKit Database** | Private database sufficient | Private database + CloudKit schema optimization | Consider CloudKit web service for bulk operations |
| **App Size** | Current size fine | Optimize assets, consider on-demand resources | Bitcode, thining, asset catalogs |
| **Build Time** | Full build acceptable | Use build phases, precompiled frameworks | Parallelize targets, use Xcode build system optimizations |
| **Testing** | Unit tests + manual QA | Add XCUITest suite | Automated testing pipeline, TestFlight beta groups |
| **Crash Reporting** | macOS Console | Firebase Crashlytics | Custom analytics, performance monitoring |

### Build Order Considerations

1. **Swift Package first** (`SundeeFundee/`) — must build before app can link it
2. **App target** (`SundeeFundee/`) — depends on package
3. **Widget extension** (`SundeeFundeeWidgets/`) — depends on package
4. **Tests** (`SundeeFundeeKitTests/`) — run in parallel with app build

**Xcode workspace handles this automatically**. Package dependency declared in `project.yml` ensures correct build order.

### Root-Level Files After Cleanup

| File | Purpose | Why Keep? |
|------|---------|-----------|
| `README.md` | Project overview, setup, stack | Entry point for developers |
| `CLAUDE.md` | AI assistant context | Improves AI code assistance |
| `.gitignore` | Ignore patterns | iOS-specific ignore (Xcode user data, derived data) |
| `.github/workflows/ci.yml` | CI/CD pipeline | Run tests on push/PR, catch issues early |
| `Logo.jpeg` | App icon source | Asset generation for multiple sizes |

**Files to remove:** `package.json`, `package-lock.json`, `wrangler.toml`, `firebase.json`, `firestore.indexes.json`, `opencode.json`, `skills-lock.json`, `.mcp.json`, `AGENTS.md`, `backlog.md`, `teenybase.ts`.

## Documentation Strategy

### Current State
- `readme.md` — outdated, describes web app stack (Next.js, Cloudflare, etc.)
- `docs/` — mixed web/iOS content
- `CLAUDE.md` — comprehensive but includes web app references

### Target State (iOS-Only)
- `README.md` — iOS app overview, setup, stack (Swift, SwiftUI, CloudKit)
- `CLAUDE.md` — iOS-only context (no web app, Firebase, Stripe)
- `docs/` — iOS-specific docs (App Store screenshots, TODO, superpowers)
- `SundeeFundee/README.md` — Swift Package-specific docs (already exists)
- Optional: `ARCHITECTURE.md` (this file) for deeper architectural decisions

**Key:** Keep documentation close to code. Package docs in package dir. App docs in repo root or `docs/`.

## Build System

### Current Setup
- **XcodeGen**: `project.yml` defines targets, dependencies, bundle IDs
- **Local Package**: Referenced as `../SundeeFundee` in `project.yml`
- **Generated Project**: `SundeeFundee.xcodeproj/` (regenerate after `project.yml` changes)

### Build Commands
```bash
# Regenerate Xcode project (after project.yml changes)
cd SundeeFundeeApp
xcodegen generate

# Build app
xcodebuild -project SundeeFundee.xcodeproj -scheme SundeeFundee -configuration Release

# Build Swift Package standalone
cd ../SundeeFundee
swift build

# Run Swift Package tests
swift test

# Run Xcode tests
xcodebuild test -project SundeeFundee.xcodeproj -scheme SundeeFundee
```

### CI/CD Pipeline
`.github/workflows/ci.yml` should:
1. Install dependencies (Swift, Xcode)
2. Run Swift Package tests (`cd SundeeFundee && swift test`)
3. Run Xcode tests (`xcodebuild test`)
4. Build app (`xcodebuild build`)
5. Archive for TestFlight (optional, on main branch)

**Replace web-app CI** (Node, npm, ESLint, Vitest) with iOS CI (Swift, Xcode, xcodebuild, XCTest).

## Sources

### HIGH Confidence (Official Documentation)
- **Swift Package Manager**: [swift.org/package-manager](https://swift.org/package-manager/) — Official SPM documentation
- **XcodeGen**: [github.com/yonaskolb/XcodeGen](https://github.com/yonaskolb/XcodeGen) — Project specification format
- **Swift 6 Concurrency**: [swift.org/blog/concurrency](https://swift.org/blog/concurrency) — Actor isolation, data races

### MEDIUM Confidence (Established Patterns)
- **Protocol-Oriented Programming**: WWDC sessions "Protocol-Oriented Programming in Swift" (2015+)
- **SwiftUI + Combine**: SwiftUI documentation, Combine framework reference
- **Xcode Project Structure**: Standard iOS app organization patterns

### LOW Confidence (Needs Validation)
- **Specific CI/CD workflows**: Need to research iOS CI best practices (GitHub Actions for macOS, TestFlight automation)
- **App Store release automation**: Fastlane vs. Xcode Cloud vs. custom scripts
- **Crash reporting/analytics**: Firebase Crashlytics vs. Sentry vs. custom solutions

### Gaps Identified
1. **CI/CD for iOS**: Research GitHub Actions for macOS, TestFlight beta automation
2. **App Store screenshots**: Current workflow uses Python scripts — validate this is best practice
3. **Widget extension testing**: How to unit test Live Activity widgets
4. **CloudKit testing**: Best practices for mocking CloudKit in unit tests
5. **Performance monitoring**: Tools for tracking app performance in production

## Recommendations

### Immediate (Cleanup Phase)
1. Keep `SundeeFundee/` and `SundeeFundeeApp/` structure as-is — it's already well-organized
2. Remove all web/backend/config files from root
3. Update `README.md` to describe iOS stack only
4. Rewrite `.github/workflows/ci.yml` for iOS (remove Node/npm steps)
5. Clean `.gitignore` to remove Node/Firebase/wrangler entries

### Short-Term (Post-Cleanup)
1. Add `ARCHITECTURE.md` to `docs/` for deeper architectural decisions
2. Separate `docs/screenshots/` into App Store assets vs. internal screenshots
3. Consider `CONTRIBUTING.md` for Swift/SwiftUI coding standards
4. Add `scripts/` for common tasks (build, test, archive, screenshots)

### Long-Term (Enhancement)
1. Evaluate Fastlane for App Store automation (screenshots, TestFlight, release)
2. Add performance monitoring (Firebase Performance, Sentry, or custom)
3. Implement CI for screenshots (ensure no visual regressions)
4. Add integration tests for CloudKit/HealthKit interactions
