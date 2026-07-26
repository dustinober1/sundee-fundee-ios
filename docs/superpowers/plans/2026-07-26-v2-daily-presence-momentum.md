# Sundee Fundee 2.0 Daily Presence and Momentum Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship the solo version 2.0 everyday loop: one presence per local day, optional one-tap status, meaningful participation levels, rolling consistency summaries, supportive achievements, and an optional daily-plan reminder.

**Architecture:** Add a small engagement domain bounded away from readiness and workout-decision logic. `DailyPresenceService` writes to a local cache first, reconciles with the active `DataClientProtocol`, and exposes pure `ConsistencyMomentumService` summaries through a `@MainActor` view model on Today. Existing workout and check-in notifications promote the current day without changing training prescriptions.

**Tech Stack:** Swift 6 strict concurrency, SwiftUI, Foundation, UserNotifications, CloudKit through `DataClientProtocol`, XCTest/Swift Testing, iOS 18+

## Global Constraints

- iOS 18+.
- CloudKit-only remote backend and zero external package dependencies.
- Swift 6 strict concurrency; view models are `@MainActor`, I/O services are actors, and pure domain services have no UI dependencies.
- Use `AppTheme.*` tokens only and semantic Dynamic Type font sizes.
- Use `HapticFeedback` for user-triggered status changes.
- Never display `error.localizedDescription` directly to users.
- HealthKit denial must not affect presence, momentum, or status selection.
- Dates encode as ISO8601 strings; avoid CloudKit-reserved field names including `createdAt`, `modifiedAt`, `startDate`, and `endDate`.
- Opening the app counts at most once per local calendar day.
- Missed days never erase rolling consistency history or trigger punitive copy.
- Rest and active recovery are successful intentional actions.
- All features remain free; do not add paywalls or paid engagement mechanics.
- Do not upload or submit to App Store Connect.
- Commit one file at a time. Never use `git add .`, `git add -A`, amend, or force-push.

## Delivery Sequence

This is plan 1 of 4:

1. Daily Presence and Momentum — this plan.
2. One-to-One Buddies — written after this plan's record and visibility contracts are verified.
3. Small Groups — written after buddy CloudKit sharing is verified.
4. External Growth — written after group membership and invitation contracts are stable.

---

### Task 1: Daily Presence Domain Record

**Files:**
- Create: `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Engagement/DailyPresenceRecord.swift`
- Test: `SundeeFundee/Tests/SundeeFundeeKitTests/DomainTests/DailyPresenceRecordTests.swift`

**Interfaces:**
- Produces: `DailyPresenceStatus`, `DailyParticipationLevel`, and `DailyPresenceRecord`.
- Record identifier format: `presence-<yyyy-MM-dd>-<sanitized-time-zone>`.
- Later tasks rely on `DailyPresenceRecord.makeID(dayKey:timeZoneIdentifier:)` and `promoting(to:status:at:)`.

- [ ] **Step 1: Write failing enum, identifier, promotion, and Codable tests**

```swift
import Foundation
import Testing
@testable import SundeeFundeeKit

@Suite("Daily presence record")
struct DailyPresenceRecordTests {
    @Test func identifierIsStableAndCloudKitSafe() {
        #expect(
            DailyPresenceRecord.makeID(
                dayKey: "2026-07-26",
                timeZoneIdentifier: "America/New_York"
            ) == "presence-2026-07-26-America-New_York"
        )
    }

    @Test func promotionNeverDowngradesParticipation() {
        let firstOpen = Date(timeIntervalSince1970: 1_753_500_000)
        let record = DailyPresenceRecord(
            dayKey: "2026-07-26",
            timeZoneIdentifier: "America/New_York",
            firstOpenDate: firstOpen
        )

        let acted = record.promoting(to: .acted, status: .resting, at: firstOpen.addingTimeInterval(60))
        let attemptedDowngrade = acted.promoting(to: .checkedIn, status: .tired, at: firstOpen.addingTimeInterval(120))

        #expect(attemptedDowngrade.participationLevel == .acted)
        #expect(attemptedDowngrade.status == .tired)
        #expect(attemptedDowngrade.mostRecentOpenDate == firstOpen.addingTimeInterval(120))
    }

    @Test func oldRecordWithoutOptionalFieldsDecodes() throws {
        let json = """
        {
          "id":"presence-2026-07-26-America_New_York",
          "dayKey":"2026-07-26",
          "timeZoneIdentifier":"America/New_York",
          "firstOpenDate":"2026-07-26T12:00:00Z",
          "mostRecentOpenDate":"2026-07-26T12:00:00Z",
          "participationLevelRaw":"showedUp",
          "dateCreated":"2026-07-26T12:00:00Z",
          "dateUpdated":"2026-07-26T12:00:00Z"
        }
        """
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let record = try decoder.decode(DailyPresenceRecord.self, from: Data(json.utf8))

        #expect(record.status == nil)
        #expect(record.modelVersion == 1)
    }
}
```

- [ ] **Step 2: Run the focused tests and verify failure**

Run:

```bash
cd SundeeFundee && swift test --filter DailyPresenceRecordTests
```

Expected: compilation fails because `DailyPresenceRecord` is not defined.

- [ ] **Step 3: Implement the domain types**

