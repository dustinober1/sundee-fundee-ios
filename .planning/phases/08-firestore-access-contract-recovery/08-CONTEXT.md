# Phase 8: Firestore Access Contract Recovery - Context

**Gathered:** 2026-02-24
**Status:** Ready for planning

<domain>
## Phase Boundary

Restore authenticated Firestore read/write access for core training surfaces (Home, Programs, Workout) by aligning Firestore rules with repository/query contracts, while providing recoverable error UX for genuine backend access failures. This phase covers access outcomes and recovery behavior within existing product flows; it does not add new product capabilities.

</domain>

<decisions>
## Implementation Decisions

### Access outcomes by user state
- Authenticated users with no active enrollment see explicit empty states with a primary "Start Program" CTA on Home, Programs, and Workout surfaces.
- Users with active enrollment but missing next-session data are treated as a valid empty-data state ("No upcoming session yet") with a refresh action, not a hard backend failure.
- Stale profile enrollment links (canceled/missing enrollment references) auto-heal to the no-enrollment state.
- Cross-tab outcomes may vary slightly, but Workout correctness takes priority over strict global state consistency.

### Recoverable error UX contract
- Error copy uses calm, direct language.
- Recoverable access failures render as a top banner while preserving underlying content skeleton/state.
- Error guidance includes retry plus a short checklist (for example: connection/app reopen guidance).
- Retry flow attempts automatic recovery first, then exposes manual retry when failure persists.

### Retry and re-entry behavior
- Initial failures auto-retry up to 3 times with short backoff.
- On app resume from background, access is revalidated and refreshed silently once.
- After auth refresh/re-auth success, users stay on their prior tab and manually trigger retry.
- Persistent retry failure escalates to a blocking recovery screen.

### Workout write-failure handling
- If workout start write fails, allow temporary local start but require successful sync before final completion.
- If progress writes fail intermittently, queue progress locally and continue the session, then sync when access recovers.
- If completion write fails, keep completion locally pending with background retries and manual retry.
- Use non-blocking toasts for transient write failures and a blocking modal for finalization failure states.

### Claude's Discretion
- Exact wording of checklist bullets, retry timing constants within the selected retry model, and detailed visual styling of banners/modals/toasts.

</decisions>

<specifics>
## Specific Ideas

- Explicitly distinguish valid "no data yet" states from genuine backend access failures.
- Favor continuity of workout execution via local buffering/queueing when writes fail transiently.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 08-firestore-access-contract-recovery*
*Context gathered: 2026-02-24*
