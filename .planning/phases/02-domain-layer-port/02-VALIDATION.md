---
phase: 2
slug: domain-layer-port
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-14
---

# Phase 2 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Jest 30.3.0 + jest-expo preset |
| **Config file** | `SundeeFundeeRN/jest.config.js` |
| **Quick run command** | `cd SundeeFundeeRN && npx jest src/domain --passWithNoTests` |
| **Full suite command** | `cd SundeeFundeeRN && npx jest --coverage` |
| **Estimated runtime** | ~5 seconds (pure logic, no native modules) |

---

## Sampling Rate

- **After every task commit:** Run `cd SundeeFundeeRN && npx jest src/domain --passWithNoTests`
- **After every plan wave:** Run `cd SundeeFundeeRN && npx jest --coverage`
- **Before `/gsd:verify-work`:** Full suite must be green with 100% line coverage on `src/domain/**`
- **Max feedback latency:** 5 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| TBD | 01 | 1 | CYAD-01 | unit (fixture) | `npx jest src/domain/cycle` | ❌ W0 | ⬜ pending |
| TBD | 01 | 1 | CYAD-02 | unit (fixture) | `npx jest src/domain/cycle` | ❌ W0 | ⬜ pending |
| TBD | 01 | 1 | CYAD-03 | unit | `npx jest src/domain/cycle` | ❌ W0 | ⬜ pending |
| TBD | 02 | 1 | INJR-02 | unit | `npx jest src/domain/injury` | ❌ W0 | ⬜ pending |
| TBD | 02 | 1 | INJR-04 | unit | `npx jest src/domain/injury` | ❌ W0 | ⬜ pending |
| TBD | 02 | 1 | INJR-05 | unit | `npx jest src/domain/injury` | ❌ W0 | ⬜ pending |
| TBD | 02 | 1 | INJR-06 | unit | `npx jest src/domain/injury` | ❌ W0 | ⬜ pending |
| TBD | 03 | 1 | WORK-06 | unit | `npx jest src/domain/calculations` | ❌ W0 | ⬜ pending |
| TBD | 03 | 1 | MAX-03 | unit (fixture) | `npx jest src/domain/calculations` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `date-fns` installation: `cd SundeeFundeeRN && npm install date-fns`
- [ ] `src/domain/types/index.ts` — shared domain interfaces (ExerciseValue, ProgramExercise, InjuryProfile, PainLog, PeriodLog, CycleSettings, etc.)
- [ ] `src/domain/__fixtures__/` directory with initial parity fixture files
- [ ] Jest coverage threshold config for `src/domain/**` at 100% lines

*All test files are greenfield — every domain test file needs to be created during execution.*

---

## Manual-Only Verifications

*All phase behaviors have automated verification. Domain layer is pure logic — no UI, no I/O, no manual steps needed.*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 5s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