```swift
import Foundation

public enum DailyPresenceStatus: String, Codable, Sendable, CaseIterable, Equatable {
    case ready
    case tired
    case sore
    case resting
    case trained
}

public enum DailyParticipationLevel: String, Codable, Sendable, CaseIterable, Comparable, Equatable {
    case showedUp
    case checkedIn
    case acted

    private var rank: Int {
        switch self {
        case .showedUp: 0
        case .checkedIn: 1
        case .acted: 2
        }
    }

    public static func < (lhs: Self, rhs: Self) -> Bool { lhs.rank < rhs.rank }
}

public struct DailyPresenceRecord: Codable, Sendable, Identifiable, Equatable {
    public let id: String
    public let dayKey: String
    public let timeZoneIdentifier: String
    public let firstOpenDate: Date
    public let mostRecentOpenDate: Date
    public let participationLevelRaw: String
    public let statusRaw: String?
    public let dateCreated: Date
    public let dateUpdated: Date
    public let modelVersion: Int

    public var participationLevel: DailyParticipationLevel {
        DailyParticipationLevel(rawValue: participationLevelRaw) ?? .showedUp
    }

    public var status: DailyPresenceStatus? {
        statusRaw.flatMap(DailyPresenceStatus.init(rawValue:))
    }

    public init(
        dayKey: String,
        timeZoneIdentifier: String,
        firstOpenDate: Date,
        mostRecentOpenDate: Date? = nil,
        participationLevel: DailyParticipationLevel = .showedUp,
        status: DailyPresenceStatus? = nil,
        dateCreated: Date? = nil,
        dateUpdated: Date? = nil,
        modelVersion: Int = 1
    ) {
        id = Self.makeID(dayKey: dayKey, timeZoneIdentifier: timeZoneIdentifier)
        self.dayKey = dayKey
        self.timeZoneIdentifier = timeZoneIdentifier
        self.firstOpenDate = firstOpenDate
        self.mostRecentOpenDate = mostRecentOpenDate ?? firstOpenDate
        participationLevelRaw = participationLevel.rawValue
        statusRaw = status?.rawValue
        self.dateCreated = dateCreated ?? firstOpenDate
        self.dateUpdated = dateUpdated ?? firstOpenDate
        self.modelVersion = modelVersion
    }

    public static func makeID(dayKey: String, timeZoneIdentifier: String) -> String {
        let safeZone = timeZoneIdentifier.map {
            $0.isLetter || $0.isNumber || $0 == "-" ? String($0) : "_"
        }.joined()
        return "presence-\(dayKey)-\(safeZone)"
    }

    public func promoting(
        to proposedLevel: DailyParticipationLevel,
        status proposedStatus: DailyPresenceStatus?,
        at date: Date
    ) -> Self {
        Self(
            dayKey: dayKey,
            timeZoneIdentifier: timeZoneIdentifier,
            firstOpenDate: firstOpenDate,
            mostRecentOpenDate: date,
            participationLevel: max(participationLevel, proposedLevel),
            status: proposedStatus ?? status,
            dateCreated: dateCreated,
            dateUpdated: date,
            modelVersion: modelVersion
        )
    }

    private enum CodingKeys: String, CodingKey {
        case id, dayKey, timeZoneIdentifier, firstOpenDate, mostRecentOpenDate
        case participationLevelRaw, statusRaw, dateCreated, dateUpdated, modelVersion
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(String.self, forKey: .id)
        dayKey = try values.decode(String.self, forKey: .dayKey)
        timeZoneIdentifier = try values.decode(String.self, forKey: .timeZoneIdentifier)
        firstOpenDate = try values.decode(Date.self, forKey: .firstOpenDate)
        mostRecentOpenDate = try values.decode(Date.self, forKey: .mostRecentOpenDate)
        participationLevelRaw = try values.decode(String.self, forKey: .participationLevelRaw)
        statusRaw = try values.decodeIfPresent(String.self, forKey: .statusRaw)
        dateCreated = try values.decode(Date.self, forKey: .dateCreated)
        dateUpdated = try values.decode(Date.self, forKey: .dateUpdated)
        modelVersion = try values.decodeIfPresent(Int.self, forKey: .modelVersion) ?? 1
    }
}
```

- [ ] **Step 4: Run the focused tests**

Run:

```bash
cd SundeeFundee && swift test --filter DailyPresenceRecordTests
```

Expected: all `DailyPresenceRecordTests` pass.

- [ ] **Step 5: Commit the domain record**

```bash
git add SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Engagement/DailyPresenceRecord.swift
git commit -m "feat(engagement): add daily presence record"
git add SundeeFundee/Tests/SundeeFundeeKitTests/DomainTests/DailyPresenceRecordTests.swift
git commit -m "test(engagement): cover daily presence record"
```

---

### Task 2: Pure Consistency Momentum Calculation

**Files:**
- Create: `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Engagement/ConsistencyMomentumService.swift`
- Test: `SundeeFundee/Tests/SundeeFundeeKitTests/DomainTests/ConsistencyMomentumServiceTests.swift`

**Interfaces:**
- Consumes: `[DailyPresenceRecord]`, reference `Date`, and `Calendar`.
- Produces: `ConsistencyMomentumSummary` with current-week counts and four complete weekly buckets.
- Does not fetch, save, log, or import SwiftUI.

- [ ] **Step 1: Write failing current-week and non-resetting-history tests**

```swift
import Foundation
import Testing
@testable import SundeeFundeeKit

@Suite("Consistency momentum")
struct ConsistencyMomentumServiceTests {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/New_York")!
        calendar.firstWeekday = 2
        return calendar
    }

    private func date(_ value: String) -> Date {
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: "\(value)T16:00:00Z")!
    }

    private func record(_ day: String, level: DailyParticipationLevel) -> DailyPresenceRecord {
        DailyPresenceRecord(
            dayKey: day,
            timeZoneIdentifier: calendar.timeZone.identifier,
            firstOpenDate: date(day),
            participationLevel: level
        )
    }

    @Test func summarizesDistinctParticipationLevels() {
        let records = [
            record("2026-07-20", level: .showedUp),
            record("2026-07-21", level: .checkedIn),
            record("2026-07-22", level: .acted)
        ]

        let result = ConsistencyMomentumService().summarize(
            records: records,
            referenceDate: date("2026-07-26"),
            calendar: calendar
        )

        #expect(result.daysPresentThisWeek == 3)
        #expect(result.checkInsThisWeek == 2)
        #expect(result.actionDaysThisWeek == 1)
    }

    @Test func emptyCurrentWeekDoesNotErasePriorWeeks() {
        let result = ConsistencyMomentumService().summarize(
            records: [record("2026-07-13", level: .acted)],
            referenceDate: date("2026-07-26"),
            calendar: calendar
        )

        #expect(result.daysPresentThisWeek == 0)
        #expect(result.rollingWeeks.map(\.daysPresent).contains(1))
        #expect(result.supportiveHeadline == "Welcome back")
    }
}
```

- [ ] **Step 2: Run the focused tests and verify failure**

Run:

```bash
cd SundeeFundee && swift test --filter ConsistencyMomentumServiceTests
```

Expected: compilation fails because the momentum types do not exist.

