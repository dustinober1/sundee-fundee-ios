# Phase 8: Fix Cycle Adaptation Wiring - Context

**Gathered:** 2026-03-15
**Status:** Ready for planning

<domain>
## Phase Boundary

Replace dead `cycleTrackingEnabled` gate with `profile?.cycleOptIn === true` so cycle-aware workout load adjustment actually activates for users who opted into cycle tracking. Covers CYAD-01 (load adjustment), CYAD-02 (set/rep scaling), CYAD-03 (readiness integration). All adaptation logic is already implemented and tested — this is a wiring fix, not a feature build.

</domain>

<decisions>
## Implementation Decisions

### Gate fix scope
- Fix both broken gates: `workout-session.tsx` (line 143) and Dashboard `index.tsx` (line 135)
- Replace `cycleSettings?.cycleTrackingEnabled === true` with `profile?.cycleOptIn === true`
- AI workout `config.tsx` already uses the correct check — no changes needed there
- Load onboarding profile from `OnboardingProfileRepo` (same pattern as `ai-workout/config.tsx`)
- Keep the existing `cycleSettings` fetch — still needed for `calculateCycleStatus`
- Only the gating condition changes; loading order and data flow stay the same

### Adaptation visibility
- Trust existing AdaptationIndicator UI code — it was built and tested in Phase 5
- Once the multiplier loads as non-1.0, the adaptation banner will render automatically
- No UI changes or new smoke tests for the indicator

### Test coverage
- Unit test the gate logic in `loadAdaptationContext` (workout-session) and Dashboard cycle loading
- Positive test: cycleOptIn=true with period logs → multiplier != 1.0
- Negative test: cycleOptIn=false → multiplier stays 1.0
- No integration/render tests — domain layer already has 100% coverage on blendMultiplier etc.

### Readiness integration
- No changes to blendMultiplier formula — it already combines cycle phase + readiness score correctly
- Once the gate is fixed, CYAD-03 (readiness integration) activates automatically
- Dashboard shows cycle phase banner only (e.g., "Luteal — Day 22") — no readiness blending in the banner display

### Claude's Discretion
- Exact test file naming and organization
- Whether to extract the profile-loading pattern into a shared hook (if both files duplicate logic)
- Any minor cleanup of imports or dead code exposed by the fix

</decisions>

<specifics>
## Specific Ideas

- Follow the exact pattern from `ai-workout/config.tsx:137` — `if (profile?.cycleOptIn === true)` — for consistency across the codebase
- The fix is narrow: two condition changes + profile loading in two files + unit tests

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- `getOnboardingProfileRepo(isGuest)`: Already used in `ai-workout/config.tsx` and `_layout.tsx` — returns profile with `cycleOptIn` boolean
- `blendMultiplier`, `resolveReadinessTier`, `resolveConfidenceScale`: Fully ported in `src/domain/cycle/cycle-adaptation-policy.ts`
- `calculateCycleStatus`: Computes current phase from period logs + cycle settings
- `AdaptationIndicator` component: Built in Phase 5 with `formatDelta` static helper

### Established Patterns
- `ai-workout/config.tsx:137` is the correct reference implementation: loads profile via `getOnboardingProfileRepo`, checks `profile?.cycleOptIn === true` before loading cycle data
- Repository factory pattern: `getXxxRepo(isGuest)` returns platform-appropriate implementation
- Adaptation context loads asynchronously via `useFocusEffect` — never blocks workout start

### Integration Points
- `workout-session.tsx`: `loadAdaptationContext` callback needs profile loading added, gate condition changed
- `(tabs)/index.tsx`: Dashboard cycle banner loading needs same profile check
- `OnboardingProfileRepo`: Already available, just not imported in the two broken files
- `CycleRepo.getCycleSettings()`: Still used for `calculateCycleStatus`, just no longer used for gating

</code_context>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 08-fix-cycle-adaptation-wiring*
*Context gathered: 2026-03-15*
