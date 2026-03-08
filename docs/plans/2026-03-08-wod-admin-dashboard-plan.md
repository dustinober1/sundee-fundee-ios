# WOD Admin Dashboard Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a web dashboard for coaches to author and schedule daily workouts, plus update the iOS app to support template-aware workout display and execution.

**Architecture:** Next.js static site on Vercel writes WODs to CloudKit Public DB via CloudKit Web Services. iOS app reads from the same DB with updated filtering (publishDate, status). Two authoring modes: client-side natural language parser and AI generation via Cloudflare AI Gateway → Gemini.

**Tech Stack:** Next.js 14 (App Router), CloudKit JS, Sign in with Apple (web), Cloudflare AI Gateway, Gemini, Swift 6, SwiftUI

---

## Phase 1: iOS Model & Repository Updates

### Task 1: Add `templateType` to WOD model

**Files:**
- Modify: `SundeeFundee/Models/WOD.swift`
- Modify: `SundeeFundee/Packages/SundeeFundeeShared/Sources/SundeeFundeeShared/Models/WOD.swift`
- Test: `SundeeFundeTests/WODTests.swift`

**Step 1: Write failing tests for templateType**

Add to `SundeeFundeTests/WODTests.swift`:

```swift
func testWODTemplateTypeDefaultsToStrength() {
    let wod = WOD(id: "wod-1", date: "2026-03-08", title: "Test", description: "Test", exercises: [])
    XCTAssertEqual(wod.templateType, "strength")
}

func testWODTemplateTypeDecodesFromJSON() throws {
    let json = """
    {
        "id": "wod-1",
        "date": "2026-03-08",
        "title": "AMRAP Test",
        "description": "Test",
        "templateType": "amrap",
        "exercises": []
    }
    """.data(using: .utf8)!
    let wod = try JSONDecoder().decode(WOD.self, from: json)
    XCTAssertEqual(wod.templateType, "amrap")
}

func testWODTemplateTypeMissingDefaultsToStrength() throws {
    let json = """
    {
        "id": "wod-1",
        "date": "2026-03-08",
        "title": "Test",
        "description": "Test",
        "exercises": []
    }
    """.data(using: .utf8)!
    let wod = try JSONDecoder().decode(WOD.self, from: json)
    XCTAssertEqual(wod.templateType, "strength")
}
```

**Step 2: Run tests to verify they fail**

```bash
xcodebuild test \
  -project SundeeFundee.xcodeproj \
  -scheme SundeeFundee \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:SundeeFundeTests/WODTests
```

Expected: FAIL — `templateType` property does not exist.

**Step 3: Add templateType to WOD model**

In `SundeeFundee/Models/WOD.swift`, add the property with a default:

```swift
struct WOD: Codable, Identifiable, Sendable, Hashable {
    let id: String
    let date: String
    let title: String
    let description: String
    let templateType: String
    let exercises: [ProgramExercise]

    // ... existing Equatable/Hashable ...

    init(id: String, date: String, title: String, description: String, templateType: String = "strength", exercises: [ProgramExercise]) {
        self.id = id
        self.date = date
        self.title = title
        self.description = description
        self.templateType = templateType
        self.exercises = exercises
    }

    init(record: CKRecord) throws {
        guard let id = record["id"] as? String,
              let date = record["date"] as? String,
              let title = record["title"] as? String,
              let description = record["description"] as? String else {
            throw WODDecodingError.missingFields
        }
        self.id = id
        self.date = date
        self.title = title
        self.description = description
        self.templateType = (record["templateType"] as? String) ?? "strength"

        if let exercisesJSON = record["exercisesJSON"] as? String,
           let data = exercisesJSON.data(using: .utf8),
           let decoded = try? JSONDecoder().decode([ProgramExercise].self, from: data) {
            self.exercises = decoded
        } else {
            self.exercises = []
        }
    }

    // Support decoding from JSON without templateType (backward compat)
    enum CodingKeys: String, CodingKey {
        case id, date, title, description, templateType, exercises
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        date = try container.decode(String.self, forKey: .date)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decode(String.self, forKey: .description)
        templateType = try container.decodeIfPresent(String.self, forKey: .templateType) ?? "strength"
        exercises = try container.decode([ProgramExercise].self, forKey: .exercises)
    }
}
```

Mirror these changes in the shared package `WOD.swift`.

**Step 4: Fix any test call sites that need updating**

Search all test files for `WOD(id:` and add `templateType` parameter where needed, or rely on the default.

**Step 5: Run tests to verify they pass**

```bash
xcodebuild test \
  -project SundeeFundee.xcodeproj \
  -scheme SundeeFundee \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:SundeeFundeTests/WODTests
```

Expected: PASS

**Step 6: Commit**

```bash
git add -A && git commit -m "feat(wod): add templateType field with backward-compatible default"
```

