# Project Documentation Rules (Non-Obvious Only)

- This repo contains two active apps: the SwiftUI iOS client and the Next.js `wod-dashboard`, plus a small Firebase Functions workspace.
- `wod-dashboard` edits the app’s bundled JSON resources in the parent project; its path helpers assume commands run from inside `wod-dashboard/`.
- Guest mode is local-only SwiftData; authenticated mode enables CloudKit-backed flows. `currentUserID` refers to the app `User.id`, not `appleUserID`.
- Subscription code is intentionally present but bypassed: the app defaults to premium and the Settings subscription UI is hidden.
- AI workout generation in the iOS app is on-device Foundation Models first; the Cloudflare worker path is retained for dashboard generation workflows.
