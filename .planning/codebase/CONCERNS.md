# Codebase Concerns

**Analysis Date:** 2026-04-15

## Tech Debt

### Large SwiftUI Views — Complexity & Maintenance Risk

**Issue:** Multiple SwiftUI view files exceed 800 lines, combining layout, logic, and state management in a single file.

**Files:**
- `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Workouts/AIWorkoutView.swift` (883 lines)
- `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Workouts/WorkoutsListView.swift` (790 lines)
- `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Programs/ProgramsListView.swift` (773 lines)
- `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Workouts/WorkoutDetailView.swift` (744 lines)
- `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Dashboard/DashboardView.swift` (675 lines)
- `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Settings/SettingsView.swift` (669 lines)

**Impact:**
- Reduced code readability and testability
- Difficulty isolating bugs to specific UI sections
- Performance penalties from single large view hierarchy
- Increased risk of accidental state sharing between unrelated sections

**Fix approach:**
Extract helper view builders and sub-components into separate files. Split each large view into 2-3 smaller composable views (e.g., `AIWorkoutQuestionnaireView`, `AIWorkoutPreviewView`). Move validation and formatting logic to computed properties or helper functions. Target: each file under 400 lines.

### CloudKit Schema Migration Incomplete

**Issue:** App persists `UserRecord` with `createdAt` field, which collides with CloudKit's reserved system field name.

**Files:**
- `SundeeFundee/Sources/SundeeFundeeKit/UI/ViewModels/AuthViewModel.swift` (line 234: `createdAt: Date()`)

**Impact:**
- CloudKit may misinterpret or silently drop the custom `createdAt` field
- Data loss or corruption when syncing to/from CloudKit
- Backward-incompatible schema if field names change later

**Fix approach:**
Rename `UserRecord.createdAt` to `UserRecord.dateCreated` (following the pattern already used in `Challenge.swift`). Update `encode(to:)` and `init(from:)` to handle legacy `createdAt` field for backwards compatibility. Add a custom decoder that tries both keys. Verify in CloudKit Dashboard that the new field is persisted correctly.

### Incomplete HealthKit Authorization Flow

**Issue:** HealthKit authorization state is never explicitly requested at app startup. The app assumes HealthKit is available and authorized without checking credential state first.

**Files:**
- `SundeeFundee/Sources/SundeeFundeeKit/DataLayer/Actors/HealthKitClient.swift` (lines 57-78: `requestAuthorization`)
- `SundeeFundee/Sources/SundeeFundeeKit/UI/ViewModels/BenchmarksViewModel.swift` — fetches menstrual cycles without checking authorization first
- `SundeeFundee/Sources/SundeeFundeeKit/UI/ViewModels/ActiveWorkoutSessionViewModel.swift` — saves workout to HealthKit without authorization check

**Impact:**
- Silent failures when HealthKit data is not accessible
- Users may not realize why cycle data or menstrual cycle logs are empty
- Workouts fail to sync to HealthKit Activity app without clear error messaging

**Fix approach:**
Add explicit authorization request in `AppDelegate` or app init. Check `HKHealthStore.authorizationStatus(for:)` before each read/write. Show user-facing alert if authorization is denied. Cache authorization status in `AuthViewModel` and propagate to data clients.

## Fragile Areas

### View Model Memory Leaks — Timer Subscriptions Not Properly Cancelled

**Issue:** `ActiveWorkoutSessionViewModel` uses `Combine` subscriptions for rest timer and elapsed time tracking (`restTimerCancellable`, `elapsedTimerCancellable`) but cleanup is not explicit in deinit.

**Files:**
- `SundeeFundee/Sources/SundeeFundeeKit/UI/ViewModels/ActiveWorkoutSessionViewModel.swift` (lines 31-32: cancellables declared, line 84-96 init, no explicit deinit cleanup)

**Impact:**
- Memory leaks if view model is dismissed while timers are running
- Stale timer callbacks after workout session closes
- Potential background activity after user navigates away from active workout

