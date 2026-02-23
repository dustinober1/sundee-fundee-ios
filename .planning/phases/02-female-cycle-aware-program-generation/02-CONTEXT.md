# Phase 2: Female Cycle-Aware Program Generation - Context

**Gathered:** 2026-02-23
**Status:** Ready for planning

<domain>
## Phase Boundary

Implement cycle-aware program generation for female users so workout prescriptions adapt to current cycle phase, with UI feedback that explains adjustments and clear fallback behavior when cycle confidence is low or data is incomplete.

</domain>

<decisions>
## Implementation Decisions

### Cycle-Phase Adaptation Policy
- Keep the current in-app phase adaptation behavior as the baseline source of truth for phase-specific logic.
- Adaptation should be noticeable, not subtle.
- Primary adaptation levers are load and sets/reps volume.
- If readiness input and cycle phase conflict, resolve using a blend of both signals.

### User-Facing Adjustment Explanations
- Explanations should be short reasons, not detailed rationale.
- Surface explanations in multiple places in the program flow.
- Tone should be neutral.
- Users should always be able to hide explanations.

### Recalculation Timing & Change Handling
- Recalculate immediately when cycle data changes.
- If a workout is currently in progress and phase updates, ask the user whether to apply the update.
- Communicate recalculation with a subtle badge.
- If multiple cycle edits happen in one day, use only the latest edit for recalculation.

### Fallback & Confidence Behavior
- If current cycle phase is missing, default to the last known phase.
- If cycle confidence is low/uncertain, apply reduced adjustments.
- Fallback messaging should be brief and actionable.
- Never block workouts due to fallback/uncertain cycle state.

### Claude's Discretion
- Exact placement and styling of short explanation text across the selected UI surfaces.
- Exact blend behavior and wording used when readiness and cycle phase both influence prescription.
- Final copy variants for subtle badges and fallback notices that preserve neutral tone.

</decisions>

<specifics>
## Specific Ideas

No external product references were provided. Preserve current in-app adaptation intent and focus this phase on making behavior visible, immediate, and user-controllable.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 02-female-cycle-aware-program-generation*
*Context gathered: 2026-02-23*
