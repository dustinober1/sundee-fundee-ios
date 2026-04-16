# Technology Stack: Recovery Score, Deload Automation, and Social Features

**Project:** Sundee Fundee v2
**Researched:** 2026-04-15
**Confidence:** HIGH (HealthKit/CloudKit verified against Apple docs and codebase; algorithm approach verified against published research)

---

## Existing Foundation (Do Not Re-research)

The app already uses:
- `HealthKitClient` actor with `fetchHeartRateVariability`, `fetchRestingHeartRate`, `fetchWorkouts`, `fetchActiveEnergy` — all wired with `withCheckedThrowingContinuation` wrapping callback-based HealthKit APIs
- `standardReadTypes` already includes `.heartRateVariabilitySDNN`, `.restingHeartRate`, `.heartRate`, `.menstrualFlow`
- `CloudKitClient` actor for private database CRUD
- Swift 6 strict concurrency throughout; zero external dependencies

The gaps are: sleep stage queries, sleep authorization, CloudKit shared zones, and the domain-layer scoring engine.

---

## Feature 1: HealthKit Sleep Data

### What to Add

`sleepAnalysis` is a `HKCategoryType`, not a `HKQuantityType`. It is not in `standardReadTypes` today. Sleep stage data requires iOS 16+ and Apple Watch (or third-party device writing to Health).

**Sleep stage values (HKCategoryValueSleepAnalysis):**

| Case | Raw Value | Meaning | iOS Availability |
|------|-----------|---------|-----------------|
| `.inBed` | 0 | User is in bed (not necessarily asleep) | iOS 8+ |
| `.asleepUnspecified` | 1 | Legacy "asleep" — pre-iOS 16 catch-all | iOS 8+ |
| `.awake` | 2 | Awake during sleep window | iOS 16+ |
| `.asleepCore` | 3 | Light/intermediate sleep (N1+N2) | iOS 16+ |
| `.asleepDeep` | 4 | Slow-wave / deep sleep | iOS 16+ |
| `.asleepREM` | 5 | REM sleep | iOS 16+ |

`HKCategoryValueSleepAnalysis.asleepValues` is a static set containing `.asleepUnspecified`, `.asleepCore`, `.asleepDeep`, `.asleepREM` — use this for "is this sample a sleep period?" without hardcoding raw values.

**Authorization**: Add to `standardReadTypes`:
```swift
if let sleep = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) {
    types.insert(sleep)
}
```

**Query pattern** (fits the existing `fetchSamples` private helper):
```swift
public func fetchSleepAnalysis(
    startDate: Date,
    endDate: Date
) async throws -> [HKCategorySample] {
    guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
        throw HealthError.noData(type: "sleep analysis")
    }
    let predicate = HKQuery.predicateForSamples(
        withStart: startDate,
        end: endDate,
        options: .strictStartDate
    )
    return try await fetchSamples(
        sampleType: sleepType,
        predicate: predicate,
        sortDescriptor: NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true),
        limit: HKObjectQueryNoLimit
    ) as? [HKCategorySample] ?? []
}
```

**Source filtering** — Apple Watch/Health writes from `com.apple.health` and `com.apple.sleepanalysis`. Third-party apps (Sleep Cycle, AutoSleep) also write sleep. Filter to authoritative sources:
```swift
let appleSamples = samples.filter {
    $0.sourceRevision.source.bundleIdentifier.hasPrefix("com.apple")
}
```
Prefer Apple Watch data when available; fall back to all sources if no Apple samples exist.

**Sleep window**: Query from 18:00 the previous day to 10:00 today to capture a single night without including the prior afternoon nap window. Adjust relative to midnight if needed.

**Duration calculation**: Sum `.asleepCore + .asleepDeep + .asleepREM` durations only. Do not include `.inBed` or `.awake` in total sleep time. This matches how the Health app calculates "Time Asleep."

**What not to use**: `HKActivitySummary` does not contain sleep data. `HKStatisticsQuery` does not work with `HKCategoryType` — it only works with `HKQuantityType`. Always use `HKSampleQuery` for sleep.

### Protocol Extension to Add

Add `fetchSleepAnalysis(startDate:endDate:)` to `HealthClientProtocol` and `MockHealthKitClient`. Add a convenience method `fetchLastNightSleep()` that uses the 18:00 yesterday / 10:00 today window.

---

## Feature 2: HRV Interpretation for Recovery Scoring

### What the Existing Data Means

`heartRateVariabilitySDNN` is SDNN — standard deviation of all NN (normal sinus) intervals in a measurement window. Apple Watch records it opportunistically during rest and via the Breathe/Mindfulness app.

