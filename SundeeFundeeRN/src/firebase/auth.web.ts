/**
 * Web Firebase Auth instance.
 *
 * Uses the Firebase JS SDK (firebase/auth) for web builds.
 * This file is selected by Metro's platform-specific resolver on web.
 * Native (iOS/Android) uses auth.native.ts instead.
 *
 * @react-native-firebase/auth does not compile for web targets — this
 * file provides the same interface using the JS SDK.
 */
import {
  getAuth,
  signInWithCredential as fbSignInWithCredential,
  signInWithEmailAndPassword as fbSignInWithEmailAndPassword,
  createUserWithEmailAndPassword as fbCreateUserWithEmailAndPassword,
  signInAnonymously as fbSignInAnonymously,
  signOut as fbSignOut,
  onAuthStateChanged as fbOnAuthStateChanged,
  OAuthProvider,
  GoogleAuthProvider as FbGoogleAuthProvider,
  User,
  Auth,
  AuthCredential,
} from 'firebase/auth';
import { initializeApp, getApps, FirebaseApp } from 'firebase/app';

export type AuthUser = User;
export { AuthCredential };

function getFirebaseApp(): FirebaseApp {
  const existing = getApps();
  if (existing.length > 0) {
    return existing[0];
  }

  const config = {
    apiKey: process.env.EXPO_PUBLIC_FIREBASE_WEB_API_KEY ?? '',
    authDomain: process.env.EXPO_PUBLIC_FIREBASE_AUTH_DOMAIN ?? '',
    projectId: process.env.EXPO_PUBLIC_FIREBASE_PROJECT_ID ?? '',
  };

  return initializeApp(config);
}

/**
 * Returns the web Firebase Auth instance.
 */
export function getAuthInstance(): Auth {
  return getAuth(getFirebaseApp());
}

/**
 * Subscribe to auth state changes.
 * Returns an unsubscribe function to clean up the listener.
 */
export function onAuthStateChanged(
  callback: (user: AuthUser | null) => void
): () => void {
  return fbOnAuthStateChanged(getAuthInstance(), callback);
}

/**
 * Sign in with a Firebase credential (Apple, Google, etc.)
 */
export async function signInWithCredential(
  credential: AuthCredential
): Promise<AuthUser> {
  const result = await fbSignInWithCredential(getAuthInstance(), credential);
  return result.user;
}

/**
 * Sign in with email and password.
 */
export async function signInWithEmailAndPassword(
  email: string,
  password: string
): Promise<AuthUser> {
  const result = await fbSignInWithEmailAndPassword(getAuthInstance(), email, password);
  return result.user;
}

/**
 * Create a new user with email and password.
 */
export async function createUserWithEmailAndPassword(
  email: string,
  password: string
): Promise<AuthUser> {
  const result = await fbCreateUserWithEmailAndPassword(getAuthInstance(), email, password);
  return result.user;
}

/**
 * Sign in anonymously (guest mode).
 */
export async function signInAnonymously(): Promise<AuthUser> {
  const result = await fbSignInAnonymously(getAuthInstance());
  return result.user;
}

/**
 * Sign out the current user.
 */
export async function signOut(): Promise<void> {
  return fbSignOut(getAuthInstance());
}

/**
 * Get the currently signed-in user, or null if not authenticated.
 */
export function getCurrentUser(): AuthUser | null {
  return getAuthInstance().currentUser;
}

// Auth providers for credential creation (web equivalents)
export const AppleAuthProvider = {
  credential: (identityToken: string, nonce?: string) => {
    const provider = new OAuthProvider('apple.com');
    return provider.credential({ idToken: identityToken, rawNonce: nonce });
  },
};

export const GoogleAuthProvider = {
  credential: (idToken: string) => FbGoogleAuthProvider.credential(idToken),
};
