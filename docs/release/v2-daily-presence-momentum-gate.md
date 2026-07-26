# V2 Daily Presence and Momentum Release Gate

Release status: **not ready** until every checkbox below has fresh evidence for
the release candidate.

This gate is validation-only. Do not import or deploy a CloudKit schema, archive
or upload a build, or submit for App Review from these instructions. Each action
requires separate authorization.

## Current Environment Limitation

The Codex host could not perform the manual simulator pass on July 26, 2026:
`xcrun simctl list devices available` returned no devices. This is a
CoreSimulator environment blocker, not a passing result. Run this gate on a host
with an available iPhone simulator and retain the device, OS, candidate commit,
and evidence links below.

## Preconditions

- [ ] Record the candidate commit: `________________`
- [ ] Record the simulator and OS: `________________`
- [ ] Complete onboarding and reach Today in guest mode.
- [ ] Sign in with a dedicated iCloud test account for CloudKit checks.
- [ ] Confirm `DailyPresenceRecord` exists in CloudKit Development and
      Production with a queryable `recordName` / `___recordID` index.
- [ ] Confirm the candidate contains no raw health, cycle, pain, HRV, or
      readiness fields in `DailyPresenceRecord`.

## Presence and Participation

- [ ] **First Today open creates one presence.** Start from an account with no
      record for the current local day, open Today, and verify exactly one
      `DailyPresenceRecord` with participation `showedUp`.
- [ ] **Same-day opens do not duplicate.** Background/foreground the app three
      times and relaunch once on the same local day. Verify the same record ID is
      updated and the record count remains one.
- [ ] **A time-zone boundary creates the expected local day.** Record the
      current `dayKey`, change the simulator time zone so the local date crosses
      midnight, relaunch, and verify exactly one new record with the new
      `dayKey`; restore the original time zone afterward.
- [ ] **Ready, Tired, and Sore remain check-ins.** Select each on fresh test
      days or reset test fixtures between selections. Verify participation is
      `checkedIn`, never `acted`.
- [ ] **Resting and Trained are intentional actions.** Select each and verify
      participation is promoted to `acted`.
- [ ] **Workout completion promotes Trained.** Complete a workout, return to
      Today, and verify status `trained` with participation `acted`.
- [ ] **Rich check-in does not claim a workout.** Complete a rich check-in
      without finishing a workout and verify participation `checkedIn` and no
      implicit `trained` status.

## Offline Persistence and Reconciliation

- [ ] **Offline open survives relaunch.** Disable network access, open Today,
      force-quit, relaunch while still offline, and verify the same local record
      remains visible.
- [ ] **Offline selection survives relaunch.** While offline, select a status,
      force-quit, relaunch, and verify the status and participation level remain.
- [ ] **Reconnect drains pending writes without duplication.** Restore network,
      wait for reconciliation, and verify the pending entry clears and CloudKit
      contains exactly one record for that stable record ID.
- [ ] **Failed records remain retryable.** If any upload fails, verify it stays
      pending with an actionable UI state; repeat reconnect until it succeeds.

## Momentum and Returning Users

- [ ] **Missed days are non-punitive.** Seed or create a gap of at least seven
      local days, open Today, and verify “Welcome back” appears without
      streak-loss or failure language.
- [ ] **Prior weeks remain.** After the gap, verify previously completed weekly
      momentum and achievements are still present.

## Accessibility, Notifications, and Appearance

- [ ] **Accessibility Large is operable.** At an accessibility Dynamic Type
      size, operate every status and verify labels, values, controls, and save
      states remain visible without clipped critical copy.
- [ ] **VoiceOver is operable.** With VoiceOver enabled, navigate to and select
      every status; verify each has a distinct name, value, and usable action.
- [ ] **Notification denial does not block Today.** Deny notification
      permission, relaunch, and verify Today plus all presence actions remain
      usable.
- [ ] **Daily-plan notification preview is privacy-safe.** Schedule and inspect
      the notification on the lock screen and Notification Center. Verify the
      title/body contain no health, cycle, pain, HRV, readiness, or private
      check-in details.
- [ ] **Light and dark appearances are correct.** Exercise all new surfaces in
      both appearances and verify legible contrast. Review the changed source
      and confirm colors, fonts, and styling use `AppTheme` tokens only.

## Evidence

| Check | Result | Evidence / notes |
| --- | --- | --- |
| Presence and participation | Not run | |
| Offline and reconnect | Not run | |
| Momentum after missed days | Not run | |
| Dynamic Type and VoiceOver | Not run | |
| Notifications and privacy | Not run | |
| Light and dark appearance | Not run | |
| CloudKit Development index | Not verified | |
| CloudKit Production index | Not verified | |

## Release Decision

- [ ] Full Swift package tests pass.
- [ ] SwiftLint exits successfully.
- [ ] The app builds for the iPhone 17 Pro simulator.
- [ ] `git diff --check` exits successfully with no output.
- [ ] Every manual check above is complete with retained evidence.
- [ ] Offline writes survive relaunch and reconcile without duplicates.
- [ ] CloudKit Development and Production indexes are verified.
- [ ] No schema deployment, App Store upload, or submission occurred as part of
      this gate.

Only after every item is checked may the candidate be marked ready for separate
release coordination.
