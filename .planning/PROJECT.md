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

## Current Milestone: v2.0 Flutter Full Rewrite

**Goal:** Rebuild Sundee-Fundee in Flutter for web, Android, and iOS with full feature parity and production deployment on Firebase.

**Target features:**
- Flutter app foundation for all 3 platforms (web, Android, iOS)
- Full feature parity migration (onboarding, programs, workouts, recommendations, progress, sync UX)
- Firebase production hosting path and release pipeline setup

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

- [ ] FLUTTER-01: Cross-platform Flutter application foundation for web, Android, and iOS
- [ ] PARITY-01: Full functional parity with v1.1 workflows (onboarding, programs, workout logging, recommendations, progress, sync UX)
- [ ] FIREBASE-01: Production Firebase hosting and release pipeline for the new Flutter app

### Out of Scope

- Real-time social features — High complexity, not core to individual tracking value
- Video analysis — storage/bandwidth costs, defer to a later milestone
- Nutrition tracking — focused purely on workout metrics in this milestone
- Wearable integrations — defer until core cross-platform parity is validated

## Context

- **Architecture baseline:** Existing product is local-first and offline-capable; v2.0 will re-establish these properties in Flutter.
- **Platform target:** Unified Flutter codebase for web + Android + iOS with production Firebase hosting.
- **Legacy reference:** Existing Next.js implementation remains the behavioral source-of-truth during migration.

## Constraints

- **Type:** UX — Must preserve mobile-first ergonomics and touch targets.
- **Type:** Reliability — Core workout flow must function offline-first in the rewritten app.
- **Type:** Scope — This milestone is focused on full feature parity, not net-new product surface area.

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Major version bump to v2.0 | Stack/architecture rewrite across platforms | ✓ Approved |
| Milestone: Flutter Full Rewrite | Explicitly signals complete cross-platform migration | ✓ Approved |
| Full parity scope | Preserve proven feature set while changing stack | ✓ Approved |
| Research-first approach | Reduce rewrite risk with ecosystem + architecture guidance | ✓ Approved |

---
*Last updated: 2026-02-20 — v2.0 milestone initialized*