---

### Task 2: Add `publishDate` and `status` fields to WOD model

**Files:**
- Modify: `SundeeFundee/Models/WOD.swift`
- Test: `SundeeFundeTests/WODTests.swift`

**Step 1: Write failing tests**

```swift
func testWODPublishDateDefaultsToDate() throws {
    let json = """
    {"id":"wod-1","date":"2026-03-08","title":"T","description":"D","exercises":[]}
    """.data(using: .utf8)!
    let wod = try JSONDecoder().decode(WOD.self, from: json)
    XCTAssertEqual(wod.publishDate, "2026-03-08")
}

func testWODPublishDateDecodesExplicitValue() throws {
    let json = """
    {"id":"wod-1","date":"2026-03-08","publishDate":"2026-03-07","title":"T","description":"D","exercises":[]}
    """.data(using: .utf8)!
    let wod = try JSONDecoder().decode(WOD.self, from: json)
    XCTAssertEqual(wod.publishDate, "2026-03-07")
}

func testWODStatusDefaultsToPublished() throws {
    let json = """
    {"id":"wod-1","date":"2026-03-08","title":"T","description":"D","exercises":[]}
    """.data(using: .utf8)!
    let wod = try JSONDecoder().decode(WOD.self, from: json)
    XCTAssertEqual(wod.status, "published")
}
```

**Step 2: Run tests to verify failure**

**Step 3: Add fields to WOD**

Add `publishDate: String` and `status: String` to the struct. In `init(from decoder:)`:

```swift
publishDate = try container.decodeIfPresent(String.self, forKey: .publishDate) ?? (try container.decode(String.self, forKey: .date))
status = try container.decodeIfPresent(String.self, forKey: .status) ?? "published"
```

In `init(record:)`:

```swift
self.publishDate = (record["publishDate"] as? String) ?? date
self.status = (record["status"] as? String) ?? "published"
```

In memberwise `init`:

```swift
init(id: String, date: String, title: String, description: String, templateType: String = "strength", publishDate: String? = nil, status: String = "published", exercises: [ProgramExercise]) {
    // ...
    self.publishDate = publishDate ?? date
    self.status = status
    // ...
}
```

**Step 4: Update CodingKeys, fix call sites, run tests**

**Step 5: Commit**

```bash
git commit -m "feat(wod): add publishDate and status fields for scheduled publishing"
```

---

### Task 3: Filter WODs by publishDate and status in repository

**Files:**
- Modify: `SundeeFundee/Repositories/WODRepository.swift`
- Modify: `SundeeFundee/Features/Dashboard/DashboardViewModel.swift`
- Test: `SundeeFundeTests/WODRepositoryTests.swift`

**Step 1: Write failing tests**

```swift
func testCloudKitWODRepositoryFiltersDrafts() async throws {
    let draftWOD = WOD(id: "draft-1", date: "2026-03-08", title: "Draft", description: "D", status: "draft", exercises: [])
    let publishedWOD = WOD(id: "pub-1", date: "2026-03-08", title: "Published", description: "D", exercises: [])
    // Create repo with mock fetcher returning both
    // Assert only published WOD is returned
}

func testCloudKitWODRepositoryFiltersFuturePublishDate() async throws {
    let futureWOD = WOD(id: "future-1", date: "2026-03-10", title: "Future", description: "D", publishDate: "2026-03-10", exercises: [])
    let todayWOD = WOD(id: "today-1", date: "2026-03-08", title: "Today", description: "D", publishDate: "2026-03-08", exercises: [])
    // Assert only todayWOD is returned when "today" is 2026-03-08
}
```

**Step 2: Run tests to verify failure**

**Step 3: Add client-side filtering to repository**

CloudKit queries don't support complex string-date comparisons well. Apply filtering client-side after fetch:

In `CloudKitWODRepository.fetchWODs()`:

```swift
func fetchWODs() async throws -> [WOD] {
    do {
        let allWODs = try await cloudFetcher()
        return Self.filterPublished(allWODs)
    } catch {
        let fallbackWODs = try await fallback.fetchWODs()
        return Self.filterPublished(fallbackWODs)
    }
}

static func filterPublished(_ wods: [WOD], now: Date = Date()) -> [WOD] {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    let todayString = formatter.string(from: now)

    return wods.filter { wod in
        wod.status == "published" && wod.publishDate <= todayString
    }
}
```

Make `filterPublished` a static method so it's testable without mocking CloudKit.

**Step 4: Run tests**

**Step 5: Commit**

```bash
git commit -m "feat(wod): filter WODs by publishDate and status"
```

---

### Task 4: Add WODTemplateType enum for display logic

**Files:**
- Create: `SundeeFundee/Domain/WODTemplateType.swift`
- Test: `SundeeFundeTests/WODTemplateTypeTests.swift`

**Step 1: Write failing tests**

