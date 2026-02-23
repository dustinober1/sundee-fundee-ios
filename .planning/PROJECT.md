# Project: Sundee-Fundee

**What this is:**
A cross-platform strength training tracker that adapts 12‑week programs for men and customizes week-to-week workouts for women based on their menstrual cycle. The app already exists (Flutter + Firebase) and provides user authentication, cycle tracking, and program generation. Our current goal is to refine the 12‑week program flow and ensure adaptive behavior for women depending on where they are in their cycle.

## Core Value
Help users follow a structured training plan while dynamically adjusting to a female user’s current menstrual cycle phase.

## Key Decisions
| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Brownfield initialization | Codebase already contains app logic and features | Treat existing functionality as validated requirements |
| Cycle‑aware programming | User requirement to adapt programs based on cycle | Focus enhancements on program generator and UI flows |

## Constraints
- Flutter/Dart technology stack with Riverpod and Firebase (existing code)
- No known budget or timeline limits at this stage
- Must maintain guest mode when Firebase is disabled

## Requirements
### Validated
- ✓ **AUTH-01**: Users can authenticate anonymously or with email/password (existing code)
- ✓ **CYCLE-01**: Users can log menstrual period data and view current cycle phase (existing)
- ✓ **PROG-01**: The app offers a 12‑week strength training program with progress tracking (existing)
- ✓ **DASH-01**: Dashboard displays cycle insights and program status (existing)
- ✓ **DATA-01**: Data persists in Firestore; repositories handle serialization (existing)

### Active
- [ ] **PROG-02**: Convert the hard‑coded 12‑week program to week‑by‑week structure for men
- [ ] **PROG-03**: Make program generation adapt for women based on cycle phase (menstrual/follicular/ovulation/luteal)
- [ ] **UI-01**: Show cycle‑specific cues (e.g. sharkweek logo) in the UI where appropriate

### Out of Scope
- Complex social features (sharing, community) — not part of current focus
- Native health integrations beyond basic cycle logging

---
*Last updated: 2026-02-23 after initialization*
