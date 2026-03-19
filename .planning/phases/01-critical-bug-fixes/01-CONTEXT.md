# Phase 1: Critical Bug Fixes - Context

**Gathered:** 2026-03-18
**Status:** Ready for planning

<domain>
## Phase Boundary

Fix 5 correctness bugs so the iOS app is stable, correct, and safe to build on. Covers: AI weight unit threading, sign-out/delete schema wipe, guest UUID stability, StoreKit cold-launch gate, and SwiftData migration path. No new features — only fix what's broken.

</domain>

<decisions>
## Implementation Decisions

### AI Weight Unit (FIX-01)
- Parameterize the system prompt in GeminiPromptBuilder — inject user's unit so bar weights, plate values, dumbbell/kettlebell lists are all in the correct unit
- Maintain a **separate kg equipment list** with real gym values (20kg bar, 1.25-25kg plates, standard kg dumbbell/kettlebell sets) — do not convert the lbs list
- Convert user's known maxes to their selected unit before sending to Gemini — no mixed unit signals in the prompt
- All prompt parameterization happens **client-side in GeminiPromptBuilder** — Cloudflare Worker stays a dumb proxy

### Guest UUID & Data Migration (FIX-03)
- Generate stable UUID at first launch, store in **Keychain** using the existing KeychainHelper pattern (new key alongside appleUserID)
- On Apple sign-in: **silent merge** — seamlessly keep all local data, no user prompt
- **Batch update** all SwiftData records from guest UUID to Apple user ID at sign-in time
- **Flag-based retry** — set a "migration pending" flag before starting; if still set on next launch, retry the batch

### StoreKit Cold-Launch Gate (FIX-04)
- **Default to free tier** on cold launch — do not read cached tier from UserDefaults
- Once StoreKit verification completes (typically <1 second), silently upgrade to verified tier
- **Remove UserDefaults cache entirely** — only trust live StoreKit verification; if offline, default to free
- UI transition style: Claude's discretion

### Sign-Out vs Delete-Account (FIX-02)
- **Different scopes:**
  - **Sign-out:** Clear auth state + wipe user-specific workout data, but preserve app preferences (onboarding complete, weight unit, theme). After sign-out, user returns to **guest mode** (can keep using the app without signing in). CloudKit will re-sync data if same user signs back in.
  - **Delete-account:** Destructive confirmation dialog. On confirm: wipe **all** V12 SwiftData models, clear **all** Keychain entries (Apple ID + guest UUID), reset to fresh install state.
- Both paths must reference **V12 schema** (current), not stale V10

### SwiftData Migration Path (FIX-05)
- Apply `migrationPlan: AppSchemaMigrationPlan.self` to the local persistent store path (currently only applied to CloudKit path)

### Claude's Discretion
- StoreKit tier upgrade UI transition (invisible vs subtle animation)
- Exact error handling for edge cases in batch userID migration
- Migration plan application approach for local store

</decisions>

<specifics>
## Specific Ideas

- Guest mode is a first-class experience — sign-in is always optional, sign-out returns to guest mode
- AI weight prescriptions should feel native to the user's unit system — kg users should see real metric equipment, not converted imperial values
- Delete-account must be genuinely destructive (Apple App Review requirement) — no hidden data retention

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- `KeychainHelper` (Auth/KeychainHelper.swift): Already has save/load/delete pattern for Keychain — add guest UUID key alongside existing appleUserIDKey
- `GeminiPromptBuilder` (Repositories/Gemini/GeminiPromptBuilder.swift): System prompt is a static string — needs to become a function that accepts weight unit
- `WorkoutGenerationContext` (Domain/AIWorkout/WorkoutGenerationContext.swift): Already carries `weightUnit` property — use this to drive prompt parameterization
- `WeightUnitConversion` (Domain/Calculations/WeightUnitConversion.swift): Existing conversion utilities for lbs/kg

### Established Patterns
- MVVM + Repository pattern with protocol abstractions
- SwiftData schema versioned (V1-V12) with lightweight migration stages
- `AppModelContainer` handles container creation with tiered fallback (CloudKit → local → in-memory)
- `SubscriptionService` is @Observable @MainActor — UI reacts to tier changes automatically

### Integration Points
- `AppModelContainer.makeContainer(.localPersistent)` at line 96 — needs `migrationPlan:` parameter added
- `SubscriptionService.init()` at line 69 — remove UserDefaults read, default to `.free`
- `AppState` / `SettingsView` — sign-out and delete-account flows reference schema version (verify V12)
- `AuthService` — guest-to-auth transition triggers batch userID update

</code_context>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 01-critical-bug-fixes*
*Context gathered: 2026-03-18*