- [ ] **Step 3: Implement the pure summary service**

```swift
import Foundation

public struct WeeklyPresenceSummary: Sendable, Equatable {
    public let weekStart: Date
    public let daysPresent: Int
    public let checkInDays: Int
    public let actionDays: Int
}

public struct ConsistencyMomentumSummary: Sendable, Equatable {
    public let daysPresentThisWeek: Int
    public let checkInsThisWeek: Int
    public let actionDaysThisWeek: Int
    public let rollingWeeks: [WeeklyPresenceSummary]
    public let supportiveHeadline: String
}

public struct ConsistencyMomentumService: Sendable {
    public init() {}

    public func summarize(
        records: [DailyPresenceRecord],
        referenceDate: Date,
        calendar: Calendar
    ) -> ConsistencyMomentumSummary {
        let currentWeekStart = calendar.dateInterval(of: .weekOfYear, for: referenceDate)!.start
        let starts = (0..<4).compactMap {
            calendar.date(byAdding: .weekOfYear, value: -$0, to: currentWeekStart)
        }.reversed()

        let weeks = starts.map { start in
            let end = calendar.date(byAdding: .weekOfYear, value: 1, to: start)!
            let matches = records.filter { $0.firstOpenDate >= start && $0.firstOpenDate < end }
            return WeeklyPresenceSummary(
                weekStart: start,
                daysPresent: Set(matches.map(\.dayKey)).count,
                checkInDays: Set(matches.filter { $0.participationLevel >= .checkedIn }.map(\.dayKey)).count,
                actionDays: Set(matches.filter { $0.participationLevel >= .acted }.map(\.dayKey)).count
            )
        }
        let current = weeks.last ?? WeeklyPresenceSummary(
            weekStart: currentWeekStart,
            daysPresent: 0,
            checkInDays: 0,
            actionDays: 0
        )
        let hasEarlierPresence = weeks.dropLast().contains { $0.daysPresent > 0 }
        let headline = current.daysPresent > 0
            ? "\(current.daysPresent) \(current.daysPresent == 1 ? "day" : "days") present this week"
            : (hasEarlierPresence ? "Welcome back" : "Start by showing up today")

        return ConsistencyMomentumSummary(
            daysPresentThisWeek: current.daysPresent,
            checkInsThisWeek: current.checkInDays,
            actionDaysThisWeek: current.actionDays,
            rollingWeeks: weeks,
            supportiveHeadline: headline
        )
    }
}
```

- [ ] **Step 4: Run the focused tests**

Run:

```bash
cd SundeeFundee && swift test --filter ConsistencyMomentumServiceTests
```

Expected: all momentum tests pass.

- [ ] **Step 5: Commit the calculation**

```bash
git add SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Engagement/ConsistencyMomentumService.swift
git commit -m "feat(engagement): calculate consistency momentum"
git add SundeeFundee/Tests/SundeeFundeeKitTests/DomainTests/ConsistencyMomentumServiceTests.swift
git commit -m "test(engagement): cover consistency momentum"
```

---

### Task 3: Local-First Presence Store and Sync Service

**Files:**
- Create: `SundeeFundee/Sources/SundeeFundeeKit/DataLayer/Engagement/PresenceLocalStore.swift`
- Create: `SundeeFundee/Sources/SundeeFundeeKit/DataLayer/Engagement/DailyPresenceService.swift`
- Test: `SundeeFundee/Tests/SundeeFundeeKitTests/DataLayerTests/DailyPresenceServiceTests.swift`

**Interfaces:**
- Produces protocol:

```swift
public protocol PresenceLocalStoring: Sendable {
    func load() async throws -> [DailyPresenceRecord]
    func save(_ record: DailyPresenceRecord) async throws
    func markSynced(id: String) async throws
    func pending() async throws -> [DailyPresenceRecord]
}
```

- Produces actor methods:

```swift
public func recordOpen(at: Date, calendar: Calendar) async throws -> DailyPresenceRecord
public func promoteToday(to: DailyParticipationLevel, status: DailyPresenceStatus?, at: Date, calendar: Calendar) async throws -> DailyPresenceRecord
public func loadSummary(referenceDate: Date, calendar: Calendar) async throws -> ConsistencyMomentumSummary
public func syncPending() async
```

- Uses `DataClientProtocol.save(_:recordType:)` with record type `DailyPresenceRecord`.

- [ ] **Step 1: Write failing local-first, idempotency, and retry tests**

```swift
import Foundation
import Testing
@testable import SundeeFundeeKit

actor MemoryPresenceStore: PresenceLocalStoring {
    var records: [String: DailyPresenceRecord] = [:]
    var pendingIDs: Set<String> = []

    func load() -> [DailyPresenceRecord] { Array(records.values) }
    func save(_ record: DailyPresenceRecord) {
        records[record.id] = record
        pendingIDs.insert(record.id)
    }
    func markSynced(id: String) { pendingIDs.remove(id) }
    func pending() -> [DailyPresenceRecord] {
        pendingIDs.compactMap { records[$0] }
    }
}

@Suite("Daily presence service")
struct DailyPresenceServiceTests {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/New_York")!
        return calendar
    }

    @Test func repeatedOpenUpsertsOneLocalDay() async throws {
        let store = MemoryPresenceStore()
        let service = DailyPresenceService(localStore: store, dataClient: nil)
        let first = Date(timeIntervalSince1970: 1_753_528_400)

        _ = try await service.recordOpen(at: first, calendar: calendar)
        let second = try await service.recordOpen(at: first.addingTimeInterval(60), calendar: calendar)

        #expect(await store.load().count == 1)
        #expect(second.firstOpenDate == first)
        #expect(second.mostRecentOpenDate == first.addingTimeInterval(60))
    }

    @Test func localWriteSucceedsWhenRemoteSaveFails() async throws {
        let store = MemoryPresenceStore()
        let failingClient = FailingPresenceDataClient()
        let service = DailyPresenceService(localStore: store, dataClient: failingClient)

        let record = try await service.recordOpen(
            at: Date(timeIntervalSince1970: 1_753_528_400),
            calendar: calendar
        )

        #expect(await store.pending().map(\.id) == [record.id])
    }
}
```

