# Phase 1: Deploy Pipeline - Research

**Researched:** 2026-03-21
**Domain:** Firebase Hosting + GitHub Actions CI/CD + Custom Domain + Vite env vars
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- Production URL: sundeefundee.com (root domain, not a subdomain)
- DNS access available; can add A/CNAME records during this phase
- Firebase Auth custom domain: sundeefundee.com (sign-in popups show branded domain)
- DNS verification and SSL provisioning included in this phase
- GitHub Actions pipeline on push to main runs: ESLint lint, TypeScript type check (tsc), Vitest tests, Vite build
- All four steps must pass (gate on everything) — no deploy if any step fails
- PR preview deploys enabled via Firebase Hosting preview channels (each PR gets a unique URL)
- Pipeline authenticates with Firebase via service account JSON stored in GitHub Secrets
- Single production environment (no staging) — PR preview deploys serve as testing surface
- CI reads env vars from GitHub Secrets; local dev uses .env.local (gitignored)
- .env.example stays as documentation of required variables
- All env vars set in this phase: 6 Firebase config keys + VITE_STRIPE_PUBLISHABLE_KEY + VITE_STRIPE_PRICE_ID (real values, not placeholders)
- CI steps (lint, typecheck, test, build) run automatically on push to main
- Production deploy is a separate manual workflow dispatch (not auto-deploy)
- Deploy always deploys latest main (no commit SHA input)
- Rollback strategy: revert commit + redeploy, or use Firebase Hosting's built-in rollback

### Claude's Discretion
- GitHub Actions workflow file structure (single vs multi-file)
- firebase.json hosting configuration details (rewrites, headers, cache policy)
- Whether to run CI steps in parallel or sequentially in the workflow
- Node version and caching strategy in GitHub Actions

### Deferred Ideas (OUT OF SCOPE)
- None — discussion stayed within phase scope
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| DEPLOY-01 | Firebase Hosting configured with `firebase.json`, SPA rewrite rules, and `.firebaserc` | firebase.json schema documented; SPA rewrite pattern confirmed; .firebaserc already exists |
| DEPLOY-02 | GitHub Actions workflow builds, tests, and deploys to Firebase Hosting on push to main | FirebaseExtended/action-hosting-deploy action confirmed; workflow YAML patterns documented |
| DEPLOY-03 | Manual `firebase deploy` script as CI/CD fallback | workflow_dispatch trigger documented; firebase CLI deploy command confirmed |
| DEPLOY-04 | Production environment variables for Firebase config, Stripe price ID, and auth domain | Vite VITE_ prefix env var injection via GitHub Secrets build step env: block documented |
</phase_requirements>

---

## Summary

Phase 1 establishes the complete deploy pipeline for the Sundee Fundee PWA: a `firebase.json` at repo root, a GitHub Actions CI workflow (lint + typecheck + test + build on push to main), a separate manual `workflow_dispatch` deploy workflow, and PR preview channels via `FirebaseExtended/action-hosting-deploy`. The build output lives in `pwa/dist/` and `firebase.json` must point `hosting.public` there. All VITE_ env vars are injected at build time from GitHub Secrets via the workflow's `env:` block.

Custom domain setup requires adding two Firebase-provided A records to the DNS registrar, a TXT record for domain ownership verification, and authorizing `sundeefundee.com` as an allowed domain in Firebase Auth. VITE_FIREBASE_AUTH_DOMAIN must then be set to `sundeefundee.com` (not the default `sundee-fundee.firebaseapp.com`) so sign-in popups show the branded domain.

Three separate workflow files are recommended: `ci.yml` (lint + typecheck + test + build on push/PR to main), `preview.yml` (PR preview channel deploy), and `deploy.yml` (manual `workflow_dispatch` production deploy). This keeps concerns cleanly separated and allows the deploy workflow to be triggered independently without re-running all CI steps.

