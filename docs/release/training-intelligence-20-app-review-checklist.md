# Training Intelligence 2.0 App Review Checklist

## Metadata gate

- The local candidate is version `2.0.0`, build `14`, but repository history also assigned build `14` to version `1.7.3`. Confirm the next available number in App Store Connect and use at least build `15` before upload.
- Local English (US) Fastlane metadata passes the repository checks. Verify the live App Store Connect metadata, privacy answers, URLs, in-app purchase state, and review notes before submission.
- Claims are limited to surfaces implemented in the candidate build: cycle-aware strength guidance, recovery/pain context, Coach Plan, programs, progress, export, guest storage, iCloud sync, and optional HealthKit access. The app is a fitness tool and does not diagnose or treat injuries.
- All training features are free. The optional Support the Developer tip does not gate access or behavior.

## External deployment steps not yet completed

- Validate the new `DailyReadinessRecord` schema and indexes in the CloudKit Development environment, then separately authorize and deploy them to Production. The repository helper appends missing record types but does not patch an existing type, so explicitly verify or add the `schemaVersion` field and its queryable/sortable index in Development first.
- Confirm the candidate build number is available and validate signing, capabilities, agreements, tax/banking status, and the optional tip product in App Store Connect.
- Archive and upload only after explicit authorization, then complete the manual TestFlight paths below on a physical device. Do not use the current `fastlane release` lane for staging because it also submits for review.
- Submit for App Review only after a separate explicit authorization.
- After approval, manually release, schedule, or configure a phased release; the current lane has automatic release disabled.

## Manual review paths

1. Launch and tap **Continue as Guest**. Complete onboarding and verify Today, Train, Cycle, Progress, and Settings are usable with local storage.
2. Grant HealthKit access and confirm workout/cycle context appears. Repeat with **Don’t Allow** for every HealthKit prompt; verify the app remains usable and explains that HealthKit is optional.
3. From Train, open **Build Coach Plan**, inspect equipment choices, then open a program and start a session. Verify equipment conversion, warmups, cues, rest guidance, and exercise swap surfaces.
4. From Cycle, review phase estimate, recovery context, pain tracking, and symptom check-in. Confirm guidance is presented as estimates and not medical advice.
5. From Progress, inspect Monthly Review, analytics, maxes, benchmarks, challenges, buddy check-ins, and **Export My Data**. Confirm export produces JSON and the share sheet can be cancelled without mutation.
6. From Settings → **Data Trust Center**, verify guest/local and signed-in/iCloud explanations, privacy policy, export, and **Delete All Data & Account**. Confirm deletion requires confirmation and clears local account data.
7. From Settings → **Support the Developer**, verify the $1.99 repeatable tip is optional and no feature, badge, or account status depends on purchase. Cancel the purchase flow.
8. Sign in with Apple on a clean account, then sign out/delete account and verify the app returns to guest/onboarding without retaining private data.

## Screenshot QA

- Fresh deterministic screenshots were captured with `--seed-screenshots` for iPhone 17 Pro (1206×2622) and iPad Pro 13-inch (2064×2752).
- Screenshots show seeded sample data only. Review confirmed no raw HealthKit measurements, private notes, or personal identifiers beyond the seeded first name “Sarah”; derived phase/readiness context is intentionally shown and is not presented as medical diagnosis.
- Do not run `fastlane release`; that lane uploads metadata/screenshots and submits for review.
