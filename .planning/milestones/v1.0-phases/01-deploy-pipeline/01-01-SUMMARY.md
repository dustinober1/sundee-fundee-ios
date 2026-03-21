---
phase: 01-deploy-pipeline
plan: 01
subsystem: infra
tags: [firebase, github-actions, ci-cd, vite, hosting]

# Dependency graph
requires: []
provides:
  - firebase.json SPA hosting config targeting pwa/dist with rewrites, cache headers, cleanUrls
  - GitHub Actions CI pipeline (lint, typecheck, test, build) on push/PR to main
  - GitHub Actions PR preview channel deploys via FirebaseExtended/action-hosting-deploy
  - GitHub Actions manual production deploy workflow via workflow_dispatch
  - pwa/package.json deploy script for local CLI fallback
  - pwa/.env.example documenting all 8 required environment variables
affects: [02-cloudkit-activation, all phases]

# Tech tracking
tech-stack:
  added: [FirebaseExtended/action-hosting-deploy@v0, GitHub Actions, Node 20 LTS]
  patterns: [monorepo CI with pwa/ working-directory, sequential CI gate, manual prod dispatch]

key-files:
  created:
    - firebase.json
    - .github/workflows/ci.yml
    - .github/workflows/preview.yml
    - .github/workflows/deploy.yml
  modified:
    - pwa/package.json
    - pwa/.env.example

key-decisions:
  - "Three separate workflow files (ci.yml, preview.yml, deploy.yml) for separation of concerns"
  - "Production deploy is manual workflow_dispatch only — not auto-deploy on push"
  - "npx tsc -b --noEmit (not tsc --noEmit) to match project references build mode in package.json"
  - "Node 20 LTS (Node 18 EOL)"
  - "npm cache via setup-node cache-dependency-path: pwa/package-lock.json"
  - "entryPoint: '.' in FirebaseExtended action so it finds firebase.json at repo root"

patterns-established:
  - "CI working-directory: pwa via defaults.run for sequential job steps"
  - "All 8 VITE_ secrets injected only at the Build step (not lint/typecheck/test)"
  - "preview.yml requires permissions.pull-requests: write to post PR comment with preview URL"

requirements-completed: [DEPLOY-01, DEPLOY-02, DEPLOY-03, DEPLOY-04]

# Metrics
duration: 1min
completed: 2026-03-21
---

# Phase 1 Plan 1: Deploy Pipeline — Firebase Hosting + CI/CD Workflows Summary

**Firebase Hosting SPA config, three GitHub Actions workflows (CI gate, PR preview deploy, manual production dispatch), and local deploy script wired to pwa/dist via firebase.json at repo root**

## Performance

- **Duration:** 1 min
- **Started:** 2026-03-21T15:44:07Z
- **Completed:** 2026-03-21T15:45:19Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments

- firebase.json configured at repo root: `pwa/dist` public dir, SPA rewrite (all routes → index.html), no-cache headers for index.html and sw.js, immutable 1-year cache for versioned assets
- Three GitHub Actions workflows cover the full CD lifecycle: CI gates on push/PR, preview deploys on PRs, manual production dispatch
- pwa/package.json `deploy` script enables `cd pwa && npm run deploy` as local CLI fallback without GitHub Actions
- pwa/.env.example now documents all 8 required env vars (added VITE_STRIPE_PRICE_ID)

## Task Commits

Each task was committed atomically:

1. **Task 1: Create firebase.json, update pwa/package.json and .env.example** - `3692201` (feat)
2. **Task 2: Create GitHub Actions workflow files (CI, preview, deploy)** - `d053a27` (feat)

## Files Created/Modified

- `firebase.json` - Firebase Hosting SPA config: pwa/dist public dir, cleanUrls, SPA rewrite, cache headers
- `.github/workflows/ci.yml` - CI pipeline: lint, typecheck (tsc -b --noEmit), test (vitest run), build on push/PR to main
- `.github/workflows/preview.yml` - PR preview channel deploy via FirebaseExtended/action-hosting-deploy with PR comment
- `.github/workflows/deploy.yml` - Manual workflow_dispatch production deploy to live channel
- `pwa/package.json` - Added `deploy` script: `npm run build && cd .. && firebase deploy --only hosting`
- `pwa/.env.example` - Added VITE_STRIPE_PRICE_ID (now documents all 8 env vars)

## Decisions Made

- Three separate workflow files rather than a monolith: cleaner separation, easier to disable preview or deploy independently
- Production deploy is `workflow_dispatch` only (not auto-deploy on push to main) — deliberate human gate before production
- `npx tsc -b --noEmit` (not `tsc --noEmit`) in CI to match the `tsc -b` project references build mode used by `npm run build`; `tsc --noEmit` alone does not honor project references
- Node 20 LTS throughout (Node 18 reached EOL October 2024)
- `entryPoint: '.'` in both FirebaseExtended action steps so the action finds firebase.json at repo root (not in pwa/)
- CI uses `defaults.run.working-directory: pwa` for the sequential lint/typecheck/test/build job; preview and deploy use explicit `working-directory: pwa` per-step since they mix pwa steps with FirebaseExtended action steps that need repo root context

## Deviations from Plan

None — plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

Before workflows can run, add these secrets to the GitHub repository (Settings > Secrets and variables > Actions):

- `VITE_FIREBASE_API_KEY`
- `VITE_FIREBASE_AUTH_DOMAIN`
- `VITE_FIREBASE_PROJECT_ID`
- `VITE_FIREBASE_STORAGE_BUCKET`
- `VITE_FIREBASE_MESSAGING_SENDER_ID`
- `VITE_FIREBASE_APP_ID`
- `VITE_STRIPE_PUBLISHABLE_KEY`
- `VITE_STRIPE_PRICE_ID`
- `FIREBASE_SERVICE_ACCOUNT` — service account JSON from Firebase Console > Project Settings > Service Accounts > Generate new private key

## Next Phase Readiness

- Deploy pipeline is fully wired. CI will run automatically on next push to main.
- Production deploy requires `FIREBASE_SERVICE_ACCOUNT` secret to be set in GitHub before first dispatch.
- Phase 2 (CloudKit activation) is independent of deploy pipeline; pipeline will validate all Phase 2 code automatically.

---
*Phase: 01-deploy-pipeline*
*Completed: 2026-03-21*
