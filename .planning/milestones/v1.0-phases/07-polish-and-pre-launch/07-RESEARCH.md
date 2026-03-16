# Phase 7: Polish and Pre-Launch - Research

**Researched:** 2026-03-15
**Domain:** React Native cross-platform polish, Firebase App Check, weight unit display, data export, account deletion
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Art Deco design refinement**
- Subtle polish only — consistent spacing, typography hierarchy, and card styles across all screens
- No new visual elements (no geometric patterns, custom icons, or Deco animations)
- Make existing screens feel cohesive and finished
- Trust React Native's built-in platform behavior for Android (no custom Android-specific adaptations)
- Claude identifies and fixes inconsistencies during planning (spacing, font sizes, card styles, color usage)

**Firebase App Check**
- Enforce at launch — DeviceCheck (iOS) and Play Integrity (Android)
- Firestore security rules require valid App Check token
- Blocks unauthenticated API access from day one

**Weight unit switching (lbs/kg)**
- Toggle lives in Settings screen (new "Weight Unit" row, same pattern as rest timer picker)
- Not asked during onboarding — Settings only
- Display-only conversion: all weights stored internally in lbs, converted on display (1 lb = 0.453592 kg)
- No data migration on unit switch — purely a display preference
- Converted kg values rounded to nearest 0.5 kg (gym plate increments)
- Input accepts user's selected unit directly (typing '60' in kg mode means 60 kg, stored as 132.28 lbs)
- Input field shows unit suffix ('kg' or 'lbs')
- Extend AppSettings interface with `weightUnit: 'lbs' | 'kg'` field (default: 'lbs')

**Data export**
- Both CSV and JSON formats available — user chooses at export time
- CSV scope: everything exportable — workouts, maxes, benchmarks, cycle logs, injury profiles, pain logs, readiness surveys
- Multiple CSV files bundled in a zip (one per data type)
- JSON: full-fidelity single file with all user data
- Delivered via native share sheet (iOS/Android) or download prompt (web)
- Weights exported in user's selected unit (column header says 'Weight (kg)' or 'Weight (lbs)')
- Export button in Settings screen

**Account deletion**
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

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| PLAT-04 | Refreshed Art Deco design (cream/navy/orange palette evolved) | Audit pattern, typography tokens already defined in `src/theme/` — identify inconsistencies systematically |
| PLAT-05 | User can switch between lbs and kg | `weightUnit` field already exists in `AppSettings` interface; domain conversion functions already exist in `src/domain/calculations/weight-unit-conversion.ts`; UI integration is the missing piece |
| PLAT-06 | User can export workout data (CSV or JSON) | `expo-file-system` + `expo-sharing` combination confirmed; zip requires `react-native-zip-archive` (native) or per-file share pattern |
| PLAT-07 | User can delete account with full data wipe | `db.recursiveDelete()` via firebase-admin confirmed; RevenueCat DELETE subscriber endpoint confirmed; Stripe subscription cancel endpoint confirmed |
</phase_requirements>

## Summary

Phase 7 is a polish and infrastructure-hardening phase with four distinct work streams: (1) visual consistency audit, (2) weight unit display plumbing across the app, (3) data export via native share sheet, and (4) account deletion via Cloud Function. The good news is that significant groundwork is already in place — the `weightUnit: 'lb' | 'kg'` field exists in `AppSettings`, the domain conversion utilities (`lbToKg`, `kgToLb`, `valueFromKilograms`, `kilogramsFrom`) are already implemented and tested in `src/domain/calculations/weight-unit-conversion.ts`, and the `revokeRCEntitlement` helper already exists in `stripeWebhook.ts` and can be extracted for reuse in the delete flow.

Firebase App Check requires a new native module (`@react-native-firebase/app-check`) and native init code in `AppDelegate.mm`/`AppDelegate.swift`. This is an Expo dev-client project (not Managed Workflow), so native code changes are possible but require a new build. The App Check token is automatically attached to all Firebase service calls after initialization — no per-call changes needed. Debug tokens must be generated and registered in Firebase Console for development; the `__DEV__` flag is used to switch providers at runtime.

