# Training Intelligence 2.0 App Review Checklist

## Metadata gate

- Marketing version is `2.0.0`; build remains `14` by authorization policy (do not increment in this task).
- Store listing metadata is English (US). Name, subtitle, promotional text, keywords, description, and release notes are within App Store character limits; URLs are HTTPS and point to the privacy, support, and marketing pages.
- Claims are limited to shipped surfaces: cycle-aware strength guidance, recovery/pain context, Coach Plan, programs, progress, export, guest storage, iCloud sync, and optional HealthKit access. The app is a fitness tool and does not diagnose or treat injuries.
- All training features are free. The optional Support the Developer tip does not gate access or behavior.

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
