# Phase 9: Onboarding Resume Eligibility Hardening - Context

**Gathered:** 2026-02-25
**Status:** Ready for planning

<domain>
## Phase Boundary

Eliminate false "Resume Onboarding" prompts for returning users while preserving resume prompts for genuinely incomplete profiles. This phase defines onboarding-completeness interpretation and resume routing behavior for current and legacy user records. It does not add new onboarding steps or redesign onboarding UI.

</domain>

<decisions>
## Implementation Decisions

### Completeness criteria
- Required onboarding field for completeness checks is `name`.
- `onboardingComplete == true` is always treated as complete, even when required fields are currently missing.
- If required fields are present while `onboardingComplete == false`, treat the user as complete and auto-heal the flag to `true`.
- For normalized explicit gender completion values, accept `male` and `female` (exclude `preferNotToSay` for completion validation paths that evaluate gender).

### Legacy record interpretation
- If `name` is missing and the user has completed workout history, do **not** bypass resume; show "Resume Onboarding."
- If `name` is missing and the user has max-only history, bypass resume and treat as complete.
- Legacy recovery heuristics must inspect both workout history and max history evidence.
- If required fields are missing and there is no qualifying history evidence, always show "Resume Onboarding."

### Resume prompt triggers
- Evaluate and trigger onboarding resume decision after sign-in bootstrap.
- When resume is bypassed via legacy recovery heuristics, show a one-time profile recovery notice.
- If profile stream bootstrap errors or times out, default to showing "Resume Onboarding."
- Users needing injury profile completion should not be shown resume onboarding first once onboarding completeness is satisfied; route to injury completion path.

### Resume flow outcome
- After successful resumed onboarding completion, land user on Home/Dashboard.
- Restart onboarding clears onboarding fields and also clears injury profiles and injury disclaimer acknowledgments.
- If a user exits onboarding before submitting, prompt "Resume Onboarding" again on next sign-in.
- Auto-heal/recovery state remains behind the scenes (no persistent settings marker).

### Claude's Discretion
- Exact microcopy for one-time profile recovery notice and resume/restart messaging.
- Exact placement/styling of one-time recovery notice in the post-sign-in experience.
- Exact threshold/timeout values used to classify profile bootstrap as timeout.

</decisions>

<specifics>
## Specific Ideas

- Keep eligibility decisions deterministic and conservative to avoid false skips.
- Preserve user trust by using one-time recovery messaging only when legacy recovery logic changed routing.
- Maintain separation of concerns between onboarding completeness and injury-profile gating.

</specifics>

<deferred>
## Deferred Ideas

None - discussion stayed within Phase 9 scope.

</deferred>

---

*Phase: 09-onboarding-resume-eligibility-hardening*
*Context gathered: 2026-02-25*