For data export, `expo-file-system` (write to cache) + `expo-sharing` (shareAsync) covers iOS and Android cleanly. Web requires a different path: generate a Blob URL and trigger a synthetic anchor click download. Zip creation with multiple CSV files is the trickiest piece — `react-native-zip-archive` requires a native build but is the clean solution. The fallback is to share files individually (one at a time) or generate a single structured JSON export. Given this project uses `expo-dev-client`, adding `react-native-zip-archive` is viable.

**Primary recommendation:** Use `expo-file-system` + `expo-sharing` for iOS/Android export, `react-native-zip-archive` for zip bundling, `@react-native-firebase/app-check` for App Check, and `db.recursiveDelete()` in the `deleteAccount` Cloud Function. The weight unit work is entirely display-layer — no data changes, no migration.

## Standard Stack

### Core (New in Phase 7)
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `@react-native-firebase/app-check` | ^21.x (matches other RNF packages) | Firebase App Check: DeviceCheck + Play Integrity | Official RNF package; matches existing `@react-native-firebase/*` install |
| `expo-file-system` | ~18.x (via `npx expo install`) | Write export files to cache directory | Official Expo SDK; supports iOS + Android; web not supported |
| `expo-sharing` | ~12.x (via `npx expo install`) | Trigger native share sheet with file URI | Official Expo SDK; works across platforms; web HTTPS required |
| `react-native-zip-archive` | ^6.x | Bundle multiple CSV files into a zip | Only native zip lib with active maintenance; needed for multi-CSV export |

### Already Present (Use These)
| Library | Location | Purpose |
|---------|----------|---------|
| `weight-unit-conversion.ts` | `src/domain/calculations/` | `lbToKg`, `kgToLb`, `valueFromKilograms`, `kilogramsFrom` — all tested |
| `AppSettings.weightUnit` | `src/repositories/SettingsRepo.ts` | `'lb' \| 'kg'` field already in interface; default `'lb'` |
| `revokeRCEntitlement()` | `functions/src/stripeWebhook.ts` | Extract and reuse in `deleteAccount` function |
| `db.recursiveDelete()` | firebase-admin ^12.x (already installed) | Recursive Firestore doc + subcollection delete |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `react-native-zip-archive` | Share files individually (no zip) | Simpler (no new native dep), but worse UX — multiple share sheets |
| `react-native-zip-archive` | JSZip (pure JS) | JSZip causes "unable to resolve module 'stream'" in Expo; not viable |
| `expo-file-system` | `react-native-fs` | `expo-file-system` is already in Expo SDK; no extra install |
| `db.recursiveDelete()` | Manual subcollection traversal | `recursiveDelete` is built into firebase-admin ^11+; manual traversal is error-prone |

**Installation (new packages only):**
```bash
# In SundeeFundeeRN/
npx expo install expo-file-system expo-sharing

# react-native-zip-archive requires native build
cd SundeeFundeeRN && npm install react-native-zip-archive

# In functions/
# No new packages — firebase-admin already installed
```

```bash
# App Check — must match existing RNF version constraint
cd SundeeFundeeRN && npm install @react-native-firebase/app-check
```

## Architecture Patterns

### Recommended Project Structure (additions only)
```
SundeeFundeeRN/
├── src/
│   ├── export/                     # NEW — data export utilities
│   │   ├── exportData.ts           # Orchestrates data collection + file generation
│   │   ├── csvFormatters.ts        # Pure functions: data → CSV string per type
│   │   └── __tests__/
│   │       └── exportData.test.ts
│   ├── domain/
│   │   └── calculations/
│   │       └── weight-unit-conversion.ts  # EXISTING — already complete
│   └── firebase/
│       └── appCheck.ts             # NEW — App Check init (called from app/_layout.tsx)
functions/src/
└── deleteAccount.ts                # NEW Cloud Function
```

### Pattern 1: Firebase App Check Initialization

**What:** Initialize App Check before any Firebase service call, using platform-specific providers.
**When to use:** Once at app startup, before any Firestore/Auth calls.