**Safe modification:**
Add explicit `deinit { restTimerCancellable?.cancel(); elapsedTimerCancellable?.cancel() }`. Alternatively, use a `@State` property with `.onDisappear()` hook to cancel subscriptions. Verify in memory profiler that timers stop when view is dismissed.

### SyncQueue Partial Failure on Offline→Online Transition

**Issue:** `SyncQueue` detects connectivity changes but doesn't guarantee all queued mutations are flushed. If a flush fails partway through, remaining mutations are left in the queue indefinitely with no retry mechanism beyond the initial detection.

**Files:**
- `SundeeFundee/Sources/SundeeFundeeKit/DataLayer/SyncQueue/SyncQueue.swift` (lines 44, 74-81: `isFlushing` flag prevents concurrent flushes, but partial failures not retried)

**Impact:**
- User makes changes offline, then goes online, but only some changes sync
- User unaware that data is out of sync
- Subsequent offline changes compound the problem

**Fix approach:**
Implement exponential backoff retry for failed mutations. Track individual mutation retry counts (already has `maxRetryAttempts`). Emit a notification or callback when sync partially fails so UI can alert the user. Periodically attempt to flush remaining mutations.

### Keychains-Stored User Data Mismatches CloudKit

**Issue:** User name, email, and user ID are stored in Keychain but may diverge from CloudKit if Keychain persists stale data after CloudKit deletion.

**Files:**
- `SundeeFundee/Sources/SundeeFundeeKit/Auth/KeychainHelper.swift` (lines 9-79: simple save/read/delete)
- `SundeeFundee/Sources/SundeeFundeeKit/UI/ViewModels/AuthViewModel.swift` (lines 66-89: fallback chain for user name)

**Impact:**
- After account deletion, Keychain still holds user ID; subsequent sign-in may use stale data
- User name cached in Keychain may not match current CloudKit state if name updated on another device
- Confusion in multi-device scenarios

**Safe modification:**
Clear ALL Keychain user data in `AuthViewModel.deleteAccount()` (lines 137-160). Add explicit `KeychainHelper.delete()` calls for `userIDKey`, `userEmailKey`, `userNameKey` after CloudKit deletion succeeds. Test account deletion flow to ensure Keychain is fully wiped.

## Test Coverage Gaps

### View Models Mostly Untested

**Issue:** Only 3 of 6 view models have test coverage.

**Untested View Models:**
- `ActiveWorkoutSessionViewModel.swift` (435 lines) — manages critical workout session state, timers, completion tracking, celebration events
- `AuthViewModel.swift` (164+ lines) — handles sign-in, guest mode, account deletion, Keychain persistence
- `PainTrackingViewModel.swift` (494 lines) — manages injury tracking, pain logging, adaptation recommendations
- `ExportViewModel.swift` (85 lines) — manages data export and JSON generation

**Tested View Models:**
- `AnalyticsViewModel` (coverage exists)
- `ProgramsListViewModel` (coverage exists)
- `WorkoutDetailViewModel` (coverage exists)

**Files:**
- `SundeeFundee/Tests/SundeeFundeeKitTests/ViewModelTests/` contains only 3 test files for 6 view models

**Risk:**
- Refactoring `ActiveWorkoutSessionViewModel` risks breaking timers, workout completion logic, or celebration events without catching regressions
- `AuthViewModel` changes (Keychain fallback chain, CloudKit interactions) not validated by tests
- `PainTrackingViewModel` injury adaptation logic not checked against domain layer changes
- `ExportViewModel` JSON generation and error handling paths untested

**Priority:** High — `ActiveWorkoutSessionViewModel` and `AuthViewModel` are core to app functionality.

**Fix approach:**
Add unit tests for:
- `ActiveWorkoutSessionViewModel`: test timer state transitions, set completion flow, celebration event triggering, rest period calculations
- `AuthViewModel`: test sign-in success/failure paths, Keychain fallback chain, guest mode setup, account deletion flow
- `PainTrackingViewModel`: test injury logging, adaptation fetches, error handling
- `ExportViewModel`: test JSON generation, error cases, category counting

