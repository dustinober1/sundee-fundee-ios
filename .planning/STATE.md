---
gsd_state_version: 1.0
milestone: v1.1
milestone_name: Launch Readiness
status: completed
stopped_at: Completed 18-01-PLAN.md
last_updated: "2026-03-17T13:07:58.196Z"
last_activity: 2026-03-17 — Phase 17.1 Plan 02 complete; configs updated, tests validated at root
progress:
  total_phases: 8
  completed_phases: 2
  total_plans: 7
  completed_plans: 6
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-03-16)

**Core value:** Users get personalized, cycle-aware strength training that adapts to their body — available on any platform, online or offline.
**Current focus:** Phase 17.1 — Repo Restructure (Promote RN to Root)

## Current Position

Phase: 17.1 (Repo Restructure — Promote RN to Root)
Plan: 2 of 2 in current phase (Plan 02 complete)
Status: Phase 17.1 Complete — all plans executed
Last activity: 2026-03-17 — Phase 17.1 Plan 02 complete; configs updated, tests validated at root

Progress (v1.1): [██████████] 100% (5/5 plans complete)

## Accumulated Context

### Decisions

- [v1.0]: React Native + Expo over Flutter — proven multi-platform, JS/TS ecosystem
- [v1.0]: Firebase over Supabase — better Expo integration, offline-first
- [v1.0]: RevenueCat + Stripe dual payments — handles app store complexity
- [v1.1]: Device verification first — resolve ~30 known items before adding native modules
- [v1.1]: Phase 18 before 19/20 — native module additions require new EAS build first (hard constraint)
- [v1.1]: expo-notifications owns all notification display; @react-native-firebase/messaging handles background data only
- [Phase 17-01]: iPhone 17 Pro used as primary target — iPhone 16 Pro unavailable in simulator pool
- [Phase 17-01]: Slider replaced with TouchableOpacity row (1-10) — @react-native-community/slider requires native rebuild (out of scope)
- [Phase 17-01]: P5-3 code-verified only — NLC simulation blocked by macOS Accessibility permissions
- [Phase 17.1-01]: Two commits used for file promotion (archive + promote) instead of single atomic commit
- [Phase 17.1-01]: google-services.json was tracked in git, moved via git mv
- [Phase 17.1]: Jest testPathIgnorePatterns added to scope tests to RN app only after root promotion
- [Phase 18-01]: analytics has no config plugin — only forceStaticLinking entry added, not plugins array
- [Phase 18-01]: initFirebase() order: AppCheck first (secures all Firebase calls), then Crashlytics, Analytics, Messaging
- [Phase 18-01]: EXPO_PUBLIC_APP_CHECK_DEBUG_TOKEN replaces FIREBASE_APP_CHECK_DEBUG_TOKEN in eas.json — only EXPO_PUBLIC_ vars accessible in JS runtime

### Roadmap Evolution

- Phase 17.1 inserted after Phase 17: Repo Restructure — Promote RN to Root (URGENT)

### Pending Todos

None yet.

### Blockers/Concerns

- [Phase 17]: ~30 human verification items from v1.0 need triage — some may require code fixes
- [Phase 18]: @react-native-firebase/messaging + /crashlytics + /analytics require new EAS dev build before phases 19/20 can be device-tested
- [Phase 18]: PrivacyInfo.xcprivacy required for App Store — cycle data must be declared as sensitive health information linked to user identity (ITMS-91053 rejection risk)
- [Phase 22]: Firestore security rules not yet deployed to production
- [Phase 23]: First Android Play Store submission must be a manual AAB upload — EAS Submit cannot do a first-ever submission

## Session Continuity

Last session: 2026-03-17T13:07:58.194Z
Stopped at: Completed 18-01-PLAN.md
Resume file: None
