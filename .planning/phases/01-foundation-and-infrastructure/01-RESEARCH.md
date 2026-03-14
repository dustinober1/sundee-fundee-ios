# Phase 1: Foundation and Infrastructure - Research

**Researched:** 2026-03-14
**Domain:** Expo + React Native Firebase + EAS Build + RevenueCat entitlement wiring
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Auth Screen Presentation**
- Stacked full-width buttons layout: Apple on top, then Google, then Email, with "Continue as Guest" as a de-emphasized text link below
- Platform-adaptive provider display: iOS shows Apple + Email + Guest; Android shows Google + Email + Guest; Web shows Google + Email + Guest
- Branding: App logo centered with a short tagline above the auth buttons

**Guest Experience Boundaries**
- Guests get full app shell access (tabs, settings, empty states) — no feature lockout, just no data sync
- Guest-to-auth upgrade merges local data into Firestore — no data loss on sign-up
- Gentle, contextual upgrade nudges only when guests try sync-dependent features (no interrupting modals, no periodic reminders)
- "Create Account" option always visible in settings, plus contextual nudges elsewhere

**Sign-out and Session Behavior**
- Sign-out requires confirmation dialog ("Are you sure?")
- All locally cached user data cleared on sign-out — clean slate for next user
- After sign-out, user returns directly to the auth screen
- Unlimited simultaneous sessions across devices — Firestore keeps data in sync