See `SundeeFundee/Tests/SundeeFundeeKitTests/ViewModelTests/` for existing test patterns.

### SwiftUI View Integration Tests Missing

**Issue:** SwiftUI views are not tested via UI automation or snapshot tests. Changes to layout, accessibility, or state binding are discovered only through manual testing.

**Files:**
- `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/` — 24 view files, 0 UI tests

**Impact:**
- Accessibility regressions not caught (e.g., missing accessibility labels)
- Layout bugs in edge cases (long text, small screens) not detected
- Interaction bugs (toggle states, navigation) not validated

**Fix approach:**
Start with high-value views: `ActiveWorkoutView` (critical user flow), `CycleCalendarView` (complex layout), `AIWorkoutView` (AI generation UX). Use XCTest with UI automation (coordinate taps, text input, screenshot validation). Alternatively, adopt Swift Testing snapshots (`swift-snapshot-testing`) for layout validation.

### AuthViewModel Edge Cases Not Tested

**Issue:** Critical authentication edge cases lack test coverage.

**Untested scenarios:**
- Apple Sign-In returns `nil` for `fullName` on subsequent sign-ins (line 72 in AuthViewModel)
- Keychain read failures during sign-in fallback (line 66)
- CloudKit save fails but Keychain persist succeeds (inconsistent state)
- Guest → signed-in transition with existing local data
- Account deletion with pending SyncQueue mutations

**Files:**
- `SundeeFundee/Sources/SundeeFundeeKit/UI/ViewModels/AuthViewModel.swift` (lines 48-101: sign-in flow has multiple fallback paths)
- `SundeeFundee/Tests/SundeeFundeeKitTests/AuthTests/AppleAuthClientTests.swift` — tests `AppleAuthClient` only, not `AuthViewModel`

**Fix approach:**
Create `AuthViewModelTests.swift` with mock `AppleAuthClient` and `DataClientProtocol`. Test:
1. Sign-in with full name available
2. Sign-in with `nil` full name (use Keychain fallback)
3. Keychain read failure (use CloudKit fallback)
4. All three fallbacks fail (show error, set `userName = nil`)
5. Guest mode initialization and persistence
6. Account deletion clears Keychain completely
7. Sign-in after account deletion works correctly

## Performance Bottlenecks

### LocalDataClient Predicate Evaluation on Large Datasets

**Issue:** `LocalDataClient.fetch()` evaluates NSPredicate on all in-memory records for every query. No indexing or query optimization.

**Files:**
- `SundeeFundee/Sources/SundeeFundeeKit/DataLayer/Actors/LocalDataClient.swift` (lines 34-59: `fetch` method)

**Code:**
```swift
let filtered = records.filter { predicate.evaluate(with: $0 as NSDictionary) }
```

**Impact:**
- As local data grows (hundreds of workouts, challenges), fetch performance degrades linearly
- Guest users with large datasets experience slow app navigation
- No benefit from UserDefaults optimization

**Current capacity:**
- Guests can store ~100-500 workouts before noticeable slowdown
- ~1000 records total before UI becomes unresponsive during fetch

**Scaling path:**
Implement lightweight in-memory indexing for common predicates (e.g., `date > X`). Cache fetches for stable record types. Consider migration to SQLite for guest data if UserDefaults size becomes problematic. For now, add pagination and lazy loading in views that display large lists.

### CloudKitClient Fetch Logs Excessive — String Allocation in Loop

**Issue:** `CloudKitClient` logs every fetch/save with string interpolation, even for large batches. Creates unnecessary String allocations and disk I/O for logs.

**Files:**
- `SundeeFundee/Sources/SundeeFundeeKit/DataLayer/Actors/CloudKitClient.swift` (lines 87, 91, 97, 128, 142-164: logging statements)

