# Sundee Fundee Native Apple App Design

**Date:** 2026-04-02
**Status:** Approved
**Author:** Claude Code + User Collaboration

## Executive Summary

Convert Sundee Fundee from a Next.js PWA to a pure native Apple application covering iOS, iPadOS, watchOS, and macOS platforms. The app will use SwiftUI, CloudKit, Apple Intelligence, and HealthKit to deliver a premium cycle-aware strength training experience.

**Key Differentiators:**
- Pure Apple ecosystem (no Firebase/Stripe dependencies)
- On-device AI via Apple Intelligence (privacy-first, no API costs)
- Full HealthKit integration for workouts and cycle data
- Cross-platform coverage across all Apple platforms

**Timeline:** 10-14 months across 8 phases

---

## Goals

1. **App Store Discoverability** - Reach users searching for fitness apps in the App Store
2. **Native Performance & Features** - Access to HealthKit, notifications, widgets, offline-first capabilities
3. **Premium UX** - More polished, native-feeling app with better animations and gestures
4. **Business Model Evolution** - Move from web-first to iOS-native with differentiated subscription tiers

---

## High-Level Architecture

### Multi-Target Xcode Project Structure

```
SundeeFundee/
├── SundeeFundee/              # iOS/iPadOS main app
├── SundeeFundeeWatch/         # watchOS companion app
├── SundeeFundeeMac/           # macOS admin app
├── SundeeFundeeKit/           # Shared framework (domain, models, CloudKit client)
├── SundeeFundeeServer/        # Vapor Swift server (standalone project)
└── SundeeFundeeTests/         # XCTest suites for shared framework
```

### Technology Stack

| Layer | Technology |
|-------|------------|
| **UI** | SwiftUI with Swift Charts |
| **Data** | SwiftData (local) + CloudKit (sync) |
| **Navigation** | NavigationStack (iOS), NavigationSplitView (iPad/Mac) |
| **Concurrency** | Async/await with Actors |
| **Networking** | URLSession for API calls, background tasks for sync |
| **Dependencies** | Swift Package Manager (no CocoaPods/SPM) |
| **Auth** | Sign in with Apple (AuthenticationServices) |
| **Subscriptions** | StoreKit 2 + RevenueCat |
| **AI** | Apple Intelligence (on-device) |
| **Health** | HealthKit framework |

### Key Design Decisions

1. **Shared Framework** - All business logic, models, and CloudKit code live in SundeeFundeeKit to avoid duplication
2. **Actor-Based Data Layer** - CloudKit and HealthKit access wrapped in Actors for thread safety
3. **Observable ViewModels** - Each screen has a `@Observable` ViewModel coordinating UI and data layer
4. **Server as Separate Repo** - Swift server lives independently, deployed separately

---

## Data Layer & CloudKit Schema

### CloudKit Structure

**Public Database** (read-only to users, managed by server):
```
Programs/                 # Workout program templates
BenchmarkDefinitions/     # Benchmark exercise catalog
ExerciseCatalog/          # Standard exercise library
BlogPosts/               # Content marketing posts
```

**Private Database** (per-user):
```
UserProfile/              # User settings, goals, subscription tier
OneRepMaxes/              # Personal strength records
CompletedWorkouts/        # Workout history with sets
EnrolledPrograms/         # Active program enrollments
PeriodLogs/               # Menstrual cycle tracking
CycleSettings/            # Cycle adaptation preferences
BenchmarkResults/         # Personal benchmark scores
Subscription/             # StoreKit subscription record
GeneratedWorkoutRecords/  # AI workout history
AIUsageDaily/             # Daily AI usage counters (analytics only)
```

### Local SwiftData Schema

- Mirrors CloudKit schema for offline-first experience
- Uses `@Attribute` with CloudKit-compatible identifiers
- Syncs via `CloudKitDatabase` automatically

### Key Actors

```swift
actor CloudKitClient {
    func fetch<T>(_ recordType: String, predicate: NSPredicate) async throws -> [T]
    func save(_ records: [CKRecord]) async throws
    func delete(_ recordIDs: [CKRecord.ID]) async throws
}

actor HealthKitClient {
    func queryWorkouts(startDate: Date, endDate: Date) async throws -> [HKWorkout]
    func saveWorkout(...) async throws
    func fetchMenstrualCycles() async throws -> [HKMenstrualCycleSample]
}
```

