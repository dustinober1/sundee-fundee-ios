---
phase: quick
plan: 260416-qbs
type: execute
wave: 1
depends_on: []
files_modified:
  - SundeeFundee/Sources/SundeeFundeeKit/DataLayer/Actors/CloudKitClient.swift
  - SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Settings/SettingsView.swift
autonomous: true
requirements:
  - QUICK-260416-qbs-01
  - QUICK-260416-qbs-02

must_haves:
  truths:
    - "CloudKitClient.save() recovers from CKError.serverRecordChanged by re-fetching the server record, merging fields, and retrying once — no user-visible oplock error"
    - "Rapid toggles across the four Settings onChange handlers (weightUnit, experienceLevel, primaryGoal, cycleTrackingEnabled) do NOT spawn parallel saves — only the latest state is committed"
    - "Existing duplicate-on-insert merge path still works (regression-safe)"
    - "Swift 6 strict concurrency still compiles clean — no new warnings"
  artifacts:
    - path: "SundeeFundee/Sources/SundeeFundeeKit/DataLayer/Actors/CloudKitClient.swift"
      provides: "save() handles both .serverRecordChanged and duplicate-insert via shared merge-and-retry helper"
      contains: "serverRecordChanged"
    - path: "SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Settings/SettingsView.swift"
      provides: "saveSettings serializes with task handle + cancellation to prevent parallel races"
      contains: "saveTask"
  key_links:
    - from: "CloudKitClient.save()"
      to: "modifyRecords retry after server merge"
      via: "catch CKError.serverRecordChanged → fetchExistingRecords → rewrite CKRecords against server changeTag → modifyRecords retry"
      pattern: "serverRecordChanged"
    - from: "SettingsView.onChange handlers"
      to: "SettingsViewModel.scheduleSave()"
      via: "single @Published Task handle cancelled on new writes"
      pattern: "saveTask\\?.cancel\\(\\)"
---

<objective>
Fix the "client oplock error updating record" alert users hit on multi-device iCloud accounts when toggling settings. Two compounding causes, one plan.

Purpose:
1. Make CloudKitClient.save() robust against server-side conflicts (CKError.serverRecordChanged) so a stale in-memory changeTag doesn't surface as a user-visible error.
2. Serialize SettingsViewModel.saveSettings so the four onChange handlers cannot spawn parallel in-flight saves that race each other.

Output:
- Patched CloudKitClient.save() with shared "merge with server record and retry once" path covering both duplicate-on-insert (existing) AND serverRecordChanged (new).
- Patched SettingsViewModel with cancellable single-task save serialization.
- Build passes; existing DataLayerTests still pass.
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@./CLAUDE.md
@.planning/STATE.md
@SundeeFundee/Sources/SundeeFundeeKit/DataLayer/Actors/CloudKitClient.swift
@SundeeFundee/Sources/SundeeFundeeKit/DataLayer/Protocols/DataClientProtocol.swift
@SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Settings/SettingsView.swift
@SundeeFundee/Sources/SundeeFundeeKit/DataLayer/SyncQueue/SyncQueue.swift

<interfaces>
Key types and contracts extracted from the codebase — use directly, no exploration needed.

CloudKitClient.save signature (from DataClientProtocol.swift):
```swift
public func save<T>(
    _ records: [T],
    recordType: String
) async throws where T: Encodable & Sendable
```

Existing helpers already in CloudKitClient (reuse — do NOT re-implement):
```swift
private func fetchExistingRecords(_ recordIDs: [CKRecord.ID]) async -> [CKRecord.ID: CKRecord]
private func mergeWithExisting(_ newRecord: CKRecord, existing: [CKRecord.ID: CKRecord], nilKeys: [CKRecord.ID: Set<String>]) -> CKRecord
private func encodeToCKRecord<T: Encodable>(_ value: T, recordType: String, nilKeyMap: inout [CKRecord.ID: Set<String>]) throws -> CKRecord
private func isDuplicateRecordError(_ error: Error) -> Bool
private func mapCKError(_ error: Error, recordID: CKRecord.ID?) -> DataError
```