**Error and Loading States**
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

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| AUTH-01 | User can sign up with email and password | Firebase Auth email/password + sendEmailVerification pattern |
| AUTH-02 | User can sign in with Apple (iOS) | expo-apple-authentication + OAuthProvider.credential(identityToken, nonce) pattern |
| AUTH-03 | User can sign in with Google (Android + Web) | @react-native-google-signin/google-signin + GoogleAuthProvider.credential(idToken) pattern |
| AUTH-04 | User can continue as guest without creating an account | Firebase signInAnonymously() — creates persistent anonymous UID for Firestore scoping |
| AUTH-05 | User session persists across app restart | onAuthStateChanged listener + Stack.Protected guard — session auto-restores from Firebase |
| AUTH-06 | User can sign out from any screen | signOut() + confirmation dialog + AsyncStorage wipe pattern |
| AUTH-07 | User data syncs across devices when authenticated | Firestore with UID-scoped document path (/users/{uid}/*) + security rules |
| PLAT-01 | App runs on iOS with native feel | Expo SDK 55 + EAS development build targeting iOS Simulator |
| PLAT-02 | App runs on Android with platform-appropriate conventions | EAS development build targeting Android Emulator, platform check for Google-only sign-in |
| PLAT-03 | App runs on Web with responsive layout | Expo Router + React Native Web; firebase-auth JS SDK for web (RNFirebase is mobile-only) |
</phase_requirements>

---

## Summary

Phase 1 establishes the complete technical foundation for a greenfield React Native + Expo app targeting iOS, Android, and Web. The core challenge is that `react-native-firebase` (native SDK, required by project decisions) only works in EAS development builds — Expo Go is explicitly excluded. This means the very first deliverable of Phase 1 is a working EAS development build, not a locally-runnable app.

The auth layer combines three distinct native integrations: `expo-apple-authentication` (iOS only), `@react-native-google-signin/google-signin` (Android + Web), and Firebase Auth email/password (all platforms). Each requires separate native configuration in `app.json`. The web target adds a wrinkle: `@react-native-firebase/auth` is mobile-only — the web build must use the Firebase JS SDK directly for auth, then hand off to the same Firestore backend.

RevenueCat wiring in Phase 1 is infrastructure-only: install `react-native-purchases`, configure API keys, and verify entitlement checking works end-to-end. No paywall UI is built (that is Phase 6). Firestore security rules must be written and deployed before any user data is stored — this is a project-level gate from STATE.md.

**Primary recommendation:** Start with `npx create-expo-app@latest --template blank-typescript`, immediately configure react-native-firebase with `expo-build-properties` (useFrameworks + forceStaticLinking), run `eas build --profile development` to validate native modules before writing any auth code.

---

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| expo | ~55.x | Managed workflow, EAS build orchestration | Latest stable; SDK 55 uses RN 0.83; New Architecture always-on |
| expo-router | ~5.x | File-based routing, tab navigation, protected routes | Bundled with Expo SDK 55; Stack.Protected for auth gating |
| @react-native-firebase/app | ^23.x | Core Firebase native SDK | Required; project decision to use native SDK not JS SDK |
| @react-native-firebase/auth | ^23.x | Firebase Authentication (mobile only) | Native module; Expo Go excluded |
| @react-native-firebase/firestore | ^23.x | Firestore database (mobile only) | Native module; offline persistence built-in |
| expo-build-properties | ~0.13.x | Configures useFrameworks + forceStaticLinking for iOS | Required for react-native-firebase on Expo SDK 55 |
| expo-apple-authentication | ~7.x | Sign in with Apple credential | Expo-managed; sets ios.usesAppleSignIn in app config |
| @react-native-google-signin/google-signin | ^14.x | Google Sign-In (Android + Web) | Only native Google auth library with Expo plugin |
| react-native-purchases | ^8.x | RevenueCat in-app purchase entitlements | Expo plugin available; works in dev build |
| firebase | ^11.x | Firebase JS SDK for Web platform auth | Web-only; RNFirebase does not compile for web |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| expo-secure-store | ~14.x | Secure token/key storage (iOS Keychain, Android Keystore) | Store Apple first-sign-in credentials (one-time only from Apple) |
| @react-native-async-storage/async-storage | ^2.x | Guest-mode local data persistence | AsyncStorage-backed repo for unauthenticated users |
| expo-dev-client | ^5.x | Development build shell for EAS | Required by all native module libraries |
| expo-constants | ~17.x | Access EAS environment variables at runtime | Pass FIREBASE_APP_CHECK_DEBUG_TOKEN from eas.json |
| expo-network | ~7.x | Detect offline state for auth screen banner | Shows "You're offline" banner; enables guest-always availability |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| @react-native-firebase | Firebase JS SDK everywhere | JS SDK works in Expo Go but lacks Analytics, Crashlytics, App Check; project decision locked native SDK |
| Zustand for auth state | React Context | Both work; Zustand avoids prop drilling for deeply nested auth checks; Context is fine for simpler apps |
| expo-apple-authentication | @invertase/react-native-apple-authentication | Expo's package has built-in config plugin; Invertase's is legacy |

**Installation:**
```bash
# Core project
npx create-expo-app@latest SundeeFundee --template blank-typescript
cd SundeeFundee

# Firebase native SDK
npx expo install @react-native-firebase/app @react-native-firebase/auth @react-native-firebase/firestore
npx expo install expo-build-properties

# Auth providers
npx expo install expo-apple-authentication
npx expo install @react-native-google-signin/google-signin

# RevenueCat
npx expo install react-native-purchases react-native-purchases-ui

# Dev infrastructure
npx expo install expo-dev-client expo-secure-store expo-constants expo-network
npx expo install @react-native-async-storage/async-storage

# Web-only Firebase JS SDK (for web platform auth)
npm install firebase
```

---

## Architecture Patterns

### Recommended Project Structure
```
SundeeFundee/
├── app/                          # Expo Router pages (file-based routes)
│   ├── _layout.tsx               # Root layout: SessionProvider + RevenueCat init
│   ├── sign-in.tsx               # Auth screen (always accessible)
│   ├── verify-email.tsx          # Email verification gate
│   └── (app)/                    # Protected route group
│       ├── _layout.tsx           # Stack.Protected guard + tab layout
│       └── (tabs)/
│           ├── _layout.tsx       # Tab bar definition
│           ├── index.tsx         # Dashboard tab
│           └── settings.tsx      # Settings tab (sign-out lives here)
├── src/
│   ├── auth/                     # Auth domain
│   │   ├── AuthContext.tsx       # Session context: user, isLoading, signIn, signOut
│   │   ├── useAppleSignIn.ts     # Apple auth hook (iOS only)
│   │   ├── useGoogleSignIn.ts    # Google auth hook (Android + Web)
│   │   ├── useEmailAuth.ts       # Email/password + verification hook
│   │   ├── useGuestSignIn.ts     # Anonymous auth hook
│   │   └── authErrors.ts         # Error code → user message mapping
│   ├── firebase/                 # Firebase setup
│   │   ├── app.ts                # Platform-aware Firebase init (native vs JS SDK)
│   │   ├── firestore.ts          # Firestore instance + emulator config
│   │   └── auth.ts               # Auth instance
│   ├── repositories/             # Data access layer (matches iOS MVVM pattern)
│   │   ├── UserRepository.ts     # Interface
│   │   ├── FirestoreUserRepo.ts  # Authenticated impl
│   │   └── LocalUserRepo.ts      # Guest/offline impl (AsyncStorage)
│   ├── entitlements/             # RevenueCat
│   │   └── useEntitlements.ts    # Hook: check premium entitlement status
│   ├── theme/                    # Art Deco design tokens
│   │   ├── colors.ts             # cream, navy, orange constants
│   │   └── typography.ts
│   └── components/               # Shared UI
│       ├── AuthButton.tsx         # Full-width button with spinner state
│       └── OfflineBanner.tsx      # Subtle connectivity indicator
├── firestore.rules               # Security rules (deployed before any data write)
├── app.json                      # Expo config with firebase + EAS plugins
├── eas.json                      # Build profiles: development, preview, production
└── google-services.json          # Android Firebase config (git-ignored, injected by EAS)
```

### Pattern 1: Platform-Aware Firebase Init
**What:** On mobile, use react-native-firebase (native). On web, use Firebase JS SDK. Same Firestore backend, different client SDKs.
**When to use:** Web platform with react-native-firebase (which does not compile for web targets)

```typescript
// src/firebase/app.ts
import { Platform } from 'react-native';

// On web: firebase JS SDK auto-initializes via google-services web config
// On native: @react-native-firebase/app auto-initializes from GoogleService-Info.plist / google-services.json
export const isWeb = Platform.OS === 'web';

// src/firebase/auth.ts
import { Platform } from 'react-native';

// Web: Firebase JS SDK
import { getAuth as getWebAuth, initializeApp } from 'firebase/auth';
// Native: react-native-firebase
import auth from '@react-native-firebase/auth';

export function getAuthInstance() {
  if (Platform.OS === 'web') {
    // web app initialized separately with JS SDK
    return getWebAuth();
  }
  return auth();
}
```

### Pattern 2: Expo Router Protected Routes (Stack.Protected)
**What:** Auth gating via `Stack.Protected` — blocks navigation to app routes when user is not authenticated.
**When to use:** Root of the app; renders before any tab or screen.

```typescript
// app/(app)/_layout.tsx
// Source: https://docs.expo.dev/router/advanced/authentication/
import { Stack } from 'expo-router';
import { useSession } from '@/src/auth/AuthContext';

export default function AppLayout() {
  const { session, isLoading } = useSession();

  if (isLoading) return null; // keep splash screen visible

  return (
    <Stack.Protected guard={session !== null}>
      {/* All tab routes live here */}
    </Stack.Protected>
  );
}
```

### Pattern 3: Firebase Auth State Listener
**What:** Single `onAuthStateChanged` listener drives all routing and user state.
**When to use:** AuthContext implementation — never read auth state directly in components.

```typescript
// src/auth/AuthContext.tsx
// Source: https://rnfirebase.io/auth/usage
import auth from '@react-native-firebase/auth';

