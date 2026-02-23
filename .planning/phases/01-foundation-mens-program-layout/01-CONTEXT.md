# Phase 1: Foundation & Men's Program Layout - Context

**Gathered:** 2026-02-23
**Status:** Ready for planning

<domain>
## Phase Boundary

Stabilize existing authentication and cycle tracking behavior, convert the men's 12-week program into a week-by-week presentation with progress indicators, surface cycle cue UI (including sharkweek cue behavior), and validate baseline Firestore read/write behavior and rule compatibility for Phase 1 flows.

</domain>

<decisions>
## Implementation Decisions

### Program Week View Semantics
- Week cards should show week number/title, completion status, workout count, intensity tag, and a short note.
- Progress should use a percent bar.
- A week is considered complete when the user manually marks it complete.
- Navigation should recommend sequence but allow jumping between weeks.

### Cycle Cues & User-Facing States
- Show sharkweek cue only during menstruation phase.
- Use hero-level prominence for the cue on the cycle screen.
- If cycle data is missing or uncertain, show a neutral "cycle data unavailable" state.
- Also show cycle cue context in program view with a short explanatory text.

### Auth Session Experience
- On restart with a valid session, route to home/dashboard.
- If stored session is invalid or expired, attempt silent refresh first; send user to login if refresh fails.
- Preserve login across app updates and reinstall when possible.
- Auth error messaging should be minimal and action-focused.

### Data Confidence Signals
- On Firestore write failure, show an inline non-blocking error banner.
- Show a persistent "last synced" timestamp on relevant screens.
- If reads succeed but fields are missing/legacy, hide affected sections and show an "incomplete data" notice.
- Phase 1 requires strong correctness, including edge cases, before launch.

### Claude's Discretion
- Exact placement/styling for week-card metadata and progress visuals.
- Exact visual design of hero cue, banners, and timestamp components.
- Final wording variants for user-facing copy that preserve the chosen tone and meaning.

</decisions>

<specifics>
## Specific Ideas

No external product references were provided. Keep cycle cues visually clear and explanatory text concise in the program view.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 01-foundation-mens-program-layout*
*Context gathered: 2026-02-23*
