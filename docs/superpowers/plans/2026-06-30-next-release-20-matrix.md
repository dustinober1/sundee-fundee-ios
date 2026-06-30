# Next Release 20-Item Matrix

| # | Recommendation | Status | Evidence | Phase | Verification |
|---:|---|---|---|---:|---|
| 1 | Make dark mode the headline fix | not started | `AppTheme.Semantic` still uses raw `Color.green/orange/red/blue`; button destructive state uses raw red | 1 | Dark/light screenshots and `AppThemeColorTests` |
| 2 | Add formal contrast and accessibility audit gate | not started | No release gate doc/script exists for dark mode, high contrast, Dynamic Type, VoiceOver, tap targets | 1 | `docs/release/dark-mode-accessibility-gate.md` checked off |
| 3 | Finish loading, error, and empty-state polish | partial | Benchmarks and Pain now have labels/empty states; remaining unlabeled button spinners exist in share/export/support/programs/AI surfaces | 1 | `scripts/audit-release-polish.sh` plus UI review |
| 4 | Add haptics to important moments | implemented-needs-verification | Haptics exist in active workout, PR/workout completion, challenges, share, settings, symptom check-in | 1 | Grep and simulator smoke test |
| 5 | Take easy performance wins | implemented-needs-verification | Benchmark fetches and share renderer already async; verify program/session paths | 1 | `swift test` and targeted code review |
| 6 | Smooth share-card rendering | implemented-needs-verification | `ShareCardRenderer.render` uses detached task with main-actor rendering | 1 | Share preview smoke test |
| 7 | Build activation funnel | not started | Growth events exist; no funnel service/surface | 3 | `ActivationFunnelServiceTests` |
| 8 | Add Coach Plan copy feedback | not started | No feedback record/service/UI | 2 | `CoachPlanFeedbackServiceTests` |
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