Current save() error-handling shape (simplified):
```swift
do {
    let (savedRecords, _) = try await database.modifyRecords(saving: ckRecords, deleting: [])
    // iterate, throw on per-record .failure
} catch {
    guard isDuplicateRecordError(error) else { throw mapCKError(error, recordID: nil) }
    // duplicate path: fetch existing → merge → retry
}
```

Observation: the duplicate-on-insert handler throws the per-record error OUT of the do-block so the outer catch can decide whether to merge. `.serverRecordChanged` comes back in the SAME shape — as a per-record CKError inside `savedRecords`, which our loop currently throws upward. This means the fix reuses the SAME exit path; we just need to (a) detect serverRecordChanged in addition to duplicate, and (b) use the server-returned CKRecord from the error's userInfo rather than re-fetching when possible.

CKError.serverRecordChanged details:
- `CKError.Code.serverRecordChanged` (raw value 14)
- `error.userInfo[CKRecordChangedErrorServerRecordKey]` contains the server's current CKRecord (includes the correct changeTag)
- `error.userInfo[CKRecordChangedErrorClientRecordKey]` contains our submitted record
- Preferred strategy: use the server record from userInfo (cheaper than refetch), overlay our field values, retry once

SettingsView onChange block (lines 90-93) — currently spawns parallel Tasks:
```swift
.onChange(of: viewModel.weightUnit) { _, _ in Task { await viewModel.saveSettings() } }
.onChange(of: viewModel.experienceLevel) { _, _ in Task { await viewModel.saveSettings() } }
.onChange(of: viewModel.primaryGoal) { _, _ in Task { await viewModel.saveSettings() } }
.onChange(of: viewModel.cycleTrackingEnabled) { _, _ in Task { await viewModel.saveSettings() } }
```

SettingsViewModel (lines 607-668) is @MainActor, has `isSaving`, `errorMessage`, `hasLoaded` state, and calls:
```swift
try await dataClient.save(record, recordType: "UserSettings")
```

UserSettingsRecord is the Codable model (Bool-as-Int64 custom decoder per CLAUDE.md — do NOT touch the model).
</interfaces>

Constraints from CLAUDE.md:
- Swift 6 strict concurrency: CloudKitClient is `@unchecked Sendable` final class; keep it that way. SettingsViewModel is `@MainActor`.
- Do NOT rename or modify UserSettingsRecord — its Bool-as-Int64 init(from:) is critical.
- Zero external dependencies — use only CloudKit, Foundation, SwiftUI.
- Date encoding: JSONEncoder(.iso8601) — unchanged.
- Auto-commit each file after editing (per project Git Workflow).
- Do NOT introduce force-unwraps; SwiftLint enforces `force_unwrapping`.
</context>

<tasks>