**Primary recommendation:** Use `FirebaseExtended/action-hosting-deploy@v0` for both preview and production deploys; use `actions/setup-node@v4` with `cache: 'npm'` and Node 20 LTS; run CI steps sequentially (they are fast and sequential failure feedback is clearer).

---

## Standard Stack

### Core

| Library / Tool | Version | Purpose | Why Standard |
|----------------|---------|---------|--------------|
| `FirebaseExtended/action-hosting-deploy` | `v0` | Deploy to Firebase Hosting from GitHub Actions | Official Firebase action; handles preview channels + PR comments |
| `actions/checkout` | `v4` | Checkout repo in CI | Standard, maintained by GitHub |
| `actions/setup-node` | `v4` | Set up Node.js with npm caching | Standard, `cache: 'npm'` built in |
| Firebase CLI (`firebase-tools`) | latest | Local deploy fallback + CI deploy via action | Official CLI; action wraps it internally |
| Vite | `^8.0.1` (already installed) | Build tool — `npm run build` in `pwa/` | Already in project |
| Vitest | `^4.1.0` (already installed) | Test runner — `npx vitest run` in `pwa/` | Already in project |

### Supporting

| Library / Tool | Version | Purpose | When to Use |
|----------------|---------|---------|-------------|
| `actions/cache` | `v4` | Manual npm cache if setup-node cache insufficient | Only if `actions/setup-node cache: npm` proves slow |
| Firebase CLI (local) | latest | `firebase deploy --only hosting` fallback | DEPLOY-03 manual fallback requirement |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `FirebaseExtended/action-hosting-deploy` | `w9jds/firebase-action` | firebase-action is community-maintained, less feature-complete; preview channels only work with the official action |
| Service account JSON | Workload Identity Federation | WIF is more secure but Firebase Admin SDK does not support WIF — project already decided service account JSON |
| Three workflow files | Single workflow file | Single file is simpler but mixing CI and deploy in one file makes manual dispatch awkward; three files is cleaner |

**Installation (local Firebase CLI for DEPLOY-03 fallback):**
```bash
npm install -g firebase-tools
firebase login
firebase deploy --only hosting
```

---

## Architecture Patterns

### Recommended File Structure

```
.github/
  workflows/
    ci.yml          # lint + typecheck + test + build on push/PR to main
    preview.yml     # preview channel deploy on pull_request
    deploy.yml      # manual workflow_dispatch production deploy
firebase.json       # at repo root (alongside .firebaserc)
.firebaserc         # already exists: { "projects": { "default": "sundee-fundee" } }
pwa/
  dist/             # Vite build output — firebase.json hosting.public points here
  .env.local        # local dev only, gitignored
  .env.example      # documentation of required vars (already exists)
```

### Pattern 1: firebase.json for SPA with pwa/dist build output

**What:** Single firebase.json at repo root. `hosting.public` points to `pwa/dist`. SPA rewrite sends all routes to `index.html`. Cache-busting headers on HTML, long-lived cache on versioned assets.

**When to use:** Always — this is the only firebase.json needed.

```json
{
  "hosting": {
    "public": "pwa/dist",
    "ignore": [
      "firebase.json",
      "**/.*",
      "**/node_modules/**"
    ],
    "cleanUrls": true,
    "rewrites": [
      {
        "source": "**",
        "destination": "/index.html"
      }
    ],
    "headers": [
      {
        "source": "/index.html",
        "headers": [
          { "key": "Cache-Control", "value": "no-cache, no-store, must-revalidate" }
        ]
      },
      {
        "source": "**/*.@(js|css|woff2|png|jpg|svg|ico)",
        "headers": [
          { "key": "Cache-Control", "value": "public, max-age=31536000, immutable" }
        ]
      }
    ]
  }
}
```

**Why `pwa/dist` and not `dist`:** Vite's `outDir` defaults to `dist` relative to the project root (`pwa/`), so the actual output path from the repo root is `pwa/dist`. Firebase CLI resolves `hosting.public` relative to `firebase.json` location (repo root).

