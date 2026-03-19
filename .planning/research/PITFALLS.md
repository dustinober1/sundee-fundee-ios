# Pitfalls Research

**Domain:** iOS + watchOS native strength training app (SwiftData + CloudKit + StoreKit 2 + APNs)
**Researched:** 2026-03-18
**Confidence:** HIGH (critical pitfalls backed by Apple Developer Forums, fatbobman.com, and official docs)

---

## Critical Pitfalls

### Pitfall 1: CloudKit Schema Not Deployed to Production Before First Release

**What goes wrong:**
CloudKit sync works perfectly in Xcode debug builds and Development environment, but fails silently once the app is distributed through TestFlight or the App Store. Users see no sync, no iCloud backup, and no error — data simply stays local. This is the most reported first-time CloudKit failure mode.

**Why it happens:**
CloudKit maintains separate Development and Production environments. In Development, CloudKit uses JIT (Just-In-Time) schema creation — it automatically creates record types the first time you write them. The Production environment has no JIT; the schema must be manually deployed from the CloudKit Console. App Store and TestFlight builds use Production by default.

**How to avoid:**
Before every release that adds or changes models: log into the Apple Developer Portal, navigate to CloudKit Console → Schema → Deploy Schema Changes, and click Deploy. Add this as a mandatory pre-release checklist step. Automate validation with a CI check that confirms schema version matches expected state.

**Warning signs:**
- Sync works on development device, breaks on TestFlight device
- No sync errors thrown, just silent local-only behavior
- CloudKit Console shows record types in Development but not Production

**Phase to address:**
Phase: CloudKit Activation (the bug-fix milestone). Must complete schema deployment before any TestFlight distribution. Do not skip even for internal testing.

---

### Pitfall 2: Activating CloudKit on the Existing Local Store Causes Boot-Time Migration Crash

**What goes wrong:**
The existing codebase has 12 schema versions accumulated under a local persistent store (never synced). When `useCloudKit` is flipped to `true`, NSPersistentCloudKitContainer attempts to initialize CloudKit before executing the migration plan. If any model in V1–V11 violates CloudKit's requirements (non-optional property, unique constraint, Deny delete rule), the container fails to load at boot, the app crashes, and production data is inaccessible.

**Why it happens:**
`AppModelContainer.makeSharedContainer` does not pass `migrationPlan: AppSchemaMigrationPlan.self` on the `.localPersistent` path. Additionally, the CloudKit container initialization validates model compatibility before migration runs, meaning models that will be fixed in V12 are still checked against CloudKit rules at their old definitions during the transition launch.

**How to avoid:**
1. Add `migrationPlan: AppSchemaMigrationPlan.self` to the `.localPersistent` container path immediately (CONCERNS.md bug fix).
2. Audit all models in V12 for CloudKit compatibility before flipping the flag (all attributes must be optional or have defaults; no `@Attribute(.unique)`; no `.deny` delete rules; all relationships optional with inverses defined).
3. Implement the fallback pattern: attempt to load container with CloudKit enabled; if it throws, disable CloudKit and load local-only for that launch, then retry on next launch after migration completes.
4. Test the migration path on a device with V1 data installed, not just a fresh install.

**Warning signs:**
- App crashes on first launch after update on devices that had the old version installed
- "CloudKit integration requires that all attributes be optional" error in logs
- Container load fails between `willMigrate` and `didMigrate` callbacks

**Phase to address:**
Phase: CloudKit Activation. Must audit and fix model compatibility before enabling the flag.

---

### Pitfall 3: CloudKit Enforces Add-Only Schema After First Production Deployment

**What goes wrong:**
After CloudKit sync is live in production, renaming an entity or attribute causes CloudKit to interpret it as "delete old, create new." Existing user records mapped to the old name become orphaned. Users lose data silently during migration. The schema cannot be rolled back once deployed.

