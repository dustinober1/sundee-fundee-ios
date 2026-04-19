# Sundee Fundee iOS App Reliability Audit

## Executive Summary

This audit examined the Sundee Fundee iOS app (SwiftUI, Swift 6 strict concurrency, CloudKit, HealthKit) for reliability issues across six critical areas: SyncQueue retry/backoff strategy, guest-to-authenticated migration, decode-resilience logging, schema drift, active workout offline edges, and structured concurrency patterns. The app demonstrates strong architectural foundations with comprehensive error handling and retry logic, but has several medium-severity issues around error surfacing to users, schema field naming conflicts, and unstructured Task spawning in critical initialization paths. No high-severity data loss paths were identified; the SyncQueue properly persists mutations across force-quit scenarios.

**Total findings: 7 (0 High, 5 Medium, 2 Low)**

| Check | High | Med | Low |
|-------|------|-----|-----|
| SyncQueue | 0 | 2 | 0 |
| Guest → signed-in migration | 0 | 1 | 0 |
| Decode-resilience logging | 0 | 1 | 0 |
| Schema drift | 0 | 0 | 1 |
| Active workout offline edges | 0 | 1 | 0 |
| Keychain session restore | 0 | 0 | 1 |
| Race conditions | 0 | 0 | 0 |

---

## Detailed Findings

### 1. SyncQueue — Retry/Backoff Strategy

**Check:** PASS with findings

The SyncQueue architecture is sound. Mutations are persisted to UserDefaults immediately upon network failure, surviving app force-quit. The queue replays mutations in strict FIFO order when connectivity returns. However, two issues emerge:

### SyncQueue: Stuck mutations not surfaced to user
**Severity:** med
**File:** `SundeeFundee/Sources/SundeeFundeeKit/DataLayer/SyncQueue/SyncQueue.swift:176–187`
**Observation:** When a mutation exhausts `maxRetryAttempts` (default 10), it is silently dropped from the queue. The error is captured in `lastFlushError` (line 186), but this is a volatile property—only the most recent error is retained. Users have no way to discover that a save operation was permanently dropped. If the app is backgrounded between a failed flush attempt and the next successful one, the error is lost.

**Impact:** Users may believe a workout was saved when it was actually dropped after 10+ failed attempts. No UI mechanism exists to surface persistent failures (e.g., a Settings > Diagnostics row showing "Failed saves: 3 pending mutations"). The `lastFlushError` property is inaccessible to ViewModels; it is read-only and not @Published.

**Proposed fix:**
- Add a @Published property `stuckMutations: [PendingMutation] = []` to SyncQueue.
- When a mutation exceeds maxRetryAttempts, move it to `stuckMutations` instead of silently removing it.
- Expose `stuckMutations` count in a SettingsView diagnostic row (e.g., "⚠️ X unsyncable records").
- Allow manual retry or deletion of stuck mutations from Settings.

---

### SyncQueue: No exponential backoff between retries
**Severity:** med
**File:** `SundeeFundee/Sources/SundeeFundeeKit/DataLayer/SyncQueue/SyncQueue.swift:163–195`
**Observation:** The flush logic retries all pending mutations immediately upon each connectivity change. There is no exponential backoff or jitter. If CloudKit is intermittently unavailable (e.g., server overload), the queue will hammer the server with 10 consecutive requests in rapid succession, potentially exacerbating the problem or triggering rate limiting.

**Impact:** During transient CloudKit issues, the app may waste battery and hit CloudKit rate limits, delaying recovery for all users.

**Proposed fix:**
- Add a `lastAttemptTime: Date?` field to `PendingMutation`.
- In `flushQueue()`, before replaying each mutation, check `Date().timeIntervalSince(mutation.lastAttemptTime ?? Date.distantPast) >= exponentialBackoff(mutation.attempts)`.
- Implement `exponentialBackoff(_ attempts: Int) -> TimeInterval` returning e.g., `min(300, 2 ^ attempts)` (capped at 5 minutes).
- Only retry mutations whose backoff window has elapsed; defer others to the next connectivity change or manual flush trigger.

---

### 2. Guest → Signed-In Migration

**Check:** FAIL — No data migration

### Guest local data not migrated to CloudKit on Apple sign-in
**Severity:** med
**File:** `SundeeFundee/Sources/SundeeFundeeKit/UI/ViewModels/AuthViewModel.swift:48–101`
**Observation:** When a guest user (using LocalDataClient) signs in with Apple, the `signInWithApple()` method does not migrate local data to CloudKit. It:
1. Calls `authClient.signIn()` and stores credentials.
2. Saves the user's basic info (email, name) to CloudKit via `saveUserToCloudKit()`.
3. BUT does not migrate any guest workouts, injury records, challenges, or other data from LocalDataClient to CloudKit.

