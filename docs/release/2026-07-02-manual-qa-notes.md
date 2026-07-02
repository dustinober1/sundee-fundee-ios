# Manual QA Notes - July 2, 2026

Device: iPhone 17 Pro Simulator, iOS 26.5.

## Verified

- Guest entry and onboarding rendered correctly. Onboarding privacy copy covered guest/local data, Apple/iCloud sync, optional Health access, and the fitness-not-medical disclaimer.
- Health access denial was non-blocking. After tapping Don't Allow, Train and Cycle remained usable.
- Train hub opened Best Next 20 Min. The workout showed a generated session, conservative starting-weight guidance, set controls, and a clean return to Train.
- Progress showed the new Start tracking guidance before training history exists: analytics unlock, first max, and benchmark prompts.
- Settings showed Support the Developer as optional, all features free. In this simulator setup StoreKit was unavailable, and the tip button was disabled with retry copy.
- The StoreKit support-tip rehearsal passed in the iOS simulator test harness with `SundeeFundee.storekit`: the real product loaded at `$1.99` and a purchase completed. Package tests covered pending, cancelled, unavailable, unverified, and repeat-purchase states.
- Data Trust Center showed guest/local storage copy, sync status, activation funnel events, and storage categories.
- Cycle showed point-of-use setup copy and kept Quick Check-In, Pain Log, and Symptom Check-In available after Health denial.
- Coach Plan questionnaire showed duration, focus, energy, and equipment controls. Preview showed Why this workout, an Energy trust badge, thumbs feedback, and quick edits. Tapping thumbs-up filled the icon; Reduce Volume changed the plan from 4 sets to 3 sets.
- Active workout completion was verified from Best Next 20 Minutes. Completing all six sets showed the final effort prompt, then the Workout Check-In sheet with Session RPE, soreness, pain, right-for-today toggle, Save Check-In, and Skip. Saving returned to the Workout Complete screen with local-save status.
- Share Workout from the completion screen rendered a workout share card with title, stats, exercises, Sundee Fundee footer, QR badge, Share Options, Share, and Copy to Photos controls.
- `sundeefundee://cycle` opened the app and landed on Cycle.
- `sundeefundee://today/check-in` was retested from a pushed Data Trust Center screen after the fix and landed directly on Quick Check-In.
- The small Cycle widget was added from the Home screen app-icon menu. It rendered a readable `No data` state with freshness text and the Sundee Fundee label. Tapping it routed into the app's Cycle tab.
- Dark appearance was applied with the Quick Check-In sheet open. Text, sliders, switches, and cards remained legible.
- Accessibility Large text with Increase Contrast enabled was applied. Train, Today root, completed workout detail, and Cycle remained readable with primary controls visible.
- Runtime accessibility snapshots verified Today, Why Today, Train, active workout, Cycle, Progress, Settings, What's New, and Data Trust Center. The active workout options control and Cycle enable row were fixed so VoiceOver sees named, single-purpose controls.

## Still Needs External Or Device-Specific Rehearsal

- CloudKit dashboard: checked-in schema includes `TodayWorkoutPreference` with queryable `___recordID`; import/deploy it in CloudKit Dashboard before relying on signed-in persistence.