**Why it happens:**
CloudKit's distributed nature means schema changes must be backwards-compatible forever. CloudKit has no concept of a "rename" operation at the server level — a rename in the local model is indistinguishable from adding a new field and removing an old one.

**How to avoid:**
Follow the Add-Only Protocol from the moment CloudKit is activated:
- Never delete an existing entity or attribute from the model definition, even if deprecated in code
- Never rename an entity or attribute; add a new one with the new name instead
- Never change an attribute's data type
- For deprecations: mark the Swift property with `@available(*, deprecated)` and stop writing to it, but keep the model definition

**Warning signs:**
- Schema migration involves an entity or attribute rename
- "Deleting" a model type that should become a new type
- Schema diff shows removals alongside additions

**Phase to address:**
Phase: CloudKit Activation and all subsequent phases with schema changes. Establish the Add-Only rule before first production CloudKit deployment.

---

### Pitfall 4: Silent Data Store Deletion on Migration Failure

**What goes wrong:**
`AppModelContainer.deleteStoreFiles` silently wipes all `.store`, `.store-wal`, and `.store-shm` files if the persistent store fails to open (e.g., corrupted write, schema mismatch during CloudKit activation). The user launches the app and finds all their workout history, cycle logs, and 1RM records gone, with no warning.

**Why it happens:**
The fallback is intentional for development convenience but has no production safeguards. There are zero tests covering this path (CONCERNS.md confirms). A failed CloudKit activation attempt — which causes a container open failure — could trigger this path on a device with years of user data.

**How to avoid:**
Before enabling CloudKit, add a mandatory user-facing alert before `deleteStoreFiles` is called:
1. Show alert: "We encountered a problem opening your data. Continuing will erase local data. If iCloud sync is enabled, your data can be restored."
2. Copy the corrupt store files to a temp location for diagnostics before deletion
3. Add a unit test that exercises the fallback deletion path
4. Only call `deleteStoreFiles` after explicit user confirmation in production builds

**Warning signs:**
- App opens to blank state with no explanation
- `AppModelContainer` logs show container initialization failure followed by store deletion
- No test coverage on the error recovery path (use this as a CI gate)

**Phase to address:**
Phase: CloudKit Activation (bug fixes). Fix before flipping the CloudKit flag so the safeguard is in place if activation causes a boot failure.

---

### Pitfall 5: watchOS Cannot Share SwiftData Store via App Group

**What goes wrong:**
Developers assume App Groups can share a SwiftData container between the iOS app and the watchOS companion, as they do for iOS/widget pairs. The watchOS app gets an empty or stale database. Data entered on the watch never appears on iPhone and vice versa.

**Why it happens:**
App Groups are a same-device mechanism. The iOS app runs on iPhone; the watchOS app runs on Apple Watch. These are separate devices on separate file systems. An App Group container cannot span devices. This has been confirmed as unsupported since watchOS 2.0. SwiftData + CloudKit iCloud sync theoretically bridges the gap but is slow and unreliable on watchOS (reported as not arriving on Apple Watch in community testing with iOS ↔ iPad successfully syncing).

**How to avoid:**
Use WatchConnectivity (`WCSession`) as the primary real-time sync channel between iOS and watchOS:
- Workout data logged on watch → `transferUserInfo` (queued, delivered when reachable) or `sendMessage` (real-time, requires both apps active)
- Use `SyncStatus` property on workout records (`.pending`, `.synced`, `.conflict`) to drive retry logic
- Treat the watch as a thin client that writes locally and pushes to iPhone; iPhone is the authoritative store
- CloudKit can serve as eventual-consistency fallback, not primary sync channel

**Warning signs:**
- Data logged on watch does not appear on iPhone even after hours
- Attempting to use `containerURL(forSecurityApplicationGroupIdentifier:)` from the watch target
- Watch app ModelContainer pointing at a shared group URL

**Phase to address:**
Phase: watchOS Companion App. Architect the sync strategy before writing any watch data persistence code.

---

