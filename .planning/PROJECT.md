# Strength (Workout Tracker)

## What This Is

A mobile-first workout tracking web application with offline-first architecture. It allows users to browse workout programs, start training cycles, log workouts with comprehensive data tracking, and receive personalized recommendations. The current focus is on completing the MVP by implementing recommendations, progress charts, Supabase sync, and E2E tests.

## Core Value

Users can reliably track their strength training progress offline and receive actionable insights to improve performance.

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

### Active

- [ ] RECOM-01: Rule-based recommendations (plateau detection, PR celebrations, missed workout reminders)
- [ ] CHARTS-01: Visual progress charts for 1RM and volume load using Recharts
- [ ] SYNC-01: Optional Supabase sync for backup and cross-device usage
- [ ] TEST-01: E2E tests for critical user flows (Playwright)
- [ ] DEPLOY-01: Production deployment configuration

### Out of Scope

- Real-time social features — High complexity, not core to individual tracking value
- Video analysis — storage/bandwidth costs, defer to v2+
- Native mobile app — Web-first approach covers mobile use cases
- Nutrition tracking — focused purely on workout metrics for v1

## Context

- **Tech Stack:** Next.js 16 (App Router), React 19, shadcn/ui, Tailwind CSS, Framer Motion, Dexie.js (IndexedDB), Supabase (optional), Vitest, Playwright.
- **Architecture:** Local-first, sync-later pattern. Primary data in IndexedDB, UI state in React Context, optional sync to Supabase.
- **UX:** Mobile-first design, thumb-friendly interactions, bottom navigation, offline indicators.
- **Status:** Core tracking features implemented. Pending advanced features (recommendations, analytics, sync) and comprehensive testing.

## Constraints

- **Type**: Tech Stack — Must use Next.js 16, React 19, Dexie.js.
- **Type**: UX — Must be fully functional offline.
- **Type**: UX — Mobile-first design (touch targets > 44px, thumb zone optimization).
- **Type**: Performance — Smooth animations and transitions (Framer Motion).

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Local-first Architecture | Ensures app works reliably in gyms with poor connectivity | ✓ Good |
| Dexie.js for Storage | robust wrapper for IndexedDB with good TypeScript support | ✓ Good |
| Supabase for Sync | Easy integration, reliable auth/db solution for backup | — Pending |

---
*Last updated: 2026-02-17 after initialization*
