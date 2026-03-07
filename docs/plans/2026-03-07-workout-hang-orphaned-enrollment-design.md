# Fix: Workout Generation Hang & Orphaned Enrollment

**Date:** 2026-03-07
**Status:** Approved

## Problem 1: Workout Generation Hang

The app freezes when generating an AI workout. Root cause: `SwiftDataAIWorkoutService.generateWorkout()` awaits `CloudKitSharedWorkoutRepository.contribute()` which calls `publicDB.save(record)` with no timeout. If CloudKit is slow or the user isn't authenticated for CloudKit, this hangs indefinitely.

**File:** `SundeeFundee/Repositories/Firebase/FirebaseAIWorkoutService.swift` (lines 59-67)

## Problem 2: Old Program Loads

Users see a stale program on the dashboard because an `EnrolledProgram` record in SwiftData references a `programID` that was removed from `programs.json`. The enrollment persists as "active" even though the program no longer exists.

**File:** `SundeeFundee/Features/Dashboard/DashboardViewModel.swift` (lines 127-154)

## Fix 1: Fire-and-Forget CloudKit Contribute

Move the CloudKit `contribute()` call into a detached `Task`. The workout returns immediately after Gemini/offline generation + local SwiftData save. Contribution is already best-effort (wrapped in do/catch that prints).

Drop the `contributedToDatabase` flag update since it requires MainActor ModelContext access from a detached task and isn't read anywhere meaningful.

## Fix 2: Auto-Cancel Orphaned Enrollments

In `DashboardViewModel.loadActiveProgram()`, when `fetchProgram(id:)` returns `nil` for the active enrollment's programID, cancel the enrollment via `SwiftDataEnrolledProgramRepository.cancel()` and set `activeEnrollment = nil`.

Requires adding `modelContext` parameter to `loadActiveProgram()`.

## Testing

- **Fix 1:** Update `SwiftDataAIWorkoutService` tests to verify workout returns without blocking on contribute.
- **Fix 2:** Add test for orphaned enrollment cleanup — mock programRepo returning nil, verify enrollment is canceled.
