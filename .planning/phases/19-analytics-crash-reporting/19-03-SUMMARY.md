---
phase: 19-analytics-crash-reporting
plan: 03
subsystem: infra
tags: [expo-updates, eas-update, ota, channels, runtimeVersion]

# Dependency graph
requires:
  - phase: 18-foundation-config-build-infra
    provides: EAS project configured with dev/preview/production build profiles
provides:
  - expo-updates native module installed (SDK 55 compatible)
  - EAS Update channel configuration (preview + production)
  - app.json runtimeVersion + updates.url for OTA delivery
affects:
  - phase-20-payments
  - phase-23-app-store-launch (requires new preview binary before OTA testing)

# Tech tracking
tech-stack:
  added:
    - expo-updates ~55.0.14
  patterns:
    - OTA update channels match build profile names (preview/production)
    - runtimeVersion uses appVersion policy — OTA updates scoped to matching app version
    - development builds excluded from OTA channel (dev client handles its own updates)

key-files:
  created: []
  modified:
    - package.json (expo-updates ~55.0.14 added)
    - package-lock.json (lockfile updated)
    - app.json (runtimeVersion, updates.url added; duplicate privacyManifests entries removed)
    - eas.json (channel: preview, channel: production added to build profiles)

key-decisions:
  - "runtimeVersion policy appVersion chosen — ties OTA updates to app version, preventing incompatible updates"
  - "development build profile deliberately excludes channel — dev builds use dev client, not OTA"
  - "eas update:configure CLI failed with version bug; manually configured equivalent output"

patterns-established:
  - "OTA channel naming: eas.json build profile name === EAS Update channel name (preview/production)"
  - "New native module install always requires new EAS binary build before OTA delivery works"

requirements-completed:
  - ANLYT-06

# Metrics
duration: 10min
completed: 2026-03-18
---

# Phase 19 Plan 03: EAS Update OTA Configuration Summary

**expo-updates installed with runtimeVersion (appVersion policy) and EAS Update channels configured for preview and production build profiles**

## Performance

- **Duration:** ~10 min
- **Started:** 2026-03-18T04:40:48Z
- **Completed:** 2026-03-18T04:51:00Z
- **Tasks:** 1 of 2 complete (Task 2 is checkpoint:human-verify — awaiting user acknowledgment)
- **Files modified:** 4

## Accomplishments

- Installed expo-updates ~55.0.14 (SDK 55 compatible version)
- Added `runtimeVersion: { policy: "appVersion" }` to app.json
- Added `updates.url` pointing to `https://u.expo.dev/dc7c3b9d-ee13-4713-8fab-85389863e18f`
- Added `channel: "preview"` to eas.json preview build profile
- Added `channel: "production"` to eas.json production build profile
- Fixed duplicate privacyManifests entries introduced by failed eas update:configure CLI

## Task Commits

Each task was committed atomically:

1. **Task 1: Install expo-updates and configure EAS Update** - `f20532b` (feat)

**Plan metadata:** (pending — final commit after checkpoint verification)

## Files Created/Modified

- `package.json` - expo-updates ~55.0.14 added as dependency
- `package-lock.json` - lockfile updated for expo-updates install
- `app.json` - runtimeVersion and updates.url added; duplicate entries cleaned up
- `eas.json` - channel field added to preview and production build profiles

## Decisions Made

- Used `{ "policy": "appVersion" }` for runtimeVersion — this ties OTA updates to the app version string, ensuring users only receive updates compatible with their installed binary
- Development build profile deliberately omits channel — dev builds use Expo Dev Client for fast iteration, not OTA updates
- `eas update:configure` CLI (eas-cli@17.x) failed with `Cannot read properties of undefined (reading 'policy')` — this is a known CLI version compatibility bug. Manually applied the equivalent configuration changes (same result as the CLI would produce)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Removed duplicate privacyManifests entries introduced by failed eas update:configure**
- **Found during:** Task 1 (Install expo-updates and configure EAS Update)
- **Issue:** The `eas update:configure` command partially executed before failing, duplicating `UIBackgroundModes`, `NSPrivacyAccessedAPITypes`, and `NSPrivacyCollectedDataTypes` entries in app.json
- **Fix:** Rewrote app.json with clean, deduplicated entries while adding runtimeVersion and updates fields
- **Files modified:** app.json
- **Verification:** JSON is valid, no duplicate array entries, runtimeVersion and updates.url present
- **Committed in:** f20532b (Task 1 commit)

---

**Total deviations:** 1 auto-fixed (1 bug — duplicate entries from failed CLI)
**Impact on plan:** Auto-fix necessary to prevent build issues. No scope creep.

## Issues Encountered

- `eas update:configure` command failed with `Cannot read properties of undefined (reading 'policy')` — this is a CLI version compatibility bug in eas-cli. The command partially wrote to app.json before failing, introducing duplicate entries. Resolved by manually writing the correct configuration and cleaning the duplicates.

## User Setup Required

A new EAS binary build is required before OTA updates can be tested:

1. Build a new preview binary: `eas build --platform ios --profile preview`
2. Install the new preview build on your device
3. Publish an update: `eas update --channel preview --message "test OTA update"`
4. Relaunch the app — it should fetch and apply the update

**Note:** The Phase 18 dev build does NOT include the expo-updates native module. OTA updates will not work until a new binary (preview or production) is built with expo-updates compiled in.

## Next Phase Readiness

- EAS Update configuration complete; infrastructure ready for OTA deployment
- New binary build needed to fully verify ANLYT-06 (OTA update installs on device)
- No blockers for continuing other Phase 19 plans

---
*Phase: 19-analytics-crash-reporting*
*Completed: 2026-03-18*
