# Phase 7: Polish and Pre-Launch - Context

**Gathered:** 2026-03-15
**Status:** Ready for planning

<domain>
## Phase Boundary

The app looks and feels correct on iOS, Android, and Web; sensitive data is secured via Firebase App Check; users can switch weight units, export all their data, and delete their account with full data wipe. The app passes App Store and Play Store review. Requirements: PLAT-04, PLAT-05, PLAT-06, PLAT-07.

</domain>

<decisions>
## Implementation Decisions

### Art Deco design refinement
- Subtle polish only — consistent spacing, typography hierarchy, and card styles across all screens
- No new visual elements (no geometric patterns, custom icons, or Deco animations)
- Make existing screens feel cohesive and finished
- Trust React Native's built-in platform behavior for Android (no custom Android-specific adaptations)
- Claude identifies and fixes inconsistencies during planning (spacing, font sizes, card styles, color usage)

### Firebase App Check
- Enforce at launch — DeviceCheck (iOS) and Play Integrity (Android)
- Firestore security rules require valid App Check token
- Blocks unauthenticated API access from day one

### Weight unit switching (lbs/kg)
- Toggle lives in Settings screen (new "Weight Unit" row, same pattern as rest timer picker)
- Not asked during onboarding — Settings only
- Display-only conversion: all weights stored internally in lbs, converted on display (1 lb = 0.453592 kg)
- No data migration on unit switch — purely a display preference
- Converted kg values rounded to nearest 0.5 kg (gym plate increments)
- Input accepts user's selected unit directly (typing '60' in kg mode means 60 kg, stored as 132.28 lbs)
- Input field shows unit suffix ('kg' or 'lbs')
- Extend AppSettings interface with `weightUnit: 'lbs' | 'kg'` field (default: 'lbs')

### Data export
- Both CSV and JSON formats available — user chooses at export time
- CSV scope: everything exportable — workouts, maxes, benchmarks, cycle logs, injury profiles, pain logs, readiness surveys
- Multiple CSV files bundled in a zip (one per data type)
- JSON: full-fidelity single file with all user data
- Delivered via native share sheet (iOS/Android) or download prompt (web)
- Weights exported in user's selected unit (column header says 'Weight (kg)' or 'Weight (lbs)')
- Export button in Settings screen

### Account deletion
- Two-step confirmation: Step 1 — tap 'Delete Account' in Settings opens warning modal with consequences listed. Step 2 — type 'DELETE' to confirm
- Warning modal suggests but doesn't require data export first: "Want to save your data first? Export it." link to export feature
- Execution via Cloud Function (`deleteAccount`): revokes RevenueCat entitlement, cancels Stripe subscription, deletes ALL Firestore user subcollections (/users/{uid} and all subcollections: workouts, maxes, injuries, painLogs, cycleData, benchmarks, enrollments, readiness, settings), then deletes Firebase Auth account
- Active subscriptions auto-canceled by the Cloud Function (RevenueCat API revoke + Stripe cancel) — no manual cancellation required from user
- Post-deletion: brief "Account deleted" goodbye screen with a 'Done' button that navigates to sign-in
- Client clears local AsyncStorage after Cloud Function succeeds
- Guest users see "Clear Local Data" instead of "Delete Account" — different action, different label (guests have no Firebase Auth or Firestore data)

### Claude's Discretion
- Which screens need spacing/typography fixes (identified during planning audit)
- App Check debug token configuration for development/testing
- CSV column ordering and file naming conventions
- Zip file naming (e.g., "sundee-fundee-export-2026-03-15.zip")
- Goodbye screen design and copy
- Delete confirmation modal exact layout
- Weight unit conversion utility implementation details

</decisions>

<specifics>
## Specific Ideas

- Weight unit input should feel natural for kg users — they type in kg, not lbs. The conversion is invisible to them.
- Account deletion should be thorough (Cloud Function deletes everything server-side) but not hostile — offer export link and show a polite goodbye screen.
- CSV export covers ALL user data types, not just workouts — users who are leaving or switching apps should get everything they put in.
- App Check enforced from launch — defense-in-depth on top of existing Firestore UID-based security rules.

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- `src/theme/colors.ts`: Full Art Deco palette with semantic aliases (background, text, accent, surface, error, border, textMuted, textSecondary)
- `src/theme/typography.ts`: Typography definitions — audit for consistency across screens
- `src/repositories/SettingsRepo.ts`: `getSettingsRepo(isGuest)` + `AppSettings` interface — extend with `weightUnit` field
- `src/entitlements/useEntitlements.ts`: Entitlement hook — needed for checking active subscription during deletion flow
- `src/components/paywall/PaywallModal.tsx`: Modal pattern reusable for delete confirmation
- `functions/`: Firebase Cloud Functions directory (Gemini proxy + Stripe webhook already deployed) — add deleteAccount function here

### Established Patterns
- Platform-specific branching: `Platform.OS` checks throughout (settings, auth) — use for share sheet vs download
- Modal bottom sheet pattern: rest timer picker in Settings — reuse for weight unit picker and export format picker
- `getSettingsRepo(isGuest)` factory: weight unit preference follows same storage pattern
- Dynamic `require('react-native-purchases')` for web safety — applicable for share sheet libraries
- Static helper functions for testability — weight conversion utilities should be static/pure functions

### Integration Points
- Settings screen (`app/(app)/(tabs)/settings.tsx`): Add Weight Unit, Export Data, and Delete Account sections
- AppSettings interface: Add `weightUnit` field
- All weight display locations: workout session, history, maxes, exercise detail, benchmarks, programs — need unit-aware formatting
- Cloud Functions (`functions/`): New `deleteAccount` function
- Firebase Auth: `deleteUser()` called server-side after data wipe
- RevenueCat REST API: Revoke entitlement during account deletion
- Stripe API: Cancel subscription during account deletion

</code_context>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 07-polish-and-pre-launch*
*Context gathered: 2026-03-15*
