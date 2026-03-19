# Architecture Research

**Domain:** iOS + watchOS native strength training app (SwiftUI, SwiftData, CloudKit)
**Researched:** 2026-03-18
**Confidence:** MEDIUM-HIGH — iOS patterns HIGH confidence (verified via official docs + community), watchOS CloudKit sync MEDIUM confidence (known reliability issues, workarounds not fully stabilized in community sources)

---

## Standard Architecture

### System Overview

```
┌──────────────────────────────────────────────────────────────────┐
│                      iPhone App Target                           │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐         │
│  │Dashboard │  │Workouts  │  │ Cycle    │  │Settings  │  ...    │
│  │  View+VM │  │  View+VM │  │  View+VM │  │  View+VM │         │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘         │
│       └─────────────┴─────────────┴──────────────┘               │
│                         Repository Protocols                      │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │  SwiftData repos │ CloudKit repos │ Gemini repo │ HealthKit │  │
│  └─────────────────────────────────────────────────────────────┘  │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │              ModelContainer (CloudKit-backed)                │  │
│  └─────────────────────────────────────────────────────────────┘  │
└──────────────────────┬────────────────┬─────────────────────────┘
                       │                │
          WatchConnectivity       CloudKit Private DB
          (real-time / active      (passive background
           workout push)            sync, all devices)
                       │                │
┌──────────────────────┴────────────────┴─────────────────────────┐
│                      Apple Watch Target                          │
│  ┌──────────────┐  ┌─────────────────┐  ┌─────────────────────┐ │
│  │  WorkoutLog  │  │  ActiveWorkout  │  │   WatchDashboard    │ │
│  │   View+VM    │  │   View+VM       │  │   View+VM           │ │
│  └──────┬───────┘  └────────┬────────┘  └──────────┬──────────┘ │
│         └───────────────────┴───────────────────────┘            │
│                     Watch Repository Protocols                    │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │  WatchSwiftData repos  │  WatchConnectivity repo            │ │
│  └─────────────────────────────────────────────────────────────┘ │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │              Watch ModelContainer (CloudKit-backed)          │ │
│  └─────────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────┐
│                  SundeeFundeeShared Package                      │
│  Domain logic │ Models (Program, WOD, ExerciseCatalog) │         │
│  Pure Swift — no framework imports — available to all targets    │
└──────────────────────────────────────────────────────────────────┘
```

### Component Responsibilities

| Component | Responsibility | Communicates With |
|-----------|---------------|-------------------|
| iPhone Feature Views + ViewModels | iOS UI, user interactions, state presentation | Repository protocols, Domain layer, AppState |
| Watch Feature Views + ViewModels | watchOS UI, compact workout logging, glanceable data | Watch repository protocols, Domain layer |
| SundeeFundeeShared Package | Pure domain logic, shared value types (Program, WOD, ExerciseCatalog, validation) | Nothing — zero dependencies |
| Repository Protocols | Contract definitions; swap implementations without touching ViewModels | Implemented by SwiftData, CloudKit, WatchConnectivity, Gemini |
| SwiftData ModelContainer (iOS) | Local persistence, CloudKit-backed sync. Three-tier fallback: CloudKit → local → in-memory | CloudKit private DB |
| SwiftData ModelContainer (watchOS) | Watch-local persistence. Separate container, same CloudKit container identifier for passive sync | CloudKit private DB |
| WatchConnectivity Service | Real-time iPhone↔Watch messaging during active workouts. Supplements CloudKit for low-latency needs | iOS app, Watch app |
| CloudKit Private DB | Ground truth sync across all user devices (iPhone, Watch). Eventual consistency | SwiftData ModelContainers on both targets |
| HealthKit / HKWorkoutSession | Live biometric data during Watch workout sessions. Required for background execution on Watch | Watch ViewModels, HealthKit framework |
| AuthService + Keychain | Sign in with Apple, session restore, credential storage | AppState, SwiftData (writes User on first sign-in) |
| SubscriptionService | StoreKit 2 tier gating (free / plus / pro) | Feature ViewModels |
| Gemini Cloudflare Proxy | AI workout generation — proxies Gemini API, returns structured workout JSON | GeminiRepository |

