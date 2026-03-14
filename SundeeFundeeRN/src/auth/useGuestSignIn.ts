/**
 * useGuestSignIn — Anonymous (guest) sign-in hook.
 *
 * Provides signIn (anonymous auth) and upgrade (linkWithCredential to convert
 * anonymous account to permanent, preserving UID and Firestore data).
 */
import { useState, useCallback } from 'react';
import auth from '@react-native-firebase/auth';
import type { FirebaseAuthTypes } from '@react-native-firebase/auth';
import { getAuthErrorMessage } from './authErrors';

export interface GuestSignInState {
  signIn: () => Promise<FirebaseAuthTypes.User>;
  upgrade: (credential: FirebaseAuthTypes.AuthCredential) => Promise<unknown>;
  isLoading: boolean;
  error: string | null;
}

export function useGuestSignIn(): GuestSignInState {
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const signIn = useCallback(async (): Promise<FirebaseAuthTypes.User> => {
    setIsLoading(true);
    setError(null);
    try {
      const result = await auth().signInAnonymously();
      return result.user;
    } catch (err) {
      setError(getAuthErrorMessage(err));
      throw err;
    } finally {
      setIsLoading(false);
    }
  }, []);

  const upgrade = useCallback(
    async (credential: FirebaseAuthTypes.AuthCredential): Promise<unknown> => {
      setIsLoading(true);
      setError(null);
      try {
        // linkWithCredential converts the anonymous account to a permanent one,
        // preserving the same Firebase UID and all Firestore data — per locked decision.
        const result = await auth().currentUser?.linkWithCredential(credential);
        return result;
      } catch (err) {
        setError(getAuthErrorMessage(err));
        throw err;
      } finally {
        setIsLoading(false);
      }
    },
    []
  );

  return { signIn, upgrade, isLoading, error };
}