### Data Flow

UI → ViewModel → Actor → SwiftData (local) + CloudKit (sync)

---

## Domain Layer (Ported from TypeScript)

### Structure

```
Domain/
├── Models/
│   ├── Workout.swift           # Workout, Exercise, Set types
│   ├── Program.swift           # Program templates, enrollment
│   ├── UserProfile.swift       # User settings, goals
│   ├── Cycle.swift             # Period logs, cycle phases
│   ├── OneRepMax.swift         # Strength records
│   └── Benchmark.swift         # Benchmark definitions, results
├── Calculations/
│   ├── WeightCalculator.swift      # Prescribed weight from %1RM
│   ├── PlateCalculator.swift       # Plate combinations
│   ├── UnitConverter.swift         # lbs/kg conversion
│   ├── CycleCalculator.swift       # Phase, load adjustments
│   └── BenchmarkScoreCalculator.swift # Rounds/reps scoring
├── Adaptation/
│   ├── CycleAdaptationEngine.swift    # Phase-based training adjustments
│   ├── InjuryAdaptationEngine.swift   # Exercise modifications
│   └── EnergyMultiplier.swift         # Intensity scaling
├── Generation/
│   ├── AIWorkoutGenerator.swift       # Apple Intelligence integration
│   └── ProgramTemplateGenerator.swift # Program creation logic
├── Readiness/
│   ├── BenchmarkReadinessCalculator.swift
│   └── RecoveryIndicator.swift
├── Subscription/
│   └── SubscriptionTier.swift       # Free, Plus, Premium features
└── __Tests__/
    └── XCTest files for each module
```

### Porting Strategy

- Pure functions become Swift functions with `throws` for error handling
- TypeScript enums become Swift enums with associated values
- Discriminated unions become Swift enums
- Vitest assertions map to XCTest
- Keep helper factory pattern (e.g., `makeWorkout()`, `makeProgram()`)

---

## UI Architecture & Navigation

### iOS/iPadOS Navigation

```
TabView (5 tabs)
├── Dashboard        # Home screen with Today's Suggested, Cycle Phase, Recent Wins
├── Programs        # Browse and enroll in workout programs
├── Workouts        # Active workout, AI generate, history
├── Maxes           # 1RM tracking, progress charts
└── Settings        # Profile, cycle settings, subscription, benchmarks

TabView → NavigationStack → Screen Views
```

### watchOS Companion

```
WatchApp (single-page with complications)
├── Quick Log       # Start active workout with complication
├── Today's Plan    # View suggested workout
├── Cycle Status    # Current phase indicator
└── Complications   # Home screen widgets
```

### macOS Admin App

```
NavigationSplitView (three-column)
├── Sidebar         # WODs, Programs, Benchmarks, Blog, Users, AI, Settings
├── Content List    # Grid/table of items in selected category
└── Detail Panel    # Editor for selected item
```

### SwiftUI Patterns

- `@Observable` ViewModels for state management
- `@Environment` for dependency injection (Clients, Navigation)
- `@Query` for SwiftData fetching
- Custom modifiers for Art Deco theming (cream/navy/orange)
- Sheet-based detail views on iPhone, split-view on iPad/Mac

---

## Authentication & Subscriptions

### Authentication

**Sign in with Apple Only** (simplifies native auth):

```swift
class AppleAuthClient {
    func signIn() async throws -> AppleAuthResult
    func getCredentialState(for userID: String) async throws -> CredentialState
}
```

- Uses AuthenticationServices framework
- No email/password or Google OAuth (reduces complexity)
- User ID from Apple ID token stored in CloudKit Private Database
- Token refresh handled automatically by iOS
- Server validates JWT tokens with Apple's public keys

### Subscription Tiers (StoreKit 2 + RevenueCat)

**Free:**
- 5 tracked lifts, 1 injury
- 30-day workout history
- Basic workout logging
- Manual cycle tracking (date only)

**Plus ($X/mo):**
- Unlimited lifts, injuries, history
- **Unlimited AI workout generation** (on-device, no API cost)
- Custom benchmarks
- Cycle phase adaptation (basic)
- HealthKit integration (workouts only)
- Program library access