<task type="auto" tdd="true">
  <name>Task 1: Handle CKError.serverRecordChanged in CloudKitClient.save() with shared merge-retry helper</name>
  <files>SundeeFundee/Sources/SundeeFundeeKit/DataLayer/Actors/CloudKitClient.swift</files>
  <behavior>
    - When modifyRecords returns a per-record .failure with CKError.serverRecordChanged: extract the server's CKRecord from error.userInfo[CKRecordChangedErrorServerRecordKey], overlay our field values (plus nil-key clears) onto it, retry modifyRecords once. If the retry also fails, throw mapCKError.
    - When modifyRecords throws a batch-level duplicate-insert error: existing path continues to work unchanged (fetchExistingRecords + mergeWithExisting + retry).
    - If any record in the first batch fails with serverRecordChanged AND the batch throws as a whole (CKError.partialFailure wrapping per-record errors), detect via CKError.Code.partialFailure + userInfo[CKPartialErrorsByItemIDKey] and route to the server-merge path.
    - Retry is bounded to ONE additional attempt — no infinite loops.
    - Logging: add `ckLogger.info("🔄 SAVE \(recordType): serverRecordChanged for <N> record(s), merging with server copy")` before retry; add `ckLogger.info("✅ SAVE \(recordType): server-merge retry success")` after.
    - Duplicate-insert and serverRecordChanged paths share a private helper that takes `[CKRecord]` + the nilKeyMap and performs the overlay + retry.
    - saveFromJSON (SyncQueue replay path) gets the same serverRecordChanged handling via the same helper — an offline-replayed mutation is even more likely to hit a stale changeTag.
  </behavior>
  <action>
    Modify CloudKitClient.save() (lines ~123-166) and saveFromJSON() (lines ~206-260). Add a new private helper:

    ```swift
    /// Detects whether an error is CKError.serverRecordChanged (client's changeTag is stale).
    private func isServerRecordChangedError(_ error: Error) -> Bool {
        guard let ckError = error as? CKError else { return false }
        return ckError.code == .serverRecordChanged
    }

    /// Extracts per-item errors from a CKError.partialFailure, or returns [nil: error]
    /// if the error is itself a per-record error (not a batch-level partialFailure).
    private func perItemErrors(from error: Error) -> [CKRecord.ID: Error]? {
        guard let ckError = error as? CKError else { return nil }
        if ckError.code == .partialFailure,
           let items = ckError.userInfo[CKPartialErrorsByItemIDKey] as? [CKRecord.ID: Error] {
            return items
        }
        return nil
    }

    /// Builds replacement CKRecords by overlaying new field values + nil-key clears
    /// onto the server copies returned in CKError.serverRecordChanged userInfo.
    /// For records not in serverRecords, falls back to the original newRecord.
    private func mergeWithServerRecords(
        newRecords: [CKRecord],
        serverRecords: [CKRecord.ID: CKRecord],
        nilKeys: [CKRecord.ID: Set<String>]
    ) -> [CKRecord] {
        newRecords.map { newRecord in
            guard let serverCopy = serverRecords[newRecord.recordID] else {
                return newRecord
            }
            for key in newRecord.allKeys() {
                serverCopy[key] = newRecord[key]
            }
            if let keysToNil = nilKeys[newRecord.recordID] {
                for key in keysToNil {
                    serverCopy[key] = nil
                }
            }
            return serverCopy
        }
    }
    ```

    Rewrite save() catch block to handle BOTH duplicate-on-insert AND serverRecordChanged. Pseudocode (preserve existing logging + error mapping):

    ```swift
    do {
        let (savedRecords, _) = try await database.modifyRecords(saving: ckRecords, deleting: [])
        // Collect per-record errors (both top-level and partialFailure form)
        var serverErrors: [CKRecord.ID: Error] = [:]
        var duplicateDetected = false
        for (recordID, result) in savedRecords {
            if case .failure(let error) = result {
                if isDuplicateRecordError(error) {
                    duplicateDetected = true
                } else if isServerRecordChangedError(error) {
                    serverErrors[recordID] = error
                } else {
                    ckLogger.error("❌ SAVE \(recordType): record error — \(error.localizedDescription)")
                    throw error
                }
            }
        }
        if duplicateDetected {
            // Existing duplicate-merge path (unchanged)
            ckLogger.info("🔄 SAVE \(recordType): duplicate detected, merging")
            let existingRecords = await fetchExistingRecords(ckRecords.map(\.recordID))
            let merged = ckRecords.map { mergeWithExisting($0, existing: existingRecords, nilKeys: nilKeyMap) }
            try await retryModifyRecords(merged, recordType: recordType)
            ckLogger.info("✅ SAVE \(recordType): merge success")
            return
        }
        if !serverErrors.isEmpty {
            ckLogger.info("🔄 SAVE \(recordType): serverRecordChanged for \(serverErrors.count) record(s), merging with server copy")
            let serverCopies = extractServerRecords(from: serverErrors)
            let merged = mergeWithServerRecords(newRecords: ckRecords, serverRecords: serverCopies, nilKeys: nilKeyMap)
            try await retryModifyRecords(merged, recordType: recordType)
            ckLogger.info("✅ SAVE \(recordType): server-merge retry success")
            return
        }
        ckLogger.info("✅ SAVE \(recordType): success")
    } catch {
        // Batch-level throw: could wrap partialFailure with serverRecordChanged inside, or be a duplicate error
        if let perItem = perItemErrors(from: error) {
            let serverChanged = perItem.filter { isServerRecordChangedError($0.value) }
            if !serverChanged.isEmpty {
                ckLogger.info("🔄 SAVE \(recordType): serverRecordChanged in batch (\(serverChanged.count)), merging")
                let serverCopies = extractServerRecords(from: serverChanged)
                let merged = mergeWithServerRecords(newRecords: ckRecords, serverRecords: serverCopies, nilKeys: nilKeyMap)
                try await retryModifyRecords(merged, recordType: recordType)
                ckLogger.info("✅ SAVE \(recordType): server-merge retry success")
                return
            }
        }
        guard isDuplicateRecordError(error) else {
            ckLogger.error("❌ SAVE \(recordType): \(error.localizedDescription)")
            throw mapCKError(error, recordID: nil)
        }
        // existing duplicate flow (unchanged)
        ckLogger.info("🔄 SAVE \(recordType): duplicate detected, merging")
        let existingRecords = await fetchExistingRecords(ckRecords.map(\.recordID))
        let merged = ckRecords.map { mergeWithExisting($0, existing: existingRecords, nilKeys: nilKeyMap) }
        try await retryModifyRecords(merged, recordType: recordType)
        ckLogger.info("✅ SAVE \(recordType): merge success")
    }
    ```

    Add these two private helpers:

    ```swift
    /// Pulls CKRecordChangedErrorServerRecordKey out of each serverRecordChanged CKError.
    private func extractServerRecords(from errors: [CKRecord.ID: Error]) -> [CKRecord.ID: CKRecord] {
        var map: [CKRecord.ID: CKRecord] = [:]
        for (id, error) in errors {
            guard let ckError = error as? CKError,
                  let server = ckError.userInfo[CKRecordChangedErrorServerRecordKey] as? CKRecord
            else { continue }
            map[id] = server
        }
        return map
    }

    /// Final retry step — runs modifyRecords once and throws mapCKError on any per-record failure.
    /// Bounded retry: caller must not invoke this in a loop.
    private func retryModifyRecords(_ records: [CKRecord], recordType: String) async throws {
        let (savedRecords, _) = try await database.modifyRecords(saving: records, deleting: [])
        for (recordID, result) in savedRecords {
            if case .failure(let error) = result {
                throw mapCKError(error, recordID: recordID)
            }
        }
    }
    ```

    Apply the SAME serverRecordChanged detection + merge to `saveFromJSON()` (lines ~206-260). For saveFromJSON, there is no nilKeyMap — pass `[:]`. This means after the existing duplicate block, add a parallel serverRecordChanged block using the same helpers.

    Constraints:
    - Do NOT change the public save() or saveFromJSON() signatures.
    - Do NOT remove the existing duplicate-insert branch — it handles a different CKError (`.serverRejectedRequest` with "record to insert already exists" string).
    - Preserve all existing ckLogger calls.
    - Retry is bounded to exactly ONE attempt. If the retry fails, throw mapCKError.
    - `CKRecordChangedErrorServerRecordKey` and `CKPartialErrorsByItemIDKey` are CloudKit constants — no imports needed beyond the existing `import CloudKit`.
  </action>
  <verify>
    <automated>cd /Users/dustinober/Projects/sundee-fundee/SundeeFundeeApp && xcodebuild -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build 2>&1 | tail -50 | grep -E "(BUILD SUCCEEDED|error:)" &amp;&amp; cd /Users/dustinober/Projects/sundee-fundee/SundeeFundee &amp;&amp; swift test --filter DataLayerTests 2>&1 | tail -30</automated>
  </verify>
  <done>
    - Build succeeds on iOS 17 Pro simulator destination with zero Swift errors or new warnings.
    - `DataLayerTests` target passes (DataErrorTests, existing SyncQueueTests, MockCloudKitClient-backed tests — the real CloudKitClient tests are commented out per CloudKitClientTests.swift line 11 and will stay that way).
    - `git diff` on CloudKitClient.swift shows: new private helpers `isServerRecordChangedError`, `perItemErrors`, `mergeWithServerRecords`, `extractServerRecords`, `retryModifyRecords`; save() and saveFromJSON() catch blocks updated; existing duplicate-merge path untouched.
    - File committed: `git(scope): fix(cloudkit): handle CKError.serverRecordChanged with server-merge retry`.
  </done>
