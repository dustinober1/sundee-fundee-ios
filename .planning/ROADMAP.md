# Sundee Fundee — Roadmap

## Milestones

- **v1.0 Repo Cleanup** -- Phases 1-11 (shipped 2026-04-09)
- **v1.1 Free App Launch** -- Phases 12-19 (in progress)

## Phases

<details>
<summary>v1.0 Repo Cleanup (Phases 1-11) -- SHIPPED 2026-04-09</summary>

- [x] Phase 1: Pre-Cleanup Audit (1/1 plans) -- completed 2026-04-08
- [x] Phase 2: Archive Creation (1/1 plans) -- completed 2026-04-08
- [x] Phase 3: Directory Deletion -- completed 2026-04-08
- [x] Phase 4: Supporting Files Deletion -- completed 2026-04-08
- [x] Phase 5: Root Config Cleanup -- completed 2026-04-08
- [x] Phase 6: Gitignore Update -- completed 2026-04-08
- [x] Phase 7: Documentation Core -- completed 2026-04-09
- [x] Phase 8: Migration Documentation -- completed 2026-04-09
- [x] Phase 9: Cross-Reference Verification -- completed 2026-04-09
- [x] Phase 10: CHANGELOG Creation -- completed 2026-04-09
- [x] Phase 11: SwiftLint Configuration -- completed 2026-04-09

Full details: [.planning/milestones/v1.0-ROADMAP.md](milestones/v1.0-ROADMAP.md)

</details>

### v1.1 Free App Launch (In Progress)

**Milestone Goal:** Remove the paywall, polish the app, and ship to the App Store as a 100% free app.

- [x] **Phase 12: Unlock Features** -- Flip all subscription tier flags to unlocked, create FreeSubscriptionClient, swap App.swift entry point (completed 2026-04-09)
- [x] **Phase 13: Remove Paywall UI** -- Strip all subscription gating UI from views and view models, delete Subscription/ directory (completed 2026-04-09)
- [x] **Phase 14: Entitlements and Tests** -- Clean entitlements, update tests to verify always-unlocked behavior (completed 2026-04-09)
- [x] **Phase 15: Fix Stubs and Guest Mode** -- Replace all placeholder implementations, verify guest mode works end-to-end (completed 2026-04-10)
- [x] **Phase 16: Accessibility** -- VoiceOver labels, Dynamic Type, and color contrast across all views (completed 2026-04-10)
- [x] **Phase 17: QA Pass** -- Manual QA through all screens, verify no crashes or broken navigation (completed 2026-04-10)
- [x] **Phase 18: App Store Prep** -- Host URLs, complete metadata, screenshots, privacy declarations (completed 2026-04-10)
- [ ] **Phase 19: Archive and Submit** -- Archive build, upload to App Store Connect, submit for review

## Phase Details

### Phase 12: Unlock Features
**Goal**: All features are functionally unlocked in the app, even though paywall UI may still exist visually
**Depends on**: Nothing (first phase of v1.1)
**Requirements**: SUB-01, SUB-02 (partial), SUB-05, SUB-06
**Success Criteria** (what must be TRUE):
  1. Every feature that was gated behind a subscription tier is now accessible without restriction
  2. App.swift initializes with FreeSubscriptionClient instead of StoreKitClient
  3. SubscriptionTier capability flags all return true and quantitative limits return unlimited
  4. CoachContext no longer references subscription tier
**Plans**: 2 plans

Plans:
- [ ] 12-01-PLAN.md — Create FreeSubscriptionClient + modify SubscriptionTier for premium-equivalent access
- [ ] 12-02-PLAN.md — Swap App.swift entry point + make CoachContext always resolve to .premium

### Phase 13: Remove Paywall UI
**Goal**: Users see no subscription-related UI anywhere in the app
**Depends on**: Phase 12
**Requirements**: SUB-02, SUB-03, SUB-04
**Success Criteria** (what must be TRUE):
  1. No upgrade prompts, lock icons, tier badges, or subscription sheets appear on any screen
  2. Dashboard, Analytics, Export, PainTracking, and Settings views contain zero subscription UI elements
  3. Dashboard, Analytics, Export, PainTracking, and Settings view models contain zero subscription-checking code
  4. The Subscription/ directory is fully deleted from the codebase
**Plans**: 2 plans

Plans:
- [x] 13-01-PLAN.md — Strip subscription UI from views and subscription-checking code from view models
- [x] 13-02-PLAN.md — Delete Subscription/ files, clean AuthViewModel and App.swift, verify build

**UI hint**: yes