```swift
import XCTest
@testable import SundeeFundee

final class WODTemplateTypeTests: XCTestCase {
    func testInitFromRawValue() {
        XCTAssertEqual(WODTemplateType(rawValue: "strength"), .strength)
        XCTAssertEqual(WODTemplateType(rawValue: "amrap"), .amrap)
        XCTAssertEqual(WODTemplateType(rawValue: "emom"), .emom)
        XCTAssertEqual(WODTemplateType(rawValue: "forTime"), .forTime)
        XCTAssertEqual(WODTemplateType(rawValue: "circuit"), .circuit)
    }

    func testUnknownRawValueDefaultsToStrength() {
        XCTAssertEqual(WODTemplateType.from("garbage"), .strength)
    }

    func testDisplayName() {
        XCTAssertEqual(WODTemplateType.amrap.displayName, "AMRAP")
        XCTAssertEqual(WODTemplateType.emom.displayName, "EMOM")
        XCTAssertEqual(WODTemplateType.forTime.displayName, "For Time")
        XCTAssertEqual(WODTemplateType.circuit.displayName, "Circuit")
        XCTAssertEqual(WODTemplateType.strength.displayName, "Strength")
    }

    func testRequiresTimer() {
        XCTAssertTrue(WODTemplateType.amrap.requiresTimer)
        XCTAssertTrue(WODTemplateType.emom.requiresTimer)
        XCTAssertTrue(WODTemplateType.forTime.requiresTimer)
        XCTAssertFalse(WODTemplateType.strength.requiresTimer)
        XCTAssertFalse(WODTemplateType.circuit.requiresTimer)
    }
}
```

**Step 2: Run tests, verify failure**

**Step 3: Implement**

```swift
enum WODTemplateType: String, Sendable {
    case strength
    case amrap
    case emom
    case forTime
    case circuit

    static func from(_ rawValue: String) -> WODTemplateType {
        WODTemplateType(rawValue: rawValue) ?? .strength
    }

    var displayName: String {
        switch self {
        case .strength: "Strength"
        case .amrap: "AMRAP"
        case .emom: "EMOM"
        case .forTime: "For Time"
        case .circuit: "Circuit"
        }
    }

    var requiresTimer: Bool {
        switch self {
        case .amrap, .emom, .forTime: true
        case .strength, .circuit: false
        }
    }
}
```

**Step 4: Run tests, verify pass**

**Step 5: Add to project.yml, run `xcodegen generate`**

**Step 6: Commit**

```bash
git commit -m "feat(wod): add WODTemplateType domain enum"
```

---

## Phase 2: iOS Template-Aware Execution Views

### Task 5: Add AMRAP timer view component

**Files:**
- Create: `SundeeFundee/Features/Workouts/AMRAPTimerView.swift`
- Test: `SundeeFundeTests/AMRAPTimerViewTests.swift`

**Step 1: Write tests for static helpers**

```swift
final class AMRAPTimerViewTests: XCTestCase {
    func testFormatTimeRemainingMinutesAndSeconds() {
        XCTAssertEqual(AMRAPTimerView.formatTimeRemaining(125), "2:05")
    }

    func testFormatTimeRemainingZero() {
        XCTAssertEqual(AMRAPTimerView.formatTimeRemaining(0), "0:00")
    }

    func testRoundDisplayText() {
        XCTAssertEqual(AMRAPTimerView.roundDisplayText(round: 3, reps: 7), "Round 3 + 7 reps")
    }

    func testRoundDisplayTextZeroReps() {
        XCTAssertEqual(AMRAPTimerView.roundDisplayText(round: 5, reps: 0), "Round 5")
    }
}
```

**Step 2: Implement AMRAPTimerView**

A SwiftUI view with:
- Countdown timer from `timeCap` minutes
- Round counter (tap to increment)
- Rep counter within current round
- Exercise list reference
- Audio alert at 3-2-1 and time's up

Static helpers for formatting (testable without view hosting).

**Step 3: Run tests, commit**

```bash
git commit -m "feat(wod): add AMRAP timer view"
```

---

### Task 6: Add EMOM timer view component

**Files:**
- Create: `SundeeFundee/Features/Workouts/EMOMTimerView.swift`
- Test: `SundeeFundeTests/EMOMTimerViewTests.swift`

**Step 1: Write tests for static helpers**

```swift
final class EMOMTimerViewTests: XCTestCase {
    func testCurrentMinuteCalculation() {
        // 65 seconds elapsed, 1-min intervals -> minute 2
        XCTAssertEqual(EMOMTimerView.currentMinute(elapsedSeconds: 65, intervalSeconds: 60), 2)
    }

    func testTimeWithinInterval() {
        // 65 seconds elapsed, 1-min intervals -> 5 seconds into current interval
        XCTAssertEqual(EMOMTimerView.timeWithinInterval(elapsedSeconds: 65, intervalSeconds: 60), 5)
    }

    func testExerciseIndexForMinute() {
        // 3 exercises, minute 5 -> exercise index 1 (5 % 3 = 2, but 0-indexed)
        XCTAssertEqual(EMOMTimerView.exerciseIndex(minute: 4, exerciseCount: 3), 1)
    }
}
```

