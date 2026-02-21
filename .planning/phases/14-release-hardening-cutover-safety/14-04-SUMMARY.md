---
phase: 14
plan: "04"
name: app-identifiers
subsystem: mobile-config
tags: [android, ios, bundle-id, app-id, release-config]

one-liner: "Set Android applicationId=com.sundeefundee.app + iOS PRODUCT_BUNDLE_IDENTIFIER=com.sundeefundee.app with Sundee Fundee display names for both platforms"

dependency-graph:
  requires: []
  provides:
    - android-application-id
    - ios-bundle-identifier
    - production-display-names
  affects:
    - 14-05  # signed release builds depend on correct IDs

tech-stack:
  added: []
  patterns:
    - android-build-gradle-kts-namespace
    - ios-xcodeproj-pbxproj-bundle-identifier

file-tracking:
  key-files:
    created: []
    modified:
      - flutter_app/android/app/build.gradle.kts
      - flutter_app/android/app/src/main/AndroidManifest.xml
      - flutter_app/ios/Runner/Info.plist
      - flutter_app/ios/Runner.xcodeproj/project.pbxproj

decisions:
  - id: D1
    context: "Android had com.sundeefundee.flutter_app (underscore variant); iOS had com.sundeefundee.flutterApp (camelCase variant)"
    choice: "Unified both to com.sundeefundee.app as specified in plan"
    rationale: "Locked after first store submission — must be correct before any submission"

metrics:
  duration: "~1 minute"
  completed: "2026-02-21"
---

# Phase 14 Plan 04: App Identifiers Summary

## What Was Built

Configured production-ready app identifiers and display names for Android and iOS. This is a one-way door — these values lock after first App Store / Play Store submission.

## Tasks Completed

| # | Task | Commit | Files Modified |
|---|------|--------|----------------|
| 1 | Configure Android applicationId and display name | `dfa827f` | build.gradle.kts, AndroidManifest.xml |
| 2 | Configure iOS bundle identifier and display name | `58bde63` | Info.plist, project.pbxproj |

## Changes Made

### Android
- `flutter_app/android/app/build.gradle.kts`
  - `namespace`: `com.sundeefundee.flutter_app` → `com.sundeefundee.app`
  - `applicationId`: `com.sundeefundee.flutter_app` → `com.sundeefundee.app`
- `flutter_app/android/app/src/main/AndroidManifest.xml`
  - `android:label`: `flutter_app` → `Sundee Fundee`

### iOS
- `flutter_app/ios/Runner/Info.plist`
  - `CFBundleDisplayName`: `Flutter App` → `Sundee Fundee`
  - `CFBundleName`: `flutter_app` → `Sundee Fundee`
- `flutter_app/ios/Runner.xcodeproj/project.pbxproj`
  - 3× `PRODUCT_BUNDLE_IDENTIFIER = com.sundeefundee.flutterApp` → `com.sundeefundee.app`
  - 3× `PRODUCT_BUNDLE_IDENTIFIER = com.sundeefundee.flutterApp.RunnerTests` → `com.sundeefundee.app.RunnerTests`

## Verification

```
flutter analyze --no-fatal-infos  →  1 pre-existing info (flutter_web_plugins), exit 0
```

All grep checks pass:
- `applicationId = "com.sundeefundee.app"` ✓
- `namespace = "com.sundeefundee.app"` ✓
- `android:label="Sundee Fundee"` ✓
- `CFBundleDisplayName = Sundee Fundee` ✓
- All 6 PRODUCT_BUNDLE_IDENTIFIER entries updated ✓
- No `flutterApp` or `flutter_app` remaining in bundle IDs ✓

## Decisions Made

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Android variant | `flutter_app` (underscore) was the actual value | Confirmed by reading file before editing |
| iOS variant | `flutterApp` (camelCase) was the actual value | Confirmed by reading project.pbxproj before editing |
| Unified target | `com.sundeefundee.app` for both | Plan spec; locked after first store submission |

## Deviations from Plan

None — plan executed exactly as written. The plan correctly noted "check actual file contents first" — Android had `flutter_app` (underscore) and iOS had `flutterApp` (camelCase) as anticipated.

## Next Phase Readiness

**14-05 (Signed Release Builds)** can now proceed:
- Android applicationId is correctly set for Play Store submission
- iOS bundle identifier is correctly set for App Store submission
- Display names show "Sundee Fundee" on both platforms
