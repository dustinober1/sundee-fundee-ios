---
phase: 1
slug: deploy-pipeline
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-21
---

# Phase 1 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Vitest 4.x |
| **Config file** | `pwa/vitest.config.ts` |
| **Quick run command** | `cd pwa && npx vitest run` |
| **Full suite command** | `cd pwa && npx vitest run` |
| **Estimated runtime** | ~15 seconds |

---

## Sampling Rate

- **After every task commit:** Run `cd pwa && npx vitest run`
- **After every plan wave:** Run `cd pwa && npx vitest run` + `firebase deploy --dry-run`
- **Before `/gsd:verify-work`:** Full suite must be green + live site returns 200
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 01-01-01 | 01 | 1 | DEPLOY-01 | manual smoke | `firebase deploy --only hosting --dry-run` | ❌ W0 | ⬜ pending |
| 01-01-02 | 01 | 1 | DEPLOY-04 | manual smoke | Browser devtools check | ❌ W0 | ⬜ pending |
| 01-02-01 | 02 | 2 | DEPLOY-02 | CI gate | Workflow runs on push to main | ❌ W0 | ⬜ pending |
| 01-02-02 | 02 | 2 | DEPLOY-03 | manual | `firebase deploy --only hosting` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `firebase.json` — at repo root with correct `public`, rewrites, headers (DEPLOY-01)
- [ ] `.github/workflows/ci.yml` — lint/typecheck/test/build on push (DEPLOY-02)
- [ ] `.github/workflows/preview.yml` — PR preview channels (DEPLOY-02)
- [ ] `.github/workflows/deploy.yml` — manual dispatch fallback (DEPLOY-03)
- [ ] `pwa/.env.example` — add missing `VITE_STRIPE_PRICE_ID` line
- [ ] GitHub Secrets — 8 secrets: 6 Firebase + Stripe keys + service account

*Wave 0 creates all infrastructure config files.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Production URL serves app over HTTPS | DEPLOY-01 | Requires live deployment + DNS | Visit `sundeefundee.com`, verify HTTPS, check deep-link refresh |
| Deployed app uses real credentials | DEPLOY-04 | Requires checking deployed runtime env | Open browser devtools, verify `import.meta.env.VITE_FIREBASE_PROJECT_ID` is not a placeholder |
| GitHub Actions auto-deploy on push | DEPLOY-02 | Requires actual push to main | Push a commit, verify workflow triggers and completes |
| Manual `firebase deploy` succeeds | DEPLOY-03 | Requires local Firebase CLI auth | Run `firebase deploy --only hosting` from local machine |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