**Step 2: Implement EMOMTimerView**

- Running clock counting up
- Current minute indicator
- Highlights which exercise to do this minute (alternating for odd/even patterns)
- Audio beep at each minute mark
- Total duration countdown

**Step 3: Run tests, commit**

```bash
git commit -m "feat(wod): add EMOM timer view"
```

---

### Task 7: Add ForTime timer view component

**Files:**
- Create: `SundeeFundee/Features/Workouts/ForTimeTimerView.swift`
- Test: `SundeeFundeTests/ForTimeTimerViewTests.swift`

**Step 1: Write tests**

```swift
final class ForTimeTimerViewTests: XCTestCase {
    func testFormatElapsedTime() {
        XCTAssertEqual(ForTimeTimerView.formatElapsed(185), "3:05")
    }

    func testIsOverTimeCap() {
        XCTAssertTrue(ForTimeTimerView.isOverTimeCap(elapsed: 610, capMinutes: 10))
        XCTAssertFalse(ForTimeTimerView.isOverTimeCap(elapsed: 590, capMinutes: 10))
    }

    func testIsOverTimeCapNilCap() {
        XCTAssertFalse(ForTimeTimerView.isOverTimeCap(elapsed: 9999, capMinutes: nil))
    }
}
```

**Step 2: Implement ForTimeTimerView**

- Stopwatch counting up
- Exercise checklist (tap to mark done)
- Optional time cap warning
- "Done" button to record final time

**Step 3: Run tests, commit**

```bash
git commit -m "feat(wod): add For Time timer view"
```

---

### Task 8: Add Circuit group view component

**Files:**
- Create: `SundeeFundee/Features/Workouts/CircuitGroupView.swift`
- Test: `SundeeFundeTests/CircuitGroupViewTests.swift`

**Step 1: Write tests**

```swift
final class CircuitGroupViewTests: XCTestCase {
    func testGroupExercisesByNotes() {
        // Exercises with notes containing "Group A" / "Group B" get grouped
        let exercises: [ProgramExercise] = [
            // ... exercises with grouping notes
        ]
        let groups = CircuitGroupView.groupExercises(exercises)
        XCTAssertEqual(groups.count, 2)
    }
}
```

**Step 2: Implement CircuitGroupView**

- Visual grouping of exercises with headers
- Round tracker per group
- Rest timer between groups

**Step 3: Run tests, commit**

```bash
git commit -m "feat(wod): add Circuit group view"
```

---

### Task 9: Update WODExecutionView for template-aware routing

**Files:**
- Modify: `SundeeFundee/Features/Workouts/WODExecutionView.swift`
- Modify: `SundeeFundee/Features/Workouts/WODExecutionViewModel.swift`
- Test: `SundeeFundeTests/WODExecutionViewModelTests.swift`

**Step 1: Write tests for template routing logic**

```swift
func testViewModelResolvesTemplateType() {
    let amrapWOD = WOD(id: "1", date: "2026-03-08", title: "T", description: "D", templateType: "amrap", exercises: [])
    let vm = WODExecutionViewModel(wod: amrapWOD, /* deps */)
    XCTAssertEqual(vm.resolvedTemplateType, .amrap)
}
```

**Step 2: Update WODExecutionView to switch on templateType**

```swift
var body: some View {
    switch WODTemplateType.from(wod.templateType) {
    case .strength:
        // Existing strength execution view (current behavior)
        strengthExecutionContent
    case .amrap:
        AMRAPTimerView(wod: wod, viewModel: viewModel)
    case .emom:
        EMOMTimerView(wod: wod, viewModel: viewModel)
    case .forTime:
        ForTimeTimerView(wod: wod, viewModel: viewModel)
    case .circuit:
        CircuitGroupView(wod: wod, viewModel: viewModel)
    }
}
```

**Step 3: Run full test suite**

```bash
xcodebuild test \
  -project SundeeFundee.xcodeproj \
  -scheme SundeeFundee \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:SundeeFundeTests
```

**Step 4: Commit**

```bash
git commit -m "feat(wod): template-aware execution view routing"
```

---

### Task 10: Update WOD Dashboard card to show template badge

**Files:**
- Modify: `SundeeFundee/Features/Dashboard/DashboardView.swift`
- Test: `SundeeFundeTests/DashboardViewCoverageTests.swift`

**Step 1: Add template type badge to WODCard**

Show "AMRAP · 12 min" or "EMOM · 20 min" or "Strength" below the WOD title.

