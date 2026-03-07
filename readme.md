# Sundee Fundee

**Strength Gained — On Your Cycle** — Native iOS strength training app, hormonal-cycle aware.

## Overview

Sundee Fundee is a hormonal-aware strength training tracker built natively for iPhone using Swift 6, SwiftUI, SwiftData, and CloudKit. It helps users follow structured periodized programs while incorporating menstrual cycle phase data for optimized training recommendations.

## Tech Stack

| Component | Technology |
|:---|:---|
| **Language** | Swift 6 |
| **UI Framework** | SwiftUI |
| **State Management** | `@Observable` + `@Environment` |
| **Local Persistence** | SwiftData |
| **Cloud Sync** | CloudKit (Private DB for user data, Public DB for programs) |
| **Authentication** | Sign in with Apple (AuthenticationServices) |
| **Observability** | MetricKit + Xcode Organizer |
| **Project Generator** | XcodeGen (`project.yml`) |
| **iOS Minimum** | 17.0 |

## Project Structure

```
SundeeFundee/
├── App/                    # @main entry, ModelContainer, AppState, AppRootView
├── Auth/                   # Sign in with Apple, KeychainHelper, SignInView
├── Onboarding/             # Multi-step onboarding flow
├── Models/                 # @Model SwiftData entities (14 types)
├── Repositories/           # Repository protocols + SwiftData implementations
│   ├── Protocols/
│   ├── SwiftData/
│   └── ProgramRepository.swift   # CloudKit Public DB + bundled JSON fallback
├── Domain/                 # Business logic (pure Swift, fully tested)
│   ├── Calculations/       # WeightCalculations, PlateCalculation, EpleyFormula
│   ├── CycleCalculations.swift
│   ├── CycleProgramGenerator.swift
│   ├── InjuryAdaptationEngine.swift
│   └── CycleAdaptationPolicy.swift
├── Features/               # Feature screens + view models
│   ├── Shell/              # MainTabView (5 tabs)
│   ├── Dashboard/
│   ├── Programs/
│   ├── Workouts/
│   ├── Cycle/
│   ├── Maxes/
│   └── Settings/
├── Observability/          # MetricsService (MetricKit)
├── Resources/Programs/     # Bundled programs.json
└── Theme/                  # AppTheme (Art Deco cream/navy/orange tokens)
SundeeFundeTests/
└── BusinessLogicTests.swift   # 24 unit tests
```

## Getting Started

### Prerequisites

- Xcode 16+
- `xcodegen` — install via `brew install xcodegen`

### Build & Run

```bash
# Generate Xcode project
xcodegen generate

# Open in Xcode
open SundeeFundee.xcodeproj

# Or build from CLI (iOS Simulator)
xcodebuild build \
  -project SundeeFundee.xcodeproj \
  -scheme SundeeFundee \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

Debug builds use `SundeeFundee.Debug.entitlements` (no iCloud or Sign in with Apple capability), which allows Personal Team development signing. Release builds keep full production entitlements.

### Run Tests

```bash
xcodebuild test \
  -project SundeeFundee.xcodeproj \
  -scheme SundeeFundee \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:SundeeFundeTests
```

## Architecture

```
UI (SwiftUI views)
    ↓
ViewModels (@Observable, @MainActor)
    ↓
Repository protocols (testable, Sendable)
    ↓
SwiftData implementations ←→ CloudKit (Private / Public DB)
    ↓
Domain / Business Logic (pure Swift, zero dependencies)
```

- **Auth**: `AppState` drives routing between Loading → SignIn → Onboarding → MainTabView.  
  `.authenticated` and `.guest` both present `MainTabView`; guest mode uses local-only SwiftData.
- **Data**: All `@Model` types use raw strings for enum fields (CloudKit requirement). Computed properties expose typed accessors.
- **Programs**: Bundled `programs.json` ships in the app target. CloudKit Public DB hosts admin-seeded programs.

## Cycle-Based Training Recommendations

`CycleCalculations` provides training guidance per menstrual phase:

| Phase | Recommendation |
|-------|---------------|
| **Menstrual** | Low intensity, recovery focus |
| **Follicular** | Moderate, building strength |
| **Ovulation** | Peak intensity, PR attempts |
| **Luteal** | Maintenance, technique work |

## CloudKit

- **Bundle ID**: `com.sundeefundee.app`
- **CloudKit Container**: `iCloud.com.sundeefundee.app`
- **Private DB**: all user data (auto-synced via SwiftData + `NSPersistentCloudKitContainer`)
- **Public DB**: `Program` records (read-only for users, seeded via admin script)

## CI/CD

`.github/workflows/ios-ci.yml` — builds and tests on `macos-15` on every push to `main`.

## Contributing

1. Run `xcodegen generate` after adding new source files.
2. Run `xcodebuild test` and ensure all tests pass before committing.
3. Use Conventional Commits: `feat:`, `fix:`, `docs:`.
4. Never commit secrets, API keys, `GoogleService-Info.plist`, or `google-services.json`.
