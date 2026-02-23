# Offline Sync Contract

## Scope
This contract defines how cycle/program/workout surfaces expose sync state and how queued writes resolve after reconnect.

## Canonical Model
`SyncStatusModel` (`flutter_app/lib/features/repositories/domain/sync_status_model.dart`) is the shared shape:
- `fromCache`: indicates UI is showing cached state.
- `pendingWrites`: indicates local changes are still syncing.
- `lastSyncedAt`: last known successful sync timestamp (nullable).
- `freshness`: `fresh`, `stale`, or `unknown` based on a 24-hour cutoff.

## Freshness Policy
- Fresh threshold: 24 hours.
- `lastSyncedAt == null` maps to `unknown`.
- Older than threshold maps to `stale`.

## UI Mapping
`SyncStatusBadge` (`flutter_app/lib/features/shared/presentation/sync_status_badge.dart`) maps state to compact UX copy:
- Pending writes: `Syncing changes`
- Cache mode: `Offline cache`
- Stale: `Stale (<timestamp>)`
- Fresh: `Last synced <timestamp>`
- Unknown: `Not yet synced`

## Write Resolution Rule
User-facing write conflicts are not surfaced as dialogs. Repository writes follow deterministic latest-edit-wins behavior by timestamped updates and Firestore replay semantics.

## Feature Integration
Current phase integration points:
- `dashboard_screen.dart`
- `cycle_tracking_screen.dart`
- `programs_screen.dart`

These continue rendering explicit `Last synced` text while also showing the compact sync badge.