### Pitfall 6: WatchConnectivity Delegate Methods Silently Never Fire

**What goes wrong:**
WCSession messages sent from the watch appear to succeed (no error callbacks), but the iOS app never receives them. Workout data sent during a session is lost. This affects roughly 5% of workout sessions and has been reported as staying broken for the entire workout once it starts.

**Why it happens:**
WCSession requires both apps to have activated their sessions before messages can flow. If the iOS app is not running, `sendMessage` fails (it requires both to be active simultaneously). `transferUserInfo` is queued and more reliable but has no delivery guarantee window. The `HKWorkoutSession.sendToRemoteWorkoutSession` variant has a known bug where the async method never returns in some cases.

**How to avoid:**
- Use `transferUserInfo` instead of `sendMessage` for non-latency-critical data (workout sets, metrics)
- Use `sendMessage` only for real-time UI feedback (active set timer, live heart rate) with fallback on failure
- Wrap all WCSession calls in a manager that queues messages when not reachable and retries on `sessionReachabilityDidChange`
- Implement a reconciliation sync at workout completion: send a full workout summary regardless of incremental message success
- Add error logging for `transferUserInfo` failures; surface them to users as "sync pending"

**Warning signs:**
- WCSession delegate methods not implemented on both sides
- No fallback or retry logic on `sendMessage`
- No reconciliation pass at workout end

**Phase to address:**
Phase: watchOS Companion App.

---

### Pitfall 7: HKWorkoutSession Not Recovered After Watch App Crash or Reboot

**What goes wrong:**
A user starts a workout on Apple Watch, the watch crashes or reboots mid-workout (e.g., forced restart due to low battery), and all in-progress workout data is lost. The `handleActiveWorkoutRecovery` delegate method is not called after a device reboot — only after a crash.

**Why it happens:**
`handleActiveWorkoutRecovery` on `WKExtensionDelegate` is called for crash recovery but is explicitly not called after device reboot. Apple's documentation notes that developers must manually call `HKHealthStore().recoverActiveWorkoutSession` during `applicationDidFinishLaunching` to handle the reboot case. Custom metrics (sets, reps, load) accumulated before the crash are not part of HealthKit's recovery data — only standard HealthKit data types survive.

**How to avoid:**
- Call `HKHealthStore().recoverActiveWorkoutSession` in `applicationDidFinishLaunching`, not just in `handleActiveWorkoutRecovery`
- Periodically checkpoint workout state (sets completed, current exercise, elapsed time) to local SwiftData on the watch during a session
- On recovery, restore custom metrics from the checkpoint before resuming the HealthKit session
- Show a recovery UI to the user ("We recovered your workout — here's what we saved")

**Warning signs:**
- No checkpoint save during active workout session
- Recovery relies solely on `handleActiveWorkoutRecovery` without the `applicationDidFinishLaunching` check

**Phase to address:**
Phase: watchOS Companion App.

---

### Pitfall 8: StoreKit 2 Cold Launch Tier Elevation Window

**What goes wrong:**
A lapsed subscriber (or a user whose subscription was revoked) sees premium features for several seconds on every cold launch. The subscription tier is read from `UserDefaults` before `loadStatus()` completes. In the window before server verification, the cached `.pro` tier grants access. CONCERNS.md confirms this is already the behavior in the existing codebase.

**Why it happens:**
`SubscriptionService.init` reads the cached tier from `UserDefaults` synchronously for instant UI rendering, which is a reasonable DX tradeoff. But when the subscription has lapsed between launches, the stale cache is wrong until the async `loadStatus()` call completes.

**How to avoid:**
- Treat the cached tier as `.free` at cold launch until `isStatusLoaded` becomes true
- Use a `subscriptionService.isStatusLoaded` gate before rendering any premium-gated UI
- Display a loading state on the paywall/premium features until verification completes (usually < 1s)
- `Transaction.currentEntitlements` in StoreKit 2 is device-verified and should be the authoritative source, not `UserDefaults`

