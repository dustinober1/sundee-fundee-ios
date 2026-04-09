# Requirements: Sundee Fundee v1.1

**Defined:** 2026-04-08
**Core Value:** A polished, 100% free iOS app for cycle-aware strength training, shipped to the App Store.

## v1 Requirements

Requirements for v1.1 Free App Launch. Each maps to roadmap phases.

### Subscription Removal

- [ ] **SUB-01**: User has unrestricted access to all features with no subscription UI or paywall
- [ ] **SUB-02**: All StoreKit 2 code removed from the codebase (Subscription/ directory deleted)
- [ ] **SUB-03**: All subscription gating removed from UI views (Dashboard, Analytics, Export, PainTracking, Settings)
- [ ] **SUB-04**: All subscription checks removed from view models (Dashboard, Analytics, Export, PainTracking, Settings VMs)
- [ ] **SUB-05**: Subscription tier reference removed from domain layer (CoachContext)
- [ ] **SUB-06**: StoreKit initialization removed from App.swift entry point
- [ ] **SUB-07**: Subscription-related tests updated to verify "always unlocked" behavior
- [ ] **SUB-08**: Entitlements file cleaned (remove in-app-payments entry)

### Audit & Polish

- [ ] **AUD-01**: All stub/placeholder implementations identified and fixed (AI workout generation, CloudKit delete ops)
- [ ] **AUD-02**: Guest mode fully functional with no dead ends or subscription gates
- [ ] **AUD-03**: Manual QA pass through all screens — no crashes, no broken navigation
- [ ] **AUD-04**: VoiceOver labels on all interactive elements
- [ ] **AUD-05**: Dynamic Type support verified across all views
- [ ] **AUD-06**: Color contrast meets WCAG AA standards for Art Deco theme

### App Store Submission

- [ ] **ASC-01**: Privacy Policy URL hosted and reachable
- [ ] **ASC-02**: Support URL hosted and reachable
- [ ] **ASC-03**: App Store metadata complete (title, subtitle, description, keywords, copyright)
- [ ] **ASC-04**: Age rating questionnaire completed accurately
- [ ] **ASC-05**: Review contact info configured
- [ ] **ASC-06**: Content rights declaration submitted
- [ ] **ASC-07**: Screenshots captured for iPhone 6.7" and 6.5" (minimum 3 per size)
- [ ] **ASC-08**: App archived, uploaded to App Store Connect
- [ ] **ASC-09**: App submitted for review

## v2 Requirements

Deferred to future release. Tracked but not in current roadmap.

### Post-Launch Growth

- **GROW-01**: App Store preview video (15-30s showing cycle-aware workout flow)
- **GROW-02**: SKStoreReviewController rating prompt after 3+ completed workouts
- **GROW-03**: App Store Optimization iteration based on search analytics
- **GROW-04**: TestFlight public link for beta testing future updates
- **GROW-05**: App Store featuring submission once ratings and retention are strong

### Localization

- **L10N-01**: App Store listing localized for top 5 markets based on analytics
- **L10N-02**: In-app UI localization for selected languages

### Future Monetization

- **MON-01**: Tip jar / patron model implemented after following established
- **MON-02**: Premium feature tier designed based on user feedback

## Out of Scope

| Feature | Reason |
|---------|--------|
| Ad-supported model | Degrades UX, requires ad SDK + ATT, extends review scope |
| Tip jar / one-time IAP | Adds StoreKit complexity back. Monetization deferred entirely |
| iPad-optimized layout | iPad runs iPhone apps via compatibility mode. Separate layout is multi-week effort |
| In-app announcement banner | App has never been paid on iOS. Banner would confuse new users |
| Migration messaging for paid users | No existing paying users — this is a first launch |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| SUB-01 | — | Pending |
| SUB-02 | — | Pending |
| SUB-03 | — | Pending |
| SUB-04 | — | Pending |
| SUB-05 | — | Pending |
| SUB-06 | — | Pending |
| SUB-07 | — | Pending |
| SUB-08 | — | Pending |
| AUD-01 | — | Pending |
| AUD-02 | — | Pending |
| AUD-03 | — | Pending |
| AUD-04 | — | Pending |
| AUD-05 | — | Pending |
| AUD-06 | — | Pending |
| ASC-01 | — | Pending |
| ASC-02 | — | Pending |
| ASC-03 | — | Pending |
| ASC-04 | — | Pending |
| ASC-05 | — | Pending |
| ASC-06 | — | Pending |
| ASC-07 | — | Pending |
| ASC-08 | — | Pending |
| ASC-09 | — | Pending |

**Coverage:**
- v1 requirements: 23 total
- Mapped to phases: 0
- Unmapped: 23 ⚠️

---
*Requirements defined: 2026-04-08*
*Last updated: 2026-04-08 after initial definition*
