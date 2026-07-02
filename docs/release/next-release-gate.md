# Next Release Gate

Do not upload, submit, or build for App Store review from this gate. App Store submission requires explicit user approval.

## Automated

Prerequisite: `swiftlint` must be installed and available on `PATH`.

- [ ] `cd SundeeFundee && swift test`
- [ ] `cd SundeeFundeeApp && xcodebuild -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build`
- [ ] `swiftlint --config .swiftlint.yml`
- [ ] `cd SundeeFundee && swift test --filter SupportTip`
- [ ] `cd SundeeFundeeApp && xcodebuild -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -quiet test -only-testing:SundeeFundeeTests/StoreKitSupportTipStoreIntegrationTests`
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

## CloudKit Deployment

- [ ] `scripts/next-release-gate.sh` confirms `TodayWorkoutPreference` and its queryable `___recordID` exist in the checked-in schema
- [ ] Save/provide a CloudKit management token with `CLOUDKIT_MANAGEMENT_TOKEN` or `xcrun cktool save-token`
- [ ] `scripts/cloudkit-schema-deploy.sh development validate`
- [ ] `scripts/cloudkit-schema-deploy.sh development import`
- [ ] Confirm `TodayWorkoutPreference` has a queryable `recordName` / `___recordID` index in Development
- [ ] `CONFIRM_PRODUCTION_CLOUDKIT_IMPORT=YES scripts/cloudkit-schema-deploy.sh production import`

Direct `cktool` validate command:

```bash
xcrun cktool validate-schema \
  --team-id 87VVCMCW3F \
  --container-id iCloud.com.sundeefundee.app \
  --environment development \
  --file SundeeFundeeApp/cloudkit-schema.json
```

Direct `cktool` Development import command:

```bash
xcrun cktool import-schema \
  --team-id 87VVCMCW3F \
  --container-id iCloud.com.sundeefundee.app \
  --environment development \
  --validate \
  --file SundeeFundeeApp/cloudkit-schema.json
```

## App Review Safety

- [ ] No paywalls
- [ ] No feature gates
- [ ] Support tip remains optional and Settings-only
- [ ] HealthKit access is optional and denial is non-blocking
- [ ] No App Store upload or submission performed