export function SessionProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<FirebaseAuthTypes.User | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    const unsubscribe = auth().onAuthStateChanged((firebaseUser) => {
      setUser(firebaseUser);
      setIsLoading(false);
    });
    return unsubscribe; // cleanup on unmount
  }, []);

  return (
    <AuthContext.Provider value={{ session: user, isLoading, signIn, signOut }}>
      {children}
    </AuthContext.Provider>
  );
}
```

### Pattern 4: Apple Sign-In with Nonce
**What:** Two-phase: Apple auth → Firebase credential. Nonce pairs the two calls.
**When to use:** iOS only — conditionally rendered based on `Platform.OS === 'ios'`.

```typescript
// src/auth/useAppleSignIn.ts
// Source: https://rnfirebase.io/auth/social-auth
import { appleAuth } from '@invertase/react-native-apple-authentication';
import auth from '@react-native-firebase/auth';

export function useAppleSignIn() {
  return async () => {
    const appleAuthResponse = await appleAuth.performRequest({
      requestedOperation: appleAuth.Operation.LOGIN,
      requestedScopes: [appleAuth.Scope.FULL_NAME, appleAuth.Scope.EMAIL],
    });
    const { identityToken, nonce } = appleAuthResponse;
    if (!identityToken) throw new Error('Apple Sign-In failed: no identity token');
    const appleCredential = auth.AppleAuthProvider.credential(identityToken, nonce);
    await auth().signInWithCredential(appleCredential);
    // NOTE: name/email only available on FIRST sign-in — store to SecureStore immediately
  };
}
```

### Pattern 5: Google Sign-In
**What:** Get idToken from Google, create Firebase credential, sign in.
**When to use:** Android and Web (not iOS per locked decision).

```typescript
// src/auth/useGoogleSignIn.ts
// Source: https://rnfirebase.io/auth/social-auth
import { GoogleSignin, GoogleAuthProvider } from '@react-native-google-signin/google-signin';
import auth from '@react-native-firebase/auth';

