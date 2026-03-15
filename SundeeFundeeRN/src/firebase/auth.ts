/**
 * Native Firebase Auth instance.
 *
 * Uses @react-native-firebase/auth which is backed by the native Firebase SDK.
 * This file is selected by Metro's platform-specific resolver on iOS and Android.
 * Web uses auth.web.ts instead.
 */
import auth, { FirebaseAuthTypes } from '@react-native-firebase/auth';

export type AuthUser = FirebaseAuthTypes.User;
export type AuthCredential = FirebaseAuthTypes.AuthCredential;

/**
 * Returns the native Firebase Auth instance.
 * @react-native-firebase auto-initializes from GoogleService-Info.plist (iOS)
 * or google-services.json (Android) via the app.json plugin.
 */
export function getAuthInstance(): FirebaseAuthTypes.Module {
  return auth();
}

/**
 * Subscribe to auth state changes.
 * Returns an unsubscribe function to clean up the listener.
 */
export function onAuthStateChanged(
  callback: (user: AuthUser | null) => void
): () => void {
  return auth().onAuthStateChanged(callback);
}

/**
 * Sign in with a Firebase credential (Apple, Google, etc.)
 */
export async function signInWithCredential(
  credential: AuthCredential
): Promise<AuthUser> {
  const result = await auth().signInWithCredential(credential);
  return result.user;
}

/**
 * Sign in with email and password.
 */
export async function signInWithEmailAndPassword(
  email: string,
  password: string
): Promise<AuthUser> {
  const result = await auth().signInWithEmailAndPassword(email, password);
  return result.user;
}

/**
 * Create a new user with email and password.
 */
export async function createUserWithEmailAndPassword(
  email: string,
  password: string
): Promise<AuthUser> {
  const result = await auth().createUserWithEmailAndPassword(email, password);
  return result.user;
}

/**
 * Sign in anonymously (guest mode).
 */
export async function signInAnonymously(): Promise<AuthUser> {
  const result = await auth().signInAnonymously();
  return result.user;
}

/**
 * Sign out the current user.
 */
export async function signOut(): Promise<void> {
  return auth().signOut();
}

/**
 * Get the currently signed-in user, or null if not authenticated.
 */
export function getCurrentUser(): AuthUser | null {
  return auth().currentUser;
}

/**
 * Send email verification to the given user.
 */
export async function sendEmailVerification(user: AuthUser): Promise<void> {
  await user.sendEmailVerification();
}

/**
 * Link an anonymous user with a credential to convert to a permanent account.
 */
export async function linkWithCredential(
  user: AuthUser,
  credential: AuthCredential
): Promise<AuthUser> {
  const result = await user.linkWithCredential(credential);
  return result.user;
}

// Re-export auth providers for credential creation
export const AppleAuthProvider = auth.AppleAuthProvider;
export const GoogleAuthProvider = auth.GoogleAuthProvider;
export const EmailAuthProvider = auth.EmailAuthProvider;
