# Architecture Patterns

**Domain:** Cycle-aware fitness app — recovery scoring, deload automation, CloudKit social
**Researched:** 2026-04-15
**Confidence:** HIGH (based on direct codebase inspection + official Apple docs)

---

## Existing Architecture Baseline

The app already has a clean layered architecture. This section documents what exists so
the new components can be placed correctly without violating existing boundaries.

```
┌─────────────────────────────────────────────────────────────┐
│  UI Layer (@MainActor)                                       │
│  SwiftUI Views  →  ViewModels (@MainActor ObservableObject)  │
└──────────────────┬──────────────────────────────────────────┘
                   │ async/await
┌──────────────────▼──────────────────────────────────────────┐
│  Service/Builder Layer (actors)                              │
│  CoachContextBuilder  DataClientFactory  HealthClientFactory │
└────────┬─────────────────────┬───────────────────────────────┘
         │                     │
┌────────▼──────┐   ┌──────────▼────────────┐
│  DataLayer    │   │  HealthKit Layer       │
│  (actors)     │   │  (actors)              │
│  CloudKitCl.  │   │  HealthKitClient       │
│  LocalDataCl. │   │  HealthClientFactory   │
│  SyncQueue    │   └────────────────────────┘
└───────────────┘
         │
┌────────▼──────────────────────────────────────────────────┐
│  DomainLayer (pure Swift, zero framework imports)          │
│  CycleAdaptationPolicy  WeeklyLoadAnalyzer  PlateauDetect  │
│  CoachContext  InjuryEngine  ProgramTemplateGenerator      │
└────────────────────────────────────────────────────────────┘
```

**Key invariant:** DomainLayer has zero framework imports. All HealthKit/CloudKit types
stop at the DataLayer boundary. Domain functions receive plain Swift values, return
plain Swift values.

---

## Component Architecture for New Features

### 1. Recovery Score

**Where it lives:** `DomainLayer/Recovery/`

The recovery score is pure computation. All five inputs (cycle phase, training volume,
pain logs, sleep, HRV) can be passed as plain values — no HealthKit or CloudKit imports
required in the domain.

```
RecoveryScoreEngine (pure enum, DomainLayer)
  Input:  RecoveryInputs struct (cycle phase, load trend, pain count, sleep hours, hrv samples)
  Output: RecoveryScore struct (value 0-100, breakdown per dimension, tier, suggestions)
```

**RecoveryInputs** assembles from existing systems:
- `cyclePhase: CyclePhase?` — from CyclePhaseCache (already @EnvironmentObject)
- `loadTrend: WeeklyLoadAnalyzer.WeeklySummary` — WeeklyLoadAnalyzer already computes this
- `activePainCount: Int` — from PainTrackingViewModel (already exists)
- `sleepHours: Double` — new HealthKit fetch (add to HealthClientProtocol)
- `hrvSamples: [Double]` — HealthKitClient already has `fetchWeeklyHeartRateVariability()`

**Score algorithm** (weighted composite, HIGH confidence pattern from app survey):
```
cyclePhase multiplier × 0.25
+ loadFatigue score × 0.25   (inverse of overreaching trend severity)
+ sleepQuality score × 0.25  (hours vs 8h target, normalized 0-1)
+ hrvScore × 0.15             (latest vs personal 7-day baseline, normalized)
+ painPenalty × 0.10          (0 pain = 1.0, each active pain -0.15)
```

Multipliers compose — same pattern used by existing `CycleAdaptationPolicy`.

**RecoveryScore output struct:**
```swift
public struct RecoveryScore: Sendable {
    public let value: Int          // 0-100
    public let tier: RecoveryTier  // .recover / .moderate / .train / .peak
    public let cycleContribution: Double
    public let loadContribution: Double
    public let sleepContribution: Double
    public let hrvContribution: Double
    public let painPenalty: Double
    public let suggestions: [String]
    public let computedAt: Date
}
```

**Persistence:** `RecoveryScoreRecord` saved to CloudKit via existing DataClientProtocol.
One record per day per user. Fetch last 90 days for trend chart.

**CloudKit schema fields to avoid:** Do not use `createdAt`, `startDate`. Use `scoreDate`
(ISO-8601 string) per the existing Bool/date encoding rules.

---

### 2. RecoveryViewModel (new ViewModel)

**Where it lives:** `UI/ViewModels/RecoveryViewModel.swift`

Follows the CoachContextBuilder pattern exactly — assembles inputs from multiple async
sources then passes to pure domain function.