```typescript
// src/firebase/appCheck.ts
import { getApp } from '@react-native-firebase/app';
import {
  initializeAppCheck,
  ReactNativeFirebaseAppCheckProvider,
} from '@react-native-firebase/app-check';

let initialized = false;

export async function initAppCheck(): Promise<void> {
  if (initialized) return;
  initialized = true;

  const provider = new ReactNativeFirebaseAppCheckProvider();
  provider.configure({
    android: {
      provider: __DEV__ ? 'debug' : 'playIntegrity',
      debugToken: process.env.EXPO_PUBLIC_APP_CHECK_DEBUG_TOKEN,
    },
    apple: {
      provider: __DEV__ ? 'debug' : 'appAttestWithDeviceCheckFallback',
      debugToken: process.env.EXPO_PUBLIC_APP_CHECK_DEBUG_TOKEN,
    },
  });

  await initializeAppCheck(getApp(), {
    provider,
    isTokenAutoRefreshEnabled: true,
  });
}
```

```objc
// ios/SundeeFundeeRN/AppDelegate.mm — add BEFORE [FIRApp configure]
#import "RNFBAppCheckModule.h"
[RNFBAppCheckModule sharedInstance];
[FIRApp configure];
```

**Debug token setup:**
1. Run app in dev, check console for auto-generated debug token
2. Register it in Firebase Console → App Check → Apps → Manage debug tokens
3. Or set `EXPO_PUBLIC_APP_CHECK_DEBUG_TOKEN` env var to a pre-registered token

### Pattern 2: Weight Unit Display

**What:** Read `weightUnit` from settings context, format weights at display time using domain utility.
**When to use:** Every weight display location — workout session, history, maxes, exercise detail, benchmarks, programs.

```typescript
// src/utils/formatWeight.ts (new utility)
import { lbToKg } from '@/src/domain/calculations/weight-unit-conversion';

/** Round to nearest 0.5 for kg display (gym plate increments). */
function roundToHalf(n: number): number {
  return Math.round(n * 2) / 2;
}

/** Format a weight stored in lbs for display in user's preferred unit. */
export function formatWeight(lbs: number, unit: 'lb' | 'kg'): string {
  if (unit === 'kg') {
    return `${roundToHalf(lbToKg(lbs)).toFixed(1)} kg`;
  }
  return `${lbs} lbs`;
}

/** Parse user input in their preferred unit, return stored lbs value. */
export function parseWeightInput(value: string, unit: 'lb' | 'kg'): number {
  const n = parseFloat(value);
  if (unit === 'kg') {
    return n * 2.2046226218; // kgToLb constant from domain
  }
  return n;
}
```

**Settings integration:** The `weightUnit` field already exists in `AppSettings`. The Settings screen needs a new row — same bottom-sheet pattern as the rest timer picker. No data migration required.

### Pattern 3: Data Export

**What:** Collect user data from all Firestore subcollections, format as CSV or JSON, write to cache, share via native sheet.
**When to use:** When user taps "Export Data" in Settings.

```typescript
// src/export/exportData.ts (simplified flow)
import * as FileSystem from 'expo-file-system/legacy';
import * as Sharing from 'expo-sharing';
import { zip } from 'react-native-zip-archive';

export async function exportUserData(
  uid: string,
  format: 'csv' | 'json',
  weightUnit: 'lb' | 'kg',
): Promise<void> {
  const data = await collectAllUserData(uid);     // query Firestore
  const exportDate = new Date().toISOString().split('T')[0];

  if (format === 'json') {
    const json = JSON.stringify(data, null, 2);
    const path = `${FileSystem.cacheDirectory}sundee-fundee-export-${exportDate}.json`;
    await FileSystem.writeAsStringAsync(path, json);
    await Sharing.shareAsync(path, { dialogTitle: 'Export Your Data' });
  } else {
    // Write each CSV file to cache
    const csvFiles = buildCsvFiles(data, weightUnit);   // returns [{name, content}]
    const dir = `${FileSystem.cacheDirectory}sf-export-${exportDate}/`;
    await FileSystem.makeDirectoryAsync(dir, { intermediates: true });
    for (const file of csvFiles) {
      await FileSystem.writeAsStringAsync(dir + file.name, file.content);
    }
    // Zip them
    const zipPath = `${FileSystem.cacheDirectory}sundee-fundee-export-${exportDate}.zip`;
    await zip(dir, zipPath);
    await Sharing.shareAsync(zipPath, { dialogTitle: 'Export Your Data' });
  }
}
```

