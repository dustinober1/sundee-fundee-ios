---
phase: 14
plan: 02
subsystem: documentation
tags: [data-migration, supabase-sync, cutover, user-guidance, release-hardening]

dependency-graph:
  requires: []
  provides:
    - DATA_MIGRATION_GUIDE.md
    - DATA-01 requirement satisfied
  affects:
    - 14-03 (cutover checklist references this doc)
    - 14-04 (release notes reference migration paths)

tech-stack:
  added: []
  patterns:
    - Migration path documentation (Supabase sync as primary, fresh start as fallback)

key-files:
  created:
    - docs/DATA_MIGRATION_GUIDE.md
  modified: []

decisions:
  - id: DATA-01-SATISFIED
    choice: "Supabase sync is the supported migration path; local-only users documented as fresh start"
    rationale: "No cross-storage import tool needed for v2.0 launch; Supabase covers the primary migration use case"
    alternatives: ["Build IndexedDB→SQLite import tool (out of scope)", "Silently discard local data (unacceptable)"]

metrics:
  duration: "~30s"
  completed: "2026-02-21"
  tasks: 1/1
---

# Phase 14 Plan 02: Data Migration Guide Summary

**One-liner:** DATA_MIGRATION_GUIDE.md documents v1.1→v2.0 cutover via Supabase sync (auto) and local-only fresh start (explicit), satisfying DATA-01 with no silent data loss.

## What Was Built

Created `docs/DATA_MIGRATION_GUIDE.md` (80 lines) covering both user migration scenarios for the v1.1 Next.js → v2.0 Flutter cutover.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Create DATA_MIGRATION_GUIDE.md | cf30329 | docs/DATA_MIGRATION_GUIDE.md |

## Key Decisions Made

### DATA-01: Supabase sync as primary migration path

**Decision:** Supabase cloud sync is the supported v1.1 → v2.0 data migration mechanism. Local-only users are documented as "fresh start" with explicit options.

**Rationale:** A cross-storage migration tool (IndexedDB → SQLite) is technically complex, error-prone, and out of scope for v2.0 launch. Supabase sync already handles bidirectional data continuity. Users who never enabled sync are given clear options: enable sync in v1.1 first, start fresh, or keep using v1.1.

**Impact:** DATA-01 satisfied. No silent data loss — user expectations are set upfront via documentation and recommended future in-app messaging.

## Document Coverage

The guide covers:
- **Path 1 (Supabase):** Sign in → automatic syncPull() restores all data
- **Path 2 (Local-only):** Fresh start with 3 explicit options
- **In-app messaging:** Recommendations for future releases (not blocking v2.0)
- **What doesn't transfer:** Preferences (low friction), local-only data
- **Technical details:** Storage engine comparison table (IndexedDB/Dexie vs SQLite/Drift)
- **FAQ:** 4 Q&As addressing data loss, dual-app use, Supabase setup, import tool

## Deviations from Plan

None — plan executed exactly as written.

## Next Phase Readiness

- DATA_MIGRATION_GUIDE.md is ready to be referenced in the cutover checklist (14-03)
- No blockers for remaining Phase 14 plans
