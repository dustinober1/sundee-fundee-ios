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

Do not run `fastlane release`, `fastlane deliver`, `xcodebuild archive`, or any upload/submission command as part of this gate. The script fails if a store-action command is present in release scripts and refuses the opt-in environment variable `TRAINING_INTELLIGENCE_GATE_ALLOW_STORE_ACTIONS=1`.

The gate requires each targeted filter to execute at least one test and scans all executable release/Fastlane scripts for archive, upload, or submission actions (descriptive documentation is not scanned). After a successful run, `git status --short` must be clean; only documented generated artifacts (`SundeeFundee/.build/`, `SundeeFundeeApp/DerivedData/`, or `.xcresult` bundles) are allowed. Record command output in `.superpowers/sdd/task-10-report.md`. App Store submission remains a separate, explicitly authorized operation.