**Step 2: Run tests, commit**

```bash
git commit -m "feat(wod): show template type badge on dashboard WOD card"
```

---

## Phase 3: Web Dashboard — Project Setup

### Task 11: Scaffold Next.js project

**Files:**
- Create: `wod-dashboard/` directory at repo root

**Step 1: Create Next.js app**

```bash
cd /Users/dustinober/Projects/Sundee-Fundee
npx create-next-app@latest wod-dashboard \
  --typescript \
  --tailwind \
  --app \
  --src-dir \
  --no-import-alias \
  --eslint
```

**Step 2: Add `.gitignore` entries if needed**

**Step 3: Verify dev server starts**

```bash
cd wod-dashboard && npm run dev
```

**Step 4: Commit**

```bash
git commit -m "chore: scaffold Next.js wod-dashboard project"
```

---

### Task 12: Set up CloudKit JS configuration

**Files:**
- Create: `wod-dashboard/src/lib/cloudkit.ts`
- Create: `wod-dashboard/.env.local` (not committed)
- Create: `wod-dashboard/.env.example`

**Step 1: Install CloudKit JS**

```bash
cd wod-dashboard && npm install tsl-apple-cloudkit
```

**Step 2: Create CloudKit config**

```typescript
// src/lib/cloudkit.ts
import CloudKit from 'tsl-apple-cloudkit';

export function configureCloudKit() {
  return CloudKit.configure({
    containers: [{
      containerIdentifier: 'iCloud.com.sundeefundee.app',
      apiTokenAuth: {
        apiToken: process.env.NEXT_PUBLIC_CLOUDKIT_API_TOKEN!,
        persist: true,
      },
      environment: process.env.NEXT_PUBLIC_CLOUDKIT_ENV as 'development' | 'production' ?? 'development',
    }],
  });
}
```

**Step 3: Create .env.example**

```
NEXT_PUBLIC_CLOUDKIT_API_TOKEN=your-api-token-from-cloudkit-dashboard
NEXT_PUBLIC_CLOUDKIT_ENV=development
CLOUDFLARE_AI_GATEWAY_URL=your-cloudflare-ai-gateway-url
GEMINI_API_KEY=your-gemini-api-key
```

Note: Generate the CloudKit API token at https://developer.apple.com/account/ → Certificates, IDs & Profiles → CloudKit Dashboard → API Tokens.

**Step 4: Commit**

```bash
git commit -m "feat(dashboard): add CloudKit JS configuration"
```

---

### Task 13: Create WOD TypeScript types matching iOS model

**Files:**
- Create: `wod-dashboard/src/types/wod.ts`

**Step 1: Define types**

```typescript
export type TemplateType = 'strength' | 'amrap' | 'emom' | 'forTime' | 'circuit';
export type WODStatus = 'draft' | 'published';

export interface ExerciseValue {
  type: 'fixed' | 'range' | 'amrap' | 'text';
  value?: number;
  min?: number;
  max?: number;
  text?: string;
}

export interface ProgramExercise {
  exercise: string;
  variant?: string | null;
  sets: number | ExerciseValue;
  reps: number | string | ExerciseValue;
  percent1RM?: number | null;
  restMinutes?: number | null;
  notes?: string | null;
  bodyweightOnly: boolean;
}

export interface WOD {
  id: string;
  date: string; // yyyy-MM-dd
  title: string;
  description: string;
  templateType: TemplateType;
  publishDate: string; // yyyy-MM-dd
  status: WODStatus;
  exercises: ProgramExercise[];
}

export interface WODFormData {
  date: string;
  title: string;
  description: string;
  templateType: TemplateType;
  publishDate: string;
  status: WODStatus;
  exercises: ProgramExercise[];
  timeCap?: number; // minutes, for AMRAP/ForTime
  interval?: number; // minutes, for EMOM
  rounds?: number; // for Circuit
}
```

**Step 2: Commit**

```bash
git commit -m "feat(dashboard): add WOD TypeScript types"
```

---

### Task 14: Create CloudKit CRUD service

**Files:**
- Create: `wod-dashboard/src/lib/wod-service.ts`

**Step 1: Implement CRUD operations**

```typescript
// src/lib/wod-service.ts
import { WOD, WODFormData } from '@/types/wod';

export async function fetchWODs(): Promise<WOD[]> {
  // Query CloudKit Public DB for all WOD records
  // Sort by date descending
}

export async function fetchWODByID(id: string): Promise<WOD | null> {
  // Lookup single WOD record
}

export async function saveWOD(data: WODFormData): Promise<WOD> {
  // Create or update WOD record in CloudKit
  // id format: "wod-{date}" e.g. "wod-2026-03-08"
  // exercisesJSON: JSON.stringify(data.exercises)
}

export async function deleteWOD(id: string): Promise<void> {
  // Delete WOD record from CloudKit
}
```

