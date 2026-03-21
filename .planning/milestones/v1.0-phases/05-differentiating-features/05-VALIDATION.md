---
phase: 05
slug: differentiating-features
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-21
---

# Phase 05 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Vitest ^4.1.0 + @testing-library/react ^16.3.2 |
| **Config file** | `pwa/vitest.config.ts` |
| **Quick run command** | `cd pwa && npx vitest run src/routes/RootErrorBoundary.test.tsx src/routes/AppErrorBoundary.test.tsx src/components/Skeleton.test.tsx src/routes/NotFound.test.tsx` |
| **Full suite command** | `cd pwa && npx vitest run` |
| **Estimated runtime** | ~15 seconds |

---

## Sampling Rate

- **After every task commit:** Run `cd pwa && npx vitest run src/routes/RootErrorBoundary.test.tsx src/routes/AppErrorBoundary.test.tsx src/components/Skeleton.test.tsx src/routes/NotFound.test.tsx`
- **After every plan wave:** Run `cd pwa && npx vitest run`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 15 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 05-00-01 | 00 | 0 | UX-01 | unit | `cd pwa && npx vitest run src/routes/RootErrorBoundary.test.tsx` | ❌ W0 | ⬜ pending |
| 05-00-02 | 00 | 0 | UX-01 | unit | `cd pwa && npx vitest run src/routes/AppErrorBoundary.test.tsx` | ❌ W0 | ⬜ pending |
| 05-00-03 | 00 | 0 | UX-02 | unit | `cd pwa && npx vitest run src/components/Skeleton.test.tsx` | ❌ W0 | ⬜ pending |
| 05-00-04 | 00 | 0 | UX-03 | unit | `cd pwa && npx vitest run src/routes/NotFound.test.tsx` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `pwa/src/routes/RootErrorBoundary.test.tsx` — stubs for UX-01 (root error boundary renders heading, message, reload link)
- [ ] `pwa/src/routes/AppErrorBoundary.test.tsx` — stubs for UX-01 (app error boundary renders recovery UI, dashboard link)
- [ ] `pwa/src/components/Skeleton.test.tsx` — stubs for UX-02 (SkeletonCard renders N shimmer divs)
- [ ] `pwa/src/routes/NotFound.test.tsx` — stubs for UX-03 (404 heading, home link)

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Shimmer animation visually smooth | UX-02 | CSS animation quality is visual | Open Dashboard/Programs/History/Cycle/Maxes with slow network; verify shimmer pulses smoothly |
| Error boundary resets on navigation | UX-01 | Requires triggering real render error + navigating | Temporarily throw in a route component, verify error UI shows, click recovery link, verify app recovers |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 15s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
