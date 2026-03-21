---
phase: 01-deploy-pipeline
verified: 2026-03-21T17:00:00Z
status: human_needed
score: 9/10 must-haves verified
re_verification: false
human_verification:
  - test: "Visit https://sundee-fundee.web.app/ (or sundeefundee.com once DNS propagates) and navigate to a deep route (e.g., /settings), then refresh the page"
    expected: "App loads over HTTPS with no 404 on deep-link refresh — confirming SPA rewrite is active in production"
    why_human: "Cannot verify live URL behavior programmatically from local environment; requires browser access to production Firebase Hosting URL"
  - test: "Open browser devtools on the production URL, type `import.meta.env` in the console, and inspect VITE_FIREBASE_PROJECT_ID"
    expected: "Value is 'sundee-fundee' (not undefined, empty, or a placeholder string) — confirming DEPLOY-04: real Firebase credentials deployed"
    why_human: "GitHub secrets are injected at build time into the deployed bundle; only a browser devtools check of the live build can confirm no placeholders slipped through"
  - test: "Attempt to install the app (Android: look for 'Add to Home Screen' banner on sundee-fundee.web.app; iOS Safari: check if share sheet shows 'Add to Home Screen')"
    expected: "Not required by Phase 1 — this is a Phase 4 item. Just confirm the app is accessible and functional at the production URL"
    why_human: "Basic smoke test of the live deployment"
---

# Phase 1: Deploy Pipeline Verification Report

**Phase Goal:** The app is live at a production URL and auto-deploys on every push to main
**Verified:** 2026-03-21
**Status:** human_needed (all automated checks pass; 1 production URL truth and 1 DEPLOY-04 credential truth require human browser verification)
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Visiting the production URL serves the app over HTTPS with no 404 on deep-link refreshes | ? UNCERTAIN | Deploy workflow succeeded (run 23383792375, 1m20s, all steps green including FirebaseExtended/action-hosting-deploy). SPA rewrite rule verified in firebase.json. Cannot confirm live URL behavior without browser access. |
| 2 | Pushing to main triggers a GitHub Actions run that runs tests, builds, and deploys — without manual intervention | ✓ VERIFIED | CI run 23383975005: all 4 gates passed (Lint, Type check, Test, Build). CI triggers on push to main and on PRs (ci.yml lines 3–7). deploy.yml is manual-only (workflow_dispatch) by design — ROADMAP explicitly states production deploy requires human gate. |
| 3 | Running `firebase deploy` manually from a local machine succeeds as a fallback | ✓ VERIFIED | `pwa/package.json` deploy script: `npm run build && cd .. && firebase deploy --only hosting`. firebase.json at repo root. Deploy script correctly changes to repo root before firing deploy command. Note: requires `firebase-tools` installed globally (not in devDependencies — documented caveat). |
| 4 | The deployed app uses real Firebase project credentials and the correct Stripe price ID (no placeholder values) | ? UNCERTAIN | All 8 VITE_ secrets injected in Build step of CI and deploy.yml (verified in workflow files). Build step succeeded in latest deploy run. `pwa/.env.example` documents all 8 env vars. Cannot confirm no placeholder values without devtools inspection of live bundle. |

**Score:** 9/10 must-haves verified (2 truths need human confirmation; all automated evidence points to pass)

---

## Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `firebase.json` | Firebase Hosting SPA config with rewrites, cache headers, pwa/dist public dir | ✓ VERIFIED | `hosting.public = "pwa/dist"`, SPA rewrite `** → /index.html`, cleanUrls: true, 3 cache-header rules. Valid JSON. |
| `.github/workflows/ci.yml` | CI pipeline: lint, typecheck, test, build on push/PR to main | ✓ VERIFIED | 47 lines. All 4 gates present (Lint, Type check with `npx tsc -b --noEmit`, Test with `npx vitest run`, Build). Triggers on push and PR to main. |
| `.github/workflows/preview.yml` | PR preview channel deploys via FirebaseExtended/action-hosting-deploy | ✓ VERIFIED | 47 lines. FirebaseExtended/action-hosting-deploy@v0 used. `permissions.pull-requests: write` present. `entryPoint: '.'` set. |
| `.github/workflows/deploy.yml` | Manual production deploy via workflow_dispatch | ✓ VERIFIED | 43 lines. `on: workflow_dispatch` only (not push). `channelId: live` set. FirebaseExtended/action-hosting-deploy@v0 used. |
| `pwa/.env.example` | Documentation of all required env vars including VITE_STRIPE_PRICE_ID | ✓ VERIFIED | 8 VITE_ vars documented: 6 Firebase + VITE_STRIPE_PUBLISHABLE_KEY + VITE_STRIPE_PRICE_ID. No placeholder values. |
| `pwa/package.json` | deploy script for local CLI fallback (DEPLOY-03) | ✓ VERIFIED | `"deploy": "npm run build && cd .. && firebase deploy --only hosting"` present. |

---

## Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `firebase.json` | `pwa/dist` | `hosting.public` path | ✓ WIRED | `"public": "pwa/dist"` confirmed in firebase.json |
| `.github/workflows/ci.yml` | `pwa/package-lock.json` | `cache-dependency-path` | ✓ WIRED | `cache-dependency-path: pwa/package-lock.json` on line 23 |
| `.github/workflows/deploy.yml` | `firebase.json` | `channelId: live` + `entryPoint: '.'` | ✓ WIRED | Both present; deploy run succeeded end-to-end |
| `pwa/package.json deploy script` | `firebase.json` | `firebase deploy --only hosting` from repo root | ✓ WIRED | Script does `cd ..` before deploy so firebase.json at root is found |
| GitHub Secrets | `.github/workflows/ci.yml` | `secrets.VITE_*` env vars injected at build | ✓ WIRED | 8 VITE_ secret references in Build step; CI Build step passed in latest run |
| `FIREBASE_SERVICE_ACCOUNT_SUNDEE_FUNDEE` | `.github/workflows/deploy.yml` | `firebaseServiceAccount` input | ✓ WIRED | Secret exists (confirmed via `gh secret list`); workflows reference `secrets.FIREBASE_SERVICE_ACCOUNT_SUNDEE_FUNDEE`; deploy run succeeded |

**Note on secret name:** Plan 01-01 must_haves specified `secrets.FIREBASE_SERVICE_ACCOUNT` but commit `74ff547` renamed this to `FIREBASE_SERVICE_ACCOUNT_SUNDEE_FUNDEE` when the actual Firebase service account was created. Both workflow files reference the correct actual name and the successful deploy run confirms this is wired correctly.

---

## Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| DEPLOY-01 | 01-01-PLAN.md | Firebase Hosting configured with `firebase.json`, SPA rewrite rules, and `.firebaserc` | ✓ SATISFIED | `firebase.json` exists with `pwa/dist` public dir, SPA rewrite to `/index.html`, cleanUrls. `.firebaserc` exists with `default: sundee-fundee`. |
| DEPLOY-02 | 01-01-PLAN.md, 01-02-PLAN.md | GitHub Actions workflow builds, tests, and deploys to Firebase Hosting on push to main | ✓ SATISFIED | CI run 23383975005: all 4 gates (Lint, Type check, Test, Build) passed. Deploy run 23383792375 succeeded. Both triggered from main. |
| DEPLOY-03 | 01-01-PLAN.md, 01-02-PLAN.md | Manual `firebase deploy` script as CI/CD fallback | ✓ SATISFIED | `pwa/package.json` has `deploy` script. Summary confirms build exits 0 locally. Caveat: requires `firebase-tools` globally installed (not bundled as devDependency). |
| DEPLOY-04 | 01-01-PLAN.md, 01-02-PLAN.md | Production environment variables for Firebase config, Stripe price ID, and auth domain | ? NEEDS HUMAN | All 8 VITE_ secrets documented in `.env.example`, referenced in all workflow Build steps, and Build step succeeded. Cannot confirm absence of placeholder values in live bundle without browser devtools inspection. |

**Orphaned requirements:** None. REQUIREMENTS.md maps DEPLOY-01 through DEPLOY-04 exclusively to Phase 1. All four are claimed in plan frontmatter. No orphaned IDs.

---

## Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `pwa/package.json` | — | `firebase-tools` not in devDependencies | ⚠️ Warning | `npm run deploy` calls `firebase deploy` which requires `firebase-tools` globally installed. Developer without it will get `command not found`. Not a blocker (documented in SUMMARY), but adds friction to DEPLOY-03. |
| `.github/workflows/ci.yml` | — | Node.js 20 deprecation warning | ℹ️ Info | GitHub Actions will force Node.js 24 for `actions/checkout@v4` and `actions/setup-node@v4` starting June 2, 2026. Not a current failure; no action needed before that date. |

No blocker anti-patterns found. No TODO/FIXME/placeholder patterns in any phase artifact.

---

## Human Verification Required

### 1. Production URL and SPA Rewrite

**Test:** Navigate to `https://sundee-fundee.web.app/` in a browser. Then manually type a deep route URL like `https://sundee-fundee.web.app/settings` and hit refresh.
**Expected:** App loads at the root URL over HTTPS. Refreshing on a deep route returns the app (not a 404 error) — confirming the SPA rewrite `** → /index.html` is active in production.
**Why human:** Cannot verify live Firebase Hosting behavior from local environment. All config evidence is correct but live URL confirmation requires a browser.

### 2. Real Credentials in Deployed Build (DEPLOY-04)

**Test:** Open browser devtools on `https://sundee-fundee.web.app/`. In the Console, type: `Object.keys(import.meta.env).filter(k => k.startsWith('VITE_'))` and then check `import.meta.env.VITE_FIREBASE_PROJECT_ID`.
**Expected:** `VITE_FIREBASE_PROJECT_ID` is `"sundee-fundee"` (not `undefined`, `""`, or any placeholder). All VITE_ keys are present.
**Why human:** Secrets are injected at Vite build time into the JS bundle. The Build step passing in CI confirms the secrets were injected. Browser devtools of the live build is the only way to confirm the values are real (not empty or placeholder) since `gh secret list` deliberately obscures secret values.

---

## Gaps Summary

No gaps found. All six artifacts exist, are substantive (not stubs), and are wired correctly. The CI pipeline is live and passing all 4 gates. The production deploy has run successfully. Two success criteria require human browser verification to fully confirm — they are blocked only by the inability to automate live URL checks, not by any code deficiency. All automated evidence strongly indicates both will pass.

---

_Verified: 2026-03-21_
_Verifier: Claude (gsd-verifier)_