</task>

<task type="auto" tdd="true">
  <name>Task 2: Serialize SettingsViewModel.saveSettings to eliminate parallel-save race</name>
  <files>SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Settings/SettingsView.swift</files>
  <behavior>
    - Rapid changes across the four onChange handlers (weightUnit, experienceLevel, primaryGoal, cycleTrackingEnabled) produce AT MOST ONE in-flight save to CloudKit at a time.
    - When a new change fires while a save is pending/running, the pending save is cancelled (or coalesced) and a new save is scheduled reflecting the LATEST state.
    - If the user makes N quick changes, the final server state equals the last change, not some interleaved mix.
    - saveSettings continues to surface errorMessage on failure (behavior unchanged).
    - No busy-wait loops; uses Task handle + cancellation (structured concurrency idiom).
  </behavior>
  <action>
    Edit `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Settings/SettingsView.swift`.

    1. In `SettingsViewModel` (class body at line 611), add a cancellable task handle property:

    ```swift
    /// Holds the in-flight save task, if any. New writes cancel the pending one
    /// so only the latest state is committed. Prevents CloudKit "client oplock"
    /// conflicts from rapid toggles.
    private var saveTask: Task<Void, Never>?
    ```

    2. Replace the current `saveSettings()` method (lines 651-667) with a debounced/coalescing wrapper. Keep the underlying save logic, but wrap it:

    ```swift
    /// Schedules a save of the current settings. If another save is pending or
    /// in-flight, it is cancelled and superseded by this one. Ensures only the
    /// latest state is committed and prevents parallel saves from racing the
    /// server's changeTag.
    func saveSettings() async {
        guard hasLoaded else { return }
        // Cancel any in-flight save — the new one will use the latest @Published values
        saveTask?.cancel()

        let task = Task { @MainActor [weak self] in
            guard let self else { return }
            // Small coalescing window: if another onChange fires within 150ms,
            // it cancels this task before the actual save runs.
            try? await Task.sleep(nanoseconds: 150_000_000)
            if Task.isCancelled { return }

            self.isSaving = true
            let record = UserSettingsRecord(
                cycleTrackingEnabled: self.cycleTrackingEnabled,
                weightUnit: self.weightUnit.rawValue,
                experienceLevel: self.experienceLevel.rawValue,
                primaryGoal: self.primaryGoal.rawValue
            )
            do {
                try await self.dataClient.save(record, recordType: "UserSettings")
            } catch {
                if !Task.isCancelled {
                    self.errorMessage = "Failed to save settings: \(error.localizedDescription)"
                }
            }
            if !Task.isCancelled {
                self.isSaving = false
            }
        }
        saveTask = task
        await task.value
    }
    ```

    3. The onChange handlers at lines 90-93 need NO textual change — they already `Task { await viewModel.saveSettings() }`. The new saveSettings internally cancels-and-replaces.

    Rationale for the 150ms coalescing sleep: the four .onChange handlers can fire within a single runloop tick when user taps a segmented picker; the sleep gives later onChanges a chance to cancel earlier ones so only ONE actual network call happens. If the user waits >150ms between toggles, each gets its own save (expected). 150ms is imperceptible but longer than SwiftUI's onChange batching.

    Constraints:
    - `@MainActor` class — the new `saveTask` property is isolated to MainActor automatically.
    - Swift 6 strict concurrency: the Task closure captures `[weak self]` to avoid retain cycle. `@MainActor` on the closure ensures self's @Published mutations are main-thread.
    - Do NOT change the public API of saveSettings — it stays `func saveSettings() async`.
    - Do NOT add a deinit — saveTask cancels itself on the next saveSettings call; the old task being a detached structured task will clean up naturally.
    - Keep `hasLoaded` gate — no saves before initial load completes (prevents clobbering server state with defaults on fresh install).
  </action>
  <verify>
    <automated>cd /Users/dustinober/Projects/sundee-fundee/SundeeFundeeApp && xcodebuild -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build 2>&1 | tail -20 | grep -E "(BUILD SUCCEEDED|error:|warning:)" &amp;&amp; cd /Users/dustinober/Projects/sundee-fundee/SundeeFundee &amp;&amp; swift test --filter DataLayerTests 2>&1 | tail -10</automated>
  </verify>
  <done>
    - Build succeeds with zero new errors or Swift 6 strict concurrency warnings.
    - `git diff` on SettingsView.swift shows: new `private var saveTask: Task<Void, Never>?` property, rewritten `saveSettings()` with cancel-and-replace + 150ms coalescing sleep, onChange handlers unchanged.
    - Existing DataLayerTests still pass (no SettingsViewModel-specific tests exist currently — acceptable for a quick fix; the save-debounce behavior is observable via manual testing of rapid picker toggles).
    - File committed: `fix(settings): serialize saveSettings with cancellable task to prevent parallel-save race`.
  </done>