---

## Code Sharing Strategy

### Recommended Approach: Local Swift Package + Target Membership

The project already has `SundeeFundeeShared` as a local Swift Package. Extend this pattern deliberately rather than using ad-hoc target membership files.

**Three tiers of code sharing:**

| Tier | What Goes Here | Mechanism |
|------|---------------|-----------|
| Shared Package (`SundeeFundeeShared`) | Domain logic, value types, validation, exercise catalog, Program/WOD models | Local SPM package, linked to both targets |
| Shared source files via target membership | Platform-agnostic utility extensions (Date, String, Numeric formatters), theme constants that apply to both platforms | `.swift` file → checked in both target memberships in `project.yml` |
| Platform-specific | iOS: Tab navigation, StoreKit paywall, full settings, HealthKit background tasks. Watch: workout session management, HKWorkoutSession, complications | Separate target source directories; conditional `#if os(watchOS)` only as last resort |

**Decision rule:** If code has zero UIKit/SwiftUI/SwiftData/HealthKit imports, it belongs in `SundeeFundeeShared`. If it has SwiftUI but no platform-specific APIs, consider target membership with `#if os(watchOS)` guards. If it requires a platform-specific framework (e.g., `WatchKit`, `HealthKit` workout sessions), it lives in the dedicated target.

**Confidence:** HIGH — this pattern (local SPM for domain, target membership for light sharing, separate source trees for platform-specific) is the standard Apple recommendation and matches the existing codebase structure.

---

## Recommended Project Structure (watchOS additions)

```
SundeeFundee/
├── SundeeFundee/                     # iOS app target (existing)
│   ├── App/
│   ├── Auth/
│   ├── Domain/                       # MOVE pure logic → SundeeFundeeShared
│   ├── Features/
│   ├── Models/
│   ├── Repositories/
│   │   ├── Protocols/
│   │   ├── SwiftData/
│   │   ├── CloudKit/
│   │   ├── WatchConnectivity/        # NEW: WCSession service (iOS side)
│   │   └── ...
│   └── ...
│
├── SundeeFundeeWatch/                # NEW: watchOS app target
│   ├── App/
│   │   ├── SundeeFundeeWatchApp.swift
│   │   ├── WatchAppState.swift
│   │   └── WatchModelContainer.swift
│   ├── Features/
│   │   ├── ActiveWorkout/            # Core feature: logging sets from wrist
│   │   ├── Dashboard/                # Glanceable summary (today's workout)
│   │   └── Shared/                   # Watch-specific UI components
│   ├── Repositories/
│   │   ├── Protocols/                # Watch-scoped protocol subset
│   │   ├── SwiftData/                # Watch SwiftData implementations
│   │   └── WatchConnectivity/        # WCSession service (Watch side)
│   └── Complications/                # ClockKit / WidgetKit complications
│
├── SundeeFundee/Packages/
│   └── SundeeFundeeShared/           # EXPANDED: add domain logic migrated from iOS Domain/
│       └── Sources/SundeeFundeeShared/
│           ├── Models/               # Program, WOD, ExerciseCatalog (existing)
│           ├── Domain/               # CycleProgramGenerator, InjuryAdaptation,
│           │                         # WeightCalculations, PlateCalculation (MOVE HERE)
│           ├── CloudKit/             # CKRecord wrappers (existing)
│           └── Validation/           # Validators (existing)
│
└── project.yml                       # XcodeGen spec — add watchOS target here
```

**Structure rationale:**
- `SundeeFundeeWatch/` is a dedicated source tree, never imports iOS-only frameworks
- Domain logic migration into `SundeeFundeeShared` makes cycle adaptation and weight calculations available on Watch without duplication
- Watch repository protocols are a subset — Watch does not need AI workout generation or HealthKit readiness repos
- `WatchConnectivity/` repositories exist on both sides of the fence; they mirror each other's interface

---

## Architectural Patterns

### Pattern 1: Separate ModelContainers with Shared CloudKit Container

**What:** Both iOS and watchOS targets create their own `ModelContainer` pointing to the same CloudKit container identifier (`iCloud.com.sundeefundee`). CloudKit acts as the sync bus. Neither target shares an in-process `ModelContext`.

