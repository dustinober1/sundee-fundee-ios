/**
 * useAppleSignIn — Apple Sign-In hook (iOS only).
 *
 * Obtains identity token via expo-apple-authentication, creates a Firebase
 * Apple credential, signs in, and stores the display name to SecureStore
 * (Apple only provides full name on first sign-in per user decision).
 */
import { useState, useCallback } from 'react';
import {
  signInWithCredential,
  AppleAuthProvider,
} from '../firebase/auth';
import {
  signInAsync as appleSignInAsync,
  AppleAuthenticationScope,
} from 'expo-apple-authentication';
import * as SecureStore from 'expo-secure-store';
import { getAuthErrorMessage } from './authErrors';

export interface AppleSignInState {
  signIn: () => Promise<unknown>;
  isLoading: boolean;
  error: string | null;
}

export function useAppleSignIn(): AppleSignInState {
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const signIn = useCallback(async (): Promise<unknown> => {
    setIsLoading(true);
    setError(null);
    try {
      const appleCredential = await appleSignInAsync({
        requestedScopes: [
          AppleAuthenticationScope.FULL_NAME,
          AppleAuthenticationScope.EMAIL,
        ],
      });

      const { identityToken, fullName } = appleCredential;

      // Create Firebase credential from Apple identity token
      // The second argument is an optional raw nonce (not provided by expo-apple-authentication)
      const credential = AppleAuthProvider.credential(identityToken, undefined);

      // Sign in to Firebase with Apple credential
      const user = await signInWithCredential(credential);

      // Store display name to SecureStore — Apple provides fullName only once
      if (fullName?.givenName) {
        const displayName = [fullName.givenName, fullName.familyName]
          .filter(Boolean)
          .join(' ');
        await SecureStore.setItemAsync('apple_display_name', displayName);
      }

      return user;
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