### Pattern 2: CI Workflow (ci.yml) — sequential steps

**What:** Runs on every push to main and every PR targeting main. Four sequential steps: lint → typecheck → test → build. All must pass. Injects VITE_ env vars from GitHub Secrets for the build step.

**When to use:** Gatekeeper on main. No deploy in this workflow.

```yaml
# Source: FirebaseExtended/action-hosting-deploy docs + vitest CI patterns
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  ci:
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: pwa

    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
          cache-dependency-path: pwa/package-lock.json

      - name: Install dependencies
        run: npm ci

      - name: Lint
        run: npm run lint

      - name: Type check
        run: npx tsc --noEmit

      - name: Test
        run: npx vitest run

      - name: Build
        run: npm run build
        env:
          VITE_FIREBASE_API_KEY: ${{ secrets.VITE_FIREBASE_API_KEY }}
          VITE_FIREBASE_AUTH_DOMAIN: ${{ secrets.VITE_FIREBASE_AUTH_DOMAIN }}
          VITE_FIREBASE_PROJECT_ID: ${{ secrets.VITE_FIREBASE_PROJECT_ID }}
          VITE_FIREBASE_STORAGE_BUCKET: ${{ secrets.VITE_FIREBASE_STORAGE_BUCKET }}
          VITE_FIREBASE_MESSAGING_SENDER_ID: ${{ secrets.VITE_FIREBASE_MESSAGING_SENDER_ID }}
          VITE_FIREBASE_APP_ID: ${{ secrets.VITE_FIREBASE_APP_ID }}
          VITE_STRIPE_PUBLISHABLE_KEY: ${{ secrets.VITE_STRIPE_PUBLISHABLE_KEY }}
          VITE_STRIPE_PRICE_ID: ${{ secrets.VITE_STRIPE_PRICE_ID }}
```

**Note on `working-directory`:** Setting `defaults.run.working-directory: pwa` means all `run:` steps execute in `pwa/`. This avoids `cd pwa &&` prefix on every step. The `actions/checkout` and `actions/setup-node` steps always run at repo root regardless.

**Note on `npm ci` vs `npm install`:** Use `npm ci` in CI — it installs exactly what's in `package-lock.json`, is faster, and fails if lock file is out of sync.

### Pattern 3: PR Preview Channel Workflow (preview.yml)

**What:** Runs on every PR. Builds the app and deploys to a Firebase Hosting preview channel. The action posts the preview URL as a PR comment automatically.

```yaml
# Source: FirebaseExtended/action-hosting-deploy README
name: Deploy Preview

on:
  pull_request:
    branches: [main]

jobs:
  preview:
    runs-on: ubuntu-latest
    permissions:
      checks: write
      contents: read
      pull-requests: write

    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
          cache-dependency-path: pwa/package-lock.json

      - name: Install dependencies
        working-directory: pwa
        run: npm ci

      - name: Build
        working-directory: pwa
        run: npm run build
        env:
          VITE_FIREBASE_API_KEY: ${{ secrets.VITE_FIREBASE_API_KEY }}
          VITE_FIREBASE_AUTH_DOMAIN: ${{ secrets.VITE_FIREBASE_AUTH_DOMAIN }}
          VITE_FIREBASE_PROJECT_ID: ${{ secrets.VITE_FIREBASE_PROJECT_ID }}
          VITE_FIREBASE_STORAGE_BUCKET: ${{ secrets.VITE_FIREBASE_STORAGE_BUCKET }}
          VITE_FIREBASE_MESSAGING_SENDER_ID: ${{ secrets.VITE_FIREBASE_MESSAGING_SENDER_ID }}
          VITE_FIREBASE_APP_ID: ${{ secrets.VITE_FIREBASE_APP_ID }}
          VITE_STRIPE_PUBLISHABLE_KEY: ${{ secrets.VITE_STRIPE_PUBLISHABLE_KEY }}
          VITE_STRIPE_PRICE_ID: ${{ secrets.VITE_STRIPE_PRICE_ID }}

      - uses: FirebaseExtended/action-hosting-deploy@v0
        with:
          repoToken: ${{ secrets.GITHUB_TOKEN }}
          firebaseServiceAccount: ${{ secrets.FIREBASE_SERVICE_ACCOUNT }}
          expires: 30d
          projectId: sundee-fundee
          entryPoint: '.'
```

