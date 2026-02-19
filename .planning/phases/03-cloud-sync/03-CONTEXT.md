# Phase 3: Cloud Sync - Context

**Gathered:** 2026-02-18
**Status:** Ready for planning

<domain>
## Phase Boundary

Securely backup user data (workouts, 1RMs, profiles) to Supabase and allow restoring it on other devices. Includes authentication, sync status indicators, conflict resolution, and offline queuing.

</domain>

<decisions>
## Implementation Decisions

### Auth Experience
- **Providers:** Google and Email/Password (Social auth preferred for friction-free start).
- **Entry Point:** Global "Sign In / Sync" button in the header/sidebar, always visible.
- **Goal:** Frictionless entry to protect data.

### Sync Behavior
- **Trigger:** Real-time sync on every save (e.g., finishing a workout, updating 1RM).
- **Offline Handling:** Show a non-intrusive banner ("Offline - Changes queued") when sync fails.
- **Queue:** Silent background queue that retries when online.

### Conflict Handling
- **Strategy:** User Choice for genuine conflicts (e.g., modified same workout on two devices).
- **UI:** A "Conflict List" (likely in settings or a dedicated modal) where users resolve items.
- **Granularity:** Workout/Object level (resolve the whole session, not individual sets/fields).

### Data Migration
- **First Sign-in (Empty Cloud):** Merge Local -> Cloud (upload existing local data).
- **Sign-in (Existing Cloud Data):** Prompt user: "Use Cloud Data (replace local)" or "Merge Local & Cloud".
  - *Correction during discussion:* User initially said "Use Cloud", then clarified "Merge" for empty cloud case. The safe default for non-empty cloud + existing local is to ASK.

### Claude's Discretion
- Specific UI for the conflict resolution list.
- exact retry backoff logic for offline queue.
- Database schema for Supabase (matching Dexie structure).

</decisions>

<specifics>
## Specific Ideas

- "Global Button" for auth suggests it's a primary feature, not buried in settings.
- "Real-time" sync implies a reactive architecture (hooks or listeners on Dexie changes).
- "Banner" for offline state balances visibility with non-intrusiveness.

</specifics>

<deferred>
## Deferred Ideas

- Social feed / Sharing (Phase 5+)
- Push notifications for social interactions.

</deferred>

---

*Phase: 03-cloud-sync*
*Context gathered: 2026-02-18*
