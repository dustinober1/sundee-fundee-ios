# Next Release 20-Item Matrix

| # | Recommendation | Status | Evidence | Phase | Verification |
|---:|---|---|---|---:|---|
| 1 | Make dark mode the headline fix | done | Adaptive semantic colors, destructive button colors, and shadow token are implemented; `AppThemeColorTests` passes 5 tests | 1 | Dark/light screenshots and `AppThemeColorTests` |
| 2 | Add formal contrast and accessibility audit gate | implemented-needs-manual-qa | `docs/release/dark-mode-accessibility-gate.md` now covers dark mode, high contrast, Dynamic Type, VoiceOver, tap targets, core flows, widgets, and evidence capture | 1 | `docs/release/dark-mode-accessibility-gate.md` checked off |
| 3 | Finish loading, error, and empty-state polish | implemented-needs-verification | Benchmarks and Pain now have labels/empty states; share/export/support/program enroll/start/AI substitution spinners now have labels/accessibility labels | 1 | `scripts/audit-release-polish.sh` plus UI review |
| 4 | Add haptics to important moments | done | Verified `HapticFeedback` call sites in active workout, PR/workout completion, challenges, share, settings, and symptom check-in; `ActiveWorkoutSessionViewModelTests` passes 5 tests | 1 | Grep and simulator smoke test |
| 5 | Take easy performance wins | done | Verified benchmark fetches use `async let`; share renderer uses detached rendering; app builds on iPhone 17 Pro simulator | 1 | `swift test` and targeted code review |
| 6 | Smooth share-card rendering | implemented-needs-manual-qa | `ShareCardRenderer.render` uses detached `ImageRenderer` work and the app builds; UIKit-gated share renderer tests exist but are not wired into current test schemes | 1 | Share preview smoke test |
| 7 | Build activation funnel | not started | Growth events exist; no funnel service/surface | 3 | `ActivationFunnelServiceTests` |
| 8 | Add Coach Plan copy feedback | implemented-needs-manual-qa | Metadata-only `CoachPlanFeedback` record/service and Coach Plan preview thumbs feedback UI are implemented; service and view-model tests pass | 2 | `CoachPlanFeedbackServiceTests` |
| 9 | Make "Why this workout?" bigger trust feature | partial | Reason codes/rationale exist; `TodayWhySheet` is plain text | 2 | `WorkoutTrustBadgeBuilderTests` and UI smoke |
| 10 | Make Best Next 20 Min context-aware | not started | `TrainHubView` hardcodes full-body, medium energy, full gym, no pain logs | 2 | `BestNextWorkoutRequestBuilderTests` |
| 11 | Let Coach Plan quick edits become learned preferences | partial | `EditableWorkoutDraft` and `PreferenceLearner` exist; no today preference persistence | 2 | `TodayWorkoutPreferenceServiceTests` |
| 12 | Close loop after workouts with quick check-in | partial | Set RPE exists; no completion check-in record/sheet | 2 | `WorkoutCompletionCheckInViewModelTests` |
| 13 | Improve Progress feature discoverability | not started | `ProgressHubView` hides destinations when empty except export/monthly review | 4 | `ProgressGuidanceServiceTests` |
| 14 | Make onboarding progressive | partial | Onboarding is short; prompts are not point-of-use policy driven | 3 | `ProgressivePromptPolicyTests` |
| 15 | Surface privacy/data-control messaging | partial | Data Trust Center exists; onboarding/settings copy can be clearer | 3 | UI text smoke and data trust screenshot |
| 16 | Keep support tip App Review-safe | implemented-needs-verification | StoreKit/product/tests exist | 5 | StoreKit path rehearsal |
| 17 | Polish widgets with freshness and deep links | partial | Freshness text exists; no `widgetURL` or app route handler | 4 | `DeepLinkRouterTests` and widget smoke |
| 18 | Clean up stale developer docs | not started | `SundeeFundee/README.md` and `Package.swift` comments are stale | 5 | Doc diff review |
| 19 | Small code-health cleanup pass | partial | Some old findings already fixed; verify `MaxRow`, `setsCount`, and lint | 5 | `rg` checks and SwiftLint |
| 20 | Create final release gate | not started | No single runbook/script covers full risk list | 5 | `docs/release/next-release-gate.md` |