**Web export:** `expo-sharing` is not available on web. Use `Blob` + `URL.createObjectURL` + synthetic `<a>` click. Wrap with `Platform.OS === 'web'` check.

### Pattern 4: Account Deletion Cloud Function

**What:** Callable Cloud Function that fully wipes a user's data and revokes subscriptions server-side.
**When to use:** Called by client after user types "DELETE" in confirmation modal.

```typescript
// functions/src/deleteAccount.ts
import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { defineSecret } from 'firebase-functions/params';
import * as admin from 'firebase-admin';
import Stripe from 'stripe';

const STRIPE_SECRET_KEY = defineSecret('STRIPE_SECRET_KEY');
const RC_SECRET_API_KEY = defineSecret('RC_SECRET_API_KEY');

export const deleteAccount = onCall(
  { secrets: [STRIPE_SECRET_KEY, RC_SECRET_API_KEY] },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'Must be authenticated');
    }
    const uid = request.auth.uid;
    const db = admin.firestore();

    // 1. Revoke RevenueCat entitlement (best-effort)
    await revokeRCEntitlement(uid, RC_SECRET_API_KEY.value());

    // 2. Cancel Stripe subscription (best-effort — find subscription from Firestore)
    const userDoc = await db.doc(`users/${uid}`).get();
    const stripeSubscriptionId = userDoc.data()?.stripeSubscriptionId as string | undefined;
    if (stripeSubscriptionId) {
      const stripe = new Stripe(STRIPE_SECRET_KEY.value());
      await stripe.subscriptions.cancel(stripeSubscriptionId).catch(() => {/* best-effort */});
    }

    // 3. Delete all Firestore data (recursiveDelete handles subcollections)
    await db.recursiveDelete(db.doc(`users/${uid}`));

    // 4. Delete Firebase Auth user
    await admin.auth().deleteUser(uid);

    return { success: true };
  }
);
```

**Important:** The existing `createCheckoutSession` does NOT store the Stripe subscription ID to Firestore. The `deleteAccount` function needs either: (a) the webhook to store `stripeSubscriptionId` on the user doc, or (b) a Stripe customer lookup by metadata. Option (a) is simpler — add one line to `stripeWebhook.ts` on `subscription.created`.

### Anti-Patterns to Avoid

- **Calling `admin.auth().deleteUser()` before Firestore wipe:** If the auth delete fails after Firestore wipe, user is locked out with data gone. Always delete Firestore first.
- **Storing weight in kg:** Never convert storage — always lbs. The CONTEXT explicitly requires display-only conversion.
- **Sharing a local file URI directly on web:** `expo-sharing` is not available on web. Must detect `Platform.OS === 'web'` and use browser download fallback.
- **Initializing App Check after Firebase calls:** Any Firestore call before `initAppCheck()` will fail once Firestore rules require App Check tokens.
- **Using JSZip in Expo:** Causes "unable to resolve module 'stream'" errors. Use `react-native-zip-archive` instead.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| lbs ↔ kg conversion | Custom conversion constants | `weight-unit-conversion.ts` (already in repo) | Already tested, matches Swift domain exactly |
| File sharing on mobile | Custom share sheet | `expo-sharing` `shareAsync()` | Handles iOS UIActivityViewController + Android Intent automatically |
| File write to disk | Custom native bridge | `expo-file-system` `writeAsStringAsync()` | Cross-platform, cache directory cleared automatically |
| Zip multiple files | In-memory zip assembler | `react-native-zip-archive` | Only viable native zip solution for Expo dev-client |
| Subcollection deletion | Manual traversal loop | `db.recursiveDelete()` | Admin SDK handles arbitrarily nested subcollections |
| App Check provider logic | Custom attestation | `@react-native-firebase/app-check` | DeviceCheck/Play Integrity attestation cannot be hand-rolled |

