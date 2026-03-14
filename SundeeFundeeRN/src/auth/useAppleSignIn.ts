/**
 * useAppleSignIn — Apple Sign-In hook (iOS only).
 *
 * Obtains identity token via expo-apple-authentication, creates a Firebase
 * Apple credential, signs in, and stores the display name to SecureStore
 * (Apple only provides full name on first sign-in per user decision).
 */
import { useState, useCallback } from 'react';
import auth, { AppleAuthProvider } from '@react-native-firebase/auth';
import {
  AppleAuthentication,
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
      const appleCredential = await AppleAuthentication.signInAsync({
        requestedScopes: [
          AppleAuthenticationScope.FULL_NAME,
          AppleAuthenticationScope.EMAIL,
        ],
      });

      const { identityToken, nonce, fullName } = appleCredential;

      // Create Firebase credential from Apple identity token
      const credential = AppleAuthProvider.credential(identityToken, nonce);

      // Sign in to Firebase with Apple credential
      const result = await auth().signInWithCredential(credential);

      // Store display name to SecureStore — Apple provides fullName only once
      if (fullName?.givenName) {
        const displayName = [fullName.givenName, fullName.familyName]
          .filter(Boolean)
          .join(' ');
        await SecureStore.setItemAsync('apple_display_name', displayName);
      }

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
