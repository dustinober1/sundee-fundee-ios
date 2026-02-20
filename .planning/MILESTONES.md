# Milestones

## v1.0 MVP — ✅ Shipped 2026-02-19

**Phases:** 1-4 | **Plans:** 11 | **Duration:** 4 days (2026-02-15 → 2026-02-19)
**Stats:** 228 files changed, ~8,452 LOC TypeScript, 156 commits

### Delivered

Full v1 feature set for the Strength workout tracking app, built on the existing core loop (Tasks 1-15). All 12 v1 requirements shipped and verified with 11 passing E2E tests.

### Key Accomplishments

1. **Smart Guidance** — Rule-based recommendation engine (70%/+5/-5 1RM), plateau detection (3+ rep-failure sessions), and full-screen PR confetti celebration wired into live workout flow
2. **Visual Progress** — Three Recharts visualizations: Epley 1RM line chart, weekly volume bar chart, 365-day activity heatmap — all integrated into /progress page
3. **Cloud Sync** — Supabase PKCE auth + offline sync engine (push/pull/retry/queue with localStorage pending queue) + auth dialog, sync nudge, dashboard status UI
4. **E2E Tests** — 11 Playwright tests covering full workout flow (TEST-01), PR celebration trigger (TEST-02), and sync queue wiring (TEST-03)

### Archive

- Roadmap: `.planning/milestones/v1.0-ROADMAP.md`
- Requirements: `.planning/milestones/v1.0-REQUIREMENTS.md`

## v1.1 Sundee-Fundee — ✅ Shipped 2026-02-20

**Phases:** 5-8 | **Plans:** 7 | **Tasks:** 15 | **Duration:** 2 days (2026-02-19 → 2026-02-20)
**Stats:** 67 files changed, +7,576/-394 lines, 11/11 E2E passing

### Delivered

Rebranded Strength to Sundee-Fundee, shipped installable PWA capabilities (manifest/icons/service worker wiring), added Android/iOS install flows, and completed Lucide icon enrichment across major UI surfaces.

### Key Accomplishments

1. **Brand Migration** — App-wide user-facing name rebrand shipped without functional regressions.
2. **PWA Foundation** — Manifest route + generated icon set + iOS PWA metadata delivered.
3. **Service Worker Infrastructure** — Serwist pipeline added with Supabase `NetworkOnly` protections and offline fallback route.
4. **Install UX** — Deferred Android `beforeinstallprompt` flow and iOS Add-to-Home-Screen modal integrated into dashboard.
5. **Icon Enrichment** — Dashboard, workout, and bottom navigation now use a consistent Lucide semantic icon set.

### Archive

- Roadmap: `.planning/milestones/v1.1-ROADMAP.md`
- Requirements: `.planning/milestones/v1.1-REQUIREMENTS.md`
