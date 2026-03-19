# Deferred Items — Phase 01

## Pre-existing test compilation failures (out of scope for 01-02)

**File:** `SundeeFundeTests/AIWorkoutTests.swift`
**Errors:**
- Line 17: `extra argument 'weightUnit' in call` 
- Line 32: `cannot infer contextual base in reference to member 'fullBody'`
- Line 34: `cannot infer contextual base in reference to member 'fullGym'`
- Line 522: `extra argument 'weightUnit' in call`
- Line 535: `extra argument 'weightUnit' in call`

**Root cause:** These errors predate plan 01-02. They are caused by an in-progress FIX-01 change (AI weight unit parameterization in plan 01-01) that updated `WorkoutGenerationContext` with a `weightUnit` parameter, but `AIWorkoutTests.swift` was not yet updated to match. This needs to be resolved as part of the FIX-01 plan completion.

**Impact:** These errors block `xcodebuild test` for the full test suite. They do not affect the production build.
