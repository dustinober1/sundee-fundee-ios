# Strength (Workout Tracker)

## What This Is

A mobile-first workout tracking web application with offline-first architecture. Users can browse 6 strength programs, start training cycles, log workouts with set/rep/weight data, receive rule-based weight recommendations, view 1RM and volume progress charts, and optionally back up their data to Supabase for cross-device access. The v1.0 MVP is complete and fully tested.

## Core Value

Users can reliably track their strength training progress offline and receive actionable insights to improve performance.

## Current State

**Version:** v1.0 MVP — shipped 2026-02-19
**Status:** Complete. All 12 v1 requirements validated, 11 E2E tests passing.
**Tech:** Next.js 16 (App Router), React 19, shadcn/ui, Tailwind CSS, Framer Motion, Dexie.js v4, Supabase (optional), Vitest, Playwright — ~8,452 LOC TypeScript.

## Current Milestone: v1.1 Sundee-Fundee

**Goal:** Rebrand app to "Sundee-Fundee", enrich the UI with Lucide icons, and ship as an installable PWA for iOS and Android.

**Target features:**
- Rename app to Sundee-Fundee (name, metadata, app icon)
- Icon enrichment across all UI pages using Lucide React
- Progressive Web App setup: manifest, service worker, install prompt, multi-size icons

## Requirements

### Validated

- ✓ Browse workout programs (back squat, front squat, bench press, deadlift, box jump, burpees) — existing
- ✓ Start training cycles (8 weeks, 3 days/week) — existing
- ✓ Log workouts with sets, reps, weight — existing
- ✓ Calculate target weights based on %1RM — existing
- ✓ Track 1RM history — existing
- ✓ Offline data storage (IndexedDB via Dexie.js) — existing
- ✓ Basic dashboard (active cycles, today's workout) — existing
- ✓ Rest timer functionality — existing
- ✓ Onboarding wizard (name, experience, goals) — existing
- ✓ RECOM-01: Rule-based weight recommendations (70%/+5/-5 1RM logic) — v1.0
- ✓ RECOM-02: Plateau detection (3+ rep-failure sessions) with deload suggestion — v1.0
- ✓ RECOM-03: PR confetti celebration (weight + volume PRs) — v1.0
- ✓ CHART-01: Epley 1RM line chart with per-exercise selector — v1.0
- ✓ CHART-02: Weekly volume bar chart (last 12 weeks) — v1.0
- ✓ CHART-03: 365-day workout frequency heatmap — v1.0
- ✓ SYNC-01: Auto-sync to Supabase after workout completion — v1.0
- ✓ SYNC-02: Cross-device restore via auth + pull on login — v1.0
- ✓ SYNC-03: Sync status indicator (synced/pending/offline) in dashboard — v1.0
- ✓ TEST-01: E2E test for full workout flow — v1.0
- ✓ TEST-02: E2E test for PR celebration trigger — v1.0
- ✓ TEST-03: E2E test for sync queue wiring — v1.0

### Active

- [ ] DEPLOY-01: Production deployment configuration (Vercel, CI/CD, env vars, Supabase project setup)

### Out of Scope

- Real-time social features — High complexity, not core to individual tracking value
- Video analysis — storage/bandwidth costs, defer to v2+
- Native mobile app — Web-first approach covers mobile use cases
- Nutrition tracking — focused purely on workout metrics for v1
- Offline mode for sync — localStorage queue handles this; service worker not needed

## Context

- **Tech Stack:** Next.js 16 (App Router), React 19, shadcn/ui, Tailwind CSS, Framer Motion, Dexie.js (IndexedDB), Supabase (optional), Vitest, Playwright.
- **Architecture:** Local-first, sync-later pattern. Primary data in IndexedDB (Dexie v4 schema), UI state in React Context (UserContext, ExerciseContext, RestTimerContext), optional Supabase sync with localStorage offline queue.
- **UX:** Mobile-first design, thumb-friendly interactions, bottom navigation, offline banner, sync status popover.
- **Codebase:** ~8,452 LOC TypeScript across src/. 11 E2E tests (Playwright), unit/integration tests (Vitest + fake-indexeddb).

## Constraints

- **Type**: Tech Stack — Must use Next.js 16, React 19, Dexie.js.
- **Type**: UX — Must be fully functional offline.
- **Type**: UX — Mobile-first design (touch targets > 44px, thumb zone optimization).
- **Type**: Performance — Smooth animations and transitions (Framer Motion).

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Local-first Architecture | Ensures app works reliably in gyms with poor connectivity | ✓ Good |
| Dexie.js for Storage | Robust wrapper for IndexedDB with good TypeScript support | ✓ Good |
| Supabase for Sync | Easy integration, reliable auth/db solution for backup | ✓ Good |
| No PR on first session (currentMax > 0 guard) | Prevents noise when no baseline exists | ✓ Good |
| Session failure = any set with actualReps < prescribed | Clear, deterministic plateau trigger | ✓ Good |
| null Supabase client when env vars missing | Prevents @supabase/ssr throw during prerender; app works offline-only | ✓ Good |
| localstorage offline queue | Survives page refreshes; no service worker needed | ✓ Good |
| bulkPut merge strategy for pull | Insert-or-replace without deleting local-only records | ✓ Good |
| reuseExistingServer: false in Playwright | Ensures webServer.env Supabase fake vars always injected | ✓ Good |
| URL assertion over raw IDB count in E2E | Dexie open connection conflicts with raw indexedDB.open() | ✓ Good |

---
*Last updated: 2026-02-19 — v1.1 milestone started*