**Key insight:** The weight conversion domain layer is already complete. Phase 7 weight work is purely a UI plumbing exercise — thread the `weightUnit` setting into every display location and input handler.

## Common Pitfalls

### Pitfall 1: App Check Breaks Emulator/Simulator Testing
**What goes wrong:** App Check with `appAttestWithDeviceCheckFallback` or `playIntegrity` requires a physical device. Simulator/emulator will return invalid attestation, breaking all Firestore calls.
**Why it happens:** DeviceCheck and Play Integrity are hardware-backed attestation; simulators have no signing identity.
**How to avoid:** Use `provider: __DEV__ ? 'debug' : 'appAttestWithDeviceCheckFallback'` — debug provider accepts the registered debug token on any device including simulators.
**Warning signs:** Firestore calls fail with PERMISSION_DENIED after adding App Check.

### Pitfall 2: App Check Init Must Precede Firebase Calls
**What goes wrong:** App Check initialized too late; first Firestore call fires before provider is ready; subsequent calls fail PERMISSION_DENIED.
**Why it happens:** `initializeAppCheck` is async and must complete before any Firebase service call when rules require a valid token.
**How to avoid:** Call `initAppCheck()` in `app/_layout.tsx` before the `<SessionProvider>` renders, or in the native `AppDelegate` init before `[FIRApp configure]`.

### Pitfall 3: Weight Input Round-Trip Precision
**What goes wrong:** User types "60 kg" → stored as 132.2773... lbs → displayed back as 60.0 kg. But `Math.round(132.28 * POUNDS_PER_KG * 2) / 2 = 60.0` — this is fine. But if user logs 60 kg and program target is 132 lbs, comparison fails.
**Why it happens:** Stored lbs values are irrational; display rounding (0.5 kg) creates apparent discrepancies.
**How to avoid:** Always compare stored values (lbs), never compare display values. Never round stored lbs to a "nice" number.

### Pitfall 4: Export Includes Stale Offline Data
**What goes wrong:** User exports while offline — Firestore returns cached data. Export appears to succeed but is missing recent online-only data.
**Why it happens:** Firestore offline persistence serves cached docs when offline.
**How to avoid:** Before export, check network connectivity (`expo-network`). If offline, warn user but allow export (clearly labeled "may not include latest data").

### Pitfall 5: Stripe Subscription Not Canceled on Account Delete
**What goes wrong:** Account is deleted from Firebase but Stripe subscription keeps billing.
**Why it happens:** The existing `createCheckoutSession` does not store the Stripe subscription ID to Firestore. The `deleteAccount` function cannot find the subscription to cancel.
**How to avoid:** Add `stripeSubscriptionId: subscription.id` to the `users/{uid}` Firestore doc in `stripeWebhook.ts` on `customer.subscription.created`. Then `deleteAccount` can look it up. Alternatively, use the RevenueCat Delete Subscriber endpoint (`DELETE /v1/subscribers/{uid}`) which removes RC purchase history (though it does NOT cancel the underlying store subscription — Apple/Google store subs must be managed by user).

### Pitfall 6: `recursiveDelete` on Large Data Sets May Time Out
**What goes wrong:** User with years of workout data triggers account delete; Cloud Function times out at default 60s.
**Why it happens:** `recursiveDelete` makes many serial Firestore operations.
**How to avoid:** Set `timeoutSeconds: 540` on the `deleteAccount` function. This is the maximum allowed by Cloud Functions v2.

### Pitfall 7: Web Export Using File URI
**What goes wrong:** `expo-sharing` throws on web; `FileSystem.writeAsStringAsync` is not available on web.
**Why it happens:** Both libraries are mobile-only.
**How to avoid:** Check `Platform.OS === 'web'` before calling export. On web, generate a Blob and use `URL.createObjectURL` + `<a download>` click. This requires the file contents to be in memory (not written to disk) on web.