```
RecoveryViewModel (@MainActor ObservableObject)
  Dependencies (injected, protocol-typed):
    - healthClient: HealthClientProtocol   (reads sleep + HRV)
    - dataClient: DataClientProtocol       (reads/saves RecoveryScoreRecord)
    - cyclePhaseCache: CyclePhaseCache     (reads current phase)
  Published:
    - recoveryScore: RecoveryScore?
    - isLoading: Bool
    - trend: [RecoveryScore]               (last 30 days for chart)
  Method: func refresh() async
    1. fetch sleepHours from healthClient
    2. fetch hrvSamples from healthClient (already wired)
    3. read cyclePhase from cache
    4. fetch painCount from dataClient
    5. fetch loadSummary via WeeklyLoadAnalyzer
    6. call RecoveryScoreEngine.compute(inputs:)
    7. save result as RecoveryScoreRecord
    8. publish to @Published properties
```

**HealthClientProtocol extension needed:**
Add `fetchSleepAnalysis(startDate:endDate:)` returning `[HKCategorySample]`.
Add to protocol + HealthKitClient actor + MockHealthKitClient.
Authorization type: `HKCategoryType(.sleepAnalysis)` (read-only, no write needed).

---

### 3. Deload Detection

**Where it lives:** `DomainLayer/Intelligence/DeloadDetector.swift`

Sits alongside PlateauDetector and WeeklyLoadAnalyzer in the Intelligence directory.
Pure function, no framework dependencies.

**Inputs (same sources already used by WeeklyLoadAnalyzer and PlateauDetector):**
```swift
public struct DeloadSignals: Sendable {
    public let weeklySummaries: [WeeklyLoadAnalyzer.WeeklySummary]  // existing
    public let trends: [WeeklyLoadAnalyzer.LoadTrend]               // existing
    public let plateaus: [PlateauDetector.PlateauAlert]             // existing
    public let recentRecoveryScores: [RecoveryScore]                 // new
    public let consecutiveLowRecoveryDays: Int                       // derived
}
```

**Trigger logic (threshold-based, not ML):**
A deload is warranted when 2+ of these conditions are true:
- `overreaching` trend present in last 2 weeks
- 3+ plateau alerts active
- Average recovery score < 55 over last 5 days
- 6+ consecutive training days without a rest day
- `frequencyDrop` trend (user is self-regulating already — confirm deload)

**Output:**
```swift
public struct DeloadRecommendation: Sendable {
    public let isRecommended: Bool
    public let triggerCount: Int
    public let triggers: [DeloadTrigger]
    public let suggestedWeek: DateInterval     // next 7 days
    public let activeRecoveryPlan: [ActiveRecoverySession]
}

public struct ActiveRecoverySession: Sendable {
    public let day: Int          // 1-7
    public let type: ActivityType  // .mobility / .yoga / .lightCardio / .rest
    public let durationMinutes: Int
    public let focus: String
}
```

**Deload confirmation flow:** DeloadDetector only recommends — it never auto-enrolls.
UI presents a confirmation sheet. User accepts → deload week written to EnrolledProgram
as a special `.deload` template type. Existing program enrollment infrastructure handles
the rest.

**No new CloudKit record type needed.** Deload state stored as an `EnrolledProgramRecord`
with a `.deload` program type flag. The `EnrolledProgramRecord` already exists and handles
Bool fields with the `Int64` fallback pattern.

---

### 4. CloudKit Social Layer

**This is the most architecturally novel component.** CloudKit zone sharing introduces
a second database scope — the shared database — which the existing `DataClientProtocol`
does not currently model.

**Chosen pattern: Zone Sharing (not record sharing)**

Zone sharing (introduced iOS 15) shares an entire `CKRecordZone` rather than individual
records. Each user has a "Social" zone in their private database. They create a `CKShare`
for that zone with `publicPermission = .none` (invitation-only). Friends are added as
`CKShareParticipant` with `.readOnly` permission. Friends read the owner's activity from
their shared database.

**Why zone sharing over record sharing:**
- Activity feed needs to share many records (every PR, workout completion, challenge win)
- Zone sharing means one `CKShare` per user, not one per record
- `recordZoneChanges` with `changeToken` enables efficient incremental sync
- Conceptually matches the "follow this person's activity" model

**Known constraints (MEDIUM confidence, from Apple dev forums):**
- One `CKShare` per `CKRecordZone` — one active share per user's social zone
- Zone limit ~1024 per container (not relevant — one per user in private database)
- Participant list requires `publicPermission = .none` to mix invited users
- No support for anonymous/link-based public feeds within zone sharing (not needed here)

