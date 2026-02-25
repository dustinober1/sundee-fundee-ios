# Phase 10 UAT Evidence Log

## Deprecated Runs

### run-20260225T205700Z

> Deprecated — backend_mode assumption (Firebase emulators) superseded by Phase 11 provider-override strategy.
> No artifacts captured. Original scaffold retained at `artifacts/run-20260225T205700Z/` for history.

- run_id: run-20260225T205700Z
- timestamp_utc: 2026-02-25T01:57:18Z
- account: elizabethober@me.com
- backend_mode: firebase emulators (assumed — never executed)
- commit_sha: 71e72d1
- status: deprecated

## Active Run

### run-20260225T033318Z

- run_id: run-20260225T033318Z
- timestamp_utc: 2026-02-25T03:33:18Z
- backend_mode: provider-override-integration-test
- commit_sha: a30aaf9
- test_file: flutter_app/integration_test/critical_access_flow_test.dart
- status: passed

### Checkpoints

| Checkpoint | Expected Outcome | Artifact | Status | Notes |
|---|---|---|---|---|
| login | Sign In screen renders, no permission-denied | `artifacts/run-20260225T033318Z/checkpoints/login-evidence.md` | covered-by-automated-test | Widget assertion: `find.text('Sign In').evaluate().isNotEmpty` |
| dashboard | Dashboard loads Next Workout, no onboarding false prompt | `artifacts/run-20260225T033318Z/checkpoints/dashboard-evidence.md` | covered-by-automated-test | Widget assertion: `find.text('Next Workout').evaluate().isNotEmpty` |
| programs | Programs tab renders active program state | `artifacts/run-20260225T033318Z/checkpoints/programs-evidence.md` | covered-by-automated-test | Widget assertion: `find.text(program.name).evaluate().isNotEmpty` |
| workout start | Workout tab shows START SESSION button | `artifacts/run-20260225T033318Z/checkpoints/workout-start-evidence.md` | covered-by-automated-test | Widget assertion: `find.text('START SESSION').evaluate().isNotEmpty` |
| final success | Session entry confirmed (W1:D1), no errors | `artifacts/run-20260225T033318Z/checkpoints/final-success-evidence.md` | covered-by-automated-test | Assertions: `(W1:D1)` present, `Resume onboarding` absent, `permission-denied` absent |

### Artifacts

- Metadata: `artifacts/run-20260225T033318Z/run-metadata.md`
- Checkpoint evidence: `artifacts/run-20260225T033318Z/checkpoints/*.md`
