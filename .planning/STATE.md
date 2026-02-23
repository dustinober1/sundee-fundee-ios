# Project State

## Current Position

Phase: 6 (Injury-Aware Plan Adaptation) — in progress  
Plan: 06-03 complete (06-04 remaining)  
Status: Milestone v1.1 execution in progress  
Last activity: 2026-02-23 — Executed 06-03-PLAN.md

Progress: ███████████████████░░ 20/21 plans complete (~95%)

## Accumulated Context

- Initialized: 2026-02-23
- Milestone completed: v1 (2026-02-23)
- Milestone audit: passed (`.planning/v1-MILESTONE-AUDIT.md`)
- Milestone archives:
  - `.planning/milestones/v1-ROADMAP.md`
  - `.planning/milestones/v1-REQUIREMENTS.md`
- Milestone index:
  - `.planning/MILESTONES.md`

## Key Decisions

| Decision | Choice | Plan |
|---|---|---|
| Injury fields serialization | View-layer-only — NOT in fromJson/toJson | 06-01 |
| No-op fast-path | Return same reference when activeInjuries is empty | 06-01 |
| Regression table | Hardcoded deterministic table for primary lifts | 06-01 |
| isContraindicatedOriginal | Engine always sets false; only user revert sets true | 06-01 |
| Disclaimer ack persistence | Map<String, DateTime> on UserModel, Firestore dot-notation merge | 06-02 |
| InjuryAdaptationContext empty injuries | disclaimerAcknowledgedForAll = true when no active injuries | 06-02 |
| Provider stacking | injuryAdaptedActiveProgramProvider wraps adaptedActiveProgramProvider (cycle preserved) | 06-02 |
| InjuryAdaptationBanner state ownership | Parent-managed visible/onToggleVisibility (matches CycleAdjustmentExplainer) | 06-03 |
| programs_screen hard gate | Grey italic text replaces week list until disclaimer acknowledged | 06-03 |
| workout_landing_screen hard gate | START SESSION button disabled (onPressed: null) until disclaimer acknowledged | 06-03 |
| dashboard injury indicator | Lightweight chip only — no full banner on dashboard | 06-03 |

## Session Continuity

Last session: 2026-02-23T23:50:21Z  
Stopped at: Completed 06-03-PLAN.md  
Resume file: None