**Premium ($Y/mo):**
- Everything in Plus, plus:
- **AI Coach Memory** - On-device model learns from history, adapts recommendations
- **Plateau Detection** - Identifies stalled progress, suggests deloads
- **Advanced Cycle Adaptation** - Energy levels, recovery phase, pain trends
- **HealthKit Full Sync** - Cycle data, heart rate, HRV, active energy integration
- **Program Generator** - AI creates custom programs based on goals/maxes
- **Benchmark Prediction** - Estimates when you'll hit PRs based on trends
- **Export Data** - CSV export for external analysis
- **Priority Support**

### RevenueCat Benefits

- Handles StoreKit 2 complexity (webhooks, refunds, trials)
- Server-side receipt validation
- Analytics dashboard
- Easy Apple promo offer integration
- Cross-platform ready for future expansion

---

## HealthKit Integration

### Health Data Types

| Type | Read | Write | Purpose |
|------|------|-------|---------|
| HKWorkoutType | ✓ | ✓ | Sync completed workouts |
| HKActiveEnergyBurned | ✓ | | Inform intensity recommendations |
| HKHeartRateVariability | ✓ | | Recovery readiness assessment |
| HKRestingHeartRate | ✓ | | Fatigue monitoring |
| HKMenstrualCycle | ✓ | ✓ | Cycle phase tracking (replace manual) |
| HKMenstrualSymptoms | ✓ | ✓ | Symptom correlation |

### HealthKit Client

```swift
actor HealthKitClient {
    // READ
    func fetchWorkouts(startDate: Date, endDate: Date) async throws -> [HKWorkout]
    func fetchMenstrualCycles() async throws -> [HKMenstrualCycleSample]
    func fetchActiveEnergy(startDate: Date) async throws -> [HKQuantitySample]
    func fetchHeartRateVariability(startDate: Date) async throws -> [HKQuantitySample]
    func fetchRestingHeartRate(startDate: Date) async throws -> [HKQuantitySample]

    // WRITE
    func saveWorkout(
        type: HKWorkoutType,
        startDate: Date,
        endDate: Date,
        exercises: [Exercise],
        totalEnergyBurned: Double?
    ) async throws

    func syncCycleSettings(phase: CyclePhase, symptoms: [CycleSymptom]) async throws
}
```

### Privacy First

- All HealthKit writes require explicit user permission per data type
- User can revoke any time
- No data leaves device except to user's private CloudKit database
- On-device AI processing only

### Premium HealthKit Features

- **Recovery Score**: Combines HRV, RHR, active energy, cycle phase
- **Readiness Indicator**: Green/Yellow/Red based on multi-day trends
- **Symptom Correlation**: Match training intensity with cycle symptoms
- **Automatic Cycle Detection**: Read from HealthKit instead of manual logging

---

## Apple Intelligence Integration

### On-Device AI Workout Generation

```swift
actor AIWorkoutGenerator {
    private let model: WorkoutGenerationModel

    func generateWorkout(context: WorkoutContext) async throws -> GeneratedWorkout
    func learnFromFeedback(
        workout: CompletedWorkout,
        userRating: Int,
        perceivedExertion: Int
    ) async throws
}

actor AICoachMemory {
    func analyzeHistory(
        workouts: [CompletedWorkout],
        maxes: [OneRepMax],
        cycleData: CycleData,
        healthMetrics: HealthMetrics
    ) async throws -> CoachingInsights

    func detectPlateau(
        exercise: Exercise,
        history: [CompletedWorkout]
    ) async throws -> PlateauAnalysis
}
```

### Apple Intelligence Capabilities

| Feature | Implementation |
|---------|----------------|
| Basic Workout Generation | ImageUnderstandingMe API with structured output |
| AI Coach Memory | On-device embedding + similarity search (Memories) |
| Plateau Detection | Tabular data analysis on training history |
| Program Generation | Multi-step reasoning with user goals + constraints |

### Prompt Strategy

- Maintain existing prompt templates from web app
- Convert to Apple Intelligence format
- Fine-tune with successful workout patterns from your data
- Local only - no API calls to external services

### Premium AI Features

- **Coach Memory**: Embeds user's workout history, finds similar patterns
- **Plateau Detection**: Analyzes 90-day trends, suggests deload or rep schemes
- **Program Generator**: Creates 4-12 week progressive programs
- **Predictive Benchmarking**: Estimates when you'll hit target weights

### Rate Limiting (Local)

- No server-side rate limits (no cost!)
- UI guardrails: "Generating..." prevents spam
- User quota display resets daily (psychological pacing)