</task>

</tasks>

<verification>
Overall phase checks (run after both tasks complete):

1. Full app build:
   ```
   cd /Users/dustinober/Projects/sundee-fundee/SundeeFundeeApp && xcodebuild -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
   ```
   Must end in `BUILD SUCCEEDED`.

2. Unit tests:
   ```
   cd /Users/dustinober/Projects/sundee-fundee/SundeeFundee && swift test --filter DataLayerTests
   ```
   All existing tests pass; no regressions in SyncQueue or DataError tests.

3. SwiftLint (optional, if CI runs it):
   ```
   swiftlint --config .swiftlint.yml SundeeFundee/Sources/SundeeFundeeKit/DataLayer/Actors/CloudKitClient.swift SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Settings/SettingsView.swift
   ```
   Zero new violations (force_unwrapping, implicitly_unwrapped_optional).

4. Manual smoke (not required for plan completion; for developer awareness):
   - Launch on simulator, go to Settings, rapidly toggle weight unit + experience level within 1 second. No error alert. Console logs show at most one "💾 SAVE UserSettings" per 150ms+ gap.
   - With a real multi-device iCloud account: change a setting on device A, then on device B before A's CloudKit push lands on B. Device B's save should log "🔄 SAVE UserSettings: serverRecordChanged ... merging with server copy" then "✅ SAVE UserSettings: server-merge retry success" — no user-visible error.