**New component: SocialClient (actor)**

```
SocialClient (actor, DataLayer/Social/)
  Owns: CKContainer reference (same container as CloudKitClient)
  Responsibilities:
    - createSocialZone() — idempotent, creates "SundeeActivity" zone if absent
    - shareZoneWithFriend(userRecord: CKUserIdentity) — creates/updates CKShare
    - acceptShare(shareMetadata: CKShare.Metadata) — adds self to friend's shared db
    - fetchFriendActivity(friendZoneID: CKRecordZone.ID) -> [ActivityEvent]
    - postActivity(event: ActivityEvent) — saves to own social zone
    - fetchOwnSocialZoneID() -> CKRecordZone.ID?
    - removeParticipant(participant: CKShareParticipant)
```

**SocialClient does NOT conform to DataClientProtocol.** The existing DataClientProtocol
models private-database CRUD. Social operations involve: CKShare manipulation, shared-
database queries, and `CKUserIdentity` lookups — none of which fit the generic
`fetch/save/delete` pattern. A separate protocol is cleaner.

**ActivityEvent record (new CloudKit record type):**
```swift
public struct ActivityEvent: Codable, Sendable {
    public let id: String
    public let activityType: ActivityType  // .pr / .workout / .challenge / .streak
    public let payload: String             // JSON summary (exercise name, weight, etc.)
    public let eventDate: String           // ISO-8601, avoids CloudKit field name collision
    public let userDisplayName: String
    public let reactionCount: Int
}
```

**Reactions (high-five):** Stored as a separate `ReactionRecord` in the owner's social
zone. The reactor's identity is a `CKUserIdentity.lookupInfo` string. SocialClient
writes reactions to the shared zone (participants with `.readWrite` permission can write
reactions; owner posts activity with `.readOnly` for viewers, but reactions need
`.readWrite` — the share permission must be `.readWrite` or reactions require a separate
mechanism).

**Reaction permission decision:** Give participants `.readWrite` on the social zone share.
This allows reaction records to be written by friends. Owner's activity records should
not be deletable by friends — this is enforced by CloudKit's owner-only deletion rule
for zone sharing (participants with readWrite can create/modify records but cannot delete
records owned by the zone owner).

**FriendsViewModel (@MainActor ObservableObject):**
```
FriendsViewModel
  Dependencies: SocialClient, AuthViewModel
  Published:
    - friends: [FriendProfile]
    - activityFeed: [ActivityEvent]        (merged from all friends' zones)
    - pendingInvites: [CKShare.Metadata]   (from app delegate scene URL handling)
  Methods:
    - loadFeed() async
    - sendInvite(lookupInfo: CKUserIdentity.LookupInfo)
    - acceptInvite(metadata: CKShare.Metadata)
    - react(to event: ActivityEvent)
    - unfriend(friend: FriendProfile)
```

**Deep link handling for share acceptance:** CloudKit share invitations arrive via a URL.
The app must implement `scene(_:continue:)` or handle `CKShare.Metadata` from the app
delegate. This requires wiring in the `App.swift` entry point (already holds `AuthViewModel`
and `ThemeViewModel` as `@StateObject`). Add a `SocialCoordinator` or handle directly in
App.swift via `onOpenURL`.

---

## Component Boundaries Summary

| Component | Layer | Talks To | Does Not Talk To |
|-----------|-------|----------|-----------------|
| `RecoveryScoreEngine` | DomainLayer | Nothing (pure) | HealthKit, CloudKit, UI |
| `DeloadDetector` | DomainLayer/Intelligence | Nothing (pure) | HealthKit, CloudKit, UI |
| `RecoveryViewModel` | UI/ViewModels | RecoveryScoreEngine, HealthClientProtocol, DataClientProtocol, CyclePhaseCache | CloudKit directly |
| `SocialClient` | DataLayer | CKContainer (direct), CKShare APIs | DataClientProtocol, DomainLayer |
| `FriendsViewModel` | UI/ViewModels | SocialClient | CKContainer directly |
| `ActivityEvent` | Models | Codable only | HealthKit, CloudKit |
| `RecoveryScoreRecord` | Models | Codable only | HealthKit, CloudKit |

---

## Data Flow

### Recovery Score Data Flow