**Warning signs:**
- `currentTier` read from `UserDefaults` used directly in premium feature gating
- No `isStatusLoaded` check on any gated view
- `UserDefaults` used as source-of-truth rather than as a performance hint

**Phase to address:**
Phase: Bug fixes milestone (directly listed in CONCERNS.md).

---

### Pitfall 9: StoreKit 2 Transaction Listener Not Started at App Launch

**What goes wrong:**
Transactions delivered while the app is not running (subscription renewal, family sharing grant, refund) are missed. The user's entitlement state falls out of sync with App Store records. Users with valid subscriptions are locked out; refunded users retain access.

**Why it happens:**
`Transaction.updates` is an async stream that must be observed with a long-lived `Task` started at app launch. If the listener is started after a delay, or only on the paywall screen, any transactions that arrived while the app was backgrounded or killed are not processed until the stream is observed.

**How to avoid:**
- Start `Transaction.updates` listener in `@main App.init()` or in `AppState.init()`, before the first view renders
- Store a reference to the `Task` to prevent deallocation
- Call `Transaction.currentEntitlements` on launch as the reconciliation pass (handles transactions missed while listener was not running)
- Do not use the deprecated `Transaction.currentEntitlement(for:)` — use `Transaction.currentEntitlements(for:)` which handles Family Sharing multiple-entitlement scenarios

**Warning signs:**
- `Transaction.updates` listener started in a view's `onAppear`
- No stored `Task` reference (listener silently deallocated)
- No `currentEntitlements` reconciliation on cold launch

**Phase to address:**
Phase: Bug fixes milestone (subscription cache concern in CONCERNS.md). Verify listener lifecycle at the same time.

---

### Pitfall 10: iOS Privacy Permission Change Kills Watch App with SIGKILL

**What goes wrong:**
A user grants or denies a privacy permission on iPhone (HealthKit, notifications, location) while the Apple Watch app is running. The Watch app is immediately terminated with SIGKILL, mid-workout. Any unsaved state is lost.

**Why it happens:**
watchOS enforces that any privacy authorization change on the paired iPhone invalidates the Watch app's running context. This is an OS-level SIGKILL that cannot be caught or handled.

**How to avoid:**
- Checkpoint workout state to SwiftData on the watch every time a set is logged (not just at workout end)
- Implement `applicationDidFinishLaunching` recovery as described in Pitfall 7
- Front-load all permission requests on iPhone during onboarding, before the user can start a watch workout, to minimize mid-session authorization prompts
- Do not request HealthKit authorization from within the watch app — always initiate from iPhone

**Warning signs:**
- HealthKit authorization requested lazily (on first use) rather than upfront during onboarding
- No checkpoint mechanism for workout-in-progress state on the watch

**Phase to address:**
Phase: watchOS Companion App. Also: onboarding flow should request all necessary permissions upfront.

---

### Pitfall 11: Swift 6 Strict Concurrency Reveals Hidden Data Races in `@unchecked Sendable` Classes

**What goes wrong:**
The existing codebase has 9 classes marked `@unchecked Sendable` to silence Swift Concurrency errors. These classes hold mutable shared state (`modelContext`, caches) accessed across actor boundaries. Under Swift 6's strict concurrency checking, real data races exist that the compiler is not warning about. Enabling strict concurrency mode reveals hundreds of errors, or worse, the races cause silent data corruption at runtime.

**Why it happens:**
`@unchecked Sendable` is a compiler escape hatch that transfers responsibility for thread safety to the developer. Without `actor` isolation or `Mutex` protection on the shared mutable state, the classes are genuinely not safe — the annotation just suppresses the compiler's ability to detect it.