Add a test-only `FailingPresenceDataClient` implementing `DataClientProtocol` whose write methods throw `DataError.networkError(underlying: nil)` and whose fetch returns an empty typed array.

- [ ] **Step 2: Run the focused tests and verify failure**

Run:

```bash
cd SundeeFundee && swift test --filter DailyPresenceServiceTests
```

Expected: compilation fails because the store and service interfaces do not exist.

- [ ] **Step 3: Implement the JSON-backed local actor**

`PresenceLocalStore` stores this envelope through an injected file URL so tests can use a temporary directory:

```swift
private struct PresenceCacheEnvelope: Codable, Sendable {
    var records: [DailyPresenceRecord]
    var pendingIDs: Set<String>
}

public actor PresenceLocalStore: PresenceLocalStoring {
    private let fileURL: URL
    private var envelope: PresenceCacheEnvelope

    public init(fileURL: URL? = nil) {
        let resolvedURL = fileURL ?? FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("SundeeFundee", isDirectory: true)
            .appendingPathComponent("daily-presence.json")
        self.fileURL = resolvedURL
        self.envelope = Self.read(from: resolvedURL)
    }

    public func load() -> [DailyPresenceRecord] { envelope.records }
    public func pending() -> [DailyPresenceRecord] {
        envelope.records.filter { envelope.pendingIDs.contains($0.id) }
    }

    public func save(_ record: DailyPresenceRecord) throws {
        if let index = envelope.records.firstIndex(where: { $0.id == record.id }) {
            envelope.records[index] = record
        } else {
            envelope.records.append(record)
        }
        envelope.pendingIDs.insert(record.id)
        try persist()
    }

    public func markSynced(id: String) throws {
        envelope.pendingIDs.remove(id)
        try persist()
    }
}
```

Implement `read(from:)` with ISO8601 decoding and an empty-envelope fallback for a missing file. Implement `persist()` by creating only the parent `SundeeFundee` directory and atomically writing ISO8601 JSON.

- [ ] **Step 4: Implement the local-day service and best-effort sync**

Use a fixed `DateFormatter` created per call from the supplied calendar:

```swift
private func dayKey(for date: Date, calendar: Calendar) -> String {
    let formatter = DateFormatter()
    formatter.calendar = calendar
    formatter.timeZone = calendar.timeZone
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter.string(from: date)
}
```

`recordOpen` loads the cache, matches the stable identifier, promotes the existing record to `.showedUp` without downgrade, saves locally, calls `syncPending()`, and returns without throwing when remote sync fails. Local file errors still throw.

`promoteToday` first calls the same upsert path, promotes to the requested level, saves locally, then retries sync. `syncPending()` saves each record individually and marks only successful saves as synced:

```swift
public func syncPending() async {
    guard let dataClient else { return }
    guard let records = try? await localStore.pending() else { return }
    for record in records {
        do {
            try await dataClient.save(record, recordType: Self.recordType)
            try await localStore.markSynced(id: record.id)
        } catch {
            continue
        }
    }
}
```

- [ ] **Step 5: Run service and local-store tests**

Run:

```bash
cd SundeeFundee && swift test --filter DailyPresenceServiceTests
```

Expected: all service tests pass, including a new round-trip test using `FileManager.default.temporaryDirectory/appendingPathComponent(UUID().uuidString)`.

- [ ] **Step 6: Commit persistence and service**

```bash
git add SundeeFundee/Sources/SundeeFundeeKit/DataLayer/Engagement/PresenceLocalStore.swift
git commit -m "feat(engagement): cache presence locally"
git add SundeeFundee/Sources/SundeeFundeeKit/DataLayer/Engagement/DailyPresenceService.swift
git commit -m "feat(engagement): sync daily presence"
git add SundeeFundee/Tests/SundeeFundeeKitTests/DataLayerTests/DailyPresenceServiceTests.swift
git commit -m "test(engagement): cover presence persistence"
```

---

### Task 4: Today Engagement View Model

**Files:**
- Create: `SundeeFundee/Sources/SundeeFundeeKit/UI/ViewModels/TodayEngagementViewModel.swift`
- Test: `SundeeFundee/Tests/SundeeFundeeKitTests/ViewModelTests/TodayEngagementViewModelTests.swift`

**Interfaces:**
- Consumes a `DailyPresenceServicing` protocol extracted beside the view model:

```swift
public protocol DailyPresenceServicing: Sendable {
    func recordOpen(at: Date, calendar: Calendar) async throws -> DailyPresenceRecord
    func promoteToday(to: DailyParticipationLevel, status: DailyPresenceStatus?, at: Date, calendar: Calendar) async throws -> DailyPresenceRecord
    func loadSummary(referenceDate: Date, calendar: Calendar) async throws -> ConsistencyMomentumSummary
}
```

- Produces `@Published private(set)` properties `today`, `summary`, `isLoading`, and `message`.
- Produces `load()` and `select(_:)`.

- [ ] **Step 1: Write failing view-model tests**

```swift
import Foundation
import Testing
@testable import SundeeFundeeKit

@MainActor
@Suite("Today engagement view model")
struct TodayEngagementViewModelTests {
    @Test func loadRecordsPresenceWithoutRequiringAStatus() async {
        let service = PresenceServiceSpy()
        let viewModel = TodayEngagementViewModel(
            service: service,
            now: { Date(timeIntervalSince1970: 1_753_528_400) }
        )

        await viewModel.load()

        #expect(viewModel.today?.participationLevel == .showedUp)
        #expect(viewModel.message == nil)
        #expect(await service.recordOpenCallCount == 1)
    }

    @Test func selectingRestingPromotesToAction() async {
        let service = PresenceServiceSpy()
        let viewModel = TodayEngagementViewModel(service: service)

        await viewModel.select(.resting)

        #expect(await service.lastPromotion?.0 == .acted)
        #expect(await service.lastPromotion?.1 == .resting)
    }
}
```

The spy maps `.ready`, `.tired`, and `.sore` to `.checkedIn`; `.resting` and `.trained` are expected to map to `.acted`.

- [ ] **Step 2: Run the focused tests and verify failure**

Run:

```bash
cd SundeeFundee && swift test --filter TodayEngagementViewModelTests
```

