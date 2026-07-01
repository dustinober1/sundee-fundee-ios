# Next Release Gate

Do not upload, submit, or build for App Store review from this gate. App Store submission requires explicit user approval.

## Automated

Prerequisite: `swiftlint` must be installed and available on `PATH`.

- [ ] `cd SundeeFundee && swift test`
- [ ] `cd SundeeFundeeApp && xcodebuild -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build`
- [ ] `swiftlint --config .swiftlint.yml`
- [ ] `cd SundeeFundee && swift test --filter SupportTip`
- [ ] `cd SundeeFundee && swift test --filter DeepLinkRouterTests`
- [ ] `cd SundeeFundee && swift test --filter BestNextWorkoutRequestBuilderTests`
- [ ] `cd SundeeFundee && swift test --filter CoachPlanFeedbackServiceTests`

## Manual Simulator QA

- [ ] Light mode Today, Train, Cycle, Progress, Settings
- [ ] Dark mode Today, Train, Cycle, Progress, Settings
- [ ] Accessibility Large active workout and Coach Plan
- [ ] VoiceOver labels for icon-only actions
- [ ] HealthKit denied path still permits guest/local training
- [ ] StoreKit success, pending, cancel, unavailable, and unverified paths
- [ ] Widget stale/no-data deep links route to the intended tab
- [ ] Coach Plan fallback works when on-device copy is unavailable
- [ ] Share card preview renders without visible freeze
- [ ] Progress empty state shows `Start tracking` guidance before data exists
- [ ] Optional post-workout check-in can be submitted or skipped

## App Review Safety

- [ ] No paywalls
- [ ] No feature gates
- [ ] Support tip remains optional and Settings-only
- [ ] HealthKit access is optional and denial is non-blocking
- [ ] No App Store upload or submission performed