```
HealthKitClient (actor)
  fetchWeeklyHeartRateVariability() → [HKQuantitySample]
  fetchSleepAnalysis() → [HKCategorySample]          ← NEW
        ↓
RecoveryViewModel (@MainActor)
  normalizes HK samples to plain Doubles
        ↓
RecoveryScoreEngine.compute(RecoveryInputs) → RecoveryScore
        ↓
DataClientProtocol.save(RecoveryScoreRecord)          ← persists to CloudKit
        ↓
RecoveryDashboardCard (view)                          ← reads published RecoveryScore
RecoveryTrendChart (view)                             ← reads published [RecoveryScore]
```

### Deload Detection Data Flow

```
WeeklyLoadAnalyzer.weeklySummaries() + detectTrends()   ← already computed
PlateauDetector.detect()                                  ← already computed
RecoveryViewModel.trend (last 5 days average)             ← new, from above
        ↓
DeloadDetector.evaluate(DeloadSignals) → DeloadRecommendation
        ↓
DeloadSuggestionSheet (UI, user confirms)
        ↓
DataClientProtocol.save(EnrolledProgramRecord with .deload type)
```

The deload recommendation is recomputed each app launch. It is NOT persisted as its own
record — only the user's acceptance (as an enrolled program) is persisted.

### Social Data Flow

```
User's private CloudKit database
  "SundeeActivity" CKRecordZone
    ActivityEvent records (PR, workout, challenge win)
    ReactionRecord records (high-fives from friends)
    CKShare (one per zone, lists participants)
        ↓
Friends' shared CloudKit database (read from their perspective)
        ↓
SocialClient.fetchFriendActivity() → [ActivityEvent]
        ↓
FriendsViewModel (@MainActor)
        ↓
FriendsFeedView / FriendProfileView (UI)
```

Activity events are written to the social zone when the user completes a workout,
sets a PR, or earns a challenge. This is a **fire-and-forget write** from the relevant
ViewModel (WorkoutViewModel, MaxesViewModel) via a `SocialActivityBroadcaster` helper —
so the social layer doesn't require those ViewModels to know about `SocialClient` directly.

```
SocialActivityBroadcaster (actor, DataLayer/Social/)
  - postIfEnabled(event: ActivityEvent) async
  - Checks: user signed in, social zone exists, not guest mode
  - Calls: SocialClient.postActivity(event:)
```

---

## Suggested Build Order

Dependencies flow bottom-up. Build in this sequence:

**Phase 1 — Recovery Score (no social dependencies)**
1. `HealthClientProtocol` — add `fetchSleepAnalysis()` (extends existing protocol)
2. `HealthKitClient` — implement sleep fetch (extends existing actor)
3. `MockHealthKitClient` — add sleep stub (test/screenshot support)
4. `RecoveryScoreEngine` (pure domain) — no dependencies, testable immediately
5. `RecoveryScoreRecord` (model) — CloudKit-safe field names
6. `RecoveryViewModel` — wires above components; triggers CloudKit write
7. `RecoveryDashboardCard` + `RecoveryDetailView` (UI)

**Phase 2 — Deload Detection (depends on Phase 1 recovery scores)**
1. `DeloadDetector` (pure domain) — depends on WeeklyLoadAnalyzer + RecoveryScore types
2. `DeloadRecommendation` + `ActiveRecoverySession` models
3. Extend `EnrolledProgramRecord` with deload flag (backwards-compatible decode)
4. `DeloadSuggestionSheet` (UI confirmation flow)
5. Integrate into `RecoveryViewModel.refresh()` — evaluate deload after scoring

**Phase 3 — Social Layer (independent of Phase 1/2, but deploy last)**
1. `ActivityEvent` record model
2. `SocialClientProtocol` + `SocialClient` actor
3. `MockSocialClient` (for testing and screenshots without CloudKit)
4. CloudKit: create "SundeeActivity" zone, deploy to production via CloudKit Dashboard
5. `SocialActivityBroadcaster` actor
6. Wire broadcaster into `WorkoutViewModel`, `MaxesViewModel` (post-save hook)
7. `FriendsViewModel`
8. `FriendsFeedView`, `FriendProfileView`, `ReactionView` (UI)
9. Share URL handling in `App.swift`

Phases 1 and 3 are independent — they can be built in parallel by different work streams.
Phase 2 depends on Phase 1 RecoveryScore type being defined.

---

## Patterns to Follow

### Pattern: Pure Domain with Builder Assembly

Matches `CoachContext` / `CoachContextBuilder`. Domain struct holds plain values;
actor-based builder assembles from multiple async sources.

```swift
// Domain struct (DomainLayer — zero imports)
public struct RecoveryInputs: Sendable { ... }
public struct RecoveryScore: Sendable { ... }
public enum RecoveryScoreEngine {
    public static func compute(_ inputs: RecoveryInputs) -> RecoveryScore { ... }
}

// Builder (actor — can import HealthKit, CloudKit via protocols)
public actor RecoveryInputsBuilder {
    func build() async -> RecoveryInputs { ... }
}
```