**How to avoid:**
- Do not use `@unchecked Sendable` on any new classes in this rebuild
- Audit each of the 9 existing `@unchecked Sendable` classes: replace with `actor` isolation for repository types, or `Mutex` (Swift 6 `Synchronization` framework) for lightweight shared-state containers
- Enable Swift 6 strict concurrency mode (`SWIFT_STRICT_CONCURRENCY = complete`) in build settings before the watchOS phase to catch issues before they multiply across two targets
- `ModelContext` must never cross actor boundaries — create new contexts per actor

**Warning signs:**
- New code adding `@unchecked Sendable` to fix compiler errors
- `modelContext` stored as an instance property on a non-main-actor class
- Compiler errors fixed by adding `nonisolated` without understanding the isolation model

**Phase to address:**
Phase: Bug fixes milestone. Address before watchOS is added (adding a second target multiplies the cross-actor boundaries).

---

### Pitfall 12: Stale Schema Reference in Sign-Out Leaves Orphaned Records

**What goes wrong:**
`signOut` and `deleteAccountAndData` iterate `AppSchemaV10.models` to delete all local records. V12 adds `BarbellPreset` and `ExerciseBarMapping`. These records are never deleted on sign-out. When a new user signs in on the same device, they see a contaminated store with a previous user's barbell presets and exercise-bar mappings.

**Why it happens:**
The schema reference was not updated when V11 added new model types. This is a direct consequence of the schema version enum approach — adding models to a new version does not automatically update call sites that reference older version enums.

**How to avoid:**
- Replace `AppSchemaV10.models` with `AppSchemaV12.models` (already used as `allModels` in `AppModelContainer`) immediately
- Add a CI test that verifies `signOut` deletes all record types present in the current schema
- Create a `AppSchema.currentModels` alias that always points to the latest version, so this bug cannot recur on the next schema bump

**Warning signs:**
- Any call site referencing a named schema version for record deletion (should always reference `.currentModels` or latest)
- Missing records from deletion audits after sign-out

**Phase to address:**
Phase: Bug fixes milestone (directly listed in CONCERNS.md).

---

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| `@unchecked Sendable` to silence compiler | Compiles immediately | Real data races silently present; explodes when strict mode enabled or watchOS added | Never — use `actor` instead |
| `userID ?? ""` empty string fallback | No nil handling needed | All guest data keyed to `""` — unrecoverable on sign-in | Never in production |
| `UserDefaults` for subscription tier | Fast sync read on launch | Tier elevation window; readable by jailbroken devices | Only as a non-authoritative hint, never as gate |
| Hardcoded model name string for Gemini | Fast to ship | Silent fallback to offline generator when preview model is deprecated | Acceptable if extracted to a named constant immediately |
| `AppSchemaV10.models` reference in sign-out | No effort to update | Orphaned records from new model types | Never — reference current schema |
| `Data(contentsOf:)` on calling actor for JSON | Simpler code | Blocks main actor during JSON reads; stutters on launch | Acceptable only in background task context |

---

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| CloudKit | Forgetting to deploy schema to Production before TestFlight | Deploy via CloudKit Console before every distribution that adds/changes models |
| CloudKit | Adding `@Attribute(.unique)` to a synced model | Remove all unique constraints; enforce uniqueness in application logic instead |
| CloudKit | Non-optional property without default in synced model | All properties must be `?` or have a `= defaultValue` |
| WatchConnectivity | Using `sendMessage` for workout data when iPhone may be backgrounded | Use `transferUserInfo` for reliability; `sendMessage` only for real-time feedback |
| StoreKit 2 | Reading tier from `UserDefaults` before `loadStatus()` completes | Gate premium UI on `isStatusLoaded`; treat cache as `.free` until verified |
| StoreKit 2 | Starting `Transaction.updates` listener in a view | Start in `@main App.init()` and store the `Task` reference |
| APNs | Assuming silent push notifications are delivered reliably | Silent pushes are best-effort, throttled by iOS; use local notifications for time-critical events (rest timer) |
| HealthKit on watchOS | Requesting authorization from the watch app | Always initiate HealthKit auth from the iPhone app during onboarding |
| Gemini Proxy | Hardcoded preview model name | Extract to a named constant; add distinct error path for model-not-found (HTTP 404) |

