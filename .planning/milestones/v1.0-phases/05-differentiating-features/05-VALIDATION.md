---
phase: 5
slug: differentiating-features
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-15
---

# Phase 5 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | jest-expo (jest 29.x) |
| **Config file** | `SundeeFundeeRN/jest.config.js` |
| **Quick run command** | `cd SundeeFundeeRN && npx jest src/domain/__tests__ src/repositories/__tests__ --no-coverage` |
| **Full suite command** | `cd SundeeFundeeRN && npx jest --coverage` |
| **Estimated runtime** | ~30 seconds (quick), ~90 seconds (full) |

---

## Sampling Rate

- **After every task commit:** Run `cd SundeeFundeeRN && npx jest src/domain/__tests__ src/repositories/__tests__ --no-coverage`
- **After every plan wave:** Run `cd SundeeFundeeRN && npx jest --coverage`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| TBD | repos | 1 | CYCL-01 | unit | `npx jest src/repositories/__tests__/CycleRepo.test.ts -x` | ❌ W0 | ⬜ pending |
| TBD | repos | 1 | INJR-01, INJR-03 | unit | `npx jest src/repositories/__tests__/InjuryRepo.test.ts -x` | ❌ W0 | ⬜ pending |
| TBD | repos | 1 | PROG-01..04 | unit | `npx jest src/repositories/__tests__/ProgramRepo.test.ts -x` | ❌ W0 | ⬜ pending |
| TBD | repos | 1 | BNCH-01..04 | unit | `npx jest src/repositories/__tests__/BenchmarkRepo.test.ts -x` | ❌ W0 | ⬜ pending |
| TBD | repos | 1 | WODS-01, WODS-02 | unit | `npx jest src/repositories/__tests__/WODRepo.test.ts -x` | ❌ W0 | ⬜ pending |
| TBD | domain | 1 | CYCL-03, CYCL-04 | unit | `npx jest src/domain/__tests__/cycle.test.ts -x` | ✅ | ⬜ pending |
| TBD | domain | 1 | CYAD-01..03 | unit | `npx jest src/domain/__tests__/cycle.test.ts -x` | ✅ | ⬜ pending |
| TBD | domain | 1 | READ-01, READ-02 | unit | `npx jest src/domain/__tests__/cycle.test.ts -x` | ✅ | ⬜ pending |
| TBD | domain | 1 | INJR-02..06 | unit | `npx jest src/domain/__tests__/injury.test.ts -x` | ✅ | ⬜ pending |
| TBD | domain | 1 | AIWK-04 | unit | `npx jest src/domain/__tests__/ai-workout.test.ts -x` | ✅ | ⬜ pending |
| TBD | domain | 1 | BNCH-02 | unit | `npx jest src/domain/__tests__/benchmarks.test.ts -x` | ❌ W0 | ⬜ pending |
| TBD | cloud-fn | 2 | AIWK-01, AIWK-02 | unit | `cd functions && npx jest -x` | ❌ W0 | ⬜ pending |
| TBD | UI | 2 | CYCL-05 | unit | `npx jest src/components/__tests__/CyclePhaseBanner.test.tsx -x` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `SundeeFundeeRN/src/repositories/__tests__/CycleRepo.test.ts` — stubs for CYCL-01
- [ ] `SundeeFundeeRN/src/repositories/__tests__/InjuryRepo.test.ts` — stubs for INJR-01, INJR-03
- [ ] `SundeeFundeeRN/src/repositories/__tests__/ProgramRepo.test.ts` — stubs for PROG-01..04
- [ ] `SundeeFundeeRN/src/repositories/__tests__/BenchmarkRepo.test.ts` — stubs for BNCH-01..04
- [ ] `SundeeFundeeRN/src/repositories/__tests__/WODRepo.test.ts` — stubs for WODS-01, WODS-02
- [ ] `SundeeFundeeRN/src/domain/__tests__/benchmarks.test.ts` — benchmark catalog + encode/decode tests
- [ ] `SundeeFundeeRN/src/components/__tests__/CyclePhaseBanner.test.tsx` — cycle opt-in gating test
- [ ] `functions/__tests__/generateWorkout.test.ts` — Gemini Cloud Function tests

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Body map tap selects correct region | INJR-01 | Visual SVG hit area requires device testing | Tap each body region, verify correct BodyLocation selected |
| Calendar period range display | CYCL-01 | Visual calendar rendering | Log period start/end, verify range highlights correctly |
| AI workout preview renders correctly | AIWK-01 | Visual layout + loading state | Generate workout, verify preview shows exercises/sets/reps |
| Offline fallback badge appears | AIWK-04 | Network state simulation | Enable airplane mode, generate workout, verify badge |
| Adaptation indicators show on workout sets | CYAD-01, CYAD-02 | Visual inline indicator | Log period dates, start workout, verify "↓ 10%" indicators |
| Dashboard cycle phase banner | CYCL-04 | Visual banner rendering | Opt into cycle tracking, verify "Follicular — Day 8" banner |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