Expected: compilation fails because `TodayEngagementViewModel` is undefined.

- [ ] **Step 3: Implement the MainActor view model**

```swift
@MainActor
public final class TodayEngagementViewModel: ObservableObject {
    @Published public private(set) var today: DailyPresenceRecord?
    @Published public private(set) var summary: ConsistencyMomentumSummary?
    @Published public private(set) var isLoading = false
    @Published public private(set) var message: String?

    private let service: any DailyPresenceServicing
    private let calendar: Calendar
    private let now: @Sendable () -> Date

    public func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            today = try await service.recordOpen(at: now(), calendar: calendar)
            summary = try await service.loadSummary(referenceDate: now(), calendar: calendar)
            message = nil
        } catch {
            message = "Your daily momentum could not be updated. Your training plan is still available."
        }
    }

    public func select(_ status: DailyPresenceStatus) async {
        let level: DailyParticipationLevel =
            status == .resting || status == .trained ? .acted : .checkedIn
        do {
            today = try await service.promoteToday(
                to: level,
                status: status,
                at: now(),
                calendar: calendar
            )
            summary = try await service.loadSummary(referenceDate: now(), calendar: calendar)
            message = nil
            HapticFeedback.light()
        } catch {
            message = "That check-in did not save. Please try again."
            HapticFeedback.warning()
        }
    }
}
```

Provide a default initializer using `DailyPresenceService(localStore: PresenceLocalStore(), dataClient: DataClientFactory.shared.client)`.

- [ ] **Step 4: Run the focused tests**

Run:

```bash
cd SundeeFundee && swift test --filter TodayEngagementViewModelTests
```

Expected: all view-model tests pass.

- [ ] **Step 5: Commit the view model**

```bash
git add SundeeFundee/Sources/SundeeFundeeKit/UI/ViewModels/TodayEngagementViewModel.swift
git commit -m "feat(today): add daily engagement view model"
git add SundeeFundee/Tests/SundeeFundeeKitTests/ViewModelTests/TodayEngagementViewModelTests.swift
git commit -m "test(today): cover daily engagement view model"
```

---

### Task 5: Today Presence and Momentum UI

**Files:**
- Create: `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Dashboard/TodayPresenceCard.swift`
- Create: `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Progress/ConsistencyMomentumView.swift`
- Modify: `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Dashboard/DashboardView.swift`
- Test: `SundeeFundee/Tests/SundeeFundeeKitTests/UI/TodayPresencePresentationTests.swift`

**Interfaces:**
- `TodayPresenceCard` consumes `DailyPresenceRecord?`, `ConsistencyMomentumSummary?`, and `(DailyPresenceStatus) -> Void`.
- `ConsistencyMomentumView` consumes `ConsistencyMomentumSummary`.
- `DashboardView` owns `@StateObject private var engagementViewModel = TodayEngagementViewModel()`.

- [ ] **Step 1: Write failing presentation-copy tests**

Extract pure labels into `DailyPresenceStatus`:

```swift
import Testing
@testable import SundeeFundeeKit

@Suite("Today presence presentation")
struct TodayPresencePresentationTests {
    @Test func statusLabelsAreShortAndSupportive() {
        #expect(DailyPresenceStatus.ready.displayName == "Ready")
        #expect(DailyPresenceStatus.resting.displayName == "Resting")
        #expect(DailyPresenceStatus.trained.systemImage == "checkmark.circle")
    }

    @Test func actionCopyDoesNotPunishMissedDays() {
        let forbidden = ["lost", "failed", "reset", "broke"]
        #expect(forbidden.allSatisfy { !ConsistencyMomentumCopy.welcomeBack.lowercased().contains($0) })
    }
}
```

- [ ] **Step 2: Run the focused tests and verify failure**

Run:

```bash
cd SundeeFundee && swift test --filter TodayPresencePresentationTests
```

Expected: compilation fails because presentation properties are missing.

- [ ] **Step 3: Add display properties without importing SwiftUI into the domain**

```swift
public extension DailyPresenceStatus {
    var displayName: String {
        switch self {
        case .ready: "Ready"
        case .tired: "Tired"
        case .sore: "Sore"
        case .resting: "Resting"
        case .trained: "Trained"
        }
    }

    var systemImage: String {
        switch self {
        case .ready: "bolt"
        case .tired: "moon.zzz"
        case .sore: "figure.cooldown"
        case .resting: "leaf"
        case .trained: "checkmark.circle"
        }
    }
}

public enum ConsistencyMomentumCopy {
    public static let welcomeBack = "Welcome back"
}
```

- [ ] **Step 4: Build the presence card**

Use `ArtDecoCard`, `AppTheme.Spacing`, `AppTheme.Text`, and `AppTheme.Accent` only. Render the five statuses as horizontally scrollable buttons with semantic `.body` and `.title3` fonts. The selected status uses `AppTheme.Accent.orange`; unselected controls use existing card and secondary-text tokens.

Accessibility requirements:

```swift
.accessibilityLabel("\(status.displayName) check-in")
.accessibilityValue(isSelected ? "Selected" : "Not selected")
.accessibilityHint("Updates today's private status")
```

Show the summary headline and “Opening Today already counted as showing up” so no interaction appears mandatory.

- [ ] **Step 5: Build the four-week momentum detail**

Render four labeled weekly bars whose heights are based on `daysPresent / 7.0`, with separate text totals for check-ins and action days. Do not color-code low weeks as errors. Use `AppTheme.Accent.gold`, `AppTheme.Background.card`, and `AppTheme.Text.secondary`.

- [ ] **Step 6: Integrate the card into Today**

Add the engagement state object and place `TodayPresenceCard` after `welcomeHeader` and before the training decision. Update the existing `.task`:

```swift
.task {
    async let engagementLoad: Void = engagementViewModel.load()
    await viewModel.loadData(cyclePhaseCache: cyclePhaseCache)
    await refreshReadiness()
    _ = await engagementLoad
}
```

Status buttons call:

```swift
Task { await engagementViewModel.select(status) }
```

Present `ConsistencyMomentumView` from a “View 4-week momentum” button. Display `engagementViewModel.message` inside the card as calm inline copy rather than using the dashboard's blocking error alert.

- [ ] **Step 7: Run tests and build**

