# UAT Access Verification Playbook (Phase 10)

## Purpose
This playbook defines the repeatable manual UAT process for verifying the repaired access path:
`login -> dashboard -> programs -> workout start`.
It complements automated tests by capturing durable, reviewable human evidence.

## Scope
- Applies to auth, onboarding eligibility, enrollment access, and workout start behavior.
- Applies to release readiness checks and any patch touching auth/onboarding/workout access code.
- Produces artifacts consumed by `.planning/phases/10-verification-evidence-and-regression-guardrails/10-UAT.md`.

## Canonical account and state
- Canonical verification account: `elizabethober@me.com`
- Required canonical pre-run state:
  - onboardingComplete is true
  - account is not routed to resume onboarding
  - one active enrollment exists with a startable next session
  - app build metadata and backend mode are known

## Pre-run checklist
1. Confirm canonical account email is correct.
2. Confirm canonical account password/access is available to tester.
3. Confirm onboarding state drift check passed.
4. Confirm enrollment state drift check passed.
5. Confirm artifact folder was scaffolded by `scripts/phase10-capture-uat-evidence.sh`.
6. Confirm session video recording is enabled.
7. Confirm timestamp and commit SHA are captured.

If any item fails, mark the run as `blocked`, stop, and attach drift recovery notes.

## Drift gate and blocked runs
A run is invalid if canonical state drift is detected.
Common drift examples:
- account routed to onboarding
- account cannot access dashboard/programs due permission state
- no active enrollment for workout-start checkpoint

Blocked-run handling:
1. Capture screenshot of visible blocking state.
2. Record UTC timestamp.
3. Record concise repro notes (max 5 bullets).
4. Stop capture and update `10-UAT.md` as blocked.
5. Link blocked artifact paths in `Failure Evidence`.

## Run steps
1. Start session recording.
2. Login with canonical account.
3. Capture `login` checkpoint evidence.
4. Verify dashboard renders expected content and capture `dashboard` evidence.
5. Navigate to Programs tab and capture `programs` evidence.
6. Navigate to Workout tab and start session.
7. Capture `workout start` evidence.
8. Capture final success evidence and stop recording.
9. Update `10-UAT.md` with artifact links and result.

## Artifact contract
All artifacts are stored under:
`.planning/phases/10-verification-evidence-and-regression-guardrails/artifacts/<run_id>/`

Required artifacts:
- `checkpoints/login.png`
- `checkpoints/dashboard.png`
- `checkpoints/programs.png`
- `checkpoints/workout-start.png`
- `checkpoints/final-success.png`
- `logs/session-video.mp4`

Failure artifacts (if needed):
- `failures/<checkpoint>-error.png`
- `failures/<checkpoint>-notes.md`

## Evidence quality bar
- Every checkpoint has one primary artifact.
- Artifact filenames are deterministic and human-readable.
- Notes include UTC time, app commit SHA, backend mode, and tester initials.
- Failure evidence includes visible error, not just text summary.

## Rerun triggers
Run the full UAT flow after any change in:
- auth provider/session bootstrap behavior
- onboarding eligibility evaluator or auto-heal behavior
- enrollment lifecycle access/retry logic
- workout start routing and sync recovery gates

## Exit criteria
Run can be marked `passed` only when:
- all required checkpoints are captured,
- final success is captured,
- no permission-denied or false onboarding prompt is observed,
- artifacts are linked in `10-UAT.md`.