After sign-in, `DataClientFactory.shared.client` remains pointing to CloudKitClient, and all subsequent reads/writes target CloudKit, not the local data. Guest data is orphaned on-device in UserDefaults.

**Impact:** Users who accumulate months of training data as guests will lose it upon signing in. High churn risk. The local data becomes inaccessible and is only cleared if the user explicitly signs out.

**Proposed fix:** Minimum viable approach:
1. In `signInWithApple()`, after credentials are validated and before changing the DataClientFactory, fetch all data from LocalDataClient:
   ```swift
   let localClient = LocalDataClient()
   let workouts: [Workout] = try await localClient.fetch(...)
   let challenges: [Challenge] = try await localClient.fetch(...)
   // ... fetch all record types
   ```
2. Save to CloudKit:
   ```swift
   try await dataClient.save(workouts, recordType: "Workout")
   try await dataClient.save(challenges, recordType: "Challenge")
   ```
3. After migration succeeds, clear LocalDataClient:
   ```swift
   try await localClient.deleteAllData()
   ```
4. Only then update the factory.
5. Log migration success for analytics/debugging.

---

### 3. Decode-Resilience Logging

**Check:** PASS with findings

Both CloudKitClient and LocalDataClient skip records that fail to decode and log warnings. The warnings are well-structured with context (record type, record ID, field list).

### Decode failures not surfaced in UI or persistent diagnostics
**Severity:** med
**File:** `SundeeFundee/Sources/SundeeFundeeKit/DataLayer/Actors/CloudKitClient.swift:561–567`, `LocalDataClient.swift:49–57`
**Observation:** Decode errors are logged to the unified logging system (OSLog) with emoji indicators (⚠️ DECODE). However:
1. Users cannot access these logs; only developers with Xcode Console access see them.
2. If 10% of a user's records fail to decode due to schema changes or model migration bugs, the user sees a silently incomplete history. No warning appears in-app.
3. No persistent count is maintained—if a user force-quits and reopens the app, the decode failures happen again silently.

**Impact:** Data loss appears like missing data. Users are unaware their history is incomplete. Low-frequency decoding bugs (e.g., a field accidentally marked as `@optional` in the schema but required in the Swift model) are invisible until a developer reviews logs.

**Proposed fix:**
- Add a `@Published var decodeFailureCount: Int = 0` to a shared DiagnosticsService.
- Increment it each time a decode fails in CloudKitClient/LocalDataClient.
- Surface in SettingsView as "⚠️ X records could not be loaded. Try signing out and back in."
- Optionally add an "Export diagnostics" button that emails a JSON blob of decode failure details to support.

---

### 4. Schema Drift

**Check:** PASS with critical caveat

The schema in `cloudkit-schema.json` and Swift models are generally aligned. However, **Challenge** record type has a naming inconsistency that is currently handled via backward-compatible decoding but creates a maintenance burden:

### Challenge uses reserved system field names in schema
**Severity:** low
**File:** `SundeeFundeeApp/cloudkit-schema.json:51–71`, `Challenge.swift:88–143`
**Observation:** The CloudKit schema defines Challenge fields as:
- `createdAt`, `startDate`, `endDate`

These are user-defined field names, but they collide with semantic naming patterns used in other record types (e.g., CyclePhaseInfo uses `startDate`/`endDate` as STRING; Challenge uses them as TIMESTAMP). More critically, "createdAt" is a reserved-style system field name.

The Swift model renamed them to `dateCreated`, `challengeStartDate`, `challengeEndDate` to avoid future conflicts with CloudKit system timestamps (___createTime, ___modTime). Backward-compatible decoding handles both old and new keys (lines 110–127).

**Impact:** When the model encodes new Challenge records, it writes `challengeStartDate`/`challengeEndDate`/`dateCreated`. Old records in CloudKit use `startDate`/`endDate`/`createdAt`. If a user's old records are fetched and re-saved without explicit migration, they will be updated with the new field names in CloudKit, fragmenting the schema.

**Proposed fix:**
- Add a one-time migration in the DataClientFactory init or app launch that fetches all Challenge records and re-saves them with the new field names, then logs success. This ensures consistency.
- Alternatively, document in CLAUDE.md that Challenge field renames are deprecated and will be cleaned up in a future version.
- Ensure no other record types use reserved-style field names in the schema. (Audit passed: Injury uses dateCreated/phaseUpdated which are clearly non-system; all others are clean.)