---

## Swift Server (Backend)

### Server Architecture - Vapor Project

```
SundeeFundeeServer/
├── Sources/
│   ├── App/
│   │   ├── app.swift                # Entry point
│   │   ├── routes.swift             # Route definitions
│   │   └── configure.swift          # Middleware config
│   ├── Controllers/
│   │   ├── AdminAuthController.swift    # Admin authentication
│   │   ├── ProgramsController.swift     # Program CRUD
│   │   ├── BenchmarksController.swift   # Benchmark CRUD
│   │   ├── BlogController.swift         # Blog post CRUD
│   │   └── AIUsageController.swift      # Rate limit tracking
│   ├── Models/
│   │   ├── Program.swift
│   │   ├── Benchmark.swift
│   │   ├── BlogPost.swift
│   │   └── AdminUser.swift
│   └── Services/
│       ├── CloudKitService.swift        # Server-to-server CloudKit
│       ├── BlogMarkdownService.swift    # MDX parsing
│       └── AIAnalyticsService.swift     # AI usage analytics
└── Tests/
```

### Deployment Options

- **AWS EC2 Mac instance** - Native Apple Silicon environment
- **Heroku** - Standard Docker deployment
- **VPS with Docker** - Most cost-effective long-term
- **AWS Lambda (via Swift Lambda runtime)** - Serverless, pay-per-use

### Key Responsibilities

1. **Admin Authentication** - Server-to-server CloudKit auth (ECDSA signatures)
2. **Content Management** - CRUD operations for public database content
3. **Blog Rendering** - MDX → HTML for public-facing blog (if kept)
4. **Analytics** - Track AI usage, popular programs, etc.
5. **Rate Limiting** - Track daily AI usage per user (for analytics)

### CloudKit Server-to-Server Auth

```swift
struct CloudKitServerAuth {
    static func signRequest(
        _ request: inout URLRequest,
        keyID: String,
        privateKey: P256.Signing.PrivateKey
    ) throws {
        let date = ISO8601DateFormatter().string(from: Date())
        let bodyHash = SHA256.hash(data: request.httpBody ?? Data())
        let signature = "sha256:\(date):\(bodyHash.base64EncodedString())"
        let signed = try privateKey.signature(for: signature.data)

        request.setValue(keyID, forHTTPHeaderField: "X-Apple-CloudKit-Request-KeyID")
        request.setValue(date, forHTTPHeaderField: "X-Apple-CloudKit-Request-ISO8601Date")
        request.setValue(signed.base64EncodedString(), forHTTPHeaderField: "X-Apple-CloudKit-Request-SignatureV1")
    }
}
```

---

## Testing Strategy

### Test Coverage Goals

- Domain layer: **100%** (maintain from TypeScript)
- ViewModels: **80%+**
- CloudKit integration: **70%+**
- UI: Snapshot testing for critical screens

### Test Organization

```
SundeeFundeeTests/
├── DomainTests/
│   ├── WeightCalculatorTests.swift
│   ├── PlateCalculatorTests.swift
│   ├── CycleCalculatorTests.swift
│   ├── InjuryAdaptationEngineTests.swift
│   └── ... (one per domain module)
├── DataLayerTests/
│   ├── CloudKitClientTests.swift      // Mock CKContainer
│   ├── HealthKitClientTests.swift     // Mock HKHealthStore
│   └── SwiftDataSyncTests.swift
├── ViewModelTests/
│   ├── DashboardViewModelTests.swift
│   ├── WorkoutViewModelTests.swift
│   └── ProgramViewModelTests.swift
└── IntegrationTests/
    └── EndToEndWorkoutFlowTests.swift
```

### Mocking Strategy

- Protocol-based abstractions for CloudKit/HealthKit
- `MockCloudKitClient` and `MockHealthKitClient` for deterministic tests
- SwiftData tests use in-memory persistent container

### UI Testing

- XCTest UI for critical flows (sign up, purchase, log workout)
- Snapshot testing with `SwiftUISnapshotTesting` library

---

## Implementation Phases

### Phase 1: Foundation (4-6 weeks)
- Set up multi-target Xcode project
- Create SundeeFundeeKit shared framework
- Port core domain models (Workout, UserProfile, etc.)
- Port calculation modules (WeightCalculator, PlateCalculator, UnitConverter)
- Set up XCTest infrastructure
- **Milestone**: All domain unit tests passing, parity with TypeScript coverage