---

## Performance Traps

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| 8+ sequential `modelContext.fetch` calls on `@MainActor` in `DashboardViewModel.load` | Dashboard shows blank then snaps in; janky scroll on launch | Concurrent `async let` fetches; move bulk reads to background context | Present now on any device, worse on older hardware |
| `Data(contentsOf:)` for JSON bundles on calling actor | Launch stutter; possible ANR on slow devices | `Task.detached` or `URLSession.data(from:)` for async file read | Present now on any iOS device |
| CloudKit shared workout query fetches unbounded records | List truncates silently at 200 entries | Implement `CKQueryOperation` with `resultsLimit` and cursor pagination | When shared workout template catalog exceeds 200 |
| watchOS: continuous UI refresh during HKWorkoutSession | Battery drains in 4-6 hours during workout | Adaptive refresh: 1Hz when wrist raised, pause when `isLuminanceReduced` | From first watchOS workout session |
| Nested `TabView` in watchOS | Memory leak accumulates during workout | Avoid nesting `TabView` in watchOS targets | Immediate; grows over session duration |
| In-memory cache for bundled programs/WODs (unbounded) | Increased memory footprint as catalog grows | Acceptable now; add LRU cache if catalog exceeds 10MB | When program/WOD catalog grows significantly |

---

## Security Mistakes

| Mistake | Risk | Prevention |
|---------|------|------------|
| Gemini proxy URL unauthenticated — no client token | Any caller can incur Gemini API costs | Add App Attest token or shared secret header; long-term: replace with Firebase Cloud Function |
| Subscription tier in `UserDefaults` | Tier can be modified by jailbroken device to elevate to `.pro` | Acceptable risk given `loadStatus()` verifies on launch; do not use `UserDefaults` value as gate for high-value features |
| `NSPredicate(format:)` in CloudKit query | Fragile if ever moved to SwiftData/SQLite context where injection is possible | Use `NSPredicate` with `%@` substitution (already done); document it as CloudKit-only safe |
| Empty-string `userID` for guest data | Data attribution failure; two guests on same device share records | Generate stable UUID in `AppState.signInAsGuest` on first launch, persist to Keychain |

---

## UX Pitfalls

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| Silent data loss when migration fails (`deleteStoreFiles`) | User loses all workout history, cycle logs, 1RMs with no explanation | Show explicit alert before any store deletion; offer iCloud restore path if available |
| Lapsed subscriber sees premium UI then it disappears | Confusing flicker or access revocation mid-session | Show loading state until verification completes; never grant access on stale cache |
| AI-generated workout shows wrong weights for metric users | Metric user prescribed "135" displayed as kg (is actually lbs) — workouts are dangerous or nonsensical | Fix unit conversion before AI workout feature is active; add unit preference to Gemini system prompt |
| Guest data orphaned on sign-in | User accumulates data as guest, signs in, all history gone | Implement guest UUID strategy; offer data migration prompt on sign-in |
| Watch workout recovery with no explanation | User restarts watch mid-workout, app opens to blank workout | Recovery UI: "We found an interrupted workout — resume?" with summary of recovered sets |
| Enrollment cancelled when CloudKit returns empty on transient error | User loses active program enrollment during brief CloudKit outage | Distinguish "no programs" from "CloudKit fetch failed" — only cancel enrollment on explicit server confirmation |

---

## "Looks Done But Isn't" Checklist

