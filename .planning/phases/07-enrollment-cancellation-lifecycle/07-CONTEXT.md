# Phase 7: Enrollment Cancellation Lifecycle - Context

**Gathered:** 2026-02-24
**Status:** Ready for planning

<domain>
## Phase Boundary

Provide an explicit cancel-plan lifecycle that lets users cancel active enrollment safely, see clear post-cancel inactive state, preserve historical completed workouts, and re-enroll in a new plan without conflicting active-state artifacts. New plan discovery/browsing features and retention analytics are out of scope for this phase.

</domain>

<decisions>
## Implementation Decisions

### Cancellation entry + confirmation flow
- Cancellation entry is broadly available anywhere plan status is shown.
- Cancellation uses a two-step confirmation flow.
- No cancellation reason is collected.
- Cancellation takes effect immediately.

### Post-cancel UI state semantics
- Primary post-cancel state is shown as `No active plan`.
- Plan surfaces use a full replacement state card (not a badge/banner overlay on prior plan details).
- Post-cancel CTA surface includes both actions: `Browse plans` and `Enroll in new plan`.
- Workout session actions are hidden completely once canceled.

### History retention + visibility after cancel
- Completed workout history remains visible in normal history views and is marked as coming from a canceled plan.
- Canceled plan detail is removed; retain workouts/history only.
- Workouts from canceled plans continue to contribute to aggregate metrics and PRs.
- Add a timeline/event entry indicating cancellation date.

### Re-enrollment behavior + guardrails
- Re-enrollment prompts the user each time to choose between restoring prior canceled enrollment (same plan) vs creating new.
- If stale active-state artifacts are detected, auto-heal state and proceed; if healing fails, surface a clear fallback error.
- Re-enrollment carries over profile and injury context, but not prior progress position.
- No cooldown/wait period is required before re-enrollment.

### Claude's Discretion
- Exact copy for confirmation steps and post-cancel replacement state card.
- Exact wording for canceled-workout history marker and cancellation timeline entry.
- Exact UX of the re-enrollment choice prompt (restore vs new) and fallback error messaging.

</decisions>

<specifics>
## Specific Ideas

- Cancellation should feel explicit and safe, without hidden side effects.
- Post-cancel state should avoid ambiguity by replacing prior active-plan presentation.
- History integrity is important: completed workouts stay visible and meaningful after cancellation.

</specifics>

<deferred>
## Deferred Ideas

None - discussion stayed within Phase 7 scope.

</deferred>

---

*Phase: 07-enrollment-cancellation-lifecycle*
*Context gathered: 2026-02-24*