</verification>

<success_criteria>
- [ ] CloudKitClient.save() catches CKError.serverRecordChanged (both top-level and inside CKError.partialFailure) and retries once using the server-returned CKRecord
- [ ] CloudKitClient.saveFromJSON() has matching serverRecordChanged handling for SyncQueue replays
- [ ] Existing duplicate-on-insert merge path still functions (verified by existing code paths being preserved, not rewritten)
- [ ] SettingsViewModel holds a single Task handle; new saves cancel pending ones
- [ ] 150ms coalescing window ensures rapid onChange fires collapse to one network call
- [ ] Build passes on iPhone 17 Pro simulator with zero new errors/warnings
- [ ] swift test --filter DataLayerTests passes
- [ ] Both files committed individually (per project Git Workflow: commit each file separately with `type(scope): description` format)
</success_criteria>

<output>
After completion, create `.planning/quick/260416-qbs-fix-cloudkit-oplock-error-handle-serverr/260416-qbs-SUMMARY.md` capturing:
- The exact diff shape for both files (helper names added, catch-block structure)
- Why 150ms was chosen for the coalesce window
- Confirmation that CKRecordChangedErrorServerRecordKey + CKPartialErrorsByItemIDKey usage is documented Apple API (not private)
- Any unexpected build warnings encountered and how resolved
</output>
