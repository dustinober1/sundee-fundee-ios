# Dark Mode and Accessibility Gate

Run this gate before the next release branch is considered ready.

## Modes

- [x] Light appearance
- [x] Dark appearance
- [x] Increased contrast enabled when available
- [x] Dynamic Type: default
- [x] Dynamic Type: Accessibility Large
- [x] VoiceOver labels for icon-only actions

## Core Flows

- [x] Auth and guest entry remain legible
- [x] Onboarding text and controls fit at Accessibility Large
- [x] Today screen cards, Why Today sheet, and Settings button are legible
- [x] Train screen, Best Next 20 Min, Coach Plan questionnaire, and Coach Plan preview are legible
- [x] Active workout set controls and workout options are legible
- [x] Cycle screen, symptom check-in, cycle settings, and pain tracking are legible
- [x] Progress screen, analytics, maxes, benchmarks, challenges, and export are legible
- [x] Settings, Data Trust Center, Support the Developer, and What's New are legible
- [x] Share card sheet preview and controls are legible
- [x] Widgets show readable stale/no-data states

## Tap Targets

- [x] Icon-only toolbar buttons have accessibility labels
- [x] Primary actions have visible disabled/enabled states
- [x] Toggle rows are usable with VoiceOver
- [x] Segmented controls fit without truncating critical words

## Evidence

Capture screenshots or notes for:

- Today light and dark
- Train light and large text
- Active workout large text
- Cycle and Pain dark/large text
- Progress empty/new-user state
- Settings Data Trust Center
- Share card sheet
- Cycle widget stale/no-data

## July 2, 2026 Evidence

- Runtime accessibility snapshots verified Today, Why Today, Train, active workout, Cycle, Progress, Settings, What's New, and Data Trust Center controls expose readable names.
- Fixed active workout options from a SwiftUI `Menu` with an unlabeled internal button to a labeled icon button plus confirmation dialog.
- Fixed Cycle's enable row from a native `Toggle` that exposed duplicate unlabeled switches to one accessible row with On/Off value and a visual switch indicator.
- Previous simulator pass verified Dark appearance, Accessibility Large text, Increase Contrast, completed workout detail, share preview, and widget no-data state.