Run:

```bash
cd SundeeFundee && swift test --filter TodayPresencePresentationTests
cd SundeeFundeeApp && xcodebuild -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

Expected: tests pass and app build ends with `** BUILD SUCCEEDED **`.

- [ ] **Step 8: Commit the Today UI**

```bash
git add SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Engagement/DailyPresenceRecord.swift
git commit -m "feat(engagement): add presence display metadata"
git add SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Dashboard/TodayPresenceCard.swift
git commit -m "feat(today): add presence card"
git add SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Progress/ConsistencyMomentumView.swift
git commit -m "feat(progress): add consistency momentum view"
git add SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Dashboard/DashboardView.swift
git commit -m "feat(today): surface daily presence"
git add SundeeFundee/Tests/SundeeFundeeKitTests/UI/TodayPresencePresentationTests.swift
git commit -m "test(today): cover presence presentation"
```

---

### Task 6: Promote Existing Check-Ins and Workouts to Actions

**Files:**
- Modify: `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Dashboard/DashboardView.swift`
- Modify: `SundeeFundee/Sources/SundeeFundeeKit/UI/ViewModels/QuickCheckInViewModel.swift`
- Modify: `SundeeFundee/Sources/SundeeFundeeKit/UI/ViewModels/ActiveWorkoutSessionViewModel.swift`
- Test: `SundeeFundee/Tests/SundeeFundeeKitTests/ViewModelTests/TodayEngagementViewModelTests.swift`

**Interfaces:**
- Add notification names:

```swift
public extension Notification.Name {
    static let dailyCheckInCompleted = Notification.Name("dailyCheckInCompleted")
    static let intentionalRecoveryCompleted = Notification.Name("intentionalRecoveryCompleted")
}
```

- `DashboardView` promotes on `.workoutCompleted`, `.dailyCheckInCompleted`, and `.intentionalRecoveryCompleted`.

- [ ] **Step 1: Add failing mapping tests**

Add:

```swift
@Test func workoutCompletionPromotesTrainedAction() async {
    let service = PresenceServiceSpy()
    let viewModel = TodayEngagementViewModel(service: service)

    await viewModel.recordAction(.trained)

    #expect(await service.lastPromotion?.0 == .acted)
    #expect(await service.lastPromotion?.1 == .trained)
}

@Test func richCheckInDoesNotPretendWorkoutWasCompleted() async {
    let service = PresenceServiceSpy()
    let viewModel = TodayEngagementViewModel(service: service)

    await viewModel.recordCheckIn()

    #expect(await service.lastPromotion?.0 == .checkedIn)
    #expect(await service.lastPromotion?.1 == nil)
}
```

- [ ] **Step 2: Run the tests and verify failure**

Run:

```bash
cd SundeeFundee && swift test --filter TodayEngagementViewModelTests
```

Expected: compilation fails because `recordAction` and `recordCheckIn` are missing.

- [ ] **Step 3: Add explicit promotion methods**

Implement:

```swift
public func recordCheckIn() async {
    await promote(level: .checkedIn, status: nil)
}

public func recordAction(_ status: DailyPresenceStatus?) async {
    await promote(level: .acted, status: status)
}
```

Move the common persistence and refresh code from `select(_:)` into the private `promote(level:status:)` method.

- [ ] **Step 4: Emit and observe completion events**

After a rich quick check-in saves successfully:

```swift
NotificationCenter.default.post(name: .dailyCheckInCompleted, object: nil)
```

Keep the existing `.workoutCompleted` event as the workout source of truth. In `DashboardView`, extend the existing observer:

```swift
.onReceive(NotificationCenter.default.publisher(for: .workoutCompleted)) { _ in
    Task {
        await engagementViewModel.recordAction(.trained)
        await viewModel.loadData(cyclePhaseCache: cyclePhaseCache)
        await refreshReadiness()
    }
}
.onReceive(NotificationCenter.default.publisher(for: .dailyCheckInCompleted)) { _ in
    Task { await engagementViewModel.recordCheckIn() }
}
.onReceive(NotificationCenter.default.publisher(for: .intentionalRecoveryCompleted)) { _ in
    Task { await engagementViewModel.recordAction(.resting) }
}
```

Do not infer intentional recovery from merely viewing a recommendation. Only emit `.intentionalRecoveryCompleted` from an actual completed recovery workout/session path. If no such completion path exists, retain the observer but do not fabricate an event.

- [ ] **Step 5: Run focused and existing completion tests**

Run:

```bash
cd SundeeFundee && swift test --filter TodayEngagementViewModelTests
cd SundeeFundee && swift test --filter QuickCheckInViewModelTests
cd SundeeFundee && swift test --filter ActiveWorkoutSessionViewModelTests
```

Expected: all three suites pass.

- [ ] **Step 6: Commit action reconciliation**

```bash
git add SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Dashboard/DashboardView.swift
git commit -m "feat(today): observe engagement actions"
git add SundeeFundee/Sources/SundeeFundeeKit/UI/ViewModels/QuickCheckInViewModel.swift
git commit -m "feat(checkin): publish daily completion"
git add SundeeFundee/Sources/SundeeFundeeKit/UI/ViewModels/ActiveWorkoutSessionViewModel.swift
git commit -m "feat(workout): publish recovery completion"
git add SundeeFundee/Tests/SundeeFundeeKitTests/ViewModelTests/TodayEngagementViewModelTests.swift
git commit -m "test(engagement): cover action promotion"
```

---

### Task 7: Supportive Solo Achievements

**Files:**
- Create: `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Engagement/ConsistencyAchievementService.swift`
- Modify: `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Progress/ConsistencyMomentumView.swift`
- Test: `SundeeFundee/Tests/SundeeFundeeKitTests/DomainTests/ConsistencyAchievementServiceTests.swift`

**Interfaces:**
- Produces:

```swift
public enum ConsistencyAchievement: String, Codable, Sendable, Equatable {
    case firstConsistentWeek
    case welcomeBack
    case plannedWorkoutCompleted
    case recoveryChoice
}

