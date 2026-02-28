# Sundee Fundee — TODO

## After Apple Developer Account is Approved

### One-Time Setup

- [ ] Set `DEVELOPMENT_TEAM` in `project.yml` (your Team ID from developer.apple.com)
- [ ] Create the app record in App Store Connect (name: "Sundee Fundee", bundle ID: `com.sundeefundee.app`)
- [ ] Enable HealthKit and CloudKit capabilities in the App Store Connect portal for the app record
- [ ] Generate an App Store Connect API key (Users & Access → Integrations → Keys) and save `APPLE_KEY_ID`, `APPLE_ISSUER_ID`, `APPLE_KEY_CONTENT`

### Certificate Management (Fastlane Match)

- [ ] Create a private GitHub repo to store certificates (e.g. `sundee-fundee-certs`)
- [ ] Run `bundle exec fastlane match appstore` locally to generate distribution cert + provisioning profile
- [ ] Set GitHub Secrets on this repo:
  - `APPLE_KEY_ID`
  - `APPLE_ISSUER_ID`
  - `APPLE_KEY_CONTENT`
  - `APPLE_ID`
  - `APPLE_TEAM_ID`
  - `MATCH_GIT_URL` (URL of the certs private repo)
  - `MATCH_PASSWORD` (encryption password you chose during match setup)

### Privacy Policy Hosting

- [ ] Host the Privacy Policy (text in `LegalContent.swift`) at a public URL (e.g. `sundeefundee.app/privacy`)
- [ ] Add the live Privacy Policy URL to App Store Connect → App Information
- [ ] Update the support URL field in App Store Connect

### App Store Connect Metadata

- [ ] Paste content from `scripts/appstore-metadata.md` into App Store Connect
- [ ] Upload screenshots (see `scripts/screenshot-guide.md` for capture instructions)
  - Required: 1320×2868 (6.9" iPhone 16 Pro Max)
  - Recommended: 1242×2208 (5.5" iPhone 8 Plus)
- [ ] Complete age rating questionnaire (answers in `scripts/appstore-metadata.md`)

### First TestFlight Build

- [ ] Tag a release to trigger the CI/CD pipeline: `git tag v1.0.0 && git push --tags`
- [ ] Confirm build appears in TestFlight (allow ~30 min for Apple processing)
- [ ] Add internal testers in TestFlight
- [ ] Test all flows listed in `scripts/appstore-metadata.md` under "What to Test"

### App Store Submission

- [ ] Submit for App Store review from App Store Connect
- [ ] Respond to any review feedback

### Xcode 26 Upgrade (Before Submission Deadline)

- [ ] Apple requires iOS/iPadOS 26 SDK for all submissions starting April 2026
- [ ] Upgrade to Xcode 26 once it goes GA and re-run the test suite
- [ ] Update `xcodeVersion` in `project.yml` and `xcode-select` in the GitHub Actions workflow
