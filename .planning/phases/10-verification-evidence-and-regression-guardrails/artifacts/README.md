# Phase 10 UAT Artifacts

This directory stores evidence for manual UAT validation of:
`login -> dashboard -> programs -> workout start`.

## Directory contract
Each run uses:
`.planning/phases/10-verification-evidence-and-regression-guardrails/artifacts/<run_id>/`

Expected structure:
- `checkpoints/login.png`
- `checkpoints/dashboard.png`
- `checkpoints/programs.png`
- `checkpoints/workout-start.png`
- `checkpoints/final-success.png`
- `logs/session-video.mp4`
- `run-metadata.md`

Failure evidence:
- `failures/<checkpoint>-error.png`
- `failures/<checkpoint>-notes.md`

## Naming
Use lowercase kebab-case filenames. Keep one artifact per checkpoint.

## Checklist
Before capture:
- canonical verification account confirmed
- state drift check completed
- run metadata initialized
- session video capture started

## Notes
Checkpoint artifacts must align with `10-UAT.md` entries so auditors can trace each checkpoint quickly.