**When to use:** Always — app groups cannot share a SQLite database across iPhone and Watch because they are different physical devices.

**Trade-offs:**
- Pro: Fully standalone Watch app; continues working without iPhone present
- Pro: CloudKit handles conflict resolution automatically
- Con: Sync is eventual — a workout logged on Watch may take seconds to minutes to appear on iPhone
- Con: Known watchOS 10 issue: CloudKit sync on Watch only triggers reliably when Watch is charging with >50% battery. Background sync is not guaranteed during workout.

**Implementation:**
```swift
// WatchModelContainer.swift — same pattern as AppModelContainer.swift
static func make() -> ModelContainer {
    let schema = Schema(WatchAppSchemaV1.models)
    let config = ModelConfiguration(
        schema: schema,
        cloudKitContainerIdentifier: "iCloud.com.sundeefundee"
    )
    return try! ModelContainer(for: schema, configurations: [config])
}
```

**Confidence:** MEDIUM — CloudKit sync on watchOS is documented but has known reliability issues (charging requirement, large dataset sync failures). This is the Apple-prescribed approach; the reliability issues are a known tradeoff, not a reason to abandon it.

---

### Pattern 2: WatchConnectivity as Real-Time Supplement

**What:** Use `WCSession` to push workout-in-progress state from Watch to iPhone during an active workout session. This is not a replacement for CloudKit sync — it is a low-latency bridge for data that must arrive before the user checks their iPhone.

**When to use:** Active workout logging only. The Watch-side `WCSession.sendMessage` delivers instantly when the counterpart app is reachable. `transferUserInfo` delivers queued, guaranteed when the Watch app goes background.

**Do not use for:** Full data sync, exercise library loading, program catalog reads. Use CloudKit for those.

**Transfer method selection:**

| Scenario | Method | Rationale |
|----------|--------|-----------|
| User completes a set mid-workout | `transferUserInfo` | Guaranteed delivery even if iPhone app is in background; FIFO queue |
| Workout session started / completed | `transferUserInfo` | Must not be lost |
| Live set display on iPhone during workout | `sendMessage` | Real-time, but both apps must be reachable |
| Sync latest user settings to Watch at launch | `updateApplicationContext` | Only latest needed; replaces previous |

**Architecture:** `WatchConnectivityService` is a singleton `@Observable` class on both targets, conforming to `WCSessionDelegate`. It is injected into the environment from the app entry point, not created per-ViewModel.

```swift
// Shared singleton pattern (both targets)
@Observable
final class WatchConnectivityService: NSObject, WCSessionDelegate {
    static let shared = WatchConnectivityService()

    private let session = WCSession.default

    func activate() {
        guard WCSession.isSupported() else { return }
        session.delegate = self
        session.activate()
    }
}
```

**Confidence:** HIGH — WCSession singleton is the canonical pattern per Apple documentation and universally used in the community.

---

### Pattern 3: HKWorkoutSession for Active Watch Workouts

**What:** Strength training workouts on Apple Watch require an `HKWorkoutSession` to keep the Watch app running in the foreground and to collect HealthKit samples (heart rate, active energy). Without a workout session, watchOS aggressively suspends the app.

**When to use:** Every time the user starts a workout on Watch. Not optional for a workout logging app.

**Key requirements:**
- HealthKit entitlement must be added to the Watch target in `project.yml`
- Request HealthKit authorization before the first workout
- `HKWorkoutSession` must be started and ended explicitly
- Workout route/samples can be written back to HealthKit on session end for Apple Fitness+ integration

**Trade-offs:**
- Pro: Prevents Watch app from suspending during 60-minute workouts
- Pro: Unlocks real heart rate and calorie data during session
- Con: Adds complexity — session state machine (not started → running → paused → ended) must be mirrored in the ViewModel
- Con: Separate HealthKit authorization request from existing iOS HealthKit readiness integration

**Confidence:** HIGH — HKWorkoutSession is required for background execution on watchOS during workouts per Apple documentation.

---

### Pattern 4: Watch-Local SwiftData Schema (Separate, Smaller)