**Key difference from fitness wearables**: WHOOP and Oura use RMSSD (root mean square of successive differences) measured during deep sleep. Apple Watch SDNN is measured during short rest windows. SDNN and RMSSD are not numerically comparable — you cannot apply WHOOP thresholds to Apple Watch SDNN values.

**Typical Apple Watch SDNN population ranges** (MEDIUM confidence — population data varies by study):
- Age 20-29: 40-80ms is typical
- Age 30-39: 35-70ms
- Age 40-49: 30-60ms
- Age 50+: 25-50ms

**Why absolute thresholds fail**: A 40ms SDNN might be excellent for a 55-year-old and concerning for a 25-year-old athlete. Population-level "green/yellow/red" bands will misclassify users constantly.

### Personal Baseline Approach (the correct approach)

Build a rolling personal baseline rather than using fixed thresholds. This is what HRV4Training, Athlytic, and other evidence-based apps do:

- **Chronic baseline**: 60-day rolling average of SDNN (provides stable personal normal)
- **Acute window**: 7-day rolling average
- **Recovery signal**: `acuteAvg / chronicAvg` ratio
  - Above 1.0: HRV trending above baseline (favorable)
  - 0.85–1.0: Within normal variation
  - 0.70–0.85: Mild suppression (yellow)
  - Below 0.70: Significant suppression (red)

**Cold start problem**: New users have fewer than 7 days of data. Treat the first 14 days as a calibration period — show recovery score as "calibrating" rather than a number. Begin scoring once 14 days of HRV data exist.

**HRV query**: The existing `fetchHeartRateVariability(startDate:endDate:)` already works. For recovery scoring, fetch the past 60 days to compute the chronic baseline. Sort descending (most recent first).

**Why not use the most recent single sample**: Apple Watch HRV varies significantly between samples. Use the 7-day average as the acute value to smooth noise.

---

## Feature 3: Recovery Score Algorithm

### Architecture Decision

Implement as a pure domain function in `DomainLayer/Recovery/`. No HealthKit imports — accept pre-fetched data. This matches the existing pattern (domain layer is zero-dependency).

### Input Model

```swift
public struct RecoveryInputs: Sendable {
    // From HealthKit
    public var recentHRVSamples: [Double]        // SDNN values, past 7 days (ms)
    public var chronicHRVSamples: [Double]       // SDNN values, past 60 days (ms)
    public var lastNightSleep: SleepSummary      // total duration + stage breakdown
    public var restingHeartRate: Double?         // today's resting HR (bpm)

    // From existing domain layer
    public var currentCyclePhase: CyclePhase
    public var trainingLoadRatio: Double         // ACWR: acute 7-day / chronic 28-day
    public var daysSinceLastWorkout: Int
    public var recentPainLevel: Int              // 0-10 from pain logs
}

public struct SleepSummary: Sendable {
    public var totalSleepMinutes: Double
    public var deepSleepMinutes: Double
    public var remSleepMinutes: Double
    public var coreSleepMinutes: Double
    public var isAvailable: Bool                 // false if HealthKit denied/no data
}
```

### Scoring Formula

Five components, each scored 0–100, then weighted:

| Component | Weight | Rationale |
|-----------|--------|-----------|
| HRV ratio vs baseline | 35% | Strongest objective signal; matches research (HRV carries highest weight in Garmin, Athlytic, AI Endurance models) |
| Sleep quality | 25% | Total duration + deep/REM proportion; well-documented fatigue predictor |
| Training load (ACWR) | 20% | Existing `WeeklyLoadAnalyzer` already computes this; ACWR 0.8–1.3 is "sweet spot" |
| Cycle phase modifier | 15% | App's core differentiator; follicular/luteal recovery capacity differs |
| Resting heart rate | 5% | Useful signal but noisier than HRV; minor weight |

**HRV component (0–100)**:
```
ratio = acuteAvg / chronicAvg
score = clamp((ratio - 0.70) / 0.50 * 100, 0, 100)
// ratio 0.70 → score 0, ratio 1.20+ → score 100
```

**Sleep component (0–100)**:
```
durationScore = clamp(totalMinutes / 480.0 * 100, 0, 100)  // 8 hours = 100
qualityScore = (deepMinutes + remMinutes) / totalMinutes * 100 (if available)
sleepScore = durationScore * 0.6 + qualityScore * 0.4
```
If sleep data unavailable: use 50 (neutral, not penalized for privacy denial).

