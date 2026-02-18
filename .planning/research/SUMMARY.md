# Research Summary: Strength Workout Tracker

**Synthesized:** 2026-02-17
**Status:** Ready for Requirements

## Executive Summary

Strength is a local-first workout tracking application designed for serious lifters who prioritize reliability in often offline gym environments. The consensus approach for this domain is a "Local-First" architecture where IndexedDB (via Dexie.js) serves as the primary source of truth to ensure zero-latency interactions, while Supabase provides background backup and optional multi-device synchronization.

The research recommends a phased build that prioritizes the core logging loop and data integrity above all else. By deferring complex two-way synchronization and social features, the team can focus on a frictionless, offline-capable experience. The most critical risks identified are data loss from naive sync implementations and performance degradation from over-fetching workout history, both of which can be mitigated with specific architectural patterns (Upsert/Timestamp sync, specialized summary tables).

## Key Findings

### Technology Stack
- **Core:** Next.js 16 (App Router), React 19, TypeScript.
- **Data Layer:** **Dexie.js** (Local IndexedDB) + **Supabase** (Remote Auth/Backup).
- **Visualization:** Recharts for 1RM/Volume progress.
- **Critical Libs:** Framer Motion (UX), Zod (Validation), Playwright (E2E).

### Feature Priorities
- **Must-Have (MVP):** Frictionless Workout Logger, Static Exercise Database, Offline Support, Basic Progress Charts.
- **Differentiators:** Smart Recommendations (weight suggestions), Plateau Detection, 1RM Estimator.
- **Defer/Avoid:** Social feeds, Video uploads, Hardware integration (Bluetooth scales).

### Architecture
- **Pattern:** **Local-First with Background Sync**. UI reads/writes to Dexie; Service Worker/Hook syncs to Supabase.
- **State Management:** React Context for UI state (Timer, User); Dexie for persistent data.
- **Logic:** Separation of concerns—Recommendation Engine must be pure functions independent of UI components.

### Critical Pitfalls
- **Naive Sync:** "Last-write-wins" without conflict detection can lose data. *Mitigation: Use upsert with `updatedAt` timestamps.*
- **Over-fetching:** Loading all past workouts to render a simple chart freezes the UI. *Mitigation: Use `limit()`, `offset()`, and summary tables.*
- **Timer State:** Losing timer progress on tab switch. *Mitigation: Store start timestamp in storage, calculate remaining time on mount.*

## Implications for Roadmap

The research suggests a dependency-driven roadmap that secures data integrity before adding complexity.

### Suggested Phases

1.  **Foundation & Data Layer** — Define Dexie schema and basic app shell.
    *   *Rationale:* The entire app relies on the local database structure.
2.  **Core Loop (The Logger)** — Build workout logging, rest timer, and offline state.
    *   *Rationale:* This is the primary utility. If this feels slow or buggy, the app fails.
3.  **Backup System (One-way Sync)** — Implement Local -> Remote sync for data safety.
    *   *Rationale:* Secures user data early without the complexity of full two-way conflict resolution.
4.  **Visualization & Progress** — Implement Charts and History views.
    *   *Rationale:* Provides the "reward" for logging data.
5.  **Smart Recommendations** — Build the rules engine for weight suggestions and plateau detection.
    *   *Rationale:* High-value differentiator that requires the data foundation from previous phases.
6.  **Multi-Device Sync (Two-way)** — Implement Remote -> Local sync with conflict resolution.
    *   *Rationale:* Highest complexity risk; best tackled once data patterns are stable.

## Research Flags

| Phase | Status | Need |
|-------|--------|------|
| **Core Loop** | 🟢 Standard | Well-understood patterns. |
| **Smart Recommendations** | 🟡 Needs Research | Define specific heuristic rules (e.g., Epley formula adaptations). |
| **Multi-Device Sync** | 🔴 Needs Research | Evaluate conflict resolution strategies (CRDTs vs. Timestamp merging) closer to implementation. |

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| **Stack** | HIGH | Next.js + Dexie is a proven combo for this domain. |
| **Features** | HIGH | Market expectations are clear (Strong, Hevy). |
| **Architecture** | HIGH | Local-first patterns are well-documented. |
| **Pitfalls** | HIGH | Specific technical risks identified with clear mitigations. |

## Sources
- Competitor Analysis (Strong, Hevy)
- Local-First Web Development (localfirstweb.dev)
- Dexie.js Best Practices & Documentation
- Supabase Offline Patterns
