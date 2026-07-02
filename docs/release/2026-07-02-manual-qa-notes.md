# Manual QA Notes - July 2, 2026

Device: iPhone 17 Pro Simulator, iOS 26.5.

## Verified

- Guest entry and onboarding rendered correctly. Onboarding privacy copy covered guest/local data, Apple/iCloud sync, optional Health access, and the fitness-not-medical disclaimer.
- Health access denial was non-blocking. After tapping Don't Allow, Train and Cycle remained usable.
- Train hub opened Best Next 20 Min. The workout showed a generated session, conservative starting-weight guidance, set controls, and a clean return to Train.
- Progress showed the new Start tracking guidance before training history exists: analytics unlock, first max, and benchmark prompts.
- Settings showed Support the Developer as optional, all features free. In this simulator setup StoreKit was unavailable, and the tip button was disabled with retry copy.
- Data Trust Center showed guest/local storage copy, sync status, activation funnel events, and storage categories.
- Cycle showed point-of-use setup copy and kept Quick Check-In, Pain Log, and Symptom Check-In available after Health denial.
- Coach Plan questionnaire showed duration, focus, energy, and equipment controls. Preview showed Why this workout, an Energy trust badge, thumbs feedback, and quick edits. Tapping thumbs-up filled the icon; Reduce Volume changed the plan from 4 sets to 3 sets.
- `sundeefundee://cycle` opened the app and landed on Cycle.
- `sundeefundee://today/check-in` was retested from a pushed Data Trust Center screen after the fix and landed directly on Quick Check-In.
- Dark appearance was applied with the Quick Check-In sheet open. Text, sliders, switches, and cards remained legible.

## Still Needs External Or Device-Specific Rehearsal

- CloudKit dashboard: add/deploy the `TodayWorkoutPreference` record type with a queryable `recordName` index before relying on signed-in persistence.
- StoreKit: run the optional support tip purchase/cancel/unavailable paths with the StoreKit configuration attached to the app scheme.
- Widgets: place the Cycle widget on the Simulator home screen and verify stale/no-data/freshness states visually. Direct deep links are verified.
- Accessibility gate: complete the full checklist in `dark-mode-accessibility-gate.md`, especially Accessibility Large Dynamic Type, VoiceOver traversal, increased contrast, and share-card/widget screenshots.