- [ ] **CloudKit activation:** Schema deployed to Production in CloudKit Console — verify by checking Production schema in CloudKit Console, not just Development
- [ ] **CloudKit activation:** Migration plan applied to `.localPersistent` container path — verify in `AppModelContainer.swift` line 94–96
- [ ] **CloudKit models:** All properties optional or have defaults, no `@Attribute(.unique)`, no `.deny` delete rules — verify by attempting container initialization
- [ ] **Sign-out/delete:** References `AppSchemaV12.models` not `AppSchemaV10.models` — verify by creating a user, adding barbell presets, signing out, signing in as new user, confirm no leaked records
- [ ] **Guest mode:** Uses stable UUID from `AppState.signInAsGuest`, not empty string — verify by logging a workout as guest, checking SwiftData `userID` field
- [ ] **StoreKit tier verification:** `currentTier` not read as authoritative before `isStatusLoaded` is true — verify by lapsing a sandbox subscription and cold-launching
- [ ] **StoreKit listener:** `Transaction.updates` task started in `App.init()`, `Task` reference stored — verify by processing a transaction while app is backgrounded
- [ ] **watchOS data sync:** WCSession activated on both sides at app launch, not lazily — verify by sending a message immediately after install
- [ ] **HealthKit auth:** Requested from iPhone during onboarding, not from Watch target — verify entitlement flow in onboarding
- [ ] **HKWorkoutSession recovery:** `recoverActiveWorkoutSession` called in `applicationDidFinishLaunching` on watchOS — verify by force-rebooting watch mid-workout
- [ ] **AI workout weights:** `initializeAISets` converts lbs to kg for metric users — verify unit conversion test passes
- [ ] **APNs registration:** Token rotation handled (new token on reinstall) — verify by reinstalling and sending a push to the old token

---

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| CloudKit schema not in Production | LOW | Deploy schema in CloudKit Console; push a patch release; no code changes required |
| Migration crash on CloudKit activation | HIGH | Revert CloudKit flag in hotfix; audit model compatibility; re-enable in next release |
| Silent store deletion wiped user data | HIGH | If CloudKit was ever enabled: iCloud data may still exist; guide user through CloudKit restore; if never enabled: data is unrecoverable |
| Stale schema ref left orphaned records | LOW | Add one-time migration step in next schema version to delete orphaned `BarbellPreset`/`ExerciseBarMapping` records with mismatched `userID` |
| WatchConnectivity data loss | MEDIUM | Reconciliation sync at next session: compare timestamps and re-send any workout records not confirmed on iPhone |
| StoreKit tier elevation window | LOW | Already mitigated by `loadStatus()` on launch; no data integrity risk, only brief UI flicker |
| HKWorkoutSession recovery failure | MEDIUM | Checkpoint strategy limits loss to one set maximum; surface recovery UI; user manually confirms recovered data |

---

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| CloudKit schema not deployed to Production | CloudKit Activation | Verify Production CloudKit Console schema before first TestFlight build |
| Migration crash on CloudKit activation | CloudKit Activation (Bug Fixes) | Integration test: install V11 build, install V12 with CloudKit enabled, confirm app boots without crash |
| Add-Only schema constraint violated | CloudKit Activation + every subsequent schema phase | Code review gate: no entity/attribute removals or renames in any SwiftData model file |
| Silent store deletion on migration failure | Bug Fixes milestone | Unit test covering `AppModelContainer.deleteStoreFiles` fallback path |
| watchOS App Group sync assumption | watchOS Companion App | Architecture review: confirm no App Group container URL used on watch target |
| WatchConnectivity delegate never fires | watchOS Companion App | Integration test: send workout from watch simulator, confirm receipt on iOS simulator |
| HKWorkoutSession crash recovery | watchOS Companion App | Manual test: force-reboot watch mid-workout, confirm recovery on relaunch |
| iOS privacy permission kills Watch | watchOS Companion App + Onboarding | Front-load all permission grants in onboarding; checkpoint test during HKWorkoutSession |
| StoreKit cold-launch tier elevation | Bug Fixes milestone | Sandbox test: let subscription lapse, cold-launch, confirm premium UI not visible before `isStatusLoaded` |
| StoreKit transaction listener missed | Bug Fixes milestone | Test: process transaction while app is background-killed; confirm entitlement updated on next launch |
| `@unchecked Sendable` data races | Bug Fixes milestone (before watchOS) | Enable `SWIFT_STRICT_CONCURRENCY = complete`; zero new errors in build |
| Stale schema ref in sign-out | Bug Fixes milestone | Integration test: create barbell preset, sign out, confirm it is deleted |
| AI weight unit bug | Bug Fixes milestone | Unit test: `initializeAISets` with metric user returns kg values |
| Guest `userID == ""` | Bug Fixes milestone | Unit test: guest workflow produces non-empty, stable `userID` |