GoogleSignin.configure({ webClientId: process.env.EXPO_PUBLIC_GOOGLE_WEB_CLIENT_ID });

export function useGoogleSignIn() {
  return async () => {
    await GoogleSignin.hasPlayServices({ showPlayServicesUpdateDialog: true });
    const result = await GoogleSignin.signIn();
    const googleCredential = auth.GoogleAuthProvider.credential(result.data?.idToken);
    await auth().signInWithCredential(googleCredential);
  };
}
```

### Pattern 6: Email Sign-Up with Verification Gate
**What:** Create account → send verification email → block app access until email verified.
**When to use:** Email/password sign-up flow (all platforms).

```typescript
// src/auth/useEmailAuth.ts
// Source: https://rnfirebase.io/auth/usage
import auth from '@react-native-firebase/auth';

export function useEmailAuth() {
  const signUp = async (email: string, password: string) => {
    const { user } = await auth().createUserWithEmailAndPassword(email, password);
    await user.sendEmailVerification();
    // Route to verify-email screen; onAuthStateChanged will re-evaluate emailVerified
    // Poll or wait for user to re-sign in after verifying
  };

  const signIn = async (email: string, password: string) => {
    const { user } = await auth().signInWithEmailAndPassword(email, password);
    if (!user.emailVerified) {
      await auth().signOut();
      throw new Error('Please verify your email before signing in.');
    }
  };

  return { signUp, signIn };
}
```

### Pattern 7: Guest (Anonymous) Auth
**What:** `signInAnonymously()` creates a persistent Firebase UID usable for Firestore scoping. Linking converts to real account.
**When to use:** "Continue as Guest" tap.

```typescript
// Source: https://rnfirebase.io/auth/usage
import auth from '@react-native-firebase/auth';

const signInAsGuest = () => auth().signInAnonymously();

