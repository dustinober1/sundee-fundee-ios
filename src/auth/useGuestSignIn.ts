/**
 * useGuestSignIn — Anonymous (guest) sign-in hook.
 *
 * Provides signIn (anonymous auth) and upgrade (linkWithCredential to convert
 * anonymous account to permanent, preserving UID and Firestore data).
 *
 * After a successful linkWithCredential, upgrade() triggers data migration from
 * AsyncStorage to Firestore. Migration errors do NOT block the upgrade — if
 * migration fails, a pending flag is set so the app can retry on next launch.
 */
import { useState, useCallback } from 'react';
import AsyncStorage from '@react-native-async-storage/async-storage';
import {
  signInAnonymously,
  getCurrentUser,
  linkWithCredential,
  type AuthUser,
  type AuthCredential,
} from '../firebase/auth';
import { getAuthErrorMessage } from './authErrors';
import { migrateGuestDataToFirestore } from '../repositories/migration';

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

        // Migrate guest data to Firestore after successful account upgrade.
        // This runs in a separate try/catch so migration errors do not block
        // the upgrade — linkWithCredential already succeeded.
        try {
          await AsyncStorage.setItem('@sundee/migration_pending', 'true');
          await migrateGuestDataToFirestore(currentUser.uid);
          // migration.ts clears @sundee/migration_pending via multiRemove on success
        } catch (migrationError) {
          console.warn('[upgrade] Migration deferred:', migrationError);
          // Do NOT re-throw — linkWithCredential already succeeded.
          // The pending flag remains set so retryPendingMigration can retry on next launch.
        }

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