**What:** The Watch target has its own schema version with a smaller set of models — only what is needed for workout logging. It does not replicate the full 22-model `AppSchemaV12`.

**Recommended Watch models:**
- `WorkoutTemplate` (read-only; synced from iPhone via CloudKit)
- `CompletedWorkout` + `CompletedSet` (write path; synced to iPhone via CloudKit)
- `UserPreferences` (weight unit, display preferences)

**Why not mirror the full schema:** CloudKit sync on Watch struggles with large datasets. A developer forum report indicates ~10k entities caused Watch CloudKit import to never complete. Limiting the Watch schema reduces initial sync time and ongoing CloudKit pressure.

**Confidence:** MEDIUM — the "smaller schema" recommendation is derived from community reports of sync performance issues, not an official Apple guideline.

---

## Data Flow

### Workout Logging (Watch → iPhone)

```
User taps "Log Set" on Watch
    ↓
ActiveWorkoutViewModel (Watch) updates in-memory state
    ↓
SwiftDataWorkoutRepository (Watch) writes CompletedSet to Watch ModelContext
    ↓
CloudKit private DB receives the CKRecord (passive, eventual)
    ↓
WatchConnectivityService.transferUserInfo(setPayload) — immediate, queued
    ↓
iPhone WatchConnectivityService.session(_:didReceiveUserInfo:) fires
    ↓
iPhone NotificationCenter.post(.watchDidLogSet) or direct ViewModel update
    ↓
iPhone ModelContext merges when CloudKit sync also arrives (deduplication by ID)
```

### Program / Exercise Catalog (iPhone → Watch)

```
Admin writes Program to CloudKit public DB via WOD dashboard
    ↓
CloudKit private DB replicates to user's private DB on next sync
    ↓
iPhone CloudKitProgramRepository fetches on dashboard load
    ↓
Watch CloudKit container syncs the same Program records (passive)
    ↓
Watch app reads Programs from Watch ModelContext on launch
```

### Auth State (iPhone → Watch)

```
User signs in on iPhone (Sign in with Apple)
    ↓
AuthService writes User record to iOS SwiftData
    ↓
CloudKit syncs User record to Watch
    ↓
OR: WatchConnectivity applicationContext carries { isAuthenticated: true, userID: "..." }
    ↓
Watch app boots in authenticated state
```

**Design decision:** Use `applicationContext` for auth state as the fast path (immediate on next Watch launch). CloudKit sync of the `User` record is the persistent path.

---

## CloudKit Container Architecture

```
CloudKit Container: iCloud.com.sundeefundee
├── Private Database (per-user)
│   ├── User record
│   ├── CompletedWorkout + CompletedSet records
│   ├── ActiveCycle + PeriodLog records
│   ├── InjuryProfile + PainLog records
│   ├── LiftMax + OneRepMax records
│   ├── EnrolledProgram records
│   └── GeneratedWorkoutRecord records
│
└── Public Database (shared, admin-written)
    ├── Program records (written by WOD dashboard)
    ├── WOD records (written by WOD dashboard)
    └── BenchmarkDefinition records
```

**Key constraint:** All `@Model` properties must be optional or have default values for CloudKit compatibility. Relationships must be optional. Unique constraints are not supported — use application-level deduplication instead.

**ModelContainer fallback (both targets):**
1. CloudKit-backed persistent store (production)
2. Local persistent store (CloudKit entitlement absent / Simulator)
3. In-memory store (unit tests)

This fallback is already implemented in `AppModelContainer.swift` on iOS and must be mirrored in `WatchModelContainer.swift`.

---

## Build Order (Phase Dependencies)

The watchOS feature has implicit dependencies that drive phase ordering:

