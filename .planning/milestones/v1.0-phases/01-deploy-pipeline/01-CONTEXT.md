# Phase 1: Deploy Pipeline - Context

**Gathered:** 2026-03-21
**Status:** Ready for planning

<domain>
## Phase Boundary

Get the PWA live at a production URL (sundeefundee.com) with automated CI on push to main and manual deploy dispatch. Covers Firebase Hosting config, GitHub Actions pipeline, environment variables, and custom domain + auth domain setup. No backend functions, no security rules, no new features.

</domain>

<decisions>
## Implementation Decisions

### Hosting domain
- Production URL: sundeefundee.com (root domain, not a subdomain)
- User has DNS access and can add A/CNAME records during this phase
- Firebase Auth custom domain: sundeefundee.com (sign-in popups show branded domain, not firebaseapp.com)
- DNS verification and SSL provisioning included in this phase

### CI/CD scope
- GitHub Actions pipeline on push to main runs: ESLint lint, TypeScript type check (tsc), Vitest tests, Vite build
- All four steps must pass (gate on everything) — no deploy if any step fails
- PR preview deploys enabled via Firebase Hosting preview channels (each PR gets a unique URL)
- Pipeline authenticates with Firebase via service account JSON stored in GitHub Secrets

### Environment strategy
- Single production environment (no staging) — PR preview deploys serve as testing surface
- CI reads env vars from GitHub Secrets; local dev uses .env.local (gitignored)
- .env.example stays as documentation of required variables
- All env vars set in this phase: 6 Firebase config keys + VITE_STRIPE_PUBLISHABLE_KEY + VITE_STRIPE_PRICE_ID (real values, not placeholders)

### Deploy trigger
- CI steps (lint, typecheck, test, build) run automatically on push to main
- Production deploy is a separate manual workflow dispatch (not auto-deploy)
- Deploy always deploys latest main (no commit SHA input)
- Rollback strategy: revert commit + redeploy, or use Firebase Hosting's built-in rollback

### Claude's Discretion
- GitHub Actions workflow file structure (single vs multi-file)
- firebase.json hosting configuration details (rewrites, headers, cache policy)
- Whether to run CI steps in parallel or sequentially in the workflow
- Node version and caching strategy in GitHub Actions

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- `.firebaserc` already configured with project "sundee-fundee"
- `vite.config.ts` has full PWA manifest config (theme_color, icons, workbox caching)
- `package.json` build script: `tsc -b && vite build` — standard Vite build
- `.env.example` documents all required env vars (6 Firebase + Stripe)
- ESLint and Vitest already configured and ready to use in CI

### Established Patterns
- Env vars accessed via `import.meta.env.VITE_*` (Vite convention)
- Stripe price ID has fallback: `import.meta.env.VITE_STRIPE_PRICE_ID ?? 'price_PLACEHOLDER'`
- PWA manifest declares icons at `/icons/icon-192.png` and `/icons/icon-512.png` — files don't exist yet (Phase 4)

### Integration Points
- `firebase.json` needs to be created at repo root (not in pwa/) — Firebase CLI expects it there alongside `.firebaserc`
- Build output goes to `pwa/dist/` (Vite default) — firebase.json hosting.public must point there
- SPA rewrite rule needed: all routes → index.html (React Router handles client-side routing)

</code_context>

<specifics>
## Specific Ideas

No specific requirements — open to standard approaches for Firebase Hosting + GitHub Actions.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 01-deploy-pipeline*
*Context gathered: 2026-03-21*