// Guest-to-auth upgrade (preserves Firestore data under same UID):
const upgrade = async (credential: FirebaseAuthTypes.AuthCredential) => {
  await auth().currentUser?.linkWithCredential(credential);
};
```

### Anti-Patterns to Avoid
- **Reading `auth().currentUser` directly in components:** Use `onAuthStateChanged` listener. Direct reads can return stale values during token refresh.
- **Calling `auth()` before `@react-native-firebase/app` initializes:** Always ensure Firebase app plugin runs first in `app.json` plugins array.
- **Storing Firebase UID in AsyncStorage and trusting it client-side:** UID from `auth().currentUser` is authoritative. Never trust a locally stored UID for security decisions.
- **Running Firestore writes without security rules deployed:** Firestore defaults to fully open for new projects for 30 days. Rules must be deployed before any user data is written (project-level gate).
- **Using Firebase JS SDK for auth on native builds:** It bypasses native session persistence and breaks App Check. Only use JS SDK on web.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Persistent auth session | Manual token refresh + storage | Firebase Auth (built-in session management) | Firebase handles token refresh, expiry, and multi-device sign-out automatically |
| Apple Sign-In nonce handling | Custom SHA-256 nonce generation | `expo-apple-authentication` returns nonce automatically | Nonce must match what Apple signs; handrolling breaks cryptographic pairing |
| Google OAuth flow | WebView-based OAuth redirect | `@react-native-google-signin/google-signin` | Native Google SDK handles Play Services, account picker, and token rotation |
| In-app purchase receipt validation | Custom StoreKit/Play Billing server | RevenueCat | Receipt validation has platform-specific edge cases, refund handling, and grace periods |
| Subscription entitlement logic | Custom Firestore premium flag | RevenueCat entitlements | RevenueCat handles billing provider webhooks, grace periods, and cross-platform sync |
| Firestore offline persistence | Local SQLite cache + sync | Firestore SDK built-in (enablePersistence) | Firestore's built-in offline cache handles conflict resolution and sync ordering |
| Security rules testing | Manual emulator test scripts | Firebase Emulator Suite + `@firebase/rules-unit-testing` | Automated rules testing prevents security regressions |

**Key insight:** Firebase Auth session management, social auth credential exchange, and RevenueCat entitlement tracking each have multi-platform edge cases (token expiry, account linking, billing state machines) that make custom implementations fragile. Use the purpose-built SDK for each.

---

## Common Pitfalls

### Pitfall 1: react-native-firebase Incompatible with Expo SDK 55 iOS Build
**What goes wrong:** Build fails on iOS with "non-modular header" errors when using `useFrameworks: "static"`.
**Why it happens:** firebase-ios-sdk requires static frameworks; Expo SDK 55 New Architecture changes how frameworks link.
**How to avoid:** Add `expo-build-properties` with both `useFrameworks: "static"` AND `forceStaticLinking` for all RNFB modules.
**Warning signs:** Build fails at pod compilation step with `CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES` errors.

```json
// app.json plugins section
["expo-build-properties", {
  "ios": {
    "useFrameworks": "static",
    "forceStaticLinking": ["RNFBApp", "RNFBAuth", "RNFBFirestore", "RNFBAppCheck"]
  }
}]
```

### Pitfall 2: Apple Sign-In Credentials Are One-Time Only
**What goes wrong:** User's name and email are returned by Apple only on the first sign-in. Subsequent sign-ins return empty strings.
**Why it happens:** Apple privacy policy — user controls what data Apple shares.
**How to avoid:** Immediately store name/email to `expo-secure-store` or Firestore on first sign-in. Never assume they will be available again.
**Warning signs:** Display name is empty for returning Apple users.

### Pitfall 3: Expo Go Used Anywhere
**What goes wrong:** `@react-native-firebase`, `@react-native-google-signin`, and `react-native-purchases` all crash in Expo Go with "native module not found" errors.
**Why it happens:** Expo Go bundles a fixed set of native modules; none of the required Firebase modules are included.
**How to avoid:** Run `eas build --profile development` immediately. Add `"expo-dev-client"` to dependencies. Never use `npx expo start` without a custom dev client.
**Warning signs:** "null is not an object (evaluating 'RNFBApp.default')" at startup.

### Pitfall 4: Google SHA-1 Fingerprint Missing for Android
**What goes wrong:** Google Sign-In succeeds in debug but fails in production with "developer error" from Google Play Services.
**Why it happens:** Android requires the app's SHA-1 certificate fingerprint registered in Firebase Console for OAuth.
**How to avoid:** Register both debug and release SHA-1 fingerprints in Firebase Console before first Android build. EAS provides fingerprints via `eas credentials`.
**Warning signs:** `ApiException: 10` from GoogleSignin on Android.

### Pitfall 5: Firestore Security Rules Not Deployed Before First Write
**What goes wrong:** User data written without rules is accessible to all users. Firebase defaults new projects to open access for 30 days.
**Why it happens:** Firebase Console creates projects with temporary permissive rules.
**How to avoid:** Write and deploy `firestore.rules` before any data write code is executed. Treat rules as Wave 0 infrastructure.
**Warning signs:** Firebase Console shows "Your security rules are defined as public" warning.

### Pitfall 6: Firebase Dynamic Links Shutdown Breaks Email Verification
**What goes wrong:** Email verification deep links stop working on August 25, 2025 because Firebase Dynamic Links shut down.
**Why it happens:** Firebase deprecated Dynamic Links; email verification previously used them for mobile deep linking.
**How to avoid:** Use standard Firebase email verification (web redirect URL), not dynamic links. The default behavior (redirect to a hosted Firebase page) works without Dynamic Links.
**Warning signs:** Email verification link opens browser, not the app — this is expected without Dynamic Links; handle via re-sign-in flow.

### Pitfall 7: Web Platform Auth with Wrong SDK
**What goes wrong:** `@react-native-firebase/auth` is imported on web build, causing "Cannot find module" or build failure because native modules don't compile for web.
**Why it happens:** react-native-firebase targets iOS/Android only. The web Expo target needs the Firebase JS SDK.
**How to avoid:** Use `Platform.OS === 'web'` branching or module aliasing to swap auth implementations. Consider a platform-specific file: `auth.native.ts` vs `auth.web.ts`.
**Warning signs:** EAS web build fails with unresolved native module imports.

### Pitfall 8: App Check Blocks Development Builds
**What goes wrong:** App Check enforcement rejects development build requests, making Auth and Firestore calls fail with permission denied.
**Why it happens:** App Check doesn't have a valid attestation provider in Simulator/Emulator environments.
**How to avoid:** Use `FIREBASE_APP_CHECK_DEBUG_TOKEN` environment variable in EAS `development` build profile. Register the debug token in Firebase Console > App Check > Debug Tokens.
**Warning signs:** Auth and Firestore calls return 403 with `AppCheck` in the error message during development.

---

## Code Examples

### app.json Firebase + EAS Configuration
```json
// Source: https://docs.expo.dev/guides/using-firebase/ + https://rnfirebase.io/
{
  "expo": {
    "name": "Sundee Fundee",
    "slug": "sundee-fundee",
    "version": "1.0.0",
    "platforms": ["ios", "android", "web"],
    "ios": {
      "bundleIdentifier": "com.sundeefundee.app",
      "googleServicesFile": "./GoogleService-Info.plist",
      "usesAppleSignIn": true
    },
    "android": {
      "package": "com.sundeefundee.app",
      "googleServicesFile": "./google-services.json"
    },
    "plugins": [
      "@react-native-firebase/app",
      "@react-native-firebase/auth",
      "expo-apple-authentication",
      [
        "expo-build-properties",
        {
          "ios": {
            "useFrameworks": "static",
            "forceStaticLinking": ["RNFBApp", "RNFBAuth", "RNFBFirestore", "RNFBAppCheck"]
          }
        }
      ]
    ]
  }
}
```

### eas.json Build Profiles
```json
// Source: https://docs.expo.dev/eas/json/
{
  "cli": { "version": ">= 13.0.0" },
  "build": {
    "development": {
      "developmentClient": true,
      "distribution": "internal",
      "env": {
        "FIREBASE_APP_CHECK_DEBUG_TOKEN": "<token-from-firebase-console>"
      }
    },
    "preview": {
      "distribution": "internal"
    },
    "production": {}
  }
}
```

### Firestore Security Rules — User-Owned Data Pattern
```
// firestore.rules
// Source: https://firebase.google.com/docs/firestore/security/rules-conditions
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Default deny all
    match /{document=**} {
      allow read, write: if false;
    }

    // User profile and all subcollections: owner-only access
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;

      match /{subcollection}/{docId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
  }
}
```

### RevenueCat Configuration
```typescript
// Source: https://www.revenuecat.com/docs/getting-started/installation/expo
// app/_layout.tsx
import Purchases from 'react-native-purchases';
import { Platform } from 'react-native';

