---
name: asc-release-flow
description: Determine whether this free app is ready to submit, then drive the App Store release flow with asc, including first-time submission fixes for availability, Game Center, and App Privacy.
---

# Release flow (readiness-first)

Use this skill when the real question is "Can my app be ready to submit?" and then guide the user through the shortest path to a clean App Store submission, especially for first-time releases.

## Preconditions
- Ensure credentials are set (`asc auth login` or `ASC_*` env vars).
- Resolve app ID, version string, and build ID up front.
- For lower-level or first-time flows, also be ready to resolve `VERSION_ID`, `SUBMISSION_ID`, `DETAIL_ID`, and related resource IDs. Use `asc-id-resolver` when needed.
- Have a metadata directory ready if you plan to use `asc release stage` or `asc release run`.
- If you use experimental web-session commands, use a user-owned Apple Account session and treat those commands as optional escape hatches, not the default path.

## How to answer
When using this skill, answer readiness questions in this order:
1. Is the app ready right now, or not yet?
2. What are the blocking issues?
3. Which blockers are API-fixable vs web-session-fixable?
4. What exact command should run next?

Group blockers like this:
- API-fixable: build validity, metadata, screenshots, review details, content rights, encryption, version/build attachment, Game Center version and review-submission setup.
- Web-session-fixable: initial app availability bootstrap and App Privacy publish state.
- Manual fallback: any flow the user does not want to run through experimental web-session commands.

## Canonical path

### 1. Fast readiness check
Run this first when the user wants the quickest answer to "can I submit now?":

```bash
asc submit preflight --app "APP_ID" --version "1.2.3" --platform IOS
```

This is the fastest high-signal readiness check and prints fix guidance without mutating anything.

### 2. Real staging pass without submit
Run this when the user wants the version prepared in App Store Connect but wants a manual checkpoint before creating a review submission:

```bash
asc release stage \
  --app "APP_ID" \
  --version "1.2.3" \
  --build "BUILD_ID" \
  --metadata-dir "./metadata/version/1.2.3" \
  --confirm
```

Use `--copy-metadata-from "1.2.2"` instead of `--metadata-dir` when you want to carry metadata forward from an existing version. `asc release stage` requires exactly one metadata source and stops before submit.

### 3. Full-pipeline dry run
Run this when the user wants one command that approximates the whole release path:

```bash
asc release run \
  --app "APP_ID" \
  --version "1.2.3" \
  --build "BUILD_ID" \
  --metadata-dir "./metadata/version/1.2.3" \
  --dry-run \
  --output table
```

This is the best single-command rehearsal for:
1. ensuring or creating the version
2. applying metadata and localizations
3. attaching the build
4. running readiness checks
5. confirming the submission path is coherent

Add `--strict-validate` when you want warnings treated as blockers.

### 4. Deep API readiness audit
Run this when the user needs a fuller version-level checklist than `submit preflight`:

```bash
asc validate --app "APP_ID" --version "1.2.3" --platform IOS --output table
```

Prefer the version string form here so it stays aligned with `asc submit preflight` and `asc release run`. Switch to `VERSION_ID` only for lower-level commands that explicitly require it.

### 5. Actual submit
When the dry run looks clean:

```bash
asc release run \
  --app "APP_ID" \
  --version "1.2.3" \
  --build "BUILD_ID" \
  --metadata-dir "./metadata/version/1.2.3" \
  --confirm
```

## First-time submission blockers

### 1. Initial app availability does not exist yet
Symptoms:
- `asc pricing availability view --app "APP_ID"` reports no availability
- `asc pricing availability edit ...` fails because it only updates existing availability

Check:

```bash
asc pricing availability view --app "APP_ID"
```

Bootstrap the first availability record with the experimental web-session flow:

```bash
asc web apps availability create \
  --app "APP_ID" \
  --territory "USA,GBR" \
  --available-in-new-territories true
```

After bootstrap, use the normal public API command for ongoing updates:

```bash
asc pricing availability edit \
  --app "APP_ID" \
  --territory "USA,GBR" \
  --available true \
  --available-in-new-territories true
```

### 2. Game Center is enabled but the app version or review submission is incomplete
If the app uses Game Center, make sure the App Store version is Game Center-enabled:

```bash
asc game-center app-versions list --app "APP_ID"
asc game-center app-versions create --app-store-version-id "VERSION_ID"
```

If you are adding Game Center components for the first time, include them in the same submission as the app version. Resolve component version IDs first:

```bash
asc game-center achievements v2 versions list --achievement-id "ACH_ID"
asc game-center leaderboards v2 versions list --leaderboard-id "LEADERBOARD_ID"
asc game-center challenges versions list --challenge-id "CHALLENGE_ID"
asc game-center activities versions list --activity-id "ACTIVITY_ID"
```

Then use the review-submission flow so you can add the app version and the Game Center component versions to the same submission:

```bash
asc review submissions-create --app "APP_ID" --platform IOS
asc review items-add --submission "SUBMISSION_ID" --item-type appStoreVersions --item-id "VERSION_ID"
asc review items-add --submission "SUBMISSION_ID" --item-type gameCenterLeaderboardVersions --item-id "GC_LEADERBOARD_VERSION_ID"
asc review submissions-submit --id "SUBMISSION_ID" --confirm
```

`asc review items-add` also supports `gameCenterAchievementVersions`, `gameCenterActivityVersions`, `gameCenterChallengeVersions`, and `gameCenterLeaderboardSetVersions`.

If Game Center component versions need to ship with the app version, prefer the explicit `asc review submissions-*` flow over `asc release run --confirm`, because you need a chance to add all submission items before final submit.

### 5. App Privacy is still unpublished
The public API can warn about App Privacy readiness but cannot fully verify publish state.

If `asc submit preflight`, `asc validate`, or `asc release run` surfaces an App Privacy advisory, reconcile it with:

```bash
asc web privacy pull --app "APP_ID" --out "./privacy.json"
asc web privacy plan --app "APP_ID" --file "./privacy.json"
asc web privacy apply --app "APP_ID" --file "./privacy.json"
asc web privacy publish --app "APP_ID" --confirm
```

If the user does not want the experimental web-session flow, confirm App Privacy manually in App Store Connect:

```text
https://appstoreconnect.apple.com/apps/APP_ID/appPrivacy
```

### 6. Review details are incomplete
Check whether the version already has review details:

```bash
asc review details-for-version --version-id "VERSION_ID"
```

If needed, create or update them:

```bash
asc review details-create \
  --version-id "VERSION_ID" \
  --contact-first-name "Dev" \
  --contact-last-name "Support" \
  --contact-email "dev@example.com" \
  --contact-phone "+1 555 0100" \
  --notes "Explain the reviewer access path here."
```

```bash
asc review details-update \
  --id "DETAIL_ID" \
  --notes "Updated reviewer instructions."
```

Only set `--demo-account-required=true` when App Review truly needs demo credentials.

## Practical readiness checklist
An app is effectively ready to submit when:
- `asc submit preflight --app "APP_ID" --version "VERSION"` reports no blocking issues
- `asc validate --app "APP_ID" --version "VERSION"` is clean or only contains understood non-blocking warnings
- `asc release stage --confirm` successfully prepared the target version when you want a real pre-submit checkpoint
- `asc release run ... --dry-run` produces the expected plan
- the build is `VALID` and attached to the target version
- metadata, screenshots, and localizations are complete
- content rights and encryption requirements are resolved
- review details are present
- app availability exists
- if the app uses Game Center, the app version is Game Center-enabled and any required Game Center component versions are in the same review submission
- any App Privacy advisory has been resolved through `asc web privacy ...` or manual confirmation

## Lower-level fallback
Use the lower-level flow only when the user needs explicit control over each step:

```bash
asc versions attach-build --version-id "VERSION_ID" --build "BUILD_ID"
asc submit preflight --app "APP_ID" --version "1.2.3" --platform IOS
asc submit create --app "APP_ID" --version "1.2.3" --build "BUILD_ID" --confirm
asc submit status --version-id "VERSION_ID"
# or, if you captured the review submission ID:
asc submit status --id "SUBMISSION_ID"
```

If the submission needs multiple review items, such as Game Center component versions, use the review-submission API directly instead:

```bash
asc review submissions-create --app "APP_ID" --platform IOS
asc review items-add --submission "SUBMISSION_ID" --item-type appStoreVersions --item-id "VERSION_ID"
asc review items-add --submission "SUBMISSION_ID" --item-type gameCenterChallengeVersions --item-id "GC_CHALLENGE_VERSION_ID"
asc review submissions-submit --id "SUBMISSION_ID" --confirm
```

## Platform notes
- Use `--platform MAC_OS`, `TV_OS`, or `VISION_OS` as needed.
- For macOS, upload the `.pkg` separately, then use the same readiness and submission flow.
- `asc publish testflight` is still the fastest TestFlight shortcut, but for App Store readiness prefer `asc submit preflight`, `asc release stage`, and `asc release run`.

## Notes
- `asc release stage --confirm` is the safest one-command way to prepare a version without submitting it.
- `asc release run --dry-run` is the closest thing to a one-command answer for "will this full release flow work?"
- `asc submit preflight` is the fastest first pass.
- `asc validate` is the deeper API-side checklist for version readiness.
- Web-session commands are experimental and should be presented as optional escape hatches when the public API cannot complete the first-time flow.
- First-time app-availability bootstrap now goes through the experimental `asc web apps availability create` flow or App Store Connect itself.
- Game Center can require explicit review-submission item management when components must ride with the app version.
- If the user asks "why did submission fail?" map the failure back into the three buckets above: API-fixable, web-session-fixable, or manual fallback.
