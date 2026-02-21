---
phase: 14
plan: "05"
name: flutter-release-workflow
subsystem: ci-cd
tags: [flutter, github-actions, android, ios, signing, ci-cd, release]

dependency-graph:
  requires:
    - "14-04: bundle identifiers set to com.sundeefundee.app on Android + iOS"
  provides:
    - "GitHub Actions workflow for Flutter release builds (web, Android AAB, iOS IPA)"
    - "Android release signing via GitHub Secrets + build.gradle.kts"
  affects:
    - "14-06: final release checklist (workflow must pass)"

tech-stack:
  added:
    - "subosito/flutter-action@v2 (GitHub Actions Flutter setup)"
    - "actions/setup-java@v4 with temurin distribution"
  patterns:
    - "Base64-decoded keystore written to build dir at CI time (avoids checked-in secrets)"
    - "Graceful signing fallback: release signingConfig falls back to debug when keystore absent"
    - "Unsigned IPA pattern for iOS (sign manually via Xcode/Transporter before App Store)"

key-files:
  created:
    - ".github/workflows/flutter-release.yml"
  modified:
    - "flutter_app/android/app/build.gradle.kts"

decisions:
  - id: D-14-05-1
    what: "Android keystore decoded at CI time from Base64 env var, written to build dir"
    why: "Avoids committing keystore binary; compatible with GitHub Secrets 64KB limit"
    alternatives: "Commit encrypted keystore + decrypt step"
  - id: D-14-05-2
    what: "isMinifyEnabled = false in Android release buildType"
    why: "Drift codegen (generated code) is incompatible with R8 minification/shrinking"
    alternatives: "ProGuard rules — not viable due to generated Drift accessor complexity"
  - id: D-14-05-3
    what: "iOS build uses --no-codesign; signing is manual via App Store Connect"
    why: "iOS code signing requires Apple Developer Program certificates not available in open CI"
    alternatives: "Fastlane Match with certificates in private repo — added complexity"
  - id: D-14-05-4
    what: "Release signing fallback to debug keys when ANDROID_KEYSTORE_BASE64 absent"
    why: "Allows local `flutter build appbundle --release` without secrets configured"
    alternatives: "Hard-fail build when keystore missing"

metrics:
  tasks-completed: 2
  tasks-total: 2
  deviations: 0
  duration: "~1 minute"
  completed: "2026-02-21"
---

# Phase 14 Plan 05: Flutter Release Workflow Summary

**One-liner:** GitHub Actions workflow producing signed Android AAB (via GitHub Secrets keystore) + unsigned iOS IPA + web assets, with Drift-safe `isMinifyEnabled=false`.

## What Was Built

### Task 1: Android Release Signing (`build.gradle.kts`)

Added `java.util.Base64` and `java.io.FileOutputStream` imports to `flutter_app/android/app/build.gradle.kts`. Introduced a `signingConfigs.create("release")` block that:

1. Reads `ANDROID_KEYSTORE_BASE64` from the environment
2. Decodes and writes the keystore binary to `${project.buildDir}/keystore.jks`
3. Sets `storePassword`, `keyAlias`, `keyPassword` from corresponding env vars

The `release` buildType uses the release signing config when the keystore file exists, falling back to debug keys otherwise (safe for local development without secrets). `isMinifyEnabled = false` is enforced because Drift's generated code breaks with R8 minification.

### Task 2: Flutter Release Workflow (`.github/workflows/flutter-release.yml`)

Created a three-job GitHub Actions workflow:

| Job | Runner | Command | Artifact |
|-----|--------|---------|----------|
| `build-web` | ubuntu-latest | `flutter build web --release` | `web-release/` (30d) |
| `build-android` | ubuntu-latest | `flutter build appbundle --release` | `app-release.aab` (30d) |
| `build-ios` | macos-latest | `flutter build ipa --release --no-codesign` | `build/ios/ipa/` (30d) |

All jobs use Flutter 3.29.3 stable with caching. The Android job injects four `ANDROID_*` secrets as environment variables for the signing step. The iOS job installs CocoaPods before the build.

**Trigger conditions:**
- Push to `main` with changes in `flutter_app/**` or the workflow file itself
- Manual `workflow_dispatch`

## Decisions Made

| ID | Decision | Rationale |
|----|----------|-----------|
| D-14-05-1 | Base64 keystore decoded at CI time into build dir | Avoids binary in repo; fits GitHub Secrets 64KB limit |
| D-14-05-2 | `isMinifyEnabled = false` | Drift generated code incompatible with R8 |
| D-14-05-3 | iOS `--no-codesign` → manual App Store Connect signing | Apple Developer certs not available in open CI |
| D-14-05-4 | Fallback to debug signing when keystore absent | Local `flutter build appbundle --release` works without secrets |

## GitHub Secrets Required

| Secret | Source |
|--------|--------|
| `ANDROID_KEYSTORE_BASE64` | `base64 -w 0 your-key.jks` |
| `ANDROID_KEYSTORE_PASSWORD` | Password used during `keytool -genkey` |
| `ANDROID_KEY_ALIAS` | Alias specified during `keytool -genkey` |
| `ANDROID_KEY_PASSWORD` | Key password (often same as keystore password) |

## Deviations from Plan

None — plan executed exactly as written.

## Next Phase Readiness

- Plan 14-06 (final release checklist) can proceed
- Android signing will work once GitHub Secrets are populated
- iOS signing runbook: download IPA artifact → Xcode Organizer or Transporter → upload to App Store Connect