function configureRevenueCat() {
  if (Platform.OS === 'ios') {
    Purchases.configure({ apiKey: process.env.EXPO_PUBLIC_RC_APPLE_KEY! });
  } else if (Platform.OS === 'android') {
    Purchases.configure({ apiKey: process.env.EXPO_PUBLIC_RC_GOOGLE_KEY! });
  }
  // Web: RevenueCat Web Billing configured separately via Stripe
}
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Expo Go for local dev | EAS development build (expo-dev-client) | SDK 50+ (native modules forced it) | No more Expo Go for this stack; first build takes ~10 min but all native modules work |
| `firebase/compat` JS SDK everywhere | Platform-specific (RNFirebase native / JS SDK web) | 2023-2024 | Cleaner separation; native SDK gives Crashlytics, App Check, Analytics |
| React Navigation manually set up | Expo Router (file-based, built-in) | SDK 50+ | Protected routes via Stack.Protected instead of navigation guards |
| Dynamic Links for email verification | Standard web redirect URL | Aug 2025 shutdown | Mobile deep link on verify now opens browser; re-sign-in flow required |
| Old Architecture (Bridge) | New Architecture always-on in SDK 55 | SDK 55 (RN 0.83) | forceStaticLinking required for react-native-firebase on iOS |
| Custom auth token storage | Firebase Auth handles session natively | Always | No SecureStore for tokens (only for Apple first-sign-in name/email) |

