---
phase: 13
plan: "03"
name: "Auth Feature — Notifier + Screen + Route"
subsystem: auth
one-liner: "Email/password auth UI with AuthNotifier wrapping supabase_flutter auth, /auth route added to GoRouter"

tags:
  - flutter
  - supabase
  - riverpod
  - auth
  - go_router

dependency-graph:
  requires:
    - "13-01"  # supabaseClientProvider + supabase_flutter dep
  provides:
    - "authProvider (NotifierProvider<AuthNotifier, AuthState>)"
    - "/auth route in GoRouter"
    - "AuthScreen with email/password form"
  affects:
    - "13-04"  # SyncNotifier — already listens to onAuthStateChange independently
    - "13-05"  # Parity tests — use Key selectors defined here

tech-stack:
  added: []
  patterns:
    - "Riverpod 3.x NotifierProvider for imperative auth state"
    - "ConsumerStatefulWidget for form lifecycle management"
    - "mounted guard pattern for async gaps (if (mounted) before navigation)"
    - "ref.watch in build(), ref.read in imperative methods"
    - "null-safe supabaseClientProvider pattern"

key-files:
  created:
    - flutter_app/lib/features/auth/auth_notifier.dart
    - flutter_app/lib/features/auth/auth_screen.dart
  modified:
    - flutter_app/lib/router/router.dart

decisions:
  - id: "auth-no-sync-logic"
    choice: "AuthNotifier contains zero sync logic"
    rationale: "SyncNotifier handles onAuthStateChange independently — clean separation"
  - id: "auth-signup-returns-true-on-user"
    choice: "signUp returns true when response.user != null (not session != null)"
    rationale: "When email confirmation is enabled, session is null but user exists; returning true lets screen show success feedback"
  - id: "auth-route-no-redirect"
    choice: "/auth route added with no redirect guard modifications"
    rationale: "Auth is optional — onboarding guard stays unchanged; users navigate to /auth voluntarily"

metrics:
  duration: "1m 19s"
  completed: "2026-02-21"
  tasks-completed: 2
  tasks-total: 2
  deviations: 0
---

# Phase 13 Plan 03: Auth Feature — Notifier + Screen + Route Summary

## What Was Built

Email/password authentication feature as a self-contained module. Users can navigate to `/auth` from the dashboard to optionally sign in or create an account to enable cloud sync.

## Tasks Completed

| # | Task | Commit | Key Files |
|---|------|--------|-----------|
| 1 | Create AuthNotifier — sign-in, sign-up, sign-out | `0502536` | `flutter_app/lib/features/auth/auth_notifier.dart` |
| 2 | Create auth screen + add /auth route | `cca6b39` | `flutter_app/lib/features/auth/auth_screen.dart`, `flutter_app/lib/router/router.dart` |

## Decisions Made

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Auth/sync separation | AuthNotifier has zero sync logic | SyncNotifier handles `onAuthStateChange` independently via stream — clean separation of concerns |
| signUp return value | Returns `true` when `response.user != null` | Email confirmation flow: session is null but user exists; allows screen to show success feedback |
| Route guard | `/auth` added with no redirect changes | Auth is optional — onboarding guard unchanged, users navigate to /auth voluntarily |

## Architecture Notes

**AuthState** is a simple immutable value class with `copyWith`. The `copyWith` pattern intentionally passes `errorMessage` as nullable (not via `??`) to allow clearing errors on new attempts.

**AuthNotifier.build()** uses `ref.watch(supabaseClientProvider)` for reactive initialization from current session. Imperative methods (`signIn`, `signUp`, `signOut`) use `ref.read` — no reactive rebuild needed during async calls.

**AuthScreen** is a `ConsumerStatefulWidget` to manage `TextEditingController` lifecycle. The `if (mounted)` guard after async `signIn`/`signUp` calls prevents navigation on disposed widgets.

**Key selectors** for parity gate tests:
- `Key('auth-screen')` — Scaffold root
- `Key('auth-email-field')` — email TextFormField
- `Key('auth-password-field')` — password TextFormField  
- `Key('auth-submit-button')` — submit ElevatedButton
- `Key('auth-toggle')` — mode toggle TextButton
- `Key('auth-error-message')` — error Text (only visible when error exists)

## Deviations from Plan

None — plan executed exactly as written.

## Verification Results

```
cd flutter_app && flutter analyze --no-fatal-infos
→ No issues found! (ran in 2.8s)
```

All must-have artifact checks pass:
- `auth_notifier.dart` exports `AuthNotifier` and `authProvider`
- `auth_screen.dart` is 147 lines (min 80 ✓)
- `router.dart` contains `/auth` route
- `supabaseClientProvider` pattern used in notifier
- `signInWithPassword` called in signIn method

## Next Phase Readiness

**13-04 (SyncNotifier):** Ready. `supabaseClientProvider` is available; auth state flows via `onAuthStateChange` stream from supabase_flutter — independent of `authProvider`.

**13-05 (Parity tests):** Ready. All Key selectors are defined and committed.
