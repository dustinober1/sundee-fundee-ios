# Phase 3: Cloud Sync - Context

**Gathered:** 2026-02-19
**Status:** Ready for planning

<domain>
## Phase Boundary

Implement Supabase-backed cloud sync so user data is securely backed up and retrievable on other devices. This phase covers authentication, data upload/download, conflict resolution, and sync status UI. It does not include social features, analytics, or admin tooling.

</domain>

<decisions>
## Implementation Decisions

### Auth Entry Points & Gating
- **Opt-in model**: Sync is fully optional. No forced auth wall.
- **Discovery**: Soft nudge shown after first completed workout (or on Dashboard) to prompt the user to enable sync.
- **Persistent access**: User can sign in or manage account from the **Dashboard top bar** (near avatar/name).
- **Auth methods**: Magic link (email, passwordless) + Google OAuth via Supabase.
- **Existing local data**: On first sign-in, ask the user whether to upload their existing local workout history to the cloud. User chooses yes/no.

### Sync Trigger & Timing
- **Primary trigger**: Sync fires immediately after a workout is completed (post-workout push).
- **App open trigger**: On app open/foreground, also pull latest data from cloud (bidirectional so other devices stay current).
- **Offline handling**: If a workout is completed while offline, show a banner: *"You're offline — data will sync when reconnected."* Queue the sync and fire it automatically when connectivity is restored.
- **Failure handling**: Retry silently up to 3 times. Only surface an error to the user if all 3 retries fail.

### Conflict Resolution
- **Strategy**: Last write wins by `completedAt` / `updatedAt` timestamp — the most recently written record always wins.
- **Notification**: Conflicts are resolved silently. The user is not interrupted or notified when the cloud wins.
- **Workout history**: Same last-write-wins strategy applies to `completedWorkouts` and `completedSets`. No special merge logic.
- **Local deletes**: Local deletions do **not** propagate to the cloud in v1. Cloud retains all records regardless of local deletes.

### Sync Status UI
- **Location**: Dashboard top bar, adjacent to the user avatar/name area.
- **States**: `Synced ✔` / `Syncing...` / `Offline` / `Error`
- **Timestamp**: Display last successful sync time (e.g., *"Synced 2 min ago"*).
- **Interaction**: The indicator is tappable — opens a small popover showing sync details (last synced time, pending count if any) plus a **"Sync now"** manual trigger button.

### Claude's Discretion
- Exact wording of the "nudge" prompt (after first workout / on dashboard).
- Exact wording of the "Upload existing data?" dialog on first sign-in.
- Popover layout and visual design.
- Retry backoff timing (e.g., 2s, 5s, 10s).
- Specific error message copy for the 3-retry failure case.

</decisions>

<specifics>
## Specific Ideas

- "Sync should feel invisible — users shouldn't have to think about it."
- "The status indicator should be informative but not loud. Only errors should demand attention."
- "The soft nudge should feel like a helpful suggestion, not a marketing push."

</specifics>

<deferred>
## Deferred Ideas

- **Propagating local deletes to cloud** — intentionally excluded from v1; could be revisited.
- **Multi-device conflict UI** — letting users manually choose which record to keep (too complex for v1).
- **Sync analytics / diagnostics view** — detailed sync log for power users.
- **Push notifications** — notify user on another device when sync completes.

</deferred>

---

*Phase: 03-cloud-sync*
*Context gathered: 2026-02-19*
