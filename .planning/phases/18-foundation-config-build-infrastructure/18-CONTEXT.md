# Phase 18: Foundation Config + Build Infrastructure - Context

**Gathered:** 2026-03-17
**Status:** Ready for planning

<domain>
## Phase Boundary

Register all v1.1 native modules (messaging, crashlytics, analytics) in app.json, configure EAS production build and submit profiles, confirm Firebase App Check in production attestation mode, and add PrivacyInfo.xcprivacy via Expo config plugin — producing a new EAS development build that unblocks all subsequent v1.1 phases.

</domain>

<decisions>
## Implementation Decisions

### Privacy Manifest (PrivacyInfo.xcprivacy)
- Match legacy Swift app declarations: Health & Fitness, User ID, Name, Purchase History, Other User Content
- All data types linked to user identity, not used for tracking (NSPrivacyTracking: false)
- Cycle/menstrual data declared as sensitive health information linked to user identity
- Explicitly declare NSPrivacyAccessedAPICategoryUserDefaults (reason: CA92.1) — don't rely on Expo auto-generation
- Add via Expo config plugin (managed workflow) — no ios/ directory ejection
- Do NOT expand for Phase 19 analytics/crash data types yet — match what's live today plus legacy parity

### EAS Production + Submit Profiles
- EAS managed credentials — let EAS handle provisioning profiles and signing certificates automatically
- Production build profile uses EAS defaults — no custom Proguard/R8 or Bitcode config
- iOS submit section: include ascAppId (user has App Store Connect app created)
- Android submit: configure track "internal" but skip serviceAccountKeyPath — first Play Store submission must be manual AAB upload
- Development builds keep existing debug token config for simulator testing

### App Check Enforcement
- Switch to production attestation in Phase 18: DeviceCheck (iOS) and Play Integrity (Android)
- Enable attestation only — do NOT enforce (reject unattested requests) yet; enforcement deferred to Phase 22
- Dual mode: development builds use debug tokens (simulator), preview/production builds use real attestation
- EAS env vars control which App Check mode activates per build profile

### Build Verification
- Smoke test new modules only — not a full retest of Phase 17 deferrals
- Physical iOS device required for App Check DeviceCheck verification (simulator can't verify this)
- iOS device needs to be registered in Apple Developer portal first (not currently registered)
- Done bar: EAS dev build installs on iOS/Android physical device, all 3 new Firebase modules (messaging, crashlytics, analytics) initialize without errors, App Check dashboard shows production attestation, PrivacyInfo.xcprivacy present in build

### Claude's Discretion
- Exact Expo config plugin implementation for PrivacyInfo.xcprivacy
- Firebase module initialization code structure
- EAS env var naming and organization
- Order of operations for module registration vs build profile config
- How to verify module initialization (logging, console output)

</decisions>

<specifics>
## Specific Ideas

- Legacy Swift PrivacyInfo.xcprivacy at `_legacy-swift/SundeeFundee/Resources/PrivacyInfo.xcprivacy` is the reference for data type declarations
- STATE.md decision: expo-notifications owns notification display; @react-native-firebase/messaging handles background data only
- Current app.json plugins already include @react-native-firebase/app and /auth — add /messaging, /crashlytics, /analytics alongside
- Current package.json has /app, /app-check, /auth, /firestore, /functions — need to npm install /messaging, /crashlytics, /analytics
- expo-build-properties plugin already configured with static linking for RNFBApp, RNFBAuth, RNFBFirestore, RNFBAppCheck — extend for new modules

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- `app.json` plugins array: already has @react-native-firebase/app, /auth, expo-build-properties with static linking config
- `eas.json`: has development/preview/production profiles — production needs content, submit section needs creation
- Legacy `PrivacyInfo.xcprivacy`: complete reference with 5 collected data types and UserDefaults API declaration
- `expo-build-properties` plugin: already configured for iOS static frameworks — extend forceStaticLinking array

### Established Patterns
- Firebase modules registered as app.json plugins (not bare native config)
- EAS env vars used for build-specific config (FIREBASE_APP_CHECK_DEBUG_TOKEN in development)
- Static linking required for all RNFB modules on iOS (CocoaPods constraint)

### Integration Points
- New Firebase modules (messaging, crashlytics, analytics) must be added to both app.json plugins AND expo-build-properties forceStaticLinking
- App Check provider config needs to distinguish development (debug) from preview/production (real attestation) via EAS env vars
- New EAS dev build becomes the base for all Phase 19-23 development and testing

</code_context>

<deferred>
## Deferred Ideas

- Analytics/crash data type additions to PrivacyInfo.xcprivacy — add when Phase 19 lands those features
- App Check enforcement (reject unattested requests) — Phase 22
- Full Phase 17 deferred item retest — later phases as features are built
- Google Play service account key setup for automated submit — after first manual AAB upload

</deferred>

---

*Phase: 18-foundation-config-build-infrastructure*
*Context gathered: 2026-03-17*
