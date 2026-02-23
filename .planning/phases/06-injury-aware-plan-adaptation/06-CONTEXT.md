# Phase 6: Injury-Aware Plan Adaptation - Context

**Gathered:** 2026-02-23
**Status:** Ready for planning

<domain>
## Phase Boundary

Adapt generated plans when injury context is present by replacing contraindicated movements with safer deterministic alternatives, adding recovery-support blocks, and showing explicit legal disclaimer copy across injury-guidance surfaces. This phase does not add diagnosis workflows, treatment prescriptions, or clinician integration.

</domain>

<decisions>
## Implementation Decisions

### Alternate-exercise behavior
- Replacement matching prioritizes same movement pattern and same primary muscle group.
- If no close match exists, fallback is a safer regression of the original movement.
- Replacements are shown inline on each affected exercise with a short reason.
- Users may manually revert to the contraindicated original exercise, but only after a strong warning.

### Recovery-support additions
- Add a short targeted warm-up plus mobility block when injury context is active.
- Show recovery-support additions at the beginning of each workout as a prep block.
- Include these additions in every workout while injury status is active.
- Users can skip the recovery-support block for a session, with a reminder warning.

### Disclaimer experience
- Use clear, direct, short medical-safety language.
- Show disclaimer text in plan overview, workout detail, and any override action flow.
- Require one-time acknowledgment per active injury period, then keep persistent reminder text visible.
- Disclaimer text can be collapsed after acknowledgment, but must remain re-openable.

### Adaptation timing and user control
- Apply injury-driven adaptations immediately for upcoming workouts; do not rewrite completed history.
- If injury context changes during an in-progress workout, prompt the user to keep current workout or apply safe updates now.
- Communicate adaptation changes using a small in-app badge plus short changelog summary.
- Do not allow disabling injury-aware adaptation while injury status is active.

### Claude's Discretion
- Exact warning/disclaimer copy variants that preserve legal clarity and product tone.
- Exact microcopy for replacement inline reasons and skip warnings.
- Exact placement/styling details for badges and changelog snippets.

</decisions>

<specifics>
## Specific Ideas

- Keep adaptation behavior explicit and user-visible without forcing full-screen interruptions.
- Preserve user agency through warnings/prompts while keeping safety defaults active.
- Maintain consistency so injury-aware behavior appears in every relevant plan surface.

</specifics>

<deferred>
## Deferred Ideas

None - discussion stayed within Phase 6 scope.

</deferred>

---

*Phase: 06-injury-aware-plan-adaptation*
*Context gathered: 2026-02-23*
