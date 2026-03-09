# Changelog

All notable changes to Sundee Fundee will be documented in this file.

## [1.2.0] - 2026-03-09

### Added
- **WODs tab** showing Workouts of the Day for the previous 5 days, today, and next 5 days with today's WOD highlighted
- **Daily readiness check-in** — 3-slider survey (sleep quality, stress, soreness) scoring training readiness 0-10 with tier labels (Prime/Normal/Fatigued)
- **Readiness auto-regulation** — readiness score automatically adjusts program workout intensity; low readiness reduces volume 40%, high readiness boosts intensity 20%
- **AI workout readiness integration** — readiness tier now flows into AI-generated workout prompts
- **Workout adjustment banners** on execution screens showing when intensity has been adjusted
- **HealthKit readiness blending** — optional Settings toggle to blend HealthKit data (sleep, HRV, resting HR) with manual survey
- **Dashboard readiness card** with daily score display and check-in prompt

### Changed
- AI-first program creation flow — admin program building now leads with AI generation prompt

## [1.1.3] - 2026-03-09

### Added
- **Programs tab** now visible in the main tab bar (between Dashboard and History)
- **Unified History tab** showing all completed workouts (AI-generated and program sessions) in one chronological list
- Source filter chips (All / AI / Program) on History tab
- Source labels on each history row ("AI Workout" or program name)
- Swipe-to-delete for individual workout history entries
- Edit mode with multi-select bulk delete for workout history
- Search bar on Programs tab (filters by name and category)
- "My Programs" section showing enrolled programs with progress and delete capability
- `deleteWorkout` method on `AIWorkoutServiceProtocol` for removing AI workout records

### Changed
- History tab now queries both `GeneratedWorkoutRecord` and `CompletedWorkout` instead of AI workouts only

## [1.1.2] - 2026-03-08

### Added
- Date-aware program display with upcoming/active/past statuses
- `ProgramAvailability` enum for determining and sorting program statuses
- Program editor UI components