**`entryPoint: '.'`** tells the action where `firebase.json` lives — repo root, which is the default. Explicitly setting it is safe and makes it clear.

### Pattern 4: Manual Production Deploy Workflow (deploy.yml)

**What:** Manual `workflow_dispatch` trigger only. Always deploys latest main. The action deploys to the `live` channel.

```yaml
# Source: FirebaseExtended/action-hosting-deploy README
name: Deploy Production

on:
  workflow_dispatch:

jobs:
  deploy:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4
        with:
          ref: main

      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
          cache-dependency-path: pwa/package-lock.json

      - name: Install dependencies
        working-directory: pwa
        run: npm ci

      - name: Build
        working-directory: pwa
        run: npm run build
        env:
          VITE_FIREBASE_API_KEY: ${{ secrets.VITE_FIREBASE_API_KEY }}
          VITE_FIREBASE_AUTH_DOMAIN: ${{ secrets.VITE_FIREBASE_AUTH_DOMAIN }}
          VITE_FIREBASE_PROJECT_ID: ${{ secrets.VITE_FIREBASE_PROJECT_ID }}
          VITE_FIREBASE_STORAGE_BUCKET: ${{ secrets.VITE_FIREBASE_STORAGE_BUCKET }}
          VITE_FIREBASE_MESSAGING_SENDER_ID: ${{ secrets.VITE_FIREBASE_MESSAGING_SENDER_ID }}
          VITE_FIREBASE_APP_ID: ${{ secrets.VITE_FIREBASE_APP_ID }}
          VITE_STRIPE_PUBLISHABLE_KEY: ${{ secrets.VITE_STRIPE_PUBLISHABLE_KEY }}
          VITE_STRIPE_PRICE_ID: ${{ secrets.VITE_STRIPE_PRICE_ID }}

      - uses: FirebaseExtended/action-hosting-deploy@v0
        with:
          firebaseServiceAccount: ${{ secrets.FIREBASE_SERVICE_ACCOUNT }}
          projectId: sundee-fundee
          channelId: live
          entryPoint: '.'
```

**No `repoToken`** on the deploy workflow — it's not a PR so there's no PR comment to post.

### Pattern 5: Custom Domain + Auth Domain Setup

**What:** Two-phase process: (1) Firebase Hosting custom domain (DNS + SSL), (2) Firebase Auth authorized domain update + VITE_FIREBASE_AUTH_DOMAIN env var update.

**Step sequence:**
1. Firebase Console → Hosting → Add custom domain → enter `sundeefundee.com`
2. Firebase provides two A records (IP addresses) and a TXT record for ownership verification
3. At DNS registrar: add TXT record first, wait for propagation (up to 24h, usually 1-2h)
4. After TXT verified in Firebase Console: add the two A records, remove any conflicting A/AAAA records
5. Firebase automatically provisions SSL certificate (up to 24h after DNS propagation)
6. Firebase Console → Authentication → Sign-in method → Authorized domains → Add `sundeefundee.com`
7. Google Cloud Console → APIs & Services → OAuth consent screen → Authorized JavaScript origins: add `https://sundeefundee.com`; Authorized redirect URIs: add `https://sundeefundee.com/__/auth/handler`
8. Update GitHub Secret `VITE_FIREBASE_AUTH_DOMAIN` value from `sundee-fundee.firebaseapp.com` to `sundeefundee.com`