**Example:**
```swift
ckLogger.info("✅ FETCH \(recordType): \(results.count) records")
```

**Impact:**
- Heavy logging during bulk sync or large result sets
- Disk I/O overhead for every fetch/save
- Log files grow quickly in production builds with verbose logging

**Fix approach:**
Reduce logging frequency: log only errors and summary statistics (start/end of bulk operations), not per-record details. Use conditional logging level checks (`if ckLogger.isEnabled(for: .debug)`) to disable verbose logs in production. Batch log messages for bulk operations (e.g., "Saved 150 records in 2.3s").

## Dependencies at Risk

### MockHealthKitClient File Size and Maintainability

**Issue:** `MockHealthKitClient` is 626 lines and contains hardcoded sample data for all menstrual cycle scenarios, workouts, and health metrics.

**Files:**
- `SundeeFundee/Sources/SundeeFundeeKit/DataLayer/Mocks/MockHealthKitClient.swift` (626 lines)

**Impact:**
- Any new health metric type requires updating the mock
- Hard to maintain consistency between mock data and real HealthKit behavior
- Large file makes testing hard to understand at a glance

**Fix approach:**
Extract sample data into separate factory files (e.g., `HealthKitTestFactories.swift`). Use builder pattern for constructing test menstrual cycles and workouts. Document the mock's limitations (e.g., does not simulate authorization denial, does not track sample query limits).

### Unused Keychain Fields May Cause Keychain Bloat

**Issue:** Keychain stores `userNameKey` and `userEmailKey` in addition to `userIDKey`, but email is transient and user name is primarily stored in CloudKit.

**Files:**
- `SundeeFundee/Sources/SundeeFundeeKit/Auth/KeychainHelper.swift` (lines 75-77: three keys defined)

**Impact:**
- Over time, multiple sign-in/sign-out cycles accumulate stale Keychain entries
- Unnecessary Keychain lookups during auth flow
- No clear strategy for when to update vs. read these values

**Fix approach:**
Simplify to storing only `userIDKey`. Fetch email and name from CloudKit on every sign-in (no offline fallback). If offline email/name lookup is required, document the strategy in `AuthViewModel` and clean up Keychain entries explicitly during sign-out.

## Missing Critical Features

### No Offline Indication for Guests

**Issue:** Guest users have no visual indication that they are in local-only mode or that their data will not sync.

**Files:**
- `SundeeFundee/Sources/SundeeFundeeKit/UI/ViewModels/AuthViewModel.swift` (line 104: `continueAsGuest()` sets state but no UI indicator)
- Related views do not display guest mode status

**Impact:**
- Users may unknowingly create data that will be lost if they uninstall the app
- Confusion when switching devices (local data doesn't sync)
- No prompt to save or export data before guest session ends

**Fix approach:**
Add a visual badge or banner in views that indicates guest mode (e.g., "Local Storage Only" label in Settings, badge in navigation). Add a prompt when user navigates away from active workout in guest mode reminding them data is local. Add "Save/Export" button in guest mode before session expires or data is cleared.

### No Data Recovery After Account Deletion

**Issue:** `AuthViewModel.deleteAccount()` permanently deletes all CloudKit data with no recovery option.

**Files:**
- `SundeeFundee/Sources/SundeeFundeeKit/UI/ViewModels/AuthViewModel.swift` (lines 137-160: `deleteAccount()` calls `dataClient.deleteAllData()`)

**Impact:**
- User accidentally deletes account and loses all data irreversibly
- No grace period or recovery option
- Violates user expectations (many apps offer 30-day recovery)

**Fix approach:**
Implement soft delete: rename records instead of deleting them, mark as `deleted=true` in CloudKit. Offer 30-day recovery window (display in Settings). Hard delete after grace period expires via nightly cleanup task. Require re-authentication before deletion to prevent accidental deletion.

---

*Concerns audit: 2026-04-15*
