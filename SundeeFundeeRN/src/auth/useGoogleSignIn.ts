/**
 * useGoogleSignIn — Google Sign-In hook (Android + Web).
 *
 * Configures Google Sign-In, checks Play Services, signs in via GoogleSignin,
 * extracts idToken, creates a Firebase Google credential, and signs in.
 *
 * getCredential() returns the AuthCredential without signing in — used by
 * sign-in.tsx to route through guest.upgrade() for anonymous users.
 */
import { useState, useCallback } from 'react';
import {
  signInWithCredential,
  GoogleAuthProvider,
  type AuthCredential,
} from '../firebase/auth';
import { GoogleSignin } from '@react-native-google-signin/google-signin';
import { getAuthErrorMessage } from './authErrors';

export interface GoogleSignInState {
  signIn: () => Promise<unknown>;
  getCredential: () => Promise<AuthCredential>;
  isLoading: boolean;
  error: string | null;
}

export function useGoogleSignIn(): GoogleSignInState {
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  /**
   * getCredential — pure credential factory, no loading/error state management.
   * Configures Google Sign-In, obtains idToken, and returns Firebase AuthCredential.
   */
  const getCredential = useCallback(async (): Promise<AuthCredential> => {
    // Configure with the web client ID (required for cross-platform)
    GoogleSignin.configure({
      webClientId: process.env.EXPO_PUBLIC_GOOGLE_WEB_CLIENT_ID,
    });

    // Check Play Services availability on Android
    await GoogleSignin.hasPlayServices({
      showPlayServicesUpdateDialog: true,
    });

    // Sign in and extract idToken
    const signInResult = await GoogleSignin.signIn();
    const idToken = signInResult.data?.idToken;

    if (!idToken) {
      throw new Error('Google Sign-In did not return an idToken');
    }

    return GoogleAuthProvider.credential(idToken);
  }, []);

  const signIn = useCallback(async (): Promise<unknown> => {
    setIsLoading(true);
    setError(null);
    try {
      const credential = await getCredential();

      // Create Firebase credential and sign in
      const user = await signInWithCredential(credential);

      return user;
    } catch (err) {
      const message = getAuthErrorMessage(err);
      setError(message);
      throw err;
    } finally {
      setIsLoading(false);
    }
  }, [getCredential]);

  return { signIn, getCredential, isLoading, error };
}
