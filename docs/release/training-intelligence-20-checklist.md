# Training Intelligence 2.0 release gate

Run `scripts/training-intelligence-20-gate.sh` from this checkout before release coordination. The gate is intentionally validation-only: it runs tests, a simulator build, UI screenshot smoke tests, schema/privacy guards, SwiftLint, and Store metadata/asset checks. It never archives, uploads, delivers, or submits an app build.

## Required checks

- Full `swift test` suite in `SundeeFundee`.
- Focused readiness, deload, and share test filters.
- iPhone 17 Pro simulator build and `SundeeFundeeScreenshotTests` smoke tests.
- CloudKit `DailyReadinessRecord` and `TodayWorkoutPreference` record/index guards.
- Privacy-safe source scan for credentials, insecure URLs, and raw sensitive share fields.
- English (US) metadata presence and screenshot dimensions: iPhone 17 Pro `1206×2622`, iPad Pro 13-inch `2064×2752`.
- SwiftLint using the repository configuration.

## Store-action safety

The Fastfile's explicitly named `lane :release` defines `upload_to_app_store` with `submit_for_review: true`; this gate inspects and acknowledges that definition but never invokes it. Do not run `fastlane release`, `fastlane deliver`, `xcodebuild archive`, or any upload/submission command as part of this gate. The script fails closed if a direct store-action invocation appears in release scripts or CI workflows, and refuses the opt-in environment variable `TRAINING_INTELLIGENCE_GATE_ALLOW_STORE_ACTIONS=1`.

The gate requires each targeted filter to report at least one executed test and scans release scripts plus CI workflows for archive, upload, or submission invocations (the documented Fastfile definitions are checked separately and are not invoked). After a successful run, `git status --short` must be clean; only documented generated artifacts (`SundeeFundee/.build/`, `SundeeFundeeApp/DerivedData/`, or `.xcresult` bundles) are allowed. Retain command output in the CI job log or equivalent run log. App Store submission remains a separate, explicitly authorized operation.