### Phase 14: Entitlements and Tests
**Goal**: Build artifacts and test suite reflect a subscription-free app
**Depends on**: Phase 13
**Requirements**: SUB-07, SUB-08
**Success Criteria** (what must be TRUE):
  1. The entitlements file has no in-app-payments entry
  2. All subscription-related tests pass and verify "always unlocked" behavior
  3. Full test suite runs green with zero subscription-related test failures
  4. Xcode project builds cleanly with no subscription import errors
**Plans**: 1 plan

Plans:
- [x] 14-01-PLAN.md — Remove in-app-payments entitlement + create FreeSubscriptionClient always-unlocked tests

### Phase 15: Fix Stubs and Guest Mode
**Goal**: Every user-facing feature uses real implementations, and guest mode works without dead ends
**Depends on**: Phase 14
**Requirements**: AUD-01, AUD-02
**Success Criteria** (what must be TRUE):
  1. AI workout generation returns actual workout data instead of sleeping or returning placeholder content
  2. CloudKit delete operations fully remove records from the database
  3. No TODO, stub, or placeholder comments remain in user-facing code paths
  4. Guest mode user can navigate all screens and use all features without hitting dead ends or empty states
  5. Signed-in user experience is unchanged from pre-stub-fix behavior
**Plans**: 1 plan

Plans:
- [x] 15-01-PLAN.md — Remove dead AI workout stub from DashboardViewModel + verify guest mode navigation

### Phase 16: Accessibility
**Goal**: The app is usable by people relying on VoiceOver, Dynamic Type, and sufficient color contrast
**Depends on**: Phase 15
**Requirements**: AUD-04, AUD-05, AUD-06
**Success Criteria** (what must be TRUE):
  1. VoiceOver reads meaningful labels on every interactive element (buttons, toggles, sliders, tabs)
  2. All views remain usable and readable at maximum Dynamic Type size
  3. Art Deco theme colors (cream/navy/orange) meet WCAG AA contrast ratios
**Plans**: 2 plans

Plans:
- [x] 16-01-PLAN.md — Add VoiceOver labels and hints to all interactive elements across all views
- [x] 16-02-PLAN.md — Convert typography to Dynamic Type + adjust colors for WCAG AA contrast

**UI hint**: yes

### Phase 17: QA Pass
**Goal**: The app is crash-free and fully navigable across all screens and user modes
**Depends on**: Phase 16
**Requirements**: AUD-03
**Success Criteria** (what must be TRUE):
  1. Manual traversal of every screen produces zero crashes
  2. All navigation flows work correctly (forward, back, deep links, tab switches)
  3. Guest mode and signed-in mode both pass full screen-by-screen QA
  4. No console warnings or errors appear during normal usage
**Plans**: TBD
**UI hint**: yes

### Phase 18: App Store Prep
**Goal**: All App Store Connect metadata, screenshots, and legal pages are in place
**Depends on**: Phase 17
**Requirements**: ASC-01, ASC-02, ASC-03, ASC-04, ASC-05, ASC-06, ASC-07
**Success Criteria** (what must be TRUE):
  1. Privacy Policy URL returns a live, reachable page
  2. Support URL returns a live, reachable page
  3. App Store listing has complete title, subtitle, description, keywords, and copyright
  4. Age rating questionnaire is completed and reflects the app accurately
  5. Screenshots captured for iPhone 6.7" and 6.5" (minimum 3 per size) showing the app's narrative flow
**Plans**: TBD
**UI hint**: yes

### Phase 19: Archive and Submit
**Goal**: The app binary is uploaded and submitted for App Store review
**Depends on**: Phase 18
**Requirements**: ASC-08, ASC-09
**Success Criteria** (what must be TRUE):
  1. App archives without errors in Xcode
  2. Build uploads successfully to App Store Connect
  3. App is submitted for review with all metadata and build attached
**Plans**: TBD

## Progress

**Execution Order:**
Phases execute in numeric order: 12 -> 13 -> 14 -> 15 -> 16 -> 17 -> 18 -> 19

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 12. Unlock Features | v1.1 | 0/2 | Complete    | 2026-04-09 |
| 13. Remove Paywall UI | v1.1 | 2/2 | Complete | 2026-04-09 |
| 14. Entitlements and Tests | v1.1 | 1/1 | Complete | 2026-04-09 |
| 15. Fix Stubs and Guest Mode | v1.1 | 1/1 | Complete | 2026-04-10 |
| 16. Accessibility | v1.1 | 2/2 | Complete    | 2026-04-10 |
| 17. QA Pass | v1.1 | 0/0 | Complete    | 2026-04-10 |
| 18. App Store Prep | v1.1 | 0/0 | Complete    | 2026-04-10 |
| 19. Archive and Submit | v1.1 | 0/? | Not started | - |

---
*Roadmap created: 2026-04-08*
*Last updated: 2026-04-10 after Phase 16 planning*