**Deprecated/outdated:**
- Firebase Dynamic Links: shut down August 25, 2025 — do not use for email verification deep links
- Expo Go: not viable for this stack — use dev client exclusively
- `use_frameworks! :linkage => :static` in Podfile directly: managed by `expo-build-properties` config plugin; never edit Podfile manually in managed workflow

---

## Open Questions

1. **Expo SDK 55 vs SDK 54 target**
   - What we know: SDK 55 uses RN 0.83, New Architecture always-on; react-native-firebase v23.x is confirmed compatible with proper forceStaticLinking config (issue #8908 closed resolved)
   - What's unclear: Whether `react-native-purchases` (RevenueCat) has confirmed SDK 55 compatibility — the research found general SDK 54 confirmation but no explicit SDK 55 mention
   - Recommendation: Target SDK 55. If RevenueCat shows issues, pin to SDK 54 for Phase 1 only. SDK 54 is the last version allowing New Architecture opt-out.

2. **Firebase App Check Strategy**
   - What we know: Debug token via `FIREBASE_APP_CHECK_DEBUG_TOKEN` env var in EAS `development` profile works for Simulator/Emulator
   - What's unclear: Whether App Check enforcement should be enabled from day one or deferred to production
   - Recommendation: Wire App Check with debug bypass in Phase 1 so enforcement can be enabled at production deploy without code changes. Document in STATE.md as a phase close gate.

3. **Web Auth Implementation Boundary**
   - What we know: `@react-native-firebase/auth` does not compile for web. Firebase JS SDK must be used on web.
   - What's unclear: Whether the React Native web target can conditionally bundle native-only modules (via `Platform.select` or `.native.ts` / `.web.ts` file extensions) without explicit metro resolver configuration
   - Recommendation: Use platform-specific file extensions (`auth.native.ts` / `auth.web.ts`) from day one. Metro resolver picks them up automatically. Do not rely on `Platform.OS` branching inside a single file for module imports.

4. **RevenueCat Web Billing (Stripe) Scope**
   - What we know: RevenueCat Web Billing uses Stripe; the same `appUserID` links mobile and web entitlements
   - What's unclear: Whether Phase 1 wiring requires a Stripe account and webhook to be live, or if entitlement checking can be stubbed until Phase 6
   - Recommendation: Wire RevenueCat SDK initialization and entitlement checking in Phase 1. Defer Stripe webhook and Web Billing configuration to Phase 6 when paywall UI is built.

---

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Jest + @testing-library/react-native (to be installed in Wave 0) |
| Config file | jest.config.js (Wave 0 gap) |
| Quick run command | `npx jest --testPathPattern="auth" --passWithNoTests` |
| Full suite command | `npx jest --coverage` |

Note: The existing iOS project enforces 100% line coverage via xccov. The RN project should establish a coverage baseline in Phase 1. 100% coverage on domain logic is the goal (matching iOS pattern); UI components and platform-specific auth hooks are tested via integration/smoke tests.

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| AUTH-01 | Email sign-up creates user + sends verification | unit (mock auth) | `npx jest --testPathPattern="useEmailAuth"` | ❌ Wave 0 |
| AUTH-02 | Apple credential → Firebase sign-in | unit (mock appleAuth + auth) | `npx jest --testPathPattern="useAppleSignIn"` | ❌ Wave 0 |
| AUTH-03 | Google credential → Firebase sign-in | unit (mock GoogleSignin + auth) | `npx jest --testPathPattern="useGoogleSignIn"` | ❌ Wave 0 |
| AUTH-04 | Anonymous sign-in creates persistent session | unit (mock auth) | `npx jest --testPathPattern="useGuestSignIn"` | ❌ Wave 0 |
| AUTH-05 | onAuthStateChanged restores session on mount | unit (mock auth listener) | `npx jest --testPathPattern="AuthContext"` | ❌ Wave 0 |
| AUTH-06 | Sign-out clears local state + AsyncStorage | unit | `npx jest --testPathPattern="AuthContext"` | ❌ Wave 0 |
| AUTH-07 | Firestore write under /users/{uid} succeeds for owner | rules test (Firebase Emulator) | `npx jest --testPathPattern="firestore.rules"` | ❌ Wave 0 |
| PLAT-01 | EAS dev build launches on iOS Simulator | smoke (manual) | manual — EAS build + `xcrun simctl launch` | ❌ Wave 0 |
| PLAT-02 | EAS dev build launches on Android Emulator | smoke (manual) | manual — EAS build + `adb shell am start` | ❌ Wave 0 |
| PLAT-03 | Web build serves auth screen | smoke (manual) | `npx expo start --web` (after dev build) | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `npx jest --testPathPattern="(auth|Auth)" --passWithNoTests`
- **Per wave merge:** `npx jest --coverage`
- **Phase gate:** All unit tests green + manual smoke tests on iOS Simulator, Android Emulator, and Web before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] `jest.config.js` — Jest configuration with React Native preset
- [ ] `__mocks__/@react-native-firebase/auth.ts` — Mock firebase auth module
- [ ] `__mocks__/expo-apple-authentication.ts` — Mock Apple auth
- [ ] `__mocks__/@react-native-google-signin/google-signin.ts` — Mock Google sign-in
- [ ] `src/auth/__tests__/AuthContext.test.tsx` — Covers AUTH-05, AUTH-06
- [ ] `src/auth/__tests__/useEmailAuth.test.ts` — Covers AUTH-01
- [ ] `src/auth/__tests__/useAppleSignIn.test.ts` — Covers AUTH-02
- [ ] `src/auth/__tests__/useGoogleSignIn.test.ts` — Covers AUTH-03
- [ ] `src/auth/__tests__/useGuestSignIn.test.ts` — Covers AUTH-04
- [ ] `firestore.rules.test.ts` — Covers AUTH-07 (requires @firebase/rules-unit-testing + Firebase Emulator)
- [ ] Framework install: `npx expo install jest-expo @testing-library/react-native`

