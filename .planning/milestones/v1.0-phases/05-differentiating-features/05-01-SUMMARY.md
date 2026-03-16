---
phase: 05-differentiating-features
plan: "01"
subsystem: repositories
tags: [cycle, injury, programs, benchmarks, wod, firestore, asyncstorage, repository-pattern]
dependency_graph:
  requires:
    - src/domain/types/index.ts (PeriodLog, CycleSettings, InjuryProfile, PainLog, Program, BenchmarkDefinition, BenchmarkScoringType)
    - src/firebase/firestore.ts (getFirestoreInstance)
    - src/repositories/ReadinessRepo.ts (pattern reference)
  provides:
    - getCycleRepo(isGuest): CycleRepository
    - getInjuryRepo(isGuest): InjuryRepository
    - getProgramRepo(isGuest): ProgramRepository
    - getBenchmarkRepo(isGuest): BenchmarkRepository
    - getWODRepo(): WODRepository
  affects:
    - All Phase 5 Wave 2 UI plans (cycle, injury, programs, benchmarks, wod screens)
tech_stack:
  added:
    - src/resources/programs.json (bundled program catalog, 2 programs)
  patterns:
    - Repository factory pattern (isGuest -> Local vs Firestore)
    - ISO string date serialization for AsyncStorage and Firestore
    - UUID-based Firestore document IDs for period logs and pain logs
    - Flat domain Program from denormalized Firestore weeks[].sessions[] schema
    - Date-as-docID for WODs (/wods/yyyy-MM-dd)
key_files:
  created:
    - SundeeFundeeRN/src/repositories/CycleRepo.ts
    - SundeeFundeeRN/src/repositories/FirestoreCycleRepo.ts
    - SundeeFundeeRN/src/repositories/LocalCycleRepo.ts
    - SundeeFundeeRN/src/repositories/InjuryRepo.ts
    - SundeeFundeeRN/src/repositories/FirestoreInjuryRepo.ts
    - SundeeFundeeRN/src/repositories/LocalInjuryRepo.ts
    - SundeeFundeeRN/src/repositories/WODRepo.ts
    - SundeeFundeeRN/src/repositories/FirestoreWODRepo.ts
    - SundeeFundeeRN/src/repositories/ProgramRepo.ts
    - SundeeFundeeRN/src/repositories/FirestoreProgramRepo.ts
    - SundeeFundeeRN/src/repositories/LocalProgramRepo.ts
    - SundeeFundeeRN/src/repositories/BenchmarkRepo.ts
    - SundeeFundeeRN/src/repositories/FirestoreBenchmarkRepo.ts
    - SundeeFundeeRN/src/repositories/LocalBenchmarkRepo.ts
    - SundeeFundeeRN/src/resources/programs.json
    - SundeeFundeeRN/src/repositories/__tests__/CycleRepo.test.ts
    - SundeeFundeeRN/src/repositories/__tests__/InjuryRepo.test.ts
    - SundeeFundeeRN/src/repositories/__tests__/WODRepo.test.ts
    - SundeeFundeeRN/src/repositories/__tests__/ProgramRepo.test.ts
    - SundeeFundeeRN/src/repositories/__tests__/BenchmarkRepo.test.ts
  modified:
    - SundeeFundeeRN/src/repositories/index.ts
decisions:
  - "[05-01]: PeriodLogRecord and PainLogRecord wrap domain types with id (UUID) and ISO string dates — Firestore doc IDs and cross-platform date serialization"
  - "[05-01]: WODRepo factory takes no isGuest parameter — WODs are public read-only data, same Firestore impl for all users"
  - "[05-01]: FirestoreProgramDocument uses weeks[].sessions[] schema — firestoreProgramToProgram flattens to domain Program.sessions"
  - "[05-01]: programs.json bundled in src/resources/ — LocalProgramRepo serves programs offline with no network dependency"
  - "[05-01]: InjuryRepo stores full InjuryProfileRecord (all domain fields serialized) not just id — enables offline recovery phase updates"
metrics:
  duration: 7 min
  completed_date: "2026-03-15"
  tasks_completed: 2
  files_created: 20
  files_modified: 1
  tests_added: 86
  tests_total_in_suite: 171
---

# Phase 5 Plan 1: Phase 5 Repository Foundation Summary

**One-liner:** Five repository interfaces with Firestore and AsyncStorage implementations — CycleRepo (period logs + settings), InjuryRepo (injury profiles + pain logs), ProgramRepo (program catalog + enrollment), BenchmarkRepo (results + custom definitions), WODRepo (public read-only WODs) — unblocking all Wave 2 UI plans.

## What Was Built

All five repository contracts required by Phase 5 differentiating features, following the established ReadinessRepo factory pattern exactly.

**CycleRepository** — period log CRUD + cycle settings persistence. Period logs use UUID doc IDs; dates serialized as ISO strings. Firestore paths: `/users/{uid}/periodLogs/{logId}`, `/users/{uid}/cycleSettings/settings`. AsyncStorage: `@sundee/period_logs`, `@sundee/cycle_settings`.

**InjuryRepository** — injury profile upserts + pain log subcollection. Firestore paths: `/users/{uid}/injuries/{injuryId}`, `/users/{uid}/injuries/{injuryId}/painLogs/{logId}`. AsyncStorage: `@sundee/injuries`, `@sundee/pain_logs`.

**WODRepository** — public read-only WODs. No guest/auth distinction — always uses FirestoreWODRepo. Firestore path: `/wods/{yyyy-MM-dd}`. No LocalWODRepo needed.

**ProgramRepository** — program catalog (public) + per-user enrollment tracking. Firestore program documents use denormalized `weeks[].sessions[]` schema; the `firestoreProgramToProgram` helper flattens to the domain `Program` type. LocalProgramRepo serves programs from bundled `programs.json` with no network dependency.

**BenchmarkRepository** — benchmark results (filtered by benchmarkId or all) + custom benchmark definitions. The `score` field stores already-encoded values; `roundsAndReps` uses `rounds * 10000 + reps` convention from domain layer.

## Test Coverage

86 new tests added across 5 test files. Total repository test suite: 171 tests, 19 test suites — all green.

Test coverage per repo:
- CycleRepo: 12 tests (LocalCycleRepo: 7, FirestoreCycleRepo: 6, factory: 2, helpers: 2)
- InjuryRepo: 16 tests (LocalInjuryRepo: 9, FirestoreInjuryRepo: 6, factory: 2, helpers: 3)
- WODRepo: 7 tests (FirestoreWODRepo: 5, factory: 1)
- ProgramRepo: 18 tests (LocalProgramRepo: 10, FirestoreProgramRepo: 8, factory: 2, helpers: 3)
- BenchmarkRepo: 20 tests (LocalBenchmarkRepo: 11, FirestoreBenchmarkRepo: 6, factory: 2, roundsAndReps: 3)

## Deviations from Plan

None — plan executed exactly as written.

The plan noted WODRepo has no LocalWODRepo (Firestore offline persistence handles offline guests). This was implemented as specified.

The plan noted programs.json should follow the exercises.json pattern. A minimal bundled programs.json was created with 2 programs (Strength 3x/Week, Bodyweight Fundamentals) as a foundation for the admin to expand.

## Self-Check: PASSED

All 15 created files confirmed present on disk. Both task commits verified in git log:
- `cbddbcb`: feat(05-01): create CycleRepo, InjuryRepo, and WODRepo with dual implementations
- `bb9daa6`: feat(05-01): create ProgramRepo, BenchmarkRepo, update barrel index, add bundled programs.json