### Pitfall 8: RevenueCat Delete Subscriber ≠ Cancel Subscription
**What goes wrong:** Calling `DELETE /v1/subscribers/{uid}` removes the user from RevenueCat's system but does NOT cancel the underlying Apple/Google subscription. User keeps getting billed.
**Why it happens:** RevenueCat can only cancel Google Play subscriptions server-side. Apple subscriptions can only be canceled by the user.
**How to avoid:** For account deletion, Stripe web subscriptions CAN be canceled server-side via `stripe.subscriptions.cancel()`. For mobile (RevenueCat-managed) subscriptions, the correct approach is to delete the RC subscriber record (cleans up RC data) and inform the user they must cancel their App Store/Play Store subscription manually. OR: use the RevenueCat v2 API which has more cancellation capabilities.

## Code Examples

Verified patterns from official sources and existing codebase:

### App Check Provider Config
```typescript
// Source: https://rnfirebase.io/app-check/usage
const provider = new ReactNativeFirebaseAppCheckProvider();
provider.configure({
  android: {
    provider: __DEV__ ? 'debug' : 'playIntegrity',
    debugToken: process.env.EXPO_PUBLIC_APP_CHECK_DEBUG_TOKEN,
  },
  apple: {
    provider: __DEV__ ? 'debug' : 'appAttestWithDeviceCheckFallback',
    debugToken: process.env.EXPO_PUBLIC_APP_CHECK_DEBUG_TOKEN,
  },
});
await initializeAppCheck(getApp(), { provider, isTokenAutoRefreshEnabled: true });
```

### Weight Conversion (already tested in codebase)
```typescript
// Source: src/domain/calculations/weight-unit-conversion.ts
export const POUNDS_PER_KG = 2.2046226218;
export function lbToKg(lb: number): number { return lb / POUNDS_PER_KG; }
export function kgToLb(kg: number): number { return kg * POUNDS_PER_KG; }
```

### Kg Display Rounding (per CONTEXT decision)
```typescript
// Round to nearest 0.5 kg (gym plate increments) — per locked decision
function roundToHalfKg(kg: number): number {
  return Math.round(kg * 2) / 2;
}
// Example: 132.28 lbs → 59.999... kg → rounded to 60.0 kg
```

### File Write + Share (iOS/Android)
```typescript
// Source: expo-file-system + expo-sharing official docs
import * as FileSystem from 'expo-file-system/legacy';
import * as Sharing from 'expo-sharing';

const path = `${FileSystem.cacheDirectory}export.json`;
await FileSystem.writeAsStringAsync(path, JSON.stringify(data));
await Sharing.shareAsync(path, { dialogTitle: 'Export Your Data' });
```

### Web Export Fallback
```typescript
// Platform.OS === 'web' path — no expo-file-system available
const blob = new Blob([JSON.stringify(data)], { type: 'application/json' });
const url = URL.createObjectURL(blob);
const a = document.createElement('a');
a.href = url;
a.download = `sundee-fundee-export-${date}.json`;
a.click();
URL.revokeObjectURL(url);
```

### Recursive Firestore Delete (Cloud Function)
```typescript
// Source: firebase.google.com/docs/firestore/solutions/delete-collections
// firebase-admin ^12.x already installed in functions/
await admin.firestore().recursiveDelete(admin.firestore().doc(`users/${uid}`));
await admin.auth().deleteUser(uid);
```

### Stripe Subscription Cancel (server-side)
```typescript
// Source: docs.stripe.com/api/subscriptions/cancel
// stripe ^20.x already installed in functions/
const stripe = new Stripe(STRIPE_SECRET_KEY.value());
await stripe.subscriptions.cancel(stripeSubscriptionId);
```