**Step 2: Commit**

```bash
git commit -m "feat(dashboard): add CloudKit WOD CRUD service"
```

---

### Task 15: Set up Sign in with Apple (web)

**Files:**
- Create: `wod-dashboard/src/lib/auth.ts`
- Create: `wod-dashboard/src/components/SignInButton.tsx`
- Modify: `wod-dashboard/src/app/layout.tsx`

**Step 1: Configure Sign in with Apple for web**

Apple's web auth requires:
- A Services ID configured in Apple Developer Console
- A domain + return URL verified
- JS SDK loaded via `<script src="https://appleid.cdn-apple.com/appleauth/static/jsapi/appleid/1/en_US/appleid.auth.js">`

```typescript
// src/lib/auth.ts
export interface AdminUser {
  appleUserID: string;
  role: 'owner' | 'coach';
}

export async function signInWithApple(): Promise<string> {
  // Returns Apple user ID
  // Uses AppleID JS SDK
}

export async function checkAdminAccess(appleUserID: string): Promise<AdminUser | null> {
  // Query CloudKit for AdminUser record matching appleUserID
  // Returns null if not an admin
}
```

**Step 2: Create AdminUser record type in CloudKit**

Via CloudKit Dashboard, create `AdminUser` record type:
- `appleUserID` (String)
- `role` (String: "owner" or "coach")

Seed your own record as owner.

**Step 3: Commit**

```bash
git commit -m "feat(dashboard): add Sign in with Apple web auth"
```

---

## Phase 4: Web Dashboard — Core UI

### Task 16: Build calendar page

**Files:**
- Create: `wod-dashboard/src/app/page.tsx` (redirect to calendar)
- Create: `wod-dashboard/src/app/calendar/page.tsx`
- Create: `wod-dashboard/src/components/WODCalendar.tsx`

**Step 1: Implement month calendar view**

- Grid layout showing days of the month
- Each day shows WOD title + template badge if one exists
- Empty days show "+" button to create
- Click existing WOD to edit
- Month navigation (prev/next)
- Color-coded: published = green, draft = yellow, empty = gray

**Step 2: Commit**

```bash
git commit -m "feat(dashboard): add WOD calendar page"
```

---

### Task 17: Build WOD editor page

**Files:**
- Create: `wod-dashboard/src/app/editor/[date]/page.tsx`
- Create: `wod-dashboard/src/components/WODEditor.tsx`
- Create: `wod-dashboard/src/components/TemplateForm.tsx`
- Create: `wod-dashboard/src/components/ExercisePicker.tsx`

**Step 1: Build the editor form**

- Text input area at top (natural language / AI prompt)
- Template type selector (tabs: Strength, AMRAP, EMOM, For Time, Circuit)
- Template-specific fields:
  - **Strength:** Exercise rows with sets/reps/%1RM/rest/notes
  - **AMRAP:** Time cap + exercise list with reps
  - **EMOM:** Duration + interval + exercises per interval
  - **For Time:** Exercise list with reps + optional time cap
  - **Circuit:** Grouped exercises + rounds + rest
- Add exercise button with searchable dropdown (seeded from exercise catalog)
- Title + description (auto-generated, editable)
- Publish date picker
- Save as Draft / Publish buttons
- Preview panel

**Step 2: Commit**

```bash
git commit -m "feat(dashboard): add WOD editor page with template forms"
```

---

### Task 18: Build exercise catalog for picker

**Files:**
- Create: `wod-dashboard/src/data/exercise-catalog.ts`

**Step 1: Port exercise catalog from iOS**

Extract the exercise names from `SundeeFundee/Models/SharedTypes.swift` (weightlifting exercises) and `SundeeFundee/Domain/BenchmarkCatalog.swift` (conditioning exercises) into a TypeScript constant:

```typescript
export const EXERCISE_CATALOG = {
  squat: ['Back Squat', 'Front Squat', 'Overhead Squat', 'Goblet Squat'],
  hinge: ['Deadlift', 'Sumo Deadlift', 'Romanian Deadlift'],
  press: ['Bench Press', 'Overhead Press', 'Push Press', 'Incline Bench Press'],
  pull: ['Barbell Row', 'Pendlay Row', 'Pull-Up', 'Weighted Pull-up'],
  olympic: ['Power Clean', 'Clean', 'Clean & Jerk', 'Snatch', 'Power Snatch', 'Hang Clean', 'Hang Snatch', 'Split Jerk'],
  accessory: ['Hip Thrust', 'Weighted Dip', 'Lateral Raise', 'Face Pull', 'Calf Raise'],
  bodyweight: ['Push-Up', 'Burpee', 'Box Jump', 'Plank', 'Dip'],
  conditioning: ['Kettlebell Swing', 'Wall Ball', 'Double Under', 'Row', 'Run', 'Walking Lunge'],
} as const;

export const ALL_EXERCISES = Object.values(EXERCISE_CATALOG).flat();
```

