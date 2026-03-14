# Phase 1: Foundation and Infrastructure - Context

**Gathered:** 2026-03-14
**Status:** Ready for planning

<domain>
## Phase Boundary

The app boots, users can authenticate on all platforms, data is secured, and the subscription entitlement pipeline is live. Covers: Expo + React Native project scaffold, Firebase Auth (Apple, Google, Email/Password, Guest), Firestore security rules, EAS development builds (iOS Simulator, Android Emulator, Web), and RevenueCat + Stripe entitlement wiring.

</domain>

<decisions>
## Implementation Decisions

### Auth Screen Presentation
- Stacked full-width buttons layout: Apple on top, then Google, then Email, with "Continue as Guest" as a de-emphasized text link below
- Platform-adaptive provider display: iOS shows Apple + Email + Guest; Android shows Google + Email + Guest; Web shows Google + Email + Guest
- Branding: App logo centered with a short tagline above the auth buttons

### Guest Experience Boundaries
- Guests get full app shell access (tabs, settings, empty states) — no feature lockout, just no data sync
- Guest-to-auth upgrade merges local data into Firestore — no data loss on sign-up
- Gentle, contextual upgrade nudges only when guests try sync-dependent features (no interrupting modals, no periodic reminders)
- "Create Account" option always visible in settings, plus contextual nudges elsewhere

### Sign-out & Session Behavior
- Sign-out requires confirmation dialog ("Are you sure?")
- All locally cached user data cleared on sign-out — clean slate for next user
- After sign-out, user returns directly to the auth screen
- Unlimited simultaneous sessions across devices — Firestore keeps data in sync

### Error & Loading States
- Auth errors shown as inline error messages below the failed button/field — no modals
- Auth loading uses button-level spinner (tapped button shows spinner, all buttons disabled during auth)
- Offline: auth screen displays normally with subtle banner "You're offline. Sign in requires a connection." Guest mode remains available
- Email sign-up requires email verification before granting app access

### Claude's Discretion
- Exact Art Deco styling of auth screen (typography, spacing, decorative elements)
- Email verification screen design and copy
- Specific error message wording for different failure modes
- Animation and transition details between auth states
- RevenueCat + Stripe pipeline implementation details (no user-facing decisions in Phase 1)

</decisions>

<specifics>
## Specific Ideas

No specific requirements — open to standard approaches. The existing iOS app uses Sign in with Apple only; the RN version expands to Google and Email/Password while keeping the same clean, non-cluttered feel.

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- None — this is a greenfield React Native project (no RN code exists yet)
- iOS app's `AuthService.swift`, `KeychainHelper.swift`, and `SignInView.swift` provide reference for auth flow patterns

### Established Patterns
- iOS app uses MVVM + protocol-based repository pattern — RN version should follow similar separation of concerns
- Art Deco design tokens from iOS: cream (#F4F0DF), navy (#0D1A40), orange (#F2731A) — to be refreshed but keeping spirit

### Integration Points
- Firebase project needs to be provisioned (or existing one reused)
- Cloudflare Worker proxy exists at `workout-proxy.sundeefundee.workers.dev` — will be replaced by Firebase Cloud Functions in later phases
- WOD admin dashboard (`wod-dashboard/`) currently uses CloudKit — will migrate to Firestore

</code_context>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 01-foundation-and-infrastructure*
*Context gathered: 2026-03-14*
