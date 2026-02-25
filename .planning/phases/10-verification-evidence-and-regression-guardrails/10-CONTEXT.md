# Phase 10: Verification Evidence and Regression Guardrails - Context

**Gathered:** 2026-02-25
**Status:** Ready for planning

<domain>
## Phase Boundary

Add durable automated and manual evidence proving repaired UAT flows remain stable for authenticated access and onboarding resume behavior. Scope includes test coverage, UAT evidence capture, and milestone artifact updates for the known `permission-denied` and onboarding false-prompt findings.

</domain>

<decisions>
## Implementation Decisions

### Automated Regression Coverage
- Use full critical-flow integration coverage across Home, Programs, and Workout surfaces.
- Include unauthenticated guard-path checks in the automated coverage set.
- Use strict assertions: validate expected data/write outcomes and explicitly assert absence of permission-denied and onboarding fallback regressions.
- Cover write paths through workout start, session progress writes, and completion/replay recovery paths.

### Manual UAT Evidence Package
- Capture a full session video for each evidence run.
- Collect one artifact per checkpoint in the flow (`login -> dashboard -> programs -> workout start`) plus a final success artifact.
- For failures, record artifact(s) showing the visible error, timestamp, and quick repro notes.
- Store evidence in a Markdown verification report within the phase folder, with linked media/log artifacts.

### Verification Account + Run Conditions
- Use one canonical verification account as the source of truth for UAT evidence.
- Require an explicit pre-run checklist with manual verification of required account/data state.
- If canonical state drifts, block evidence collection and restore canonical state before continuing.
- Execute a full evidence run after each major change affecting auth, onboarding, or workout flow behavior.

### Milestone Artifact Resolution Format
- Record resolved-finding evidence in the phase verification document and milestone roadmap status notes.
- For each finding (`permission-denied`, onboarding false-prompt), require automated test evidence, UAT artifact evidence, and a short root-cause/fix note.
- Use a structured resolution checklist format: finding, cause, fix, verification proof, residual risk.
- Track unresolved/partial items in an explicit open-risks section with owner and follow-up phase pointer.

### Claude's Discretion
- None explicitly granted; decisions above are locked for research/planning.

</decisions>

<specifics>
## Specific Ideas

- Primary UAT evidence path is the exact sequence: `login -> dashboard -> programs -> workout start`.
- Evidence requirements are designed to prove stability, not just one-time pass/fail snapshots.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 10-verification-evidence-and-regression-guardrails*
*Context gathered: 2026-02-25*