**Why step 7 matters:** Google OAuth sign-in will fail with "redirect_uri_mismatch" if the new domain isn't in the OAuth client's authorized origins/redirects.

### Anti-Patterns to Avoid

- **`firebase.json` in `pwa/` subdirectory:** Firebase CLI expects `firebase.json` alongside `.firebaserc` at repo root. Placing it in `pwa/` requires passing `--project` flags everywhere and breaks the GitHub action's default `entryPoint`.
- **Auto-deploy production on every push:** The user decided production deploy is manual `workflow_dispatch`. Do not add `channelId: live` to the CI or preview workflows.
- **`npm install` instead of `npm ci` in CI:** `npm install` can upgrade minor/patch versions; `npm ci` is deterministic and 2-3x faster in CI.
- **Env vars injected at workflow level vs build step level:** Vite inlines `VITE_*` vars at build time. The env vars must be on the `Build` step (or workflow-level `env:` block), not only exported elsewhere.
- **Forgetting `permissions: pull-requests: write`** on the preview workflow: The action needs this to post PR comments with preview URLs.
- **Not removing old A/AAAA records before adding Firebase A records:** Firebase cannot provision SSL if conflicting records exist.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Firebase Hosting deploy in CI | Custom `firebase deploy` shell script in workflow | `FirebaseExtended/action-hosting-deploy@v0` | Handles auth, preview channels, PR comments, expiry management automatically |
| PR preview URL posting | Custom GitHub API calls to post PR comments | `repoToken: ${{ secrets.GITHUB_TOKEN }}` in the action | Built into the action; zero extra code |
| Node.js dependency caching | Manual `actions/cache` steps | `actions/setup-node@v4` with `cache: 'npm'` | Built-in caching is correct and simpler |
| Service account setup | Manually editing GCP IAM JSON | `firebase init hosting:github` CLI command | Auto-creates service account, assigns correct roles, uploads secret to GitHub |

**Key insight:** The `firebase init hosting:github` CLI command is the fastest path to service account setup — it creates the GCP service account with exactly the right IAM roles, generates the JSON key, and uploads it to GitHub Secrets in one step. Do this once locally rather than manual GCP console steps.

---

## Common Pitfalls

### Pitfall 1: `pwa/dist` path in firebase.json

**What goes wrong:** `firebase deploy` or the GitHub action says "hosting.public does not exist" or deploys an empty site.
**Why it happens:** Vite's `outDir` is relative to `pwa/` (the Vite project root), producing `pwa/dist`. Firebase reads `hosting.public` relative to `firebase.json` location (repo root). So `"public": "dist"` looks for `{repo-root}/dist` which doesn't exist.
**How to avoid:** Set `"public": "pwa/dist"` in firebase.json.
**Warning signs:** `firebase deploy` output shows "0 files uploaded" or "Directory does not exist".

### Pitfall 2: Vite env vars not inlined in production build

**What goes wrong:** The deployed app shows blank fields, Firebase fails to initialize, Stripe key is undefined.
**Why it happens:** Vite replaces `import.meta.env.VITE_*` at build time. If the GitHub Actions `Build` step doesn't have those env vars in scope, they resolve to `undefined` and the built JS bundle contains `undefined` literally.
**How to avoid:** Always put all `VITE_*` secrets in the `env:` block of the Build step (not just defined as GitHub Secrets — they must be explicitly mapped into the step env).
**Warning signs:** `import.meta.env.VITE_FIREBASE_API_KEY` is `undefined` in browser devtools on the live site.

### Pitfall 3: OAuth redirect_uri_mismatch after custom domain

**What goes wrong:** Google Sign-In fails with error `redirect_uri_mismatch` after switching to `sundeefundee.com`.
**Why it happens:** Google OAuth client has `sundee-fundee.firebaseapp.com/__/auth/handler` as the only authorized redirect URI. The new domain isn't registered.
**How to avoid:** Before or immediately after DNS cutover, add `https://sundeefundee.com` to authorized JavaScript origins and `https://sundeefundee.com/__/auth/handler` to redirect URIs in GCP Console → OAuth client → sundeefundee.
**Warning signs:** Sign-in popup opens then immediately closes with error; Firebase Auth error code `auth/unauthorized-domain`.