---

## Sources

### Primary (HIGH confidence)
- `https://rnfirebase.io/` — react-native-firebase current version (v23.x), auth patterns, social auth patterns, iOS setup requirements
- `https://rnfirebase.io/auth/usage` — onAuthStateChanged, email/password, anonymous auth patterns
- `https://rnfirebase.io/auth/social-auth` — Apple credential pattern, Google credential pattern, exact code
- `https://docs.expo.dev/router/advanced/authentication/` — Stack.Protected pattern, SessionProvider structure, file layout
- `https://docs.expo.dev/guides/using-firebase/` — RNFirebase vs JS SDK differences, EAS build requirements, app.json config
- `https://firebase.google.com/docs/firestore/security/rules-conditions` — Firestore security rule patterns, UID-based access control
- `https://www.revenuecat.com/docs/getting-started/installation/expo` — RevenueCat Expo setup, react-native-purchases, entitlements

### Secondary (MEDIUM confidence)
- `https://expo.dev/changelog/sdk-55` — Expo SDK 55 release: React Native 0.83, New Architecture always-on
- `https://github.com/invertase/react-native-firebase/issues/8908` — Confirmed resolved: RNFirebase compatible with Expo SDK 55 + New Architecture with forceStaticLinking
- `https://react-native-google-signin.github.io/docs/setting-up/expo` — @react-native-google-signin Expo plugin setup, SHA-1 requirements
- `https://docs.expo.dev/versions/latest/sdk/apple-authentication/` — expo-apple-authentication built-in config plugin, ios.usesAppleSignIn
- `https://www.revenuecat.com/blog/engineering/build-a-single-expo-app-with-subscriptions-on-ios-android-and-web-using-revenuecat/` — RevenueCat Web Billing + Stripe + mobile unified entitlements

### Tertiary (LOW confidence — needs validation)
- Community reports of react-native-firebase + Expo SDK 55 requiring forceStaticLinking — verified by GitHub issue resolution but no official docs yet
- RevenueCat explicit SDK 55 compatibility — inferred from general Expo support; needs validation on first build

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — versions confirmed via npm and official docs; react-native-firebase v23.x, Expo SDK 55 confirmed current
- Architecture: HIGH — file structure and auth patterns from official Expo Router and react-native-firebase documentation
- EAS build setup: HIGH — confirmed via official Expo and RNFirebase docs
- Pitfalls: HIGH (SDK 55 compat) / MEDIUM (App Check emulator) — RNFirebase issue #8908 closed-resolved; App Check debug token pattern from official docs
- RevenueCat wiring: MEDIUM — setup confirmed; SDK 55 explicit compat not found in docs (inferred from Expo support claim)

**Research date:** 2026-03-14
**Valid until:** 2026-04-14 (30 days — Expo SDK and react-native-firebase release frequently)