**Step 2: Commit**

```bash
git commit -m "feat(dashboard): add exercise catalog for picker"
```

---

## Phase 5: Natural Language Parser

### Task 19: Build workout text parser

**Files:**
- Create: `wod-dashboard/src/lib/workout-parser.ts`
- Create: `wod-dashboard/src/lib/__tests__/workout-parser.test.ts`

**Step 1: Write tests**

```typescript
import { parseWorkoutText } from '../workout-parser';

describe('parseWorkoutText', () => {
  it('parses strength format: "5x5 back squat 75%"', () => {
    const result = parseWorkoutText('5x5 back squat 75%');
    expect(result.templateType).toBe('strength');
    expect(result.exercises[0]).toEqual({
      exercise: 'Back Squat',
      sets: 5,
      reps: 5,
      percent1RM: 0.75,
      bodyweightOnly: false,
    });
  });

  it('parses AMRAP format: "AMRAP 12 min: 10 KB swings, 15 box jumps"', () => {
    const result = parseWorkoutText('AMRAP 12 min: 10 KB swings, 15 box jumps');
    expect(result.templateType).toBe('amrap');
    expect(result.timeCap).toBe(12);
    expect(result.exercises).toHaveLength(2);
  });

  it('parses EMOM format: "EMOM 20: odd 5 cleans, even 10 burpees"', () => {
    const result = parseWorkoutText('EMOM 20: odd 5 cleans, even 10 burpees');
    expect(result.templateType).toBe('emom');
    expect(result.timeCap).toBe(20);
  });

  it('parses For Time: "For time: 21-15-9 thrusters and pull-ups"', () => {
    const result = parseWorkoutText('For time: 21-15-9 thrusters and pull-ups');
    expect(result.templateType).toBe('forTime');
  });

  it('parses multiple exercises with commas', () => {
    const result = parseWorkoutText('3x10 RDL 60%, 3x12 leg press, 3x60s plank');
    expect(result.exercises).toHaveLength(3);
  });

  it('matches exercise names case-insensitively against catalog', () => {
    const result = parseWorkoutText('5x5 back squat');
    expect(result.exercises[0].exercise).toBe('Back Squat');
  });
});
```

**Step 2: Implement parser**

Pattern matching approach:
1. Detect template type from keywords (AMRAP, EMOM, "for time")
2. Extract time parameters (cap, intervals)
3. Split exercise segments by comma or newline
4. For each segment, extract: sets×reps, exercise name, %1RM, notes
5. Fuzzy-match exercise names against catalog

**Step 3: Run tests**

```bash
cd wod-dashboard && npm test
```

**Step 4: Commit**

```bash
git commit -m "feat(dashboard): add natural language workout parser"
```

---

## Phase 6: AI Workout Generation

### Task 20: Build AI generation service

**Files:**
- Create: `wod-dashboard/src/lib/ai-generate.ts`
- Create: `wod-dashboard/src/app/api/generate/route.ts`

**Step 1: Create API route**

The API route proxies to Cloudflare AI Gateway → Gemini to keep the API key server-side:

```typescript
// src/app/api/generate/route.ts
import { NextRequest, NextResponse } from 'next/server';

export async function POST(request: NextRequest) {
  const { prompt } = await request.json();

  const systemPrompt = `You are a strength and conditioning coach creating workouts for the Sundee Fundee fitness app.
Generate a structured workout in JSON format matching this schema:
{
  "title": "string",
  "description": "string - brief coaching notes",
  "templateType": "strength|amrap|emom|forTime|circuit",
  "timeCap": "number|null - minutes",
  "exercises": [
    {
      "exercise": "string - from standard catalog",
      "variant": "string|null",
      "sets": "number",
      "reps": "number|string",
      "percent1RM": "number|null - as decimal 0.0-1.0",
      "restMinutes": "number|null",
      "notes": "string|null",
      "bodyweightOnly": "boolean"
    }
  ]
}
Respond with ONLY the JSON, no markdown.`;

  const response = await fetch(process.env.CLOUDFLARE_AI_GATEWAY_URL!, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${process.env.GEMINI_API_KEY}`,
    },
    body: JSON.stringify({
      contents: [
        { role: 'user', parts: [{ text: systemPrompt + '\n\nUser request: ' + prompt }] }
      ],
    }),
  });

  const data = await response.json();
  // Extract generated text, parse JSON, return structured WOD
  return NextResponse.json(data);
}
```

**Step 2: Create client-side wrapper**

```typescript
// src/lib/ai-generate.ts
import { WODFormData } from '@/types/wod';

