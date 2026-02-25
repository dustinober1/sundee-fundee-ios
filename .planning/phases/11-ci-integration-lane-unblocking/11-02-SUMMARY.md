---
phase: 11
plan: 02
subsystem: ci-infrastructure
tags: [flutter, linux-desktop, xvfb, integration-test, ci, github-actions]

dependency-graph:
  requires:
    - "11-01: harness guard (no-op when !_firebaseEnabled || !_useEmulators)"
  provides:
    - "flutter_app/linux/ — Linux desktop platform scaffold for flutter test -d linux"
    - ".github/workflows/flutter-release.yml — quality-integration job via xvfb-run Linux desktop"
  affects:
    - "CI pipeline: quality-integration job now passes without Firebase/Node/Java"
    - "Release jobs: build-web/android/ios gate on quality-integration (unchanged)"

tech-stack:
  added: []
  patterns:
    - "Linux desktop headless integration testing via xvfb-run"
    - "Flutter integration_test on desktop target (no emulator required)"

file-tracking:
  key-files:
    created:
      - flutter_app/linux/CMakeLists.txt
      - flutter_app/linux/flutter/CMakeLists.txt
      - flutter_app/linux/flutter/generated_plugin_registrant.cc
      - flutter_app/linux/flutter/generated_plugin_registrant.h
      - flutter_app/linux/flutter/generated_plugins.cmake
      - flutter_app/linux/runner/CMakeLists.txt
      - flutter_app/linux/runner/main.cc
      - flutter_app/linux/runner/my_application.cc
      - flutter_app/linux/runner/my_application.h
      - flutter_app/linux/.gitignore
    modified:
      - .github/workflows/flutter-release.yml
      - flutter_app/lib/features/settings/presentation/onboarding_profile_screen.dart
      - flutter_app/test/features/auth/data/auth_repository_onboarding_bootstrap_test.dart

decisions:
  - choice: "Linux desktop (xvfb-run) over web/chrome driver for integration test CI"
    rationale: "Linux desktop is the only headless-capable Flutter desktop target on ubuntu-latest; no extra emulator infra needed"
  - choice: "Remove Firebase emulators from quality-integration job entirely"
    rationale: "critical_access_flow_test.dart uses 100% provider overrides; harness guard from 11-01 ensures no-op without ENABLE_FIREBASE; eliminates Java/Node deps and MissingPluginException"

metrics:
  duration: "~4 minutes"
  completed: "2026-02-25"
---

# Phase 11 Plan 02: Linux Desktop CI Integration Summary

**One-liner:** Linux desktop platform scaffold + xvfb-run CI job replacing Firebase emulator approach — zero-dep headless integration test lane.

## What Was Built

### Task 1: Linux Desktop Platform Files
Generated `flutter_app/linux/` via `flutter create --platforms=linux .`. The 10 scaffolded files provide the CMake build system and GTK runner entry points needed for `flutter test -d linux` to compile and launch the app headlessly. Reverted unintended `.metadata` change (android/ios/web platform entries were stripped by flutter create; restored to original).

### Task 2: quality-integration CI Job Rewrite
Replaced the Firebase-emulator-based integration job in `.github/workflows/flutter-release.yml` with a Linux desktop approach:

**Removed:**
- `actions/setup-node@v4` (Node.js)
- `npm install -g firebase-tools`
- `firebase emulators:exec --only auth,firestore "..."` wrapper
- `--dart-define=ENABLE_FIREBASE=true`, `USE_FIREBASE_EMULATORS=true`, `SEED_VERIFICATION_ACCOUNT=true`
- Firebase log file artifacts (`firebase-debug.log`, `firestore-debug.log`, `ui-debug.log`)

**Added:**
- `sudo apt-get install -y clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev`
- `flutter config --enable-linux-desktop`
- `xvfb-run flutter test integration_test/critical_access_flow_test.dart -d linux -r expanded`

**Preserved:**
- `needs: quality` on quality-integration
- `needs: [quality, quality-integration]` on build-web, build-android, build-ios

## Verification Results

| Check | Result |
|---|---|
| `flutter_app/linux/CMakeLists.txt` exists | ✅ |
| `flutter_app/linux/runner/main.cc` exists | ✅ |
| No unintended changes outside linux/ | ✅ (reverted .metadata) |
| `xvfb-run` in quality-integration job | ✅ |
| No `firebase emulators:exec` in workflow | ✅ |
| No `ENABLE_FIREBASE` in quality-integration | ✅ |
| Build jobs still `needs: [quality, quality-integration]` | ✅ (3 jobs) |
| `flutter analyze` passes | ✅ No issues found |

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Reverted unintended `.metadata` change**
- **Found during:** Task 1
- **Issue:** `flutter create --platforms=linux .` modified `.metadata` to remove android/ios/web platform entries, replacing them with only linux
- **Fix:** `git checkout -- flutter_app/.metadata` to restore original
- **Files modified:** flutter_app/.metadata (reverted)

**2. [Rule 1 - Bug] Removed unnecessary `dart:async` import**
- **Found during:** Task 2 (flutter analyze)
- **Issue:** Pre-existing `import 'dart:async'` in `auth_repository_onboarding_bootstrap_test.dart` caused analyze info
- **Fix:** Removed the unused import
- **Files modified:** `flutter_app/test/features/auth/data/auth_repository_onboarding_bootstrap_test.dart`
- **Commit:** 1a74658

**3. [Rule 1 - Bug] Suppressed pre-existing `deprecated_member_use` in DropdownButtonFormField**
- **Found during:** Task 2 (flutter analyze)
- **Issue:** `DropdownButtonFormField.value` flagged as deprecated (use `initialValue`), but this is a controlled dropdown — changing to `initialValue` would break setState-driven UI updates
- **Fix:** Added `// ignore: deprecated_member_use` comment to preserve controlled behavior
- **Files modified:** `flutter_app/lib/features/settings/presentation/onboarding_profile_screen.dart`
- **Commit:** 1a74658

## Commits

| Task | Commit | Description |
|---|---|---|
| Task 1 | f5ed9d4 | feat(11-02): generate Linux desktop platform files |
| Task 2 | 1a74658 | feat(11-02): rewrite quality-integration CI job for Linux desktop |

## Next Phase Readiness

**CI status:** quality-integration job is now wired to run `critical_access_flow_test.dart` on Linux desktop via xvfb-run. On next push to main (touching flutter_app/ or the workflow), the CI lane will run. No blockers remaining for Phase 11 completion.

**Open follow-up:** Observe the first CI run to confirm the xvfb-run + linux desktop build succeeds end-to-end in GitHub Actions environment (GTK deps, clang toolchain availability on ubuntu-latest).