public func newlyEarned(
    records: [DailyPresenceRecord],
    previouslyEarned: Set<ConsistencyAchievement>,
    referenceDate: Date,
    calendar: Calendar
) -> Set<ConsistencyAchievement>
```

- Phase 1 deliberately excludes buddy/group achievements.

- [ ] **Step 1: Write failing achievement tests**

```swift
import Foundation
import Testing
@testable import SundeeFundeeKit

@Suite("Consistency achievements")
struct ConsistencyAchievementServiceTests {
    @Test func threePresenceDaysEarnFirstConsistentWeek() {
        let records = makePresenceRecords(
            days: ["2026-07-20", "2026-07-22", "2026-07-24"],
            level: .showedUp
        )
        let earned = ConsistencyAchievementService().newlyEarned(
            records: records,
            previouslyEarned: [],
            referenceDate: makeDate("2026-07-26"),
            calendar: makeCalendar()
        )
        #expect(earned == [.firstConsistentWeek])
    }

    @Test func priorAchievementIsNotReAwarded() {
        let earned = ConsistencyAchievementService().newlyEarned(
            records: makePresenceRecords(days: ["2026-07-20", "2026-07-22", "2026-07-24"], level: .showedUp),
            previouslyEarned: [.firstConsistentWeek],
            referenceDate: makeDate("2026-07-26"),
            calendar: makeCalendar()
        )
        #expect(earned.isEmpty)
    }
}
```

Use local factory helpers in the test file so it is independently readable.

- [ ] **Step 2: Run the focused tests and verify failure**

Run:

```bash
cd SundeeFundee && swift test --filter ConsistencyAchievementServiceTests
```

Expected: compilation fails because achievement types are absent.

- [ ] **Step 3: Implement deterministic achievement rules**

Rules:

- `firstConsistentWeek`: at least three distinct presence days in one calendar week.
- `welcomeBack`: an acted or checked-in day follows a gap of at least seven local days; never award for the user's first record.
- `plannedWorkoutCompleted`: a record has `.acted` and `.trained`.
- `recoveryChoice`: a record has `.acted` and `.resting`.
- Subtract `previouslyEarned` before returning.

Keep achievement persistence as a JSON set beside the presence cache. Do not create a CloudKit record type in Phase 1; achievements can be re-derived from presence history after migration.

- [ ] **Step 4: Present achievements without blocking Today**

Add an “Achievements” section to `ConsistencyMomentumView`. Newly earned achievements appear with concise copy and an `AppTheme.Accent.gold` symbol. Trigger `HapticFeedback.success()` only when a newly earned achievement first appears during the current process, not on every view load.

- [ ] **Step 5: Run tests and build**

Run:

```bash
cd SundeeFundee && swift test --filter ConsistencyAchievementServiceTests
cd SundeeFundeeApp && xcodebuild -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

Expected: tests pass and the app builds.

- [ ] **Step 6: Commit achievements**

```bash
git add SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Engagement/ConsistencyAchievementService.swift
git commit -m "feat(engagement): derive consistency achievements"
git add SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Progress/ConsistencyMomentumView.swift
git commit -m "feat(progress): show consistency achievements"
git add SundeeFundee/Tests/SundeeFundeeKitTests/DomainTests/ConsistencyAchievementServiceTests.swift
git commit -m "test(engagement): cover consistency achievements"
```

---

### Task 8: Optional Daily-Plan Reminder

**Files:**
- Modify: `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Habits/WeeklyTrainingPlan.swift`
- Modify: `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Habits/ReminderService.swift`
- Modify: `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Settings/WorkoutRemindersSettingsView.swift`
- Modify: `SundeeFundee/Sources/SundeeFundeeKit/UI/App/WorkoutReminderNotificationDelegate.swift`
- Test: `SundeeFundee/Tests/SundeeFundeeKitTests/DomainTests/ReminderServiceTests.swift`

**Interfaces:**
- Extend `WorkoutReminderSettings` with backward-compatible:

```swift
public var dailyPlanEnabled: Bool
public var dailyPlanHour: Int
public var dailyPlanMinute: Int
```

- Add `ReminderType.dailyPlanReminder`.
- Stable request identifier: `com.sundeefundee.daily-plan`.
- Deep link opens Today without forcing a modal.

- [ ] **Step 1: Write failing default and redaction tests**

```swift
@Test func oldSettingsDefaultDailyPlanReminderOff() throws {
    let oldJSON = """
    {"id":"workout-reminders","enabled":false,"hour":8,"minute":0,"weekdays":[]}
    """
    let settings = try JSONDecoder().decode(WorkoutReminderSettings.self, from: Data(oldJSON.utf8))
    #expect(settings.dailyPlanEnabled == false)
    #expect(settings.dailyPlanHour == 8)
    #expect(settings.dailyPlanMinute == 0)
}

@Test func dailyPlanCopyContainsNoSensitiveTerms() {
    let copy = ReminderService.dailyPlanNotificationCopy
    let forbidden = ["cycle", "period", "pain", "HRV", "readiness score", "HealthKit"]
    #expect(forbidden.allSatisfy { !copy.body.localizedCaseInsensitiveContains($0) })
}
```

- [ ] **Step 2: Run the reminder tests and verify failure**

Run:

```bash
cd SundeeFundee && swift test --filter ReminderServiceTests
```

Expected: compilation fails because daily-plan settings and copy are missing.

- [ ] **Step 3: Add backward-compatible settings decoding**

Retain current initializer behavior and add custom decoding with:

```swift
dailyPlanEnabled = try container.decodeIfPresent(Bool.self, forKey: .dailyPlanEnabled) ?? false
dailyPlanHour = try container.decodeIfPresent(Int.self, forKey: .dailyPlanHour) ?? 8
dailyPlanMinute = try container.decodeIfPresent(Int.self, forKey: .dailyPlanMinute) ?? 0
```

Validate hour to `0...23` and minute to `0...59` in the public initializer.

- [ ] **Step 4: Schedule one privacy-safe daily request**

When enabled, add a repeating daily calendar trigger using:

```swift
var components = DateComponents()
components.hour = settings.dailyPlanHour
components.minute = settings.dailyPlanMinute
let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
```

Use title `“Your day is ready”` and body `“Open Sundee Fundee for today’s plan or a quick check-in.”` Add only a route value identifying the Today tab. Do not add readiness or health content to `userInfo`.

- [ ] **Step 5: Add Settings controls**