**Training load component (0–100)**:
```
// ACWR "sweet spot" = 0.8–1.3, danger zone = >1.5
if acwr < 0.5: score = 40          // undertraining (low fitness signal)
if acwr in 0.5–0.8: score = 70    // below sweet spot
if acwr in 0.8–1.3: score = 100   // optimal zone
if acwr in 1.3–1.5: score = 70    // elevated but manageable
if acwr > 1.5: score = 20         // spike zone, injury risk signal
```

**Cycle phase modifier (multiplier, not additive)**:
```
// Based on existing adaptation multipliers; adjust final score
follicular: 1.05   // energy typically higher
ovulatory:  1.10   // peak performance window
luteal:     0.95   // fatigue/mood sensitivity
menstrual:  0.85   // recovery prioritized
```

**Resting heart rate component (0–100)**:
```
// Score relative to personal 30-day average
deviation = (personalAvg - today) / personalAvg
score = clamp(50 + deviation * 200, 0, 100)
// RHR 5bpm below average → score ~90; 5bpm above → score ~10
```

**Final composite**:
```
raw = hrv*0.35 + sleep*0.25 + load*0.20 + rhr*0.05
final = raw * cycleModifier
output = clamp(round(final), 0, 100)
```

### Graceful Degradation

- If HRV not available (HealthKit denied or <14 days data): drop HRV weight to 0, redistribute to sleep (40%) and load (30%). Show "Calibrating" badge on score card.
- If sleep not available: use 50 for sleep component, flag on detail screen.
- If no RHR: drop to 0 weight, add to HRV weight.
- Never fail to show a score — always compute with available signals.

---

## Feature 4: Deload Detection Algorithm

### Architecture Decision

Extend `Intelligence/PlateauDetector` or add a sibling `DeloadDetector` in `DomainLayer/Intelligence/`. Pure function: accepts historical data, returns `DeloadRecommendation`.

### Trigger Signals (all must be evaluated together, not individually)

```swift
public struct DeloadSignals: Sendable {
    public var averageRecoveryScore7Days: Double      // rolling average
    public var recoverySoreTrend: Double             // slope: negative = declining
    public var acwr: Double                          // acute:chronic workload ratio
    public var weeklyVolumeChangePercent: Double     // week-over-week volume delta
    public var consecutiveLowRecoveryDays: Int       // streak of score < 55
    public var daysSinceLastDeload: Int
    public var plateauDetected: Bool                 // from existing PlateauDetector
}
```

### Decision Logic

```
STRONG deload signal (recommend immediately):
  - consecutiveLowRecoveryDays >= 5
  - OR (averageRecoveryScore7Days < 45 AND acwr > 1.4)
  - OR (plateauDetected AND averageRecoveryScore7Days < 60)

MODERATE deload signal (suggest soon):
  - consecutiveLowRecoveryDays >= 3
  - OR (recoverySoreTrend is declining AND daysSinceLastDeload > 21)
  - OR (acwr > 1.5 for 3+ consecutive days)

NO deload needed:
  - averageRecoveryScore7Days >= 65
  - AND consecutiveLowRecoveryDays < 2
```

Minimum interval between deloads: 14 days (avoid deload thrash for users whose recovery score is chronically low due to lifestyle factors).

### Deload Program Generation

Replace the current week's lifting sessions with active recovery content. Use the existing `ProgramTemplateGenerator` pattern — add an `activeRecoveryWeek()` generator:

```swift
public enum ActiveRecoveryType: Sendable {
    case mobility(focus: MuscleGroup)        // 20-40 min mobility/stretching
    case lightCardio(duration: Int)          // 20-30 min zone 2 walk/bike
    case yoga(style: YogaStyle)              // restorative or vinyasa
}
```

Session structure: 3–4 sessions for the deload week, matching the user's normal frequency, replacing all lifting with mobility/yoga/cardio. No 1RM tracking, no progressive overload — pure recovery.

---

## Feature 5: CloudKit Shared Zones (Social Layer)

### Architecture Decision

Use **CloudKit zone-based sharing** (introduced WWDC 2021). Each user shares their activity feed as a private CKRecordZone. Friends accept a share link and read from the shared database. No separate social backend required.

### Key Constraints to Understand Before Building

- **One CKShare per zone** — you cannot have multiple share configurations for the same zone. This means the entire "activity feed" zone is shared with all friends at once. You cannot share with friend A but not friend B within the same zone — either everyone in the share list sees everything, or nobody does.
- **Participant limit** — officially undocumented but developer reports suggest ~100 participants per share is practical. 100 friends is more than sufficient for this use case.
- **iCloud required** — all participants must be signed in to iCloud. Guest-mode users cannot participate in social features. This is acceptable given the constraint.
- **Sharing by link** — UICloudSharingController presents the standard iOS sharing sheet and generates a `ckshare://` URL. Recipients tap the link, iOS opens the app via the scene delegate, and the app calls `accept(_:)` on the metadata.

