# Sundee-Fundee (Workout Tracker)

## What This Is

A mobile-first workout tracking web application with offline-first architecture. Users can browse 6 strength programs, start training cycles, log workouts with set/rep/weight data, receive rule-based recommendations, view progress charts, and optionally sync to Supabase. v1.1 is shipped with full rebrand + installable PWA + icon enrichment.

## Core Value

Users can reliably track their strength training progress offline and receive actionable insights to improve performance.

## Current State

**Version:** v1.1 Sundee-Fundee — shipped 2026-02-20  
**Status:** Complete. All 15 v1.1 requirements validated; 11 E2E tests passing.  
**Tech:** Next.js 16 (App Router), React 19, shadcn/ui, Tailwind CSS, Framer Motion, Dexie.js v4, Supabase (optional), Vitest, Playwright — ~11,947 LOC TS/TSX.  
**Archives:** `.planning/milestones/v1.1-ROADMAP.md`, `.planning/milestones/v1.1-REQUIREMENTS.md`

## Next Milestone Goals

- [ ] Start `/gsd-new-milestone` and define v1.2 scope
- [ ] Create fresh `.planning/REQUIREMENTS.md` for next milestone
- [ ] Prioritize DEPLOY-01 and post-ship quality hardening

<details>
<summary>Archived v1.1 milestone goals (shipped)</summary>

**Goal:** Rebrand app to "Sundee-Fundee", enrich UI with Lucide icons, and ship as installable PWA for iOS/Android.

**Target features:**
- Rename app to Sundee-Fundee (name, metadata, app icon)
- Icon enrichment across key UI pages using Lucide React
- PWA setup: manifest, service worker, install prompt, multi-size icons

</details>

## Requirements

### Validated

- ✓ v1.0 core loop + recommendations/charts/sync/E2E coverage
- ✓ BRAND-01/02/03: Full user-facing and config/documentation rebrand — v1.1
- ✓ PWA-01/02/03/04/05/06: Manifest, icons, SW, iOS tags, middleware exclusions, and Playwright SW guard — v1.1
- ✓ INSTALL-01/02: Android install prompt + iOS A2HS modal — v1.1
- ✓ ICON-01/02/03/04: Lucide icon enrichment across dashboard/workout/navigation — v1.1

### Active

- [ ] DEPLOY-01: Production deployment configuration (Vercel, CI/CD, env vars, Supabase project setup)

### Out of Scope

- Real-time social features — High complexity, not core to individual tracking value
- Video analysis — storage/bandwidth costs, defer to v2+
- Native mobile app — Web-first approach covers mobile use cases
- Nutrition tracking — focused purely on workout metrics for v1

## Context

- **Architecture:** Local-first, sync-later. IndexedDB (Dexie) is authoritative; Supabase is optional backup/sync.
- **UX:** Mobile-first interactions, bottom nav, offline status, sync status, install UX.
- **Codebase:** ~11,947 LOC TS/TSX, 11 Playwright E2E tests.

## Constraints

- **Type:** Tech Stack — Must use Next.js 16, React 19, Dexie.js.
- **Type:** UX — Must be fully functional offline.
- **Type:** UX — Mobile-first design (touch targets >44px, thumb zone optimization).
- **Type:** Data — `super('StrengthApp')` in Dexie is permanently frozen.

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Local-first Architecture | Reliable gym/offline operation | ✓ Good |
| Dexie.js for Storage | Robust IndexedDB wrapper with TypeScript support | ✓ Good |
| Supabase for Sync | Practical auth/db backup path | ✓ Good |
| `@serwist/turbopack` for SW | Required for Next.js 16 Turbopack compatibility | ✓ Good |
| Supabase `NetworkOnly` in SW | Avoid cached auth/data responses | ✓ Good |
| `serviceWorkers: 'block'` in Playwright | Prevent SW flakiness in E2E tests | ✓ Good |
| `Activity` icon for Workout tab | Better semantic distinction from Programs tab icon | ✓ Good |

---
*Last updated: 2026-02-20 — after v1.1 milestone completion*