export async function generateWorkout(prompt: string): Promise<Partial<WODFormData>> {
  const response = await fetch('/api/generate', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ prompt }),
  });
  return response.json();
}
```

**Step 3: Commit**

```bash
git commit -m "feat(dashboard): add AI workout generation via Cloudflare/Gemini"
```

---

### Task 21: Wire AI + parser into editor

**Files:**
- Modify: `wod-dashboard/src/components/WODEditor.tsx`

**Step 1: Add input mode detection**

The text input area should:
1. Detect if input looks structured (contains "x" patterns like "5x5", exercise names) → use parser
2. Detect if input is intent-based ("heavy leg day", "recovery workout") → use AI
3. Show a toggle for the user to force one mode or the other
4. Display a loading state during AI generation
5. Populate the template form with the result, allowing edits before save

**Step 2: Commit**

```bash
git commit -m "feat(dashboard): wire parser and AI generation into editor"
```

---

## Phase 7: Admin Management & Polish

### Task 22: Build admin management page

**Files:**
- Create: `wod-dashboard/src/app/admin/page.tsx`
- Create: `wod-dashboard/src/components/AdminList.tsx`

**Step 1: Implement admin CRUD**

- List current admins (Apple ID + role)
- "Add Admin" form (enter Apple ID, select role)
- Remove admin button (owner only)
- Owner cannot remove themselves

**Step 2: Commit**

```bash
git commit -m "feat(dashboard): add admin management page"
```

---

### Task 23: Add Art Deco theming to dashboard

**Files:**
- Modify: `wod-dashboard/tailwind.config.ts`
- Modify: `wod-dashboard/src/app/globals.css`
- Modify: `wod-dashboard/src/app/layout.tsx`

**Step 1: Configure theme colors**

```typescript
// tailwind.config.ts
colors: {
  cream: '#F4F0DF',
  navy: '#0D1A40',
  orange: '#F2731A',
}
```

**Step 2: Apply Art Deco styling**

- Cream background, navy text, orange accents
- Geometric borders and decorative elements
- Consistent with iOS app aesthetic

**Step 3: Commit**

```bash
git commit -m "feat(dashboard): add Art Deco theming"
```

---

## Phase 8: Deployment

### Task 24: Deploy to Vercel

**Step 1: Create Vercel project**

```bash
cd wod-dashboard && npx vercel
```

**Step 2: Set environment variables in Vercel dashboard**

- `NEXT_PUBLIC_CLOUDKIT_API_TOKEN`
- `NEXT_PUBLIC_CLOUDKIT_ENV` = `production`
- `CLOUDFLARE_AI_GATEWAY_URL`
- `GEMINI_API_KEY`

**Step 3: Configure custom domain (optional)**

**Step 4: Deploy**

```bash
npx vercel --prod
```

**Step 5: Commit any Vercel config changes**

```bash
git commit -m "chore: add Vercel deployment config"
```

---

### Task 25: Add CloudKit schema fields

**Manual steps in CloudKit Dashboard:**

1. Go to CloudKit Dashboard → Schema → Record Types → WOD
2. Add field: `templateType` (String)
3. Add field: `publishDate` (String)
4. Add field: `status` (String)
5. Create new Record Type: `AdminUser`
   - `appleUserID` (String)
   - `role` (String)
6. Seed your AdminUser record with role "owner"
7. Generate API Token for web dashboard use
8. Deploy schema to production

---

### Task 26: End-to-end test

**Step 1: Test full flow**

1. Open dashboard → sign in with Apple
2. Click a calendar date → editor opens
3. Type "5x5 back squat 75%, 3x10 RDL 60%" → parser fills form
4. Publish → verify WOD appears in CloudKit
5. Open iOS app → verify WOD appears on dashboard
6. Start WOD → verify execution view matches template type

**Step 2: Test AI generation**

1. Type "Heavy upper body day, 45 minutes"
2. Verify Gemini generates structured workout
3. Edit and publish
4. Verify in iOS app

**Step 3: Test scheduled publishing**

1. Create WOD with future publishDate
2. Verify it does NOT appear in iOS app today
3. Verify it appears on the publishDate

---

## Build Order Summary

| Phase | Tasks | Dependencies |
|-------|-------|-------------|
| 1: iOS Model | 1-3 | None |
| 1: iOS Domain | 4 | Task 1 |
| 2: iOS Views | 5-10 | Task 4 |
| 3: Web Setup | 11-14 | None (parallel with Phase 1-2) |
| 4: Web UI | 15-18 | Tasks 12-14 |
| 5: Parser | 19 | Task 13 |
| 6: AI | 20-21 | Tasks 17, 19 |
| 7: Admin | 22-23 | Task 15 |
| 8: Deploy | 24-26 | All above |

**iOS and Web phases can run in parallel.** Tasks 1-10 (iOS) and Tasks 11-19 (Web) have no cross-dependencies until the final integration test.