### Pattern: Backwards-Compatible Record Decoding

All new CloudKit records must follow the resilience pattern. Add `init(from:)` that uses
`try?` with defaults for every field. Use `scoreDate` not `startDate`, `eventDate` not
`createdAt`.

### Pattern: Protocol-Typed Dependencies in ViewModels

All ViewModels take protocol-typed dependencies in their initializer (matching AuthViewModel
and CoachContextBuilder). This allows MockSocialClient, MockHealthKitClient injection in
tests and screenshot mode without conditional compilation.

---

## Anti-Patterns to Avoid

### Anti-Pattern: Recovery Score in HealthKit Observer

**What:** Using `HKObserverQuery` to recompute recovery score on every HealthKit update.
**Why bad:** Background HealthKit observations in Swift 6 strict concurrency require careful
actor isolation. For a daily score, the complexity is not justified.
**Instead:** Compute on app foreground (`scenePhase == .active`) and on manual refresh.
Cache the daily score in CloudKit so it survives app restarts without requerying HealthKit.

### Anti-Pattern: SocialClient Conforming to DataClientProtocol

**What:** Extending `DataClientProtocol` with sharing methods or making `SocialClient`
conform to it.
**Why bad:** `DataClientProtocol` models private-database CRUD. CloudKit sharing involves
a fundamentally different API surface (CKShare, CKUserIdentity, shared database scope).
Forcing it into the same protocol adds leaky abstractions and breaks the protocol's
single-responsibility.
**Instead:** Separate `SocialClientProtocol` with social-specific methods.

### Anti-Pattern: Storing Deload State as a Separate Record

**What:** Adding a `DeloadStateRecord` to CloudKit.
**Why bad:** Adds a new schema record type requiring index creation + production deployment.
The accepted deload IS an enrolled program — storing it twice creates sync ambiguity.
**Instead:** Add an `isDeloadWeek: Bool` field to `EnrolledProgramRecord` with backwards-
compatible decoding (try Bool, fall back to Int64 = 0, per existing pattern).

### Anti-Pattern: Eager Social Zone Creation

**What:** Creating the "SundeeActivity" `CKRecordZone` at first app launch for all users.
**Why bad:** Creates CloudKit records on behalf of users who may never use social features,
wastes iCloud storage quota, and triggers unnecessary permissions dialogs.
**Instead:** Lazy initialization — create zone only when user first navigates to Friends tab
or explicitly enables social features.

---

## Scalability Considerations

| Concern | Current (1 user) | At 100 friends | Notes |
|---------|-----------------|---------------|-------|
| Friend feed fetch | N/A | Parallel `recordZoneChanges` per friend | Use `CKFetchRecordZoneChangesOperation` with all zone IDs in one batch operation |
| Recovery score history | 0 records | ~90 RecoveryScoreRecords | Trivial for CloudKit private DB |
| Activity events | 0 records | ~5-10/week/user | Prune events older than 90 days |
| Social zone participants | N/A | ~50 friends realistic | CKShare has no documented hard limit on participants; Apple forums suggest practical limit is low hundreds |

---

## Sources

- Existing codebase: `/SundeeFundee/Sources/SundeeFundeeKit/` (direct inspection)
- [CloudKit Zone Sharing — Swift with Majid](https://swiftwithmajid.com/2022/03/29/zone-sharing-in-cloudkit/) (MEDIUM confidence)
- [Apple sample-cloudkit-zonesharing on GitHub](https://github.com/apple/sample-cloudkit-zonesharing) (HIGH confidence — official Apple sample)
- [CKShare Apple Developer Documentation](https://developer.apple.com/documentation/cloudkit/ckshare) (HIGH confidence)
- [CloudKit sharing limits — Apple Developer Forums](https://developer.apple.com/forums/thread/767226) (MEDIUM confidence — forum thread)
- [HKCategoryValueSleepAnalysis — Apple Developer Documentation](https://developer.apple.com/documentation/healthkit/hkcategoryvaluesleepanalysis) (HIGH confidence)
- [Retrieving Sleep Data with HealthKit in Swift — Medium](https://medium.com/@nathan.woolmore/retrieving-sleep-data-with-healthkit-in-swift-e81829f4a726) (MEDIUM confidence)
- Athlytic / Cora recovery score algorithm pattern survey (MEDIUM confidence — behavioral inference from App Store descriptions)