### Pitfall 4: SSL provisioning blocked by conflicting DNS records

**What goes wrong:** Firebase cannot provision SSL certificate; site stays on `http://` or shows certificate error.
**Why it happens:** Existing A records or AAAA records at the apex domain conflict with Firebase's required A records.
**How to avoid:** Before adding Firebase A records, delete all existing A records and AAAA records for the root domain.
**Warning signs:** Firebase Console Hosting page shows "Needs attention" status after DNS changes.

### Pitfall 5: `tsc --noEmit` vs `tsc -b` in CI typecheck step

**What goes wrong:** `npm run build` uses `tsc -b` (project references build mode). Running `tsc --noEmit` in a separate typecheck step may not respect project references if `tsconfig.app.json` / `tsconfig.node.json` split exists.
**Why it happens:** `pwa/` has `tsconfig.json` (references `tsconfig.app.json` and `tsconfig.node.json`). `tsc -b` builds all referenced projects. `tsc --noEmit` targets the root `tsconfig.json`.
**How to avoid:** Run `npx tsc -b --noEmit` (build mode with no-emit) or simply rely on the `Build` step catching type errors since `npm run build` runs `tsc -b` first. If the CI typecheck step runs before the build step, use `npx tsc --noEmit` targeting `tsconfig.app.json`: `npx tsc -p tsconfig.app.json --noEmit`.
**Warning signs:** Typecheck passes in CI but `npm run build` fails with type errors.

### Pitfall 6: Preview channel deploys exposing production Stripe keys

**What goes wrong:** PR preview deploys use real production Stripe price ID, allowing testers to trigger real charges.
**Why it happens:** All VITE_ secrets are mapped from the same GitHub Secrets in both preview and production workflows.
**How to avoid:** This is acceptable for Phase 1 (single environment by design decision). Document that PR previews use production credentials and testers should use Stripe test mode card numbers. Alternatively (future phase): add a second set of `VITE_STRIPE_*_TEST` secrets for previews only.
**Warning signs:** Not a warning sign in Phase 1 — acknowledged tradeoff.

---

## Code Examples

### Complete firebase.json
```json
{
  "hosting": {
    "public": "pwa/dist",
    "ignore": [
      "firebase.json",
      "**/.*",
      "**/node_modules/**"
    ],
    "cleanUrls": true,
    "rewrites": [
      {
        "source": "**",
        "destination": "/index.html"
      }
    ],
    "headers": [
      {
        "source": "/index.html",
        "headers": [
          { "key": "Cache-Control", "value": "no-cache, no-store, must-revalidate" }
        ]
      },
      {
        "source": "/sw.js",
        "headers": [
          { "key": "Cache-Control", "value": "no-cache, no-store, must-revalidate" }
        ]
      },
      {
        "source": "**/*.@(js|css|woff2|png|jpg|jpeg|svg|ico|webp)",
        "headers": [
          { "key": "Cache-Control", "value": "public, max-age=31536000, immutable" }
        ]
      }
    ]
  }
}
```

**Note on `sw.js` cache header:** The service worker file must never be cached (it controls update behavior). `vite-plugin-pwa` outputs `sw.js` to the dist root. Setting `no-store` here prevents stale service worker serving.

### Service Account Setup (one-time, from local machine)

```bash
# From repo root — Firebase CLI must be installed and logged in
firebase init hosting:github
# Follow prompts:
# - GitHub repo: <org>/<repo>
# - Set up preview deploys? Yes
# - Set up auto-deploy on push? No (we manage manually)
# This creates the service account, assigns IAM roles, uploads FIREBASE_SERVICE_ACCOUNT secret to GitHub
```

