# INTEGRATIONS

## Purpose
List of third-party services, deployment targets and external integrations referenced by the codebase.

## Active / Primary
- Supabase (optional sync/backup) — code under `src/lib/supabase/` (feature toggled; not mandatory)
- Vercel — `vercel.json` present (primary hosting / preview)
- Playwright — E2E tests (`tests/e2e/`) run against mobile viewport

## Libraries (integrations inside app)
- Dexie.js (IndexedDB) — local-first persistence
- Recharts — progress & stats charts
- Framer Motion — animations/timing
- shadcn/ui & Tailwind — UI system

## Config / Secrets
- Environment: `.env.local.example` (contains Supabase and other runtime vars)
- Deployment: `vercel.json` and standard Next.js build settings

## Notes / Observability
- No formal analytics pipeline found in repo (add if needed)
- CI integration (GitHub Actions) not present in repo root — verify org-level pipelines if required

---
Next actions: validate Supabase credentials before enabling sync in staging.