### Zone Design

Create two zones per user:

| Zone Name | Purpose | Shared? |
|-----------|---------|---------|
| `UserPrivateZone` | All personal data (workouts, cycles, settings) | No |
| `UserActivityFeedZone` | PR records, workout completions, challenge badges | Yes (read-only to friends) |

Separating activity feed from private data ensures friends only see what you explicitly publish to the feed zone — not your cycle data, settings, or injury logs.

### Activity Feed Record Design

```swift
// Stored in UserActivityFeedZone (shared zone)
struct ActivityFeedRecord: Codable, Sendable {
    var recordID: String        // CKRecord.ID name
    var activityType: String    // "pr", "workout", "challenge", "streak"
    var displayText: String     // "Hit a new PR on deadlift: 225 lbs"
    var dateCreated: Date       // Avoid CloudKit system field name "createdAt"
    var userDisplayName: String // Denormalized — cached at write time
    var highFiveCount: Int      // Aggregate updated by owner
    var metadata: String        // JSON-encoded type-specific data
}
```

Note: `highFiveCount` is updated by the owner (write to private zone, push to feed zone). Participants cannot write to the feed zone (`.readOnly` permission). "High-five" reactions are stored in the reactor's own private zone and aggregated by count only — no per-user reaction tracking needed in the shared zone.

### UICloudSharingController Integration

`UICloudSharingController` is a UIKit class — wrap with `UIViewControllerRepresentable` in SwiftUI. Critical: create the `CKShare` object first (save it), then initialize the controller with the pre-existing share. The other constructor (takes a preparationHandler closure) has known bugs when wrapped in SwiftUI.

```swift
// Step 1: Create and save share in actor
func createOrFetchActivityFeedShare() async throws -> CKShare {
    // Check for existing share first — one CKShare per zone
    let existingShares = try await container.privateCloudDatabase
        .fetchShares(matching: [activityFeedZoneID])
    if let existing = existingShares[activityFeedZoneID] {
        return existing
    }
    let share = CKShare(recordZoneID: activityFeedZoneID)
    share[CKShare.SystemFieldKey.title] = "My Sundee Fundee Activity"
    share.publicPermission = .none    // invitation-only, not public link
    _ = try await container.privateCloudDatabase.save(share)
    return share
}

// Step 2: Present UICloudSharingController with the pre-saved share
struct ShareView: UIViewControllerRepresentable {
    let share: CKShare
    let container: CKContainer
    func makeUIViewController(context: Context) -> UICloudSharingController {
        let vc = UICloudSharingController(share: share, container: container)
        vc.availablePermissions = [.allowReadOnly, .allowPrivate]
        return vc
    }
}
```

### Fetching Friends' Activity Feed

```swift
// In CloudKitClient actor (or a new SocialCloudKitClient actor)
func fetchFriendsActivityFeed() async throws -> [ActivityFeedRecord] {
    let sharedDB = container.sharedCloudDatabase
    let sharedZones = try await sharedDB.allRecordZones()

    return try await withThrowingTaskGroup(of: [ActivityFeedRecord].self) { group in
        for zone in sharedZones {
            group.addTask {
                try await self.fetchActivityRecords(in: zone.zoneID, from: sharedDB)
            }
        }
        var allRecords: [ActivityFeedRecord] = []
        for try await records in group {
            allRecords.append(contentsOf: records)
        }
        return allRecords.sorted { $0.dateCreated > $1.dateCreated }
    }
}
```

### Accepting Share Links

Register the `CKSharingSupported: YES` key in `Info.plist`. Implement in `App.swift` via `.handlesExternalEvents` or scene delegate:

```swift
// SwiftUI app scene delegate
.onOpenURL { url in
    // Handle ckshare:// URLs
    Task {
        try await cloudKitService.acceptShare(from: url)
    }
}
```

Use `CKContainer.accept(_:completionHandler:)` wrapping with `withCheckedThrowingContinuation`.

### What NOT to Use

- **Core Data + CloudKit (`NSPersistentCloudKitContainer`)** — the app already uses direct CloudKit APIs. Do not introduce Core Data — it would require a data model migration and adds complexity without benefit.
- **CloudKit public database** — the public database is for discoverable content, not private social graphs. Social features belong in the private database with zone sharing.
- **CloudKit subscriptions for notifications** — `CKDatabaseSubscription` can push notifications when friends post, but requires APNs entitlement and push certificate setup. Defer push notifications to v3; use on-demand polling for the feed in v2.
- **CloudKit server-to-server** — no server, staying Apple-only.