If `firebase init hosting:github` has interactive issues, create manually:
1. GCP Console → IAM → Service Accounts → Create
2. Assign roles: `Firebase Hosting Admin`, `Firebase Authentication Admin`, `API Keys Viewer`
3. Create JSON key → download
4. GitHub repo → Settings → Secrets → Actions → New secret: `FIREBASE_SERVICE_ACCOUNT` → paste JSON content

### .env.example update (add missing VITE_STRIPE_PRICE_ID)

```bash
# Current .env.example is missing VITE_STRIPE_PRICE_ID
# Add to pwa/.env.example:
VITE_STRIPE_PRICE_ID=
```

### Local deploy fallback (DEPLOY-03)

```bash
# From repo root
cd pwa && npm run build
cd ..
firebase deploy --only hosting
```

Or as an npm script in `pwa/package.json`:
```json
{
  "scripts": {
    "deploy": "npm run build && cd .. && firebase deploy --only hosting"
  }
}
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `w9jds/firebase-action` community action | `FirebaseExtended/action-hosting-deploy@v0` official action | 2020 | Preview channels, PR comments, correct IAM roles |
| Workload Identity Federation for Firebase | Service account JSON (Firebase limitation) | N/A (ongoing) | Firebase Admin SDK never supported WIF; service account JSON is still required |
| `actions/setup-node@v2` with separate cache action | `actions/setup-node@v4` with built-in `cache: 'npm'` | 2022 | Simpler setup, same performance |
| `npm install` in CI | `npm ci` in CI | Best practice | Deterministic, faster, fails on lock file drift |
| Node.js 18 | Node.js 20 LTS | Oct 2023 | Node 20 is current LTS; Node 18 reaches EOL April 2025 |

**Deprecated/outdated:**
- `w9jds/firebase-action`: Community-maintained, lacks preview channel support
- Node 18 in CI: Will be EOL April 2025; use Node 20

---

## Open Questions

1. **`VITE_FIREBASE_AUTH_DOMAIN` value timing**
   - What we know: Custom domain setup requires updating this env var from `sundee-fundee.firebaseapp.com` to `sundeefundee.com`
   - What's unclear: DNS propagation can take 2-24h; should the GitHub Secret be updated before or after DNS points to Firebase?
   - Recommendation: Update the GitHub Secret to `sundeefundee.com` before DNS cutover. The app will fail to init Firebase Auth only if `sundeefundee.com` is NOT yet an authorized domain in Firebase Auth console. Add the domain to Firebase Auth authorized domains first, then update DNS, then update the secret. This order prevents any window of broken auth.

2. **`www` subdomain redirect**
   - What we know: Firebase Hosting custom domain setup is for the root domain `sundeefundee.com`
   - What's unclear: Does Firebase Hosting automatically handle `www.sundeefundee.com` redirects to root, or is a separate custom domain entry needed?
   - Recommendation: Add `www.sundeefundee.com` as a separate custom domain in Firebase Hosting console (Firebase supports multiple domains per site). Configure it as a redirect to `sundeefundee.com`. This is a one-time console step; no code change needed.

3. **`tsc` command for CI typecheck step**
   - What we know: `pwa/tsconfig.json` uses project references (`tsconfig.app.json`, `tsconfig.node.json`); `npm run build` runs `tsc -b && vite build`
   - What's unclear: Whether `tsc --noEmit` at root catches the same errors as `tsc -b`
   - Recommendation: Use `npx tsc -b --noEmit` in the CI typecheck step to match the build script's behavior exactly.

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Vitest 4.x |
| Config file | `pwa/vitest.config.ts` |
| Quick run command | `cd pwa && npx vitest run` |
| Full suite command | `cd pwa && npx vitest run` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| DEPLOY-01 | `firebase.json` has correct `public`, rewrites, headers | manual smoke | `firebase deploy --only hosting --dry-run` | ❌ Wave 0 (config file to create) |
| DEPLOY-02 | GitHub Actions workflow YAML is valid and runs | CI gate | Workflow runs on push to main | ❌ Wave 0 (workflow files to create) |
| DEPLOY-03 | `firebase deploy --only hosting` succeeds locally | manual | `firebase deploy --only hosting` | ❌ Wave 0 |
| DEPLOY-04 | Deployed app reads correct VITE_ env vars (no placeholders) | manual smoke | Browser devtools: `import.meta.env.VITE_FIREBASE_PROJECT_ID` | ❌ Wave 0 |

**Note:** DEPLOY-01 through DEPLOY-04 are infrastructure/config requirements. They cannot be verified by unit tests — verification is by manual smoke test after deploy. The CI workflow itself gates DEPLOY-02 by running the existing Vitest suite on every push.

### Sampling Rate

- **Per task commit:** `cd pwa && npx vitest run` (existing tests must stay green)
- **Per wave merge:** `cd pwa && npx vitest run` + `firebase deploy --dry-run` (verify firebase.json is parseable)
- **Phase gate:** Live site at `sundeefundee.com` returns 200, deep-link refresh works, no placeholder env vars

### Wave 0 Gaps

- [ ] `firebase.json` — at repo root, covers DEPLOY-01
- [ ] `.github/workflows/ci.yml` — covers DEPLOY-02
- [ ] `.github/workflows/preview.yml` — covers DEPLOY-02 (PR preview channel)
- [ ] `.github/workflows/deploy.yml` — covers DEPLOY-03 (manual dispatch)
- [ ] `pwa/.env.example` — add missing `VITE_STRIPE_PRICE_ID` line (currently absent per file inspection)
- [ ] GitHub Secrets — 8 secrets must be created: 6 Firebase + `VITE_STRIPE_PUBLISHABLE_KEY` + `VITE_STRIPE_PRICE_ID` + `FIREBASE_SERVICE_ACCOUNT`

---

## Sources

### Primary (HIGH confidence)
- `FirebaseExtended/action-hosting-deploy` GitHub README — workflow YAML patterns, input parameters, service account roles
- `FirebaseExtended/action-hosting-deploy/docs/service-account.md` — IAM roles required: `Firebase Hosting Admin`, `Firebase Authentication Admin`, `API Keys Viewer`, `Cloud Run Viewer`
- Vite documentation (`vite.dev/guide/env-and-mode`) — VITE_ prefix build-time injection behavior
- Firebase Hosting docs (`firebase.google.com/docs/hosting`) — SPA rewrite pattern, custom domain DNS process

### Secondary (MEDIUM confidence)
- stevekinney.com GitHub Actions + Vitest tutorial — `actions/setup-node@v4` with `cache: 'npm'`, `npx vitest run` flag
- DEV Community: Vite + GitHub Actions + Secrets — `env:` block pattern for VITE_ secrets injection, verified against Vite docs
- Multiple Firebase Hosting guides — SPA `"source": "**"` → `"/index.html"` rewrite pattern, confirmed consistent across sources

### Tertiary (LOW confidence)
- None — all critical claims verified against official sources or multiple consistent community sources

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — `action-hosting-deploy` is official Firebase; `setup-node@v4` is GitHub standard
- Architecture (workflow YAML): HIGH — directly from official action README
- firebase.json patterns: HIGH — consistent across Firebase docs + multiple verified guides
- Custom domain DNS process: HIGH — official Firebase Hosting docs process confirmed by multiple sources
- Auth domain / OAuth authorized domains: MEDIUM — process confirmed by multiple guides; specific GCP console navigation may differ slightly by project setup
- Pitfalls: HIGH (all verified against known failure modes in official docs/GitHub issues)

**Research date:** 2026-03-21
**Valid until:** 2026-09-21 (stable infrastructure tooling; `action-hosting-deploy@v0` is pinned)