### RevenueCat Delete Subscriber
```typescript
// Source: docs.revenuecat.com/reference — DELETE /v1/subscribers/{app_user_id}
// Note: removes RC data only — does NOT cancel Apple/Google store subscriptions
await fetch(`https://api.revenuecat.com/v1/subscribers/${encodeURIComponent(uid)}`, {
  method: 'DELETE',
  headers: { Authorization: `Bearer ${rcSecretKey}` },
});
```

### Existing RC Revoke Pattern (already in codebase)
```typescript
// Source: functions/src/stripeWebhook.ts — extract revokeRCEntitlement() into shared helper
// Revokes the promotional entitlement specifically (not the store subscription)
DELETE https://api.revenuecat.com/v1/subscribers/{uid}/entitlements/premium/promotional
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Manual subcollection deletion loops | `db.recursiveDelete()` | firebase-admin v11+ | Eliminates manual traversal, handles arbitrary depth |
| `expo-file-system` `writeAsStringAsync` from main export | `expo-file-system/legacy` import path | Expo SDK 50+ | New `File` class API introduced; legacy path still works but new `File`/`Paths` API is preferred |
| AppDelegate.mm (ObjC) | AppDelegate.swift (Swift) | React Native 0.79+ | Project uses RN 0.83.2 — Swift AppDelegate is default |

**Deprecated/outdated:**
- `import * as FileSystem from 'expo-file-system'` for `writeAsStringAsync`: Now under `expo-file-system/legacy`. The new `File` class API is preferred but either works. Use legacy import to match existing patterns in this project.

## Open Questions

1. **Stripe Subscription ID Not Stored**
   - What we know: `createCheckoutSession.ts` stores `firebaseUID` in subscription metadata but does NOT write `stripeSubscriptionId` back to Firestore
   - What's unclear: How the `deleteAccount` function will find the subscription ID to cancel
   - Recommendation: Add `stripeSubscriptionId: subscription.id` to `/users/{uid}` in `stripeWebhook.ts` on `customer.subscription.created`. This is a one-line addition that unlocks server-side cancel on account deletion.

2. **App Check and Existing Firestore Security Rules**
   - What we know: App Check tokens are enforced at the Firestore rules level; the CONTEXT says "Firestore security rules require valid App Check token"
   - What's unclear: Current `firestore.rules` — whether they already have App Check enforcement or it needs to be added
   - Recommendation: Research task should read existing `firestore.rules` and add `request.app != null` guard to all rules, or use Firebase Console to enable App Check enforcement per-product.

3. **React Native Zip Archive — Build Required**
   - What we know: `react-native-zip-archive` is a native module requiring a new dev build
   - What's unclear: Whether the current dev build configuration supports adding native modules without EAS Build
   - Recommendation: Plan should note that adding `react-native-zip-archive` requires running `npx expo run:ios` / `npx expo run:android` or a new EAS build. This is standard for this project (uses `expo-dev-client`).

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Jest 29 + jest-expo preset |
| Config file | `SundeeFundeeRN/jest.config.js` |
| Quick run command | `cd SundeeFundeeRN && npx jest --testPathPattern="settings\|export\|deleteAccount" --passWithNoTests` |
| Full suite command | `cd SundeeFundeeRN && npx jest --coverage` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| PLAT-04 | Art Deco visual consistency (spacing, typography, colors) | visual/manual | Manual review — no automated visual regression in this project | N/A — manual only |
| PLAT-05 | Weight unit toggle saves to settings and updates all displays | unit | `npx jest --testPathPattern="formatWeight\|weightUnit\|settings"` | ❌ Wave 0 — `src/utils/__tests__/formatWeight.test.ts` |
| PLAT-05 | `formatWeight()` converts lbs → kg with 0.5 rounding | unit | `npx jest src/utils/__tests__/formatWeight.test.ts` | ❌ Wave 0 |
| PLAT-05 | `parseWeightInput()` converts user kg input → stored lbs | unit | `npx jest src/utils/__tests__/formatWeight.test.ts` | ❌ Wave 0 |
| PLAT-06 | `collectAllUserData()` fetches all Firestore subcollections | unit (mocked) | `npx jest src/export/__tests__/exportData.test.ts` | ❌ Wave 0 |
| PLAT-06 | `buildCsvFiles()` formats data with correct column headers (unit-aware) | unit | `npx jest src/export/__tests__/exportData.test.ts` | ❌ Wave 0 |
| PLAT-07 | `deleteAccount` Cloud Function deletes Firestore, Auth, RC, Stripe | unit (mocked) | `cd functions && npx jest __tests__/deleteAccount.test.ts` | ❌ Wave 0 |
| PLAT-07 | Guest "Clear Local Data" wipes AsyncStorage only | unit | `npx jest --testPathPattern="settings"` | ❌ needs new test case in settings.test.tsx |