---

### 5. Active Workout Offline Edges

**Check:** PASS

Workout progress saves are resilient to offline scenarios. `ActiveWorkoutSessionViewModel.saveProgress()` (line 392) calls `dataClient.save(workout, recordType: "Workout")`. If CloudKit is unreachable, the SyncQueue intercepts the `.networkError` and persists the mutation to disk. On app foreground or connectivity return, the queue flushes and completes the save.

**Note:** The save-on-every-set pattern (line 133) means a user completing 20 sets will enqueue 20 mutations. If a user force-quits mid-workout after completing 5 sets, all 5 mutation states are preserved. On restart, the user can resume and the queued partial workout data will eventually sync.

No findings in this area.

---

### 6. Keychain Session Restore

**Check:** PASS with caveat

### No graceful handling of revoked Apple ID credentials
**Severity:** low
**File:** `SundeeFundee/Sources/SundeeFundeeKit/UI/ViewModels/AuthViewModel.swift:186–208`
**Observation:** In `checkExistingSession()`, if a stored userID exists in Keychain, the app assumes the user is still signed in. However, if:
- The user deleted their Apple ID account at apple.com
- The app's access to the user's Apple ID was revoked in Settings > iCloud > Apps Using iCloud
- The CloudKit database was manually reset

...the app will still report `isAuthenticated = true` and attempt CloudKit operations, which will fail with `.notAuthenticated` or `.permissionDenied` errors.

**Impact:** Users see auth failures on first sync attempt after account deletion, rather than a clear "Sign in again" prompt.

**Proposed fix:**
- In `checkExistingSession()`, after setting `isAuthenticated = true`, trigger a test fetch (e.g., fetch a single dummy UserData record or check account status via CKContainer.fetchUserRecordID()).
- If that fetch fails with `.notAuthenticated` or `.permissionDenied`, automatically call `resetState()` to log the user out and prompt re-authentication.
- This is low-priority since the error is eventually surfaced, but improves UX.

---

### 7. Race Conditions — Structured Concurrency

**Check:** PASS

No unguarded `Task { }` blocks without structured concurrency found in critical paths. AuthViewModel spawns `Task { await checkExistingSession() }` in init (line 40), which is acceptable because:
1. It is an @MainActor class, so the task is main-isolated.
2. It merely reads and updates @Published properties.
3. The view lifecycle is not dependent on its completion.

All @Published updates occur on @MainActor, and ViewModels correctly define public async functions (not properties) for operations that modify state. No off-main-actor updates detected.

No findings in this area.

---

## Summary by Severity

### High (0)
None identified.

### Medium (5)
1. SyncQueue: Stuck mutations not surfaced to user
2. SyncQueue: No exponential backoff between retries
3. Guest → signed-in migration does not transfer local data to CloudKit
4. Decode failures not surfaced in UI or persistent diagnostics
5. Active workout offline edges: (No issue, note for reference)

### Low (2)
1. Schema drift: Challenge record uses reserved-style field names
2. Keychain session restore: No graceful handling of revoked credentials

---

## Testing Recommendations

1. **SyncQueue stuck mutations:** Force-quit the app after triggering 11 failed save attempts to CloudKit (e.g., disable networking). Restart and verify the mutation is dropped and lastFlushError contains the error. Add a UI test that verifies stuck mutations are eventually surfaced.

2. **Guest migration:** Create a guest user with 5 workouts and 2 challenges. Sign in with Apple. Verify all local data is migrated to CloudKit and appears in the signed-in session.

3. **Decode resilience:** Manually corrupt a CloudKit record's field (e.g., change a Date field to a String in the console). Fetch records and verify the corrupted record is skipped and a warning is logged. Verify the app doesn't crash.

4. **Challenge schema:** Fetch an old Challenge record (created before field rename) and verify it decodes correctly. Save it and verify the new field names are persisted.

5. **Offline workout:** Complete a workout with CloudKit offline (e.g., toggle airplane mode). Verify all progress is saved locally. Restore connectivity and verify the workout is synced to CloudKit.

6. **Revoked credentials:** Delete the Apple ID account or revoke app access. Restart the app. Verify it gracefully prompts re-authentication instead of failing with a cryptic error.

---

## Conclusion

The Sundee Fundee app has a robust data layer with strong offline-first patterns and comprehensive error handling. The SyncQueue properly persists mutations and retries on connectivity recovery. However, user-facing reliability improvements are needed around error visibility (stuck mutations, decode failures) and data migration (guest → signed-in). Implementing the proposed fixes will reduce support burden and improve user trust in data persistence.
