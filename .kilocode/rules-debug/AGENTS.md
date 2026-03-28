# Project Debug Rules (Non-Obvious Only)

- `CKContainer(identifier:)` without CloudKit entitlement does not throw; it traps with SIGTRAP. Check entitlement guards before suspecting repository logic.
- SwiftData warnings about “unbinding from the main queue” usually mean a `ModelContext` holder is missing `@MainActor`.
- If tab data looks stale after navigation, inspect `.task` usage first; tab views stay alive and do not rerun `.task` on reselection.
- Broken navigation from nested flows is often caused by `NavigationLink(value:)` used below the root `NavigationStack`; switch to destination-based links.
- Before validating a “fresh install” path on Simulator, uninstall the existing app first to avoid stale persisted data influencing results.
- Dashboard file corruption/races usually come from bypassing `src/lib/file-io.ts`; that module serializes writes and keeps `.bak` snapshots.