### Sampling Rate
- **Per task commit:** `cd SundeeFundeeRN && npx jest --testPathPattern="formatWeight\|exportData\|deleteAccount\|settings" --passWithNoTests`
- **Per wave merge:** `cd SundeeFundeeRN && npx jest --coverage && cd ../functions && npx jest`
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] `SundeeFundeeRN/src/utils/__tests__/formatWeight.test.ts` — covers PLAT-05: `formatWeight()`, `parseWeightInput()`, rounding to 0.5 kg
- [ ] `SundeeFundeeRN/src/export/__tests__/exportData.test.ts` — covers PLAT-06: data collection, CSV formatting, file naming
- [ ] `functions/__tests__/deleteAccount.test.ts` — covers PLAT-07: full delete orchestration (RC revoke, Stripe cancel, Firestore delete, Auth delete)
- [ ] New test cases in `settings.test.tsx` for weight unit toggle and account deletion sections

## Sources

### Primary (HIGH confidence)
- [rnfirebase.io/app-check/usage](https://rnfirebase.io/app-check/usage) — App Check provider configuration, `initializeAppCheck` API, debug token setup
- [docs.expo.dev/versions/latest/sdk/sharing/](https://docs.expo.dev/versions/latest/sdk/sharing/) — `shareAsync` API, platform support, web limitations
- [docs.expo.dev/versions/latest/sdk/filesystem/](https://docs.expo.dev/versions/latest/sdk/filesystem/) — `writeAsStringAsync`, cache directory, web not supported
- `SundeeFundeeRN/src/domain/calculations/weight-unit-conversion.ts` — confirmed existing conversion functions
- `SundeeFundeeRN/src/repositories/SettingsRepo.ts` — confirmed `weightUnit: 'lb' | 'kg'` already in `AppSettings`
- `functions/src/stripeWebhook.ts` — confirmed `revokeRCEntitlement` helper and Stripe SDK usage
- [firebase.google.com/docs/firestore/solutions/delete-collections](https://firebase.google.com/docs/firestore/solutions/delete-collections) — `db.recursiveDelete()` pattern confirmed for firebase-admin

### Secondary (MEDIUM confidence)
- [docs.revenuecat.com — Delete Subscriber](https://docs.revenuecat.com/v3.1/reference/subscribersapp_user_id) — `DELETE /v1/subscribers/{app_user_id}` endpoint confirmed; caution: removes RC data only, does not cancel Apple/Google store subscriptions
- [docs.stripe.com/api/subscriptions/cancel](https://docs.stripe.com/api/subscriptions/cancel) — `stripe.subscriptions.cancel(id)` confirmed for immediate cancellation
- [npmjs.com/package/react-native-zip-archive](https://www.npmjs.com/package/react-native-zip-archive) — zip creation for native; JSZip confirmed incompatible with Expo

### Tertiary (LOW confidence)
- Medium/blog posts on App Check Expo integration — multiple sources agree on debug token pattern; use official rnfirebase.io as authoritative

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — existing codebase confirmed `weightUnit` field and conversion utilities; App Check from official RNF docs; expo-sharing/file-system from official Expo docs
- Architecture: HIGH — follows existing patterns (repo factory, platform branching, Cloud Functions) exactly
- Pitfalls: HIGH — Stripe subscription ID gap is a confirmed issue identified by reading actual `createCheckoutSession.ts` and `stripeWebhook.ts`; App Check simulator pitfall is from official docs; zip library incompatibility verified from multiple sources

**Research date:** 2026-03-15
**Valid until:** 2026-04-15 (30 days — stable libraries; App Check and expo-sharing APIs are stable)
