# Roadmap

## Phases Overview

1. **Foundation & Men’s Program Layout** ✅ Completed (2026-02-23)
   - Goal: Ensure existing auth/cycle tracking is solid and convert the 12-week program display to a week-by-week format for male users.
   - Requirements: AUTH-01, CYCLE-01, PROG-01, PROG-02, UI-01
   - Success Criteria:
     1. Users can log in and remain authenticated on restart.
     2. Cycle data is recorded and correct phase computed.
     3. Men’s program appears as discrete weeks with progress indicators.
     4. UI cues (sharkweek logo) show on the cycle screen when applicable.
     5. Firestore reads/writes succeed and rules validate basic data.

2. **Female Cycle‑Aware Program Generation** ✅ Completed (2026-02-23)
   - Goal: Implement dynamic program generation that adjusts intensity based on the user’s cycle phase.
   - Requirements: PROG-03
   - Success Criteria:
     1. Workout prescriptions change when cycle phase updates.
     2. CycleProgramGenerator unit tests cover phase multipliers.
     3. UI reflects adjustments in program details.
     4. Backend data structures support per-phase program settings.

3. **Polish & Future Prep** ✅ Completed (2026-02-23)
   - Goal: Address remaining UI polish, add offline support checks, and prepare schema/rules for v2 features.
   - Requirements: UI-01 (polish), PROG-03 (stability), plus prepare for deferred v2 requirements.
   - Success Criteria:
     1. App works offline with cached cycle and program data.
     2. All Firebase rules updated for new program fields.
     3. Codebase documented and tests cover critical paths.


## Phase Status
- Phase 1: Complete (verified)
- Phase 2: Complete (verified)
- Phase 3: Complete (verified)

## Traceability Updates
- Phase 1: AUTH-01, CYCLE-01, PROG-01, PROG-02, UI-01
- Phase 2: PROG-03
- Phase 3: UI-01 (polish), PROG-03 (stability)