---

## Privacy and Authorization

### HealthKit Privacy Manifest

The app has a `PrivacyInfo.xcprivacy`. Add these data type declarations for new sleep access:
- `NSPrivacyAccessedAPICategoryHealthData` is not a required reason API (it's in NSHealthShareUsageDescription)
- Add `NSHealthShareUsageDescription` to `Info.plist` if not present: "Sundee Fundee reads your sleep and heart rate data to calculate your daily recovery score."
- Sleep data does NOT require `NSHealthUpdateUsageDescription` (we only read, not write)

### CloudKit Social Features

- No new entitlements required — CloudKit is already in the app entitlements
- Confirm `CloudKit` capability is in `SundeeFundeeApp/project.yml` with the correct container ID
- `CKSharingSupported: YES` must be added to `Info.plist`

---

## Summary: What to Add vs. What Already Exists

| Capability | Status | Action Required |
|------------|--------|-----------------|
| HRV SDNN query | EXISTS (`fetchHeartRateVariability`) | Add 60-day window for chronic baseline |
| Resting HR query | EXISTS (`fetchRestingHeartRate`) | Add 30-day window for personal average |
| Sleep stage query | MISSING | Add `fetchSleepAnalysis` to protocol + actor |
| Sleep authorization | MISSING | Add `.sleepAnalysis` to `standardReadTypes` |
| Recovery score engine | MISSING | New `DomainLayer/Recovery/RecoveryScoreCalculator.swift` |
| Deload detector | PARTIALLY EXISTS | Extend `Intelligence/` with `DeloadDetector` |
| Active recovery programming | MISSING | New `DomainLayer/Program/ActiveRecoveryGenerator.swift` |
| CloudKit activity feed zone | MISSING | New zone design + CRUD in `CloudKitClient` |
| CloudKit zone sharing | MISSING | New `SocialCloudKitClient` actor or extend existing |
| Share acceptance (scene delegate) | MISSING | `App.swift` + `Info.plist` changes |
| UICloudSharingController | MISSING | New SwiftUI-wrapped view component |

---

## Sources

- [HKCategoryValueSleepAnalysis — Apple Developer Docs](https://developer.apple.com/documentation/healthkit/hkcategoryvaluesleepanalysis)
- [HKCategoryValueSleepAnalysis.asleepCore — Apple Developer Docs](https://developer.apple.com/documentation/healthkit/hkcategoryvaluesleepanalysis/asleepcore)
- [heartRateVariabilitySDNN — Apple Developer Docs](https://developer.apple.com/documentation/healthkit/hkquantitytypeidentifier/heartratevariabilitysdnn)
- [Retrieving Sleep Data with HealthKit in Swift — Nathan Woolmore, Medium](https://medium.com/@nathan.woolmore/retrieving-sleep-data-with-healthkit-in-swift-e81829f4a726)
- [How different wearables measure HRV: SDNN vs RMSSD — Empirical Health](https://www.empirical.health/blog/how-wearables-measure-hrv/)
- [On Heart Rate Variability and Readiness — Marco Altini, Medium](https://medium.com/@altini_marco/on-heart-rate-variability-hrv-and-readiness-394a499ed05b)
- [Zone sharing in CloudKit — Swift with Majid](https://swiftwithmajid.com/2022/03/29/zone-sharing-in-cloudkit/)
- [Sharing CloudKit Data with Other iCloud Users — Apple Developer Docs](https://developer.apple.com/documentation/CloudKit/sharing-cloudkit-data-with-other-icloud-users)
- [CKShare — Apple Developer Docs](https://developer.apple.com/documentation/cloudkit/ckshare)
- [Apple sample-cloudkit-zonesharing — GitHub](https://github.com/apple/sample-cloudkit-zonesharing)
- [Acute:Chronic Workload Ratio — Science for Sport](https://www.scienceforsport.com/acutechronic-workload-ratio/)
- [HRV4Training app — recovery baseline methodology](https://apps.apple.com/us/app/hrv4training/id686923970)
- [Athlytic recovery score approach — Help Scout](https://athlyticapp.helpscoutdocs.com/article/21-recovery-preferences)
- [Training Readiness classification — Garmin Wiki](https://wiki.garminrumors.com/Training_Readiness)
- [Best Recovery Apps 2026 Compared — Cora Health](https://www.corahealth.app/blog/best-recovery-apps)
