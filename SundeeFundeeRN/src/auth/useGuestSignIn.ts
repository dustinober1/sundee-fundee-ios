/**
 * useGuestSignIn — Anonymous (guest) sign-in hook.
 *
 * Provides signIn (anonymous auth) and upgrade (linkWithCredential to convert
 * anonymous account to permanent, preserving UID and Firestore data).
 */
import { useState, useCallback } from 'react';
import {
  signInAnonymously,
  getCurrentUser,
  linkWithCredential,
  type AuthUser,
  type AuthCredential,
} from '../firebase/auth';
import { getAuthErrorMessage } from './authErrors';

export interface GuestSignInState {
  signIn: () => Promise<AuthUser>;
  upgrade: (credential: AuthCredential) => Promise<unknown>;
  isLoading: boolean;
  error: string | null;
}

export function useGuestSignIn(): GuestSignInState {
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const signIn = useCallback(async (): Promise<AuthUser> => {
    setIsLoading(true);
    setError(null);
    try {
      const user = await signInAnonymously();
      return user;
    } catch (err) {
      setError(getAuthErrorMessage(err));
      throw err;
    } finally {
      setIsLoading(false);
    }
  }, []);

  const upgrade = useCallback(
    async (credential: AuthCredential): Promise<unknown> => {
      setIsLoading(true);
      setError(null);
      try {
        const currentUser = getCurrentUser();
        if (!currentUser) {
          throw new Error('No current user to upgrade');
        }
        // linkWithCredential converts the anonymous account to a permanent one,
        // preserving the same Firebase UID and all Firestore data — per locked decision.
        const result = await linkWithCredential(currentUser, credential);
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
