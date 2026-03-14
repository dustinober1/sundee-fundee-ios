/**
 * useGoogleSignIn — Google Sign-In hook (Android + Web).
 *
 * Configures Google Sign-In, checks Play Services, signs in via GoogleSignin,
 * extracts idToken, creates a Firebase Google credential, and signs in.
 */
import { useState, useCallback } from 'react';
import auth, { GoogleAuthProvider } from '@react-native-firebase/auth';
import { GoogleSignin } from '@react-native-google-signin/google-signin';
import { getAuthErrorMessage } from './authErrors';

export interface GoogleSignInState {
  signIn: () => Promise<unknown>;
  isLoading: boolean;
  error: string | null;
}

export function useGoogleSignIn(): GoogleSignInState {
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const signIn = useCallback(async (): Promise<unknown> => {
    setIsLoading(true);
    setError(null);
    try {
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

      // Create Firebase credential and sign in
      const credential = GoogleAuthProvider.credential(idToken);
      const result = await auth().signInWithCredential(credential);

      return result.user;
    } catch (err) {
      const message = getAuthErrorMessage(err);
      setError(message);
      throw err;
    } finally {
      setIsLoading(false);
    }
  }, []);

  return { signIn, isLoading, error };
}