```
Phase 1: Fix existing CloudKit bugs on iOS
    → CloudKit must be activated and working on iOS before Watch can sync
    → Known bugs: disabled CloudKit flag, stale schema references, migration plan path

Phase 2: Expand SundeeFundeeShared Package
    → Migrate Domain/ pure logic into the shared package
    → This unblocks Watch from consuming cycle adaptation and weight math
    → Required before Watch ViewModels can compute adapted workouts

Phase 3: watchOS Target Scaffold
    → Add watchOS target to project.yml
    → WatchModelContainer (smaller schema, same container ID)
    → WatchConnectivityService (singleton, both targets)
    → Requires Phase 1 (CloudKit must be healthy) and Phase 2 (shared domain)

Phase 4: Active Workout Feature (Watch)
    → HKWorkoutSession integration
    → Set logging UI (compact SwiftUI for 45mm screen)
    → transferUserInfo back to iPhone
    → Requires Phase 3 scaffold

Phase 5: Watch Dashboard + Complications
    → Read-only glanceable view of today's program
    → ClockKit / WidgetKit complication
    → Requires Phase 3 scaffold + CloudKit sync flowing (Phase 1)
```

---

## Anti-Patterns

### Anti-Pattern 1: Sharing a ModelContext Between Targets

**What people do:** Attempt to use an App Group container so both apps read the same SQLite file.

**Why it's wrong:** iPhone and Apple Watch are separate physical devices. App Groups share containers within a single device, not across the iPhone-to-Watch boundary. This will compile but produce two isolated stores with no sync.

**Do this instead:** Separate `ModelContainer` on each target, same CloudKit container identifier. Let CloudKit be the sync bus.

---

### Anti-Pattern 2: Using sendMessage as the Primary Sync Mechanism

**What people do:** Implement all Watch→iPhone sync via `WCSession.sendMessage` because it feels like the simplest API.

**Why it's wrong:** `sendMessage` fails silently if the counterpart is not reachable. A workout logged while the iPhone is out of Bluetooth range is lost. `sendMessage` also requires the Watch app to be in the foreground (iOS→Watch direction).

**Do this instead:** Use `transferUserInfo` for all workout data. Reserve `sendMessage` only for optional real-time display (e.g., a live set counter visible on iPhone while the user is on the Watch). Always write to SwiftData first, then fire WatchConnectivity.

---

### Anti-Pattern 3: Replicating the Full iOS Schema to Watch

**What people do:** Link `AppSchemaV12` (22 models) to the Watch target so there is one canonical schema.

**Why it's wrong:** CloudKit sync on Watch degrades significantly with large record counts. The Watch app only needs a handful of models. A 22-model schema that mirrors the iPhone schema will hit sync performance issues.

**Do this instead:** Define a minimal `WatchAppSchemaV1` with only the models the Watch needs (WorkoutTemplate, CompletedWorkout, CompletedSet, UserPreferences). Use the same CloudKit container so records flow bidirectionally.

---

### Anti-Pattern 4: Skipping HKWorkoutSession for Workout Logging

**What people do:** Build the Watch workout logging UI without starting an `HKWorkoutSession`, assuming the app will stay active.

**Why it's wrong:** watchOS aggressively suspends apps that are not running a workout session. The user will tap "Log Set" and find the app has been suspended, losing in-progress state.

**Do this instead:** Start `HKWorkoutSession` when the user begins a workout. The session keeps the app in the foreground, enables heart rate sampling, and allows `extendedRuntimeSession` for warmup/cooldown periods outside the formal session.

---

### Anti-Pattern 5: CloudKit Unique Constraints

**What people do:** Add `#Unique` macro constraints to `@Model` types (e.g., ensuring one `User` per `appleUserID`).

**Why it's wrong:** CloudKit does not support unique constraint enforcement at the schema level. SwiftData will silently fall back to a non-CloudKit store if unique constraints are present and CloudKit sync is configured.

**Do this instead:** Enforce uniqueness in application logic — query before inserting, or handle duplicates with a deduplication step in the repository.

---

## Integration Points

### External Services

| Service | Integration Pattern | Notes |
|---------|---------------------|-------|
| CloudKit Private DB | SwiftData `ModelContainer` with `cloudKitContainerIdentifier` | Same container ID on both targets; sync is eventual |
| CloudKit Public DB | `CloudKitProgramRepository` using `CKContainer.publicCloudDatabase` | Programs and WODs; admin writes via WOD dashboard |
| WatchConnectivity | `WCSession` singleton service, delegate pattern | Must activate on both targets at launch; test on real devices only |
| HealthKit / HKWorkoutSession | Watch-only; request authorization, start session on workout begin | Required for Watch background execution |
| Gemini (Cloudflare Worker) | HTTP via `GeminiRepository` on iOS only | Watch does not need AI generation |
| StoreKit 2 | `SubscriptionService` on iOS only | Watch reads subscription tier via `applicationContext` push from iPhone |
| APNs | iOS only at present | Future: Watch can receive notifications independently with WatchKit extension |

