# Phase 15: Fix Stubs and Guest Mode - Context

**Gathered:** 2026-04-09
**Status:** Ready for planning

<domain>
## Phase Boundary

Every user-facing feature uses real implementations, and guest mode works without dead ends. Replace DashboardView's stubbed `generateAIWorkout()` with the real CoachServiceProtocol. Verify guest mode navigation across all screens.

</domain>

<decisions>
## Implementation Decisions

### AI Workout Stub
- Replace DashboardView's `generateAIWorkout()` Task.sleep stub with real AIWorkoutViewModel / CoachServiceProtocol call
- Reuse existing implementation from AIWorkoutView — do not duplicate

### Code Completeness
- Skip `saveFromJSON` not-implemented in DataClientProtocol — only used by SyncQueue offline replay, not a user-facing code path

### Guest Mode Verification
- Manual screen-by-screen check in simulator to verify no dead ends
- Guest mode should support all features — LocalDataClient supports full CRUD

### Claude's Discretion
- Implementation details for wiring Dashboard AI workout to real service
- Guest mode empty-state handling for screens with no data

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- AIWorkoutView.swift: Full AI workout generation using CoachServiceProtocol (OnDeviceCoachService for iOS 26+ with Apple Intelligence, DeterministicCoachService as fallback)
- LocalDataClient.swift: Complete guest mode persistence using UserDefaults
- AuthViewModel.swift: Guest mode via `continueAsGuest()` sets isGuest=true, userID="guest_local", switches to LocalDataClient

### Established Patterns
- DashboardView.swift:459 — stub `generateAIWorkout()` uses Task.sleep(2s) and comment "Simulate AI generation"
- All other stubs have been removed in prior phases

### Integration Points
- DashboardView shows AI workout sheet via `$showingAIWorkout` → AIWorkoutView()
- The stub is in DashboardViewModel, but the sheet already presents the real AIWorkoutView

</code_context>

<specifics>
## Specific Ideas

- DashboardView.swift line 459: replace Task.sleep stub with real call or remove the stub entirely since the sheet already uses the real AIWorkoutView

</specifics>

<deferred>
## Deferred Ideas

- `saveFromJSON` implementation for SyncQueue offline replay — not user-facing

</deferred>