### Phase 2: Data Layer (6-8 weeks)
- Implement CloudKit schema and actors
- Build SwiftData models with CloudKit sync
- Create CloudKitClient with mock for testing
- Implement HealthKitClient with mock for testing
- Build sign-in with Apple flow
- Set up RevenueCat SDK
- **Milestone**: User can sign in, save workout to CloudKit, view in app

### Phase 3: Core UI Features (8-10 weeks)
- Build TabView navigation
- Dashboard screen with cycle phase banner
- Workouts: log new workout, view history
- Maxes: track 1RM, view progress charts
- Settings: profile, cycle settings
- **Milestone**: MVP user app functional for basic workout logging

### Phase 4: Programs & AI (6-8 weeks)
- Program browsing and enrollment
- Active program execution UI
- Apple Intelligence integration for workout generation
- AI Coach Memory (Premium)
- Program Generator (Premium)
- **Milestone**: Full feature parity with web app user features

### Phase 5: Premium Features (6-8 weeks)
- Advanced HealthKit integrations (HRV, RHR, cycle data)
- Recovery readiness indicator
- Plateau detection
- Benchmark predictions
- Custom benchmarks
- Pain trends
- **Milestone**: Premium tier fully differentiated

### Phase 6: watchOS App (4-6 weeks)
- Build watchOS target
- Quick log complication
- Today's plan view
- Cycle status indicator
- **Milestone**: Companion app on App Store

### Phase 7: macOS Admin App (6-8 weeks)
- Build macOS target
- Admin authentication (server-to-server CloudKit)
- WOD/Program/Benchmark CRUD
- Blog post management
- User management dashboard
- **Milestone**: Admins can manage all content without web

### Phase 8: Polish & Launch (4-6 weeks)
- Performance optimization
- Accessibility audit
- App Store screenshots and metadata
- Beta testing (TestFlight)
- Marketing website integration
- **Milestone**: App Store submission

**Estimated Timeline: 44-58 weeks (~10-14 months)**

---

## Data Migration Strategy

**No Migration** - Launch as fresh app, existing users continue on web.

Rationale:
- Cleanest architecture
- Web app remains available for existing users
- New users start directly on native
- Avoids complex Firebase → CloudKit migration
- Web app can eventually be sunset when native is mature

---

## Success Criteria

1. **Feature Parity** - All user-facing features from web app available in native
2. **Admin Parity** - All admin features available in macOS app
3. **App Store Approval** - App passes Apple review and is available for download
4. **Performance** - App launches in < 2 seconds, smooth 60fps scrolling
5. **Test Coverage** - Domain layer maintains 100% coverage
6. **Subscription Revenue** - StoreKit IAP generating revenue within 30 days of launch

---

## Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Apple Intelligence availability | High - core feature depends on beta framework | Phase 4 delivery allows time for framework to mature; fallback to basic algorithms |
| CloudKit learning curve | Medium - different paradigm than Firestore | Incremental implementation with extensive testing; use CloudKit Dashboard |
| Sign in with Apple only | Medium - loses Google/Email users | Market as "Apple-first" experience; majority of target demographic uses Apple ID |
| 10-14 month timeline | Medium - long development cycle | Flexible timeline allows shipping in phases; Phase 3 delivers MVP |
| Server complexity | Low - separate Vapor project | Well-documented patterns; can be deployed to managed services |

---

## Open Questions

These questions should be resolved before or during Phase 1:

1. **Pricing** - Determine exact price points for Plus ($X/mo) and Premium ($Y/mo) tiers. Consider competitor pricing and target market.
2. **Blog Strategy** - Decide on approach:
   - Keep existing MDX blog on web only
   - Build native blog reader that fetches from CloudKit
   - Deprecate blog entirely and focus on App Store presence
3. **Web App Future** - Define transition strategy:
   - Keep web app running indefinitely as free tier
   - Sunset web app after native launch (timeline?)
   - Redirect web traffic to App Store download page
4. **Server Hosting** - Select Vapor deployment option based on cost, maintenance, and scaling needs
5. **Apple Intelligence Framework** - Final framework name and API availability may differ; monitor WWDC announcements

---

## Next Steps

1. Create implementation plan via writing-plans skill
2. Set up Xcode project with multi-target structure
3. Begin Phase 1: Foundation