### Internal Boundaries

| Boundary | Communication | Notes |
|----------|---------------|-------|
| iOS Domain → Watch Domain | `SundeeFundeeShared` package, same compiled code | No cross-process communication needed; domain is pure Swift |
| iOS ViewModels → Watch ViewModels | No direct connection — they share CloudKit data, not in-process state | |
| Watch → iPhone (workout data) | `WCSession.transferUserInfo` + CloudKit eventual sync | transferUserInfo is the reliable path; CloudKit is truth |
| iPhone → Watch (programs, settings) | CloudKit passive sync + `WCSession.updateApplicationContext` | applicationContext for fast path on Watch launch |
| Watch → HealthKit | `HKWorkoutSession` + `HKHealthStore` writes | Active workout only |

---

## Scaling Considerations

This is a single-user app with a CloudKit private database. Scaling is not a concern in the traditional sense. The relevant "scale" question is dataset size per user.

| Concern | Approach |
|---------|----------|
| Large workout history (1000+ workouts) | CloudKit handles; Watch sync may be slow on first install. Keep Watch schema minimal. |
| Offline Watch logging | SwiftData writes locally; CloudKit syncs when connectivity restored. WatchConnectivity delivers when phones reconnect via Bluetooth. |
| Schema migrations on both targets | iOS and Watch schema versions are independent. Increment separately. Lightweight migrations preferred. |
| CloudKit sync reliability on Watch | Known issue: sync requires charging + >50% battery for reliable background sync. Accept eventual consistency. Do not design UX that depends on instant Watch→iPhone sync. |

---

## Sources

- [Transferring data with Watch Connectivity — Apple Developer Documentation](https://developer.apple.com/documentation/WatchConnectivity/transferring-data-with-watch-connectivity)
- [Watch Connectivity framework — Apple Developer Documentation](https://developer.apple.com/documentation/watchconnectivity)
- [Syncing model data across a person's devices — Apple Developer Documentation](https://developer.apple.com/documentation/swiftdata/syncing-model-data-across-a-persons-devices)
- [Running workout sessions (HKWorkoutSession) — Apple Developer Documentation](https://developer.apple.com/documentation/healthkit/running-workout-sessions)
- [Three Ways to Communicate via WatchConnectivity — Alexander Weiss](https://alexanderweiss.dev/blog/2023-01-18-three-ways-to-communicate-via-watchconnectivity)
- [SwiftData CloudKit sync on watchOS 10 — Apple Developer Forums](https://developer.apple.com/forums/thread/733397)
- [watchOS 10: CloudKit CoreData Sync issues — Apple Developer Forums](https://developer.apple.com/forums/thread/737661)
- [Sharing Swift package with watchOS extension — Corner Software](https://csdcorp.com/blog/coding/sharing-swift-package-with-watchos-extension/)
- [watchOS With SwiftUI by Tutorials, Chapter 2: Project Structure — Kodeco](https://www.kodeco.com/books/watchos-with-swiftui-by-tutorials/v1.0/chapters/2-project-structure)
- [watchOS With SwiftUI by Tutorials, Chapter 4: Watch Connectivity — Kodeco](https://www.kodeco.com/books/watchos-with-swiftui-by-tutorials/v1.0/chapters/4-watch-connectivity)
- [Data Synchronization Between iOS and watchOS Using WatchConnectivity — Medium](https://medium.com/@sheik25bareeth/data-synchronization-between-ios-and-watchos-using-watchconnectivity-009a3064e12a)
- [Organizing your code with local packages — Apple Developer Documentation](https://developer.apple.com/documentation/xcode/organizing-your-code-with-local-packages)

---

*Architecture research for: iOS + watchOS SwiftUI strength training app (Swift 6, SwiftData, CloudKit)*
*Researched: 2026-03-18*