Add a “Daily plan” toggle and time picker to `WorkoutRemindersSettingsView`. Request notification authorization only when the user enables it. If authorization is denied, revert the toggle and show:

`“Notifications are off. You can still use your daily plan, or enable reminders in Settings.”`

Use the existing error-state and save/reconcile patterns in the view.

- [ ] **Step 6: Route notification taps to Today**

Extend the notification delegate's route handling so `com.sundeefundee.daily-plan` selects Today without presenting Quick Check-In. Add a focused deep-link parsing test beside existing `AppIntentsTests` or notification tests.

- [ ] **Step 7: Run tests and build**

Run:

```bash
cd SundeeFundee && swift test --filter ReminderServiceTests
cd SundeeFundee && swift test --filter AppIntentsTests
cd SundeeFundeeApp && xcodebuild -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

Expected: tests pass and app build succeeds.

- [ ] **Step 8: Commit the daily reminder**

```bash
git add SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Habits/WeeklyTrainingPlan.swift
git commit -m "feat(reminders): add daily plan settings"
git add SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Habits/ReminderService.swift
git commit -m "feat(reminders): schedule daily plan reminder"
git add SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Settings/WorkoutRemindersSettingsView.swift
git commit -m "feat(settings): configure daily plan reminder"
git add SundeeFundee/Sources/SundeeFundeeKit/UI/App/WorkoutReminderNotificationDelegate.swift
git commit -m "feat(reminders): route daily plan notification"
git add SundeeFundee/Tests/SundeeFundeeKitTests/DomainTests/ReminderServiceTests.swift
git commit -m "test(reminders): cover daily plan reminder"
```

---

### Task 9: CloudKit Schema, Privacy Gate, and Release Verification

**Files:**
- Modify: `SundeeFundeeApp/cloudkit-schema.json`
- Create: `docs/release/v2-daily-presence-momentum-gate.md`
- Test: `SundeeFundee/Tests/SundeeFundeeKitTests/DataLayerTests/DailyPresencePrivacyTests.swift`

**Interfaces:**
- Adds CloudKit record type `DailyPresenceRecord`.
- Requires a queryable record-name index in Development and Production before release.
- Verifies that Phase 1 has no shared-zone or sensitive-health fields.

- [ ] **Step 1: Write the privacy schema test**

```swift
import Foundation
import Testing
@testable import SundeeFundeeKit

@Suite("Daily presence privacy")
struct DailyPresencePrivacyTests {
    @Test func encodedRecordContainsOnlyApprovedFields() throws {
        let record = DailyPresenceRecord(
            dayKey: "2026-07-26",
            timeZoneIdentifier: "America/New_York",
            firstOpenDate: Date(timeIntervalSince1970: 1_753_528_400),
            participationLevel: .checkedIn,
            status: .tired
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let object = try #require(
            JSONSerialization.jsonObject(with: encoder.encode(record)) as? [String: Any]
        )

        let approved = Set([
            "id", "dayKey", "timeZoneIdentifier", "firstOpenDate",
            "mostRecentOpenDate", "participationLevelRaw", "statusRaw",
            "dateCreated", "dateUpdated", "modelVersion"
        ])
        #expect(Set(object.keys) == approved)
        #expect(object.keys.allSatisfy { key in
            !["cycle", "pain", "health", "hrv", "readiness"].contains { term in
                key.localizedCaseInsensitiveContains(term)
            }
        })
    }
}
```

- [ ] **Step 2: Run the privacy test**

Run:

```bash
cd SundeeFundee && swift test --filter DailyPresencePrivacyTests
```

Expected: PASS.

- [ ] **Step 3: Update and validate the CloudKit schema**

Add `DailyPresenceRecord` fields matching the encoded record exactly. Store dates as strings, not CloudKit timestamps. Add the queryable record-name index used by upsert/fetch paths.

Run the project-local validator:

```bash
sed -n '1,240p' .Codex/skills/cloudkit-validate/SKILL.md
```

Then follow that skill's validation command against `DailyPresenceRecord.swift` and `SundeeFundeeApp/cloudkit-schema.json`. Do not deploy the schema or submit the app unless separately authorized.

- [ ] **Step 4: Write the manual release gate**

Document these checks in `docs/release/v2-daily-presence-momentum-gate.md`:

- first Today open creates one presence;
- repeated foreground/open on the same local day does not duplicate it;
- a time-zone boundary produces the expected new local-day record;
- Ready/Tired/Sore remain check-ins;
- Resting/Trained are intentional actions;
- workout completion promotes Trained;
- rich check-in promotes Checked In without claiming a workout;
- offline open and selection persist after relaunch;
- CloudKit reconnect clears pending records without duplication;
- missed days show “Welcome back” and preserve prior weeks;
- large Dynamic Type and VoiceOver can operate every status;
- notification denial does not block Today;
- daily-plan notification contains no sensitive preview;
- light and dark mode use only `AppTheme` tokens.

- [ ] **Step 5: Run the complete verification set**

Run:

```bash
cd SundeeFundee && swift test
swiftlint --config .swiftlint.yml
cd SundeeFundeeApp && xcodebuild -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
git diff --check
```

Expected: package tests pass, lint exits successfully, app build succeeds, and `git diff --check` prints nothing.

- [ ] **Step 6: Commit the release gate and schema**

```bash
git add SundeeFundeeApp/cloudkit-schema.json
git commit -m "chore(cloudkit): add daily presence schema"
git add SundeeFundee/Tests/SundeeFundeeKitTests/DataLayerTests/DailyPresencePrivacyTests.swift
git commit -m "test(engagement): guard presence privacy"
git add docs/release/v2-daily-presence-momentum-gate.md
git commit -m "docs(engagement): add presence release gate"
```

## Phase 1 Completion Definition

Phase 1 is complete only when:

- all nine tasks are committed independently;
- the full Swift package test suite passes;
- the iPhone 17 Pro simulator build succeeds;
- the CloudKit model validates against project schema rules;
- the manual gate is completed on at least one iPhone simulator;
- offline writes survive relaunch and reconcile without duplicates;
- no raw health, cycle, pain, or readiness fields exist in `DailyPresenceRecord`;
- no App Store upload or submission has occurred.