---

## Sources

- [Designing Models for CloudKit Sync: Core Data & SwiftData Rules — fatbobman.com](https://fatbobman.com/en/snippet/rules-for-adapting-data-models-to-cloudkit/)
- [Fixing CloudKit Sync in Production: Deploying Schema — fatbobman.com](https://fatbobman.com/en/snippet/why-core-data-or-swiftdata-cloud-sync-stops-working-after-app-store-login/)
- [Fixing SwiftData & Core Data Sync: initializeCloudKitSchema — fatbobman.com](https://fatbobman.com/en/snippet/resolving-incomplete-icloud-data-sync-in-ios-development-using-initializecloudkitschema/)
- [From YaoYao to Tooboo - watchOS Development Pitfalls and Practical Tips — fatbobman.com](https://fatbobman.com/en/posts/watchos-development-pitfalls-and-practical-tips)
- [Key Considerations Before Using SwiftData — fatbobman.com](https://fatbobman.com/en/posts/key-considerations-before-using-swiftdata/)
- [SwiftData+CloudKit Migration Failure — Apple Developer Forums](https://developer.apple.com/forums/thread/742899)
- [SwiftData with CloudKit failing to migrate schema — Apple Developer Forums](https://developer.apple.com/forums/thread/744491)
- [SwiftData CloudKit sync on WatchOS 10 — Apple Developer Forums](https://developer.apple.com/forums/thread/733397)
- [Deploy your CloudKit-backed SwiftData entities to production — leojkwan.com](https://www.leojkwan.com/swiftdata-cloudkit-deploy-schema-changes/)
- [SOLVED: SwiftUI App failing to sync CloudKit data in TestFlight — Hacking with Swift forums](https://www.hackingwithswift.com/forums/swiftui/swiftui-app-failing-to-sync-cloudkit-data-but-only-in-testflight-version/10714)
- [Some Quirks of SwiftData with CloudKit — firewhale.io](https://firewhale.io/posts/swift-data-quirks/)
- [Building a Universal Workout App: iPhone ↔ Apple Watch Data Sync — Wesley Matlock, Medium](https://medium.com/@wesleymatlock/building-a-universal-workout-app-seamless-iphone-apple-watch-data-sync-3d77a001b0ba)
- [HKWorkoutSession.sendToRemoteWorkoutSession never returns — Apple Developer Forums](https://developer.apple.com/forums/thread/769355)
- [Beware @unchecked Sendable — Jared Sinclair](https://jaredsinclair.com/2024/11/12/beware-unchecked.html)
- [Mastering StoreKit 2 in SwiftUI: A Complete Guide (2025) — Medium](https://medium.com/@dhruvinbhalodiya752/mastering-storekit-2-in-swiftui-a-complete-guide-to-in-app-purchases-2025-ef9241fced46)
- [iOS In-App Subscription Tutorial with StoreKit 2 — RevenueCat](https://www.revenuecat.com/blog/engineering/ios-in-app-subscription-tutorial-with-storekit-2-and-swift/)
- [Silent Push Notifications: Opportunities, Not Guarantees — Medium](https://mohsinkhan845.medium.com/silent-push-notifications-in-ios-opportunities-not-guarantees-2f18f645b5d5)
- CONCERNS.md (internal codebase audit — 2026-03-18)

---
*Pitfalls research for: iOS + watchOS native strength training app*
*Researched: 2026-03-18*
