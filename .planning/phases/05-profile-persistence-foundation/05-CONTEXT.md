# Phase 5: Profile Persistence Foundation - Context

**Gathered:** 2026-02-23
**Status:** Ready for planning

<domain>
## Phase Boundary

Persist onboarding and injury profile data so returning authenticated users are not repeatedly prompted and profile state remains stable across sessions/devices. This phase includes bootstrap gating, profile persistence behavior, injury profile CRUD/state integrity, and safe defaults for legacy users with missing fields. Injury-based plan adaptation behavior itself is out of scope for this phase.

</domain>

<decisions>
## Implementation Decisions

### Session bootstrap rules
- Completion is determined by a hybrid rule: `onboardingCompleted` flag plus required-field validation.
- If onboarding is partial, users get a choice to resume from last step or restart from step 1.
- On local/server profile conflict at startup, use most-recent timestamp reconciliation.
- If required injury fields are missing, block plan flow until the injury section is answered.

### Profile edit persistence UX
- Provide separate post-onboarding edit surfaces: one for onboarding answers and one for injury profile.
- Use hybrid save behavior: auto-save simple fields, explicit save for injury section.
- Save failures are non-blocking: allow continuation, queue retry, and show warning.
- Plan-impacting profile edits regenerate the current plan automatically.

### Injury profile structure
- Required injury fields: location, movement limitations, recovery goal, and active/inactive status.
- Support multiple concurrent active injuries.
- Clearing an injury marks it resolved and retains history (no hard delete by default).
- Prompt injury reassessment every 2 weeks.

### Legacy account defaults + migration behavior
- Initialize missing fields client-side at bootstrap, then sync.
- If migration/default write fails, allow all usage with warning and retry later.
- Show a one-time lightweight migration notice to legacy users.
- For contradictory legacy state (completion flag but missing required answers), ask user whether to keep existing profile path or redo.

### Claude's Discretion
- Exact UI copy/tone for resume vs restart and migration notice.
- Exact conflict-resolution tie-breaker when timestamps are identical.
- Exact retry cadence/backoff for failed migration/profile writes.

</decisions>

<specifics>
## Specific Ideas

- Keep onboarding persistence friction-free so users are not asked every login.
- Injury section is treated as a required safety gate for plan flow when required fields are absent.
- Migration messaging should be lightweight, not a full forced walkthrough.

</specifics>

<deferred>
## Deferred Ideas

- Legal disclaimer wording and display coverage for injury guidance is Phase 6 scope.
- Deterministic alternate exercise generation and recovery-support additions are Phase 6 scope.
- Plan cancellation lifecycle is Phase 7 scope.

</deferred>

---

*Phase: 05-profile-persistence-foundation*
*Context gathered: 2026-02-23*
