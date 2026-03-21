/**
 * Firebase Auth — web-only, no platform branching.
 * Adapted from the existing auth.web.ts.
 */
import {
  getAuth,
  signInWithCredential as fbSignInWithCredential,
  signInWithEmailAndPassword as fbSignInWithEmailAndPassword,
  createUserWithEmailAndPassword as fbCreateUserWithEmailAndPassword,
  signInAnonymously as fbSignInAnonymously,
  signOut as fbSignOut,
  onAuthStateChanged as fbOnAuthStateChanged,
  sendEmailVerification as fbSendEmailVerification,
  linkWithCredential as fbLinkWithCredential,
  signInWithPopup,
  OAuthProvider,
  GoogleAuthProvider as FbGoogleAuthProvider,
  EmailAuthProvider as FbEmailAuthProvider,
  type User,
  type Auth,
  type AuthCredential,
} from 'firebase/auth';
import { getFirebaseApp } from './app';

export type AuthUser = User;
export type { AuthCredential };

export function getAuthInstance(): Auth {
  return getAuth(getFirebaseApp());
}

export function onAuthStateChanged(
  callback: (user: AuthUser | null) => void,
): () => void {
  return fbOnAuthStateChanged(getAuthInstance(), callback);
}

export async function signInWithCredential(
  credential: AuthCredential,
): Promise<AuthUser> {
  const result = await fbSignInWithCredential(getAuthInstance(), credential);
  return result.user;
}

export async function signInWithEmailAndPassword(
  email: string,
  password: string,
): Promise<AuthUser> {
  const result = await fbSignInWithEmailAndPassword(getAuthInstance(), email, password);
  return result.user;
}

export async function createUserWithEmailAndPassword(
  email: string,
  password: string,
): Promise<AuthUser> {
  const result = await fbCreateUserWithEmailAndPassword(getAuthInstance(), email, password);
  return result.user;
}

export async function signInAnonymously(): Promise<AuthUser> {
  const result = await fbSignInAnonymously(getAuthInstance());
  return result.user;
}

export async function signOut(): Promise<void> {
  return fbSignOut(getAuthInstance());
}

export function getCurrentUser(): AuthUser | null {
  return getAuthInstance().currentUser;
}

export async function sendEmailVerification(user: AuthUser): Promise<void> {
  await fbSendEmailVerification(user);
}

export async function linkWithCredential(
  user: AuthUser,
  credential: AuthCredential,
): Promise<AuthUser> {
  const result = await fbLinkWithCredential(user, credential);
  return result.user;
}

/** Sign in with Google via popup. */
export async function signInWithGoogle(): Promise<AuthUser> {
  const provider = new FbGoogleAuthProvider();
  const result = await signInWithPopup(getAuthInstance(), provider);
  return result.user;
}

/** Sign in with Apple via popup. */
export async function signInWithApple(): Promise<AuthUser> {
  const provider = new OAuthProvider('apple.com');
  provider.addScope('email');
  provider.addScope('name');
  const result = await signInWithPopup(getAuthInstance(), provider);
  return result.user;
}

export const AppleAuthProvider = {
  credential: (identityToken: string, nonce?: string) => {
    const provider = new OAuthProvider('apple.com');
    return provider.credential({ idToken: identityToken, rawNonce: nonce });
  },
};

export const GoogleAuthProvider = {
  credential: (idToken: string) => FbGoogleAuthProvider.credential(idToken),
};

export const EmailAuthProvider = {
  credential: (email: string, password: string) =>
    FbEmailAuthProvider.credential(email, password),
};
